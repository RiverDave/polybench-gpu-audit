# polybench-gpu-audit

Audit of `@llvm.nvvm.*` and `@llvm.amdgcn.*` intrinsics emitted by the upstream
Clang frontend across the 21-kernel [Polybench/GPU](https://github.com/RiverDave/polybenchGpu)
suite, to define the builtin surface ClangIR must support for end-to-end GPU
compilation ([llvm/llvm-project#179278](https://github.com/llvm/llvm-project/issues/179278)).

This may also be used to explore and identify potential heterogeneous optimizations
as part of the GSOC project [CIR Combine: Cross-Boundary Analysis for Heterogeneous CUDA/HIP Compilation](https://summerofcode.withgoogle.com/programs/2026/projects/DtnfQpPD).

## Reproduce

```bash
# Prerequisites: Ubuntu 22.04, CUDA headers, clang-20, ROCm 6.3.4
wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s 20 all
sudo apt install -y hip-dev hipify-clang rocm-device-libs=1.0.0.60304-76~22.04

KERNELS="2DCONV 2MM 3DCONV 3MM ADI ATAX BICG CORR COVAR DOITGEN \
         FDTD-2D GEMM GEMVER GESUMMV GRAMSCHM JACOBI1D JACOBI2D LU MVT SYR2K SYRK"

# CUDA -> IR
cd polybenchGpu/CUDA
for k in $KERNELS; do
  clang-20 -x cuda --cuda-device-only --cuda-gpu-arch=sm_80 \
    --cuda-path=/usr/local/cuda -I /usr/include -O0 -emit-llvm -S \
    -I ../common -I "$k" $(ls "$k"/*.cu | head -1) -o cuda-ir/"$k".ll
done

# HIP -> IR
for k in $KERNELS; do
  clang-20 -x hip --offload-device-only --offload-arch=gfx90a \
    --rocm-path=/opt/rocm-6.3.4 \
    --rocm-device-lib-path=/opt/rocm-6.3.4/lib/llvm/lib/clang/18/lib/amdgcn/bitcode \
    -O0 -emit-llvm -S -I ../common -I "$k" hip-src/"$k".hip.cpp -o hip-ir/"$k".ll
done
```
