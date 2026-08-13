#!/usr/bin/env python3
"""Single entry point for the PolyBench CIR-vs-OG audit.

Resolves the toolchain from machines.json (or auto-detection), so the common
case needs no paths:

  ./run_polybench.py --all --accurate-mode                 # every axis
  ./run_polybench.py --hip --compile --accurate-mode       # one axis
  ./run_polybench.py --all --accurate-mode --publish       # + push results
  ./run_polybench.py --cuda --compile --offload-merge      # CIR no-merge vs CIR-merge

Axes:
  --compile     CIR vs OG compile-time breakdown, single arch
  --runtime     CIR vs OG GPU execution time + binary size
  --multi-arch  compile-time breakdown per target arch (compile-only: you can
                only execute on the GPU actually present)
  --all         all three, in that order

--offload-merge swaps the compared pair of every axis from CIR vs OG to
CIR (no-merge) vs CIR-merge, where the merge arm adds --clangir-offload-merge.
That is the combine-work comparison (compile-time merge overhead + runtime
parity), formerly `run_cir_offload_merge.py`.

--accurate-mode is the paper-grade profile: fully serialized (-j 1) to remove
CPU and GPU contention, 3 warmups, 8 timed samples, run-tagged log dirs, and
it refuses to run on a guessed GPU arch. It also implies --validate: paper-grade
runs carry the CPU-reference correctness check (misses) in the record.

Settings resolve as: explicit flag > machines.json profile > auto-detection.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import run_compile
import run_runtime
from polybench_common import (
    detect_cuda_arch,
    detect_hip_arch,
    find_clang,
    find_cuda_root,
    find_gcc_install,
    find_rocm_device_lib,
    find_rocm_root,
    load_machine_config,
    provenance,
)

# Paper-grade profile: serialized, enough samples to separate signal from noise.
ACCURATE = {"jobs": 1, "warmup": 3, "samples": 8}

# Smoke profile: exercise every axis end-to-end in minutes, not hours.
TEST = {"warmup": 1, "samples": 2}
TEST_LIMIT = 2

RESULTS_REPO = "git@github.com:RiverDave/polybench-results.git"
COMMIT_NAME  = "RiverDave"
COMMIT_EMAIL = "davidriverg@gmail.com"


def build_argv(mode: str, args, arch: str) -> tuple[list[str], str]:
    """Translate the unified CLI into argv for run_compile / run_runtime."""
    target = "--hip" if args.hip else "--cuda"
    tag    = "hip" if args.hip else "cuda"
    argv = [
        target,
        "--clang", str(args.clang),
        "--polybench-root", str(args.polybench_root),
        "--gcc-install-dir", str(args.gcc_install_dir),
        "--warmup", str(args.warmup),
        "-j", str(args.jobs),
    ]

    if args.hip:
        argv += ["--hip-path", str(args.hip_path),
                 "--rocm-device-lib-path", str(args.rocm_device_lib_path)]
    else:
        argv += ["--cuda-root", str(args.cuda_root)]

    if args.offload_merge:
        argv += ["--merge"]

    slug = f"{mode}-{tag}-{'multi' if mode == 'multiarch' else arch}-j{args.jobs}"
    if args.offload_merge:
        slug += "-merge"
    log_dir = str(Path(args.log_root) / slug)
    argv += ["--log-dir", log_dir]

    # The two scripts spell arch and repetition count differently.
    if mode == "runtime":
        argv += ["--arch", arch,
                 "--runs", str(args.samples),
                 "--warmup", str(args.warmup),
                 "--build-dir", f"{log_dir}/build"]
        if args.validate:
            argv += ["--validate"]
    else:
        argv += ["--hip-arch" if args.hip else "--cuda-arch", arch,
                 "--samples", str(args.samples)]
        if mode == "multiarch":
            argv += ["--multi-arch"]
            if args.multi_arches:
                argv += ["--arches", ",".join(args.multi_arches)]

    if args.limit:
        argv += ["--limit", str(args.limit)]
    if args.clang_flags:
        argv += [f"--clang-flags={args.clang_flags}"]
    return argv, log_dir


def publish(log_dirs: list[str], machine: str, prov: dict, suffix: str = "") -> int:
    """Copy summaries + raw JSON into the results repo and push."""
    checkout = Path.home() / "polybench-results"
    if not (checkout / ".git").is_dir():
        print(f"\nCloning {RESULTS_REPO} -> {checkout}")
        if subprocess.run(["git", "clone", RESULTS_REPO, str(checkout)]).returncode != 0:
            print("error: clone failed; results left on disk")
            return 1

    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%MZ") + suffix
    dest  = checkout / machine / stamp
    dest.mkdir(parents=True, exist_ok=True)

    copied = 0
    for d in log_dirs:
        for pattern in ("*_summary.md", "*_results.json"):
            for f in Path(d).glob(pattern):
                shutil.copy2(f, dest / f"{Path(d).name}__{f.name}")
                copied += 1
        artifacts_src = Path(d) / "artifacts"
        if artifacts_src.is_dir():
            artifacts_dst = dest / "artifacts" / Path(d).name
            artifacts_dst.mkdir(parents=True, exist_ok=True)
            for a in artifacts_src.iterdir():
                shutil.copy2(a, artifacts_dst / a.name)
                copied += 1
    (dest / "provenance.json").write_text(
        json.dumps(prov, indent=2) + "\n")

    print(f"\nPublishing {copied} files to {machine}/{stamp}")
    git = ["git", "-C", str(checkout)]

    # A bare benchmark box often has no git identity, which makes commit fail.
    # Set it repo-locally rather than touching the user's global config.
    if subprocess.run(git + ["config", "user.email"], capture_output=True).returncode != 0:
        subprocess.run(git + ["config", "user.email", COMMIT_EMAIL], check=False)
        subprocess.run(git + ["config", "user.name",  COMMIT_NAME],  check=False)

    subprocess.run(git + ["add", "-A"], check=False)
    commit = subprocess.run(git + ["commit", "-m", f"{machine}: results {stamp}"],
                            capture_output=True, text=True)
    if commit.returncode != 0 and "nothing to commit" not in commit.stdout:
        print(f"error: commit failed:\n{commit.stdout}{commit.stderr}")
        return 1

    # An empty remote has no branch to rebase onto ("unborn branch"), so only
    # pull once origin actually has one. Both boxes may finish together, hence
    # the rebase-and-retry.
    for attempt in (1, 2):
        has_remote_branch = subprocess.run(
            git + ["ls-remote", "--exit-code", "--heads", "origin"],
            capture_output=True).returncode == 0
        if has_remote_branch:
            subprocess.run(git + ["pull", "--rebase"], check=False)
        if subprocess.run(git + ["push", "-u", "origin", "HEAD"]).returncode == 0:
            print(f"Pushed to {RESULTS_REPO} ({machine}/{stamp})")
            return 0
        print(f"push attempt {attempt} failed, retrying after rebase…")
    print("error: push failed; results are committed locally in", checkout)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)

    target = parser.add_mutually_exclusive_group()
    target.add_argument("--hip",  action="store_true", help="Benchmark the HIP sources")
    target.add_argument("--cuda", action="store_true", help="Benchmark the CUDA sources")

    parser.add_argument("--compile",    action="store_true", help="Compile-time axis")
    parser.add_argument("--runtime",    action="store_true", help="Runtime axis")
    parser.add_argument("--multi-arch", action="store_true", help="Per-arch compile-time axis")
    parser.add_argument("--all",        action="store_true", help="All three axes")
    parser.add_argument("--accurate-mode", action="store_true",
                        help=f"Paper-grade profile: {ACCURATE}, and refuse a guessed arch")
    parser.add_argument("--test", action="store_true",
                        help=f"Smoke test: every selected axis on {TEST_LIMIT} benchmarks with "
                             f"{TEST['samples']} samples, into temp/smoke/. Verifies the whole "
                             f"pipeline before committing to a full run.")

    parser.add_argument("--machine", help="machines.json profile name (else matched by hostname)")
    parser.add_argument("--config",  default=str(Path(__file__).parent / "machines.json"))
    parser.add_argument("--publish", action="store_true",
                        help=f"Push summaries + raw JSON to {RESULTS_REPO}")
    parser.add_argument("--validate", action="store_true",
                        help="Runtime: build without DNO_CPU_REF and check correctness")
    parser.add_argument("--offload-merge", action="store_true",
                        help="Compare CIR no-merge vs CIR-merge (--clangir-offload-merge) instead of CIR vs OG")

    parser.add_argument("--arch",            help="Override the detected GPU arch")
    parser.add_argument("--clang",           help="Override the detected clang++")
    parser.add_argument("--polybench-root",  help="Override the PolyBench checkout")
    parser.add_argument("--cuda-root",       help="Override the detected CUDA toolkit")
    parser.add_argument("--hip-path",        help="Override the detected ROCm root")
    parser.add_argument("--rocm-device-lib-path", help="Override the detected amdgcn bitcode dir")
    parser.add_argument("--gcc-install-dir", help="Override the detected GCC install dir")
    parser.add_argument("--log-root", default="temp", help="Parent dir for run-tagged log dirs")
    parser.add_argument("--warmup",  type=int, help="Warmup iterations")
    parser.add_argument("--samples", type=int, help="Timed repetitions per benchmark")
    parser.add_argument("--limit",   type=int, default=0, help="Cap benchmarks (smoke tests)")
    parser.add_argument("--clang-flags", default="", help="Extra flags forwarded to every clang compile line")
    parser.add_argument("-j", "--jobs", type=int, help="Parallel jobs (accurate-mode forces 1)")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running")

    args = parser.parse_args()

    if args.all:
        args.compile = args.runtime = args.multi_arch = True
    if not (args.compile or args.runtime or args.multi_arch):
        parser.error("pick at least one axis: --compile / --runtime / --multi-arch / --all")

    cfg = load_machine_config(Path(args.config).expanduser(), args.machine)
    machine_name = args.machine or cfg.get("name") or _profile_name(Path(args.config), cfg)

    # Target: explicit flag, else the profile's declared target.
    if not (args.hip or args.cuda):
        t = cfg.get("target")
        if t == "hip":    args.hip = True
        elif t == "cuda": args.cuda = True
        else: parser.error("no --hip/--cuda given and no 'target' in the machine profile")

    # Profiles fill in only what was left unset, so explicit flags always win.
    # --test is applied first: when combined with --accurate-mode it keeps the
    # serialized -j1 execution but overrides the long sample counts.
    if args.test:
        for key, value in TEST.items():
            if getattr(args, key) is None:
                setattr(args, key, value)
        args.limit    = args.limit or TEST_LIMIT
        args.log_root = str(Path(args.log_root) / "smoke")
    for key, value in ACCURATE.items():
        if args.accurate_mode and getattr(args, key) is None:
            setattr(args, key, value)
    # Paper-grade runs carry the correctness stamp: --accurate-mode implies the
    # runtime validation phase (build without NO_CPU_REF, check misses).
    if args.accurate_mode:
        args.validate = True
    if args.jobs    is None: args.jobs    = 4
    if args.warmup  is None: args.warmup  = 2
    if args.samples is None: args.samples = 5

    # Settings resolve as: explicit flag > machines.json > auto-detection.
    args.clang           = args.clang           or cfg.get("clang")           or find_clang()
    args.polybench_root  = args.polybench_root  or cfg.get("polybench_root")  or "~/polybenchGpu"
    args.gcc_install_dir = args.gcc_install_dir or cfg.get("gcc_install_dir") or find_gcc_install()
    args.multi_arches    = cfg.get("multi_arches")

    if args.hip:
        rocm = Path(str(args.hip_path or cfg.get("hip_path") or find_rocm_root())).expanduser()
        args.hip_path = rocm
        args.rocm_device_lib_path = (args.rocm_device_lib_path
                                     or cfg.get("rocm_device_lib_path")
                                     or find_rocm_device_lib(rocm))
    else:
        args.cuda_root = args.cuda_root or cfg.get("cuda_root") or find_cuda_root()

    arch = args.arch or cfg.get("arch")
    if arch:
        arch_source = "explicit" if args.arch else "machines.json"
    else:
        arch, detected = detect_hip_arch() if args.hip else detect_cuda_arch()
        arch_source = "detected" if detected else "FALLBACK"

    # A guessed arch silently benchmarks the wrong target — never acceptable for a paper run.
    if arch_source == "FALLBACK" and args.accurate_mode:
        print(f"error: GPU arch could not be detected (would guess '{arch}').\n"
              f"       --accurate-mode refuses to benchmark a guessed target.\n"
              f"       Pass --arch <target>, or add one to {args.config}.")
        return 2

    prov = provenance()
    print(f"machine: {machine_name}   host={prov['hostname']}")
    print(f"target : {'HIP' if args.hip else 'CUDA'}  arch={arch} ({arch_source})")
    print(f"clang  : {args.clang}")
    print(f"gpu    : {prov['gpu'] or '?'}   cpu={prov['cpu_count']} threads")
    print(f"profile: -j{args.jobs}  warmup={args.warmup}  samples={args.samples}"
          f"{'  [accurate-mode]' if args.accurate_mode else ''}")
    if args.offload_merge:
        print("compare: CIR no-merge vs CIR-merge (--clangir-offload-merge)")
    if args.test:
        print(f"*** SMOKE TEST: {args.limit} benchmarks, {args.samples} samples, "
              f"results in {args.log_root}/ — NOT publication data ***")

    modes = [m for m, on in (("compile",   args.compile),
                             ("runtime",   args.runtime),
                             ("multiarch", args.multi_arch)) if on]
    log_dirs: list[str] = []
    for mode in modes:
        argv, log_dir = build_argv(mode, args, arch)
        entry = run_runtime.main if mode == "runtime" else run_compile.main
        print(f"\n=== {mode} ===\n$ {' '.join(argv)}\n")
        if args.dry_run:
            log_dirs.append(log_dir)
            continue
        if (rc := entry(argv)) != 0:
            return rc
        log_dirs.append(log_dir)

    if args.publish and not args.dry_run:
        return publish(log_dirs, machine_name, prov, "-smoke" if args.test else "")
    return 0


def _profile_name(config: Path, cfg: dict) -> str:
    """Reverse-lookup the profile's key in machines.json, for labelling results."""
    if not cfg or not config.exists():
        return "unknown"
    data = json.loads(config.read_text())
    for name, entry in data.items():
        if entry is cfg or entry == cfg:
            return name
    return "unknown"


if __name__ == "__main__":
    raise SystemExit(main())
