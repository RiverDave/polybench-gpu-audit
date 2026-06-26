#!/usr/bin/env python3
"""Measure where the --clangir-offload-merge overhead goes for a single benchmark.

Pipeline (merge arm):
  step 1  cc1 host   -emit-cir  (host frontend  → host.cir)
  step 2  cc1 device -emit-cir  (device frontend → device.cir)
  step 3  cir-offload-merge --combine
  step 4  cir-offload-merge --split
  step 5  cc1 device -x cir -S  (parseCIR + lower device → PTX)
  step 6  cc1 host   -x cir -emit-obj  (parseCIR + lower host → obj)

Pipeline (no-merge arm, baseline):
  step A  cc1 device -x cuda -S   (full device pipeline, no CIR serialization)
  step B  cc1 host   -x cuda -emit-obj  (full host pipeline)

Usage:
  python3 measure_merge_overhead.py --bench ~/polybenchGpu/CUDA/3MM/3mm.cu
"""

from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path


CLANG    = Path("~/llvm-project/build/bin/clang++").expanduser()
CC1      = Path("~/llvm-project/build/bin/clang-23").expanduser()
MERGE    = Path("~/llvm-project/build/bin/cir-offload-merge").expanduser()
GCC_DIR  = "/usr/lib/gcc/x86_64-linux-gnu/11"
CUDA     = "/usr/local/cuda"
ARCH     = "sm_86"
LIBDEV   = f"{CUDA}/nvvm/libdevice/libdevice.10.bc"
RESDIR   = Path("~/llvm-project/build/lib/clang/23").expanduser()

# Absolute paths matching the -### output (4 levels up from GCC_DIR)
_CXX11       = "/usr/include/c++/11"
_CXX11_ARCH  = "/usr/include/x86_64-linux-gnu/c++/11"
_CXX11_BACK  = "/usr/include/c++/11/backward"
_ARCH_INC    = "/usr/lib/gcc/x86_64-linux-gnu/11/../../../../x86_64-linux-gnu/include"

# host-side system include flags (same as -### output)
_HOST_ISYSTEM = [
    "-internal-isystem", f"{RESDIR}/include/cuda_wrappers",
    "-include", "__clang_cuda_runtime_wrapper.h",
    "-I", f"{CUDA}/include",
    "-internal-isystem", _CXX11,
    "-internal-isystem", _CXX11_ARCH,
    "-internal-isystem", _CXX11_BACK,
    "-internal-isystem", _CXX11,
    "-internal-isystem", _CXX11_ARCH,
    "-internal-isystem", _CXX11_BACK,
    "-internal-isystem", f"{RESDIR}/include",
    "-internal-isystem", "/usr/local/include",
    "-internal-isystem", _ARCH_INC,
    "-internal-externc-isystem", "/usr/include/x86_64-linux-gnu",
    "-internal-externc-isystem", "/include",
    "-internal-externc-isystem", "/usr/include",
    "-internal-isystem", f"{CUDA}/include",
]
_DEV_ISYSTEM = [
    "-internal-isystem", f"{RESDIR}/include/cuda_wrappers",
    "-include", "__clang_cuda_runtime_wrapper.h",
    "-I", f"{CUDA}/include",
    "-internal-isystem", _CXX11,
    "-internal-isystem", _CXX11_ARCH,
    "-internal-isystem", _CXX11_BACK,
    "-internal-isystem", _CXX11,
    "-internal-isystem", _CXX11_ARCH,
    "-internal-isystem", _CXX11_BACK,
    "-internal-isystem", f"{RESDIR}/include",
    "-internal-isystem", "/usr/local/include",
    "-internal-isystem", _ARCH_INC,
    "-internal-externc-isystem", "/usr/include/x86_64-linux-gnu",
    "-internal-externc-isystem", "/include",
    "-internal-externc-isystem", "/usr/include",
    "-internal-isystem", f"{CUDA}/include",
]

TARGET_HOST = "host-x86_64-unknown-linux-gnu"
TARGET_DEV  = f"cuda-nvptx64-nvidia-cuda-unknown-{ARCH}"

