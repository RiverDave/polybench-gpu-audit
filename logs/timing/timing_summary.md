PolyBench CUDA compile-phase timing: CIR vs OG.

- CUDA arch: `sm_90a`
- PolyBench root: `/home/ubuntu/polybenchGpu`
- Logs: `/home/ubuntu/polybench-gpu-audit/logs/timing`
- Flags: `-O3 --cuda-device-only -ftime-report -mllvm -time-passes` (CIR adds `--mlir-timing --mlir-pass-statistics`)
- CIR compiled OK: `42/42`
- OG compiled OK: `42/42`

## Phase averages (wall seconds, over successful compilations)

| Phase | CIR avg | OG avg | delta |
|---|---:|---:|---:|
| **Total (wall)** | **0.774** | **0.824** | **-0.049** |

## Per-benchmark breakdown (wall seconds)

| Benchmark | Source set | CIR total | OG total |
|---|---:|---:|---:|
| convolution-2d | CUDA | 0.819 | 0.817 |
| 2mm | CUDA | 0.812 | 0.783 |
| convolution-3d | CUDA | 0.802 | 0.871 |
| 3mm | CUDA | 0.848 | 0.773 |
| adi | CUDA | 0.751 | 0.872 |
| atax | CUDA | 0.799 | 0.782 |
| bicg | CUDA | 0.772 | 0.881 |
| correlation | CUDA | 0.867 | 0.845 |
| covariance | CUDA | 0.739 | 0.886 |
| doitgen | CUDA | 0.695 | 0.862 |
| fdtd-2d | CUDA | 0.754 | 0.777 |
| gemm | CUDA | 0.778 | 0.843 |
| gemver | CUDA | 0.726 | 0.889 |
| gesummv | CUDA | 0.776 | 0.752 |
| gramschmidt | CUDA | 0.862 | 0.794 |
| jacobi-1d-imper | CUDA | 0.742 | 0.857 |
| jacobi-2d-imper | CUDA | 0.825 | 0.800 |
| lu | CUDA | 0.824 | 0.744 |
| mvt | CUDA | 0.833 | 0.792 |
| syr2k | CUDA | 0.710 | 0.814 |
| syrk | CUDA | 0.839 | 0.828 |
| convolution-2d | CUDA duplicate | 0.705 | 0.845 |
| 2mm | CUDA duplicate | 0.713 | 0.772 |
| convolution-3d | CUDA duplicate | 0.772 | 0.836 |
| 3mm | CUDA duplicate | 0.738 | 0.863 |
| adi | CUDA duplicate | 0.808 | 0.882 |
| atax | CUDA duplicate | 0.743 | 0.765 |
| bicg | CUDA duplicate | 0.671 | 0.836 |
| correlation | CUDA duplicate | 0.758 | 0.796 |
| covariance | CUDA duplicate | 0.757 | 0.833 |
| doitgen | CUDA duplicate | 0.738 | 0.806 |
| fdtd-2d | CUDA duplicate | 0.796 | 0.810 |
| gemm | CUDA duplicate | 0.796 | 0.892 |
| gemver | CUDA duplicate | 0.804 | 0.780 |
| gesummv | CUDA duplicate | 0.778 | 0.743 |
| gramschmidt | CUDA duplicate | 0.845 | 0.818 |
| jacobi-1d-imper | CUDA duplicate | 0.693 | 0.827 |
| jacobi-2d-imper | CUDA duplicate | 0.697 | 0.820 |
| lu | CUDA duplicate | 0.806 | 0.864 |
| mvt | CUDA duplicate | 0.735 | 0.852 |
| syr2k | CUDA duplicate | 0.811 | 0.806 |
| syrk | CUDA duplicate | 0.789 | 0.886 |
