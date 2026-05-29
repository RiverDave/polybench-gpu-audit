#!/usr/bin/env python3
"""CIR vs OG compile-phase timing breakdown for PolyBench CUDA/HIP benchmarks.

Compiles each benchmark with -O3, device-only, and timing flags:
  CIR: -fclangir -ftime-report -mllvm -time-passes -mmlir --mlir-pass-statistics
  OG:  -ftime-report -mllvm -time-passes

Each benchmark is compiled --warmup times (default 2) before the timed run
to avoid cold-cache noise.
"""

from __future__ import annotations

import argparse
import os
import re
import shlex
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path


BENCHMARK_NAMES = {
    "2DCONV": "convolution-2d", "2MM": "2mm", "3DCONV": "convolution-3d",
    "3MM": "3mm", "ADI": "adi", "ATAX": "atax", "BICG": "bicg",
    "CORR": "correlation", "COVAR": "covariance", "DOITGEN": "doitgen",
    "FDTD-2D": "fdtd-2d", "GEMM": "gemm", "GEMVER": "gemver",
    "GESUMMV": "gesummv", "GRAMSCHM": "gramschmidt",
    "JACOBI1D": "jacobi-1d-imper", "JACOBI2D": "jacobi-2d-imper",
    "LU": "lu", "MVT": "mvt", "SYR2K": "syr2k", "SYRK": "syrk",
}

_HIP_MULTI_ARCHES  = ["gfx906", "gfx908", "gfx90a", "gfx942"]
_CUDA_MULTI_ARCHES = ["sm_80",  "sm_86",  "sm_89",  "sm_90"]

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
    benchmark:   str
    source_set:  str
    file:        Path
    pipeline:    str   # "CIR" or "OG"
    arch:        str
    ok:          bool
    elapsed:     float
    phases:      dict[str, float]
    log:         Path
    command:     list[str]
    first_error: str = ""


# ---------------------------------------------------------------------------
# Auto-detection
# ---------------------------------------------------------------------------

def _find_rocm_root() -> Path:
    candidates = sorted(Path("/opt").glob("rocm-[0-9]*"), reverse=True)
    for c in candidates:
        if (c / "include/hip/hip_runtime.h").exists():
            return c
    return Path("/opt/rocm")

def _find_gcc_install() -> Path:
    for crt in sorted(Path("/usr/lib/gcc").glob("*/*/crtbegin.o"), reverse=True):
        return crt.parent
    return Path("/usr/lib/gcc/x86_64-linux-gnu/11")

def _find_rocm_device_lib(rocm: Path) -> Path:
    v6 = sorted(Path("/opt").glob("rocm-6*/amdgcn/bitcode"), reverse=True)
    return v6[0] if v6 else rocm / "amdgcn/bitcode"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def path_arg(s: str) -> Path:
    return Path(s).expanduser().resolve()

def safe_name(root: Path, file: Path) -> str:
    return "_".join(file.relative_to(root).parts)

def benchmark_name(file: Path) -> str:
    return BENCHMARK_NAMES.get(file.parent.name.upper(), file.stem.lower())

def is_hip(file: Path) -> bool:
    return ".hip" in file.suffixes or file.suffix == ".hip"

def source_set(root: Path, file: Path) -> str:
    parts = file.relative_to(root).parts
    if parts[:1] == ("HIP",):   return "HIP"
    if parts[:1] == ("CUDA",):  return "CUDA"
    if len(parts) >= 2 and parts[0] == "polybenchCodesCudaOpenClHMPPOpenAcc":
        return "CUDA duplicate"
    return parts[0] if parts else "unknown"

def _normalize_phase(raw: str) -> str:
    key = raw.lower().strip()
    for fragment, short in _PHASE_ALIASES.items():
        if fragment in key:
            return short
    return raw[:35] if len(raw) > 35 else raw