WARMUP = 3


def run(cmd: list[str], label: str, warmup: int = WARMUP) -> tuple[float, str, str]:
    env = os.environ.copy()
    env["PATH"] = f"{CLANG.parent}:{env['PATH']}"
    for _ in range(warmup):
        subprocess.run(cmd, capture_output=True, env=env)
    t0 = time.perf_counter()
    proc = subprocess.run(cmd, capture_output=True, text=True, env=env)
    elapsed = time.perf_counter() - t0
    if proc.returncode != 0:
        print(f"  ERROR in {label}:", file=sys.stderr)
        print(proc.stderr[:800], file=sys.stderr)
        sys.exit(1)
    return elapsed, proc.stdout, proc.stderr


def host_emit_cir_cmd(src: Path, out: Path, extra_includes: list[str]) -> list[str]:
    return [
        str(CC1), "-cc1",
        "-triple", "x86_64-unknown-linux-gnu",
        "-aux-triple", "nvptx64-nvidia-cuda",
        "-O3", "-fclangir", "-emit-cir",
        "-disable-free", "-clear-ast-before-backend",
        "-main-file-name", src.name,
        "-mrelocation-model", "pic", "-pic-level", "2", "-pic-is-pie",
        "-mframe-pointer=none", "-fmath-errno", "-ffp-contract=on",
        "-fno-rounding-math", "-mconstructor-aliases",
        "-funwind-tables=2",
        "-target-cpu", "x86-64", "-tune-cpu", "generic",
        "-debugger-tuning=gdb",
        "-resource-dir", str(RESDIR),
        "-target-sdk-version=12.8",
        f"-D__CUDA_ARCH_LIST__=860",
        *_HOST_ISYSTEM,
        *extra_includes,
        "-std=c++17", "-fdeprecated-macro",
        "-ferror-limit", "19", "--offload-new-driver",
        "-fgnuc-version=4.2.1", "-fskip-odr-check-in-gmf",
        "-fcxx-exceptions", "-fexceptions",
        "-vectorize-loops", "-vectorize-slp",
        "-cuid=deadbeef00000001",
        "-o", str(out),
        "-x", "cuda", str(src),
    ]


def dev_emit_cir_cmd(src: Path, out: Path, extra_includes: list[str]) -> list[str]:
    return [
        str(CC1), "-cc1",
        "-triple", "nvptx64-nvidia-cuda",
        "-aux-triple", "x86_64-unknown-linux-gnu",
        "-O3", "-fclangir", "-emit-cir",
        "-disable-free", "-clear-ast-before-backend",
        "-main-file-name", src.name,
        "-mrelocation-model", "static", "-mframe-pointer=all",
        "-fno-rounding-math", "-no-integrated-as",
        "-aux-target-cpu", "x86-64",
        "-fcuda-is-device",
        "-mllvm", "-enable-memcpyopt-without-libcalls",
        "-fno-threadsafe-statics",
        "-mlink-builtin-bitcode", LIBDEV,
        "-target-cpu", ARCH, "-target-feature", "+ptx87",
        "-debugger-tuning=gdb", "-fno-dwarf-directory-asm",
        "-resource-dir", str(RESDIR),
        "-target-sdk-version=12.8",
        f"-D__CUDA_ARCH_LIST__=860",
        *_DEV_ISYSTEM,
        *extra_includes,
        "-std=c++17", "-fdeprecated-macro",
        "-fno-autolink", "-ferror-limit", "19", "--offload-new-driver",
        "-fgnuc-version=4.2.1", "-fskip-odr-check-in-gmf",
        "-fcxx-exceptions", "-fexceptions",
        "-vectorize-loops", "-vectorize-slp",
        "-cuid=deadbeef00000001",
        "-o", str(out),
        "-x", "cuda", str(src),
    ]


