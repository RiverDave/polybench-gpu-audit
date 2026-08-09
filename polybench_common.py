#!/usr/bin/env python3
"""Shared helpers for the PolyBench CIR-vs-OG audit scripts.

Holds the benchmark name table, path/name helpers, and toolchain
auto-detection used by both run_compile.py and run_runtime.py.
"""

from __future__ import annotations

import fnmatch
import json
import os
import platform
import shutil
import socket
import subprocess
from datetime import datetime, timezone
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

HIP_MULTI_ARCHES  = ["gfx906", "gfx908", "gfx90a", "gfx942"]
CUDA_MULTI_ARCHES = ["sm_80",  "sm_86",  "sm_89",  "sm_90"]


# ---------------------------------------------------------------------------
# Path / name helpers
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


# ---------------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------------

def mean_stddev(xs: list[float]) -> tuple[float, float]:
    if not xs:       return float("nan"), float("nan")
    m = sum(xs) / len(xs)
    if len(xs) == 1: return m, 0.0
    return m, (sum((x - m) ** 2 for x in xs) / (len(xs) - 1)) ** 0.5


def median(xs: list[float]) -> float:
    """Median wall time — robust to the occasional scheduler-induced outlier."""
    if not xs:
        return float("nan")
    s = sorted(xs)
    mid = len(s) // 2
    return s[mid] if len(s) % 2 else (s[mid - 1] + s[mid]) / 2


# ---------------------------------------------------------------------------
# Toolchain auto-detection
# ---------------------------------------------------------------------------

def _run(cmd: list[str]) -> str:
    """Run a detection command, returning stripped stdout ('' on any failure)."""
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return out.stdout.strip() if out.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def git_rev(repo: Path) -> str:
    rev = _run(["git", "-C", str(repo), "rev-parse", "--short", "HEAD"])
    return rev or "unknown"


def find_rocm_root() -> Path:
    for c in sorted(Path("/opt").glob("rocm-[0-9]*"), reverse=True):
        if (c / "include/hip/hip_runtime.h").exists():
            return c
    return Path("/opt/rocm")


def find_rocm_device_lib(rocm: Path) -> Path:
    """Locate the amdgcn bitcode dir, preferring the versioned ROCm install."""
    for base in sorted(Path("/opt").glob("rocm-[0-9]*"), reverse=True):
        bitcode = base / "amdgcn/bitcode"
        if bitcode.is_dir():
            return bitcode
    return rocm / "amdgcn/bitcode"


def find_gcc_install() -> Path:
    for crt in sorted(Path("/usr/lib/gcc").glob("*/*/crtbegin.o"), reverse=True):
        return crt.parent
    return Path("/usr/lib/gcc/x86_64-linux-gnu/11")


def find_clang() -> Path:
    """Locate a locally built clang++ (the CIR-capable one), else fall back to PATH."""
    candidates = [
        Path.home() / "llvm-project/build/bin/clang++",
        Path.home() / "polybench-gpu-audit/llvm-project/build/bin/clang++",
    ]
    for c in candidates:
        if c.exists():
            return c
    found = shutil.which("clang++")
    return Path(found) if found else candidates[0]


def _has_libdevice(root: Path) -> bool:
    """True if `root` has the device-compile bitcode clang hardcodes as
    <cuda-path>/nvvm/libdevice/libdevice*.bc.

    This is the check that matters, not cuda_runtime.h: on Debian-family
    systems clang always additionally searches /usr/include regardless of
    --cuda-path, so a root missing headers still compiles fine (host headers
    resolve from the system path). A root missing libdevice does not fail
    until a kernel calls a math builtin (expf, sqrtf, ...), at which point
    clang errors with "cannot find libdevice for <arch>" — silent until then.
    """
    return any(root.glob("nvvm/libdevice/libdevice*.bc"))


def find_cuda_root() -> Path:
    """Locate a CUDA toolkit root with libdevice bitcode.

    Prefers the nvcc-derived root, then falls back to well-known locations —
    but only among roots that actually have libdevice; a root missing it is
    never preferred over one that has it, even if found first (some distros
    split the install: headers under /usr/include, libdevice under
    /usr/local/cuda, with nvcc itself resolving to neither).
    """
    candidates = []
    if (nvcc := shutil.which("nvcc")):
        candidates.append(Path(nvcc).resolve().parent.parent)
    candidates.append(Path("/usr/local/cuda"))
    candidates += sorted(Path("/usr/local").glob("cuda-[0-9]*"), reverse=True)
    candidates.append(Path("/opt/cuda"))

    for c in candidates:
        if _has_libdevice(c):
            return c
    # Nothing had libdevice; fall back to the first with at least headers,
    # so callers can still compile host-only code or pass -nocudalib.
    for c in candidates:
        if (c / "include/cuda_runtime.h").exists():
            return c
    return Path("/usr/local/cuda")


