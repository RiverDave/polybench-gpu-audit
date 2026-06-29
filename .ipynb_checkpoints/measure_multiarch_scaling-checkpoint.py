#!/usr/bin/env python3
"""Measure --clangir-offload-merge compile-time overhead vs number of target architectures.

For each N in 1..len(arches), compiles all PolyBench/GPU benchmarks with both
pipelines (no-merge, merge) targeting arches[:N], records wall-clock time,
saves to JSON, and optionally generates a scaling plot.

Usage:
  # Measure CUDA  (sm_80 → sm_80+sm_86 → … → all four):
  python3 measure_multiarch_scaling.py --cuda -j8 --out results.json --plot

  # Plot only from a prior run:
  python3 measure_multiarch_scaling.py --plot --from results.json
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path


CLANG_DEFAULT  = Path("~/llvm-project/build/bin/clang++")
POLYBENCH_ROOT = Path("~/polybenchGpu")
CUDA_ROOT      = Path("/usr/local/cuda")

CUDA_ARCHES = ["sm_80", "sm_86", "sm_89", "sm_90"]
HIP_ARCHES  = ["gfx906", "gfx908", "gfx90a", "gfx942"]

BENCHMARK_NAMES = {
    "2DCONV": "2dconv", "2MM": "2mm", "3DCONV": "3dconv",
    "3MM": "3mm", "ADI": "adi", "ATAX": "atax", "BICG": "bicg",
    "CORR": "corr", "COVAR": "covar", "DOITGEN": "doitgen",
    "FDTD-2D": "fdtd-2d", "GEMM": "gemm", "GEMVER": "gemver",
    "GESUMMV": "gesummv", "GRAMSCHM": "gramschmidt",
    "JACOBI1D": "jacobi1d", "JACOBI2D": "jacobi2d",
    "LU": "lu", "MVT": "mvt", "SYR2K": "syr2k", "SYRK": "syrk",
}


def _git_rev(path: Path) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", str(path), "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        return r.stdout.strip() if r.returncode == 0 else "unknown"
    except Exception:
        return "unknown"


def _bench_name(file: Path) -> str:
    return BENCHMARK_NAMES.get(file.parent.name.upper(), file.stem.lower())


def _is_hip(file: Path) -> bool:
    return ".hip" in file.suffixes or file.suffix == ".hip"


def _find_gcc_install() -> Path:
    # Prefer the newest GCC that ships C++ headers (g++ installed, not just gcc).
    for crt in sorted(Path("/usr/lib/gcc").glob("*/*/crtbegin.o"), reverse=True):
        ver = crt.parent.name
        if Path(f"/usr/include/c++/{ver}").is_dir():
            return crt.parent
    return Path("/usr/lib/gcc/x86_64-linux-gnu/11")


def _find_rocm_root() -> Path:
    for c in sorted(Path("/opt").glob("rocm-[0-9]*"), reverse=True):
        if (c / "include/hip/hip_runtime.h").exists():
            return c
    return Path("/opt/rocm")


# ---------------------------------------------------------------------------
# Compile one file with a given arch list and pipeline
# ---------------------------------------------------------------------------

def compile_one(
    clang:           Path,
    file:            Path,
    polybench_root:  Path,
    cuda_root:       Path,
    hip_path:        Path,
    rocm_device_lib: Path,
    gcc_install_dir: Path,
    arches:          list[str],
    pipeline:        str,
    warmup:          int,
    env:             dict,
) -> tuple[float, bool, str]:
    """Returns (elapsed_seconds, ok, first_error)."""
    cmd = [str(clang), "-fclangir"]
    if pipeline == "merge":
        cmd.append("--clangir-offload-merge")
    cmd.append(f"--gcc-install-dir={gcc_install_dir}")

    if _is_hip(file):
        cuda_dir = Path(str(file.parent).replace("/HIP/", "/CUDA/", 1))
        cmd += ["-x", "hip", f"--hip-path={hip_path}",
                f"--rocm-device-lib-path={rocm_device_lib}",
                "-D__AMDGCN_WAVEFRONT_SIZE=64"]
        cmd += [f"--offload-arch={a}" for a in arches]
        if cuda_dir.is_dir():
            cmd.append(f"-I{cuda_dir}")
    else:
        cmd.append(f"--cuda-path={cuda_root}")
        cmd += [f"--cuda-gpu-arch={a}" for a in arches]
        cmd.append(f"-I{cuda_root}/include")

    cmd += ["-std=c++17", "-O3", "-c", str(file),
            f"-I{polybench_root}", f"-I{file.parent}"]

    tmp = tempfile.NamedTemporaryFile(suffix=".o", delete=False)
    tmp.close()
    cmd += ["-o", tmp.name]

    for _ in range(warmup):
        subprocess.run(cmd, capture_output=True, env=env)

    t0 = time.perf_counter()
    proc = subprocess.run(cmd, capture_output=True, text=True, env=env)
    elapsed = time.perf_counter() - t0

    try:
        os.unlink(tmp.name)
    except OSError:
        pass

    first_error = ""
    if proc.returncode != 0:
        for line in (proc.stdout + proc.stderr).splitlines():
            if "error:" in line.lower() or "fatal" in line.lower():
                first_error = line.strip()
                break

    return elapsed, proc.returncode == 0, first_error


# ---------------------------------------------------------------------------
# Run both pipelines for all files at a fixed arch count
# ---------------------------------------------------------------------------

def measure_for_n(
    n:               int,
    arches:          list[str],
    files:           list[Path],
    clang:           Path,
    polybench_root:  Path,
    cuda_root:       Path,
    hip_path:        Path,
    rocm_device_lib: Path,
    gcc_install_dir: Path,
    warmup:          int,
    jobs:            int,
    env:             dict,
) -> dict[str, dict]:
    arch_subset = arches[:n]
    tasks = [(f, p) for f in files for p in ("no-merge", "merge")]
    total = len(tasks)
    width = len(str(total))

    print(f"\n  [N={n}]  {'+'.join(arch_subset)}  ({total} jobs, warmup={warmup})")

    raw: dict[tuple[Path, str], tuple[float, bool, str]] = {}
    with ThreadPoolExecutor(max_workers=jobs) as ex:
        futures = {
            ex.submit(
                compile_one,
                clang, file, polybench_root, cuda_root, hip_path,
                rocm_device_lib, gcc_install_dir, arch_subset,
                pipeline, warmup, env,
            ): (file, pipeline)
            for file, pipeline in tasks
        }
        done = 0
        for fut in as_completed(futures):
            file, pipeline = futures[fut]
            done += 1
            elapsed, ok, err = fut.result()
            raw[(file, pipeline)] = (elapsed, ok, err)
            status = f"{elapsed:.3f}s" if ok else f"FAIL  {err[:60]}"
            print(f"    [{done:0{width}d}/{total}] {pipeline:8s}  {_bench_name(file):12s}  {status}")

    results: dict[str, dict] = {}
    for file in files:
        name = _bench_name(file)
        entry: dict = {}
        for pipeline in ("no-merge", "merge"):
            elapsed, ok, err = raw.get((file, pipeline), (None, False, ""))
            entry[pipeline] = {"elapsed": elapsed, "ok": ok}
            if not ok and err:
                entry[pipeline]["error"] = err
        results[name] = entry
    return results


# ---------------------------------------------------------------------------
# Plot
# ---------------------------------------------------------------------------

def plot_results(data: dict, out: Path | None) -> None:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not installed — skipping plot", file=sys.stderr)
        return

    datapoints = data["datapoints"]
    ns         = [dp["n_arches"] for dp in datapoints]
    all_benches = sorted({b for dp in datapoints for b in dp["benchmarks"]})
    arches_pool = data["arches_pool"]

    fig, (ax_time, ax_speedup) = plt.subplots(1, 2, figsize=(14, 5))
    fig.suptitle(
        f"ClangIR offload-merge: compile time scaling vs. # target architectures\n"
        f"arches: {' → '.join(arches_pool)}   clangir: {data['meta']['clangir_rev']}",
        fontsize=10,
    )

    # ── left: mean wall time (no-merge vs merge) ──────────────────────────────
    nm_means, mg_means = [], []
    for dp in datapoints:
        def _vals(pipeline: str) -> list[float]:
            return [
                dp["benchmarks"][b][pipeline]["elapsed"]
                for b in all_benches
                if dp["benchmarks"].get(b, {}).get(pipeline, {}).get("ok")
                and dp["benchmarks"][b][pipeline]["elapsed"] is not None
            ]
        nm = _vals("no-merge")
        mg = _vals("merge")
        nm_means.append(sum(nm) / len(nm) if nm else float("nan"))
        mg_means.append(sum(mg) / len(mg) if mg else float("nan"))

    ax_time.plot(ns, nm_means, "o-", color="tab:blue",   label="no-merge", linewidth=2)
    ax_time.plot(ns, mg_means, "s-", color="tab:orange", label="merge",    linewidth=2)
    ax_time.set_xlabel("# target architectures")
    ax_time.set_ylabel("mean compile time (s)")
    ax_time.set_xticks(ns)
    ax_time.set_xticklabels(
        [f"N={dp['n_arches']}\n({'+'.join(dp['arches'])})" for dp in datapoints],
        fontsize=7,
    )
    ax_time.legend()
    ax_time.grid(alpha=0.3)
    ax_time.set_title("Mean compile time across benchmarks")

    # ── right: per-benchmark speedup (no-merge / merge) ──────────────────────
    cmap = plt.cm.tab20
    for i, bench in enumerate(all_benches):
        valid_ns, ratios = [], []
        for dp in datapoints:
            bdata = dp["benchmarks"].get(bench, {})
            nm = bdata.get("no-merge", {})
            mg = bdata.get("merge", {})
            if (nm.get("ok") and mg.get("ok")
                    and nm.get("elapsed") and mg.get("elapsed", 0) > 0):
                ratios.append(nm["elapsed"] / mg["elapsed"])
                valid_ns.append(dp["n_arches"])
        if ratios:
            ax_speedup.plot(valid_ns, ratios, "o-",
                            color=cmap(i / max(len(all_benches), 1)),
                            label=bench, linewidth=1, markersize=4, alpha=0.85)

    ax_speedup.axhline(1.0, color="black", linestyle="--", linewidth=1, label="breakeven")
    ax_speedup.set_xlabel("# target architectures")
    ax_speedup.set_ylabel("speedup  (no-merge time / merge time)\n>1 = merge is faster")
    ax_speedup.set_xticks(ns)
    ax_speedup.set_xticklabels(
        [f"N={dp['n_arches']}\n({'+'.join(dp['arches'])})" for dp in datapoints],
        fontsize=7,
    )
    ax_speedup.legend(fontsize=6, ncol=2, loc="upper left")
    ax_speedup.grid(alpha=0.3)
    ax_speedup.set_title("Per-benchmark speedup from merge")

    fig.tight_layout()
    dest = out or Path("multiarch_scaling.png")
    fig.savefig(dest, dpi=150, bbox_inches="tight")
    print(f"\nPlot saved → {dest}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    _rocm = _find_rocm_root()

    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    src = ap.add_mutually_exclusive_group()
    src.add_argument("--cuda", action="store_true", help="Test CUDA benchmarks")
    src.add_argument("--hip",  action="store_true", help="Test HIP benchmarks")

    ap.add_argument("--clang",
                    type=lambda s: Path(s).expanduser().resolve(),
                    default=CLANG_DEFAULT.expanduser().resolve())
    ap.add_argument("--polybench-root",
                    type=lambda s: Path(s).expanduser().resolve(),
                    default=POLYBENCH_ROOT.expanduser().resolve())
    ap.add_argument("--cuda-root",
                    type=lambda s: Path(s).expanduser().resolve(),
                    default=CUDA_ROOT.expanduser().resolve())
    ap.add_argument("--hip-path",
                    type=lambda s: Path(s).expanduser().resolve(),
                    default=_rocm)
    ap.add_argument("--rocm-device-lib",
                    type=lambda s: Path(s).expanduser().resolve(),
                    default=_rocm / "amdgcn/bitcode")
    ap.add_argument("--gcc-install-dir",
                    type=lambda s: Path(s).expanduser().resolve(),
                    default=_find_gcc_install())
    ap.add_argument("--warmup",   type=int,  default=2)
    ap.add_argument("-j", "--jobs", type=int, default=4)
    ap.add_argument("--limit",    type=int,  default=0,
                    help="Cap number of source files (0 = all)")
    ap.add_argument("--out",      type=Path, default=None,
                    help="JSON output path (default: auto-timestamped)")
    ap.add_argument("--plot",     action="store_true",
                    help="Generate plot after measurement")
    ap.add_argument("--plot-out", type=Path, default=None,
                    help="Plot output path (default: multiarch_scaling.png)")
    ap.add_argument("--from",     dest="from_json", type=Path, default=None,
                    help="Skip measurement; plot from existing JSON")
    args = ap.parse_args()

    if args.from_json:
        data = json.loads(args.from_json.read_text())
        plot_results(data, args.plot_out)
        return 0

    if not args.clang.exists():
        print(f"error: --clang not found: {args.clang}", file=sys.stderr)
        return 2
    if not args.polybench_root.exists():
        print(f"error: --polybench-root not found: {args.polybench_root}", file=sys.stderr)
        return 2

    arches = HIP_ARCHES if args.hip else CUDA_ARCHES

    all_files = sorted(
        (f for pat in ("*.cu", "*.hip.cpp")
         for f in args.polybench_root.rglob(pat)
         if ".ipynb_checkpoints" not in f.parts
         and "polybenchCodesCudaOpenClHMPPOpenAcc" not in f.parts),
        key=lambda p: p.name,
    )
    if args.hip:    files = [f for f in all_files if _is_hip(f)]
    elif args.cuda: files = [f for f in all_files if not _is_hip(f)]
    else:           files = all_files
    if args.limit:  files = files[:args.limit]

    if not files:
        print("error: no source files found", file=sys.stderr)
        return 2

    env = os.environ.copy()
    env["PATH"] = f"{args.clang.parent}:{env['PATH']}"

    clangir_rev = _git_rev(args.clang.parent.parent.parent)
    scripts_rev = _git_rev(Path(__file__).parent)

    print(f"Multi-arch scaling measurement")
    print(f"  benchmarks : {len(files)}")
    print(f"  arches     : {arches}")
    print(f"  warmup     : {args.warmup}")
    print(f"  jobs       : {args.jobs}")
    print(f"  clangir    : {clangir_rev}")

    data: dict = {
        "meta": {
            "date":        datetime.now(timezone.utc).isoformat(),
            "clangir_rev": clangir_rev,
            "scripts_rev": scripts_rev,
            "warmup":      args.warmup,
            "target":      "hip" if args.hip else "cuda",
        },
        "arches_pool": arches,
        "datapoints":  [],
    }

    for n in range(1, len(arches) + 1):
        bench_results = measure_for_n(
            n=n, arches=arches, files=files,
            clang=args.clang,
            polybench_root=args.polybench_root,
            cuda_root=args.cuda_root,
            hip_path=args.hip_path,
            rocm_device_lib=args.rocm_device_lib,
            gcc_install_dir=args.gcc_install_dir,
            warmup=args.warmup,
            jobs=args.jobs,
            env=env,
        )
        data["datapoints"].append({
            "n_arches":   n,
            "arches":     arches[:n],
            "benchmarks": bench_results,
        })

    stamp    = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = args.out or Path(f"multiarch_scaling_{stamp}.json")
    out_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print(f"\nResults saved → {out_path}")

    if args.plot:
        plot_results(data, args.plot_out)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
