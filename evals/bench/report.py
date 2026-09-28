#!/usr/bin/env python3
"""Summarise a results directory: quality and cost per arm, with honest error bars.

Statistics, chosen for small paired samples:
  * Every case weighs the same (means of per-case means), so one long case
    can't dominate.
  * Cost-like metrics (USD, context tokens, calls, wall time) compare as a
    ratio of geometric means, paired by case. 0.80 means the arm used 20% less.
  * Quality compares as a difference (pass rate, score), paired by case.
  * 95% intervals come from a bootstrap that resamples trials within each
    case, so they reflect run-to-run noise. If an interval straddles 1.0 (ratio)
    or 0 (difference), the data can't tell the arms apart yet.
  * Pass rates also get a Wilson interval, and pass^k is the share of cases
    where every trial passed (consistency, not luck).

  python evals/bench/report.py evals/results/<timestamp>
"""

import glob
import json
import math
import os
import random
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import load_json, save_json  # noqa: E402

BOOT = 2000
COST_METRICS = [  # (key, label)
    ("cost_usd", "cost $"),
    ("context", "context tokens"),
    ("output", "output tokens"),
    ("calls", "API calls"),
    ("wall_s", "wall s"),
]
QUALITY_METRICS = [("pass", "pass rate"), ("score", "check score")]
INFO_METRICS = [
    ("structure", "structure score"), ("overhang", "sloped overhang mm2"),
    ("asserts", "asserts"), ("openscad_calls", "openscad calls"),
    ("images", "images viewed"), ("sub_share", "sub-agent share of context"),
    ("skill_kb", "skill KB read"), ("thinking", "thinking tokens"),
    ("out_share", "output+thinking share of cost (approx)"),
]


def flatten(r):
    m, g = r.get("metrics") or {}, r.get("grade") or {}
    q, t = g.get("quality") or {}, m.get("tokens") or {}
    return {
        "pass": 1.0 if g.get("pass") else 0.0, "score": g.get("score", 0.0),
        "cost_usd": m.get("cost_usd"), "context": t.get("context_volume"), "output": t.get("output"),
        "calls": m.get("api_calls"), "wall_s": r.get("wall_s"),
        "structure": q.get("structure_score"), "overhang": q.get("overhang_45_sloped_mm2"),
        "asserts": q.get("asserts"), "openscad_calls": m.get("openscad_calls"),
        "images": m.get("image_reads"), "sub_share": m.get("subagent_share_of_context"),
        "skill_kb": (m.get("skill_read_bytes") or 0) / 1024.0,
        "out_share": (m.get("cost_split") or {}).get("output"),
        "thinking": t.get("thinking"),
    }


def load_runs(out):
    runs = []
    for p in glob.glob(os.path.join(out, "runs", "*", "*", "t*", "run.json")):
        r = load_json(p)
        if r and not r.get("skipped"):
            r["_flat"] = flatten(r)
            runs.append(r)
    return runs


def gmean(xs):
    xs = [x for x in xs if x is not None and x > 0]
    return math.exp(sum(math.log(x) for x in xs) / len(xs)) if xs else None


def mean(xs):
    xs = [x for x in xs if x is not None]
    return sum(xs) / len(xs) if xs else None


def wilson(k, n, z=1.96):
    if n == 0:
        return (None, None)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (max(0.0, c - h), min(1.0, c + h))


def by_case(runs, arm, key):
    out = {}
    for r in runs:
        if r["arm"] == arm:
            out.setdefault(r["case"], []).append(r["_flat"].get(key))
    return out


