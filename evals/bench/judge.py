#!/usr/bin/env python3
"""Blind pairwise judge: for each case and trial, which arm's design is better?

Deterministic checks can't tell a clever mechanism from a clumsy one. This
shows a judge model both designs (the harness renders, the source header and
the hand-off message), labelled only "Design 1" and "Design 2", and asks which
better meets the brief. Each pair is judged twice with the order swapped; a
design wins only if it wins both times, otherwise it's a tie. That cancels the
judge's position bias instead of hiding it in the result.

Use a different model from the one that did the designing where you can, and
spot-check its verdicts against your own before trusting it (see README).

  python evals/bench/judge.py evals/results/<ts> --a base --b cand [--judge-model sonnet]
"""

import argparse
import glob
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import find_claude, load_json, save_json  # noqa: E402
import run as runner  # noqa: E402

SCHEMA = {
    "type": "object",
    "properties": {
        "winner": {"type": "string", "enum": ["1", "2", "tie"]},
        "requirements": {"type": "string", "enum": ["1", "2", "tie"]},
        "mechanism": {"type": "string", "enum": ["1", "2", "tie"]},
        "printability": {"type": "string", "enum": ["1", "2", "tie"]},
        "reasons": {"type": "string"},
    },
    "required": ["winner", "requirements", "mechanism", "printability", "reasons"],
}
DEFAULT_CRITERIA = [
    "Meets every stated requirement of the brief (dimensions, fit, counts, features).",
    "The mechanism or structure would actually work as a physical object.",
    "Printable on an FDM printer as oriented: flat on the plate, minimal unsupported overhang, "
    "sensible wall thickness, fits the stated printer.",
    "Parametric and documented well enough that the user could adjust it.",
]


def design_block(label, run_dir, root):
    imgs = sorted(glob.glob(os.path.join(run_dir, "renders", "*.png")))
    scads = sorted(glob.glob(os.path.join(run_dir, "files", "**", "*.scad"), recursive=True),
                   key=lambda p: -os.path.getsize(p))
    lines = ["%s:" % label]
    lines += ["  render: %s" % os.path.relpath(p, root) for p in imgs] or ["  (no renders)"]
    if scads:
        lines.append("  source (read the header comments, roughly the first 120 lines): %s"
                     % os.path.relpath(scads[0], root))
    fm = os.path.join(run_dir, "final_message.md")
    if os.path.exists(fm):
        lines.append("  hand-off message to the user: %s" % os.path.relpath(fm, root))
    return "\n".join(lines)


def ask(claude, model, prompt, cwd):
    cmd = [claude, "-p", prompt, "--output-format", "json", "--json-schema", json.dumps(SCHEMA),
           "--allowedTools", "Read,Glob", "--disallowedTools", ",".join(runner.BLOCKED),
           "--setting-sources", "project",
           "--no-session-persistence", "--max-turns", "40", "--model", model]
    out = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, stdin=subprocess.DEVNULL,
                         timeout=1200)
    try:
        res = json.loads(out.stdout)
    except ValueError:
        return None, 0.0
    verdict = res.get("structured_output")
    if verdict is None:
        try:
            verdict = json.loads(res.get("result", ""))
        except ValueError:
            verdict = None
    return verdict, res.get("total_cost_usd") or 0.0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out")
    ap.add_argument("--a", required=True, help="reference arm")
    ap.add_argument("--b", required=True, help="candidate arm")
    ap.add_argument("--judge-model", default="sonnet")
    ap.add_argument("--cases", help="comma-separated subset")
    args = ap.parse_args()
    claude = find_claude()
    cases = runner.all_cases()
    out = os.path.abspath(args.out)
    result = {"judge_model": args.judge_model, "a": args.a, "b": args.b, "cases": {},
              "totals": {"a": 0, "b": 0, "tie": 0}, "details": [], "cost_usd": 0.0}
    for case_dir in sorted(glob.glob(os.path.join(out, "runs", "*"))):
        name = os.path.basename(case_dir)
        if args.cases and name not in args.cases.split(","):
            continue
        case = cases.get(name)
        if not case or not case.get("design", True):
            continue
        crit = case.get("judge_criteria") or DEFAULT_CRITERIA
        tally = {"a": 0, "b": 0, "tie": 0}
        for ta in sorted(glob.glob(os.path.join(case_dir, args.a, "t*"))):
            tb = os.path.join(case_dir, args.b, os.path.basename(ta))
            if not os.path.isdir(tb):
                continue
            votes = []
            for first, second in ((ta, tb), (tb, ta)):
                prompt = "\n\n".join([
                    "You are reviewing two independent designs made from the same brief for a "
                    "3D-printable part. Judge the designs, not the writing: look at every render "
                    "(Read the PNG files), skim each source header, and read each hand-off message.",
                    "The brief:\n<brief>\n%s\n</brief>" % case["prompt"],
                    "Criteria, in priority order:\n" + "\n".join("%d. %s" % (i + 1, c) for i, c in enumerate(crit)),
                    design_block("Design 1", first, out), design_block("Design 2", second, out),
                    "Pick the better design overall and per criterion group, or 'tie' if you "
                    "genuinely can't separate them. A longer or more confident hand-off message is "
                    "not evidence of a better design. Keep reasons under 120 words."])
                verdict, cost = ask(claude, args.judge_model, prompt, out)
                result["cost_usd"] += cost
                w = (verdict or {}).get("winner")
                # map "Design 1/2" back to arms for this ordering
                arm = {"1": "a" if first == ta else "b", "2": "b" if first == ta else "a"}.get(w, "tie")
                votes.append(arm)
                result["details"].append({"case": name, "trial": os.path.basename(ta),
                                          "order": "a-first" if first == ta else "b-first",
                                          "verdict": verdict})
            final = votes[0] if votes[0] == votes[1] else "tie"
            tally[final] += 1
            result["totals"][final] += 1
            print("%s %s: %s (votes %s)" % (name, os.path.basename(ta), final, votes))
        result["cases"][name] = tally
    save_json(os.path.join(out, "judge.json"), result)
    print("judge spend ~$%.2f; totals %s" % (result["cost_usd"], result["totals"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
