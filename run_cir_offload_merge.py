#!/usr/bin/env python3
"""CIR compile-time (and optionally runtime) comparison: no-merge vs --clangir-offload-merge.

Both arms use -fclangir. The "merge" arm additionally passes
--clangir-offload-merge.

Examples:
  # CUDA sm_86 — compile-time only
  python3 run_cir_offload_merge.py --cuda \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \\
      --arch sm_86 -j $(nproc)

  # CUDA sm_86 — compile-time + runtime
  python3 run_cir_offload_merge.py --cuda --runtime \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \\
      --arch sm_86 -j $(nproc)

  # CUDA multi-arch (compile-time only; runtime uses primary --arch)
  python3 run_cir_offload_merge.py --cuda --multi-arch \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \\
      -j $(nproc)

  # HIP gfx942
  python3 run_cir_offload_merge.py --hip \\
      --clang ~/llvm-project/build/bin/clang++ \\
      --hip-path /opt/rocm --rocm-device-lib-path /opt/rocm/amdgcn/bitcode \\
      --hip-arch gfx942 -j $(nproc)
"""

from __future__ import annotations

import argparse
import math
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
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
_GPU_RUNTIME = re.compile(r"GPU Runtime:\s*([\d.]+)s")

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

PIPELINES = ("no-merge", "merge")

_EXTERN_RTCLOCK = re.compile(r"extern\s+double\s+rtclock")

# C++ shim: wraps C-linkage _pb_rtclock (from polybench.o) for kernels that
# declare `extern double rtclock(void)` in a .cu file (e.g. DOITGEN).
_POLYBENCH_SHIM = (
    'extern "C" { double _pb_rtclock(); }\n'
    'double rtclock() { return _pb_rtclock(); }\n'
)


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class TimingResult:
    benchmark:   str
    source_set:  str
    file:        Path
    pipeline:    str   # "no-merge" or "merge"
    arch:        str
    ok:          bool
    elapsed:     float
    phases:      dict[str, float]
    log:         Path
    command:     list[str]
    first_error: str = ""


@dataclass
class RuntimeResult:
    benchmark:   str
    source_set:  str
    file:        Path
    pipeline:    str   # "no-merge" or "merge"
    arch:        str
    compile_ok:  bool
    compile_log: Path
    binary:      Path | None
    times:       list[float] = field(default_factory=list)
    first_error: str = ""


# ---------------------------------------------------------------------------
# Auto-detection
# ---------------------------------------------------------------------------

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

def _find_gcc_install() -> Path:
    # Prefer the newest GCC that ships C++ headers (g++ installed, not just gcc).
    for crt in sorted(Path("/usr/lib/gcc").glob("*/*/crtbegin.o"), reverse=True):
        ver = crt.parent.name
        if Path(f"/usr/include/c++/{ver}").is_dir():
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

def _mean_stddev(xs: list[float]) -> tuple[float, float]:
    if not xs:       return float("nan"), float("nan")
    m = sum(xs) / len(xs)
    if len(xs) == 1: return m, 0.0
    return m, math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))

def _parse_time(stdout: str) -> float | None:
    for line in reversed(stdout.splitlines()):
        m = _GPU_RUNTIME.search(line)
        if m:
            return float(m.group(1))
        try:
            return float(line.strip())
        except ValueError:
            continue
    return None

def _needs_polybench_c(file: Path) -> bool:
    try:
        content = file.read_text(errors="ignore")
        return bool(_EXTERN_RTCLOCK.search(content)) and "polybench.c" not in content
    except OSError:
        return False

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
                    phases[name] = phases.get(name, 0.0) + float(m.group(1))
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
# Compile-time measurement
# ---------------------------------------------------------------------------

