#!/usr/bin/env python3
"""Compare design-review quality across reviewer models on fixed, seeded-defect designs.

The skill's full A/B can't isolate the reviewer: the author changes the design, triages
the findings, and only then is graded. This holds the design fixed. Each fixture in
evals/reviewer/fixtures/ is a small .scad model that passes the build gate, a brief
(printer, material, acceptance criteria) and an answer key of seeded defects marked vital
or minor; one fixture is a clean control with no defects.

For every fixture x reviewer model x trial, the reviewer gets exactly the brief the
skill's author sends its review sub-agent (SKILL.md, Design Review): the .scad path, the
OpenSCAD path, printer and material, the numbered criteria, and "read design-review.md,
your complete brief; the gate has passed". A fixed judge model then maps the review's
findings onto the answer key and rates any other findings (real / debatable / wrong).

  python evals/bench/review_models.py --reviewers sonnet=claude-sonnet-5-5,fable=claude-fable-5-1 \
      --trials 3 --effort high -j 3 --label "Sonnet vs Fable on simple parts"
  python evals/bench/review_models.py --render      # rebuild evals/reviewer/RESULTS.md

Results: raw runs in evals/results/reviewer-<timestamp>/ (git-ignored); one row per run is
appended to evals/reviewer/runs.jsonl and RESULTS.md is regenerated (both committed).
Resumable: repeat with the same --out and finished runs are skipped. Every run is a real
model call: costs are list-price USD as Claude Code reports them.
"""

import argparse
import concurrent.futures
import datetime
import hashlib
import json
import os
import shutil
import statistics
import subprocess
import sys
import tempfile
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import EVALS_DIR, REPO_ROOT, SKILL_REL, find_claude, find_openscad  # noqa: E402
import transcript as tx  # noqa: E402

FIXTURES = os.path.join(EVALS_DIR, "reviewer", "fixtures")
LEDGER = os.path.join(EVALS_DIR, "reviewer", "runs.jsonl")
RESULTS_MD = os.path.join(EVALS_DIR, "reviewer", "RESULTS.md")
PRICING = "https://platform.claude.com/docs/en/about-claude/pricing"
LEAKY_ENV = ("CLAUDE_CODE_SESSION_ID", "CLAUDE_EFFORT", "CLAUDE_AUTO_BACKGROUND_TASKS",
             "CLAUDE_CODE_BG_TASKS_REPORT_RUNNING")
REVIEW_TOOLS = "Read,Bash,Glob,Grep"
LIMIT_MARK = "hit your session limit"

JUDGE_SCHEMA = {
    "type": "object", "additionalProperties": False,
    "required": ["reviewer_model_id", "defects", "other_findings"],
    "properties": {
        "reviewer_model_id": {"type": "string"},
        "defects": {"type": "array", "items": {
            "type": "object", "additionalProperties": False, "required": ["id", "found", "quote"],
            "properties": {"id": {"type": "string"}, "found": {"type": "boolean"},
                           "quote": {"type": "string"}}}},
        "other_findings": {"type": "array", "items": {
            "type": "object", "additionalProperties": False,
            "required": ["summary", "verdict", "claimed_serious"],
            "properties": {"summary": {"type": "string"},
                           "verdict": {"type": "string", "enum": ["real", "debatable", "wrong"]},
                           "claimed_serious": {"type": "boolean"}}}},
    },
}

JUDGE_PROMPT = """You are grading one design review of a 3D-printable OpenSCAD model against an
answer key. Be strict and literal: credit a seeded defect only if the review clearly identifies
that problem (its "credit" line says what counts); a vague or passing mention that does not
say what is wrong is not a find. A defect the review raises and then dismisses as fine is not
a find.

Then list every OTHER finding the review makes that is not one of the seeded defects, one
entry per distinct issue (merge duplicates). For each, give:
- verdict: "real" if it is a genuine problem with this model given the brief, "debatable" if
  reasonable engineers could disagree, "wrong" if it is factually incorrect about the model
  or not a problem;
- claimed_serious: true if the review presents it as critical, major, high or blocking.

Also report the model ID the review states at its top (or "unknown").

## Brief given to the reviewer
Printer: {printer}
Material: {material}
Acceptance criteria:
{criteria}

## The model file
```openscad
{scad}
```

## Answer key (seeded defects)
{answers}

## The review to grade
{review}
"""


