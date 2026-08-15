#!/usr/bin/env python3
"""Generate hecbench_suite.json from an ORNL/HeCBench checkout.

Consumes benchmarks.yaml (the upstream manifest: categories, models,
test.regex / test.args / test.timeout per benchmark) and pins everything the
harness needs to build + measure a benchmark without re-reading upstream:

  - run args (argv problem sizes) and timing-extraction regex
  - timing unit, inferred from the regex literal (us / ms / s / ...)
  - source dir existence per backend (src/<name>-cuda, src/<name>-hip)
  - vendor library deps (cublas, cufft, ...) found in the sources, which the
    harness must add to the link line

The output is pinned to a HeCBench commit so runs are reproducible without
touching upstream; regenerate only when deliberately bumping the pin.

Usage:
  python3 gen_hecbench_manifest.py [--root ~/dev/hecbench] [--output hecbench_suite.json]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# Longer tokens first: 'ms' contains 's', 'seconds' contains 's', etc.
_UNIT_TOKENS = [
    ("microsecond", "us"), ("microseconds", "us"), ("usec", "us"), (r"\bus\b", "us"),
    ("nanosecond", "ns"), ("nanoseconds", "ns"), (r"\bns\b", "ns"),
    ("millisecond", "ms"), ("milliseconds", "ms"), ("msec", "ms"), (r"\bms\b", "ms"),
    ("seconds", "s"), ("second", "s"), ("secs", "s"), ("sec", "s"), (r"\(s\)", "s"),
]
_BARE_S = re.compile(r"(?<![a-zA-Z\u00b5])s(?![a-zA-Z])")
# Throughput/rate regexes capture GB/s, FLOPS, bandwidth — NOT durations.
# A rate number must never enter a latency geomean.
_RATE_RE = re.compile(
    r"(?:bytes?/s|b/s|flops|bandwidth|throughput|per second|gbytes|mbytes)", re.IGNORECASE)
_SOURCE_UNIT = re.compile(r"(usec|us|msec|ms|secs|sec|seconds?|\(s\))\b", re.IGNORECASE)
_RE_WORD = re.compile(r"[A-Za-z][A-Za-z]*")

# Vendor libraries whose presence in sources changes the link line.
_VENDOR_LIBS = [
    "cublas", "cufft", "cusparse", "curand", "cudnn", "cusolver",
    "nvblas", "nvgraph", "nppi",
]

# Libraries that are real deps vs false positives (e.g. "cuda_runtime.h"
# contains neither; "cublas" substring in "cublas_v2.h" is a true positive).
_VENDOR_HEADER_RE = {
    "cublas":  re.compile(r"#include\s*[<\"](?:cublas|cublas_v2)"),
    "cufft":   re.compile(r"#include\s*[<\"](?:cufft|cufftXt)"),
    "cusparse": re.compile(r"#include\s*[<\"](?:cusparse|cusparse_v2)"),
    "curand":  re.compile(r"#include\s*[<\"](?:curand|curand_kernel)"),
    "cudnn":   re.compile(r"#include\s*[<\"](?:cudnn|cudnn_ops)"),
    "cusolver": re.compile(r"#include\s*[<\"](?:cusolverDn|cusolverSp)"),
    "nvblas":  re.compile(r"#include\s*[<\"](?:nvblas)"),
    "nvgraph": re.compile(r"#include\s*[<\"](?:nvgraph)"),
    "nppi":    re.compile(r"#include\s*[<\"](?:nppi)"),
}


def infer_unit(regex: str) -> str | None:
    """Infer the timing unit from a regex literal like `(?: \\(us\\))`.

    Returns None when the regex is ambiguous — multiple distinct unit tokens
    (e.g. alternations like `(?:s|ms|us)`, which match `us`, `ms` and `s`) —
    so the caller falls back to reading the unit from the benchmark source,
    whose printed unit is authoritative. `bitpacking` prints seconds but its
    regex alternation would otherwise pin `us` (1,000,000x error).
    """
    units = {unit for token, unit in _UNIT_TOKENS
             if re.search(token, regex, re.IGNORECASE if token.isalpha() else 0)}
    if len(units) == 1:
        return next(iter(units))
    if len(units) > 1:
        return None
    if _BARE_S.search(regex):
        return "s"
    return None


def unit_from_source(regex: str, main: Path) -> str | None:
    """Fallback: find the print statement the regex matches and read its unit.

    Some benchmarks print e.g. "elapsed time=0.12 ms" but their CI regex only
    captures the number; the unit lives in the source's format string.
    """
    try:
        text = main.read_text(errors="ignore")
    except OSError:
        return None
    # Longest literal words from the regex, tried in order as anchors.
    words = list(dict.fromkeys(_RE_WORD.findall(regex)))
    for w in sorted(words, key=len, reverse=True):
        i = text.find(w)
        if i == -1:
            continue
        line = text[i:i + 400]
        m = _SOURCE_UNIT.search(line)
        if m:
            u = m.group(1).lower()
            return {"usec": "us", "us": "us", "msec": "ms", "ms": "ms",
                    "sec": "s", "secs": "s", "second": "s", "seconds": "s"}[u]
    return None


def scan_vendor_libs(main: Path) -> list[str]:
    """Vendor libs referenced by a benchmark's source file, in link order."""
    try:
        text = main.read_text(errors="ignore")
    except OSError:
        return []
    found = [lib for lib in _VENDOR_LIBS
             if lib in _VENDOR_HEADER_RE and _VENDOR_HEADER_RE[lib].search(text)]
    # Also catch link-time references without includes (rare).
    for lib in _VENDOR_LIBS:
        if lib not in found and re.search(rf"-l{lib}\b", text):
            found.append(lib)
    return found


