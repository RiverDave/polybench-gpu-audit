#!/usr/bin/env bash
# One-shot VM setup for ClangIR / PolyBench-GPU development.
#
# Usage:
#   bash setup.sh [--runpod | --lambda] [--skip-build] [--jobs N]
#
#   --runpod      Target RunPod instance.
#                 Source + build tree on /dev/shm (RAM) for speed; executables
#                 symlinked to /workspace (exec-capable persistent volume)
#                 during the build, then copied to /opt (local overlay) for
#                 fast benchmark runs — avoids the FUSE network penalty on
#                 every clang subprocess.
#   --lambda      Target Lambda Labs GPU  (paths rooted at $HOME)  [default]
#
# Assumptions: Ubuntu 22.04, ROCm already installed at /opt/rocm-*, sudo access.

set -euo pipefail

LLVM_FORK="https://github.com/RiverDave/llvm-project"
POLYBENCH_FORK="https://github.com/RiverDave/polybenchGpu"
JOBS="$(nproc)"
SKIP_BUILD=0
MACHINE="lambda"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --runpod)     MACHINE="runpod"; shift ;;
        --lambda)     MACHINE="lambda"; shift ;;
        --skip-build) SKIP_BUILD=1;     shift ;;
        --jobs)       JOBS="$2";        shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Paths — vary by machine
# ---------------------------------------------------------------------------
if [[ "$MACHINE" == "runpod" ]]; then
    # Build in RAM (/dev/shm) — fast I/O, but noexec. bin/ and lib/ are
    # symlinked into /workspace during the build so tblgen and the linker
    # can execute/dlopen them. After the build they are copied to /opt
    # (local overlay, exec-capable) so benchmark runs don't pay the FUSE
    # network cost on every clang invocation.
    LLVM_SRC="/dev/shm/llvm-project"
    LLVM_BUILD="/dev/shm/llvm-build"
    BIN_DIR="/workspace/llvm-bin"       # build-time exec target (FUSE)
    POLYBENCH_DIR="/workspace/polybenchGpu"
    OPT_BIN="/opt/llvm-bin"            # run-time clang location (local disk)
    OPT_LIB="/opt/llvm-lib"
    ROCM_ROOT="$(ls -d /opt/rocm-[0-9]* 2>/dev/null | sort -V | tail -1)"
    ROCM_ROOT="${ROCM_ROOT:-/opt/rocm}"
else
    LLVM_SRC="$HOME/llvm-project"
    LLVM_BUILD="$LLVM_SRC/build"
    BIN_DIR="$LLVM_BUILD/bin"
    POLYBENCH_DIR="$HOME/polybenchGpu"
    OPT_BIN="$BIN_DIR"
    OPT_LIB=""
fi

echo "=== [0/6] Machine profile: ${MACHINE} ==="
echo "  LLVM source : ${LLVM_SRC}"
echo "  LLVM build  : ${LLVM_BUILD}"
echo "  Build bins  : ${BIN_DIR}"
if [[ "$MACHINE" == "runpod" ]]; then
    echo "  Run bins    : ${OPT_BIN}  (local overlay — faster than FUSE)"
    echo "  ROCm root   : ${ROCM_ROOT}"
fi
echo "  PolyBench   : ${POLYBENCH_DIR}"

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
    gcc-11 g++-11 \
    cmake \
    python3 python3-pip \
    git

python3 -m pip install --quiet matplotlib

# ---------------------------------------------------------------------------
# 3. Clone repos
# ---------------------------------------------------------------------------
echo ""
echo "=== [3/6] Repos ==="

if [[ ! -d "$LLVM_SRC/.git" ]]; then
    echo "Cloning llvm-project fork (shallow)…"
    git clone --depth=1 --branch users/riverdave/cir/hip-offload-merge "$LLVM_FORK" "$LLVM_SRC"
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
# 4. Configure LLVM
# ---------------------------------------------------------------------------
echo ""
echo "=== [4/6] CMake configure ==="

mkdir -p "$LLVM_BUILD"

# RunPod: /dev/shm is noexec — executables and shared libs cannot be run or
# dlopen'd from there. Pre-symlink bin/, lib/, and NATIVE/bin/ into /workspace
# before cmake so the build system automatically places everything exec-able
# on the persistent volume. The linker replaces lib/ symlinks with real files
# on each link step, but the pre-symlink means new files land in /workspace
# from the start rather than in /dev/shm.
if [[ "$MACHINE" == "runpod" ]]; then
    mkdir -p "$BIN_DIR" "/workspace/llvm-lib" "/workspace/llvm-bin-native"
    # /workspace/lib → /workspace/llvm-lib lets clang resolve its resource
    # dir as ../lib/clang/<ver> relative to /workspace/llvm-bin/clang++.
    [[ ! -e /workspace/lib ]] && ln -s /workspace/llvm-lib /workspace/lib
    [[ ! -L "$LLVM_BUILD/bin" ]]         && ln -s "$BIN_DIR"                  "$LLVM_BUILD/bin"
    [[ ! -L "$LLVM_BUILD/lib" ]]         && ln -s "/workspace/llvm-lib"        "$LLVM_BUILD/lib"
    mkdir -p "$LLVM_BUILD/NATIVE"
    [[ ! -L "$LLVM_BUILD/NATIVE/bin" ]] && ln -s "/workspace/llvm-bin-native" "$LLVM_BUILD/NATIVE/bin"