def dev_cir_to_ptx_cmd(cir: Path, out: Path) -> list[str]:
    return [
        str(CC1), "-cc1",
        "-triple", "nvptx64-nvidia-cuda",
        "-aux-triple", "x86_64-unknown-linux-gnu",
        "-O3", "-fclangir", "-S",
        "-disable-free", "-clear-ast-before-backend",
        "-mrelocation-model", "static", "-mframe-pointer=all",
        "-fno-rounding-math", "-no-integrated-as",
        "-aux-target-cpu", "x86-64",
        "-fcuda-is-device",
        "-mllvm", "-enable-memcpyopt-without-libcalls",
        "-fno-threadsafe-statics",
        "-mlink-builtin-bitcode", LIBDEV,
        "-target-cpu", ARCH, "-target-feature", "+ptx87",
        "-debugger-tuning=gdb", "-fno-dwarf-directory-asm",
        "-resource-dir", str(RESDIR),
        "-std=c++17", "-fno-autolink",
        "-ferror-limit", "19", "--offload-new-driver",
        "-fgnuc-version=4.2.1", "-fskip-odr-check-in-gmf",
        "-vectorize-loops", "-vectorize-slp",
        "-cuid=deadbeef00000001",
        "-o", str(out),
        "-x", "cir", str(cir),
    ]


def host_cir_to_obj_cmd(cir: Path, out: Path) -> list[str]:
    return [
        str(CC1), "-cc1",
        "-triple", "x86_64-unknown-linux-gnu",
        "-aux-triple", "nvptx64-nvidia-cuda",
        "-O3", "-fclangir", "-emit-obj",
        "-disable-free", "-clear-ast-before-backend",
        "-mrelocation-model", "pic", "-pic-level", "2", "-pic-is-pie",
        "-mframe-pointer=none", "-fmath-errno", "-ffp-contract=on",
        "-fno-rounding-math", "-mconstructor-aliases",
        "-funwind-tables=2",
        "-target-cpu", "x86-64", "-tune-cpu", "generic",
        "-debugger-tuning=gdb",
        "-resource-dir", str(RESDIR),
        "-std=c++17",
        "-ferror-limit", "19", "--offload-new-driver",
        "-fgnuc-version=4.2.1", "-fskip-odr-check-in-gmf",
        "-vectorize-loops", "-vectorize-slp",
        "-cuid=deadbeef00000001",
        "-o", str(out),
        "-x", "cir", str(cir),
    ]


def dev_cuda_to_ptx_cmd(src: Path, out: Path, extra_includes: list[str]) -> list[str]:
    return [
        str(CC1), "-cc1",
        "-triple", "nvptx64-nvidia-cuda",
        "-aux-triple", "x86_64-unknown-linux-gnu",
        "-O3", "-fclangir", "-S",
        "-disable-free", "-clear-ast-before-backend",
        "-main-file-name", src.name,
        "-mrelocation-model", "static", "-mframe-pointer=all",
        "-fno-rounding-math", "-no-integrated-as",
        "-aux-target-cpu", "x86-64",
        "-fcuda-is-device",
        "-mllvm", "-enable-memcpyopt-without-libcalls",
        "-fno-threadsafe-statics",
        "-mlink-builtin-bitcode", LIBDEV,
        "-target-cpu", ARCH, "-target-feature", "+ptx87",
        "-debugger-tuning=gdb", "-fno-dwarf-directory-asm",
        "-resource-dir", str(RESDIR),
        "-target-sdk-version=12.8",
        f"-D__CUDA_ARCH_LIST__=860",
        *_DEV_ISYSTEM,
        *extra_includes,
        "-std=c++17", "-fdeprecated-macro",
        "-fno-autolink", "-ferror-limit", "19", "--offload-new-driver",
        "-fgnuc-version=4.2.1", "-fskip-odr-check-in-gmf",
        "-fcxx-exceptions", "-fexceptions",
        "-vectorize-loops", "-vectorize-slp",
        "-cuid=deadbeef00000001",
        "-o", str(out),
        "-x", "cuda", str(src),
    ]


