# Rebuild & Run Guide (RunPod MI300X)

How to rebuild ClangIR from scratch and run the PolyBench CIR audit on a fresh
RunPod pod with an MI300X GPU.

## Pod requirements

- GPU: MI300X (gfx942)
- Container disk: ≥ 41 GB
- Network volume at `/workspace`: ≥ 20 GB (stores stripped binaries ~13 GB)
- OS: Ubuntu 22.04

## 1. Install ROCm 6.3

ROCm 6.3 is required — clang-23 needs `oclc_abi_version_600.bc` which ROCm 5.x
does not ship.

```bash
sudo apt-get update
sudo apt-get install -y rocm-dev rocm-libs hip-dev
# verify
ls /opt/rocm-6.3.0/amdgcn/bitcode/oclc_abi_version_600.bc
```

If the package manager installs a different minor version, adjust `--hip-path`
and `--og-clang` paths in step 4 accordingly.

## 2. Clone repos (if not already present)

```bash
cd ~
git clone https://github.com/RiverDave/polybench-gpu-audit
git clone https://github.com/RiverDave/polybenchGpu
# LLVM with ClangIR (already cloned at ~/llvm-project on the branch you want)
```

## 3. Build ClangIR

The build uses `/dev/shm` for speed (RAM-backed FS) but `/workspace/llvm-bin`
for binaries (exec-capable NFS). `/dev/shm` is mounted `noexec` so binaries
can't run from there directly; the symlink trick below works around that.

```bash
bash ~/polybench-gpu-audit/build_llvm.sh
```

`build_llvm.sh` lives in this repo (copy of `~/build_llvm.sh`).  
After the build finishes, strip debug symbols to stay under the disk quota:

```bash
find /workspace/llvm-bin -type f -exec file {} + \
  | grep ELF | cut -d: -f1 \
  | xargs strip --strip-debug
# should land around 13 GB total
du -sh /workspace/llvm-bin
```

### Resource-dir symlink (required for HIP)

clang-23 resolves its resource dir relative to its own binary path.  
Binaries are at `/workspace/llvm-bin/`, so it looks for
`/workspace/lib/clang/23/`.  The actual files are in the build tree:

```bash
mkdir -p /workspace/lib/clang
ln -sfn /dev/shm/llvm-build/lib/clang/23 /workspace/lib/clang/23
```

Without this symlink HIP compilation fails with
`__clang_hip_runtime_wrapper.h not found`.

## 4. Run the audit

```bash
cd ~/polybench-gpu-audit
mkdir -p logs/cir-rocm

python3 run_polybench_cir.py \
  --clang          /workspace/llvm-bin/clang \
  --og-clang       /opt/rocm-6.3.0/llvm/bin/clang \
  --polybench-root ~/polybenchGpu \
  --hip-path       /opt/rocm-6.3.0 \
  --gcc-install-dir /usr/lib/gcc/x86_64-linux-gnu/11 \
  --hip-arch       gfx942 \
  --log-dir        ~/polybench-gpu-audit/logs/cir-rocm \
  -j 4
```

The script compiles every `.hip.cpp` file twice — once with `-fclangir` (CIR
pipeline) and once with the ROCm-native clang (OG baseline) — and writes a
Markdown summary to `logs/cir-rocm/summary.md`.

### Why two different clangs?

`clang-linker-wrapper` from the ClangIR build has a static-init
double-registration bug that crashes even on `--version`. The CIR pipeline only
needs the frontend (it stops at `-emit-obj` before device linking), so we use
clang-23 for CIR. The OG baseline uses the ROCm-native clang which has a
working linker-wrapper.

## 5. Known issues / workarounds already in the script

| Issue | Workaround |
|---|---|
| `__AMDGCN_WAVEFRONT_SIZE` removed in clang-23 | `-D__AMDGCN_WAVEFRONT_SIZE=64` added to CIR flags |
| `.cuh` headers only in `CUDA/` subtree | script adds the mirrored `CUDA/<BENCH>` dir as `-I` for HIP files |
| `clang-linker-wrapper` crashes (double-registration) | OG pipeline uses ROCm clang; CIR pipeline uses clang-23 |
| `-v` flag triggers linker-wrapper for HIP | `-v` only passed for CUDA files |

## 6. Current CIR result (as of this session)

- OG: **21/21** pass
- CIR: **0/21** fail — all fail with the same verifier error (see below)

## 7. Known CIR bug: addrspace cast missing after array-to-pointer decay

All 21 CIR failures share one root cause. See `repro.cpp` in this repo.

**Minimal reproducer** (`repro.cpp`):

```cpp
void foo() {
    const char fmt[] = "hello";   // stack array → AMDGPU private addrspace(5)
    const char *tmp = fmt;        // decay must cast addrspace(5) → generic
    while (*tmp++);
}
```

**Command that triggers it**:

```bash
/workspace/llvm-bin/clang -cc1 \
  -triple amdgcn-amd-amdhsa -target-cpu gfx942 \
  -fclangir -std=c++17 -O0 -emit-obj -x c++ repro.cpp -o /dev/null
```

**Error**:
```
error: 'cir.cast' op result type address space does not match the address space of the operand
fatal error: CIR module verification error before running CIR-to-CIR passes
```

**Root cause**: `CK_ArrayToPointerDecay` on an AMDGPU stack array preserves
`addrspace(5)` in the CIR result type. Storing that into a generic (`addrspace 0`)
pointer variable causes `createStore` to emit a `bitcast` that changes the outer
pointer's address space, which the verifier correctly rejects. OG inserts an
`addrspacecast addrspace(5) → flat` immediately after the alloca; CIR does not.