def src_main(root: Path, name: str, model: str) -> Path | None:
    """Path to the benchmark's main source file for a model, or None."""
    src = root / "src" / f"{name}-{model}"
    if not src.is_dir():
        return None
    main_cu = src / "main.cu"
    if main_cu.exists():
        return main_cu
    cus = sorted(src.glob("*.cu"))
    return cus[0] if cus else None


_DEFINE_RE = re.compile(r"-D[A-Za-z_][A-Za-z0-9_]*(?:=[^ ]+)?")
_INCLUDE_RE = re.compile(r"-I([^\s\\]+)")

# Per-benchmark compile overrides the Makefiles cannot express:
#   lr: linear.h guards on __NVCC__ (nvcc-only macro); clang CUDA must define
#       it to take the CUDA include branch instead of HIP.
EXTRA_DEFINES = {
    "lr": ["-D__NVCC__"],
}


def makefile_flags(src: Path) -> tuple[list[str], list[str]]:
    """(-D defines, -I include dirs) from the Makefile CFLAGS block.

    Handles multi-line continuations (line ends with backslash) and one-level
    $(VAR) references defined in the same Makefile (e.g. SPATH). -I paths are
    stored relative to the bench's own src dir (absolute paths stay absolute)
    so the manifest is portable across checkouts (~/dev/hecbench vs ~/hecbench).
    """
    mf = src / "Makefile"
    if not mf.exists():
        return [], []
    text = mf.read_text(errors="ignore")
    # Simple variable assignments (first definition wins, like make).
    vars_: dict[str, str] = {}
    for line in text.splitlines():
        m = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*[:?+]?=\s*(.+?)\s*$", line)
        if m and m.group(1) not in vars_ and not m.group(2).startswith("$("):
            vars_[m.group(1)] = m.group(2).rstrip("\\").strip()
    def resolve(tok: str) -> str | None:
        out = re.sub(r"\$\((\w+)\)",
                     lambda mm: vars_.get(mm.group(1), mm.group(0)), tok)
        return out if "$(" not in out else None
    defs: list[str] = []
    incs: list[str] = []
    in_cflags = False
    for raw in text.splitlines():
        line = raw.rstrip()
        if "CFLAGS" in line and "=" in line:
            in_cflags = True
        if in_cflags:
            for tok in _DEFINE_RE.findall(line):
                r = resolve(tok)
                if r:
                    defs.append(r)
            for tok in _INCLUDE_RE.findall(line):
                r = resolve(tok)
                if r:
                    incs.append(r)
        if in_cflags and not line.endswith("\\"):
            in_cflags = False
    resolved = []
    for p in incs:
        if os.path.isabs(p):
            resolved.append(p)
        else:
            resolved.append(os.path.relpath((src / p).resolve(), src))
    return list(dict.fromkeys(defs)), list(dict.fromkeys(resolved))


