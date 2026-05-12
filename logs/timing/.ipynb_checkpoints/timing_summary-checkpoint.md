PolyBench compile-phase timing: CIR vs OG.

- arch: `hip:gfx942`
- PolyBench root: `/root/polybenchGpu`
- Logs: `/root/polybench-gpu-audit/logs/timing`
- Flags: `-O3 device-only -ftime-report -mllvm -time-passes` (CIR adds `--mlir-pass-statistics`)
- CIR compiled OK: `1/1`
- OG compiled OK: `1/1`

## Phase averages (wall seconds, over successful compilations)

| Phase | CIR avg | OG avg | delta |
|---|---:|---:|---:|
| Frontend+IRGen | 0.980 | 0.938 | +0.042 |
| ISel | 0.001 | 0.001 | +0.000 |
| LLVM-analysis | 0.003 | 0.003 | +0.000 |
| LLVM-passes | 0.024 | 0.022 | +0.002 |
| RegAlloc | 0.000 | 0.000 | +0.000 |
| **Total (wall)** | **1.151** | **1.107** | **+0.044** |

## Per-benchmark breakdown (wall seconds)

| Benchmark | Source set | CIR Frontend+IRGen | OG Frontend+IRGen | CIR ISel | OG ISel | CIR LLVM-analysis | OG LLVM-analysis | CIR LLVM-passes | OG LLVM-passes | CIR RegAlloc | OG RegAlloc | CIR total | OG total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| convolution-2d | HIP | 0.980 | 0.938 | 0.001 | 0.001 | 0.003 | 0.003 | 0.024 | 0.022 | 0.000 | 0.000 | 1.151 | 1.107 |
