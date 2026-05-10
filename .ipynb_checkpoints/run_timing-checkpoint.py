#!/usr/bin/env python3
"""CIR vs OG compile-phase timing breakdown for PolyBench CUDA benchmarks.

Compiles each benchmark with -O3 --cuda-device-only and timing flags:
  CIR: -fclangir -ftime-report -mllvm -time-passes -mmlir --mlir-timing -mmlir --mlir-pass-statistics
  OG:  -ftime-report -mllvm -time-passes
"""

from __future__ import annotations

import argparse
import re
import shlex
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path


BENCHMARK_NAMES = {
    "2DCONV": "convolution-2d",
    "2MM": "2mm",
    "3DCONV": "convolution-3d",
    "3MM": "3mm",
    "ADI": "adi",
    "ATAX": "atax",
    "BICG": "bicg",
    "CORR": "correlation",
    "COVAR": "covariance",
    "DOITGEN": "doitgen",
    "FDTD-2D": "fdtd-2d",
    "GEMM": "gemm",
    "GEMVER": "gemver",
    "GESUMMV": "gesummv",
    "GRAMSCHM": "gramschmidt",
    "JACOBI1D": "jacobi-1d-imper",
    "JACOBI2D": "jacobi-2d-imper",
    "LU": "lu",
    "MVT": "mvt",
    "SYR2K": "syr2k",
    "SYRK": "syrk",
}

_SECTION_SEP = re.compile(r"^={10,}")
_EXEC_TIME = re.compile(r"Total Execution Time:\s*[\d.]+\s*seconds\s*\(([\d.]+)\s*wall")

_PHASE_ALIASES = {
    "clang front-end time report": "Frontend",
    "llvm ir code generation time": "IRGen",
    "code generation time": "CodeGen",
    "pass execution timing report": "LLVM-passes",
    "mir parsing and codegen time": "MIR",
    "mlir pass manager": "MLIR-passes",
    "mlir module pass manager": "MLIR-passes",
}


@dataclass
class TimingResult:
    benchmark: str
    source_set: str
    file: Path
    pipeline: str  # "CIR" or "OG"
    ok: bool
    elapsed: float
    phases: dict[str, float]  # phase_name -> wall_seconds
    log: Path
    command: list[str]
    first_error: str = ""


def path_arg(text: str) -> Path:
    return Path(text).expanduser().resolve()


def safe_name(root: Path, file: Path) -> str:
    return "_".join(file.relative_to(root).parts)


def benchmark_name(file: Path) -> str:
    return BENCHMARK_NAMES.get(file.parent.name.upper(), file.stem.lower())


def source_set(root: Path, file: Path) -> str:
    parts = file.relative_to(root).parts
    if parts[:1] == ("CUDA",):
        return "CUDA"
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
    """Extract wall-clock totals from each -ftime-report / -time-passes section."""
    phases: dict[str, float] = {}
    lines = stderr.splitlines()
    i = 0
    while i < len(lines):
        if _SECTION_SEP.match(lines[i].strip()):
            # Skip separators and blank lines to find section name
            j = i + 1
            while j < len(lines) and (not lines[j].strip() or _SECTION_SEP.match(lines[j].strip())):
                j += 1
            if j >= len(lines):
                i = j
                continue
            raw_name = lines[j].strip()
            name = _normalize_phase(raw_name)
            # Find "Total Execution Time" within the next 200 lines (passes list can be long)
            for k in range(j + 1, min(j + 200, len(lines))):
                m = _EXEC_TIME.search(lines[k])
                if m:
                    # First occurrence per phase name wins
                    phases.setdefault(name, float(m.group(1)))
                    break
                # Stop if we hit another section separator
                if _SECTION_SEP.match(lines[k].strip()):
                    break
            i = j + 1
        else:
            i += 1
    return phases


def discover_include_dirs(root: Path) -> list[Path]:
    suffixes = {".h", ".hpp", ".cuh"}
    dirs = {p.parent for p in root.rglob("*") if p.is_file() and p.suffix in suffixes}
    return sorted(dirs)


