#!/usr/bin/env python3
"""Compile PolyBench CUDA/HIP files through ClangIR and print a PR-friendly report."""

from __future__ import annotations

import argparse
import os
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


# ---------------------------------------------------------------------------
# Auto-detection helpers
# ---------------------------------------------------------------------------

def _find_rocm_root() -> Path:
    """Return the newest versioned ROCm install that has HIP headers, falling back to /opt/rocm."""
    candidates = sorted(Path("/opt").glob("rocm-[0-9]*"), reverse=True)
    for c in candidates:
        if (c / "include/hip/hip_runtime.h").exists():
            return c
    return Path("/opt/rocm")


def _find_gcc_install() -> Path:
    """Return the newest GCC multilib dir that contains crtbegin.o."""
    for crt in sorted(Path("/usr/lib/gcc").rglob("crtbegin.o"), reverse=True):
        return crt.parent
    return Path("/usr/lib/gcc/x86_64-linux-gnu/11")


def _find_rocm_device_lib(rocm: Path) -> Path:
    """Prefer a versioned 6.x bitcode dir (needs oclc_abi_version_600.bc)."""
    v6_candidates = sorted(Path("/opt").glob("rocm-6*/amdgcn/bitcode"), reverse=True)
    if v6_candidates:
        return v6_candidates[0]
    return rocm / "amdgcn/bitcode"


# ---------------------------------------------------------------------------
# Core helpers
# ---------------------------------------------------------------------------

def path_arg(text: str) -> Path:
    return Path(text).expanduser().resolve()


def discover_include_dirs(files: list[Path]) -> list[Path]:
    suffixes = {".h", ".hpp", ".cuh", ".hip"}
    search_dirs = {f.parent for f in files}
    dirs: set[Path] = set()
    for d in search_dirs:
        for p in d.iterdir():
            if p.is_file() and p.suffix in suffixes:
                dirs.add(p.parent)
                break
    return sorted(dirs)


def safe_name(root: Path, file: Path) -> str:
    return "_".join(file.relative_to(root).parts)


def benchmark_name(file: Path) -> str:
    return BENCHMARK_NAMES.get(file.parent.name.upper(), file.stem.lower())


def source_set(root: Path, file: Path) -> str:
    parts = file.relative_to(root).parts
    if parts[:1] == ("CUDA",):
        return "CUDA"
    if parts[:1] == ("HIP",):
        return "HIP"
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


def is_hip(file: Path) -> bool:
    return ".hip" in file.suffixes or file.suffix == ".hip"


# ---------------------------------------------------------------------------
# Compilation
# ---------------------------------------------------------------------------

