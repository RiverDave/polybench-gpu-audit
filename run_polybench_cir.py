#!/usr/bin/env python3
"""Compile PolyBench CUDA files through ClangIR and print a PR-friendly report. TODO: Missing HIP support once we have a rocm machine"""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
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


@dataclass
class Result:
    benchmark: str
    source_set: str
    file: Path
    pipeline: str  # "CIR" or "OG"
    ok: bool
    elapsed: float
    log: Path
    command: list[str]
    first_error: str = ""


def path_arg(text: str) -> Path:
    return Path(text).expanduser().resolve()


def discover_include_dirs(root: Path) -> list[Path]:
    suffixes = {".h", ".hpp", ".cuh"}
    dirs = {p.parent for p in root.rglob("*") if p.is_file() and p.suffix in suffixes}
    return sorted(dirs)


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


def first_real_error(log_text: str) -> str:
    for line in log_text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        lowered = stripped.lower()
        if " warning:" in lowered or lowered.startswith("warning:"):
            continue
        if " note:" in lowered or lowered.startswith("note:"):
            continue
        if " error:" in lowered or lowered.startswith("error:"):
            return stripped
        if "fatal" in lowered or "not yet implemented" in lowered:
            return stripped
    return ""


def compile_one(
    clang: Path,
    root: Path,
    cuda_root: Path,
    gcc_install_dir: Path,
    arch: str,
    pipeline: str,
    file: Path,
    include_dirs: list[Path],
    log_dir: Path,
) -> Result:
    log = log_dir / f"{safe_name(root, file)}.{pipeline.lower()}.log"
    out = Path("/tmp") / f"{safe_name(root, file)}.{pipeline.lower()}.o"
    cmd = [str(clang)]
    if pipeline == "CIR":
        cmd.append("-fclangir")
    cmd.extend([
        f"--gcc-install-dir={gcc_install_dir}",
        f"--cuda-path={cuda_root}",
        f"--cuda-gpu-arch={arch}",
        "-std=c++17",
        "-O0",
        "-c",
        str(file),
        f"-I{root}",
        f"-I{file.parent}",
        "-o",
        str(out),
        "-v",
    ])
    cmd.extend(f"-I{d}" for d in include_dirs)

    start = time.perf_counter()
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    elapsed = time.perf_counter() - start # end

    log.write_text("COMMAND: " + shlex.join(cmd) + "\n\n" + proc.stdout, encoding="utf-8")
    ok = proc.returncode == 0
    return Result(
        benchmark=benchmark_name(file),
        source_set=source_set(root, file),
        file=file,
        pipeline=pipeline,
        ok=ok,
        elapsed=elapsed,
        log=log,
        command=cmd,
        first_error="" if ok else first_real_error(proc.stdout),
    )


