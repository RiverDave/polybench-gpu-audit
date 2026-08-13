#!/usr/bin/env bash
# One-shot VM setup for ClangIR / PolyBench-GPU development on AMD Devcloud.
#
# Usage:
#   ./setup.sh [--skip-build] [--jobs N] \
#              [--llvm-repo <url>] [--llvm-branch <branch>] [--llvm-commit <sha>] \
#              [--with-agents]
#
#   --llvm-repo    llvm-project to clone (default: David's fork over ssh).
#                  Upstream: git@github.com:llvm/llvm-project.git
#   --llvm-branch  Checkout this branch after clone.
#   --llvm-commit  Checkout this exact commit after clone (wins over branch).
#   --with-agents  Also install claude-code + opencode (default: off).
#
# Assumptions: Ubuntu 22.04, ROCm already installed at /opt/rocm-*, sudo access.

set -euo pipefail

LLVM_REPO="git@github.com:RiverDave/llvm-project.git"
LLVM_BRANCH=""
LLVM_COMMIT=""
WITH_AGENTS=0
POLYBENCH_FORK="https://github.com/RiverDave/polybenchGpu"
POLYBENCH_AUDIT_FORK="https://github.com/RiverDave/polybench-gpu-audit.git"
POLYBENCH_RESULTS_FORK="git@github.com:RiverDave/polybench-results.git"
INTERCOMMS_FORK="git@github.com:RiverDave/intercomms.git"
JOBS="$(nproc)"
SKIP_BUILD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build)  SKIP_BUILD=1; shift ;;
        --jobs)        JOBS="$2";    shift 2 ;;
        --llvm-repo)   LLVM_REPO="$2";   shift 2 ;;
        --llvm-branch) LLVM_BRANCH="$2"; shift 2 ;;
        --llvm-commit) LLVM_COMMIT="$2"; shift 2 ;;
        --with-agents) WITH_AGENTS=1; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
LLVM_SRC="$HOME/llvm-project"
LLVM_BUILD="$LLVM_SRC/build"
BIN_DIR="$LLVM_BUILD/bin"
POLYBENCH_DIR="$HOME/polybenchGpu"
POLYBENCH_RESULTS_DIR="$HOME/polybench-results"
INTERCOMMS_DIR="$HOME/intercomms"
# ROCM_ROOT="$(ls -d /opt/rocm-[0-9]* 2>/dev/null | sort -V | tail -1)"
# ROCM_ROOT="${ROCM_ROOT:-/opt/rocm}"

echo "=== [0/6] Machine profile: AMD Devcloud ==="
echo "  LLVM source : ${LLVM_SRC}"
echo "  LLVM build  : ${LLVM_BUILD}"
echo "  Build bins  : ${BIN_DIR}"
# echo "  ROCm root   : ${ROCM_ROOT}"
echo "  PolyBench   : ${POLYBENCH_DIR}"
echo "  Results     : ${POLYBENCH_RESULTS_DIR}"
echo "  Intercomms  : ${INTERCOMMS_DIR}"

# ---------------------------------------------------------------------------
# 1. SSH key — generate if absent, always show public key
# ---------------------------------------------------------------------------
echo ""
echo "=== [1/6] SSH key ==="

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

ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

# Git identity — same as David's machine (matches run_polybench.py COMMIT_*).
git config --global user.name  "RiverDave"
git config --global user.email "davidriverg@gmail.com"

# ---------------------------------------------------------------------------
# 2. System packages
# ---------------------------------------------------------------------------
echo ""
echo "=== [2/6] System packages ==="
sudo apt-get update -q
sudo apt-get install -y \
    ninja-build \
    ccache \
    lld \
    clang \
    gcc-12 g++-12 \
    cmake \
    python3 python3-pip \
    git

# python3 -m pip install --quiet matplotlib

# ---------------------------------------------------------------------------
# 3. Clone repos
# ---------------------------------------------------------------------------
echo ""
echo "=== [3/6] Repos ==="

if [[ ! -d "$LLVM_SRC/.git" ]]; then
    echo "Cloning llvm-project from $LLVM_REPO"
    git clone "$LLVM_REPO" "$LLVM_SRC"
else
    echo "llvm-project: already present, skipping clone."
fi
if [[ -n "$LLVM_COMMIT" ]]; then
    git -C "$LLVM_SRC" checkout "$LLVM_COMMIT"
elif [[ -n "$LLVM_BRANCH" ]]; then
    git -C "$LLVM_SRC" checkout "$LLVM_BRANCH"
fi

