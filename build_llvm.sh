#!/usr/bin/env bash
set -euo pipefail

LLVM_SRC_ORIG="${HOME}/llvm-project"
LLVM_SRC="/dev/shm/llvm-project"   # source on RAM fs — fast reads during configure + compile
BUILD_DIR="/dev/shm/llvm-build"    # build tree on RAM fs — fast writes for .o / .a / CMakeFiles
BIN_DIR="/workspace/llvm-bin"      # binaries only on exec-capable NFS (noexec workaround via symlink)

mkdir -p "${BIN_DIR}"

# Copy source to RAM fs if not already there
if [ ! -d "${LLVM_SRC}" ]; then
  echo "=== Copying source to /dev/shm (~6 GB) ==="
  cp -a "${LLVM_SRC_ORIG}" "${LLVM_SRC}"
fi

# Pre-create build dir and symlink bin/ → exec-capable NFS path.
# The kernel resolves symlinks before checking noexec, so built tools
# actually live on /workspace and can be executed during the build.
mkdir -p "${BUILD_DIR}"
if [ ! -L "${BUILD_DIR}/bin" ]; then
  ln -s "${BIN_DIR}" "${BUILD_DIR}/bin"
fi

echo "=== Configuring LLVM ==="
cmake -G Ninja \
  -S "${LLVM_SRC}/llvm" \
  -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DLLVM_ENABLE_PROJECTS="clang;mlir;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86;AMDGPU;NVPTX" \
  -DCLANG_ENABLE_CIR=ON \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_PARALLEL_LINK_JOBS=16 \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_BUILD_DOCS=OFF \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_CXX_COMPILER=g++ \
  -DLLVM_USE_LINKER=lld

# Phase 1: generate all MLIR tablegen headers before full parallel build.
# CIR lowering files include MLIR builtin headers but the cmake dependency
# graph is missing the edge, so a 192-way parallel build races them. Building
# mlir-headers first avoids the race without patching any CMakeLists.
echo "=== Phase 1: MLIR headers ($(nproc) jobs) ==="
cmake --build "${BUILD_DIR}" --target mlir-headers -j "$(nproc)" 2>&1 | tee "${BUILD_DIR}/build.log"

echo "=== Phase 2: full build ($(nproc) jobs) ==="
cmake --build "${BUILD_DIR}" -j "$(nproc)" 2>&1 | tee -a "${BUILD_DIR}/build.log"

# Strip debug info from all binaries — unstripped RelWithDebInfo can hit
# the /workspace quota (5+ GB per binary × ~50 tools ≈ 100+ GB).
echo "=== Stripping binaries ==="
find "${BIN_DIR}" -type f -executable | xargs strip 2>/dev/null || true

echo "=== Done. clang at ${BIN_DIR}/clang ==="
