#!/usr/bin/env python3
"""CIR vs OG compile-phase timing breakdown for PolyBench CUDA/HIP benchmarks.

Compiles each benchmark with -O3, host+device, and timing flags:
  CIR: -fclangir -ftime-report -mllvm -time-passes
  OG:  -ftime-report -mllvm -time-passes

Pass --device-only to restore the old device-only compilation mode.

Each benchmark is compiled --warmup times (default 2) before the timed run
to avoid cold-cache noise.

Examples:
  # CUDA single-arch (H100, sm_90), full host+device compilation
  python3 run_compile.py --cuda \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \\
      -j 1

  # CUDA multi-arch (sm_80, sm_86, sm_89, sm_90)
  python3 run_compile.py --cuda --multi-arch \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \\
      -j $(nproc)

  # HIP single-arch (gfx942)
  python3 run_compile.py --hip \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --hip-path /opt/rocm --rocm-device-lib-path /opt/rocm/amdgcn/bitcode \\
      -j $(nproc)

  # HIP multi-arch (gfx906, gfx908, gfx90a, gfx942)
  python3 run_compile.py --hip --multi-arch \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --hip-path /opt/rocm --rocm-device-lib-path /opt/rocm/amdgcn/bitcode \\
      -j $(nproc)
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

from polybench_common import (
    CUDA_MULTI_ARCHES,
    HIP_MULTI_ARCHES,
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

_SECTION_SEP = re.compile(r"^===-{3,}")
_EXEC_TIME   = re.compile(r"Total Execution Time:\s*[\d.]+\s*seconds\s*\(([\d.]+)\s*wall")

_PHASE_ALIASES = {
    "clang time report":            "Frontend+IRGen",
    "clang front-end time report":  "Frontend+IRGen",
    "pass execution timing report": "LLVM-passes",
    "analysis execution timing":    "LLVM-analysis",
    "instruction selection":        "ISel",
    "register allocation":          "RegAlloc",
    "mir parsing and codegen time": "MIR",
    "mlir pass manager":            "MLIR-passes",
    "mlir module pass manager":     "MLIR-passes",
}


@dataclass
class TimingResult:
    benchmark:      str
    source_set:     str
    file:           Path
    pipeline:       str   # "CIR" or "OG"
    arch:           str
    ok:             bool
    elapsed:         float   # mean wall time across timed samples
    elapsed_stddev:  float
    elapsed_median:  float
    elapsed_samples: list[float]   # every timed sample, for offline stats
    samples:         int
    phases:         dict[str, float]   # mean per-phase time across timed samples
    log:            Path
    command:        list[str]
    first_error:    str = ""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _mean_phases(samples: list[dict[str, float]]) -> dict[str, float]:
    keys = {k for s in samples for k in s}
    return {k: sum(s[k] for s in samples if k in s) / sum(1 for s in samples if k in s) for k in keys}

def _normalize_phase(raw: str) -> str:
    key = raw.lower().strip()
    for fragment, short in _PHASE_ALIASES.items():
        if fragment in key:
            return short
    return raw[:35] if len(raw) > 35 else raw

def parse_phases(stderr: str) -> dict[str, float]:
    """Extract per-phase wall times from -ftime-report / -time-passes output.

    A full CUDA/HIP compilation runs two cc1 invocations (device + host), each
    emitting its own complete block of reports ending with its "Clang time
    report". The LLVM pass/analysis/ISel/RegAlloc sections are sub-intervals of
    the same cc1's clang report (its Optimizer + Machine codegen lines), so
    summing them with the clang total would double-count. Per cc1 block we
    instead attribute Frontend+IRGen as clang_total minus the LLVM sections in
    that block, giving a complete, non-overlapping partition of the reported
    time. Anything still unaccounted (ptxas, fatbinary, driver) shows up as
    unattributed.
    """
    phases: dict[str, float] = {}
    lines = stderr.splitlines()
    block: list[tuple[str, float]] = []

    def flush() -> None:
        clang_total = sum(v for n, v in block if n == "Frontend+IRGen")
        llvm_sum    = sum(v for n, v in block if n != "Frontend+IRGen")
        for n, v in block:
            if n != "Frontend+IRGen":
                phases[n] = phases.get(n, 0.0) + v
        if clang_total:
            phases["Frontend+IRGen"] = phases.get("Frontend+IRGen", 0.0) + max(0.0, clang_total - llvm_sum)
        block.clear()

    i = 0
    while i < len(lines):
        if _SECTION_SEP.match(lines[i].strip()):
            j = i + 1
            while j < len(lines) and (not lines[j].strip() or _SECTION_SEP.match(lines[j].strip())):
                j += 1
            if j >= len(lines):
                i = j
                continue
            name = _normalize_phase(lines[j].strip())
            k_start = j + 1
            while k_start < len(lines) and _SECTION_SEP.match(lines[k_start].strip()):
                k_start += 1
            for k in range(k_start, min(k_start + 200, len(lines))):
                m = _EXEC_TIME.search(lines[k])
                if m:
                    block.append((name, float(m.group(1))))
                    if name == "Frontend+IRGen":
                        flush()  # clang report ends this cc1's block
                    break
                if _SECTION_SEP.match(lines[k].strip()):
                    break
            i = j + 1
        else:
            i += 1
    flush()
    return phases

def discover_include_dirs(files: list[Path]) -> list[Path]:
    suffixes = {".h", ".hpp", ".cuh", ".hip"}
    dirs: set[Path] = set()
    for d in {f.parent for f in files}:
        for p in d.iterdir():
            if p.is_file() and p.suffix in suffixes:
                dirs.add(p.parent)
                break
    return sorted(dirs)


# ---------------------------------------------------------------------------
# Compilation
# ---------------------------------------------------------------------------

def timing_compile_one(
    clang:                Path,
    root:                 Path,
    cuda_root:            Path,
    hip_path:             Path,
    rocm_device_lib_path: Path,
    gcc_install_dir:      Path,
    arch:                 str,
    pipeline:             str,
    file:                 Path,
    include_dirs:         list[Path],
    log_dir:              Path,
    warmup:               int = 2,
    samples:              int = 1,
    device_only:          bool = False,
    clang_flags:          str = "",
) -> TimingResult:
    log = log_dir / f"{safe_name(root, file)}.{pipeline.lower()}.{arch}.log"
    cmd = [str(clang)]
    if pipeline == "CIR":
        cmd.append("-fclangir")
        cmd.extend(["-Xclang", "-clangir-enable-call-conv-lowering"])
    cmd.append(f"--gcc-install-dir={gcc_install_dir}")

    obj_path = log_dir / f"{safe_name(root, file)}.{pipeline.lower()}.{arch}.o"
    if is_hip(file):
        cuda_counterpart = Path(str(file.parent).replace("/HIP/", "/CUDA/", 1))
        cmd.extend([
            "-x", "hip",
            f"--hip-path={hip_path}",
            f"--offload-arch={arch}",
            f"--rocm-device-lib-path={rocm_device_lib_path}",
            "-D__AMDGCN_WAVEFRONT_SIZE=64",
        ])
        if device_only:
            cmd.append("--offload-device-only")
        if cuda_counterpart.is_dir():
            cmd.append(f"-I{cuda_counterpart}")
    else:
        cmd.extend([
            f"--cuda-path={cuda_root}",
            f"--cuda-gpu-arch={arch}",
        ])
        if device_only:
            cmd.append("--cuda-device-only")

    cmd.extend(["-std=c++17", "-O3", "-ftime-report", "-mllvm", "-time-passes"])
    if clang_flags:
        cmd.extend(shlex.split(clang_flags))
    cmd.extend(["-c", str(file), f"-I{root}", f"-I{file.parent}", "-o", str(obj_path)])
    cmd.extend(f"-I{d}" for d in include_dirs)

    env = os.environ.copy()
    if pipeline == "CIR":
        env["PATH"] = f"{clang.parent}:{env['PATH']}"

    for _ in range(warmup):
        subprocess.run(cmd, capture_output=True, env=env)

    elapsed_samples: list[float] = []
    phase_samples: list[dict[str, float]] = []
    proc = None
    for _ in range(samples):
        start = time.perf_counter()
        proc = subprocess.run(cmd, text=True, capture_output=True, env=env)
        elapsed_samples.append(time.perf_counter() - start)
        if proc.returncode != 0:
            break
        phase_samples.append(parse_phases(proc.stderr))

    assert proc is not None
    ok = proc.returncode == 0
    elapsed, elapsed_stddev = mean_stddev(elapsed_samples) if ok else (elapsed_samples[-1], 0.0)
    phases = _mean_phases(phase_samples) if phase_samples else {}
    first_error = ""
    if not ok:
        for line in (proc.stdout + proc.stderr).splitlines():
            if " error:" in line.lower() or "fatal" in line.lower():
                first_error = line.strip()
                break

    log.write_text(
        "COMMAND: " + shlex.join(cmd)
        + f"\n\nSAMPLES (wall seconds): {[f'{t:.4f}' for t in elapsed_samples]}"
        + "\n\nSTDOUT (last sample):\n" + proc.stdout + "\nSTDERR (last sample):\n" + proc.stderr,
        encoding="utf-8",
    )

    try:
        obj_path.unlink(missing_ok=True)
    except OSError:
        pass

    return TimingResult(
        benchmark=benchmark_name(file), source_set=source_set(root, file),
        file=file, pipeline=pipeline, arch=arch, ok=ok,
        elapsed=elapsed, elapsed_stddev=elapsed_stddev,
        elapsed_median=median(elapsed_samples) if ok else float("nan"),
        elapsed_samples=elapsed_samples, samples=len(elapsed_samples),
        phases=phases, log=log, command=cmd, first_error=first_error,
    )


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def _phase_rows(results: list[TimingResult]) -> list[str]:
    """Phase averages table (header + rows) over the given result set."""
    all_phases = sorted({p for r in results for p in r.phases})
    lines = ["| Phase | CIR avg | OG avg | delta |", "|---|---:|---:|---:|"]
    for phase in all_phases:
        ct = [r.phases[phase] for r in results if r.pipeline == "CIR" and r.ok and phase in r.phases]
        ot = [r.phases[phase] for r in results if r.pipeline == "OG"  and r.ok and phase in r.phases]
        ca = sum(ct) / len(ct) if ct else None
        oa = sum(ot) / len(ot) if ot else None
        d  = (f"+{ca-oa:.3f}" if ca >= oa else f"{ca-oa:.3f}") if (ca is not None and oa is not None) else "—"
        lines.append(
            f"| {phase} | {f'{ca:.3f}' if ca is not None else '—'} | {f'{oa:.3f}' if oa is not None else '—'} | {d} |"
        )
    ct = [r.elapsed for r in results if r.pipeline == "CIR" and r.ok]
    ot = [r.elapsed for r in results if r.pipeline == "OG"  and r.ok]
    if ct and ot:
        ca, oa = sum(ct) / len(ct), sum(ot) / len(ot)
        d = f"+{ca-oa:.3f}" if ca >= oa else f"{ca-oa:.3f}"
        lines.append(f"| **Total (wall)** | **{ca:.3f}** | **{oa:.3f}** | **{d}** |")
    return lines


def _arch_section(results: list[TimingResult], root: Path, arch: str) -> list[str]:
    """Full markdown section for one arch: pass/fail counts, phase table, per-benchmark table."""
    by_key       = {(r.file, r.pipeline): r for r in results}
    files_ordered: list[Path] = list(dict.fromkeys(r.file for r in results))
    cir_ok = sum(1 for f in files_ordered if by_key.get((f, "CIR")) and by_key[(f, "CIR")].ok)
    og_ok  = sum(1 for f in files_ordered if by_key.get((f, "OG"))  and by_key[(f, "OG")].ok)

    all_phases = sorted({p for r in results for p in r.phases})
    header = "| Benchmark | Source set |" + "".join(f" CIR {ph} | OG {ph} |" for ph in all_phases) + " CIR total | CIR σ | CIR med | OG total | OG σ | OG med | CIR/OG |"
    sep    = "|---|---:|" + "---:|---:|" * len(all_phases) + "---:|---:|---:|---:|---:|---:|---:|"

    lines = [
        f"### arch: `{arch}`", "",
        f"- CIR compiled OK: `{cir_ok}/{len(files_ordered)}`",
        f"- OG compiled OK: `{og_ok}/{len(files_ordered)}`",
        "", *_phase_rows(results), "", header, sep,
    ]
    for file in files_ordered:
        cir = by_key.get((file, "CIR"))
        og  = by_key.get((file, "OG"))
        ref = cir or og
        assert ref is not None
        row = f"| {ref.benchmark} | {ref.source_set} |"
        for ph in all_phases:
            row += f" {f'{cir.phases[ph]:.3f}' if cir and cir.ok and ph in cir.phases else '—'}"
            row += f" | {f'{og.phases[ph]:.3f}' if og  and og.ok  and ph in og.phases  else '—'} |"
        cir_t  = cir.elapsed        if cir and cir.ok else None
        cir_sd = cir.elapsed_stddev if cir and cir.ok else None
        og_t   = og.elapsed         if og  and og.ok  else None
        og_sd  = og.elapsed_stddev  if og  and og.ok  else None
        ratio = f"{cir_t / og_t:.3f}" if (cir_t is not None and og_t is not None and og_t > 0) else "—"
        cir_md = cir.elapsed_median if cir and cir.ok else None
        og_md  = og.elapsed_median  if og  and og.ok  else None
        row += (
            f" {f'{cir_t:.3f}' if cir_t is not None else '—'} |"
            f" {f'{cir_sd:.3f}' if cir_sd is not None else '—'} |"
            f" {f'{cir_md:.3f}' if cir_md is not None else '—'} |"
            f" {f'{og_t:.3f}' if og_t is not None else '—'} |"
            f" {f'{og_sd:.3f}' if og_sd is not None else '—'} |"
            f" {f'{og_md:.3f}' if og_md is not None else '—'} |"
            f" {ratio} |"
        )
        lines.append(row)
    return lines


def markdown(results: list[TimingResult], root: Path, arch_tag: str, log_dir: Path, warmup: int, samples: int,
             clangir_rev: str = "unknown", scripts_rev: str = "unknown") -> str:
    arches    = sorted(set(r.arch for r in results))
    multi     = len(arches) > 1
    cir_ok    = sum(1 for r in results if r.pipeline == "CIR" and r.ok)
    og_ok     = sum(1 for r in results if r.pipeline == "OG"  and r.ok)
    total_cir = sum(1 for r in results if r.pipeline == "CIR")
    total_og  = sum(1 for r in results if r.pipeline == "OG")

    lines = [
        "PolyBench compile-phase timing: CIR vs OG.", "",
        f"- ClangIR commit: `{clangir_rev}`",
        f"- Scripts commit: `{scripts_rev}`",
        f"- arch: `{arch_tag}`",
        f"- PolyBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        "- Flags: `-O3 host+device -ftime-report -mllvm -time-passes`",
        f"- Warmup runs per benchmark: {warmup}",
        f"- Timed samples per benchmark: {samples}",
        f"- CIR compiled OK: `{cir_ok}/{total_cir}`",
        f"- OG compiled OK: `{og_ok}/{total_og}`",
        "",
        "## Environment",
        "",
        *provenance_lines(provenance()),
        "",
        "## Phase averages (wall seconds, over successful compilations)",
        *(["_(averaged across all architectures)_", ""] if multi else [""]),
        *_phase_rows(results),
        "",
        "## Per-arch breakdown" if multi else "## Per-benchmark breakdown",
        "",
    ]
    for arch in arches:
        lines.extend(_arch_section([r for r in results if r.arch == arch], root, arch))
        lines.append("")

    failures = [r for r in results if not r.ok]
    if failures:
        lines += ["## Failures", ""]
        for r in failures:
            tag = f"{r.pipeline}/{r.arch}" if multi else r.pipeline
            lines += [
                f"- [{tag}] `{r.file}`",
                f"  - error: `{r.first_error or 'see log'}`",
                f"  - log: `{r.log}`",
            ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    _rocm = find_rocm_root()

    parser = argparse.ArgumentParser(description=__doc__)

    src = parser.add_mutually_exclusive_group()
    src.add_argument("--hip",  action="store_true", help="Time HIP benchmarks only")
    src.add_argument("--cuda", action="store_true", help="Time CUDA benchmarks only")

    parser.add_argument("--clang",                type=path_arg, default=find_clang())
    parser.add_argument("--polybench-root",       type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root",            type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--hip-path",             type=path_arg, default=_rocm)
    parser.add_argument("--rocm-device-lib-path", type=path_arg, default=find_rocm_device_lib(_rocm))
    parser.add_argument("--gcc-install-dir",      type=path_arg, default=find_gcc_install())
    parser.add_argument("--cuda-arch",   default="sm_86",  help="CUDA GPU arch (single-arch mode)")
    parser.add_argument("--hip-arch",    default="gfx942", help="HIP/AMDGPU arch (single-arch mode)")
    parser.add_argument("--multi-arch",  action="store_true",
                        help=f"Compile for all arches per target "
                             f"(HIP: {HIP_MULTI_ARCHES}, CUDA: {CUDA_MULTI_ARCHES})")
    parser.add_argument("--arches", help="Comma-separated arch list overriding the --multi-arch defaults")
    parser.add_argument("--warmup",  type=int, default=2,  help="Warm-up runs before timed samples (default: 2)")
    parser.add_argument("--samples", type=int, default=5,  help="Timed compile repetitions per benchmark, reported as mean +/- stddev (default: 5)")
    parser.add_argument("--log-dir", type=path_arg, default=Path("~/polybench-gpu-audit/temp/compile"))
    parser.add_argument("--limit",   type=int, default=0,  help="Cap number of source files")
    parser.add_argument("--device-only", action="store_true", help="Device-only compilation (old default)")
    parser.add_argument("--clang-flags", default="", help="Extra flags forwarded to every clang compile line")
    parser.add_argument("-j", "--jobs", type=int, default=4)

    args = parser.parse_args(argv)
    args.polybench_root = args.polybench_root.expanduser().resolve()
    args.cuda_root      = args.cuda_root.expanduser().resolve()
    args.log_dir        = args.log_dir.expanduser().resolve()

    errors = []
    if not args.clang.exists():          errors.append(f"--clang not found: {args.clang}")
    if not args.polybench_root.exists(): errors.append(f"--polybench-root not found: {args.polybench_root}")
    if args.jobs < 1:                    errors.append("--jobs must be >= 1")
    if args.warmup < 0:                  errors.append("--warmup must be >= 0")
    if args.samples < 1:                 errors.append("--samples must be >= 1")
    if errors:
        for e in errors: print(f"error: {e}", file=sys.stderr)
        return 2

    args.log_dir.mkdir(parents=True, exist_ok=True)
    for old in args.log_dir.glob("*.log"):
        old.unlink()
    for old in args.log_dir.glob("*.o"):
        old.unlink(missing_ok=True)

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

    if args.limit: files = files[: args.limit]
    if not files:
        print("error: no source files found", file=sys.stderr)
        return 2

    override    = [a.strip() for a in args.arches.split(",") if a.strip()] if args.arches else None
    hip_arches  = (override or HIP_MULTI_ARCHES)  if args.multi_arch else [args.hip_arch]
    cuda_arches = (override or CUDA_MULTI_ARCHES) if args.multi_arch else [args.cuda_arch]
    include_dirs = discover_include_dirs(files)

    jobs = [
        (file, pipeline, arch)
        for file in files
        for pipeline in ("CIR", "OG")
        for arch in (hip_arches if is_hip(file) else cuda_arches)
    ]
    total_jobs = len(jobs)
    width      = len(str(total_jobs))

    results_by_key: dict[tuple[Path, str, str], TimingResult] = {}
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(
                timing_compile_one,
                args.clang, args.polybench_root,
                args.cuda_root, args.hip_path, args.rocm_device_lib_path,
                args.gcc_install_dir, arch, pipeline, file,
                include_dirs, args.log_dir, args.warmup, args.samples,
                args.device_only, args.clang_flags,
            ): (file, pipeline, arch)
            for file, pipeline, arch in jobs
        }
        completed = 0
        for future in as_completed(futures):
            file, pipeline, arch = futures[future]
            completed += 1
            try:
                result = future.result()
            except Exception as exc:
                print(
                    f"[{completed:0{width}d}/{total_jobs}] {pipeline}/{arch} ERROR"
                    f" {file.relative_to(args.polybench_root)}: {exc}",
                    file=sys.stderr,
                )
                raise
            results_by_key[(file, pipeline, arch)] = result
            status        = "ok" if result.ok else "FAIL"
            phase_summary = "  ".join(f"{k}={v:.2f}s" for k, v in result.phases.items())
            print(
                f"[{completed:0{width}d}/{total_jobs}] {pipeline}/{arch} {status}"
                f" {file.relative_to(args.polybench_root)}"
                f" wall={result.elapsed:.3f}s+/-{result.elapsed_stddev:.3f}s  {phase_summary}"
            )

    results = [
        results_by_key[(file, pipeline, arch)]
        for file, pipeline, arch in jobs
        if (file, pipeline, arch) in results_by_key
    ]

    if args.multi_arch:
        active_hip, active_cuda = ",".join(hip_arches), ",".join(cuda_arches)
    else:
        active_hip, active_cuda = args.hip_arch, args.cuda_arch
    arch_tag = (
        f"hip:{active_hip}"   if args.hip  else
        f"cuda:{active_cuda}" if args.cuda else
        f"cuda:{active_cuda} hip:{active_hip}"
    )

    clangir_rev = git_rev(args.clang.parent.parent.parent)
    scripts_rev = git_rev(Path(__file__).parent)
    report      = markdown(results, args.polybench_root, arch_tag, args.log_dir, args.warmup, args.samples,
                           clangir_rev=clangir_rev, scripts_rev=scripts_rev)
    report_path = args.log_dir / "compile_summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")

    # Raw per-sample data, so plots / CIs / significance tests can be redone offline.
    json_path = args.log_dir / "compile_results.json"
    json_path.write_text(json.dumps({
        "kind":          "compile",
        "arch_tag":      arch_tag,
        "warmup":        args.warmup,
        "samples":       args.samples,
        "jobs":          args.jobs,
        "device_only":   args.device_only,
        "clangir_commit": clangir_rev,
        "scripts_commit": scripts_rev,
        "polybench_root": str(args.polybench_root),
        "environment":   provenance(),
        "results": [{
            "benchmark":       r.benchmark,
            "source_set":      r.source_set,
            "file":            str(r.file),
            "pipeline":        r.pipeline,
            "arch":            r.arch,
            "ok":              r.ok,
            "elapsed_mean":    r.elapsed,
            "elapsed_stddev":  r.elapsed_stddev,
            "elapsed_median":  r.elapsed_median,
            "elapsed_samples": r.elapsed_samples,
            "phases_mean":     r.phases,
            "command":         r.command,
            "first_error":     r.first_error,
        } for r in results],
    }, indent=2) + "\n", encoding="utf-8")

    print()
    print(report)
    print(f"\nReport written to {report_path}")
    print(f"Raw samples written to {json_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
