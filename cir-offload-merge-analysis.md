# CIR Offload Merge Analysis
_Date: 2026-06-24 | ADI + PolyBench/GPU suite, sm_86_

---

## Gate Check: FAIL — merge output is incomplete

| Section / Symbol | no-merge | merge |
|---|---|---|
| `.nv_fatbin` (31 KB embedded fatbin) | ✅ | ❌ absent |
| `.nvFatBinSegment` | ✅ | ❌ |
| `__cudaRegisterFatBinary` / `__cudaRegisterFunction` | ✅ | ❌ |
| `__cuda_module_ctor` / `_dtor` | ✅ | ❌ |
| `.init_array` (module init hook) | ✅ | ❌ |

**Device code quality is correct**: ptxas reports identical register usage for all 6 ADI kernels on both arms (kernel1: 31 regs, kernel2: 16, kernel3: 23, kernel4: 21, kernel5: 16, kernel6: 17). PTX is compiled correctly in the merge path — but never embedded in the host object.

**Root cause**: The final host `cc1` in the merge pipeline runs with `-x cir` as input (not `-x cuda`). The CIR-to-obj codegen path does not trigger CUDA module registration code generation even though `-fcuda-include-gpubinary <fatbin>` is passed. That flag is only consumed by the source-to-obj path. The fatbin is created then discarded.

A binary linked from merge objects would silently skip all GPU kernel launches (or crash depending on how the runtime handles unregistered kernels).

---

## Wall-clock time (whole driver, warmup done)

| arm | `time` real |
|---|---|
| no-merge | 15.2s |
| merge | 1.75s |

Confirmed by `time` wrapping the full driver invocation, not just `-ftime-report`. The entire process tree is timed.

---

## Where does no-merge's time go?

`-ftime-report` accumulated across all cc1 invocations for ADI:

| cc1 invocation | Total | Frontend | Backend |
|---|---|---|---|
| no-merge: device cc1 (source → PTX) | 0.70s | 0.67s | 0.07s |
| **no-merge: host cc1 (source → obj)** | **14.09s** | **13.86s (98.8%)** | 0.23s |
| merge: host cc1 (source → CIR) | 0.69s | 0.69s | — |
| merge: device cc1 (source → CIR) | 0.68s | 0.68s | — |
| merge: device cc1 (CIR → PTX) | 0.23s | 0.05s | 0.18s |
| merge: host cc1 (CIR → obj) | 0.14s | — | 0.14s |

The bottleneck is entirely the host `cc1` frontend in no-merge. The 13.86s "Frontend" includes CIRGen (AST → CIR) + all CIR passes over the combined host+device module. The backend (LLVM passes, isel, regalloc) is essentially the same cost in both arms (~0.23s).

---

## Superlinear scaling — confirmed

| Benchmark | no-merge | merge | ratio |
|---|---|---|---|
| jacobi1D (simple, 2 kernels) | 1.89s | 1.57s | **1.2×** |
| 2mm (medium, 3 kernels) | 3.71s | 1.66s | **2.2×** |
| adi (complex, 6 kernels + heavy loop nests) | 15.2s | 1.75s | **8.7×** |

No-merge scaling: 1.9 → 3.7 → 15.2 (roughly quadratic). Merge is flat at ~1.6–1.8s across all three.

The flat merge line confirms this isn't a property of benchmark complexity — the no-merge host cc1 is doing something O(n²) or worse over the combined module size.

---

## Driver subprocess sequence (both arms)

**no-merge:**
```
cc1 (nvptx64, source → PTX)   →  ptxas  →  fatbinary  →  cc1 (x86_64, source → obj, -fcuda-include-gpubinary)
```

**merge:**
```
cc1 (x86_64, source → host.cir)
cc1 (nvptx64, source → dev.cir)
  → cir-offload-merge -combine  → container.cir
  → cir-offload-merge -split    → host.cir + dev.cir
  → cc1 (nvptx64, dev.cir → PTX)  →  ptxas  →  fatbinary
  → cc1 (x86_64, host.cir → obj, -fcuda-include-gpubinary)   ← bug: stubs not generated here
```

---

## What needs to happen

1. **Correctness bug is blocking.** The merge pipeline must generate CUDA module registration stubs in the final host CIR→obj step. Options:
   - Store registration-site data in the host CIR during `emit-cir` so the CIR→obj backend can emit stubs.
   - Have the CIR→obj backend synthesize stubs when it sees `-fcuda-include-gpubinary` (the fatbin path is already passed correctly).
   Until fixed, timing comparisons are against an incomplete compile.

2. **Superlinear behavior is real but imprecisely located.** `-ftime-report` lumps CIRGen + all CIR passes into "Frontend." To pinpoint the specific pass, need `--mlir-pass-statistics` output from the no-merge host `cc1` specifically (device cc1 is fast). Prime suspect: a CIR pass that walks the combined host+device module before the split point — candidates are CIR verifier, CIRToLLVMLowering over a fat module, or any pass that iterates function pairs. Prove it with the pass name and the scaling curve across all three benchmarks.

---

## Full suite results (prior run, 21/21 benchmarks, -j1, 3 warmups)

From `~/polybench-gpu-audit/temp/offload-merge/offload_merge_summary.md`.
Note: these were measured before the gate check — merge arm was producing incomplete objects.

| Phase | no-merge avg | merge avg | delta |
|---|---:|---:|---:|
| Frontend+IRGen | 4.197s | 1.553s | -2.645s |
| LLVM-passes | 0.139s | 0.135s | -0.005s |
| ISel | 0.019s | 0.019s | 0.000s |
| **Total (wall)** | **4.254s** | **1.660s** | **-2.594s** |

Overall reported 2.6× average speedup; ADI showed 8.2×. Both figures are against an incomplete merge output — true speedup after the correctness fix will differ.