def parse_phases(stderr: str) -> dict[str, float]:
    phases: dict[str, float] = {}
    lines = stderr.splitlines()
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
                    phases.setdefault(name, float(m.group(1)))
                    break
                if _SECTION_SEP.match(lines[k].strip()):
                    break
            i = j + 1
        else:
            i += 1
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
) -> TimingResult:
    log = log_dir / f"{safe_name(root, file)}.{pipeline.lower()}.{arch}.log"
    cmd = [str(clang)]
    if pipeline == "CIR":
        cmd.append("-fclangir")
    cmd.append(f"--gcc-install-dir={gcc_install_dir}")

    if is_hip(file):
        cuda_counterpart = Path(str(file.parent).replace("/HIP/", "/CUDA/", 1))
        cmd.extend([
            "-x", "hip",
            f"--hip-path={hip_path}",
            f"--offload-arch={arch}",
            "--offload-device-only",
            f"--rocm-device-lib-path={rocm_device_lib_path}",
            "-D__AMDGCN_WAVEFRONT_SIZE=64",
        ])
        if cuda_counterpart.is_dir():
            cmd.append(f"-I{cuda_counterpart}")
    else:
        cmd.extend([
            f"--cuda-path={cuda_root}",
            f"--cuda-gpu-arch={arch}",
            "--cuda-device-only",
        ])

    cmd.extend(["-std=c++17", "-O3", "-ftime-report", "-mllvm", "-time-passes"])
    if pipeline == "CIR":
        cmd.extend(["-mmlir", "--mlir-pass-statistics"])
    cmd.extend(["-c", str(file), f"-I{root}", f"-I{file.parent}", "-o", "/dev/null"])
    cmd.extend(f"-I{d}" for d in include_dirs)

    env = os.environ.copy()
    if pipeline == "CIR":
        env["PATH"] = f"{clang.parent}:{env['PATH']}"

    for _ in range(warmup):
        subprocess.run(cmd, capture_output=True, env=env)

    start = time.perf_counter()
    proc = subprocess.run(cmd, text=True, capture_output=True, env=env)
    elapsed = time.perf_counter() - start

    log.write_text(
        "COMMAND: " + shlex.join(cmd) + "\n\nSTDOUT:\n" + proc.stdout + "\nSTDERR:\n" + proc.stderr,
        encoding="utf-8",
    )

    ok = proc.returncode == 0
    phases = parse_phases(proc.stderr) if ok else {}
    first_error = ""
    if not ok:
        for line in (proc.stdout + proc.stderr).splitlines():
            if " error:" in line.lower() or "fatal" in line.lower():
                first_error = line.strip()
                break

    return TimingResult(
        benchmark=benchmark_name(file), source_set=source_set(root, file),
        file=file, pipeline=pipeline, arch=arch, ok=ok, elapsed=elapsed,
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
    header = "| Benchmark | Source set |" + "".join(f" CIR {ph} | OG {ph} |" for ph in all_phases) + " CIR total | OG total |"
    sep    = "|---|---:|" + "---:|---:|" * len(all_phases) + "---:|---:|"

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
        row += f" {f'{cir.elapsed:.3f}' if cir else '—'} | {f'{og.elapsed:.3f}' if og else '—'} |"
        lines.append(row)
    return lines


def markdown(results: list[TimingResult], root: Path, arch_tag: str, log_dir: Path, warmup: int) -> str:
    arches    = sorted(set(r.arch for r in results))
    multi     = len(arches) > 1
    cir_ok    = sum(1 for r in results if r.pipeline == "CIR" and r.ok)
    og_ok     = sum(1 for r in results if r.pipeline == "OG"  and r.ok)
    total_cir = sum(1 for r in results if r.pipeline == "CIR")
    total_og  = sum(1 for r in results if r.pipeline == "OG")

    lines = [
        "PolyBench compile-phase timing: CIR vs OG.", "",
        f"- arch: `{arch_tag}`",
        f"- PolyBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        "- Flags: `-O3 device-only -ftime-report -mllvm -time-passes` (CIR adds `--mlir-pass-statistics`)",
        f"- Warmup runs per benchmark: {warmup}",
        f"- CIR compiled OK: `{cir_ok}/{total_cir}`",
        f"- OG compiled OK: `{og_ok}/{total_og}`",
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

def main() -> int:
    _rocm = _find_rocm_root()

    parser = argparse.ArgumentParser(description=__doc__)

    src = parser.add_mutually_exclusive_group()
    src.add_argument("--hip",  action="store_true", help="Time HIP benchmarks only")
    src.add_argument("--cuda", action="store_true", help="Time CUDA benchmarks only")

    parser.add_argument("--clang",                type=path_arg, default=Path("~/polybench-gpu-audit/llvm-project/build/bin/clang++"))
    parser.add_argument("--polybench-root",       type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root",            type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--hip-path",             type=path_arg, default=_rocm)
    parser.add_argument("--rocm-device-lib-path", type=path_arg, default=_find_rocm_device_lib(_rocm))
    parser.add_argument("--gcc-install-dir",      type=path_arg, default=_find_gcc_install())
    parser.add_argument("--cuda-arch",   default="sm_86",  help="CUDA GPU arch (single-arch mode)")
    parser.add_argument("--hip-arch",    default="gfx942", help="HIP/AMDGPU arch (single-arch mode)")
    parser.add_argument("--multi-arch",  action="store_true",
                        help=f"Compile for all arches per target "
                             f"(HIP: {_HIP_MULTI_ARCHES}, CUDA: {_CUDA_MULTI_ARCHES})")
    parser.add_argument("--warmup",  type=int, default=2,  help="Warm-up runs before timed run (default: 2)")
    parser.add_argument("--log-dir", type=path_arg, default=Path("~/polybench-gpu-audit/logs/timing"))
    parser.add_argument("--limit",   type=int, default=0,  help="Cap number of source files")
    parser.add_argument("-j", "--jobs", type=int, default=4)

    args = parser.parse_args()
    args.polybench_root = args.polybench_root.expanduser().resolve()
    args.cuda_root      = args.cuda_root.expanduser().resolve()
    args.log_dir        = args.log_dir.expanduser().resolve()

    errors = []
    if not args.clang.exists():          errors.append(f"--clang not found: {args.clang}")
    if not args.polybench_root.exists(): errors.append(f"--polybench-root not found: {args.polybench_root}")
    if args.jobs < 1:                    errors.append("--jobs must be >= 1")
    if args.warmup < 0:                  errors.append("--warmup must be >= 0")
    if errors:
        for e in errors: print(f"error: {e}", file=sys.stderr)
        return 2

    args.log_dir.mkdir(parents=True, exist_ok=True)
    for old in args.log_dir.glob("*.log"):
        old.unlink()

    all_files = sorted(
        list(args.polybench_root.rglob("*.cu")) +
        list(args.polybench_root.rglob("*.hip.cpp")),
        key=lambda p: p.name,
    )
    if args.hip:    files = [f for f in all_files if is_hip(f)]
    elif args.cuda: files = [f for f in all_files if not is_hip(f)]
    else:           files = all_files

    if args.limit: files = files[: args.limit]
    if not files:
        print("error: no source files found", file=sys.stderr)
        return 2

    hip_arches  = _HIP_MULTI_ARCHES  if args.multi_arch else [args.hip_arch]
    cuda_arches = _CUDA_MULTI_ARCHES if args.multi_arch else [args.cuda_arch]
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
                include_dirs, args.log_dir, args.warmup,
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
                f" wall={result.elapsed:.3f}s  {phase_summary}"
            )

    results = [
        results_by_key[(file, pipeline, arch)]
        for file, pipeline, arch in jobs
        if (file, pipeline, arch) in results_by_key
    ]

    if args.multi_arch:
        active_hip, active_cuda = ",".join(_HIP_MULTI_ARCHES), ",".join(_CUDA_MULTI_ARCHES)
    else:
        active_hip, active_cuda = args.hip_arch, args.cuda_arch
    arch_tag = (
        f"hip:{active_hip}"   if args.hip  else
        f"cuda:{active_cuda}" if args.cuda else
        f"cuda:{active_cuda} hip:{active_hip}"
    )

    report      = markdown(results, args.polybench_root, arch_tag, args.log_dir, args.warmup)
    report_path = args.log_dir / "timing_summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")
    print()
    print(report)
    print(f"\nReport written to {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
