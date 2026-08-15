#!/usr/bin/env python3
"""Benchmark-agnostic router: one entry point, suite selected by flag.

  ./run_measure_cir_gpu.py --polybench --cuda --accurate-mode --publish
  ./run_measure_cir_gpu.py --hecbench  --cuda --compile --publish
  ./run_measure_cir_gpu.py --hecbench  --cuda --benchmarks accuracy,gmm --runtime

The router owns only the suite selector; everything else passes through to the
suite backend untouched (each backend validates its own flag vocabulary, so a
flag that does not apply fails with that backend's own error message). Both
backends stay directly invokable for automation (setup.sh, cron, docs).

Exit code and publish behaviour are the backend's.
"""

from __future__ import annotations

import argparse
import sys

import run_hecbench
import run_polybench


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="run_measure_cir_gpu", add_help=False,
        description="CIR-vs-OG GPU measurement across benchmark suites.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--polybench", action="store_true",
                       help="PolyBench suite (default)")
    group.add_argument("--hecbench", action="store_true",
                       help="HeCBench suite (ORNL)")
    known, rest = parser.parse_known_args(argv)

    entry = run_hecbench.main if known.hecbench else run_polybench.main
    return entry(rest)


if __name__ == "__main__":
    raise SystemExit(main())