def compile_one(
    clang: Path,
    root: Path,
    cuda_root: Path,
    hip_path: Path,
    rocm_device_lib_path: Path,
    gcc_install_dir: Path,
    cuda_arch: str,
    hip_arch: str,
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
    cmd.append(f"--gcc-install-dir={gcc_install_dir}")

    if is_hip(file):
        cuda_counterpart = Path(str(file.parent).replace("/HIP/", "/CUDA/", 1))
        hip_flags = [
            "-x", "hip",
            f"--hip-path={hip_path}",
            f"--offload-arch={hip_arch}",
            f"--rocm-device-lib-path={rocm_device_lib_path}",
        ]
        if pipeline == "CIR":
            # __AMDGCN_WAVEFRONT_SIZE was removed in clang-23; ROCm headers still use it
            hip_flags.append("-D__AMDGCN_WAVEFRONT_SIZE=64")
        cmd.extend(hip_flags)
        if cuda_counterpart.is_dir():
            cmd.append(f"-I{cuda_counterpart}")
    else:
        cmd.extend([
            f"--cuda-path={cuda_root}",
            f"--cuda-gpu-arch={cuda_arch}",
        ])

    cmd.extend([
        "-std=c++17",
        "-O0",
        "-c",
        str(file),
        f"-I{root}",
        f"-I{file.parent}",
        "-o",
        str(out),
    ])
    if not is_hip(file):
        cmd.append("-v")
    cmd.extend(f"-I{d}" for d in include_dirs)

    # For CIR, prepend our clang bin dir to PATH so clang-linker-wrapper
    # picks up our lld (LLVM 23) instead of the ROCm system lld (LLVM 17).
    env = os.environ.copy()
    if pipeline == "CIR":
        env["PATH"] = f"{clang.parent}:{env['PATH']}"

    start = time.perf_counter()
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
    elapsed = time.perf_counter() - start

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


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def markdown(results: list[Result], root: Path, arch: str, log_dir: Path) -> str:
    by_key: dict[tuple[Path, str], Result] = {(r.file, r.pipeline): r for r in results}
    seen: set[Path] = set()
    files_ordered: list[Path] = []
    for r in results:
        if r.file not in seen:
            seen.add(r.file)
            files_ordered.append(r.file)

    total = len(files_ordered)
    cir_passed = sum(1 for f in files_ordered if by_key.get((f, "CIR"), Result("","",f,"",False,0,Path(),[],)).ok)
    og_passed  = sum(1 for f in files_ordered if by_key.get((f, "OG"),  Result("","",f,"",False,0,Path(),[],)).ok)

    lines = [
        "PolyBench CUDA/HIP compile-only results through ClangIR.",
        "",
        f"- arch: `{arch}`",
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
        og  = by_key.get((file, "OG"))
        ref = cir or og
        assert ref is not None
        cir_status = ("pass" if cir.ok else "fail") if cir else "N/A"
        og_status  = ("pass" if og.ok  else "fail") if og  else "N/A"
        cir_time   = f"{cir.elapsed:.3f}" if cir else "N/A"
        og_time    = f"{og.elapsed:.3f}"  if og  else "N/A"
        lines.append(
            f"| {ref.benchmark} | {ref.source_set} | {cir_status} | {og_status} | {cir_time} | {og_time} |"
        )

    failures = [r for r in results if not r.ok]
    if failures:
        lines.extend(["", "Failures:", ""])
        for r in failures:
            lines.extend([
                f"- [{r.pipeline}] `{r.file}`",
                f"  - log: `{r.log}`",
                f"  - error: `{r.first_error or 'unknown error'}`",
                f"  - command: `{shlex.join(r.command)}`",
            ])
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    _rocm = _find_rocm_root()

    parser = argparse.ArgumentParser(description=__doc__)

    # Source-set filter (mutually exclusive)
    src_group = parser.add_mutually_exclusive_group()
    src_group.add_argument("--hip",  action="store_true", help="Run HIP benchmarks only")
    src_group.add_argument("--cuda", action="store_true", help="Run CUDA benchmarks only (requires CUDA toolkit)")

    # Paths — all auto-detected, override as needed
    parser.add_argument("--clang",               type=path_arg, default=Path("/workspace/llvm-bin/clang"),
                        help="clang binary (used for both CIR and OG; OG simply omits -fclangir)")
    parser.add_argument("--polybench-root",      type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root",           type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--hip-path",            type=path_arg, default=_rocm)
    parser.add_argument("--rocm-device-lib-path",type=path_arg, default=_find_rocm_device_lib(_rocm),
                        help="ROCm 6.x bitcode dir (needs oclc_abi_version_600.bc)")
    parser.add_argument("--gcc-install-dir",     type=path_arg, default=_find_gcc_install())
    parser.add_argument("--cuda-arch",  default="sm_80",  help="CUDA GPU arch")
    parser.add_argument("--hip-arch",   default="gfx942", help="HIP/AMDGPU arch")
    parser.add_argument("--log-dir",    type=path_arg, default=Path("~/polybench-gpu-audit/logs/cir-rocm"))
    parser.add_argument("--limit", type=int, default=0, help="Cap number of source files (for quick tests)")
    parser.add_argument("-j", "--jobs", type=int, default=4)

    args = parser.parse_args()

    # Resolve remaining unexpanded paths
    args.polybench_root = args.polybench_root.expanduser().resolve()
    args.cuda_root      = args.cuda_root.expanduser().resolve()
    args.log_dir        = args.log_dir.expanduser().resolve()

    # Validate
    errors = []
    if not args.clang.exists():
        errors.append(f"--clang not found: {args.clang}")
    if not args.polybench_root.exists():
        errors.append(f"--polybench-root not found: {args.polybench_root}")
    if args.jobs < 1:
        errors.append("--jobs must be >= 1")
    if errors:
        for e in errors:
            print(f"error: {e}", file=sys.stderr)
        return 2

    args.log_dir.mkdir(parents=True, exist_ok=True)
    for old_log in args.log_dir.glob("*.log"):
        old_log.unlink()

    # Discover source files
    all_files = sorted(
        list(args.polybench_root.rglob("*.cu")) +
        list(args.polybench_root.rglob("*.hip.cpp")),
        key=lambda p: p.name,
    )

    # Apply source-set filter
    if args.hip:
        files = [f for f in all_files if is_hip(f)]
    elif args.cuda:
        files = [f for f in all_files if not is_hip(f)]
    else:
        files = all_files

    if args.limit:
        files = files[: args.limit]

    if not files:
        print("error: no source files found after filtering", file=sys.stderr)
        return 2

    include_dirs = discover_include_dirs(files)

    pipelines = ("CIR", "OG")
    total_jobs = len(files) * len(pipelines)
    width = len(str(total_jobs))
    results_by_key: dict[tuple[Path, str], Result] = {}

    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(
                compile_one,
                args.clang,
                args.polybench_root,
                args.cuda_root,
                args.hip_path,
                args.rocm_device_lib_path,
                args.gcc_install_dir,
                args.cuda_arch,
                args.hip_arch,
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
                    f"[{completed:0{width}d}/{total_jobs}] {pipeline} error"
                    f" {file.relative_to(args.polybench_root)}: {exc}",
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

    arch_tag = f"hip:{args.hip_arch}" if args.hip else f"cuda:{args.cuda_arch}" if args.cuda else f"cuda:{args.cuda_arch} hip:{args.hip_arch}"
    report = markdown(results, args.polybench_root, arch_tag, args.log_dir)
    report_path = args.log_dir / "summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")
    print()
    print(report)

    cir_results = [r for r in results if r.pipeline == "CIR"]
    return 0 if all(r.ok for r in cir_results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
