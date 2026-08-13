# polybench-gpu-audit

CIR vs Classic CodeGen measurement harness for the 21-kernel
[Polybench/GPU](https://github.com/RiverDave/polybenchGpu) suite (CUDA + HIP).
This is the staging area for all combine/timing metrics feeding the
[polybench-results](https://github.com/RiverDave/polybench-results) artifact
repo and the LLVM-HPC paper.

## What's here

| File | Purpose |
|---|---|
| `run_polybench.py` | Single entry point; resolves the toolchain from `machines.json` and drives the other scripts (`--compile`, `--runtime`, `--all`, `--offload-merge`, `--publish`). |
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
