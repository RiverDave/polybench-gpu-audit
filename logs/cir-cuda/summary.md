PolyBench CUDA/HIP compile-only results through ClangIR.

- CUDA arch: `cuda:sm_80 hip:gfx942`
- PolyBench root: `/root/polybenchGpu/HIP`
- Logs: `/root/polybench-gpu-audit/logs/cir-cuda`
- CIR result: `0/21` passed
- OG result: `21/21` passed

| Benchmark | Source set | CIR | OG | CIR time (s) | OG time (s) |
|---|---:|:---:|:---:|---:|---:|
| convolution-2d | 2DCONV | fail | pass | 7.605 | 1.069 |
| 2mm | 2MM | fail | pass | 7.802 | 1.106 |
| convolution-3d | 3DCONV | fail | pass | 7.580 | 1.080 |
| 3mm | 3MM | fail | pass | 7.790 | 1.115 |
| adi | ADI | fail | pass | 6.732 | 1.080 |
| atax | ATAX | fail | pass | 6.695 | 1.082 |
| bicg | BICG | fail | pass | 8.120 | 1.079 |
| correlation | CORR | fail | pass | 9.373 | 1.103 |
| covariance | COVAR | fail | pass | 7.415 | 1.098 |
| doitgen | DOITGEN | fail | pass | 7.200 | 1.073 |
| fdtd-2d | FDTD-2D | fail | pass | 7.186 | 1.117 |
| gemm | GEMM | fail | pass | 7.610 | 1.102 |
| gemver | GEMVER | fail | pass | 7.749 | 1.083 |
| gesummv | GESUMMV | fail | pass | 7.261 | 1.122 |
| gramschmidt | GRAMSCHM | fail | pass | 8.329 | 1.120 |
| jacobi-1d-imper | JACOBI1D | fail | pass | 7.840 | 1.108 |
| jacobi-2d-imper | JACOBI2D | fail | pass | 8.479 | 1.070 |
| lu | LU | fail | pass | 7.392 | 1.079 |
| mvt | MVT | fail | pass | 6.995 | 1.124 |
| syr2k | SYR2K | fail | pass | 7.191 | 1.064 |
| syrk | SYRK | fail | pass | 6.448 | 1.084 |

Failures:

