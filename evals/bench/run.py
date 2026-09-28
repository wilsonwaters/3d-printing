#!/usr/bin/env python3
"""Run benchmark cases through `claude -p` for one or more skill versions (arms).

Each run starts in its own empty temp directory outside the repo, with user
settings, user skills, CLAUDE.md and memory excluded (--setting-sources
project), and with exactly one copy of the skill loaded via --plugin-dir. That
matters: an installed copy of the skill (e.g. anthropic-skills:3d-print-designer)
would otherwise load in every arm and blur the comparison.

After each run the harness, not the agent, compiles and measures the output
(grade.py), renders fixed views (render.py), and records tokens and cost from
the transcript (transcript.py). Results land in OUT/runs/<case>/<arm>/tN/.

Arms are NAME=REF[@MODEL]:
  REF is a git ref (main, HEAD~3, a sha), WORKTREE (the skill as it is on disk
  now), or none (no skill: the vanilla-Claude baseline).

  # A/B a skill edit against main, 3 trials per case, smoke tier
  python evals/bench/run.py --tier smoke --arms base=main,cand=WORKTREE --trials 3

  # Compare models on the same skill (the flagship, one trial each)
  python evals/bench/run.py --cases rain-gauge --arms opus=WORKTREE@claude-opus-5-5,fable=WORKTREE@claude-fable-5-1 --trials 1

  # How much does the skill add over vanilla Claude?
  python evals/bench/run.py --tier standard --arms skill=WORKTREE,vanilla=none

Resumable: re-run with the same --out and finished runs are skipped.
After changing the grader or a case's checks, `--regrade OUT` re-scores the
saved outputs without calling a model.

Every finished suite is added to evals/history/<model>/ (runs.jsonl and a
generated HISTORY.md); pass --label to say what changed, --no-record to skip.
Every run is a real model call billed to your account; --max-cost-usd stops
launching new runs once the running total passes it.
"""

import argparse
import concurrent.futures
import datetime
import glob
import io
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import EVALS_DIR, REPO_ROOT, SKILL_REL, find_claude, find_openscad, openscad_version, save_json  # noqa: E402
import footprint  # noqa: E402
import grade as grader  # noqa: E402
import history  # noqa: E402
import render  # noqa: E402
import report  # noqa: E402
import transcript as tx  # noqa: E402

CASE_DIRS = [os.path.join(EVALS_DIR, "cases"), os.path.join(EVALS_DIR, "flagship")]
TOOLS = ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "Agent", "Task", "Skill",
         "TodoWrite", "WebSearch", "WebFetch"]
# Plan mode and questions need a human. The skill-discovery tools can reach a
# copy of the skill on your claude.ai account, which would contaminate every arm.
BLOCKED = ["AskUserQuestion", "EnterPlanMode", "ExitPlanMode", "SearchSkills", "ListSkills",
           "SuggestSkills"]
# Identical for every arm. It replaces the human the skill would otherwise ask.
UNATTENDED = (
    "This is an automated, unattended evaluation run: no human will read or answer anything "
    "until it ends. Where you would normally ask the user a question or wait for approval "
    "(including plan mode), make the most reasonable assumption, state it in one line, and "
    "carry on. AskUserQuestion and plan mode are unavailable. Save every deliverable you would "
    "hand to the user (the .scad source and any STL, 3MF, PNG or README) in the current "
    "directory; scratch files go in $TMPDIR. Finish the task in this session."
)
KEEP_EXT = {".scad", ".md", ".txt", ".json", ".py", ".3mf", ".stl", ".png", ".svg", ".csv"}
KEEP_MAX = 20 * 1024 * 1024


def all_cases():
    found = {}
    for root in CASE_DIRS:
        for cj in glob.glob(os.path.join(root, "*", "case.json")):
            c = grader.load_case(os.path.dirname(cj))
            found[c["name"]] = c
    return found


def git(*args, **kw):
    return subprocess.run(["git", "-C", REPO_ROOT] + list(args), capture_output=True, check=True, **kw)


