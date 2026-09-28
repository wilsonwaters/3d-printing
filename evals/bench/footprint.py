#!/usr/bin/env python3
"""Static context cost of the skill: free, deterministic, runs on every commit.

What a skill costs before the model does any work is the text it makes the
model read. This reports, per file and per load path (evals/footprint-profiles.json):

  always-on   the frontmatter name + description, paid in every session
  profiles    the files a typical run reads (e.g. author_petg, reviewer)
  duplication text repeated across files (paid twice when both are loaded)
  lint        broken links/anchors, orphan files, references nested more than
              one level below SKILL.md, SKILL.md over 500 lines, frontmatter

Token counts are estimates (bytes / 2.8, calibrated to `claude plugin details`,
which reports ~9.4k for the 26.3 KB SKILL.md). Pass --exact with
ANTHROPIC_API_KEY set to use the free count_tokens endpoint instead.

  python evals/bench/footprint.py                 # report
  python evals/bench/footprint.py --check         # CI: fail if a budget grew >2%
  python evals/bench/footprint.py --update        # accept current numbers as baseline
  python evals/bench/footprint.py --skill-dir DIR # measure another copy (e.g. a git worktree)
"""

import argparse
import collections
import json
import os
import re
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import EVALS_DIR, SKILL_DIR, load_json, read_text, save_json  # noqa: E402

BYTES_PER_TOKEN = 2.8
BASELINE = os.path.join(EVALS_DIR, "baselines", "footprint.json")
PROFILES = os.path.join(EVALS_DIR, "footprint-profiles.json")
SHINGLE = 12  # words; a repeated 12-word run is almost never coincidence


def estimate(text, exact_model=None):
    if exact_model:
        req = urllib.request.Request(
            "https://api.anthropic.com/v1/messages/count_tokens",
            data=json.dumps({"model": exact_model,
                             "messages": [{"role": "user", "content": text or "."}]}).encode(),
            headers={"x-api-key": os.environ["ANTHROPIC_API_KEY"],
                     "anthropic-version": "2023-06-01", "content-type": "application/json"})
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)["input_tokens"]
    return int(round(len(text.encode("utf-8")) / BYTES_PER_TOKEN))


def split_frontmatter(text):
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.S)
    if not m:
        return {}, "", text
    fm = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"^(\w[\w-]*):\s*(.*)$", line)
        if mm:
            fm[mm.group(1)] = mm.group(2).strip().strip("'\"")
    return fm, m.group(0), text[m.end():]


def slug(heading):
    s = heading.strip().lower()
    s = re.sub(r"[^\w\- ]", "", s)
    return s.replace(" ", "-")


def anchors(text):
    return {slug(h) for h in re.findall(r"^#{1,6}\s+(.+?)\s*#*$", text, re.M)}


def links(text):
    code_free = re.sub(r"```.*?```", "", text, flags=re.S)
    return re.findall(r"\[[^\]]*\]\(([^)\s]+)\)", code_free)


def duplication(texts):
    """Shingle-level repetition within and across files."""
    where = collections.defaultdict(list)
    words_by_file = {}
    for name, text in texts.items():
        words = re.findall(r"[a-z0-9]+", text.lower())
        words_by_file[name] = words
        for i in range(len(words) - SHINGLE + 1):
            where[" ".join(words[i:i + SHINGLE])].append((name, i))
    per_file, passages = {}, collections.Counter()
    for name, words in words_by_file.items():
        n = max(1, len(words) - SHINGLE + 1)
        covered = set()
        for i in range(len(words) - SHINGLE + 1):
            key = " ".join(words[i:i + SHINGLE])
            if len(where[key]) > 1:
                covered.update(range(i, i + SHINGLE))
                files = tuple(sorted({f for f, _ in where[key]}))
                passages[(files, key)] += 1
        per_file[name] = round(100.0 * len(covered) / max(1, len(words)), 1)
    # collapse overlapping shingles into one row per file-set, biggest first
    groups = {}
    for (files, key), c in passages.items():
        g = groups.setdefault(files, {"files": list(files), "example": key, "shingles": 0})
        g["shingles"] += c
    top = sorted(groups.values(), key=lambda g: -g["shingles"])[:12]
    return per_file, top