def host_cuda_to_obj_cmd(src: Path, out: Path, extra_includes: list[str]) -> list[str]:
    return [
        str(CC1), "-cc1",
        "-triple", "x86_64-unknown-linux-gnu",
        "-aux-triple", "nvptx64-nvidia-cuda",
        "-O3", "-fclangir", "-emit-obj",
        "-disable-free", "-clear-ast-before-backend",
        "-main-file-name", src.name,
        "-mrelocation-model", "pic", "-pic-level", "2", "-pic-is-pie",
        "-mframe-pointer=none", "-fmath-errno", "-ffp-contract=on",
        "-fno-rounding-math", "-mconstructor-aliases",
        "-funwind-tables=2",
        "-target-cpu", "x86-64", "-tune-cpu", "generic",
        "-debugger-tuning=gdb",
        "-resource-dir", str(RESDIR),
        "-target-sdk-version=12.8",
        f"-D__CUDA_ARCH_LIST__=860",
        *_HOST_ISYSTEM,
        *extra_includes,
        "-std=c++17", "-fdeprecated-macro",
        "-ferror-limit", "19", "--offload-new-driver",
        "-fgnuc-version=4.2.1", "-fskip-odr-check-in-gmf",
        "-fcxx-exceptions", "-fexceptions",
        "-vectorize-loops", "-vectorize-slp",
        "-cuid=deadbeef00000001",
        "-o", str(out),
        "-x", "cuda", str(src),
    ]