def timing_compile_one(
    clang:                Path,
    root:                 Path,
    cuda_root:            Path,
    hip_path:             Path,
    rocm_device_lib_path: Path,
    gcc_install_dir:      Path,
    arch:                 str,
    pipeline:             str,   # "no-merge" or "merge"
    file:                 Path,
    include_dirs:         list[Path],
    log_dir:              Path,
    warmup:               int = 2,
) -> TimingResult:
    log = log_dir / f"{safe_name(root, file)}.cir-{pipeline}.{arch}.log"

    # Both arms: full host+device compile (-c, no device-only).
    # The only variable is --clangir-offload-merge.
    cmd = [str(clang), "-fclangir"]
    if pipeline == "merge":
        cmd.append("--clangir-offload-merge")
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
    else:
        cmd.extend([
            f"--cuda-path={cuda_root}",
            f"--cuda-gpu-arch={arch}",
            # Host-side CIR compilation doesn't auto-inject the CUDA include
            # path for either arm, so add it explicitly.
            f"-I{cuda_root}/include",
        ])

    cmd.extend([
        "-std=c++17", "-O3",
        "-ftime-report", "-mllvm", "-time-passes",
        "-mmlir", "--mlir-pass-statistics",
        "-c", str(file), f"-I{root}", f"-I{file.parent}",
    ])
    cmd.extend(f"-I{d}" for d in include_dirs)

    # Both arms produce a fat object — /dev/null won't work for either.
    tmp_out = tempfile.NamedTemporaryFile(suffix=".o", delete=False)
    tmp_out.close()
    cmd.extend(["-o", tmp_out.name])

    env = os.environ.copy()
    env["PATH"] = f"{clang.parent}:{env['PATH']}"

    for _ in range(warmup):
        subprocess.run(cmd, capture_output=True, env=env)

    start = time.perf_counter()
    proc = subprocess.run(cmd, text=True, capture_output=True, env=env)
    elapsed = time.perf_counter() - start

    try:
        os.unlink(tmp_out.name)
    except OSError:
        pass

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
# Runtime measurement
# ---------------------------------------------------------------------------

def _compile_polybench_objs(
    clang: Path, common_dir: Path, gcc_install_dir: Path, build_dir: Path,
) -> list[Path]:
    pb_obj   = build_dir / "polybench.o"
    shim_src = build_dir / "polybench_shim.cpp"
    shim_obj = build_dir / "polybench_shim.o"

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


def runtime_compile_one(
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
) -> RuntimeResult:
    tag = f"{safe_name(root, file)}.rt-{pipeline}.{arch}"
    log    = log_dir   / f"{tag}.log"
    binary = build_dir / tag

    cmd = [str(clang), "-fclangir"]
    if pipeline == "merge":
        cmd.append("--clangir-offload-merge")
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

    extra_obj = [str(o) for o in polybench_objs] if _needs_polybench_c(file) else []
    cmd.extend([
        "-std=c++17", "-O3", "-DPOLYBENCH_TIME=1",
        str(file),
        f"-I{common_dir}", f"-I{file.parent}", f"-I{root}",
        "-lm", *link_flags, *extra_obj, "-o", str(binary),
    ])

    env = os.environ.copy()
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

    return RuntimeResult(
        benchmark=benchmark_name(file), source_set=source_set(root, file),
        file=file, pipeline=pipeline, arch=arch,
        compile_ok=ok, compile_log=log,
        binary=binary if ok else None,
        first_error=first_error,
    )


def run_binary(result: RuntimeResult, runs: int, warmup: int) -> None:
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
        pass


# ---------------------------------------------------------------------------
# Reporting — compile-time
# ---------------------------------------------------------------------------

def _phase_rows(results: list[TimingResult]) -> list[str]:
    all_phases = sorted({p for r in results for p in r.phases})
    lines = ["| Phase | no-merge avg | merge avg | delta |", "|---|---:|---:|---:|"]
    for phase in all_phases:
        nt = [r.phases[phase] for r in results if r.pipeline == "no-merge" and r.ok and phase in r.phases]
        mt = [r.phases[phase] for r in results if r.pipeline == "merge"    and r.ok and phase in r.phases]
        na = sum(nt) / len(nt) if nt else None
        ma = sum(mt) / len(mt) if mt else None
        d  = (f"+{ma-na:.3f}" if ma >= na else f"{ma-na:.3f}") if (na is not None and ma is not None) else "—"
        lines.append(
            f"| {phase} | {f'{na:.3f}' if na is not None else '—'}"
            f" | {f'{ma:.3f}' if ma is not None else '—'} | {d} |"
        )
    nt = [r.elapsed for r in results if r.pipeline == "no-merge" and r.ok]
    mt = [r.elapsed for r in results if r.pipeline == "merge"    and r.ok]
    if nt and mt:
        na, ma = sum(nt) / len(nt), sum(mt) / len(mt)
        d = f"+{ma-na:.3f}" if ma >= na else f"{ma-na:.3f}"
        lines.append(f"| **Total (wall)** | **{na:.3f}** | **{ma:.3f}** | **{d}** |")
    return lines


