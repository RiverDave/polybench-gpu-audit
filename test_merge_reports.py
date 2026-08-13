#!/usr/bin/env python3
"""Synthetic test: dynamic pipeline labels in run_compile/run_runtime reports."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from run_compile import TimingResult, _phase_rows, _arch_section, markdown as compile_markdown
from run_runtime import PerfResult, markdown as runtime_markdown

def fake_prov():
    return {"hostname": "test", "cpu_count": "8", "gpu": "?", "cpu": "", "kernel": "",
            "rocm_version": "", "cuda_version": "", "driver_version": "",
            "ptxas_version": "", "os_release": "", "timestamp_utc": "x"}
import run_compile, run_runtime
run_compile.provenance = fake_prov
run_runtime.provenance = fake_prov

def t(bench, pipeline, ok=True, elapsed=1.0, phases=None):
    return TimingResult(benchmark=bench, source_set="CUDA", file=Path(f"/pb/{bench}.cu"),
                        pipeline=pipeline, arch="sm_86", ok=ok, elapsed=elapsed,
                        elapsed_stddev=0.05, elapsed_median=elapsed, elapsed_samples=[elapsed],
                        samples=1, phases=phases or {"Frontend+IRGen": 0.5, "MLIR-passes": 0.1},
                        log=Path("/tmp/x.log"), command=["clang"], first_error="")

# --- run_compile: merge mode report ---
res = [t("adi", "CIR", elapsed=2.0, phases={"Frontend+IRGen": 0.8, "MLIR-passes": 0.3}),
       t("adi", "CIR-merge", elapsed=2.5, phases={"Frontend+IRGen": 0.9, "MLIR-passes": 0.7}),
       t("gemm", "CIR", elapsed=1.0, phases={"Frontend+IRGen": 0.4}),
       t("gemm", "CIR-merge", elapsed=1.4, phases={"Frontend+IRGen": 0.5, "MLIR-passes": 0.6})]

rows = _phase_rows(res, "CIR", "CIR-merge")
assert rows[0] == "| Phase | CIR avg | CIR-merge avg | delta |", rows[0]
assert any("MLIR-passes" in r and "0.65" in r for r in rows), rows  # (0.7+0.6)/2
assert any("Total (wall)" in r for r in rows), rows

sec = _arch_section(res, Path("/pb"), "sm_86", "CIR", "CIR-merge")
assert any("CIR compiled OK: `2/2`" in l for l in sec), sec
assert any("CIR-merge/CIR |" in l for l in sec) or any("| CIR-merge/CIR |" in l for l in sec), sec

md = compile_markdown(res, Path("/pb"), "cuda:sm_86", Path("/tmp"), 1, 1,
                      pipelines=("CIR", "CIR-merge"))
assert "PolyBench compile-phase timing: CIR vs CIR-merge." in md, md[:200]
assert "merge arm adds `--clangir-offload-merge`" in md, md[:400]

# --- run_compile: default CIR vs OG still works ---
md2 = compile_markdown(res, Path("/pb"), "cuda:sm_86", Path("/tmp"), 1, 1)
assert "PolyBench compile-phase timing: CIR vs OG." in md2

# --- run_runtime: merge mode report ---
def p(bench, pipeline, times, wall_times, size=1000):
    return PerfResult(benchmark=bench, source_set="CUDA", file=Path(f"/pb/{bench}.cu"),
                      pipeline=pipeline, arch="sm_86", compile_ok=True, compile_log=Path("/tmp/l"),
                      binary=Path("/tmp/b"), size=size, times=times, wall_times=wall_times)

rt = [p("adi", "CIR", [0.010, 0.011], [0.020, 0.021]),
      p("adi", "CIR-merge", [0.010, 0.010], [0.019, 0.020])]
rmd = runtime_markdown(rt, Path("/pb"), "sm_86", Path("/tmp"), 2, 1,
                       pipelines=("CIR", "CIR-merge"))
assert "PolyBench runtime performance: CIR vs CIR-merge." in rmd
assert "GPU CIR-merge/CIR" in rmd, rmd[:600]
assert "**Total GPU CIR-merge/CIR (geomean):**" in rmd
assert "| CIR wall | CIR GPU | CIR host | CIR-merge wall | CIR-merge GPU | CIR-merge host | GPU CIR-merge/CIR | CIR size | CIR-merge size |" in rmd

print("report-label tests: ALL OK")
