# polybench-gpu-audit

CIR vs Classic CodeGen measurement harness for the 21-kernel
[Polybench/GPU](https://github.com/RiverDave/polybenchGpu) suite (CUDA + HIP).
This is the staging area for all combine/timing metrics feeding the
[polybench-results](https://github.com/RiverDave/polybench-results) artifact
repo and the LLVM-HPC paper.

## What's here

| File | Purpose |
|---|---|
| `run_polybench.py` | PolyBench entry point; resolves the toolchain from `machines.json` and drives the other scripts (`--compile`, `--runtime`, `--all`, `--offload-merge`, `--publish`). |
| `run_hecbench.py` | HeCBench entry point: same CLI vocabulary + benchmark selection (`--benchmarks`, `--benchmarks-file`, `--skip`); data-driven from `hecbench_suite.json`. |
| `run_measure_cir_gpu.py` | Benchmark-agnostic router: `--polybench` (default) or `--hecbench`; everything else passes through to the backend. |
| `gen_hecbench_manifest.py` / `hecbench_suite.json` | Generator + pinned manifest (run args, timing regex, unit, vendor libs per benchmark) from ORNL/HeCBench `benchmarks.yaml`. |
| `run_compile.py` | CIR vs OG compile-phase timing breakdown (host+device, `-ftime-report` / `-time-passes`); `--merge` swaps the pair to CIR vs CIR-merge. |
| `run_runtime.py` | CIR vs OG GPU runtime + executable size per benchmark; `--merge` swaps the pair to CIR vs CIR-merge. |
| `polybench_common.py` | Shared benchmark table, path/name helpers, toolchain auto-detection. |
| `measure_merge_overhead.py` | Step-by-step pipeline timing for the merge overhead (single benchmark). |
| `measure_multiarch_scaling.py` | Merge compile-time overhead vs number of target architectures. |
| `machines.json` | Toolchain profiles per machine (CUDA/ROCm paths, archs). |
| `setup.sh` / `build_polybench_cir.sh` | VM provisioning + ClangIR build. |
| `cir-offload-merge-analysis.md`, `results.json`, `multiarch_scaling*.json/png` | Prior analysis outputs. |

## Typical usage

```bash
# Everything, one machine, auto-detected toolchain:
./run_polybench.py --all --accurate-mode

# Benchmark-agnostic entry (defaults to PolyBench; --hecbench switches suite):
./run_measure_cir_gpu.py --hecbench --cuda --compile --publish
./run_measure_cir_gpu.py --hecbench --cuda --benchmarks accuracy,fft --runtime

# HeCBench selection: explicit names, a JSON file, or all 162 with metadata
# (--skip / --limit refine; units come from the pinned manifest).
./run_hecbench.py --cuda --runtime --benchmarks-file hecbench_paper.json

# One axis:
./run_polybench.py --hip --compile --accurate-mode

# Offload-merge comparison (combine work): CIR no-merge vs CIR-merge
./run_polybench.py --cuda --runtime --accurate-mode --offload-merge --publish

# Merge-specific overhead, single benchmark:
python3 measure_merge_overhead.py --cuda --benchmark adi --clang .../bin/clang++

# Multi-arch scaling:
python3 measure_multiarch_scaling.py --cuda -j8 --out results.json --plot
```

## Output convention

Runs produce `provenance.json` + `*__{compile,runtime}_results.json` /
`*_summary.md` directories (named `<machine>/<ISO-timestamp>`), matching what
`polybench-results` consumes. `--publish` commits them to
`RiverDave/polybench-results` directly.

## Reproducing the paper data

The canonical paper runs (LLVM `c45e6b9e4d95`, scripts commit `acc8640`,
8 samples) live in `polybench-results`: `nvidia-h100/2026-08-10T00-06Z`
and `amd-mi300x/2026-08-10T01-19Z`. See that repo's README.