def _arch_section(results: list[TimingResult], root: Path, arch: str) -> list[str]:
    by_key        = {(r.file, r.pipeline): r for r in results}
    files_ordered = list(dict.fromkeys(r.file for r in results))
    nm_ok = sum(1 for f in files_ordered if by_key.get((f, "no-merge")) and by_key[(f, "no-merge")].ok)
    mg_ok = sum(1 for f in files_ordered if by_key.get((f, "merge"))    and by_key[(f, "merge")].ok)

    all_phases = sorted({p for r in results for p in r.phases})
    header = (
        "| Benchmark | Source set |"
        + "".join(f" no-merge {ph} | merge {ph} |" for ph in all_phases)
        + " no-merge total | merge total | merge/no-merge |"
    )
    sep = "|---|---:|" + "---:|---:|" * len(all_phases) + "---:|---:|---:|"

    lines = [
        f"### arch: `{arch}`", "",
        f"- no-merge OK: `{nm_ok}/{len(files_ordered)}`",
        f"- merge OK:    `{mg_ok}/{len(files_ordered)}`",
        "", *_phase_rows(results), "", header, sep,
    ]
    for file in files_ordered:
        nm  = by_key.get((file, "no-merge"))
        mg  = by_key.get((file, "merge"))
        ref = nm or mg
        assert ref is not None
        row = f"| {ref.benchmark} | {ref.source_set} |"
        for ph in all_phases:
            row += f" {f'{nm.phases[ph]:.3f}' if nm and nm.ok and ph in nm.phases else '—'}"
            row += f" | {f'{mg.phases[ph]:.3f}' if mg and mg.ok and ph in mg.phases else '—'} |"
        nm_t  = nm.elapsed if nm and nm.ok else None
        mg_t  = mg.elapsed if mg and mg.ok else None
        ratio = f"{mg_t / nm_t:.3f}" if (nm_t is not None and mg_t is not None and nm_t > 0) else "—"
        row  += f" {f'{nm_t:.3f}' if nm_t is not None else '—'} | {f'{mg_t:.3f}' if mg_t is not None else '—'} | {ratio} |"
        lines.append(row)
    return lines


# ---------------------------------------------------------------------------
# Reporting — runtime
# ---------------------------------------------------------------------------

def _runtime_section(
    rt_results: list[RuntimeResult], root: Path, arch: str, runs: int, warmup: int,
) -> list[str]:
    by_key        = {(r.file, r.pipeline): r for r in rt_results}
    files_ordered = list(dict.fromkeys(r.file for r in rt_results))

    def _f(v: float) -> str:
        return "—" if math.isnan(v) else f"{v:.4f}"

    nm_run_ok = sum(1 for f in files_ordered
                    if by_key.get((f, "no-merge")) and by_key[(f, "no-merge")].times)
    mg_run_ok = sum(1 for f in files_ordered
                    if by_key.get((f, "merge"))    and by_key[(f, "merge")].times)

    lines = [
        f"### arch: `{arch}`  ({runs} timed runs + {warmup} warmup)", "",
        f"- no-merge ran OK: `{nm_run_ok}/{len(files_ordered)}`",
        f"- merge ran OK:    `{mg_run_ok}/{len(files_ordered)}`",
        "",
        "| Benchmark | Source set | no-merge mean | no-merge σ | merge mean | merge σ | merge/no-merge |",
        "|---|---:|---:|---:|---:|---:|---:|",
    ]

    nm_means, mg_means = [], []
    for file in files_ordered:
        nm = by_key.get((file, "no-merge"))
        mg = by_key.get((file, "merge"))
        ref = nm or mg
        assert ref is not None
        nm_m, nm_s = _mean_stddev(nm.times if nm else [])
        mg_m, mg_s = _mean_stddev(mg.times if mg else [])
        if not math.isnan(nm_m): nm_means.append(nm_m)
        if not math.isnan(mg_m): mg_means.append(mg_m)
        ratio = f"{mg_m / nm_m:.3f}" if (not math.isnan(nm_m) and not math.isnan(mg_m) and nm_m > 0) else "—"
        lines.append(
            f"| {ref.benchmark} | {ref.source_set}"
            f" | {_f(nm_m)} | {_f(nm_s)} | {_f(mg_m)} | {_f(mg_s)} | {ratio} |"
        )

    if nm_means and mg_means:
        avg_nm = sum(nm_means) / len(nm_means)
        avg_mg = sum(mg_means) / len(mg_means)
        d = f"+{avg_mg - avg_nm:.4f}" if avg_mg >= avg_nm else f"{avg_mg - avg_nm:.4f}"
        lines.append(
            f"| **avg** | — | **{avg_nm:.4f}** | — | **{avg_mg:.4f}** | — | **{d}** |"
        )

    return lines