def fmt(seconds: float) -> str:
    return f"{seconds*1000:.1f} ms"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bench", type=Path,
                    default=Path("~/polybenchGpu/CUDA/3MM/3mm.cu").expanduser())
    ap.add_argument("--warmup", type=int, default=WARMUP)
    args = ap.parse_args()

    src = args.bench.expanduser().resolve()
    if not src.exists():
        print(f"error: {src} not found", file=sys.stderr)
        return 1

    extra_inc = [f"-I{src.parent}"]

    with tempfile.TemporaryDirectory(prefix="cir-measure-") as td:
        d = Path(td)

        host_cir    = d / "host.cir"
        dev_cir     = d / "device.cir"
        merged_cir  = d / "merged.cir"
        split_host  = d / "split_host.cir"
        split_dev   = d / "split_device.cir"
        ptx_merge   = d / "device_merge.s"
        obj_merge   = d / "host_merge.o"
        ptx_nomerge = d / "device_nomerge.s"
        obj_nomerge = d / "host_nomerge.o"

        print(f"\nBenchmark: {src.name}")
        print(f"Warmup runs: {args.warmup}\n")
        print("=" * 60)
        print("MERGE PIPELINE")
        print("=" * 60)

        t_host_emit, _, _ = run(
            host_emit_cir_cmd(src, host_cir, extra_inc),
            "host -emit-cir", warmup=args.warmup,
        )
        print(f"  step 1  host  -emit-cir   (frontend serialize): {fmt(t_host_emit)}"
              f"  [{host_cir.stat().st_size/1024:.0f} KB]")

        t_dev_emit, _, _ = run(
            dev_emit_cir_cmd(src, dev_cir, extra_inc),
            "device -emit-cir", warmup=args.warmup,
        )
        print(f"  step 2  dev   -emit-cir   (frontend serialize): {fmt(t_dev_emit)}"
              f"  [{dev_cir.stat().st_size/1024:.0f} KB]")

        combine_cmd = [
            str(MERGE), "-combine",
            f"-targets={TARGET_HOST},{TARGET_DEV}",
            f"-output={merged_cir}",
            f"-input={host_cir}",
            f"-input={dev_cir}",
        ]
        t_combine, _, _ = run(combine_cmd, "cir-offload-merge --combine", warmup=args.warmup)
        print(f"  step 3  cir-offload-merge --combine          : {fmt(t_combine)}"
              f"  [{merged_cir.stat().st_size/1024:.0f} KB]")

        split_cmd = [
            str(MERGE), "-split",
            f"-targets={TARGET_HOST},{TARGET_DEV}",
            f"-input={merged_cir}",
            f"-output={split_host}",
            f"-output={split_dev}",
        ]
        t_split, _, _ = run(split_cmd, "cir-offload-merge --split", warmup=args.warmup)
        split_host_kb = split_host.stat().st_size / 1024
        split_dev_kb  = split_dev.stat().st_size / 1024
        print(f"  step 4  cir-offload-merge --split            : {fmt(t_split)}"
              f"  [host={split_host_kb:.0f} KB, dev={split_dev_kb:.0f} KB]")

        t_dev_resume, _, _ = run(
            dev_cir_to_ptx_cmd(split_dev, ptx_merge),
            "device -x cir -S (parseCIR+lower)", warmup=args.warmup,
        )
        print(f"  step 5  dev   -x cir  -S  (parseCIR + lower) : {fmt(t_dev_resume)}")

        t_host_resume, _, _ = run(
            host_cir_to_obj_cmd(split_host, obj_merge),
            "host -x cir -emit-obj (parseCIR+lower)", warmup=args.warmup,
        )
        print(f"  step 6  host  -x cir  -emit-obj (parseCIR)   : {fmt(t_host_resume)}")

        merge_total = t_host_emit + t_dev_emit + t_combine + t_split + t_dev_resume + t_host_resume
        print(f"\n  MERGE total (sum of steps, excl ptxas/fatbinary): {fmt(merge_total)}")

        print()
        print("=" * 60)
        print("NO-MERGE PIPELINE (baseline)")
        print("=" * 60)

        t_dev_direct, _, _ = run(
            dev_cuda_to_ptx_cmd(src, ptx_nomerge, extra_inc),
            "device -x cuda -S (direct)", warmup=args.warmup,
        )
        print(f"  step A  dev   -x cuda -S  (full pipeline)     : {fmt(t_dev_direct)}")

        t_host_direct, _, _ = run(
            host_cuda_to_obj_cmd(src, obj_nomerge, extra_inc),
            "host -x cuda -emit-obj (direct)", warmup=args.warmup,
        )
        print(f"  step B  host  -x cuda -emit-obj (full pipeline): {fmt(t_host_direct)}")

        nomerge_total = t_dev_direct + t_host_direct
        print(f"\n  NO-MERGE total (sum of steps, excl ptxas/fatbinary): {fmt(nomerge_total)}")

        print()
        print("=" * 60)
        print("OVERHEAD BREAKDOWN")
        print("=" * 60)
        overhead = merge_total - nomerge_total

        def pct(x: float) -> str:
            return f"{x/nomerge_total*100:+.1f}%"

        rows = [
            ("CIR serialize host  (step 1 vs nothing)",     t_host_emit,                          "new cost"),
            ("CIR serialize dev   (step 2 vs nothing)",     t_dev_emit,                           "new cost"),
            ("cir-offload-merge --combine (step 3)",        t_combine,                            "new cost"),
            ("cir-offload-merge --split   (step 4)",        t_split,                              "new cost"),
            ("CIR resume dev  (step 5 vs step A)",          t_dev_resume  - t_dev_direct,         "delta"),
            ("CIR resume host (step 6 vs step B)",          t_host_resume - t_host_direct,        "delta"),
        ]

        for label, val, kind in rows:
            sign = "+" if val >= 0 else ""
            print(f"  {label:<52} {sign}{fmt(val):>9}  ({pct(val) if kind == 'new cost' else f'{val*1000:+.1f} ms'})")

        print(f"\n  Total overhead: {fmt(overhead)}  ({pct(overhead)})")

        print()
        print("=" * 60)
        print("CIR FILE SIZES")
        print("=" * 60)
        for label, p in [
            ("host.cir   (emit, before merge)", host_cir),
            ("device.cir (emit, before merge)", dev_cir),
            ("merged.cir (combined)",           merged_cir),
            ("split_host.cir (after split)",    split_host),
            ("split_dev.cir  (after split)",    split_dev),
        ]:
            kb = p.stat().st_size / 1024
            print(f"  {label:<40} {kb:>8.1f} KB")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
