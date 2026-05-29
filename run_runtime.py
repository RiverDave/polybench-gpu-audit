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
import math
import os
import re
import shlex
import subprocess
import sys
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
    times:       list[float]  # polybench wall-clock samples (seconds)
    first_error: str = ""


# ---------------------------------------------------------------------------
# Auto-detection + helpers
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

def _find_gcc_install() -> Path:
    for crt in sorted(Path("/usr/lib/gcc").glob("*/*/crtbegin.o"), reverse=True):
        return crt.parent
    return Path("/usr/lib/gcc/x86_64-linux-gnu/11")

def _git_rev(repo: Path) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", str(repo), "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        return out.stdout.strip() if out.returncode == 0 else "unknown"
    except Exception:
        return "unknown"


def _find_rocm_root() -> Path:
    candidates = sorted(Path("/opt").glob("rocm-[0-9]*"), reverse=True)
    for c in candidates:
        if (c / "include/hip/hip_runtime.h").exists():
            return c
    return Path("/opt/rocm")

def _find_rocm_device_lib(rocm: Path) -> Path:
    v6 = sorted(Path("/opt").glob("rocm-6*/amdgcn/bitcode"), reverse=True)
    return v6[0] if v6 else rocm / "amdgcn/bitcode"

def _mean_stddev(xs: list[float]) -> tuple[float, float]:
    if not xs:       return float("nan"), float("nan")
    m = sum(xs) / len(xs)
    if len(xs) == 1: return m, 0.0
    return m, math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))

_GPU_RUNTIME = re.compile(r"GPU Runtime:\s*([\d.]+)s")

def _parse_time(stdout: str) -> float | None:
    # polybenchCodesCudaOpenClHMPPOpenAcc kernels: "GPU Runtime: 0.000481s"
    # CUDA/ kernels (polybench_timer_print): bare float on its own line
    for line in reversed(stdout.splitlines()):
        m = _GPU_RUNTIME.search(line)
        if m:
            return float(m.group(1))
        try:
            return float(line.strip())
        except ValueError:
            continue
    return None


# ---------------------------------------------------------------------------
# Compilation
# ---------------------------------------------------------------------------

