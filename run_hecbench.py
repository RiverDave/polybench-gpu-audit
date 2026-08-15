#!/usr/bin/env python3
"""HeCBench CIR-vs-OG audit backend (suite: hecbench).

Data-driven counterpart of run_polybench.py: every benchmark's run args,
timing-extraction regex, unit, and vendor libs come from hecbench_suite.json
(generated from ORNL/HeCBench's benchmarks.yaml at a pinned commit), never
from reading the upstream checkout at run time.

Key differences vs the polybench backend:

  - Problem sizes are argv-driven (manifest args), not compile-time macros.
  - The binary itself loops `repeat` times internally and prints its own
    averaged kernel time; our warmup/timed runs sit on top.
  - Timing extraction is per-benchmark (manifest regex + unit), normalized to
    seconds. Benches whose regex captures a rate (GB/s) or no unit at all are
    measured but EXCLUDED from the geomean (noted in the report).
  - Validation is in-binary (PASS/FAIL printed by the benchmark's own
    host-reference compare): no second build, parse the same stdout.
  - CIR compile failures are expected data (features not yet implemented):
    they land in the Failures section with first-error, never abort the run.

Examples:
  ./run_hecbench.py --cuda --compile --limit 2 --dry-run          # coverage probe
  ./run_hecbench.py --cuda --compile --publish                    # compile axis, all
  ./run_hecbench.py --cuda --runtime --benchmarks accuracy,gmm    # runtime, subset
  ./run_hecbench.py --hip --runtime --accurate-mode --publish     # paper-grade
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path

from polybench_common import (
    CUDA_MULTI_ARCHES,
    HIP_MULTI_ARCHES,
    detect_cuda_arch,
    detect_hip_arch,
    find_clang,
    find_cuda_root,
    find_gcc_install,
    find_rocm_device_lib,
    find_rocm_root,
    git_rev,
    load_machine_config,
    mean_stddev,
    median,
    path_arg,
    provenance,
    provenance_lines,
)
from run_compile import parse_phases   # -ftime-report section parsing (generic)
from run_polybench import publish      # results-repo push (generic)

MANIFEST_PATH = Path(__file__).parent / "hecbench_suite.json"
HECBENCH_DEFAULT_ROOT = Path("~/hecbench")

UNIT_SCALE = {"us": 1e-6, "ms": 1e-3, "s": 1.0, "ns": 1e-9}

# Paper-grade profile: serialized, enough samples to separate signal from noise.
ACCURATE = {"jobs": 1, "warmup": 3, "samples": 8}
# Smoke profile: exercise every axis end-to-end in minutes, not hours.
TEST = {"warmup": 1, "samples": 2}
TEST_LIMIT = 2


@dataclass
class BenchResult:
    """One (benchmark, pipeline) runtime measurement."""
    name: str
    model: str
    pipeline: str
    arch: str
    args: list[str]
    regex: str
    regex_groups: int
    unit: str | None
    not_duration: bool
    timeout: int
    compile_ok: bool
    compile_log: Path
    binary: Path | None = None
    size: int | None = None
    times: list[float] = field(default_factory=list)       # seconds-normalized
    raw_times: list[float] = field(default_factory=list)   # as printed
    wall_times: list[float] = field(default_factory=list)
    validation_status: str | None = None
    first_error: str = ""


@dataclass
class CompileResult:
    """One (benchmark, pipeline, arch) compile-phase timing."""
    name: str
    model: str
    pipeline: str
    arch: str
    ok: bool
    elapsed: float
    elapsed_stddev: float
    elapsed_median: float
    elapsed_samples: list[float]
    samples: int
    phases: dict[str, float]
    log: Path
    command: list[str]
    first_error: str = ""


# ---------------------------------------------------------------------------
# Manifest + selection
# ---------------------------------------------------------------------------

def load_manifest(path: Path = MANIFEST_PATH) -> dict:
    if not path.exists():
        raise SystemExit(f"error: manifest not found: {path}\n"
                         f"       regenerate with gen_hecbench_manifest.py")
    return json.loads(path.read_text())


def select_benchmarks(manifest: dict, model: str, names: str | None,
                      bench_file: str | None, skip: str | None,
                      limit: int) -> list[tuple[str, dict]]:
    """Resolve the benchmark set. Order: --benchmarks > manifest-all (with a
    source dir for this model), then --skip, then --limit."""
    benches = manifest["benchmarks"]
    known = set(benches)

    selected: list[tuple[str, dict]] = []
    if names:
        wanted = [n.strip() for n in names.split(",") if n.strip()]
        unknown = [n for n in wanted if n not in known]
        if unknown:
            raise SystemExit(f"error: unknown benchmark(s): {', '.join(unknown)}\n"
                             f"       known: {', '.join(sorted(known))}")
        selected = [(n, benches[n]) for n in wanted]
    else:
        selected = [(n, e) for n, e in sorted(benches.items())
                    if e.get(f"has_{model}_dir")]

    skip_set: set[str] = set()
    if bench_file:
        overrides = json.loads(Path(bench_file).expanduser().read_text())
        f_names = overrides.get("benchmarks")
        if f_names:
            unknown = [n for n in f_names if n not in known]
            if unknown:
                raise SystemExit(f"error: unknown benchmark(s) in {bench_file}: "
                                 f"{', '.join(unknown)}")
            selected = [(n, benches[n]) for n in f_names]
        for n, args in (overrides.get("args") or {}).items():
            if n not in known:
                raise SystemExit(f"error: unknown benchmark in {bench_file} args: {n}")
            if n in benches:
                benches[n]["args"] = list(args)
        skip_set.update(overrides.get("skip") or [])
    if skip:
        skip_set.update(s.strip() for s in skip.split(",") if s.strip())

    selected = [(n, e) for n, e in selected
                if e.get(f"has_{model}_dir") and n not in skip_set]
    if not selected:
        raise SystemExit(f"error: no benchmarks selected (model={model})")
    if limit:
        selected = selected[:limit]
    return selected


# ---------------------------------------------------------------------------
# Compile command construction (shared by both axes)
# ---------------------------------------------------------------------------

def build_cmd(clang: Path, model: str, entry: dict, cuda_root: Path,
              hip_path: Path, rocm_device_lib_path: Path,
              gcc_install_dir: Path, pipeline: str, arch: str,
              source: Path, out: Path, extra: list[str],
              link: bool) -> list[str]:
    cmd = [str(clang)]
    if pipeline in ("CIR", "CIR-merge"):
        cmd.append("-fclangir")
        if pipeline == "CIR-merge":
            cmd.append("--clangir-offload-merge")
    cmd.append(f"--gcc-install-dir={gcc_install_dir}")
    if model == "hip":
        cmd += ["-x", "hip",
                f"--hip-path={hip_path}",
                f"--offload-arch={arch}",
                f"--rocm-device-lib-path={rocm_device_lib_path}",
                "-D__AMDGCN_WAVEFRONT_SIZE=64"]
    else:
        cmd += [f"--cuda-path={cuda_root}", f"--cuda-gpu-arch={arch}"]
    cmd += ["-std=c++17", "-O3", *extra,
            *(entry.get(f"{model}_defines") or []),   # Makefile -D flags (e.g. adv: dfloat=double)
            str(source), f"-I{source.parent}"]
    # Makefile -I flags, stored bench-relative (or absolute); e.g. boxfilter
    # pulls shrUtils.h from its sycl sibling dir.
    for inc in entry.get(f"{model}_includes") or []:
        cmd.append(inc if inc.startswith("/") else f"-I{source.parent}/{inc}")
    if link:
        if model == "hip":
            cmd += [f"-L{hip_path}/lib", "-lamdhip64"]
        else:
            cmd += [f"-L{cuda_root}/lib64", "-lcudart"]
        for lib in entry.get(f"{model}_libs") or []:
            cmd.append(f"-l{lib}")
        cmd.append("-lm")
    cmd += ["-o", str(out)]
    return cmd


def _env_for(clang: Path, pipeline: str) -> dict:
    env = os.environ.copy()
    if pipeline.startswith("CIR"):
        env["PATH"] = f"{clang.parent}:{env['PATH']}"
    return env


def _first_error(stdout: str, stderr: str) -> str:
    for line in (stdout + stderr).splitlines():
        if " error:" in line.lower() or "fatal" in line.lower():
            return line.strip()
    return ""


def _source_path(root: Path, name: str, model: str, entry: dict) -> Path:
    main_name = entry.get(f"{model}_main")
    if not main_name:
        raise SystemExit(f"error: {name}: no {model} source in manifest")
    return root / "src" / f"{name}-{model}" / main_name


# ---------------------------------------------------------------------------
# Timing + validation parsing (runtime axis)
# ---------------------------------------------------------------------------

def parse_time(stdout: str, regex: str, groups: int) -> float | None:
    """Extract the benchmark's own kernel time from stdout (first match).

    Upstream regexes use the class ``[0-9.+-e]`` whose ``-e`` range spans
    0x2D..0x65 — it matches letters, so "NaN" (or "1e999") can land in the
    capture. Non-finite values must never enter a ratio/geomean.
    """
    m = re.search(regex, stdout)
    if not m:
        return None
    num = m.group(1) if groups >= 1 else m.group(0)
    try:
        v = float(num)
    except ValueError:
        return None
    return v if math.isfinite(v) else None


def parse_validation(stdout: str) -> str:
    """In-binary host-reference compare: PASS / FAIL / missing_output."""
    if re.search(r"\bFAIL\b", stdout):
        return "failed"
    if re.search(r"\bPASS\b", stdout):
        return "passed"
    return "missing_output"


# ---------------------------------------------------------------------------
# Runtime axis
# ---------------------------------------------------------------------------

def runtime_compile_one(clang: Path, root: Path, name: str, entry: dict,
                        model: str, cuda_root: Path, hip_path: Path,
                        rocm_device_lib_path: Path, gcc_install_dir: Path,
                        pipeline: str, arch: str, build_dir: Path,
                        log_dir: Path, clang_flags: str) -> BenchResult:
    source = _source_path(root, name, model, entry)
    tag = f"{name}.{model}.{pipeline.lower()}.{arch}"
    binary = build_dir / tag
    log = log_dir / f"{tag}.log"

    cmd = build_cmd(clang, model, entry, cuda_root, hip_path,
                    rocm_device_lib_path, gcc_install_dir, pipeline, arch,
                    source, binary, shlex.split(clang_flags) if clang_flags else [],
                    link=True)

    proc = subprocess.run(cmd, text=True, capture_output=True, env=_env_for(clang, pipeline))
    log.write_text("COMMAND: " + shlex.join(cmd) + "\n\nSTDOUT:\n" + proc.stdout
                   + "\nSTDERR:\n" + proc.stderr, encoding="utf-8")
    ok = proc.returncode == 0
    return BenchResult(
        name=name, model=model, pipeline=pipeline, arch=arch,
        args=list(entry.get("args") or []), regex=entry["regex"],
        regex_groups=entry.get("regex_groups", 1), unit=entry.get("unit"),
        not_duration=bool(entry.get("not_duration")),
        timeout=int(entry.get("timeout", 300)),
        compile_ok=ok, compile_log=log,
        binary=binary if ok else None,
        size=binary.stat().st_size if ok else None,
        first_error=_first_error(proc.stdout, proc.stderr),
    )


def run_binary(result: BenchResult, runs: int, warmup: int) -> None:
    """Run the binary in-place, filling times/wall_times/validation. Mutates result."""
    assert result.binary is not None
    try:
        for _ in range(warmup):
            subprocess.run([str(result.binary), *result.args],
                           capture_output=True, timeout=result.timeout)
        for _ in range(runs):
            start = time.perf_counter()
            proc = subprocess.run([str(result.binary), *result.args],
                                  capture_output=True, text=True,
                                  timeout=result.timeout)
            result.wall_times.append(time.perf_counter() - start)
            if proc.returncode != 0:
                result.validation_status = "exec_failed"
                break
            t = parse_time(proc.stdout, result.regex, result.regex_groups)
            if t is not None:
                result.raw_times.append(t)
                if result.unit:
                    result.times.append(t * UNIT_SCALE[result.unit])
            result.validation_status = parse_validation(proc.stdout)
    except subprocess.TimeoutExpired:
        pass  # timed out mid-run; result.times holds whatever completed


def runtime_markdown(results: list[BenchResult], root: Path, arch: str,
                     log_dir: Path, runs: int, warmup: int,
                     clangir_rev: str, scripts_rev: str, prov: dict,
                     pipelines: tuple[str, str], validate: bool) -> str:
    p0, p1 = pipelines
    by_key = {(r.name, r.pipeline): r for r in results}
    names = list(dict.fromkeys(r.name for r in results))
    compile_ok = sum(1 for r in results if r.compile_ok)
    run_ok = sum(1 for r in results if r.times)

    def fmt_ms(v: float) -> str:
        return "—" if math.isnan(v) else f"{v * 1000:.3f}"

    lines = [
        f"HeCBench runtime performance: {p0} vs {p1} (all times ms).", "",
        f"- ClangIR commit: `{clangir_rev}`",
        f"- Scripts commit: `{scripts_rev}`",
        f"- arch: `{arch}`",
        f"- HeCBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        f"- Runs: {runs} timed + {warmup} warmup (each binary loops internally)",
        f"- Compiled OK: `{compile_ok}/{len(results)}`",
        f"- Ran OK: `{run_ok}/{len(results)}`",
        *(["- **Validation: in-binary PASS/FAIL check**", ""] if validate else []),
        "",
        "## Environment",
        "",
        *provenance_lines(prov),
        "",
        "## Results (ms)",
        "",
        f"| Benchmark | args | {p0} wall | {p0} GPU | {p0} host | {p1} wall | {p1} GPU | {p1} host | GPU {p1}/{p0} | unit | {p0} size | {p1} size |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for name in names:
        r0 = by_key.get((name, p0))
        r1 = by_key.get((name, p1))
        ref = r0 or r1
        m0, _ = mean_stddev(r0.times if r0 else [])
        m1, _ = mean_stddev(r1.times if r1 else [])
        w0, _ = mean_stddev(r0.wall_times if r0 else [])
        w1, _ = mean_stddev(r1.wall_times if r1 else [])
        ratio = f"{m1 / m0:.3f}" if (m0 > 0 and m1 > 0) else "—"
        unit = ref.unit or ("rate" if ref.not_duration else "?")
        lines.append(
            f"| {name} | {' '.join(ref.args)} |"
            f" {fmt_ms(w0)} | {fmt_ms(m0)} | {fmt_ms(w0 - m0)} |"
            f" {fmt_ms(w1)} | {fmt_ms(m1)} | {fmt_ms(w1 - m1)} | {ratio} | {unit} |"
            f" {f'{r0.size / 1024:.1f} KiB' if r0 and r0.size else '—'} |"
            f" {f'{r1.size / 1024:.1f} KiB' if r1 and r1.size else '—'} |"
        )

    ratios, excluded = [], []
    for name in names:
        r0 = by_key.get((name, p0)); r1 = by_key.get((name, p1))
        m0, _ = mean_stddev(r0.times if r0 else [])
        m1, _ = mean_stddev(r1.times if r1 else [])
        ref = r0 or r1
        if m0 > 0 and m1 > 0:
            if ref.unit:
                ratios.append(m1 / m0)
            else:
                excluded.append(name)
    if ratios:
        from statistics import geometric_mean
        lines += ["", f"**Total GPU {p1}/{p0} (geomean):** `{geometric_mean(ratios):.4f}`", ""]
    if excluded:
        lines += ["", f"*Excluded from geomean (no duration unit or rate capture): "
                      f"{', '.join(excluded)}*", ""]

    failures = [r for r in results if not r.compile_ok or not r.times]
    if failures:
        lines += ["", "## Failures", ""]
        for r in failures:
            reason = "compile failed" if not r.compile_ok else "no timing output"
            lines += [f"- [{r.pipeline}] `{r.name}` — {reason}"]
            if r.first_error:
                lines += [f"  - error: `{r.first_error}`"]
            lines += [f"  - log: `{r.compile_log}`"]

    if validate:
        val_fail = [r for r in results
                    if r.validation_status in ("failed", "exec_failed", "missing_output")]
        val_ok = sum(1 for r in results if r.validation_status == "passed")
        val_n = sum(1 for r in results if r.validation_status)
        lines += ["", f"- Validation: `{val_ok}/{val_n}` passed"]
        for r in val_fail:
            lines += [f"  - [{r.pipeline}] `{r.name}` — {r.validation_status}"]
    return "\n".join(lines)


def runtime_json(results: list[BenchResult], args, clangir_rev: str,
                 scripts_rev: str, prov: dict, pipelines: tuple[str, str]) -> dict:
    return {
        "kind": "runtime", "suite": "hecbench",
        "arch": args.arch, "runs": args.samples, "warmup": args.warmup,
        "jobs": args.jobs, "merge": args.offload_merge,
        "pipelines": list(pipelines),
        "clangir_commit": clangir_rev, "scripts_commit": scripts_rev,
        "hecbench_root": str(args.hecbench_root),
        "environment": prov,
        "validate": args.validate,
        "results": [{
            "benchmark": r.name, "model": r.model, "pipeline": r.pipeline,
            "arch": r.arch, "args": r.args, "regex": r.regex,
            "unit": r.unit, "compile_ok": r.compile_ok,
            "binary_bytes": r.size, "times": r.times, "raw_times": r.raw_times,
            "wall_times": r.wall_times,
            "validation_status": r.validation_status, "first_error": r.first_error,
        } for r in results],
    }


# ---------------------------------------------------------------------------
# Compile axis
# ---------------------------------------------------------------------------

def compile_one(clang: Path, root: Path, name: str, entry: dict, model: str,
                cuda_root: Path, hip_path: Path, rocm_device_lib_path: Path,
                gcc_install_dir: Path, pipeline: str, arch: str,
                obj_path: Path, log_path: Path, warmup: int, samples: int,
                clang_flags: str) -> CompileResult:
    source = _source_path(root, name, model, entry)
    extra = ["-ftime-report", "-mllvm", "-time-passes", "-c"]
    if clang_flags:
        extra += shlex.split(clang_flags)
    cmd = build_cmd(clang, model, entry, cuda_root, hip_path,
                    rocm_device_lib_path, gcc_install_dir, pipeline, arch,
                    source, obj_path, extra, link=False)
    env = _env_for(clang, pipeline)

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
    elapsed, stddev = mean_stddev(elapsed_samples) if ok else (elapsed_samples[-1], 0.0)
    phases = {k: sum(s[k] for s in phase_samples) / len(phase_samples)
              for k in {k for s in phase_samples for k in s}} if phase_samples else {}
    log_path.write_text(
        "COMMAND: " + shlex.join(cmd)
        + f"\n\nSAMPLES (wall seconds): {[f'{t:.4f}' for t in elapsed_samples]}"
        + "\n\nSTDOUT (last sample):\n" + (proc.stdout or "")
        + "\nSTDERR (last sample):\n" + (proc.stderr or ""),
        encoding="utf-8",
    )
    return CompileResult(
        name=name, model=model, pipeline=pipeline, arch=arch, ok=ok,
        elapsed=elapsed, elapsed_stddev=stddev,
        elapsed_median=median(elapsed_samples) if ok else float("nan"),
        elapsed_samples=elapsed_samples, samples=len(elapsed_samples),
        phases=phases, log=log_path, command=cmd,
        first_error=_first_error(proc.stdout, proc.stderr),
    )


def compile_markdown(results: list[CompileResult], root: Path, arch_tag: str,
                     log_dir: Path, warmup: int, samples: int,
                     clangir_rev: str, scripts_rev: str, prov: dict,
                     pipelines: tuple[str, str]) -> str:
    p0, p1 = pipelines
    arches = sorted(set(r.arch for r in results))
    multi = len(arches) > 1
    ok0 = sum(1 for r in results if r.pipeline == p0 and r.ok)
    ok1 = sum(1 for r in results if r.pipeline == p1 and r.ok)
    t0 = sum(1 for r in results if r.pipeline == p0)
    t1 = sum(1 for r in results if r.pipeline == p1)

    lines = [
        f"HeCBench compile-phase timing: {p0} vs {p1}.", "",
        f"- ClangIR commit: `{clangir_rev}`",
        f"- Scripts commit: `{scripts_rev}`",
        f"- arch: `{arch_tag}`",
        f"- HeCBench root: `{root}`",
        f"- Logs: `{log_dir}`",
        "- Flags: `-O3 host+device -ftime-report -mllvm -time-passes`"
        + ("; merge arm adds `--clangir-offload-merge`" if p1 == "CIR-merge" else ""),
        f"- Warmup runs per benchmark: {warmup}",
        f"- Timed samples per benchmark: {samples}",
        f"- {p0} compiled OK: `{ok0}/{t0}`",
        f"- {p1} compiled OK: `{ok1}/{t1}`",
        "",
        "## Environment",
        "",
        *provenance_lines(prov),
        "",
        "## Per-benchmark wall time (seconds)",
        "",
    ]
    for arch in arches:
        sub = [r for r in results if r.arch == arch]
        lines.append(f"### arch: `{arch}`")
        lines.append("")
        lines.append(f"| Benchmark | {p0} | {p0} σ | {p1} | {p1} σ | {p1}/{p0} |")
        lines.append("|---|---:|---:|---:|---:|---:|")
        for r in sorted(sub, key=lambda x: x.name):
            if r.pipeline != p0:
                continue
            r1 = next((x for x in sub if x.name == r.name and x.pipeline == p1), None)
            ratio = f"{r1.elapsed / r.elapsed:.3f}" if (r1 and r.ok and r1.ok and r.elapsed > 0) else "—"
            e1 = f"{r1.elapsed:.3f}" if r1 and r1.ok else "—"
            s1 = f"{r1.elapsed_stddev:.3f}" if r1 and r1.ok else "—"
            lines.append(
                f"| {r.name} | {r.elapsed:.3f} | {r.elapsed_stddev:.3f} |"
                f" {e1} | {s1} | {ratio} |"
            )
        lines.append("")

    ratios = []
    for r in results:
        if r.pipeline == p1 and r.ok:
            r0 = next((x for x in results
                       if x.name == r.name and x.pipeline == p0 and x.ok), None)
            if r0 and r0.elapsed > 0:
                ratios.append(r.elapsed / r0.elapsed)
    if ratios:
        from statistics import geometric_mean
        lines += [f"**Total compile {p1}/{p0} (geomean):** `{geometric_mean(ratios):.4f}`", ""]

    failures = [r for r in results if not r.ok]
    if failures:
        lines += ["## Failures (compile)", ""]
        for r in failures:
            tag = f"{r.pipeline}/{r.arch}" if multi else r.pipeline
            lines += [f"- [{tag}] `{r.name}` — `{r.first_error or 'see log'}`",
                      f"  - log: `{r.log}`"]
    return "\n".join(lines)


def compile_json(results: list[CompileResult], args, clangir_rev: str,
                 scripts_rev: str, prov: dict, pipelines: tuple[str, str]) -> dict:
    return {
        "kind": "compile", "suite": "hecbench",
        "arch": args.arch, "warmup": args.warmup, "samples": args.samples,
        "jobs": args.jobs, "merge": args.offload_merge, "pipelines": list(pipelines),
        "clangir_commit": clangir_rev, "scripts_commit": scripts_rev,
        "hecbench_root": str(args.hecbench_root),
        "environment": prov,
        "results": [{
            "benchmark": r.name, "model": r.model, "pipeline": r.pipeline,
            "arch": r.arch, "ok": r.ok, "elapsed": r.elapsed,
            "elapsed_stddev": r.elapsed_stddev,
            "elapsed_median": r.elapsed_median,
            "elapsed_samples": r.elapsed_samples, "samples": r.samples,
            "phases": r.phases, "first_error": r.first_error,
        } for r in results],
    }


# ---------------------------------------------------------------------------
# Axis runners
# ---------------------------------------------------------------------------

def run_compile_axis(args, selected, model, pipelines, arches, log_dir) -> list[CompileResult]:
    jobs = [(name, entry, pipeline, a) for a in arches
            for name, entry in selected for pipeline in pipelines]
    print(f"Compiling {len(jobs)} object files with -j{args.jobs}...")
    if args.dry_run:
        for name, entry, pipeline, a in jobs[:3]:
            src = _source_path(args.hecbench_root, name, model, entry)
            print("$", " ".join(build_cmd(
                Path(args.clang), model, entry,
                Path(args.cuda_root or "/usr/local/cuda"),
                Path(args.hip_path or "/opt/rocm"),
                Path(args.rocm_device_lib_path or "/opt/rocm/amdgcn/bitcode"),
                Path(args.gcc_install_dir), pipeline, a, src,
                log_dir / f"{name}.{model}.{pipeline.lower()}.{a}.o",
                ["-ftime-report", "-mllvm", "-time-passes", "-c"], False)))
        print(f"(dry-run: {len(jobs)} compile jobs total)")
        return []
    results: list[CompileResult] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {
            ex.submit(compile_one, Path(args.clang), args.hecbench_root, name,
                      entry, model,
                      Path(args.cuda_root or "/usr/local/cuda"),
                      Path(args.hip_path or "/opt/rocm"),
                      Path(args.rocm_device_lib_path or "/opt/rocm/amdgcn/bitcode"),
                      Path(args.gcc_install_dir), pipeline, a,
                      log_dir / f"{name}.{model}.{pipeline.lower()}.{a}.o",
                      log_dir / f"{name}.{model}.{pipeline.lower()}.{a}.log",
                      args.warmup, args.samples, args.clang_flags): (name, pipeline, a)
            for name, entry, pipeline, a in jobs
        }
        done = 0
        for fut in as_completed(futures):
            done += 1
            r = fut.result()
            results.append(r)
            print(f"[{done}/{len(jobs)}] {r.pipeline}/{r.arch} {r.name} "
                  f"{'ok' if r.ok else 'FAIL'} {r.elapsed:.2f}s")
    return results


def run_runtime_axis(args, selected, model, pipelines, arch, log_dir) -> list[BenchResult]:
    build_dir = log_dir / "build"
    build_dir.mkdir(parents=True, exist_ok=True)
    jobs = [(name, entry, pipeline) for name, entry in selected for pipeline in pipelines]
    print(f"Building {len(jobs)} binaries with -j{args.jobs}...")
    if args.dry_run:
        for name, entry, pipeline in jobs[:3]:
            src = _source_path(args.hecbench_root, name, model, entry)
            print("$", " ".join(build_cmd(
                Path(args.clang), model, entry,
                Path(args.cuda_root or "/usr/local/cuda"),
                Path(args.hip_path or "/opt/rocm"),
                Path(args.rocm_device_lib_path or "/opt/rocm/amdgcn/bitcode"),
                Path(args.gcc_install_dir), pipeline, arch, src,
                build_dir / f"{name}.bin", [], True)))
        print(f"(dry-run: {len(jobs)} build jobs + run with manifest args)")
        return []
    results: list[BenchResult] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {
            ex.submit(runtime_compile_one, Path(args.clang), args.hecbench_root,
                      name, entry, model,
                      Path(args.cuda_root or "/usr/local/cuda"),
                      Path(args.hip_path or "/opt/rocm"),
                      Path(args.rocm_device_lib_path or "/opt/rocm/amdgcn/bitcode"),
                      Path(args.gcc_install_dir), pipeline, arch,
                      build_dir, log_dir, args.clang_flags): (name, pipeline)
            for name, entry, pipeline in jobs
        }
        done = 0
        for fut in as_completed(futures):
            done += 1
            r = fut.result()
            results.append(r)
            print(f"[{done}/{len(jobs)}] {r.pipeline} {'ok' if r.compile_ok else 'FAIL'} {r.name}")
    runnable = [r for r in results if r.compile_ok]
    print(f"\nRunning {len(runnable)} binaries ({args.warmup} warmup + "
          f"{args.samples} timed, -j{args.jobs})...")
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {ex.submit(run_binary, r, args.samples, args.warmup): r
                   for r in runnable}
        for fut in as_completed(futures):
            fut.result()
    return results


def write_artifacts(log_dir: Path, kind: str, report: str, results,
                    args, clangir_rev: str, scripts_rev: str, prov: dict,
                    pipelines: tuple[str, str]) -> None:
    (log_dir / f"{kind}_summary.md").write_text(report + "\n", encoding="utf-8")
    data = (runtime_json if kind == "runtime" else compile_json)(
        results, args, clangir_rev, scripts_rev, prov, pipelines)
    (log_dir / f"{kind}_results.json").write_text(
        json.dumps(data, indent=2) + "\n", encoding="utf-8")
    if kind == "runtime":
        artifacts = log_dir / "artifacts"
        artifacts.mkdir(exist_ok=True)
        for r in results:
            if r.compile_ok and r.binary and r.binary.exists():
                shutil.copy2(r.binary, artifacts / r.binary.name)
    print(f"\nReport written to {log_dir}/{kind}_summary.md")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def _profile_name(config: Path, cfg: dict) -> str:
    """Reverse-lookup the profile's key in machines.json, for labelling results."""
    if not cfg or not config.exists():
        return "unknown"
    try:
        data = json.loads(config.read_text())
    except OSError:
        return "unknown"
    for name, entry in data.items():
        if entry is cfg or entry == cfg:
            return name
    return "unknown"