def measure(skill_dir, exact_model=None):
    files = sorted(f for f in os.listdir(skill_dir) if f.endswith(".md"))
    texts = {f: read_text(os.path.join(skill_dir, f)) for f in files}
    fm, fm_raw, body = split_frontmatter(texts.get("SKILL.md", ""))
    per_file = {}
    for f in files:
        per_file[f] = {"bytes": len(texts[f].encode("utf-8")), "lines": texts[f].count("\n"),
                       "tokens": estimate(texts[f], exact_model)}
    scripts = sorted(f for f in os.listdir(skill_dir) if f.endswith((".py", ".sh")))
    always_on = estimate("%s: %s" % (fm.get("name", ""), fm.get("description", "")), exact_model)

    prof_cfg = load_json(PROFILES, {"profiles": {}})["profiles"]
    profiles, lint = {}, []
    for name, members in prof_cfg.items():
        missing = [m for m in members if m not in per_file]
        if missing:
            lint.append(("error", "profile %s lists missing file(s): %s" % (name, ", ".join(missing))))
        profiles[name] = sum(per_file[m]["tokens"] for m in members if m in per_file)

    # --- lint ---
    if not fm:
        lint.append(("error", "SKILL.md has no frontmatter"))
    else:
        if fm.get("name") != os.path.basename(os.path.normpath(skill_dir)):
            lint.append(("warn", "frontmatter name %r != directory name" % fm.get("name")))
        if len(fm.get("description", "")) > 1024:
            lint.append(("error", "description is %d chars (limit 1024)" % len(fm["description"])))
    if "SKILL.md" in texts and texts["SKILL.md"].count("\n") > 500:
        lint.append(("warn", "SKILL.md is %d lines (best practice: under 500)"
                     % texts["SKILL.md"].count("\n")))
    graph = {}
    for f, text in texts.items():
        graph[f] = set()
        for target in links(text):
            if re.match(r"^[a-z]+://|^mailto:", target):
                continue
            path, _, anchor = target.partition("#")
            dest = path or f
            if path and not os.path.exists(os.path.join(skill_dir, path)):
                lint.append(("error", "%s links to missing %s" % (f, path)))
                continue
            if dest.endswith(".md"):
                graph[f].add(dest)
                if anchor and anchor not in anchors(texts.get(dest, "")):
                    lint.append(("error", "%s links to missing anchor %s#%s" % (f, dest, anchor)))
    direct = graph.get("SKILL.md", set())
    for f in files:
        if f == "SKILL.md" or f in direct:
            continue
        via = sorted(g for g, outs in graph.items() if f in outs)
        lint.append(("warn", "%s is not linked from SKILL.md%s" % (
            f, " (only via %s: nested references may be read partially)" % ", ".join(via)
            if via else " (orphan)")))
    for s in scripts:
        if not any(s in t for t in texts.values()):
            lint.append(("warn", "script %s is never mentioned" % s))

    dup_pct, dup_top = duplication(texts)
    for f in per_file:
        per_file[f]["dup_pct"] = dup_pct.get(f, 0.0)
    return {
        "skill_dir": os.path.abspath(skill_dir),
        "estimator": "count_tokens:%s" % exact_model if exact_model else "bytes/%.1f" % BYTES_PER_TOKEN,
        "always_on": always_on,
        "description_chars": len(fm.get("description", "")),
        "total_md_tokens": sum(v["tokens"] for v in per_file.values()),
        "profiles": profiles,
        "files": per_file,
        "scripts": {s: os.path.getsize(os.path.join(skill_dir, s)) for s in scripts},
        "duplication": dup_top,
        "lint": [{"level": lvl, "msg": msg} for lvl, msg in lint],
    }


def budgets(m):
    out = {"always_on": m["always_on"], "total_md_tokens": m["total_md_tokens"]}
    out.update({"profile:" + k: v for k, v in m["profiles"].items()})
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--skill-dir", default=SKILL_DIR)
    ap.add_argument("--json", help="write the full measurement here")
    ap.add_argument("--check", action="store_true", help="exit 1 if any budget grew past tolerance")
    ap.add_argument("--update", action="store_true", help="write the baseline")
    ap.add_argument("--tolerance", type=float, default=0.02)
    ap.add_argument("--exact", metavar="MODEL", help="use count_tokens with this model id")
    args = ap.parse_args()

    m = measure(args.skill_dir, args.exact)
    if args.json:
        save_json(args.json, m)
    base = load_json(BASELINE, {}).get("budgets", {})
    cur = budgets(m)

    print("## Skill footprint (%s)\n" % m["estimator"])
    print("| budget | tokens | baseline | change |\n|---|---:|---:|---:|")
    grew = []
    for k, v in cur.items():
        b = base.get(k)
        ch = "" if not b else "%+.1f%%" % (100.0 * (v - b) / b)
        if b and v > b * (1 + args.tolerance):
            grew.append(k)
        print("| %s | %d | %s | %s |" % (k, v, b if b else "-", ch))
    print("\n| file | tokens | lines | repeated elsewhere |\n|---|---:|---:|---:|")
    for f, v in sorted(m["files"].items(), key=lambda kv: -kv[1]["tokens"]):
        print("| %s | %d | %d | %.0f%% |" % (f, v["tokens"], v["lines"], v["dup_pct"]))
    if m["duplication"]:
        print("\nMost-repeated passages (12-word runs found in more than one place):")
        for d in m["duplication"][:8]:
            print("- %s (%d runs): \"%s ...\"" % (" + ".join(d["files"]), d["shingles"], d["example"]))
    if m["lint"]:
        print("\nLint:")
        for item in m["lint"]:
            print("- %s: %s" % (item["level"].upper(), item["msg"]))

    errors = [x for x in m["lint"] if x["level"] == "error"]
    if args.update:
        save_json(BASELINE, {"estimator": m["estimator"], "budgets": cur})
        print("\nBaseline written to %s" % os.path.relpath(BASELINE))
        return 0
    if args.check:
        if grew:
            print("\nFAIL: grew past +%.0f%%: %s. If intended, run with --update and commit the "
                  "baseline with the change." % (100 * args.tolerance, ", ".join(grew)))
        shrank = [k for k, v in cur.items() if base.get(k) and v < base[k] * (1 - args.tolerance)]
        if shrank and not grew:
            print("\nShrank: %s. Run --update to lock in the saving." % ", ".join(shrank))
        return 1 if grew or errors else 0
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