_EXTERN_RTCLOCK = re.compile(r"extern\s+double\s+rtclock")

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
    # clashing with the C++ symbol the shim will provide.
    cmd = [str(clang), f"--gcc-install-dir={gcc_install_dir}",
           "-O3", "-DPOLYBENCH_TIME=1", "-Dstatic=", "-Drtclock=_pb_rtclock",
           "-c", str(common_dir / "polybench.c"), f"-I{common_dir}", "-o", str(pb_obj)]
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
) -> PerfResult:
    tag    = f"{safe_name(root, file)}.{pipeline.lower()}.{arch}"
    log    = log_dir   / f"{tag}.log"
    binary = build_dir / tag

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
    extra_obj = [str(o) for o in polybench_objs] if _needs_polybench_c(file) else []
    cmd.extend([
        "-std=c++17", "-O3",
        str(file),
        f"-I{common_dir}", f"-I{file.parent}", f"-I{root}",
        "-lm", *link_flags, *extra_obj, "-o", str(binary),
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
        times=[], first_error=first_error,
    )


# ---------------------------------------------------------------------------
# Running
# ---------------------------------------------------------------------------

def run_binary(result: PerfResult, runs: int, warmup: int) -> None:
    """Run the binary in-place, filling result.times. Mutates result."""
    assert result.binary is not None
    try:
        for _ in range(warmup):
            subprocess.run([str(result.binary)], capture_output=True, timeout=300)
        for _ in range(runs):
            proc = subprocess.run([str(result.binary)], capture_output=True, text=True, timeout=300)
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
             runs: int, warmup: int, clangir_rev: str = "unknown", scripts_rev: str = "unknown") -> str:
    by_key        = {(r.file, r.pipeline): r for r in results}
    files_ordered = list(dict.fromkeys(r.file for r in results))
    compile_ok    = sum(1 for r in results if r.compile_ok)
    run_ok        = sum(1 for r in results if r.times)

    def fmt(v: float) -> str:
        return "—" if math.isnan(v) else f"{v:.4f}"

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
        "",
        "## Results (wall seconds, polybench timer)",
        "",
        "| Benchmark | Source set | CIR mean | CIR σ | OG mean | OG σ | CIR/OG |",
        "|---|---:|---:|---:|---:|---:|---:|",
    ]
    for file in files_ordered:
        cir = by_key.get((file, "CIR"))
        og  = by_key.get((file, "OG"))
        ref = cir or og
        assert ref is not None
        cir_m, cir_s = _mean_stddev(cir.times if cir else [])
        og_m,  og_s  = _mean_stddev(og.times  if og  else [])
        ratio = f"{cir_m / og_m:.3f}" if (not math.isnan(cir_m) and not math.isnan(og_m) and og_m > 0) else "—"
        lines.append(
            f"| {ref.benchmark} | {ref.source_set} |"
            f" {fmt(cir_m)} | {fmt(cir_s)} | {fmt(og_m)} | {fmt(og_s)} | {ratio} |"
        )

    failures = [r for r in results if not r.compile_ok or not r.times]
    if failures:
        lines += ["", "## Failures", ""]
        for r in failures:
            reason = "compile failed" if not r.compile_ok else "no timing output"
            lines += [f"- [{r.pipeline}] `{r.file}` — {reason}"]
            if r.first_error:
                lines += [f"  - error: `{r.first_error}`"]
            lines += [f"  - log: `{r.compile_log}`"]

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    _rocm = _find_rocm_root()

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    src = parser.add_mutually_exclusive_group()
    src.add_argument("--hip",  action="store_true", help="Run HIP benchmarks only")
    src.add_argument("--cuda", action="store_true", help="Run CUDA benchmarks only")

    parser.add_argument("--clang",                type=path_arg, default=Path("~/polybench-gpu-audit/llvm-project/build/bin/clang++"))
    parser.add_argument("--polybench-root",       type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root",            type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--hip-path",             type=path_arg, default=_rocm)
    parser.add_argument("--rocm-device-lib-path", type=path_arg, default=_find_rocm_device_lib(_rocm))
    parser.add_argument("--gcc-install-dir",      type=path_arg, default=_find_gcc_install())
    parser.add_argument("--arch",      default="sm_86",  help="GPU arch (default: sm_86)")
    parser.add_argument("--runs",      type=int, default=5, help="Timed runs per benchmark (default: 5)")
    parser.add_argument("--warmup",    type=int, default=1, help="Warmup runs before timing (default: 1)")
    parser.add_argument("--log-dir",   type=path_arg, default=Path("~/polybench-gpu-audit/temp/runtime"))
    parser.add_argument("--build-dir", type=path_arg, default=Path("~/polybench-gpu-audit/temp/runtime/build"))
    parser.add_argument("--limit",     type=int, default=0, help="Cap number of source files")
    parser.add_argument("-j", "--jobs", type=int, default=4, help="Parallel compile jobs (default: 4)")

    args = parser.parse_args()
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
                common_dir, pb_objs, args.build_dir, args.log_dir,
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
            m, s = _mean_stddev(r.times)
            status = f"mean={m:.4f}s σ={s:.4f}s" if r.times else "no timing output"
            print(f"[{done:0{rw}d}/{len(runnable)}] {r.pipeline}/{r.arch} {r.benchmark} {status}")

    results     = [results_map[(f, p)] for f, p in jobs if (f, p) in results_map]
    clangir_rev = _git_rev(args.clang.parent.parent.parent)
    scripts_rev = _git_rev(Path(__file__).parent)
    report      = markdown(results, args.polybench_root, args.arch, args.log_dir, args.runs, args.warmup,
                           clangir_rev=clangir_rev, scripts_rev=scripts_rev)
    report_path = args.log_dir / "runtime_summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")
    print()
    print(report)
    print(f"\nReport written to {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
