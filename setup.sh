#!/usr/bin/env bash
# One-shot VM setup for ClangIR / PolyBench-GPU development.
#
# Usage:
#   bash setup.sh [--skip-build] [--jobs N]
#
# Assumptions: Ubuntu 22.04, CUDA already at /usr/local/cuda, sudo access.

set -euo pipefail

LLVM_FORK="https://github.com/RiverDave/llvm-project"
POLYBENCH_FORK="https://github.com/RiverDave/polybenchGpu"
LLVM_SRC="$HOME/llvm-project"
LLVM_BUILD="$LLVM_SRC/build"
POLYBENCH_DIR="$HOME/polybenchGpu"
JOBS="$(nproc)"
SKIP_BUILD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=1; shift ;;
        --jobs)       JOBS="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# 1. SSH key — generate if absent, always show public key
# ---------------------------------------------------------------------------
echo "=== [1/5] SSH key ==="

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    echo "No SSH key found — generating one."
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "davidriverg@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
    echo ""
    echo "Add this public key to https://github.com/settings/keys before continuing:"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    read -r -p "Press Enter once the key is added to GitHub… "
else
    echo "SSH key already present."
    echo "Public key: $(cat "$HOME/.ssh/id_ed25519.pub")"
fi

# Make sure github.com is in known_hosts so git clone doesn't prompt
ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

# ---------------------------------------------------------------------------
# 2. System packages
# ---------------------------------------------------------------------------
echo ""
echo "=== [2/5] System packages ==="
sudo apt-get update -q
sudo apt-get install -y \
    ninja-build \
    ccache \
    lld \
    gcc-11 g++-11 \
    cmake \
    python3 python3-pip \
    git

# ---------------------------------------------------------------------------
# 3. Clone repos
# ---------------------------------------------------------------------------
echo ""
echo "=== [3/5] Repos ==="

if [[ ! -d "$LLVM_SRC/.git" ]]; then
    echo "Cloning llvm-project fork (this is large — ~5 GB)…"
    git clone "$LLVM_FORK" "$LLVM_SRC"
else
    echo "llvm-project: already present, skipping clone."
fi

if [[ ! -d "$POLYBENCH_DIR/.git" ]]; then
    echo "Cloning polybenchGpu…"
    git clone "$POLYBENCH_FORK" "$POLYBENCH_DIR"
else
    echo "polybenchGpu: already present, skipping clone."
fi

# ---------------------------------------------------------------------------
# 4. Configure LLVM (Ninja + ccache + lld)
# ---------------------------------------------------------------------------
echo ""
echo "=== [4/5] CMake configure ==="

mkdir -p "$LLVM_BUILD"

cmake -G Ninja \
    -S "$LLVM_SRC/llvm" \
    -B "$LLVM_BUILD" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_COMPILER=/usr/bin/gcc-11 \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++-11 \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCLANG_ENABLE_CIR=ON \
    -DLLVM_ENABLE_LLD=ON \
    -DLLVM_ENABLE_PROJECTS="clang;mlir" \
    -DLLVM_TARGETS_TO_BUILD="X86;NVPTX" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_BUILD_TESTS=OFF \
    -DLLVM_BUILD_EXAMPLES=OFF \
    -DLLVM_ENABLE_RTTI=OFF \
    -DLLVM_ENABLE_EH=OFF

# ---------------------------------------------------------------------------
# 5. Build
# ---------------------------------------------------------------------------
echo ""
if [[ "$SKIP_BUILD" -eq 1 ]]; then
    echo "=== [5/5] Skipping build (--skip-build) ==="
    echo "Run: ninja -C $LLVM_BUILD clang clang-linker-wrapper cir-offload-merge -j$JOBS"
else
    echo "=== [5/5] Building clang (-j$JOBS) — ~20-40 min cold, fast with ccache ==="
    ninja -C "$LLVM_BUILD" clang clang-linker-wrapper cir-offload-merge -j"$JOBS"
    echo ""
    echo "clang++ version:"
    "$LLVM_BUILD/bin/clang++" --version
fi


# ---------------------------------------------------------------------------
# 6. Claude
# ---------------------------------------------------------------------------

curl -fsSL https://claude.ai/install.sh | bash

echo ""
echo "=== Done ==="
echo ""
echo "Useful commands:"
echo "  Rebuild:    ninja -C $LLVM_BUILD clang -j\$(nproc)"
echo "  Benchmarks: python3 run_cir_offload_merge.py \\"
echo "                --clang $LLVM_BUILD/bin/clang++ \\"
echo "                --polybench-root $POLYBENCH_DIR \\"
echo "                --cuda-root /usr/local/cuda \\"
echo "                --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \\"
echo "                --arch sm_86"
