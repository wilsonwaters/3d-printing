#!/usr/bin/env python3
"""Token, cost and behaviour metrics from a Claude Code transcript.

Reads either the stream-json a `claude -p --output-format stream-json
--verbose` run prints, or the session .jsonl files an interactive session
leaves under ~/.claude/projects/<project>/ (pass the session file and its
subagents/*.jsonl, which are picked up automatically, so the review sub-agent
is counted).

Two traps this handles:
  * A result event's `usage` covers the last top-level turn only. The totals
    that include sub-agents are `modelUsage` and `total_cost_usd` on the LAST
    result event (a run that waits on a background sub-agent emits several).
  * Each assistant message is streamed as several events that repeat the same
    usage, so per-call numbers are de-duplicated by message id.

  python evals/bench/transcript.py run.jsonl [more.jsonl ...] [--json out.json]
"""

import argparse
import collections
import json
import os
import re
import sys

SKILL_MARK = "3d-print-designer"
IMAGE_RE = re.compile(r"\.(png|jpe?g|gif|webp)$", re.I)
# An OpenSCAD compile/render: the binary (or the skill's $OSCAD variable) and a
# .scad on one line. Excludes `cat openscad-reference.md`.
OPENSCAD_CMD = r"(?im)^.*(openscad(\.exe|\.appimage)?\b(?!-reference)|\$\{?oscad\b).*\.scad"
OPENSCAD_RE = re.compile(OPENSCAD_CMD)
MD_NAME_RE = re.compile(r"([A-Za-z0-9_-]+\.md)\b")


def expand(paths):
    """A session file brings its sub-agent transcripts (<session>/subagents/*.jsonl)."""
    out = []
    for p in paths:
        out.append(p)
        sub = os.path.join(os.path.splitext(p)[0], "subagents")
        if p.endswith(".jsonl") and os.path.isdir(sub):
            out.extend(os.path.join(sub, f) for f in sorted(os.listdir(sub)) if f.endswith(".jsonl"))
    return list(dict.fromkeys(out))


def _events(paths):
    for path in paths:
        sub_file = os.sep + "subagents" + os.sep in os.path.abspath(path)
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line.startswith("{"):
                    continue
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                if sub_file:
                    e.setdefault("isSidechain", True)
                yield e


def _num(d, *keys):
    return sum(int(d.get(k) or 0) for k in keys)