def makefile_sources(src: Path) -> list[str]:
    """Source files a Makefile actually builds (`source =` / `obj =` lines).

    Several upstream targets need multiple translation units or sibling
    sources (clenergy-cuda: `source = clenergy.cu WKFUtils.cu`; boxfilter-cuda:
    `obj = main.o shrUtils.o cmd_arg_reader.o reference.o`). A single
    alphabetical `.cu` fallback (the old behavior) would compile the wrong
    TU (e.g. WKFUtils.cu alone) or miss whole programs. Handles backslash
    continuations and one-level `$(VAR)` resolution; `obj =` entries are
    mapped back to sources by stem (shrUtils.o -> shrUtils.cu/.cpp). Falls
    back to all `*.cu` files for wildcard builds.
    """
    mf = src / "Makefile"
    if not mf.exists():
        return sorted(f.name for f in src.glob("*.cu"))
    text = mf.read_text(errors="ignore")
    vars_: dict[str, str] = {}
    for line in text.splitlines():
        m = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*[:?+]?=\s*(.+?)\s*$", line)
        if m and m.group(1) not in vars_ and not m.group(2).startswith("$("):
            vars_[m.group(1)] = m.group(2).rstrip("\\").strip()
    def resolve(tok: str) -> str | None:
        out = re.sub(r"\$\((\w+)\)",
                     lambda mm: vars_.get(mm.group(1), mm.group(0)), tok)
        return out if "$(" not in out else None
    named: list[str] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        raw = lines[i]
        m = re.match(r"^\s*(?:source|obj)\s*[:?+]?=\s*(.*)$", raw.rstrip())
        if not m:
            i += 1
            continue
        toks = [m.group(1)]
        while raw.rstrip().endswith("\\") and i + 1 < len(lines):
            i += 1
            raw = lines[i]
            toks.append(raw.rstrip())
        for tok in " ".join(toks).split():
            r = resolve(tok)
            if r:
                named.append(r)
        i += 1
    spath_raw = resolve(vars_.get("SPATH", "")) if vars_.get("SPATH") else None
    spath_dir = (src / spath_raw).resolve() if spath_raw else None
    sources: list[str] = []
    for tok in named:
        if tok.endswith(".o"):
            # Objects map back to sources in the bench dir or its SPATH
            # sibling (boxfilter: shrUtils.o -> ../boxfilter-sycl/shrUtils.cpp).
            stem = tok[:-2]
            cands = [src / (stem + ext) for ext in (".cu", ".cpp")]
            if spath_dir:
                cands += [spath_dir / (stem + ext) for ext in (".cu", ".cpp")]
            hit = next((p for p in cands if p.exists()), None)
            if hit is None:
                continue  # generated/unknown object; not a source we can build
            tok = os.path.relpath(hit.resolve(), src)
        if tok.endswith((".cu", ".cpp")) and tok not in sources:
            sources.append(tok)
    return sources or sorted(f.name for f in src.glob("*.cu"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("~/dev/hecbench"),
                        help="HeCBench checkout (default: ~/dev/hecbench)")
    parser.add_argument("--output", type=Path, default=Path(__file__).parent / "hecbench_suite.json")
    args = parser.parse_args()

    root = args.root.expanduser().resolve()
    yaml_path = root / "benchmarks.yaml"
    if not yaml_path.exists():
        print(f"error: {yaml_path} not found", file=sys.stderr)
        return 2

    commit = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"],
                            capture_output=True, text=True).stdout.strip()
    if not commit:
        print("warning: not a git checkout; pinning will be empty", file=sys.stderr)

    try:
        import yaml
    except ImportError:
        print("error: PyYAML required (pip install pyyaml)", file=sys.stderr)
        return 2

    data = yaml.safe_load(yaml_path.read_text())
    benches = {k: v for k, v in data.items() if not k.startswith("#")}

    manifest: dict = {
        "manifest_version": 1,
        "hecbench_url": "https://github.com/ORNL/HeCBench",
        "hecbench_commit": commit,
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "benchmarks": {},
    }

    n_meta = n_bad = 0
    bad: list[str] = []
    for name in sorted(benches):
        entry = benches[name]
        test = entry.get("test") or {}
        if not test.get("regex"):
            continue  # no metadata -> cannot run headless; excluded
        n_meta += 1

        regex = test["regex"]
        try:
            compiled = re.compile(regex)
            groups = compiled.groups
        except re.error as e:
            bad.append(f"{name}: regex does not compile: {e}")
            n_bad += 1
            continue

        unit = infer_unit(regex)
        unit_source = "regex-literal" if unit else None
        not_duration = bool(_RATE_RE.search(regex))
        if not_duration:
            # e.g. "The average performance of reduction is %f GBytes/sec"
            unit = None
            unit_source = "rate-not-duration"
        if unit is None and not not_duration:
            # The unit often lives in a non-main TU (bwt prints "Device time:
            # ... ms" from main.cpp, not bwt.cu): scan every source file of
            # every model dir, first hit wins.
            for model in ("cuda", "hip"):
                sdir = root / "src" / f"{name}-{model}"
                if not sdir.is_dir():
                    continue
                for f in sorted([*sdir.glob("*.cu"), *sdir.glob("*.cpp")]):
                    unit = unit_from_source(regex, f)
                    if unit:
                        break
                if unit:
                    break
            unit_source = "source-printf" if unit else None
        if unit is None and not not_duration:
            bad.append(f"{name}: no unit token in regex or source: {regex[:90]}")

        per: dict = {
            "categories": entry.get("categories", []),
            "models": entry.get("models", []),
            "args": list(test.get("args") or []),
            "regex": regex,
            "regex_groups": groups,
            "unit": unit,
            "unit_source": unit_source,
            "not_duration": not_duration,
            "timeout": test.get("timeout", 300),
        }
        for model in ("cuda", "hip"):
            src = root / "src" / f"{name}-{model}"
            per[f"has_{model}_dir"] = src.is_dir()
            sources = makefile_sources(src) if src.is_dir() else []
            per[f"{model}_sources"] = sources
            per[f"{model}_main"] = ("main.cu" if "main.cu" in sources
                                    else (sources[0] if sources else None))
            if sources:
                per[f"{model}_libs"] = list(dict.fromkeys(
                    lib for s in sources for lib in scan_vendor_libs(src / s)))
                defs, incs = makefile_flags(src)
                per[f"{model}_defines"] = list(dict.fromkeys(
                    defs + EXTRA_DEFINES.get(name, [])))
                per[f"{model}_includes"] = incs
        manifest["benchmarks"][name] = per

    manifest["counts"] = {
        "with_metadata": n_meta,
        "excluded_no_metadata": len(benches) - n_meta,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"wrote {args.output}")
    print(f"benchmarks with metadata: {n_meta} / {len(benches)}")
    for line in bad:
        print(f"  WARN {line}")
    print(f"warnings: {len(bad)} (unit-unknown and regex issues — inspect above)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