def timing_compile_one(
    clang: Path,
    root: Path,
    cuda_root: Path,
    gcc_install_dir: Path,
    arch: str,
    pipeline: str,
    file: Path,
    include_dirs: list[Path],
    log_dir: Path,
) -> TimingResult:
    log = log_dir / f"{safe_name(root, file)}.{pipeline.lower()}.log"
    cmd = [str(clang)]
    if pipeline == "CIR":
        cmd.append("-fclangir")
    cmd.extend([
        f"--gcc-install-dir={gcc_install_dir}",
        f"--cuda-path={cuda_root}",
        f"--cuda-gpu-arch={arch}",
        "--cuda-device-only",
        "-std=c++17",
        "-O3",
        "-ftime-report",
        "-mllvm", "-time-passes",
    ])
    if pipeline == "CIR":
        cmd.extend(["-mmlir", "--mlir-pass-statistics"])
    cmd.extend([
        "-c", str(file),
        f"-I{root}",
        f"-I{file.parent}",
        "-o", "/dev/null",
    ])
    cmd.extend(f"-I{d}" for d in include_dirs)

    start = time.perf_counter()
    proc = subprocess.run(cmd, text=True, capture_output=True)
    elapsed = time.perf_counter() - start

    full_log = "COMMAND: " + shlex.join(cmd) + "\n\nSTDOUT:\n" + proc.stdout + "\nSTDERR:\n" + proc.stderr
    log.write_text(full_log, encoding="utf-8")

    ok = proc.returncode == 0
    phases = parse_phases(proc.stderr) if ok else {}
    first_error = ""
    if not ok:
        for line in (proc.stdout + proc.stderr).splitlines():
            if " error:" in line.lower() or "fatal" in line.lower():
                first_error = line.strip()
                break

    return TimingResult(
        benchmark=benchmark_name(file),
        source_set=source_set(root, file),
        file=file,
        pipeline=pipeline,
        ok=ok,
        elapsed=elapsed,
        phases=phases,
        log=log,
        command=cmd,
        first_error=first_error,
    )