def prepare_arm(name, spec, out):
    ref, _, model = spec.partition("@")
    info = {"name": name, "ref": ref, "model": model or None, "plugin": None}
    if ref == "none":
        return info
    dest = os.path.join(out, "arms", name, "plugin")
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    os.makedirs(dest)
    if ref == "WORKTREE":
        for rel in (".claude-plugin", SKILL_REL):
            shutil.copytree(os.path.join(REPO_ROOT, rel), os.path.join(dest, rel))
        head = git("rev-parse", "--short", "HEAD", text=True).stdout.strip()
        dirty = git("status", "--porcelain", "--", SKILL_REL, text=True).stdout.strip()
        info["sha"] = head + ("+dirty" if dirty else "")
    else:
        info["sha"] = git("rev-parse", "--short", ref, text=True).stdout.strip()
        tar = git("archive", "--format=tar", ref, "--", ".claude-plugin", SKILL_REL).stdout
        with tarfile.open(fileobj=io.BytesIO(tar)) as t:
            try:
                t.extractall(dest, filter="data")
            except TypeError:  # Python < 3.12
                t.extractall(dest)
    info["plugin"] = dest
    info["skill_hash"] = history.skill_hash(dest)
    skill_dir = os.path.join(dest, SKILL_REL)
    fp = footprint.measure(skill_dir)
    info["footprint"] = {"always_on": fp["always_on"], "profiles": fp["profiles"],
                         "total_md_tokens": fp["total_md_tokens"]}
    return info


def child_env():
    # A parent session's id, or its effort level, would otherwise leak into every
    # child run; effort is set only by --effort so both arms get the same one.
    return {k: v for k, v in os.environ.items()
            if k not in ("CLAUDE_CODE_SESSION_ID", "CLAUDE_EFFORT")}


def build_cmd(claude, case, arm, model, effort, scratch):
    prompt = case["prompt"]
    cmd = [claude, "-p", prompt, "--output-format", "stream-json", "--verbose",
           "--max-turns", str(case.get("max_turns", 150)), "--no-session-persistence",
           "--setting-sources", "project", "--permission-mode", "acceptEdits",
           "--allowedTools", ",".join(case.get("allowed_tools", TOOLS)),
           "--disallowedTools", ",".join(BLOCKED), "--add-dir", scratch]
    if case.get("unattended", True):
        cmd += ["--append-system-prompt", UNATTENDED]
    if arm["plugin"]:
        cmd += ["--plugin-dir", arm["plugin"]]
    if arm.get("model") or model:
        cmd += ["--model", arm.get("model") or model]
    if effort:
        cmd += ["--effort", effort]
    if case.get("max_budget_usd"):
        cmd += ["--max-budget-usd", str(case["max_budget_usd"])]
    return cmd


def preflight(claude, arm, env):
    """Start a one-turn session and read its init event: the arm must see exactly
    its own copy of the skill (and the no-skill arm must see none)."""
    cmd = [claude, "-p", "Reply with the single word OK.", "--output-format", "stream-json",
           "--verbose", "--max-turns", "1", "--no-session-persistence", "--setting-sources",
           "project", "--model", "haiku", "--disallowedTools", ",".join(BLOCKED)]
    if arm["plugin"]:
        cmd += ["--plugin-dir", arm["plugin"]]
    tmp = tempfile.mkdtemp(prefix="skbench-pre-")
    try:
        out = subprocess.run(cmd, cwd=tmp, capture_output=True, text=True, timeout=300,
                             stdin=subprocess.DEVNULL, env=env).stdout
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    for line in out.splitlines():
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if e.get("type") == "system" and e.get("subtype") == "init":
            skills = [x for x in e.get("skills", []) if "3d-print" in x]
            plugins = [p.get("name") for p in e.get("plugins", [])]
            ours = ("3d-print-designer", "3d-print-designer:3d-print-designer")
            if arm["plugin"] and (len(skills) != 1 or skills[0] not in ours
                                  or "3d-print-designer" not in plugins):
                return "expected only the arm's 3d-print-designer; session saw skills=%s plugins=%s" % (skills, plugins)
            if not arm["plugin"] and skills:
                return "no-skill arm can still see %s (an installed copy leaks in)" % skills
            return None
    return "no init event from claude -p (is it logged in?)"