def markdown(results: list[Result], root: Path, arch: str, log_dir: Path) -> str:
    by_key: dict[tuple[Path, str], Result] = {(r.file, r.pipeline): r for r in results}
    seen: set[Path] = set()
    files_ordered: list[Path] = []
    for r in results:
        if r.file not in seen:
            seen.add(r.file)
            files_ordered.append(r.file)

    total = len(files_ordered)
    cir_passed = sum(1 for f in files_ordered if by_key.get((f, "CIR")) and by_key[(f, "CIR")].ok)
    og_passed = sum(1 for f in files_ordered if by_key.get((f, "OG")) and by_key[(f, "OG")].ok)

    lines = [
        "PolyBench CUDA compile-only results through ClangIR.",
        "",
        f"- CUDA arch: `{arch}`",
        f"- PolyBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        f"- CIR result: `{cir_passed}/{total}` passed",
        f"- OG result: `{og_passed}/{total}` passed",
        "",
        "| Benchmark | Source set | CIR | OG | CIR time (s) | OG time (s) |",
        "|---|---:|:---:|:---:|---:|---:|",
    ]
    for file in files_ordered:
        cir = by_key.get((file, "CIR"))
        og = by_key.get((file, "OG"))
        ref = cir or og
        assert ref is not None
        cir_status = ("pass" if cir.ok else "fail") if cir else "N/A"
        og_status = ("pass" if og.ok else "fail") if og else "N/A"
        cir_time = f"{cir.elapsed:.3f}" if cir else "N/A"
        og_time = f"{og.elapsed:.3f}" if og else "N/A"
        lines.append(
            f"| {ref.benchmark} | {ref.source_set} | {cir_status} | {og_status} | {cir_time} | {og_time} |"
        )

    failures = [r for r in results if not r.ok]
    if failures:
        lines.extend(["", "Failures:", ""])
        for result in failures:
            lines.extend(
                [
                    f"- [{result.pipeline}] `{result.file}`",
                    f"  - log: `{result.log}`",
                    f"  - error: `{result.first_error or 'unknown error'}`",
                    f"  - command: `{shlex.join(result.command)}`",
                ]
            )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--clang", type=path_arg, default=Path("~/llvm-project/build/bin/clang++"))
    parser.add_argument("--polybench-root", type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root", type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--gcc-install-dir", type=path_arg, default=Path("/usr/lib/gcc/aarch64-linux-gnu/11"))
    parser.add_argument("--arch", default="sm_90a")
    parser.add_argument("--log-dir", type=path_arg, default=Path("~/polybench-gpu-audit/logs/cir-cuda"))
    parser.add_argument("--limit", type=int, default=0, help="Compile only the first N files.")
    parser.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=1,
        help="Number of compile jobs to run in parallel.",
    )
    args = parser.parse_args()

    args.clang = args.clang.expanduser().resolve()
    args.polybench_root = args.polybench_root.expanduser().resolve()
    args.cuda_root = args.cuda_root.expanduser().resolve()
    args.gcc_install_dir = args.gcc_install_dir.expanduser().resolve()
    args.log_dir = args.log_dir.expanduser().resolve()

    if not args.clang.exists():
        print(f"error: clang not found: {args.clang}", file=sys.stderr)
        return 2
    if not args.polybench_root.exists():
        print(f"error: PolyBench root not found: {args.polybench_root}", file=sys.stderr)
        return 2

    args.log_dir.mkdir(parents=True, exist_ok=True)
    for old_log in args.log_dir.glob("*.log"):
        old_log.unlink()

    files = sorted(args.polybench_root.rglob("*.cu"))
    if args.limit:
        files = files[: args.limit]
    include_dirs = discover_include_dirs(args.polybench_root)

    if args.jobs < 1:
        print("error: --jobs must be >= 1", file=sys.stderr)
        return 2

    pipelines = ("CIR", "OG")
    results_by_key: dict[tuple[Path, str], Result] = {}
    total_jobs = len(files) * len(pipelines)
    width = len(str(total_jobs))
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(
                compile_one,
                args.clang,
                args.polybench_root,
                args.cuda_root,
                args.gcc_install_dir,
                args.arch,
                pipeline,
                file,
                include_dirs,
                args.log_dir,
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
                    f"[{completed:0{width}d}/{total_jobs}] {pipeline} fail"
                    f" {file.relative_to(args.polybench_root)} ({exc})",
                    file=sys.stderr,
                )
                raise
            results_by_key[(file, pipeline)] = result
            status = "pass" if result.ok else "fail"
            print(
                f"[{completed:0{width}d}/{total_jobs}] {pipeline} {status} "
                f"{file.relative_to(args.polybench_root)} ({result.elapsed:.3f}s)"
            )

    results = [
        results_by_key[(file, pipeline)]
        for file in files
        for pipeline in pipelines
        if (file, pipeline) in results_by_key
    ]

    report = markdown(results, args.polybench_root, args.arch, args.log_dir)
    report_path = args.log_dir / "summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")
    print()
    print(report)

    cir_results = [r for r in results if r.pipeline == "CIR"]
    return 0 if all(r.ok for r in cir_results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