def paired(runs, base, cand, key, ratio, rng):
    """Point estimate + bootstrap CI of cand vs base over shared cases."""
    b, c = by_case(runs, base, key), by_case(runs, cand, key)
    shared = [k for k in b if k in c]
    agg = gmean if ratio else mean

    def stat(bs, cs):
        vals = []
        for k in shared:
            x, y = agg(bs[k]), agg(cs[k])
            if x is None or y is None:
                continue
            vals.append(math.log(y / x) if ratio else y - x)
        if not vals:
            return None
        v = sum(vals) / len(vals)
        return math.exp(v) if ratio else v

    point = stat(b, c)
    if point is None:
        return None, None, None
    boots = []
    for _ in range(BOOT):
        bs = {k: [rng.choice(b[k]) for _ in b[k]] for k in shared}
        cs = {k: [rng.choice(c[k]) for _ in c[k]] for k in shared}
        s = stat(bs, cs)
        if s is not None:
            boots.append(s)
    boots.sort()
    lo = boots[int(0.025 * len(boots))] if boots else None
    hi = boots[int(0.975 * len(boots)) - 1] if boots else None
    return point, lo, hi


def fmt(v, digits=2):
    if v is None:
        return "-"
    if isinstance(v, float) and abs(v) >= 1000:
        return "{:,.0f}".format(v)
    return ("%." + str(digits) + "f") % v if isinstance(v, float) else str(v)