def child_env(scratch):
    env = {k: v for k, v in os.environ.items() if k not in LEAKY_ENV}
    env["TMPDIR"] = scratch
    return env


def load_fixtures(names=None):
    out = []
    for name in sorted(os.listdir(FIXTURES)):
        d = os.path.join(FIXTURES, name)
        if not os.path.isdir(d) or (names and name not in names):
            continue
        with open(os.path.join(d, "brief.json")) as f:
            brief = json.load(f)
        with open(os.path.join(d, "answers.json")) as f:
            answers = json.load(f)
        with open(os.path.join(d, "model.scad"), encoding="utf-8") as f:
            scad = f.read()
        out.append({"name": name, "dir": d, "brief": brief, "answers": answers, "scad": scad})
    return out


def skill_hash(skill_dir):
    h = hashlib.sha256()
    for root, _, files in sorted(os.walk(skill_dir)):
        for fn in sorted(files):
            with open(os.path.join(root, fn), "rb") as f:
                h.update(fn.encode() + f.read())
    return h.hexdigest()[:10]


def review_prompt(ws, openscad, fx):
    b = fx["brief"]
    crit = "\n".join("  %d. %s" % (i + 1, c) for i, c in enumerate(b["criteria"]))
    return ("You are the design-review sub-agent for a 3D-printable OpenSCAD model.\n\n"
            "- Model: %s/model.scad\n- OpenSCAD: %s\n- Printer: %s\n- Material: %s\n"
            "- Acceptance criteria:\n%s\n\n"
            "Read %s/skill/design-review.md, your complete brief; the gate has passed.\n"
            "Write any renders or scratch files under $TMPDIR. Your final message is your findings."
            % (ws, openscad, b["printer"], b["material"], crit, ws))


def run_claude(cmd, cwd, env, timeout, out_path):
    t0 = time.time()
    with open(out_path, "w") as out, open(out_path + ".stderr", "w") as err:
        proc = subprocess.Popen(cmd, cwd=cwd, stdout=out, stderr=err, stdin=subprocess.DEVNULL, env=env)
        try:
            code = proc.wait(timeout=timeout)
            timed_out = False
        except subprocess.TimeoutExpired:
            proc.kill()
            code, timed_out = proc.wait(), True
    return code, timed_out, round(time.time() - t0, 1)


def judge(claude, fx, review, model, effort, workdir):
    b = fx["brief"]
    prompt = JUDGE_PROMPT.format(
        printer=b["printer"], material=b["material"],
        criteria="\n".join("%d. %s" % (i + 1, c) for i, c in enumerate(b["criteria"])),
        scad=fx["scad"], review=review or "(the reviewer returned nothing)",
        answers=(json.dumps(fx["answers"]["defects"], indent=1) if fx["answers"].get("defects")
                 else "None: this is a clean control with no seeded defects. Grade only its other findings."))
    cmd = [claude, "-p", prompt, "--model", model, "--effort", effort, "--tools", "",
           "--output-format", "json", "--no-session-persistence", "--setting-sources", "project",
           "--json-schema", json.dumps(JUDGE_SCHEMA)]
    p = subprocess.run(cmd, cwd=workdir, capture_output=True, text=True, timeout=900,
                       env=child_env(workdir), stdin=subprocess.DEVNULL)
    res = json.loads(p.stdout)
    if LIMIT_MARK in (res.get("result") or ""):
        raise RuntimeError("usage limit")
    return res.get("structured_output"), res.get("total_cost_usd") or 0.0