def analyse(paths, skill_root=None):
    calls = {}  # message id -> (is_sub, model, usage)
    tools = collections.Counter()
    tool_inputs = {}
    subagent_ids = set()
    results = []
    final_text = ""
    last_main_text = ""
    for e in _events(paths):
        t = e.get("type")
        if t == "result":
            results.append(e)
            if isinstance(e.get("result"), str):
                final_text = e["result"]
            continue
        if t != "assistant":
            continue
        msg = e.get("message") or {}
        is_sub = bool(e.get("parent_tool_use_id") or e.get("isSidechain"))
        mid = msg.get("id") or e.get("uuid")
        if msg.get("usage"):
            calls[mid] = (is_sub, msg.get("model"), msg["usage"])
        for block in msg.get("content") or []:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use" and block.get("id") not in tool_inputs:
                tool_inputs[block.get("id")] = (block.get("name"), block.get("input") or {}, is_sub)
            elif block.get("type") == "text" and not is_sub:
                last_main_text = block.get("text") or last_main_text

    reads = collections.Counter()
    skill_read_bytes = 0
    openscad_calls = image_reads = 0
    bash_cmds = []
    def skill_file(base, path=None):
        nonlocal skill_read_bytes
        reads[base] += 1
        for cand in (path, os.path.join(skill_root, base) if skill_root else None):
            if cand and os.path.isfile(cand):
                skill_read_bytes += os.path.getsize(cand)
                return

    for name, inp, is_sub in tool_inputs.values():
        tools[name] += 1
        if name in ("Agent", "Task"):
            subagent_ids.add(json.dumps(inp, sort_keys=True)[:200])
        if name == "Skill" and SKILL_MARK in str(inp.get("skill", "")):
            skill_file("SKILL.md")  # the Skill tool injects SKILL.md itself
        if name == "Read":
            fp = str(inp.get("file_path", ""))
            if IMAGE_RE.search(fp):
                image_reads += 1
            norm = fp.replace("\\", "/")
            if SKILL_MARK in norm or (skill_root and fp.startswith(skill_root)):
                skill_file(norm.rsplit("/", 1)[-1], fp)
        elif name == "Bash":
            cmd = str(inp.get("command", ""))
            bash_cmds.append(cmd)
            if OPENSCAD_RE.search(cmd):
                openscad_calls += 1
            # references are often read with cat/sed/head from inside the skill dir
            if SKILL_MARK in cmd or (skill_root and skill_root in cmd):
                if re.search(r"\b(cat|head|tail|sed|less|more|type|Get-Content)\b", cmd):
                    for base in MD_NAME_RE.findall(cmd):
                        skill_file(base)

    def bucket(sel):
        b = {"api_calls": 0, "input": 0, "cache_read": 0, "cache_write": 0, "output": 0,
             "max_context": 0}
        for is_sub, _model, u in calls.values():
            if is_sub != sel:
                continue
            ctx = _num(u, "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")
            b["api_calls"] += 1
            b["input"] += _num(u, "input_tokens")
            b["cache_read"] += _num(u, "cache_read_input_tokens")
            b["cache_write"] += _num(u, "cache_creation_input_tokens")
            b["output"] += _num(u, "output_tokens")  # streamed counts can undercount
            b["max_context"] = max(b["max_context"], ctx)
        b["context_volume"] = b["input"] + b["cache_read"] + b["cache_write"]
        return b

    main, sub = bucket(False), bucket(True)
    cw_1h = sum(int(((u.get("cache_creation") or {}).get("ephemeral_1h_input_tokens")) or 0)
                for _s, _m, u in calls.values())
    last = results[-1] if results else {}
    model_usage = last.get("modelUsage") or {}
    if model_usage:
        tok = {
            "input": sum(_num(m, "inputTokens") for m in model_usage.values()),
            "output": sum(_num(m, "outputTokens") for m in model_usage.values()),
            "cache_read": sum(_num(m, "cacheReadInputTokens") for m in model_usage.values()),
            "cache_write": sum(_num(m, "cacheCreationInputTokens") for m in model_usage.values()),
            "thinking": sum(_num(m, "thinkingTokens") for m in model_usage.values()),
        }
    else:  # interactive transcripts carry no totals: sum the de-duplicated calls
        tok = {k: main[k] + sub[k] for k in ("input", "output", "cache_read", "cache_write")}
        tok["thinking"] = None
    tok["context_volume"] = tok["input"] + tok["cache_read"] + tok["cache_write"]
    # Where the money goes, using list-price ratios to input (write 1.25x for the
    # 5-minute cache, 2x for 1-hour; read 0.1x; output 5x). Approximate by design:
    # it says which lever matters (thinking/output vs loaded text), not the bill.
    cw_1h = min(cw_1h, tok["cache_write"])
    w = {"output": 5.0 * tok["output"], "cache_write": 1.25 * (tok["cache_write"] - cw_1h) + 2.0 * cw_1h,
         "cache_read": 0.1 * tok["cache_read"], "input": 1.0 * tok["input"]}
    total_w = sum(w.values()) or 1.0
    cost_split = {k: round(v / total_w, 3) for k, v in w.items()}
    costs = [r.get("total_cost_usd") for r in results if r.get("total_cost_usd") is not None]
    return {
        "cost_usd": round(max(costs), 4) if costs else None,
        "tokens": tok,
        "cost_split": cost_split,
        "by_model": {k: {"cost_usd": v.get("costUSD"), "output": v.get("outputTokens"),
                         "cache_read": v.get("cacheReadInputTokens"),
                         "cache_write": v.get("cacheCreationInputTokens")}
                     for k, v in model_usage.items()},
        "main": main,
        "subagents": dict(sub, spawned=tools.get("Agent", 0) + tools.get("Task", 0)),
        "subagent_share_of_context": (round(sub["context_volume"] /
                                            (main["context_volume"] + sub["context_volume"]), 3)
                                      if main["context_volume"] + sub["context_volume"] else None),
        "api_calls": main["api_calls"] + sub["api_calls"],
        "num_turns": sum(int(r.get("num_turns") or 0) for r in results) or None,
        "duration_api_s": round(sum(float(r.get("duration_api_ms") or 0) for r in results) / 1000, 1),
        "tools": dict(tools.most_common()),
        "openscad_calls": openscad_calls,
        "image_reads": image_reads,
        "skill_invoked": tools.get("Skill", 0) > 0 or bool(reads),
        "skill_files_read": dict(reads),
        "skill_read_bytes": skill_read_bytes,
        "web": {"search": tools.get("WebSearch", 0), "fetch": tools.get("WebFetch", 0)},
        "terminal_reason": last.get("terminal_reason") or last.get("subtype"),
        "is_error": bool(last.get("is_error")),
        "permission_denials": len(last.get("permission_denials") or []),
        "final_text": final_text or last_main_text,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="+")
    ap.add_argument("--json")
    args = ap.parse_args()
    m = analyse(expand(args.paths))
    text = m.pop("final_text")
    if args.json:
        with open(args.json, "w") as f:
            json.dump(m, f, indent=2)
    t = m["tokens"]
    print("cost $%s | context %s (read %s, write %s, uncached %s) | output %s | calls %d (sub %d) | "
          "tools %s" % (m["cost_usd"], t["context_volume"], t["cache_read"], t["cache_write"],
                        t["input"], t["output"], m["api_calls"], m["subagents"]["api_calls"],
                        sum(m["tools"].values())))
    cs = m["cost_split"]
    print("cost split (approx): output+thinking %.0f%%, cache writes %.0f%%, cache reads %.0f%%" % (
        100 * cs["output"], 100 * cs["cache_write"], 100 * cs["cache_read"]))
    print("skill files read: %s" % (", ".join("%s x%d" % kv for kv in m["skill_files_read"].items()) or "none"))
    print("openscad calls %d, images viewed %d, sub-agents %d" % (
        m["openscad_calls"], m["image_reads"], m["subagents"]["spawned"]))
    if text:
        print("--- final message (first 400 chars) ---\n" + text[:400])
    return 0


if __name__ == "__main__":
    sys.exit(main())
