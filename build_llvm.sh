#!/usr/bin/env bash
set -euo pipefail

LLVM_SRC_ORIG="${HOME}/llvm-project"
LLVM_SRC="/dev/shm/llvm-project"      # source on RAM fs — fast reads during configure + compile
BUILD_DIR="/dev/shm/llvm-build"        # build tree on RAM fs — fast writes for .o / .a / CMakeFiles
BIN_DIR="/workspace/llvm-bin"          # binaries only on exec-capable NFS
INSTALL_DIR="/workspace/llvm-install"

mkdir -p "${BIN_DIR}" "${INSTALL_DIR}"

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
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
  -DLLVM_ENABLE_PROJECTS="clang;mlir" \
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

echo "=== Building with $(nproc) jobs ==="
cmake --build "${BUILD_DIR}" -j "$(nproc)" 2>&1 | tee "${BUILD_DIR}/build.log"

echo "=== Installing to ${INSTALL_DIR} ==="
cmake --install "${BUILD_DIR}"

echo "=== Done. Binaries at ${INSTALL_DIR}/bin ==="