if [[ ! -d "$HOME/polybench-gpu-audit/.git" ]]; then
    echo "Cloning polybench-gpu-audit…"
    git clone "$POLYBENCH_AUDIT_FORK" "$HOME/polybench-gpu-audit"
else
    echo "polybench-gpu-audit: already present, skipping clone."
fi

if [[ ! -d "$POLYBENCH_DIR/.git" ]]; then
    echo "Cloning polybenchGpu…"
    git clone "$POLYBENCH_FORK" "$POLYBENCH_DIR"
else
    echo "polybenchGpu: already present, skipping clone."
fi

if [[ ! -d "$POLYBENCH_RESULTS_DIR/.git" ]]; then
    echo "Cloning polybench-results…"
    git clone "$POLYBENCH_RESULTS_FORK" "$POLYBENCH_RESULTS_DIR"
else
    echo "polybench-results: already present, skipping clone."
fi

if [[ ! -d "$INTERCOMMS_DIR/.git" ]]; then
    echo "Cloning intercomms…"
    git clone "$INTERCOMMS_FORK" "$INTERCOMMS_DIR"
else
    echo "intercomms: already present, skipping clone."
fi

# ---------------------------------------------------------------------------
# 4. Configure LLVM
# ---------------------------------------------------------------------------
echo ""
echo "=== [4/6] CMake configure ==="

# NOTE: the LLVM/clang/MLIR dylib options must stay OFF. With them ON, clang
# ends up with two independent copies of LLVM (one statically linked into the
# clang binary, one in libLLVM.so). Each copy has its own cl::opt registry and
# its own LLVMContext, so most -mllvm options silently vanish — including
# -enable-memcpyopt-without-libcalls, which the CUDA driver injects into *every*
# device-side compile — and IRGen fails with "Attribute list does not match
# Module context!". Linking statically keeps a single copy. (MLIR's dylib flag
# must be turned off too, or the clang link fails with "unable to find -lMLIR"
# once the LLVM side goes static.)

mkdir -p "$LLVM_BUILD"

cmake -G Ninja \
    -S "$LLVM_SRC/llvm" \
    -B "$LLVM_BUILD" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCLANG_ENABLE_CIR=ON \
    -DLLVM_ENABLE_LLD=ON \
    -DLLVM_ENABLE_PROJECTS="clang;mlir;lld" \
    -DLLVM_TARGETS_TO_BUILD="X86;NVPTX;AMDGPU" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_USE_SPLIT_DWARF=ON \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DCLANG_LINK_CLANG_DYLIB=OFF \
    -DMLIR_BUILD_MLIR_DYLIB=OFF \
    -DMLIR_LINK_MLIR_DYLIB=OFF \
    -DLLVM_PARALLEL_LINK_JOBS=4 \
    -DLLVM_BUILD_TESTS=OFF \
    -DLLVM_BUILD_EXAMPLES=OFF \
    -DLLVM_ENABLE_RTTI=OFF \
    -DLLVM_ENABLE_EH=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# ---------------------------------------------------------------------------
# 5. Build
# ---------------------------------------------------------------------------
echo ""
if [[ "$SKIP_BUILD" -eq 1 ]]; then
    echo "=== [5/6] Skipping build (--skip-build) ==="
else
    echo "=== [5/6] Building (~20-40 min cold, fast with ccache) ==="

    # Phase 1: MLIR tablegen headers first. CIR files include MLIR builtin
    # headers but the cmake dependency graph is missing the edge, so at high
    # parallelism the build races the .inc generation.
    ninja -C "$LLVM_BUILD" mlir-headers -j"$JOBS"

    # Phase 2: clang + all HIP offload pipeline tools.
    # System lld (apt) is too old (v14) for AMDGPU ELF output — build ours.
    ninja -C "$LLVM_BUILD" -j"$JOBS" \
        clang \
        clang-linker-wrapper \
        lld \
        llvm-offload-binary \
        clang-offload-bundler \
        clang-offload-packager \
        llvm-objcopy

    echo ""
    echo "clang++ version:"
    "${BIN_DIR}/clang++" --version
fi

# ---------------------------------------------------------------------------
# 6. AI coding agents
# ---------------------------------------------------------------------------
echo ""
if [[ "$WITH_AGENTS" -eq 1 ]]; then
echo "=== [6/6] AI coding agents ==="

echo "Installing Claude Code…"
curl -fsSL https://claude.ai/install.sh | bash

echo "Installing opencode…"
curl -fsSL https://opencode.ai/install | bash
else
echo "=== [6/6] Skipping AI coding agents (use --with-agents to install) ==="
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "=== Setup complete ==="
echo ""