def detect_hip_arch(fallback: str = "gfx942") -> tuple[str, bool]:
    """Query the AMD GPU for its gfx target. Returns (arch, detected)."""
    rocm = find_rocm_root()
    tools = [
        rocm / "llvm/bin/amdgpu-arch",
        rocm / "bin/rocm_agent_enumerator",
        Path("/opt/rocm/llvm/bin/amdgpu-arch"),
    ]
    tools += [Path(p) for t in ("amdgpu-arch", "rocm_agent_enumerator")
              if (p := shutil.which(t))]
    for tool in tools:
        if not Path(tool).exists():
            continue
        for line in _run([str(tool)]).splitlines():
            if line.strip().startswith("gfx"):
                return line.strip(), True
    return fallback, False


def detect_cuda_arch(fallback: str = "sm_86") -> tuple[str, bool]:
    """Query the NVIDIA GPU for its compute capability (8.6 -> sm_86). Returns (arch, detected)."""
    cap = _run(["nvidia-smi", "--query-gpu=compute_cap", "--format=csv,noheader"])
    first = cap.splitlines()[0].strip() if cap else ""
    if first and "." in first:
        major, _, minor = first.partition(".")
        if major.isdigit() and minor.isdigit():
            return f"sm_{major}{minor}", True
    if (p := shutil.which("nvptx-arch")):
        for line in _run([p]).splitlines():
            if line.strip().startswith("sm_"):
                return line.strip(), True
    return fallback, False


# ---------------------------------------------------------------------------
# Provenance + machine config
# ---------------------------------------------------------------------------

def provenance() -> dict[str, str]:
    """Environment fields recorded in every report, for reproducibility."""
    cpu = ""
    try:
        for line in Path("/proc/cpuinfo").read_text().splitlines():
            if line.startswith("model name"):
                cpu = line.split(":", 1)[1].strip()
                break
    except OSError:
        pass

    gpu = ""
    for line in _run(["rocm-smi", "--showproductname"]).splitlines():
        if "Card Series" in line:
            gpu = line.split(":")[-1].strip()
            break
    if not gpu:
        gpu = _run(["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"]).split("\n")[0].strip()

    rocm_ver = ""
    for f in (Path("/opt/rocm/.info/version"), find_rocm_root() / ".info/version"):
        if f.exists():
            rocm_ver = f.read_text().strip()
            break

    cuda_ver = ""
    if (nvcc := shutil.which("nvcc")):
        for line in _run([nvcc, "--version"]).splitlines():
            if "release" in line:
                cuda_ver = line.split("release")[-1].strip().split(",")[0].strip()
                break

    driver_ver = ""
    if shutil.which("nvidia-smi"):
        lines = _run(["nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"]).splitlines()
        driver_ver = lines[0].strip() if lines else ""
    elif (rsmi := shutil.which("rocm-smi")):
        for line in _run([rsmi, "--showdriverversion"]).splitlines():
            if ":" in line:
                driver_ver = line.split(":", 1)[-1].strip()
                break
        if not driver_ver:
            driver_ver = _run(["cat", "/sys/module/amdgpu/version"])

    ptxas_ver = ""
    if (ptxas := shutil.which("ptxas")):
        first_line = _run([ptxas, "--version"]).splitlines()
        if first_line:
            ptxas_ver = first_line[0].strip()

    os_release = _run(["lsb_release", "-ds"]) or platform.version() or ""

    return {
        "hostname":       socket.gethostname(),
        "timestamp_utc":  datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "cpu":            cpu,
        "cpu_count":      str(len(os.sched_getaffinity(0))),
        "kernel":         platform.release(),
        "gpu":            gpu,
        "rocm_version":   rocm_ver,
        "cuda_version":   cuda_ver,
        "driver_version": driver_ver,
        "ptxas_version":  ptxas_ver,
        "os_release":     os_release,
    }


def provenance_lines(prov: dict[str, str]) -> list[str]:
    """Provenance rendered as markdown bullets for a report header."""
    order = ["hostname", "cpu", "cpu_count", "gpu", "kernel",
             "rocm_version", "cuda_version", "driver_version",
             "ptxas_version", "os_release", "timestamp_utc"]
    return [f"- {k.replace('_', ' ')}: `{prov[k]}`" for k in order if prov.get(k)]


def load_machine_config(config: Path, machine: str | None = None) -> dict:
    """Resolve this machine's profile from machines.json.

    Selection order: explicit --machine name, exact hostname key, then any
    profile whose "hostname_patterns" glob matches (devcloud hostnames are
    regenerated per instance, so exact keys alone are brittle).
    """
    if not config.exists():
        return {}
    data = json.loads(config.read_text())

    if machine:
        if machine not in data:
            raise SystemExit(f"error: machine '{machine}' not in {config}. "
                             f"Known: {', '.join(sorted(data))}")
        return data[machine]

    host = socket.gethostname()
    if host in data:
        return data[host]
    for cfg in data.values():
        for pattern in cfg.get("hostname_patterns", []):
            if fnmatch.fnmatch(host, pattern):
                return cfg
    return {}
