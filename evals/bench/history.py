#!/usr/bin/env python3
"""A/B results over time, one folder per AI model.

Every finished suite is recorded (run.py does it automatically) into
evals/history/<model>/:

  runs.jsonl   one row per case x arm x suite, plus one "ab" row per suite
               that compared two skill versions on the same model
  HISTORY.md   generated from runs.jsonl: the A/B log and each case's trend

Numbers are only comparable within one model, which is why the folders are
per model; compare effort levels with care too (it's a column). Recording
the same suite again (after --regrade or judge.py) replaces its rows, so the
history always matches the latest grading.

  python evals/bench/history.py record evals/results/<suite>   # add or refresh a suite
  python evals/bench/history.py render                          # rebuild every HISTORY.md
"""

import argparse
import hashlib
import json
import os
import re
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import EVALS_DIR, SKILL_REL, load_json  # noqa: E402
import report  # noqa: E402

HISTORY_DIR = os.environ.get("SKILL_BENCH_HISTORY") or os.path.join(EVALS_DIR, "history")
AB_METRICS = ("pass", "score", "cost_usd", "context", "calls", "wall_s")


def skill_hash(plugin_dir):
    """Content hash of a skill copy: identical text gives the same hash, even
    when the git sha says +dirty."""
    root = os.path.join(plugin_dir, SKILL_REL)
    if not os.path.isdir(root):
        return None
    h = hashlib.sha256()
    for d, dirs, files in os.walk(root):
        dirs.sort()
        for f in sorted(files):
            p = os.path.join(d, f)
            h.update(os.path.relpath(p, root).replace(os.sep, "/").encode())
            with open(p, "rb") as fh:
                h.update(fh.read())
    return h.hexdigest()[:10]


def model_dir_name(model):
    return re.sub(r"[^a-z0-9.-]+", "-", (model or "unknown-model").lower()).strip("-")


def _median(xs):
    xs = [x for x in xs if x is not None]
    return statistics.median(xs) if xs else None


def _mean(xs):
    xs = [x for x in xs if x is not None]
    return sum(xs) / len(xs) if xs else None


def _arm_model(arm, suite, runs):
    configured = arm.get("model") or suite.get("model")
    if configured and "-" in configured:  # a full id; aliases like "opus" get resolved below
        return configured
    seen = [r["metrics"].get("main_model") for r in runs if r["metrics"].get("main_model")]
    return max(set(seen), key=seen.count) if seen else configured


def rows_for(out):
    suite = load_json(os.path.join(out, "suite.json"), {})
    summary = load_json(os.path.join(out, "summary.json"), {})
    judge = load_json(os.path.join(out, "judge.json"))
    runs = report.load_runs(out)
    base_id = os.path.basename(os.path.normpath(out))
    sid = "%s@%s" % (base_id, suite.get("started", ""))
    common = {"suite": base_id, "suite_id": sid, "started": suite.get("started") or "",
              "date": (suite.get("started") or "")[:10],
              "label": suite.get("label"), "effort": suite.get("effort") or "default",
              "claude_version": suite.get("claude_version"), "openscad": suite.get("openscad")}
    arms, rows = {}, []
    for a in suite.get("arms", []):
        ar = [r for r in runs if r["arm"] == a["name"]]
        if not ar:
            continue
        plugin = os.path.join(out, "arms", a["name"], "plugin")
        arms[a["name"]] = {
            "arm": a["name"], "ref": a["ref"], "sha": a.get("sha"),
            "skill_hash": a.get("skill_hash") or (skill_hash(plugin) if os.path.isdir(plugin) else None),
            "model": _arm_model(a, suite, ar),
            "static_tokens": ((a.get("footprint") or {}).get("profiles") or {}).get("typical_run_petg_bambu"),
        }
        for case in sorted({r["case"] for r in ar}):
            cr = [r for r in ar if r["case"] == case]
            f = [r["_flat"] for r in cr]
            fails = {}
            for r in cr:
                for ch in r["grade"]["checks"]:
                    if not ch["ok"]:
                        fails[ch["id"]] = fails.get(ch["id"], 0) + 1
            rows.append(dict(common, kind="case", case=case, trials=len(cr),
                             passes=sum(1 for r in cr if r["grade"]["pass"]),
                             score=_mean([x["score"] for x in f]),
                             cost_median=_median([x["cost_usd"] for x in f]),
                             context_median=_median([x["context"] for x in f]),
                             output_median=_median([x["output"] for x in f]),
                             calls_median=_median([x["calls"] for x in f]),
                             wall_median=_median([x["wall_s"] for x in f]),
                             sub_share=_mean([x["sub_share"] for x in f]),
                             timeouts=sum(1 for r in cr if r.get("timed_out")),
                             cost_estimated=sum(1 for r in cr if (r.get("metrics") or {}).get("cost_estimated")),
                             failing=fails, **arms[a["name"]]))
    names = [a["name"] for a in suite.get("arms", []) if a["name"] in arms]
    if len(names) >= 2 and summary.get("paired"):
        base = arms[names[0]]
        for cand_name in names[1:]:
            cand = arms[cand_name]
            if cand["model"] != base["model"]:
                continue  # a model comparison, not a skill A/B: the ledger's job
            est = {k: summary["paired"].get("%s:%s" % (cand_name, k)) for k in AB_METRICS}
            ps = summary.get("arms", {})
            rows.append(dict(common, kind="ab", model=base["model"], base=base, cand=cand,
                             cases=summary.get("cases"), trials=suite.get("trials"),
                             pass_base=(ps.get(names[0]) or {}).get("pass"),
                             pass_cand=(ps.get(cand_name) or {}).get("pass"),
                             estimates=est,
                             judge=judge.get("totals") if judge and judge.get("b") == cand_name else None))
    return sid, rows