def build(out):
    rng = random.Random(1234)
    runs = load_runs(out)
    suite = load_json(os.path.join(out, "suite.json"), {})
    arms = [a["name"] for a in suite.get("arms", [])] or sorted({r["arm"] for r in runs})
    arms = [a for a in arms if any(r["arm"] == a for r in runs)]
    cases = sorted({r["case"] for r in runs})
    L = ["# Skill bench report", ""]
    if suite:
        L.append("Claude Code %s · OpenSCAD %s · model %s · effort %s · %s trial(s)/case" % (
            suite.get("claude_version"), suite.get("openscad"), suite.get("model") or "default",
            suite.get("effort") or "default", suite.get("trials")))
        for a in suite.get("arms", []):
            fp = a.get("footprint") or {}
            L.append("- **%s** = `%s` %s%s%s" % (
                a["name"], a["ref"], a.get("sha") or "", " @" + a["model"] if a.get("model") else "",
                "  (static: always-on %s, typical run %s tokens)" % (
                    fp.get("always_on"), (fp.get("profiles") or {}).get("typical_run_petg_bambu"))
                if fp else ""))
        L.append("")
    if not runs:
        L.append("No finished runs.")
        return "\n".join(L)

    # ---- per-arm summary ----
    L += ["## Per arm (each case weighted equally)", "",
          "| metric | " + " | ".join(arms) + " |", "|---|" + "---:|" * len(arms)]
    summary = {"arms": {}, "cases": cases}
    for a in arms:
        per = {}
        for key, _ in COST_METRICS + QUALITY_METRICS + INFO_METRICS:
            vals = [mean(v) for v in by_case(runs, a, key).values()]
            per[key] = mean(vals)
        rs = [r for r in runs if r["arm"] == a]
        k = sum(1 for r in rs if r["grade"].get("pass"))
        per["pass_n"], per["runs"] = k, len(rs)
        per["pass_ci"] = wilson(k, len(rs))
        cs = by_case(runs, a, "pass")
        per["pass_hat_k"] = mean([1.0 if all(v == 1.0 for v in vs) else 0.0 for vs in cs.values()])
        per["total_cost"] = sum(r["_flat"]["cost_usd"] or 0 for r in rs)
        summary["arms"][a] = per
    rows = [("pass rate (Wilson 95%)", lambda p: "%s [%s-%s] (%d/%d)" % (
        fmt(p["pass"]), fmt(p["pass_ci"][0]), fmt(p["pass_ci"][1]), p["pass_n"], p["runs"])),
        ("pass^k (all trials pass)", lambda p: fmt(p["pass_hat_k"]))]
    rows += [(lbl, (lambda key: lambda p: fmt(p[key]))(key))
             for key, lbl in QUALITY_METRICS[1:] + COST_METRICS + INFO_METRICS]
    rows.append(("total spend $", lambda p: fmt(p["total_cost"])))
    for lbl, f in rows:
        L.append("| %s | %s |" % (lbl, " | ".join(f(summary["arms"][a]) for a in arms)))
    L.append("")

    # ---- paired comparison against the first arm ----
    if len(arms) > 1:
        base = arms[0]
        L += ["## Compared with `%s` (paired by case, bootstrap 95%% CI)" % base, "",
              "| arm | metric | estimate | 95% CI | reading |", "|---|---|---:|---|---|"]
        summary["paired"] = {}
        for cand in arms[1:]:
            for key, lbl in QUALITY_METRICS + COST_METRICS:
                ratio = key not in ("pass", "score")
                p, lo, hi = paired(runs, base, cand, key, ratio, rng)
                if p is None:
                    continue
                if ratio:
                    read = ("lower" if hi < 1 else "higher" if lo > 1 else "no clear difference")
                    est, ci = "x%.2f" % p, "x%.2f - x%.2f" % (lo, hi)
                else:
                    read = ("better" if lo > 0 else "worse" if hi < 0 else "no clear difference")
                    est, ci = "%+.2f" % p, "%+.2f to %+.2f" % (lo, hi)
                L.append("| %s | %s | %s | %s | %s |" % (cand, lbl, est, ci, read))
                summary["paired"]["%s:%s" % (cand, key)] = {"estimate": p, "lo": lo, "hi": hi}
        L.append("")

    judge = load_json(os.path.join(out, "judge.json"))
    if judge:
        L += ["## Pairwise judge (%s)" % judge.get("judge_model"), "",
              "| case | %s wins | %s wins | ties / inconsistent |" % (judge["a"], judge["b"]),
              "|---|---:|---:|---:|"]
        for case, v in sorted(judge["cases"].items()):
            L.append("| %s | %d | %d | %d |" % (case, v["a"], v["b"], v["tie"]))
        tot = judge["totals"]
        L += ["| **all** | %d | %d | %d |" % (tot["a"], tot["b"], tot["tie"]), ""]
        summary["judge"] = tot

    # ---- per case ----
    L += ["## Per case", "", "| case | arm | pass | score | median $ | median context | calls | "
          "wall s | failing checks |", "|---|---|---:|---:|---:|---:|---:|---:|---|"]
    for case in cases:
        for a in arms:
            rs = [r for r in runs if r["case"] == case and r["arm"] == a]
            if not rs:
                continue
            fails = {}
            for r in rs:
                for ch in r["grade"]["checks"]:
                    if not ch["ok"]:
                        fails[ch["id"]] = fails.get(ch["id"], 0) + 1
            med = lambda key: statistics.median([r["_flat"][key] for r in rs if r["_flat"][key] is not None] or [0])  # noqa: E731
            L.append("| %s | %s | %d/%d | %.2f | %s | %s | %s | %s | %s |" % (
                case, a, sum(1 for r in rs if r["grade"]["pass"]), len(rs),
                mean([r["_flat"]["score"] for r in rs]), fmt(float(med("cost_usd"))),
                fmt(float(med("context")), 0), fmt(med("calls"), 0), fmt(float(med("wall_s")), 0),
                ", ".join("%s x%d" % kv for kv in sorted(fails.items())) or ""))
    L.append("")

    # ---- renders, trial 1 side by side ----
    L += ["## Renders (trial 1, harness cameras)", "", "| case | " + " | ".join(arms) + " |",
          "|---|" + "---|" * len(arms)]
    for case in cases:
        cells = []
        for a in arms:
            p = os.path.join("runs", case, a, "t1", "renders", "default_iso.png")
            cells.append("![](%s)" % p.replace(os.sep, "/") if os.path.exists(os.path.join(out, p)) else "-")
        L.append("| %s | %s |" % (case, " | ".join(cells)))
    L.append("")
    md = "\n".join(L)
    with open(os.path.join(out, "report.md"), "w") as f:
        f.write(md)
    save_json(os.path.join(out, "summary.json"), summary)
    return md


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    print(build(sys.argv[1]))