class Budget:
    def __init__(self, ceiling):
        self.ceiling, self.spent, self.lock = ceiling, 0.0, threading.Lock()

    def ok(self):
        with self.lock:
            return self.ceiling is None or self.spent < self.ceiling

    def add(self, usd):
        with self.lock:
            self.spent += usd or 0.0


def run_one(job, args, claude, budget):
    case, arm, trial = job["case"], job["arm"], job["trial"]
    run_dir = os.path.join(args.out, "runs", case["name"], arm["name"], "t%d" % trial)
    rec_path = os.path.join(run_dir, "run.json")
    if os.path.exists(rec_path) and not args.force:
        with open(rec_path) as f:
            return json.load(f)
    if not budget.ok():
        return {"case": case["name"], "arm": arm["name"], "trial": trial, "skipped": "cost ceiling"}
    os.makedirs(run_dir, exist_ok=True)
    base = tempfile.mkdtemp(prefix="skbench-")
    ws, scratch = os.path.join(base, "work"), os.path.join(base, "scratch")
    os.makedirs(ws)
    os.makedirs(scratch)
    fixtures = []
    for dst, src in (case.get("fixtures") or {}).items():
        shutil.copy(os.path.join(case["_dir"], src), os.path.join(ws, dst))
        fixtures.append(dst)
    env = child_env()
    env["TMPDIR"] = scratch
    cmd = build_cmd(claude, case, arm, args.model, args.effort, scratch)
    tpath = os.path.join(run_dir, "transcript.jsonl")
    t0 = time.time()
    timed_out = False
    with open(tpath, "w") as out, open(os.path.join(run_dir, "stderr.log"), "w") as err:
        proc = subprocess.Popen(cmd, cwd=ws, stdout=out, stderr=err, stdin=subprocess.DEVNULL, env=env)
        try:
            code = proc.wait(timeout=case.get("timeout_s", 2700))
        except subprocess.TimeoutExpired:
            proc.kill()
            code, timed_out = proc.wait(), True
    wall = round(time.time() - t0, 1)
    metrics = tx.analyse([tpath], skill_root=arm["plugin"])
    metrics["_tool_matches"] = grader.tool_matches(case, [tpath])
    g = grader.grade(ws, case, metrics, fixtures=fixtures, timeout=args.compile_timeout)
    everything = grader.list_files(ws)  # includes fixtures an edit case changed in place
    scads = grader.deliverable_scads(ws, everything) if case.get("design", True) else []
    if scads and not args.no_render:
        render.render_views(os.path.join(ws, scads[0]), os.path.join(run_dir, "renders"))
    keep = os.path.join(run_dir, "files")
    for f in everything:
        src = os.path.join(ws, f)
        if os.path.splitext(f)[1].lower() in KEEP_EXT and os.path.getsize(src) <= KEEP_MAX:
            os.makedirs(os.path.dirname(os.path.join(keep, f)), exist_ok=True)
            shutil.copy(src, os.path.join(keep, f))
    if args.keep_workspace:
        shutil.copytree(ws, os.path.join(run_dir, "workspace"), dirs_exist_ok=True)
    shutil.rmtree(base, ignore_errors=True)
    final = metrics.pop("final_text", "")
    metrics.pop("_tool_matches", None)
    with open(os.path.join(run_dir, "final_message.md"), "w") as f:
        f.write(final or "")
    rec = {"case": case["name"], "arm": arm["name"], "trial": trial, "ref": arm["ref"],
           "sha": arm.get("sha"), "model": arm.get("model") or args.model, "effort": args.effort,
           "exit_code": code, "timed_out": timed_out, "wall_s": wall,
           "metrics": metrics, "grade": g}
    save_json(rec_path, rec)
    budget.add(metrics.get("cost_usd"))
    return rec


