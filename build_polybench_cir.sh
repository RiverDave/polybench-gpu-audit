#!/usr/bin/env bash
# Build ClangIR (LLVM + Clang + MLIR with CLANG_ENABLE_CIR) then compile all
# PolyBench/GPU CUDA kernels through both the CIR and upstream pipelines.
#
# Usage:
#   ./build_polybench_cir.sh [--skip-build] [--arch sm_XX] [--jobs N]
#
#   --skip-build  Skip the LLVM cmake/make step (use an existing build).
#   --arch        CUDA GPU architecture (default: sm_86 for A10).
#   --jobs        Parallel jobs for both LLVM build and kernel compilation
#                 (default: nproc).

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
LLVM_SRC="/home/ubuntu/polybench-gpu-audit/llvm-project"
LLVM_BUILD="${LLVM_SRC}/build"
POLYBENCH_ROOT="/home/ubuntu/polybenchGpu"
CUDA_ROOT="/usr/local/cuda"
GCC_INSTALL_DIR="/usr/lib/gcc/x86_64-linux-gnu/11"
LOG_DIR="/home/ubuntu/polybench-gpu-audit/logs/cir-cuda"
SCRIPT="/home/ubuntu/polybench-gpu-audit/run_polybench_cir.py"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
SKIP_BUILD=0
ARCH="sm_86"
JOBS="$(nproc)"

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=1; shift ;;
        --arch)       ARCH="$2";   shift 2 ;;
        --jobs)       JOBS="$2";   shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

echo "=== PolyBench/GPU + ClangIR build script ==="
echo "  LLVM source  : ${LLVM_SRC}"
echo "  LLVM build   : ${LLVM_BUILD}"
echo "  PolyBench    : ${POLYBENCH_ROOT}"
echo "  CUDA root    : ${CUDA_ROOT}"
echo "  GCC dir      : ${GCC_INSTALL_DIR}"
echo "  GPU arch     : ${ARCH}"
echo "  Jobs         : ${JOBS}"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Build ClangIR
# ---------------------------------------------------------------------------
if [[ "${SKIP_BUILD}" -eq 0 ]]; then
    echo "--- Step 1/2: Configure + build LLVM/Clang/MLIR with ClangIR ---"

    mkdir -p "${LLVM_BUILD}"
    cd "${LLVM_BUILD}"

    cmake "${LLVM_SRC}/llvm" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DLLVM_ENABLE_PROJECTS="clang;mlir" \
        -DCLANG_ENABLE_CIR=ON \
        -DLLVM_TARGETS_TO_BUILD="X86;NVPTX" \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_USE_SPLIT_DWARF=ON \
        -DLLVM_PARALLEL_LINK_JOBS=4 \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

    make -j"${JOBS}" clang mlir-opt
else
    echo "--- Step 1/2: Skipping LLVM build (--skip-build) ---"
fi

CLANG="${LLVM_BUILD}/bin/clang++"
if [[ ! -x "${CLANG}" ]]; then
    echo "error: clang++ not found at ${CLANG}" >&2
    exit 1
fi
echo "clang++ : ${CLANG}"
"${CLANG}" --version
echo ""

# ---------------------------------------------------------------------------
# Step 2: Compile all CUDA kernels through CIR + OG pipelines
# ---------------------------------------------------------------------------
# echo "--- Step 2/2: Compile PolyBench CUDA kernels (CIR + OG) ---"
# mkdir -p "${LOG_DIR}"

# python3 "${SCRIPT}" \
#     --clang        "${CLANG}" \
#     --polybench-root "${POLYBENCH_ROOT}" \
#     --cuda-root    "${CUDA_ROOT}" \
#     --gcc-install-dir "${GCC_INSTALL_DIR}" \
#     --arch         "${ARCH}" \
#     --log-dir      "${LOG_DIR}" \
#     --jobs         "${JOBS}"

# echo ""
# echo "Done. Summary: ${LOG_DIR}/summary.md"