- [CIR] `/root/polybenchGpu/HIP/2DCONV/2DConvolution.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/2DCONV_2DConvolution.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/2DCONV -std=c++17 -O0 -c /root/polybenchGpu/HIP/2DCONV/2DConvolution.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/2DCONV -o /tmp/2DCONV_2DConvolution.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/2MM/2mm.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/2MM_2mm.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/2MM -std=c++17 -O0 -c /root/polybenchGpu/HIP/2MM/2mm.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/2MM -o /tmp/2MM_2mm.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/3DCONV/3DConvolution.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/3DCONV_3DConvolution.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/3DCONV -std=c++17 -O0 -c /root/polybenchGpu/HIP/3DCONV/3DConvolution.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/3DCONV -o /tmp/3DCONV_3DConvolution.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/3MM/3mm.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/3MM_3mm.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/3MM -std=c++17 -O0 -c /root/polybenchGpu/HIP/3MM/3mm.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/3MM -o /tmp/3MM_3mm.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/ADI/adi.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/ADI_adi.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/ADI -std=c++17 -O0 -c /root/polybenchGpu/HIP/ADI/adi.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/ADI -o /tmp/ADI_adi.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/ATAX/atax.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/ATAX_atax.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/ATAX -std=c++17 -O0 -c /root/polybenchGpu/HIP/ATAX/atax.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/ATAX -o /tmp/ATAX_atax.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/BICG/bicg.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/BICG_bicg.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/BICG -std=c++17 -O0 -c /root/polybenchGpu/HIP/BICG/bicg.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/BICG -o /tmp/BICG_bicg.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/CORR/correlation.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/CORR_correlation.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/CORR -std=c++17 -O0 -c /root/polybenchGpu/HIP/CORR/correlation.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/CORR -o /tmp/CORR_correlation.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/COVAR/covariance.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/COVAR_covariance.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/COVAR -std=c++17 -O0 -c /root/polybenchGpu/HIP/COVAR/covariance.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/COVAR -o /tmp/COVAR_covariance.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/DOITGEN/doitgen.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/DOITGEN_doitgen.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/DOITGEN -std=c++17 -O0 -c /root/polybenchGpu/HIP/DOITGEN/doitgen.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/DOITGEN -o /tmp/DOITGEN_doitgen.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/FDTD-2D/fdtd2d.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/FDTD-2D_fdtd2d.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/FDTD-2D -std=c++17 -O0 -c /root/polybenchGpu/HIP/FDTD-2D/fdtd2d.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/FDTD-2D -o /tmp/FDTD-2D_fdtd2d.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/GEMM/gemm.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/GEMM_gemm.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/GEMM -std=c++17 -O0 -c /root/polybenchGpu/HIP/GEMM/gemm.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/GEMM -o /tmp/GEMM_gemm.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/GEMVER/gemver.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/GEMVER_gemver.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/GEMVER -std=c++17 -O0 -c /root/polybenchGpu/HIP/GEMVER/gemver.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/GEMVER -o /tmp/GEMVER_gemver.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/GESUMMV/gesummv.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/GESUMMV_gesummv.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/GESUMMV -std=c++17 -O0 -c /root/polybenchGpu/HIP/GESUMMV/gesummv.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/GESUMMV -o /tmp/GESUMMV_gesummv.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/GRAMSCHM/gramschmidt.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/GRAMSCHM_gramschmidt.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/GRAMSCHM -std=c++17 -O0 -c /root/polybenchGpu/HIP/GRAMSCHM/gramschmidt.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/GRAMSCHM -o /tmp/GRAMSCHM_gramschmidt.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/JACOBI1D/jacobi1D.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/JACOBI1D_jacobi1D.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/JACOBI1D -std=c++17 -O0 -c /root/polybenchGpu/HIP/JACOBI1D/jacobi1D.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/JACOBI1D -o /tmp/JACOBI1D_jacobi1D.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/JACOBI2D/jacobi2D.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/JACOBI2D_jacobi2D.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/JACOBI2D -std=c++17 -O0 -c /root/polybenchGpu/HIP/JACOBI2D/jacobi2D.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/JACOBI2D -o /tmp/JACOBI2D_jacobi2D.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/LU/lu.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/LU_lu.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/LU -std=c++17 -O0 -c /root/polybenchGpu/HIP/LU/lu.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/LU -o /tmp/LU_lu.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/MVT/mvt.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/MVT_mvt.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/MVT -std=c++17 -O0 -c /root/polybenchGpu/HIP/MVT/mvt.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/MVT -o /tmp/MVT_mvt.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/SYR2K/syr2k.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/SYR2K_syr2k.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/SYR2K -std=c++17 -O0 -c /root/polybenchGpu/HIP/SYR2K/syr2k.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/SYR2K -o /tmp/SYR2K_syr2k.hip.cpp.cir.o`
- [CIR] `/root/polybenchGpu/HIP/SYRK/syrk.hip.cpp`
  - log: `/root/polybench-gpu-audit/logs/cir-cuda/SYRK_syrk.hip.cpp.cir.log`
  - error: `loc("/opt/rocm-6.3.0/include/hip/amd_detail/hip_assert.h":70:3): error: 'cir.cast' op result type address space does not match the address space of the operand`
  - command: `/workspace/llvm-bin/clang-23 -fclangir --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/11 -x hip --hip-path=/opt/rocm-6.3.0 --offload-arch=gfx942 -D__AMDGCN_WAVEFRONT_SIZE=64 -I/root/polybenchGpu/CUDA/SYRK -std=c++17 -O0 -c /root/polybenchGpu/HIP/SYRK/syrk.hip.cpp -I/root/polybenchGpu/HIP -I/root/polybenchGpu/HIP/SYRK -o /tmp/SYRK_syrk.hip.cpp.cir.o`