def score(fx, verdict):
    key = {d["id"]: d for d in fx["answers"].get("defects", [])}
    found = {d["id"] for d in (verdict or {}).get("defects", []) if d.get("found") and d["id"] in key}
    other = (verdict or {}).get("other_findings", [])
    vit = [k for k, d in key.items() if d["severity"] == "vital"]
    mnr = [k for k, d in key.items() if d["severity"] != "vital"]
    return {"found": sorted(found), "vital_total": len(vit), "vital_found": sum(k in found for k in vit),
            "minor_total": len(mnr), "minor_found": sum(k in found for k in mnr),
            "extra_real": sum(o["verdict"] == "real" for o in other),
            "extra_debatable": sum(o["verdict"] == "debatable" for o in other),
            "wrong": sum(o["verdict"] == "wrong" for o in other),
            "wrong_serious": sum(o["verdict"] == "wrong" and o["claimed_serious"] for o in other)}


def run_one(job, args, claude, openscad, skill_dir, stop):
    fx, (rname, rmodel), trial = job
    d = os.path.join(args.out, "runs", fx["name"], rname, "t%d" % trial)
    rec_path = os.path.join(d, "run.json")
    if os.path.exists(rec_path):
        with open(rec_path) as f:
            return json.load(f)
    if stop.is_set():
        return None
    os.makedirs(d, exist_ok=True)
    base = tempfile.mkdtemp(prefix="revbench-")
    ws, scratch = os.path.join(base, "work"), os.path.join(base, "scratch")
    os.makedirs(scratch)
    shutil.copytree(skill_dir, os.path.join(ws, "skill"))
    shutil.copy(os.path.join(fx["dir"], "model.scad"), os.path.join(ws, "model.scad"))
    cmd = [claude, "-p", review_prompt(ws, openscad, fx), "--model", rmodel, "--effort", args.effort,
           "--output-format", "stream-json", "--verbose", "--max-turns", "60", "--no-session-persistence",
           "--setting-sources", "project", "--permission-mode", "acceptEdits",
           "--tools", REVIEW_TOOLS, "--allowedTools", REVIEW_TOOLS, "--add-dir", scratch]
    tpath = os.path.join(d, "transcript.jsonl")
    code, timed_out, wall = run_claude(cmd, ws, child_env(scratch), args.timeout, tpath)
    with open(tpath, encoding="utf-8", errors="replace") as f:
        if LIMIT_MARK in f.read():
            stop.set()
            print("USAGE LIMIT hit on %s/%s/t%d: not recording it; stopping new launches" % (fx["name"], rname, trial))
            shutil.rmtree(d, ignore_errors=True)
            return None
    m = tx.analyse([tpath])
    review = m.get("final_text") or ""
    with open(os.path.join(d, "review.md"), "w", encoding="utf-8") as f:
        f.write(review)
    try:
        verdict, jcost = judge(claude, fx, review, args.judge_model, args.judge_effort, scratch)
    except RuntimeError:
        stop.set()
        print("USAGE LIMIT hit while judging %s/%s/t%d; stopping" % (fx["name"], rname, trial))
        return None
    with open(os.path.join(d, "judge.json"), "w") as f:
        json.dump(verdict, f, indent=1)
    rec = {"fixture": fx["name"], "control": bool(fx["answers"].get("control")), "reviewer": rname,
           "model": rmodel, "trial": trial, "effort": args.effort, "exit": code, "timed_out": timed_out,
           "wall_s": wall, "cost_usd": m.get("cost_usd"), "api_calls": m.get("api_calls"),
           "images": m.get("image_reads"), "judge_model": args.judge_model, "judge_cost_usd": jcost,
           "stated_model": (verdict or {}).get("reviewer_model_id"), **score(fx, verdict)}
    with open(rec_path, "w") as f:
        json.dump(rec, f, indent=1)
    shutil.rmtree(base, ignore_errors=True)
    print("%-16s %-7s t%d  vital %d/%d  minor %d/%d  extra real %d  wrong-serious %d  $%.2f  %.0fs"
          % (fx["name"], rname, trial, rec["vital_found"], rec["vital_total"], rec["minor_found"],
             rec["minor_total"], rec["extra_real"], rec["wrong_serious"], rec["cost_usd"] or 0, wall))
    return rec