def markdown(results: list[TimingResult], root: Path, arch: str, log_dir: Path) -> str:
    by_key: dict[tuple[Path, str], TimingResult] = {(r.file, r.pipeline): r for r in results}
    seen: set[Path] = set()
    files_ordered: list[Path] = []
    for r in results:
        if r.file not in seen:
            seen.add(r.file)
            files_ordered.append(r.file)

    # Collect all phase names seen across CIR results (OG won't have MLIR phases)
    cir_phases: list[str] = []
    og_phases: list[str] = []
    for f in files_ordered:
        for p in (by_key.get((f, "CIR")) or TimingResult("","",f,"CIR",False,0.0,{},log_dir/".x",[])).phases:
            if p not in cir_phases:
                cir_phases.append(p)
        for p in (by_key.get((f, "OG")) or TimingResult("","",f,"OG",False,0.0,{},log_dir/".x",[])).phases:
            if p not in og_phases:
                og_phases.append(p)

    total = len(files_ordered)
    cir_ok = sum(1 for f in files_ordered if by_key.get((f, "CIR")) and by_key[(f, "CIR")].ok)
    og_ok = sum(1 for f in files_ordered if by_key.get((f, "OG")) and by_key[(f, "OG")].ok)

    lines = [
        "PolyBench CUDA compile-phase timing: CIR vs OG.",
        "",
        f"- CUDA arch: `{arch}`",
        f"- PolyBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        f"- Flags: `-O3 --cuda-device-only -ftime-report -mllvm -time-passes` (CIR adds `--mlir-timing --mlir-pass-statistics`)",
        f"- CIR compiled OK: `{cir_ok}/{total}`",
        f"- OG compiled OK: `{og_ok}/{total}`",
        "",
    ]

    # --- Per-phase aggregate table ---
    all_phases = sorted(set(cir_phases) | set(og_phases))
    lines += [
        "## Phase averages (wall seconds, over successful compilations)",
        "",
        "| Phase | CIR avg | OG avg | delta |",
        "|---|---:|---:|---:|",
    ]
    for phase in all_phases:
        cir_times = [by_key[(f, "CIR")].phases[phase] for f in files_ordered
                     if (f, "CIR") in by_key and by_key[(f, "CIR")].ok and phase in by_key[(f, "CIR")].phases]
        og_times = [by_key[(f, "OG")].phases[phase] for f in files_ordered
                    if (f, "OG") in by_key and by_key[(f, "OG")].ok and phase in by_key[(f, "OG")].phases]
        cir_avg = sum(cir_times) / len(cir_times) if cir_times else None
        og_avg = sum(og_times) / len(og_times) if og_times else None
        cir_str = f"{cir_avg:.3f}" if cir_avg is not None else "—"
        og_str = f"{og_avg:.3f}" if og_avg is not None else "—"
        if cir_avg is not None and og_avg is not None:
            delta_str = f"+{cir_avg - og_avg:.3f}" if cir_avg >= og_avg else f"{cir_avg - og_avg:.3f}"
        else:
            delta_str = "—"
        lines.append(f"| {phase} | {cir_str} | {og_str} | {delta_str} |")

    # Total wall time row
    cir_totals = [by_key[(f, "CIR")].elapsed for f in files_ordered if (f, "CIR") in by_key and by_key[(f, "CIR")].ok]
    og_totals = [by_key[(f, "OG")].elapsed for f in files_ordered if (f, "OG") in by_key and by_key[(f, "OG")].ok]
    if cir_totals and og_totals:
        ca, oa = sum(cir_totals) / len(cir_totals), sum(og_totals) / len(og_totals)
        d = ca - oa
        delta_str = f"+{d:.3f}" if d >= 0 else f"{d:.3f}"
        lines.append(f"| **Total (wall)** | **{ca:.3f}** | **{oa:.3f}** | **{delta_str}** |")

    # --- Per-benchmark detail table ---
    phase_cols = all_phases  # show all phases; prune empty columns below
    header = "| Benchmark | Source set |"
    sep = "|---|---:|"
    for ph in phase_cols:
        header += f" CIR {ph} | OG {ph} |"
        sep += "---:|---:|"
    header += " CIR total | OG total |"
    sep += "---:|---:|"

    lines += ["", "## Per-benchmark breakdown (wall seconds)", "", header, sep]
    for file in files_ordered:
        cir = by_key.get((file, "CIR"))
        og = by_key.get((file, "OG"))
        ref = cir or og
        assert ref is not None
        row = f"| {ref.benchmark} | {ref.source_set} |"
        for ph in phase_cols:
            cir_v = f"{cir.phases[ph]:.3f}" if cir and cir.ok and ph in cir.phases else "—"
            og_v = f"{og.phases[ph]:.3f}" if og and og.ok and ph in og.phases else "—"
            row += f" {cir_v} | {og_v} |"
        cir_total = f"{cir.elapsed:.3f}" if cir else "—"
        og_total = f"{og.elapsed:.3f}" if og else "—"
        row += f" {cir_total} | {og_total} |"
        lines.append(row)

    # Failures
    failures = [r for r in results if not r.ok]
    if failures:
        lines += ["", "## Failures", ""]
        for r in failures:
            lines += [
                f"- [{r.pipeline}] `{r.file}`",
                f"  - error: `{r.first_error or 'see log'}`",
                f"  - log: `{r.log}`",
            ]

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--clang", type=path_arg, default=Path("~/llvm-project/build/bin/clang++"))
    parser.add_argument("--polybench-root", type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root", type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--gcc-install-dir", type=path_arg, default=Path("/usr/lib/gcc/aarch64-linux-gnu/11"))
    parser.add_argument("--arch", default="sm_90a")
    parser.add_argument("--log-dir", type=path_arg, default=Path("~/polybench-gpu-audit/logs/timing"))
    parser.add_argument("--limit", type=int, default=0, help="Compile only the first N files.")
    parser.add_argument("-j", "--jobs", type=int, default=1, help="Parallel compile jobs.")
    args = parser.parse_args()

    for attr in ("clang", "polybench_root", "cuda_root", "gcc_install_dir", "log_dir"):
        setattr(args, attr, getattr(args, attr).expanduser().resolve())

    if not args.clang.exists():
        print(f"error: clang not found: {args.clang}", file=sys.stderr)
        return 2
    if not args.polybench_root.exists():
        print(f"error: PolyBench root not found: {args.polybench_root}", file=sys.stderr)
        return 2
    if args.jobs < 1:
        print("error: --jobs must be >= 1", file=sys.stderr)
        return 2

    args.log_dir.mkdir(parents=True, exist_ok=True)
    for old in args.log_dir.glob("*.log"):
        old.unlink()

    files = sorted(args.polybench_root.rglob("*.cu"))
    if args.limit:
        files = files[: args.limit]
    include_dirs = discover_include_dirs(args.polybench_root)

    pipelines = ("CIR", "OG")
    total_jobs = len(files) * len(pipelines)
    width = len(str(total_jobs))
    results_by_key: dict[tuple[Path, str], TimingResult] = {}

    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(
                timing_compile_one,
                args.clang, args.polybench_root, args.cuda_root,
                args.gcc_install_dir, args.arch, pipeline,
                file, include_dirs, args.log_dir,
            ): (file, pipeline)
            for file in files
            for pipeline in pipelines
        }
        completed = 0
        for future in as_completed(futures):
            file, pipeline = futures[future]
            completed += 1
            try:
                result = future.result()
            except Exception as exc:
                print(
                    f"[{completed:0{width}d}/{total_jobs}] {pipeline} ERROR"
                    f" {file.relative_to(args.polybench_root)} ({exc})",
                    file=sys.stderr,
                )
                raise
            results_by_key[(file, pipeline)] = result
            status = "ok" if result.ok else "FAIL"
            phase_summary = "  ".join(f"{k}={v:.2f}s" for k, v in result.phases.items())
            print(
                f"[{completed:0{width}d}/{total_jobs}] {pipeline} {status}"
                f" {file.relative_to(args.polybench_root)}"
                f" wall={result.elapsed:.3f}s  {phase_summary}"
            )

    results = [
        results_by_key[(file, pipeline)]
        for file in files
        for pipeline in pipelines
        if (file, pipeline) in results_by_key
    ]

    report = markdown(results, args.polybench_root, args.arch, args.log_dir)
    report_path = args.log_dir / "timing_summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")
    print()
    print(report)
    print(f"\nReport written to {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
