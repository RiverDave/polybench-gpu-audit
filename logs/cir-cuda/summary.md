PolyBench CUDA compile-only results through ClangIR.

- CUDA arch: `sm_90a`
- PolyBench root: `/home/ubuntu/polybenchGpu`
- Logs: `/home/ubuntu/polybench-gpu-audit/logs/cir-cuda`
- CIR result: `1/1` passed
- OG result: `1/1` passed

| Benchmark | Source set | CIR | OG | CIR time (s) | OG time (s) |
|---|---:|:---:|:---:|---:|---:|
| convolution-2d | CUDA | pass | pass | 4.398 | 1.460 |