def record(out):
    """Add a suite's rows to each model's history, replacing any earlier copy."""
    sid, rows = rows_for(os.path.abspath(out))
    touched = {}
    for r in rows:
        touched.setdefault(model_dir_name(r["model"]), []).append(r)
    for name, new in touched.items():
        d = os.path.join(HISTORY_DIR, name)
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, "runs.jsonl")
        old = []
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                old = [json.loads(ln) for ln in f if ln.strip()]
        keep = [r for r in old if r.get("suite_id") != sid] + new
        keep.sort(key=lambda r: (r.get("started", ""), r.get("suite_id", ""), r.get("kind") != "ab"))
        with open(path, "w", encoding="utf-8") as f:
            for r in keep:
                f.write(json.dumps(r, sort_keys=True) + "\n")
        render_model(d)
    render_index()
    return sorted(os.path.join(HISTORY_DIR, n) for n in touched)


# ---------------------------------------------------------------------------
# HISTORY.md

def _n(v, digits=0, money=False):
    if v is None:
        return "-"
    if money:
        return "$%.2f" % v
    return "{:,.{d}f}".format(v, d=digits)


def _ratio(e):
    if not e or e.get("estimate") is None:
        return "-"
    word = "lower" if e["hi"] < 1 else "higher" if e["lo"] > 1 else "~same"
    return "x%.2f [%.2f-%.2f] %s" % (e["estimate"], e["lo"], e["hi"], word)


def _diff(e):
    if not e or e.get("estimate") is None:
        return "-"
    word = "better" if e["lo"] > 0 else "worse" if e["hi"] < 0 else "~same"
    return "%+.2f [%+.2f, %+.2f] %s" % (e["estimate"], e["lo"], e["hi"], word)


def _skill(r):
    ref = r.get("ref") or "?"
    ver = r.get("sha") or ""
    return "`%s` %s%s" % (ref, ver, " · %s" % r["skill_hash"] if r.get("skill_hash") else "")