fi

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
    -DLLVM_TARGETS_TO_BUILD="X86;NVPTX$([[ "$MACHINE" == "runpod" ]] && echo ";AMDGPU")" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_USE_SPLIT_DWARF=ON \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
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
        cir-offload-merge \
        lld \
        llvm-offload-binary \
        clang-offload-bundler \
        clang-offload-packager \
        llvm-objcopy

    echo ""
    echo "clang++ version:"
    "${BIN_DIR}/clang++" --version

    # -----------------------------------------------------------------------
    # RunPod: copy bins + libs from /workspace (FUSE, slow) to /opt (local
    # overlay, fast). Every benchmark invocation spawns a clang subprocess;
    # loading the binary and shared libs over FUSE adds ~1-2 s per call.
    # -----------------------------------------------------------------------
    if [[ "$MACHINE" == "runpod" ]]; then
        echo ""
        echo "Copying bins + libs to /opt for fast local-disk execution…"
        cp -a "$BIN_DIR"           "$OPT_BIN"
        cp -a /workspace/llvm-lib  "$OPT_LIB"
        # /opt/lib → /opt/llvm-lib so clang resolves ../lib/clang/<ver>
        ln -sf "$OPT_LIB" /opt/lib
        echo "  ${OPT_BIN}/clang++ → $(${OPT_BIN}/clang++ --version | head -1)"
    fi
fi

# ---------------------------------------------------------------------------
# 6. Claude Code
# ---------------------------------------------------------------------------
echo ""
echo "=== [6/6] Claude Code ==="
curl -fsSL https://claude.ai/install.sh | bash

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "=== Setup complete ==="
echo ""

if [[ "$MACHINE" == "runpod" ]]; then
    ROCM_BITCODE="${ROCM_ROOT}/amdgcn/bitcode"
    cat <<EOF
Run benchmarks (HIP / gfx942):
  export LD_LIBRARY_PATH=${OPT_LIB}

  # Single-arch compile-time comparison (no-merge vs merge):
  python3 run_cir_offload_merge.py --hip \\
      --clang ${OPT_BIN}/clang++ \\
      --polybench-root ${POLYBENCH_DIR} \\
      --hip-path ${ROCM_ROOT} \\
      --rocm-device-lib-path ${ROCM_BITCODE} \\
      --hip-arch gfx942 \\
      -j \$(nproc)

  # Multi-arch scaling (gfx906 → gfx908 → gfx90a → gfx942) + plot:
  python3 measure_multiarch_scaling.py --hip \\
      --clang ${OPT_BIN}/clang++ \\
      --polybench-root ${POLYBENCH_DIR} \\
      --hip-path ${ROCM_ROOT} \\
      --rocm-device-lib ${ROCM_BITCODE} \\
      --warmup 3 -j \$(nproc) \\
      --plot --plot-out multiarch_scaling.png \\
      --out multiarch_scaling.json

  # Step-by-step pipeline overhead for a single benchmark:
  python3 measure_merge_overhead.py \\
      --bench ${POLYBENCH_DIR}/HIP/2DCONV/2DConvolution.hip.cpp

Rebuild after changes:
  ninja -C ${LLVM_BUILD} clang cir-offload-merge llvm-offload-binary clang-offload-bundler clang-offload-packager llvm-objcopy -j\$(nproc)
  cp -a ${BIN_DIR}/. ${OPT_BIN}/
EOF
else
    cat <<EOF
Run benchmarks (HIP / gfx942):
  python3 run_cir_offload_merge.py --hip \\
      --clang ${BIN_DIR}/clang++ \\
      --polybench-root ${POLYBENCH_DIR} \\
      --hip-path /opt/rocm \\
      --rocm-device-lib-path /opt/rocm/amdgcn/bitcode \\
      --hip-arch gfx942 \\
      -j \$(nproc)

  # Multi-arch scaling + plot:
  python3 measure_multiarch_scaling.py --hip \\
      --clang ${BIN_DIR}/clang++ \\
      --polybench-root ${POLYBENCH_DIR} \\
      --hip-path /opt/rocm \\
      --rocm-device-lib /opt/rocm/amdgcn/bitcode \\
      --warmup 3 -j \$(nproc) --plot

Rebuild:
  ninja -C ${LLVM_BUILD} clang cir-offload-merge -j\$(nproc)
EOF
fi
