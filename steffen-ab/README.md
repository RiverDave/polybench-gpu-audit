# Steffen staging branch vs fork trunk — PolyBench A/B

Runs the standard polybench-gpu-audit evaluation twice on one box, once per arm,
rebuilding the single LLVM tree between arms:

| arm | ref | meaning |
|---|---|---|
| A | `cb73209ee662` (fork trunk commit) | **control** — fork's own CIR/offload-merge pipeline |
| B | `experiment/steffen-staging-on-trunk` | **treatment** — Steffen's offload MLIR/CIR staging port |

## Why a separate branch

`run_polybench.py` already supports everything needed (`--clang`, `--log-root`,
`--clang-flags`, `--accurate-mode`, `--publish`), so this branch only adds the
two-arm driver + build helper. No change to the measurement code path: both arms
go through the same script, the same warmup/sample protocol and the same
provenance stamping as every other campaign.

## Usage (on the box)

```bash
cd ~/polybench-gpu-audit
git checkout experiment/steffen-staging-ab
./steffen-ab/run_ab.sh              # builds A, measures A, builds B, measures B
PUBLISH=1 ./steffen-ab/run_ab.sh    # also push results to polybench-results
```

Requirements, both assumed to exist on the box:

- `~/llvm-project` — a clone of `RiverDave/llvm-project` (any depth).
- `~/polybenchGpu` — corpus pinned to `f5613c4` (`experiment/static-kernels-pr25`),
  same pin as the launch-noalias campaigns.
- CUDA toolkit at `/usr/local/cuda` (harness auto-detects), `ccache` installed.

## Notes

- Default runs measure **CIR vs OG** per arm; the OG column is the
  unchanged-code negative control across arms (same classic codegen, same
  corpus, same GPU) and the CIR column is each arm's own pipeline. Set
  `OFFLOAD_MERGE=1` to swap the pair to CIR vs CIR-merge (both arms then run
  the fork's `--clangir-offload-merge` driver path).
- Arm separation is `--log-root temp-A` / `temp-B`. The results are only safe
  once copied/published — the harness reuses a per-run-kind temp dir otherwise.
- On arm B, CUDA codegen is Steffen's offload representation by default
  (`-fclangir` injects `-clangir-offload`), so the A/B is
  representation-plus-pass-set vs the fork's pipeline, not pass-set alone.
- Provenance trap applies: each arm's run happens with its checkout in place;
  do not move `HEAD` mid-run.
- `compare_arms.py` reads each arm's `runtime_results.json` (the harness's own
  output) and writes `AB-report.md` next to this script.