def render_model(d):
    rows = []
    with open(os.path.join(d, "runs.jsonl"), encoding="utf-8") as f:
        rows = [json.loads(ln) for ln in f if ln.strip()]
    model = next((r["model"] for r in rows if r.get("model")), os.path.basename(d))
    L = ["# A/B history: %s" % model, "",
         "Generated from `runs.jsonl` by `python evals/bench/history.py render`; don't edit by "
         "hand. Numbers compare only within this model, and only at the same effort. The skill "
         "column is `ref` sha · content hash (same hash = same skill text).", "",
         "Costs ($) are US dollars at Anthropic's list API prices "
         "(https://platform.claude.com/docs/en/about-claude/pricing), as Claude Code reports them "
         "in `total_cost_usd`, sub-agents included. Runs killed at their time limit report no cost, "
         "so theirs is estimated from their tokens (marked est.). A Claude subscription isn't billed "
         "this way: the runs draw on its usage limits instead.", ""]
    abs_ = [r for r in rows if r["kind"] == "ab"]
    L += ["## Skill A/B comparisons", ""]
    if abs_:
        L += ["| Date | Suite | Change | Effort | Base → Cand | Cases × trials | Pass rate | "
              "Check score Δ | Cost ratio [95% CI] | Context ratio [95% CI] | Judge cand/base/tie |",
              "|---|---|---|---|---|---|---|---|---|---|---|"]
        for r in reversed(abs_):
            e, j = r["estimates"], r.get("judge")
            L.append("| %s | %s | %s | %s | %s → %s | %d × %s | %s → %s | %s | %s | %s | %s |" % (
                r["date"], r["suite"], r.get("label") or "", r["effort"], _skill(r["base"]),
                _skill(r["cand"]), len(r.get("cases") or []), r.get("trials"),
                _n(r.get("pass_base"), 2), _n(r.get("pass_cand"), 2), _diff(e.get("score")),
                _ratio(e.get("cost_usd")), _ratio(e.get("context")),
                "%d/%d/%d" % (j["b"], j["a"], j["tie"]) if j else "-"))
    else:
        L.append("None yet: run `run.py` with two arms on this model.")
    L.append("")
    cases = sorted({r["case"] for r in rows if r["kind"] == "case"})
    L += ["## Per case over time", "",
          "Newest first. Median $, context and calls are per run; pass is passes/trials.", ""]
    for case in cases:
        cr = [r for r in rows if r["kind"] == "case" and r["case"] == case]
        L += ["### %s" % case, "",
              "| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | "
              "Calls | Wall s | Sub-agent share | Static tokens | Failing checks |",
              "|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|"]
        for r in reversed(cr):
            L.append("| %s | %s | %s | %s | %s | %d/%d | %.2f | %s | %s | %s | %s | %s | %s | %s |" % (
                r["date"], r["suite"], r["arm"], _skill(r), r["effort"], r["passes"], r["trials"],
                r["score"] or 0, _n(r.get("cost_median"), money=True) + (
                    " (%d est.)" % r["cost_estimated"] if r.get("cost_estimated") else ""),
                _n(r.get("context_median")),
                _n(r.get("calls_median")), _n(r.get("wall_median")),
                _n((r.get("sub_share") or 0) * 100) + "%" if r.get("sub_share") is not None else "-",
                _n(r.get("static_tokens")),
                ", ".join(["%s x%d" % kv for kv in sorted((r.get("failing") or {}).items())]
                          + (["timeout x%d" % r["timeouts"]] if r.get("timeouts") else []))))
        L.append("")
    with open(os.path.join(d, "HISTORY.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L))


def render_index():
    os.makedirs(HISTORY_DIR, exist_ok=True)
    L = ["# Eval history", "",
         "One folder per AI model; each holds `runs.jsonl` (the data) and a generated "
         "`HISTORY.md`. `run.py` records every suite here automatically (`--no-record` to skip). "
         "Rain-gauge flagship runs are also kept in [the ledger](../flagship/rain-gauge/LEDGER.md).", "",
         "| Model | Suites | A/B comparisons | Latest |", "|---|---:|---:|---|"]
    for name in sorted(os.listdir(HISTORY_DIR)):
        path = os.path.join(HISTORY_DIR, name, "runs.jsonl")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as f:
            rows = [json.loads(ln) for ln in f if ln.strip()]
        L.append("| [%s](%s/HISTORY.md) | %d | %d | %s |" % (
            name, name, len({r["suite_id"] for r in rows}), sum(1 for r in rows if r["kind"] == "ab"),
            max((r["date"] for r in rows), default="-")))
    with open(os.path.join(HISTORY_DIR, "README.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    rec = sub.add_parser("record", help="add or refresh a finished suite")
    rec.add_argument("out", nargs="+")
    sub.add_parser("render", help="rebuild every HISTORY.md from runs.jsonl")
    args = ap.parse_args()
    if args.cmd == "record":
        for out in args.out:
            for d in record(out):
                print("recorded %s -> %s" % (os.path.basename(os.path.normpath(out)), os.path.relpath(d)))
    else:
        for name in sorted(os.listdir(HISTORY_DIR)) if os.path.isdir(HISTORY_DIR) else []:
            if os.path.isfile(os.path.join(HISTORY_DIR, name, "runs.jsonl")):
                render_model(os.path.join(HISTORY_DIR, name))
        render_index()
        print("rendered %s" % os.path.relpath(HISTORY_DIR))
    return 0


if __name__ == "__main__":
    sys.exit(main())
