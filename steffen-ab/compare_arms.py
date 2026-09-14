#!/usr/bin/env python3
"""Compare two PolyBench runtime arms (temp-A = control, temp-B = treatment).

Reads the harness's own `runtime_results.json` from each arm's log dirs, so the
numbers are exactly what run_polybench.py produced (median per benchmark x
pipeline, plus geomean of the ratios). No re-timing, no re-parsing of stdout.

Usage: compare_arms.py [A_dir] [B_dir]   (defaults: temp-A temp-B)
"""
import json
import statistics
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HARNESS = HERE.parent


def load(arm_dir: Path):
    """{benchmark: {pipeline: {'median': s, 'runs': n, 'ok': bool, 'validation': str}}}"""
    out = {}
    for res in sorted(arm_dir.glob("*/runtime_results.json")):
        data = json.loads(res.read_text())
        for r in data["results"]:
            b = r["benchmark"]
            p = r["pipeline"]
            times = [t for t in r["times"] if t is not None]
            out.setdefault(b, {})[p] = {
                "median": statistics.median(times) if times else None,
                "runs": len(times),
                "ok": bool(r["compile_ok"]),
                "validation": r.get("validation_status") or "",
                "commit": data.get("clangir_commit", "")[:12],
                "merge": data.get("merge"),
            }
    return out


def geomean(xs):
    xs = [x for x in xs if x and x > 0]
    if not xs:
        return None
    prod = 1.0
    for x in xs:
        prod *= x
    return prod ** (1.0 / len(xs))


def main():
    a_dir = Path(sys.argv[1] if len(sys.argv) > 1 else HARNESS / "temp-A")
    b_dir = Path(sys.argv[2] if len(sys.argv) > 2 else HARNESS / "temp-B")
    A, B = load(a_dir), load(b_dir)
    if not A or not B:
        print(f"missing results: {a_dir} -> {len(A)} benches, {b_dir} -> {len(B)} benches")
        return 1

    commits = {v["commit"] for b in A.values() for v in b.values()}
    commits_b = {v["commit"] for b in B.values() for v in b.values()}
    print(f"arm A (control)  : {sorted(commits)}")
    print(f"arm B (treatment): {sorted(commits_b)}\n")

    pipelines = sorted({p for b in B.values() for p in b} | {p for b in A.values() for p in b})
    rows = []
    for bench in sorted(set(A) & set(B)):
        for pipe in pipelines:
            ra, rb = A[bench].get(pipe), B[bench].get(pipe)
            if not ra or not rb or ra["median"] is None or rb["median"] is None:
                continue
            ratio = ra["median"] / rb["median"]  # >1 = B faster
            rows.append((bench, pipe, ra["median"], rb["median"], ratio,
                         ra["ok"], rb["ok"], ra["validation"], rb["validation"]))

    print(f"{'benchmark':12} {'pipeline':22} {'A med (s)':>10} {'B med (s)':>10} "
          f"{'A/B':>7}  notes")
    for bench, pipe, ma, mb, ratio, oka, okb, va, vb in rows:
        notes = []
        if not (oka and okb):
            notes.append(f"compile A={oka} B={okb}")
        if va not in ("", "pass") or vb not in ("", "pass"):
            notes.append(f"validate A={va} B={vb}")
        print(f"{bench:12} {pipe:22} {ma:10.4f} {mb:10.4f} {ratio:7.3f}  "
              f"{'; '.join(notes)}")

    for pipe in pipelines:
        gm = geomean([r[4] for r in rows if r[1] == pipe])
        n = len([r for r in rows if r[1] == pipe])
        if gm:
            print(f"\ngeomean A/B over {n} benchmarks, pipeline {pipe}: {gm:.4f}")

    out = HERE / "AB-report.md"
    lines = ["# Steffen staging branch vs fork trunk — PolyBench runtime A/B", "",
             f"- arm A (control): `{sorted(commits)}`", f"- arm B (treatment): `{sorted(commits_b)}`",
             f"- ratio = A_median / B_median (>1 means the treatment is faster)", "",
             "| benchmark | pipeline | A median (s) | B median (s) | A/B | notes |",
             "|---|---|---|---|---|---|"]
    for bench, pipe, ma, mb, ratio, oka, okb, va, vb in rows:
        notes = "; ".join([f"compile A={oka} B={okb}"] if not (oka and okb) else [] +
                          ([f"validate A={va} B={vb}"] if (va not in ("", "pass") or vb not in ("", "pass")) else []))
        lines.append(f"| {bench} | {pipe} | {ma:.4f} | {mb:.4f} | {ratio:.3f} | {notes} |")
    for pipe in pipelines:
        gm = geomean([r[4] for r in rows if r[1] == pipe])
        if gm:
            lines += ["", f"**geomean A/B ({pipe}):** `{gm:.4f}`"]
    out.write_text("\n".join(lines) + "\n")
    print(f"\nwrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())