def regrade(out, compile_timeout, record=True):
    """Re-score saved runs with the current grader and cases: no model calls.
    Uses each run's kept files, so anything outside KEEP_EXT is gone."""
    cases = all_cases()
    suite = os.path.join(out, "suite.json")
    arms = {a["name"]: a for a in (json.load(open(suite))["arms"] if os.path.exists(suite) else [])}
    for rec_path in sorted(glob.glob(os.path.join(out, "runs", "*", "*", "t*", "run.json"))):
        with open(rec_path) as f:
            rec = json.load(f)
        case = cases.get(rec["case"])
        if rec.get("skipped") or not case:
            continue
        run_dir = os.path.dirname(rec_path)
        tpath = os.path.join(run_dir, "transcript.jsonl")
        plugin = os.path.join(out, "arms", rec["arm"], "plugin")
        skill_root = os.path.join(plugin, SKILL_REL) if os.path.isdir(plugin) else None
        metrics = tx.analyse([tpath], skill_root=skill_root)
        metrics["_tool_matches"] = grader.tool_matches(case, [tpath])
        files = os.path.join(run_dir, "files")
        os.makedirs(files, exist_ok=True)
        g = grader.grade(files, case, metrics, fixtures=list((case.get("fixtures") or {}).keys()),
                         timeout=compile_timeout, known_files=rec["grade"].get("files", []))
        metrics.pop("final_text", None)
        metrics.pop("_tool_matches", None)
        rec["metrics"], rec["grade"] = metrics, g
        save_json(rec_path, rec)
        print("%-18s %-8s t%s  %s score=%.2f" % (rec["case"], rec["arm"], rec["trial"],
                                                "PASS" if g["pass"] else "FAIL", g["score"]))
    print(report.build(out))
    if record:
        for d in history.record(out):
            print("history updated: %s" % os.path.relpath(d))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--cases", help="comma-separated case names")
    ap.add_argument("--tier", help="run every case tagged with this tier (smoke, standard, flagship)")
    ap.add_argument("--arms", default="cand=WORKTREE", help="NAME=REF[@MODEL],... (default cand=WORKTREE)")
    ap.add_argument("--trials", type=int, default=3)
    ap.add_argument("--model", help="model for every arm without its own @MODEL (pin this for A/B)")
    ap.add_argument("--effort", help="effort level (pin this for A/B)")
    ap.add_argument("-j", "--concurrency", type=int, default=2)
    ap.add_argument("--max-cost-usd", type=float, help="stop launching runs past this total")
    ap.add_argument("--out", help="results dir (default evals/results/<timestamp>)")
    ap.add_argument("--force", action="store_true", help="re-run finished runs")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--keep-workspace", action="store_true", help="copy the whole workspace back")
    ap.add_argument("--compile-timeout", type=int, default=900)
    ap.add_argument("--label", help="what changed, for the history (e.g. 'trim printer-profiles')")
    ap.add_argument("--no-record", action="store_true",
                    help="don't add this suite to evals/history/<model>/ (throwaway runs)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--list", action="store_true", help="list cases and exit")
    ap.add_argument("--regrade", metavar="OUT", help="re-score a finished results dir (free)")
    args = ap.parse_args()
    if args.regrade:
        regrade(os.path.abspath(args.regrade), args.compile_timeout, record=not args.no_record)
        return 0

    cases = all_cases()
    if args.list:
        for n, c in sorted(cases.items()):
            print("%-22s %-28s %s" % (n, ",".join(c.get("tiers", [])), c.get("description", "")))
        return 0
    if args.cases:
        names = args.cases.split(",")
        missing = [n for n in names if n not in cases]
        if missing:
            raise SystemExit("unknown case(s): %s (try --list)" % ", ".join(missing))
        chosen = [cases[n] for n in names]
    elif args.tier:
        chosen = [c for c in cases.values() if args.tier in c.get("tiers", [])]
    else:
        raise SystemExit("pick --cases or --tier (try --list)")
    claude = find_claude()
    if not claude:
        raise SystemExit("claude CLI not found (set $CLAUDE_BIN)")
    if not find_openscad():
        raise SystemExit("OpenSCAD not found: the grader compiles every output (set $OPENSCAD)")

    arm_specs = [a.split("=", 1) for a in args.arms.split(",")]
    n_runs = len(chosen) * len(arm_specs) * args.trials
    print("%d case(s) x %d arm(s) x %d trial(s) = %d runs" % (len(chosen), len(arm_specs), args.trials, n_runs))
    for c in chosen:
        print("  %-22s max_turns=%s timeout=%ss budget=$%s" % (
            c["name"], c.get("max_turns", 150), c.get("timeout_s", 2700), c.get("max_budget_usd", "-")))
    if args.dry_run:
        return 0

    # absolute: every agent runs from its own temp dir, so a relative --plugin-dir would miss
    args.out = os.path.abspath(args.out or os.path.join(
        EVALS_DIR, "results", datetime.datetime.now().strftime("%Y%m%d-%H%M%S")))
    os.makedirs(args.out, exist_ok=True)
    arms = [prepare_arm(n, s, args.out) for n, s in arm_specs]
    for a in arms:
        problem = preflight(claude, a, child_env())
        if problem:
            raise SystemExit("arm %s failed preflight: %s" % (a["name"], problem))
        print("arm %-8s ok: %s" % (a["name"], "skill %s loaded" % a.get("sha") if a["plugin"] else "no skill visible"))
    ver = subprocess.run([claude, "--version"], capture_output=True, text=True).stdout.strip()
    save_json(os.path.join(args.out, "suite.json"), {
        "started": datetime.datetime.now().isoformat(timespec="seconds"),
        "claude_version": ver, "openscad": openscad_version(find_openscad()),
        "label": args.label, "model": args.model, "effort": args.effort, "trials": args.trials,
        "cases": [c["name"] for c in chosen],
        "arms": [{k: v for k, v in a.items() if k != "plugin"} for a in arms]})

    # Interleave arms (and rotate their order) so drift over the session hits every arm alike.
    jobs = []
    for t in range(1, args.trials + 1):
        for c in chosen:
            order = arms[(t - 1) % len(arms):] + arms[:(t - 1) % len(arms)]
            jobs.extend({"case": c, "arm": a, "trial": t} for a in order)
    budget = Budget(args.max_cost_usd)
    done = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.concurrency)) as pool:
        futs = [pool.submit(run_one, j, args, claude, budget) for j in jobs]
        for fut in concurrent.futures.as_completed(futs):
            done += 1
            try:
                r = fut.result()
            except Exception as exc:  # keep the suite going; the report shows the gap
                print("[%d/%d] run crashed: %s" % (done, len(jobs), exc))
                continue
            if r.get("skipped"):
                print("[%d/%d] %s/%s t%d skipped (%s)" % (done, len(jobs), r["case"], r["arm"], r["trial"], r["skipped"]))
                continue
            m, g = r["metrics"], r["grade"]
            print("[%d/%d] %-18s %-8s t%d  %s score=%.2f  $%s  %ss  calls=%s%s" % (
                done, len(jobs), r["case"], r["arm"], r["trial"], "PASS" if g["pass"] else "FAIL",
                g["score"], m.get("cost_usd"), r["wall_s"], m.get("api_calls"),
                "  TIMEOUT" if r["timed_out"] else ""))
    md = report.build(args.out)
    print("\n" + md)
    print("Spent ~$%.2f. Report: %s" % (budget.spent, os.path.join(args.out, "report.md")))
    if not args.no_record:
        for d in history.record(args.out):
            print("History: %s (commit it to keep the record)" % os.path.relpath(os.path.join(d, "HISTORY.md")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
