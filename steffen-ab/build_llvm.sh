#!/bin/bash
# Check out one ref in ~/llvm-project and build it. $1 = ref (commit or branch),
# $2 = tag used for the logs. Mirrors setup.sh's cmake flags (CIR enabled,
# lld, split dwarf, dylibs off, tests off) so both arms are built identically.
set -e
REF="$1"; TAG="$2"
cd ~/llvm-project
git fetch -q origin "$REF" 2>/dev/null || true
git checkout -q "$REF"
echo "=== $(date) building $TAG at $(git rev-parse --short HEAD) ==="
cmake -G Ninja -S llvm -B build \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DCLANG_ENABLE_CIR=ON -DLLVM_ENABLE_LLD=ON \
  -DLLVM_ENABLE_PROJECTS="clang;mlir;lld" -DLLVM_TARGETS_TO_BUILD="X86;NVPTX;AMDGPU" \
  -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_USE_SPLIT_DWARF=ON -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DLLVM_BUILD_LLVM_DYLIB=OFF -DLLVM_LINK_LLVM_DYLIB=OFF -DCLANG_LINK_CLANG_DYLIB=OFF \
  -DMLIR_BUILD_MLIR_DYLIB=OFF -DMLIR_LINK_MLIR_DYLIB=OFF -DLLVM_PARALLEL_LINK_JOBS=4 \
  -DLLVM_BUILD_TESTS=OFF -DLLVM_BUILD_EXAMPLES=OFF -DLLVM_ENABLE_RTTI=OFF -DLLVM_ENABLE_EH=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON > ~/cmake-$TAG.log 2>&1
ninja -C build -j "${JOBS:-30}" clang cir-opt cir-offload-merge llc opt > ~/build-$TAG.log 2>&1
echo "=== $(date) DONE $TAG $(git rev-parse --short HEAD) ==="