# ---------------------------------------------------------------------------
# Full report
# ---------------------------------------------------------------------------

def markdown(
    results:     list[TimingResult],
    root:        Path,
    arch_tag:    str,
    log_dir:     Path,
    warmup:      int,
    rt_results:  list[RuntimeResult] | None = None,
    rt_runs:     int = 5,
    rt_warmup:   int = 1,
    clangir_rev: str = "unknown",
    scripts_rev: str = "unknown",
) -> str:
    arches = sorted(set(r.arch for r in results))
    multi  = len(arches) > 1
    nm_ok  = sum(1 for r in results if r.pipeline == "no-merge" and r.ok)
    mg_ok  = sum(1 for r in results if r.pipeline == "merge"    and r.ok)
    total  = sum(1 for r in results if r.pipeline == "no-merge")

    lines = [
        "PolyBench CIR compile-time: no-merge vs --clangir-offload-merge.", "",
        f"- ClangIR commit: `{clangir_rev}`",
        f"- Scripts commit: `{scripts_rev}`",
        f"- arch: `{arch_tag}`",
        f"- PolyBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        "- Base flags (both arms): `-fclangir -O3 -c -ftime-report -mllvm -time-passes -mmlir --mlir-pass-statistics`",
        "- Both arms: full host+device compile; only variable is `--clangir-offload-merge`",
        f"- Warmup runs per benchmark: {warmup}",
        f"- no-merge OK: `{nm_ok}/{total}`",
        f"- merge OK:    `{mg_ok}/{total}`",
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
        lines += ["## Compile failures (timing phase)", ""]
        for r in failures:
            tag = f"{r.pipeline}/{r.arch}" if multi else r.pipeline
            lines += [
                f"- [{tag}] `{r.file}`",
                f"  - error: `{r.first_error or 'see log'}`",
                f"  - log: `{r.log}`",
            ]

    if rt_results:
        rt_arches = sorted(set(r.arch for r in rt_results))
        lines += [
            "",
            "---",
            "",
            "## Runtime performance (no-merge vs merge)",
            "",
            "Polybench wall-clock timer (`POLYBENCH_TIME=1`). "
            "Both binaries compiled with `-fclangir -O3`; only variable is `--clangir-offload-merge`.",
            "",
        ]
        for arch in rt_arches:
            lines.extend(
                _runtime_section(
                    [r for r in rt_results if r.arch == arch],
                    root, arch, rt_runs, rt_warmup,
                )
            )
            lines.append("")

        rt_failures = [r for r in rt_results if not r.compile_ok or not r.times]
        if rt_failures:
            lines += ["## Runtime failures", ""]
            for r in rt_failures:
                reason = "compile failed" if not r.compile_ok else "no timing output"
                lines += [
                    f"- [{r.pipeline}/{r.arch}] `{r.file}` — {reason}",
                    f"  - log: `{r.compile_log}`",
                ]
                if r.first_error:
                    lines[-1:] = lines[-1:] + [f"  - error: `{r.first_error}`"]

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    _rocm = _find_rocm_root()

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    src = parser.add_mutually_exclusive_group()
    src.add_argument("--hip",  action="store_true", help="Test HIP benchmarks only")
    src.add_argument("--cuda", action="store_true", help="Test CUDA benchmarks only")

    parser.add_argument("--clang",                type=path_arg, default=Path("~/llvm-project/build/bin/clang++"))
    parser.add_argument("--polybench-root",       type=path_arg, default=Path("~/polybenchGpu"))
    parser.add_argument("--cuda-root",            type=path_arg, default=Path("/usr/local/cuda"))
    parser.add_argument("--hip-path",             type=path_arg, default=_rocm)
    parser.add_argument("--rocm-device-lib-path", type=path_arg, default=_find_rocm_device_lib(_rocm))
    parser.add_argument("--gcc-install-dir",      type=path_arg, default=_find_gcc_install())
    parser.add_argument("--arch",       default="sm_86",  help="CUDA GPU arch (default: sm_86)")
    parser.add_argument("--hip-arch",   default="gfx942", help="HIP/AMDGPU arch (default: gfx942)")
    parser.add_argument("--multi-arch", action="store_true",
                        help=f"Compile for all arches per target "
                             f"(HIP: {_HIP_MULTI_ARCHES}, CUDA: {_CUDA_MULTI_ARCHES}); "
                             f"runtime (if enabled) uses the primary --arch/--hip-arch")
    parser.add_argument("--warmup",  type=int, default=2,
                        help="Compile warm-up runs before timed compile (default: 2)")
    parser.add_argument("--log-dir", type=path_arg, default=Path("~/polybench-gpu-audit/temp/offload-merge"))
    parser.add_argument("--limit",   type=int, default=0, help="Cap number of source files (0 = no cap)")
    parser.add_argument("-j", "--jobs", type=int, default=4)

    # Runtime flags
    parser.add_argument("--runtime", action="store_true",
                        help="Also compile to executables and measure runtime performance")
    parser.add_argument("--runs",           type=int, default=5,
                        help="Timed execution runs per binary (default: 5)")
    parser.add_argument("--runtime-warmup", type=int, default=1,
                        help="Warmup execution runs before timing (default: 1)")
    parser.add_argument("--build-dir", type=path_arg,
                        default=Path("~/polybench-gpu-audit/temp/merge-runtime"),
                        help="Directory for runtime executables")

    args = parser.parse_args()
    args.polybench_root = args.polybench_root.expanduser().resolve()
    args.cuda_root      = args.cuda_root.expanduser().resolve()
    args.log_dir        = args.log_dir.expanduser().resolve()
    args.build_dir      = args.build_dir.expanduser().resolve()

    errors = []
    if not args.clang.exists():          errors.append(f"--clang not found: {args.clang}")
    if not args.polybench_root.exists(): errors.append(f"--polybench-root not found: {args.polybench_root}")
    if args.jobs < 1:                    errors.append("--jobs must be >= 1")
    if args.warmup < 0:                  errors.append("--warmup must be >= 0")
    if args.runtime and args.runs < 1:   errors.append("--runs must be >= 1")
    if errors:
        for e in errors: print(f"error: {e}", file=sys.stderr)
        return 2

    args.log_dir.mkdir(parents=True, exist_ok=True)
    for old in args.log_dir.glob("*.log"):
        old.unlink()

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

    hip_arches   = _HIP_MULTI_ARCHES  if args.multi_arch else [args.hip_arch]
    cuda_arches  = _CUDA_MULTI_ARCHES if args.multi_arch else [args.arch]
    include_dirs = discover_include_dirs(files)

    # -------------------------------------------------------------------------
    # Phase 1: compile-time measurement
    # -------------------------------------------------------------------------
    ct_jobs = [
        (file, pipeline, arch)
        for file in files
        for pipeline in PIPELINES
        for arch in (hip_arches if is_hip(file) else cuda_arches)
    ]
    total_jobs = len(ct_jobs)
    width      = len(str(total_jobs))

    print(f"[compile-time] {total_jobs} jobs, -j{args.jobs}, warmup={args.warmup}")
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
            for file, pipeline, arch in ct_jobs
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

    ct_results = [
        results_by_key[(file, pipeline, arch)]
        for file, pipeline, arch in ct_jobs
        if (file, pipeline, arch) in results_by_key
    ]

    # -------------------------------------------------------------------------
    # Phase 2 (optional): runtime measurement
    # -------------------------------------------------------------------------
    rt_results: list[RuntimeResult] | None = None

    if args.runtime:
        common_dir = args.polybench_root / "common"
        if not common_dir.is_dir():
            print(f"error: common dir not found: {common_dir}", file=sys.stderr)
            return 2

        args.build_dir.mkdir(parents=True, exist_ok=True)

        try:
            pb_objs = _compile_polybench_objs(
                args.clang, common_dir, args.gcc_install_dir, args.build_dir,
            )
        except RuntimeError as e:
            print(f"error: {e}", file=sys.stderr)
            return 2

        # Runtime uses a single arch per file (the primary arch), even with --multi-arch.
        rt_jobs = [
            (file, pipeline, args.hip_arch if is_hip(file) else args.arch)
            for file in files
            for pipeline in PIPELINES
        ]
        rt_total = len(rt_jobs)
        rt_width = len(str(rt_total))

        print(f"\n[runtime compile] {rt_total} binaries, -j{args.jobs}")
        rt_by_key: dict[tuple[Path, str, str], RuntimeResult] = {}
        with ThreadPoolExecutor(max_workers=args.jobs) as executor:
            futures = {
                executor.submit(
                    runtime_compile_one,
                    args.clang, args.polybench_root,
                    args.cuda_root, args.hip_path, args.rocm_device_lib_path,
                    args.gcc_install_dir, arch, pipeline, file,
                    common_dir, pb_objs, args.build_dir, args.log_dir,
                ): (file, pipeline, arch)
                for file, pipeline, arch in rt_jobs
            }
            done = 0
            for future in as_completed(futures):
                file, pipeline, arch = futures[future]
                done += 1
                try:
                    r = future.result()
                except Exception as exc:
                    print(f"[{done:0{rt_width}d}/{rt_total}] {pipeline}/{arch} ERROR"
                          f" {file.name}: {exc}", file=sys.stderr)
                    raise
                rt_by_key[(file, pipeline, arch)] = r
                print(f"[{done:0{rt_width}d}/{rt_total}] {pipeline}/{arch}"
                      f" {'ok' if r.compile_ok else 'FAIL'}"
                      f" {file.relative_to(args.polybench_root)}")

        runnable = [rt_by_key[k] for k in rt_jobs if k in rt_by_key and rt_by_key[k].compile_ok]
        rw = len(str(len(runnable)))
        print(f"\n[runtime run] {len(runnable)} binaries,"
              f" {args.runtime_warmup} warmup + {args.runs} timed, -j{args.jobs}")
        done = 0
        with ThreadPoolExecutor(max_workers=args.jobs) as executor:
            futures2 = {
                executor.submit(run_binary, r, args.runs, args.runtime_warmup): r
                for r in runnable
            }
            for future in as_completed(futures2):
                future.result()
                r = futures2[future]
                done += 1
                m, s = _mean_stddev(r.times)
                status = f"mean={m:.4f}s σ={s:.4f}s" if r.times else "no timing output"
                print(f"[{done:0{rw}d}/{len(runnable)}] {r.pipeline}/{r.arch}"
                      f" {r.benchmark}  {status}")

        rt_results = [rt_by_key[k] for k in rt_jobs if k in rt_by_key]

    # -------------------------------------------------------------------------
    # Report
    # -------------------------------------------------------------------------
    if args.multi_arch:
        active_hip  = ",".join(_HIP_MULTI_ARCHES)
        active_cuda = ",".join(_CUDA_MULTI_ARCHES)
    else:
        active_hip, active_cuda = args.hip_arch, args.arch
    arch_tag = (
        f"hip:{active_hip}"   if args.hip  else
        f"cuda:{active_cuda}" if args.cuda else
        f"cuda:{active_cuda} hip:{active_hip}"
    )

    clangir_rev = _git_rev(args.clang.parent.parent.parent)
    scripts_rev = _git_rev(Path(__file__).parent)
    report = markdown(
        ct_results, args.polybench_root, arch_tag, args.log_dir, args.warmup,
        rt_results=rt_results, rt_runs=args.runs, rt_warmup=args.runtime_warmup,
        clangir_rev=clangir_rev, scripts_rev=scripts_rev,
    )
    report_path = args.log_dir / "offload_merge_summary.md"
    report_path.write_text(report + "\n", encoding="utf-8")
    print()
    print(report)
    print(f"\nReport written to {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
