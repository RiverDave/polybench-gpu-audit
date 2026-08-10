#!/usr/bin/env python3
"""CIR vs OG runtime performance for PolyBench CUDA/HIP benchmarks.

Compiles each kernel to a full host+device executable and runs it --runs times,
recording the polybench wall-clock timer printed to stdout (%0.6lf).
Reports mean ± stddev and CIR/OG ratio per benchmark.

Examples:
  # CUDA (A10, sm_86)
  python3 run_runtime.py --cuda \\
      --clang ~/polybench-gpu-audit/llvm-project/build/bin/clang++ \\
      --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \\
      -j $(nproc)

  # HIP (gfx942)
  python3 run_runtime.py --hip \\
      --clang ~/polybench-gpu-audit/llvm-project/build/bin/clang++ \\
      --hip-path /opt/rocm \\
      -j $(nproc)
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

from polybench_common import (
    benchmark_name,
    find_clang,
    find_gcc_install,
    find_rocm_device_lib,
    find_rocm_root,
    git_rev,
    provenance,
    provenance_lines,
    is_hip,
    mean_stddev,
    median,
    path_arg,
    safe_name,
    source_set,
)


@dataclass
class PerfResult:
    benchmark:   str
    source_set:  str
    file:        Path
    pipeline:    str          # "CIR" or "OG"
    arch:        str
    compile_ok:  bool
    compile_log: Path
    binary:      Path | None  # None if compilation failed
    size:        int | None   # linked binary size in bytes, None if compilation failed
    times:       list[float]  # polybench wall-clock samples (seconds)
    wall_times:  list[float]  # process wall-time samples from perf_counter
    misses:      int | None = None   # validation mismatch count, None = not validated
    first_error: str = ""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_GPU_RUNTIME = re.compile(r"GPU Runtime:\s*([\d.]+)s")
# Lines that signal the next bare float line is a GPU timing value.
_TIMING_MARKER = re.compile(r"GPU\s+(?:Time|Runtime|elapsed)", re.IGNORECASE)
_MISSES = re.compile(r"Number of misses:\s*(\d+)")

def _parse_time(stdout: str) -> float | None:
    """Return the first GPU-time float from a polybench kernel's stdout.

    Two output conventions exist across the suite:

    1. ``GPU Runtime: 0.000481s`` – DOITGEN and the
       polybenchCodesCudaOpenClHMPPOpenAcc copies.

    2. ``GPU Time in seconds:\\n0.004241`` – GEMVER and other kernels that use
       the polybench timer macros (``polybench_start_instruments`` /
       ``polybench_stop_instruments`` / ``polybench_timer_print``).  The label
       is printed by the kernel, then the bare float by ``polybench_timer_print``.

    Both conventions print the GPU measurement *before* the CPU reference, so
    the function stops at the first GPU-related float.
    """
    lines = stdout.splitlines()
    for i, line in enumerate(lines):
        m = _GPU_RUNTIME.search(line)
        if m:
            return float(m.group(1))
        if _TIMING_MARKER.search(line):
            # The next non-empty line should be the bare float.
            for j in range(i + 1, len(lines)):
                candidate = lines[j].strip()
                if not candidate:
                    continue
                try:
                    return float(candidate)
                except ValueError:
                    break  # not a float – maybe a multi-line label, keep scanning
    return None


# ---------------------------------------------------------------------------
# Compilation
# ---------------------------------------------------------------------------

_EXTERN_RTCLOCK = re.compile(r"extern\s+double\s+rtclock")

# Guard the serial CPU reference in DOITGEN, which is the only benchmark
# without a RUN_ON_CPU guard (the other 20 have it pre-patched in the source).
# The print_array function in the RUN_ON_CPU #else branch has been
# checksummed by the source patcher to avoid per-element fprintf overhead.
_CPU_REF_PATCHES = [
    ("doitgenCPU(sum, A, C4);",
     "#ifndef NO_CPU_REF\ndoitgenCPU(sum, A, C4);\n#endif"),
]

def _needs_polybench_c(file: Path) -> bool:
    """True if the file forward-declares rtclock() as extern without including polybench.c.

    Kernels like DOITGEN have `extern double rtclock(void)` and rely on an
    external definition. Kernels whose common/polybenchUtilFuncts.h defines
    rtclock inline do not have this declaration and don't need polybench.c.
    """
    try:
        content = file.read_text(errors="ignore")
        return bool(_EXTERN_RTCLOCK.search(content)) and "polybench.c" not in content
    except OSError:
        return False


# C++ shim: wraps the C-linkage _pb_rtclock (from polybench.o) as a C++ symbol.
# DOITGEN declares `extern double rtclock(void)` in a .cu (C++) file, so the
# linker looks for the C++ mangled name; polybench.c only provides C linkage.
_POLYBENCH_SHIM = (
    'extern "C" { double _pb_rtclock(); }\n'
    'double rtclock() { return _pb_rtclock(); }\n'
)


def _compile_polybench_objs(clang: Path, common_dir: Path, gcc_install_dir: Path, build_dir: Path) -> list[Path]:
    """Return [polybench.o, polybench_shim.o] for linking into DOITGEN-style kernels."""
    pb_obj   = build_dir / "polybench.o"
    shim_src = build_dir / "polybench_shim.cpp"
    shim_obj = build_dir / "polybench_shim.o"

    # Compile polybench.c as plain C; rename rtclock → _pb_rtclock to avoid
    # clashing with the C++ symbol the shim will provide. -x c is required, not
    # cosmetic: `clang` here is clang++, which would otherwise treat the .c
    # input as C++ and mangle _pb_rtclock, breaking the shim's extern "C" link.
    cmd = [str(clang), f"--gcc-install-dir={gcc_install_dir}",
           "-O3", "-DPOLYBENCH_TIME=1", "-Dstatic=", "-Drtclock=_pb_rtclock",
           "-x", "c", "-c", str(common_dir / "polybench.c"), f"-I{common_dir}", "-o", str(pb_obj)]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"polybench.c compile failed:\n{proc.stderr[:500]}")

    shim_src.write_text(_POLYBENCH_SHIM)
    cmd = [str(clang), f"--gcc-install-dir={gcc_install_dir}",
           "-O3", "-c", str(shim_src), "-o", str(shim_obj)]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"polybench shim compile failed:\n{proc.stderr[:500]}")

    return [pb_obj, shim_obj]


def compile_one(
    clang:                Path,
    root:                 Path,
    cuda_root:            Path,
    hip_path:             Path,
    rocm_device_lib_path: Path,
    gcc_install_dir:      Path,
    arch:                 str,
    pipeline:             str,
    file:                 Path,
    common_dir:           Path,
    polybench_objs:       list[Path],
    build_dir:            Path,
    log_dir:              Path,
    merge: bool,
    no_cpu_ref: bool = True,
    clang_flags: str = "",
) -> PerfResult:
    suffix = "" if no_cpu_ref else "-validate"
    tag    = f"{safe_name(root, file)}.{pipeline.lower()}.{arch}{suffix}"
    log    = log_dir   / f"{tag}.log"
    binary = build_dir / tag

    source_file = file
    if no_cpu_ref:
        try:
            content = file.read_text()
            patched = False
            for old, new in _CPU_REF_PATCHES:
                if old in content:
                    content = content.replace(old, new)
                    patched = True
            if patched:
                patched_path = build_dir / f"{tag}.cu"
                patched_path.write_text(content)
                source_file = patched_path
        except OSError:
            pass

    cmd = [str(clang)]
    if pipeline == "CIR":
        cmd.append("-fclangir")
        cmd.extend(["-Xclang", "-clangir-enable-call-conv-lowering"])
    cmd.append(f"--gcc-install-dir={gcc_install_dir}")
    if merge != False:
        cmd.append(f"--clangir-offload-merge")
    if is_hip(file):
        cuda_counterpart = Path(str(file.parent).replace("/HIP/", "/CUDA/", 1))
        cmd.extend([
            "-x", "hip",
            f"--hip-path={hip_path}",
            f"--offload-arch={arch}",
            f"--rocm-device-lib-path={rocm_device_lib_path}",
            "-D__AMDGCN_WAVEFRONT_SIZE=64",
        ])
        if cuda_counterpart.is_dir():
            cmd.append(f"-I{cuda_counterpart}")
        link_flags = [f"-L{hip_path}/lib", "-lamdhip64"]
    else:
        cmd.extend([f"--cuda-path={cuda_root}", f"--cuda-gpu-arch={arch}"])
        link_flags = [f"-L{cuda_root}/lib64", "-lcudart"]

    # DOITGEN-style kernels declare `extern rtclock()` without including polybench.c.
    # `-x hip` above is sticky in the driver, so reset to extension-based language
    # detection before the object files or they'd be compiled as HIP source.
    extra_obj = [str(o) for o in polybench_objs] if _needs_polybench_c(file) else []
    flag = ["-DNO_CPU_REF"] if no_cpu_ref else []
    xflags = shlex.split(clang_flags) if clang_flags else []
    cmd.extend([
        "-std=c++17", "-O3", *flag, *xflags,
        str(source_file),
        f"-I{common_dir}", f"-I{file.parent}", f"-I{root}",
        "-lm", *link_flags, "-x", "none", *extra_obj, "-o", str(binary),
    ])

    env = os.environ.copy()
    if pipeline == "CIR":
        env["PATH"] = f"{clang.parent}:{env['PATH']}"

    proc = subprocess.run(cmd, text=True, capture_output=True, env=env)
    log.write_text(
        "COMMAND: " + shlex.join(cmd) + "\n\nSTDOUT:\n" + proc.stdout + "\nSTDERR:\n" + proc.stderr,
        encoding="utf-8",
    )
    ok = proc.returncode == 0
    first_error = ""
    if not ok:
        for line in (proc.stdout + proc.stderr).splitlines():
            if " error:" in line.lower() or "fatal" in line.lower():
                first_error = line.strip()
                break

    return PerfResult(
        benchmark=benchmark_name(file), source_set=source_set(root, file),
        file=file, pipeline=pipeline, arch=arch,
        compile_ok=ok, compile_log=log,
        binary=binary if ok else None,
        size=binary.stat().st_size if ok else None,
        times=[], wall_times=[], first_error=first_error,
    )


# ---------------------------------------------------------------------------
# Running
# ---------------------------------------------------------------------------

def run_binary(result: PerfResult, runs: int, warmup: int) -> None:
    """Run the binary in-place, filling result.times and result.wall_times. Mutates result."""
    assert result.binary is not None
    try:
        for _ in range(warmup):
            subprocess.run([str(result.binary)], capture_output=True, timeout=300)
        for _ in range(runs):
            start = time.perf_counter()
            proc = subprocess.run([str(result.binary)], capture_output=True, text=True, timeout=300)
            result.wall_times.append(time.perf_counter() - start)
            if proc.returncode != 0:
                break
            t = _parse_time(proc.stdout)
            if t is not None:
                result.times.append(t)
    except subprocess.TimeoutExpired:
        pass  # timed out mid-run; result.times holds whatever completed


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def markdown(results: list[PerfResult], root: Path, arch: str, log_dir: Path,
             runs: int, warmup: int, clangir_rev: str = "unknown", scripts_rev: str = "unknown",
             validate: bool = False) -> str:
    by_key        = {(r.file, r.pipeline): r for r in results}
    files_ordered = list(dict.fromkeys(r.file for r in results))
    compile_ok    = sum(1 for r in results if r.compile_ok)
    run_ok        = sum(1 for r in results if r.times)

    def fmt(v: float) -> str:
        return "—" if math.isnan(v) else f"{v:.4f}"

    def fmt_size(n: int | None) -> str:
        return "—" if n is None else f"{n / 1024:.1f} KiB"

    lines = [
        "PolyBench runtime performance: CIR vs OG.", "",
        f"- ClangIR commit: `{clangir_rev}`",
        f"- Scripts commit: `{scripts_rev}`",
        f"- arch: `{arch}`",
        f"- PolyBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        f"- Runs: {runs} timed + {warmup} warmup",
        f"- Compiled OK: `{compile_ok}/{len(results)}`",
        f"- Ran OK: `{run_ok}/{len(results)}`",
        *(["- **Validation: correctness check enabled**", ""] if validate else []),
        "",
        "## Environment",
        "",
        *provenance_lines(provenance()),
        "",
        "## Results (wall + GPU split, seconds)",
        "",
        "| Benchmark | Source set | CIR wall | CIR GPU | CIR host | OG wall | OG GPU | OG host | GPU CIR/OG | CIR size | OG size |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for file in files_ordered:
        cir = by_key.get((file, "CIR"))
        og  = by_key.get((file, "OG"))
        ref = cir or og
        assert ref is not None
        cir_m, cir_s = mean_stddev(cir.times if cir else [])
        og_m,  og_s  = mean_stddev(og.times  if og  else [])
        ratio = f"{cir_m / og_m:.3f}" if (not math.isnan(cir_m) and not math.isnan(og_m) and og_m > 0) else "—"
        cir_wm, _ = mean_stddev(cir.wall_times if cir else [])
        og_wm,  _ = mean_stddev(og.wall_times  if og  else [])
        cir_host = f"{cir_wm - cir_m:.4f}" if (not math.isnan(cir_wm) and not math.isnan(cir_m)) else "—"
        og_host  = f"{og_wm - og_m:.4f}" if (not math.isnan(og_wm) and not math.isnan(og_m)) else "—"
        cir_sz = cir.size if cir else None
        og_sz  = og.size  if og  else None
        lines.append(
            f"| {ref.benchmark} | {ref.source_set} |"
            f" {fmt(cir_wm)} | {fmt(cir_m)} | {cir_host} |"
            f" {fmt(og_wm)} | {fmt(og_m)} | {og_host} | {ratio} |"
            f" {fmt_size(cir_sz)} | {fmt_size(og_sz)} |"
        )

    ratios = []
    for file in files_ordered:
        cir = by_key.get((file, "CIR")); og = by_key.get((file, "OG"))
        cir_m, _ = mean_stddev(cir.times if cir else [])
        og_m,  _ = mean_stddev(og.times  if og  else [])
        if not math.isnan(cir_m) and not math.isnan(og_m) and cir_m > 0 and og_m > 0:
            ratios.append(cir_m / og_m)
    if ratios:
        from statistics import geometric_mean
        gm = geometric_mean(ratios)
        lines += ["", f"**Total GPU CIR/OG (geomean):** `{gm:.4f}`", ""]

    failures = [r for r in results if not r.compile_ok or not r.times]
    if failures:
        lines += ["", "## Failures", ""]
        for r in failures:
            reason = "compile failed" if not r.compile_ok else "no timing output"
            lines += [f"- [{r.pipeline}] `{r.file}` — {reason}"]
            if r.first_error:
                lines += [f"  - error: `{r.first_error}`"]
            lines += [f"  - log: `{r.compile_log}`"]

    val_failures = [r for r in results if r.misses is not None and r.misses != 0]
    if val_failures:
        lines += ["", "## Correctness failures (validation builds)", ""]
        for r in val_failures:
            lines += [f"- [{r.pipeline}] `{r.benchmark}` — {r.misses} mismatches / `{r.file}`"]

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    _rocm = find_rocm_root()

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    src = parser.add_mutually_exclusive_group()
    src.add_argument("--hip",  action="store_true", help="Run HIP benchmarks only")
    src.add_argument("--cuda", action="store_true", help="Run CUDA benchmarks only")

    parser.add_argument("--clang",                type=path_arg, default=find_clang())
    parser.add_argument("--polybench-root",       type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root",            type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--hip-path",             type=path_arg, default=_rocm)
    parser.add_argument("--rocm-device-lib-path", type=path_arg, default=find_rocm_device_lib(_rocm))
    parser.add_argument("--gcc-install-dir",      type=path_arg, default=find_gcc_install())
    parser.add_argument("--merge",      type=bool, default=False)
    parser.add_argument("--arch",      default="sm_86",  help="GPU arch (default: sm_86)")
    parser.add_argument("--runs",      type=int, default=5, help="Timed runs per benchmark (default: 5)")
    parser.add_argument("--warmup",    type=int, default=1, help="Warmup runs before timing (default: 1)")
    parser.add_argument("--log-dir",   type=path_arg, default=Path("~/polybench-gpu-audit/temp/runtime"))
    parser.add_argument("--build-dir", type=path_arg, default=Path("~/polybench-gpu-audit/temp/runtime/build"))
    parser.add_argument("--limit",     type=int, default=0, help="Cap number of source files")
    parser.add_argument("--validate",  action="store_true", help="Build once without NO_CPU_REF and check correctness")
    parser.add_argument("--clang-flags", default="", help="Extra flags forwarded to every clang compile line")
    parser.add_argument("-j", "--jobs", type=int, default=4, help="Parallel compile jobs (default: 4)")

    args = parser.parse_args(argv)
    args.polybench_root = args.polybench_root.expanduser().resolve()
    args.cuda_root      = args.cuda_root.expanduser().resolve()
    args.log_dir        = args.log_dir.expanduser().resolve()
    args.build_dir      = args.build_dir.expanduser().resolve()

    errors = []
    if not args.clang.exists():          errors.append(f"--clang not found: {args.clang}")
    if not args.polybench_root.exists(): errors.append(f"--polybench-root not found: {args.polybench_root}")
    if args.jobs < 1:                    errors.append("--jobs must be >= 1")
    if args.runs < 1:                    errors.append("--runs must be >= 1")
    if args.warmup < 0:                  errors.append("--warmup must be >= 0")
    if errors:
        for e in errors: print(f"error: {e}", file=sys.stderr)
        return 2

    args.log_dir.mkdir(parents=True, exist_ok=True)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    for old in args.log_dir.glob("*.log"):
        old.unlink()

    common_dir = args.polybench_root / "common"
    if not common_dir.is_dir():
        print(f"error: common dir not found: {common_dir}", file=sys.stderr)
        return 2

    try:
        pb_objs = _compile_polybench_objs(args.clang, common_dir, args.gcc_install_dir, args.build_dir)
    except RuntimeError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    all_files = sorted(
        (f for pattern in ("*.cu", "*.hip.cpp")
         for f in args.polybench_root.rglob(pattern)
         if ".ipynb_checkpoints" not in f.parts
         and "polybenchCodesCudaOpenClHMPPOpenAcc" not in f.parts),
        key=lambda p: p.name,
    )
    if args.hip:    files = [f for f in all_files if is_hip(f)]
    elif args.cuda: files = [f for f in all_files if not is_hip(f)]
    else:           files = all_files
    if args.limit:  files = files[: args.limit]
    if not files:
        print("error: no source files found", file=sys.stderr)
        return 2

    jobs       = [(f, p) for f in files for p in ("CIR", "OG")]
    total_jobs = len(jobs)
    width      = len(str(total_jobs))

    # Phase 1: compile in parallel
    print(f"Compiling {total_jobs} binaries with -j{args.jobs}...")
    results_map: dict[tuple[Path, str], PerfResult] = {}
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(
                compile_one,
                args.clang, args.polybench_root,
                args.cuda_root, args.hip_path, args.rocm_device_lib_path,
                args.gcc_install_dir, args.arch, pipeline, file,
                common_dir, pb_objs, args.build_dir, args.log_dir, args.merge,
                clang_flags=args.clang_flags,
            ): (file, pipeline)
            for file, pipeline in jobs
        }
        done = 0
        for future in as_completed(futures):
            file, pipeline = futures[future]
            done += 1
            try:
                r = future.result()
            except Exception as exc:
                print(f"[{done:0{width}d}/{total_jobs}] {pipeline} ERROR {file.name}: {exc}", file=sys.stderr)
                raise
            results_map[(file, pipeline)] = r
            print(f"[{done:0{width}d}/{total_jobs}] {pipeline} {'ok' if r.compile_ok else 'FAIL'} {file.relative_to(args.polybench_root)}")

    # Phase 2: run (parallel — CUDA processes serialize at hardware level, so timing
    # is noisier than sequential but total wall time is much shorter)
    runnable = [results_map[(f, p)] for f, p in jobs if results_map[(f, p)].compile_ok]
    rw = len(str(len(runnable)))
    print(f"\nRunning {len(runnable)} binaries ({args.warmup} warmup + {args.runs} timed, -j{args.jobs})...")
    done = 0
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(run_binary, r, args.runs, args.warmup): r for r in runnable}
        for future in as_completed(futures):
            future.result()
            r = futures[future]
            done += 1
            m, s = mean_stddev(r.times)
            wm, _ = mean_stddev(r.wall_times) if r.wall_times else (float("nan"), float("nan"))
            status = f"gpu={m:.4f}s wall={wm:.4f}s" if r.times else "no timing output"
            print(f"[{done:0{rw}d}/{len(runnable)}] {r.pipeline}/{r.arch} {r.benchmark} {status}")

    results     = [results_map[(f, p)] for f, p in jobs if (f, p) in results_map]

    # Phase 3: validation — compile without NO_CPU_REF, run once, check mismatches
    if args.validate:
        print(f"\nValidating {total_jobs} binaries (correctness check, no CPU ref exclusion)...")
        with ThreadPoolExecutor(max_workers=args.jobs) as executor:
            v_futures = {
                executor.submit(
                    compile_one,
                    args.clang, args.polybench_root,
                    args.cuda_root, args.hip_path, args.rocm_device_lib_path,
                    args.gcc_install_dir, args.arch, pipeline, file,
                    common_dir, pb_objs, args.build_dir, args.log_dir, args.merge,
                    no_cpu_ref=False, clang_flags=args.clang_flags,
                ): (file, pipeline)
                for file, pipeline in jobs
            }
            v_done = 0
            for future in as_completed(v_futures):
                file, pipeline = v_futures[future]
                v_done += 1
                try:
                    vr = future.result()
                except Exception as exc:
                    print(f"[{v_done:0{width}d}/{total_jobs}] v/{pipeline} ERROR {file.name}: {exc}", file=sys.stderr)
                    raise
                if vr.compile_ok:
                    proc = subprocess.run([str(vr.binary)], capture_output=True, text=True, timeout=600)
                    m = _MISSES.search(proc.stdout)
                    misses = int(m.group(1)) if m else 0
                    trim = results_map[(file, pipeline)]
                    trim.misses = misses
                    print(f"[{v_done:0{width}d}/{total_jobs}] v/{pipeline} misses={misses}", end="")
                    print(" FAIL" if misses != 0 else " ok")
                else:
                    print(f"[{v_done:0{width}d}/{total_jobs}] v/{pipeline} compile FAIL {file.relative_to(args.polybench_root)}")

    clangir_rev = git_rev(args.clang.parent.parent.parent)
    scripts_rev = git_rev(Path(__file__).parent)
    report      = markdown(results, args.polybench_root, args.arch, args.log_dir, args.runs, args.warmup,
                           clangir_rev=clangir_rev, scripts_rev=scripts_rev, validate=args.validate)
    report_path = args.log_dir / "runtime_summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")

    # Raw per-run samples, so plots / CIs / significance tests can be redone offline.
    json_path = args.log_dir / "runtime_results.json"
    json_path.write_text(json.dumps({
        "kind":           "runtime",
        "arch":           args.arch,
        "runs":           args.runs,
        "warmup":         args.warmup,
        "jobs":           args.jobs,
        "clangir_commit": clangir_rev,
        "scripts_commit": scripts_rev,
        "polybench_root": str(args.polybench_root),
        "environment":    provenance(),
        "no_cpu_ref":     True,   # timing mode: CPU reference disabled
        "validate":       args.validate,
        "results": [{
            "benchmark":    r.benchmark,
            "source_set":   r.source_set,
            "file":         str(r.file),
            "pipeline":     r.pipeline,
            "arch":         r.arch,
            "compile_ok":   r.compile_ok,
            "binary_bytes": r.size,
            "times":        r.times,
            "wall_times":   r.wall_times,
            "misses":       r.misses,
            "first_error":  r.first_error,
        } for r in results],
    }, indent=2) + "\n", encoding="utf-8")

    print()
    print(report)
    print(f"\nReport written to {report_path}")
    print(f"Raw samples written to {json_path}")

    artifacts = args.log_dir / "artifacts"
    artifacts.mkdir(exist_ok=True)
    binary_count = 0
    for r in results:
        if r.compile_ok and r.binary and r.binary.exists():
            shutil.copy2(r.binary, artifacts / r.binary.name)
            binary_count += 1
    print(f"Artifacts ({binary_count} binaries) saved to {artifacts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