# --------------------------------------------------------------------------- results

def med(xs):
    xs = [x for x in xs if x is not None]
    return statistics.median(xs) if xs else 0


def render():
    rows = []
    if os.path.exists(LEDGER):
        with open(LEDGER) as f:
            rows = [json.loads(ln) for ln in f if ln.strip()]
    fx = {f["name"]: f for f in load_fixtures()}
    L = ["# Reviewer model comparison", "",
         "Generated from `runs.jsonl` by `python evals/bench/review_models.py --render`; don't edit by "
         "hand. How it works is in [README.md](README.md).", "",
         "Each run gives one reviewer model the skill's design-review brief for one fixed fixture, "
         "then a judge model maps its findings onto the fixture's seeded defects. **Vital** defects "
         "would stop the part working or printing; **minor** ones are rule or quality slips. "
         "Costs are US dollars at Anthropic's [list API prices](%s), as Claude Code reports them "
         "(reviewer only; judging is listed separately). On a subscription they draw on usage "
         "limits instead." % PRICING, ""]
    for suite in sorted({r["suite"] for r in rows}, reverse=True):
        rs = [r for r in rows if r["suite"] == suite]
        meta = rs[0]
        L += ["## %s" % suite, "",
              "%s. Skill `%s` · %s, effort `%s`, judged by `%s`. %d runs." % (
                  meta.get("label") or "No label", meta.get("skill_sha"), meta.get("skill_hash"),
                  meta.get("effort"), meta.get("judge_model"), len(rs)), ""]
        revs = sorted({r["reviewer"] for r in rs})
        L += ["| Reviewer | Model | Vital defects found | Minor found | Extra real findings per review | "
              "Serious false alarms per review | Control: serious false alarms | Median $ per review | "
              "Median minutes |", "|---|---|---:|---:|---:|---:|---:|---:|---:|"]
        for rv in revs:
            x = [r for r in rs if r["reviewer"] == rv]
            seeded = [r for r in x if not r["control"]]
            ctrl = [r for r in x if r["control"]]
            vf, vt = sum(r["vital_found"] for r in seeded), sum(r["vital_total"] for r in seeded)
            mf, mt = sum(r["minor_found"] for r in seeded), sum(r["minor_total"] for r in seeded)
            L.append("| %s | `%s` | %d/%d (%.0f%%) | %d/%d (%.0f%%) | %.1f | %.2f | %s | %.2f | %.1f |" % (
                rv, x[0]["model"], vf, vt, 100.0 * vf / vt if vt else 0, mf, mt, 100.0 * mf / mt if mt else 0,
                statistics.mean(r["extra_real"] for r in x), statistics.mean(r["wrong_serious"] for r in x),
                "%d in %d" % (sum(r["wrong_serious"] for r in ctrl), len(ctrl)) if ctrl else "-",
                med(r["cost_usd"] for r in x), med(r["wall_s"] for r in x) / 60))
        L += ["", "Per seeded defect (reviews that found it):", "",
              "| Fixture | Defect | Severity | " + " | ".join(revs) + " |",
              "|---|---|---|" + "---:|" * len(revs)]
        for name in sorted({r["fixture"] for r in rs}):
            for d in fx.get(name, {}).get("answers", {}).get("defects", []):
                cells = []
                for rv in revs:
                    x = [r for r in rs if r["reviewer"] == rv and r["fixture"] == name]
                    cells.append("%d/%d" % (sum(d["id"] in r["found"] for r in x), len(x)))
                L.append("| %s | %s | %s | %s |" % (name, d["id"], d["severity"], " | ".join(cells)))
        jc = sum(r.get("judge_cost_usd") or 0 for r in rs)
        rc = sum(r.get("cost_usd") or 0 for r in rs)
        L += ["", "Spend: $%.2f on reviews, $%.2f on judging." % (rc, jc), ""]
    with open(RESULTS_MD, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    print("rendered %s" % os.path.relpath(RESULTS_MD, REPO_ROOT))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--reviewers", default="sonnet=claude-sonnet-5-5,fable=claude-fable-5-1",
                    help="NAME=MODEL,... (model IDs or aliases)")
    ap.add_argument("--fixtures", help="comma-separated fixture names (default: all)")
    ap.add_argument("--trials", type=int, default=3)
    ap.add_argument("--effort", default="high", help="reviewer effort, the same for every model")
    ap.add_argument("--judge-model", default="claude-opus-5-5")
    ap.add_argument("--judge-effort", default="medium")
    ap.add_argument("-j", "--concurrency", type=int, default=3)
    ap.add_argument("--timeout", type=int, default=1500, help="seconds per review")
    ap.add_argument("--out", help="results dir (default evals/results/reviewer-<timestamp>)")
    ap.add_argument("--label", help="what this suite tests, for RESULTS.md")
    ap.add_argument("--no-record", action="store_true")
    ap.add_argument("--render", action="store_true", help="only rebuild RESULTS.md from runs.jsonl")
    args = ap.parse_args()
    if args.render:
        return render()
    claude, openscad = find_claude(), find_openscad()
    if not claude or not openscad:
        sys.exit("needs the claude CLI and OpenSCAD")
    fixtures = load_fixtures(args.fixtures.split(",") if args.fixtures else None)
    reviewers = [tuple(s.split("=", 1)) for s in args.reviewers.split(",")]
    args.out = os.path.abspath(args.out or os.path.join(
        EVALS_DIR, "results", "reviewer-" + datetime.datetime.now().strftime("%Y-%m-%dT%H-%M-%S")))
    os.makedirs(args.out, exist_ok=True)
    skill_dir = os.path.join(REPO_ROOT, SKILL_REL)
    sha = subprocess.run(["git", "-C", REPO_ROOT, "rev-parse", "--short", "HEAD"],
                         capture_output=True, text=True).stdout.strip()
    dirty = subprocess.run(["git", "-C", REPO_ROOT, "status", "--porcelain", "--", SKILL_REL],
                           capture_output=True, text=True).stdout.strip()
    suite_path = os.path.join(args.out, "suite.json")
    if os.path.exists(suite_path):
        with open(suite_path) as f:
            suite = json.load(f)
    else:
        suite = {"suite": os.path.basename(args.out), "label": args.label, "started":
                 datetime.datetime.now().isoformat(timespec="seconds"),
                 "skill_sha": sha + ("+dirty" if dirty else ""), "skill_hash": skill_hash(skill_dir)}
        with open(suite_path, "w") as f:
            json.dump(suite, f, indent=1)
    # interleave reviewers so drift during the session hits both
    jobs = [(fx, rv, t) for t in range(1, args.trials + 1) for fx in fixtures for rv in reviewers]
    stop = threading.Event()
    with concurrent.futures.ThreadPoolExecutor(args.concurrency) as ex:
        recs = list(ex.map(lambda j: run_one(j, args, claude, openscad, skill_dir, stop), jobs))
    done = [r for r in recs if r]
    print("%d of %d runs finished" % (len(done), len(jobs)))
    if stop.is_set():
        print("Stopped early on the usage limit: re-run with --out %s after it resets" % args.out)
    if args.no_record or len(done) < len(jobs):
        if len(done) < len(jobs):
            print("Not recorded until every run has finished.")
        return
    old = []
    if os.path.exists(LEDGER):
        with open(LEDGER) as f:
            old = [json.loads(ln) for ln in f if ln.strip() and json.loads(ln)["suite"] != suite["suite"]]
    with open(LEDGER, "w") as f:
        for r in old + [dict(r, **{k: suite[k] for k in ("suite", "label", "skill_sha", "skill_hash")},
                             date=suite["started"][:10]) for r in done]:
            f.write(json.dumps(r, sort_keys=True) + "\n")
    render()


if __name__ == "__main__":
    main()