def main(argv: list[str] | None = None) -> int:
    _rocm = find_rocm_root()

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    target = parser.add_mutually_exclusive_group()
    target.add_argument("--hip", action="store_true", help="Benchmark the HIP sources")
    target.add_argument("--cuda", action="store_true", help="Benchmark the CUDA sources")

    parser.add_argument("--compile", action="store_true", help="Compile-time axis")
    parser.add_argument("--runtime", action="store_true", help="Runtime axis")
    parser.add_argument("--multi-arch", action="store_true", help="Per-arch compile-time axis")
    parser.add_argument("--all", action="store_true", help="All three axes")
    parser.add_argument("--accurate-mode", action="store_true",
                        help=f"Paper-grade profile: {ACCURATE}, and refuse a guessed arch")
    parser.add_argument("--test", action="store_true",
                        help=f"Smoke test: {TEST_LIMIT} benchmarks, {TEST['samples']} samples")

    parser.add_argument("--machine", help="machines.json profile name (else matched by hostname)")
    parser.add_argument("--config", default=str(Path(__file__).parent / "machines.json"))
    parser.add_argument("--publish", action="store_true",
                        help="Push summaries + raw JSON to the results repo")
    parser.add_argument("--validate", action="store_true",
                        help="Record the in-binary PASS/FAIL correctness check (free: no rebuild)")
    parser.add_argument("--offload-merge", action="store_true",
                        help="Compare CIR no-merge vs CIR-merge instead of CIR vs OG")

    parser.add_argument("--arch", help="Override the detected GPU arch")
    parser.add_argument("--clang", help="Override the detected clang++")
    parser.add_argument("--hecbench-root", help="Override the HeCBench checkout")
    parser.add_argument("--cuda-root", help="Override the detected CUDA toolkit")
    parser.add_argument("--hip-path", help="Override the detected ROCm root")
    parser.add_argument("--rocm-device-lib-path", help="Override the detected amdgcn bitcode dir")
    parser.add_argument("--gcc-install-dir", help="Override the detected GCC install dir")
    parser.add_argument("--log-root", default="temp", help="Parent dir for run-tagged log dirs")
    parser.add_argument("--warmup", type=int, help="Warmup iterations")
    parser.add_argument("--samples", type=int, help="Timed repetitions per benchmark")
    parser.add_argument("--limit", type=int, default=0, help="Cap benchmarks (smoke tests)")
    parser.add_argument("--clang-flags", default="", help="Extra flags forwarded to every clang compile line")
    parser.add_argument("-j", "--jobs", type=int, help="Parallel jobs (accurate-mode forces 1)")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running")

    parser.add_argument("--benchmarks", help="Comma-separated benchmark names (default: all with metadata)")
    parser.add_argument("--benchmarks-file", help="JSON: {\"benchmarks\": [...], \"skip\": [...], \"args\": {name: [...]}}")
    parser.add_argument("--skip", help="Comma-separated benchmark names to exclude")
    parser.add_argument("--manifest", type=Path, default=MANIFEST_PATH,
                        help="Suite manifest (default: hecbench_suite.json)")
    parser.add_argument("--arches", help="Comma-separated arch list overriding --multi-arch defaults")

    args = parser.parse_args(argv)

    if args.all:
        args.compile = args.runtime = args.multi_arch = True
    if not (args.compile or args.runtime or args.multi_arch):
        parser.error("pick at least one axis: --compile / --runtime / --multi-arch / --all")

    cfg = load_machine_config(Path(args.config).expanduser(), args.machine)
    machine_name = args.machine or cfg.get("name") or _profile_name(Path(args.config), cfg)

    if not (args.hip or args.cuda):
        t = cfg.get("target")
        if t == "hip": args.hip = True
        elif t == "cuda": args.cuda = True
        else: parser.error("no --hip/--cuda given and no 'target' in the machine profile")
    model = "hip" if args.hip else "cuda"

    if args.test:
        for key, value in TEST.items():
            if getattr(args, key) is None:
                setattr(args, key, value)
        args.limit = args.limit or TEST_LIMIT
        args.log_root = str(Path(args.log_root) / "smoke")
    for key, value in ACCURATE.items():
        if args.accurate_mode and getattr(args, key) is None:
            setattr(args, key, value)
    if args.accurate_mode:
        args.validate = True
    if args.jobs is None: args.jobs = 4
    if args.warmup is None: args.warmup = 2
    if args.samples is None: args.samples = 5

    # machines.json profiles store clang/roots as ~-relative strings; expand
    # them here (polybench backends get this from their argparse path_arg type;
    # this backend resolves directly).
    args.clang = str(Path(args.clang or cfg.get("clang") or str(find_clang())).expanduser())
    args.hecbench_root = Path(
        args.hecbench_root or cfg.get("hecbench_root") or HECBENCH_DEFAULT_ROOT
    ).expanduser().resolve()
    args.gcc_install_dir = str(Path(
        args.gcc_install_dir or cfg.get("gcc_install_dir") or str(find_gcc_install())
    ).expanduser())

    if model == "hip":
        rocm = Path(args.hip_path or cfg.get("hip_path") or str(find_rocm_root())).expanduser()
        args.hip_path = rocm
        args.rocm_device_lib_path = str(Path(
            args.rocm_device_lib_path
            or cfg.get("rocm_device_lib_path")
            or find_rocm_device_lib(rocm)).expanduser())
    else:
        args.cuda_root = args.cuda_root or cfg.get("cuda_root") or str(find_cuda_root())

    arch = args.arch or cfg.get("arch")
    if arch:
        arch_source = "explicit" if args.arch else "machines.json"
    else:
        arch, detected = detect_hip_arch() if model == "hip" else detect_cuda_arch()
        arch_source = "detected" if detected else "FALLBACK"
    if arch_source == "FALLBACK" and args.accurate_mode:
        print(f"error: GPU arch could not be detected (would guess '{arch}').\n"
              f"       --accurate-mode refuses to benchmark a guessed target.\n"
              f"       Pass --arch <target>, or add one to {args.config}.")
        return 2

    manifest = load_manifest(args.manifest)
    selected = select_benchmarks(manifest, model, args.benchmarks,
                                 args.benchmarks_file, args.skip, args.limit)
    hecbench_rev = git_rev(args.hecbench_root)
    clangir_rev = git_rev(Path(args.clang).parent.parent.parent)
    scripts_rev = git_rev(Path(__file__).parent)

    prov = provenance()
    prov["suite"] = "hecbench"
    prov["hecbench_commit"] = hecbench_rev
    prov["manifest_commit"] = manifest.get("hecbench_commit", "unknown")
    prov["manifest_path"] = str(args.manifest)
    prov["benchmark_args"] = json.dumps({n: e["args"] for n, e in selected})
    try:
        out = subprocess.run([args.clang, "--version"], capture_output=True,
                             text=True, timeout=10)
        prov["compiler_version"] = out.stdout.strip().splitlines()[0] if out.stdout else ""
    except (OSError, subprocess.SubprocessError):
        pass

    print(f"machine: {machine_name}   host={prov['hostname']}")
    print(f"suite  : hecbench ({manifest.get('hecbench_commit', '?')[:12]})")
    print(f"target : {model.upper()}  arch={arch} ({arch_source})")
    print(f"clang  : {args.clang}")
    print(f"gpu    : {prov['gpu'] or '?'}   cpu={prov['cpu_count']} threads")
    print(f"benchmarks: {len(selected)} — "
          f"{' '.join(n for n, _ in selected[:8])}{' ...' if len(selected) > 8 else ''}")
    print(f"profile: -j{args.jobs}  warmup={args.warmup}  samples={args.samples}"
          f"{'  [accurate-mode]' if args.accurate_mode else ''}")
    if args.offload_merge:
        print("compare: CIR no-merge vs CIR-merge (--clangir-offload-merge)")
    if args.test:
        print(f"*** SMOKE TEST: {len(selected)} benchmarks — NOT publication data ***")

    pipelines = ("CIR", "CIR-merge") if args.offload_merge else ("CIR", "OG")
    log_dirs: list[str] = []

    if args.compile or args.multi_arch:
        arches = [arch]
        if args.multi_arch:
            arches = list(HIP_MULTI_ARCHES if model == "hip" else CUDA_MULTI_ARCHES)
            if args.arches:
                arches = [a.strip() for a in args.arches.split(",") if a.strip()]
        slug = (f"hecbench-compile-{model}-{'-'.join(arches) if args.multi_arch else arch}"
                f"-j{args.jobs}")
        if args.offload_merge:
            slug += "-merge"
        log_dir = Path(args.log_root) / slug
        log_dir.mkdir(parents=True, exist_ok=True)
        log_dirs.append(str(log_dir))
        results = run_compile_axis(args, selected, model, pipelines, arches, log_dir)
        if not args.dry_run:
            report = compile_markdown(results, args.hecbench_root, ",".join(arches),
                                      log_dir, args.warmup, args.samples,
                                      clangir_rev, scripts_rev, prov, pipelines)
            write_artifacts(log_dir, "compile", report, results, args,
                            clangir_rev, scripts_rev, prov, pipelines)

    if args.runtime:
        slug = f"hecbench-runtime-{model}-{arch}-j{args.jobs}"
        if args.offload_merge:
            slug += "-merge"
        log_dir = Path(args.log_root) / slug
        log_dir.mkdir(parents=True, exist_ok=True)
        log_dirs.append(str(log_dir))
        results = run_runtime_axis(args, selected, model, pipelines, arch, log_dir)
        if not args.dry_run:
            report = runtime_markdown(results, args.hecbench_root, arch, log_dir,
                                      args.samples, args.warmup,
                                      clangir_rev, scripts_rev, prov, pipelines,
                                      validate=args.validate)
            write_artifacts(log_dir, "runtime", report, results, args,
                            clangir_rev, scripts_rev, prov, pipelines)

    if args.publish and not args.dry_run:
        return publish(log_dirs, machine_name, prov, "-hecbench")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
