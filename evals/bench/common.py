"""Shared helpers for the skill bench. Python 3.8+ standard library only."""

import glob
import json
import os
import re
import shutil
import subprocess
import sys

BENCH_DIR = os.path.dirname(os.path.abspath(__file__))
EVALS_DIR = os.path.dirname(BENCH_DIR)
REPO_ROOT = os.path.dirname(EVALS_DIR)
SKILL_REL = os.path.join(".claude", "skills", "3d-print-designer")
SKILL_DIR = os.path.join(REPO_ROOT, SKILL_REL)


def load_json(path, default=None):
    if not os.path.exists(path):
        return default
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save_json(path, data):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=False)
        f.write("\n")


def read_text(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


_FOUND = {}


def find_openscad():
    """Resolve the newest OpenSCAD binary: $OPENSCAD, else the newest of PATH
    and the usual install locations (a nightly beats 2021.01)."""
    env = os.environ.get("OPENSCAD")
    if env:
        return env
    if "bin" in _FOUND:
        return _FOUND["bin"]
    candidates = [shutil.which(n) for n in ("openscad-nightly", "openscad")]
    for pat in (r"C:\Program Files\OpenSCAD*\openscad.exe",
                r"C:\Program Files (x86)\OpenSCAD*\openscad.exe",
                "/Applications/OpenSCAD*.app/Contents/MacOS/OpenSCAD"):
        candidates.extend(glob.glob(pat))
    ranked = []
    for p in set(c for c in candidates if c and os.path.isfile(c)):
        v = openscad_version(p)
        if v:
            ranked.append((tuple(int(x) for x in v.split(".")), p))
    _FOUND["bin"] = max(ranked)[1] if ranked else None
    return _FOUND["bin"]


def openscad_version(binary):
    try:
        out = subprocess.run([binary, "--version"], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        return None
    m = re.search(r"(\d{4}\.\d{2}(?:\.\d{2})?)", out.stdout + out.stderr)
    return m.group(1) if m else None


def find_claude():
    return os.environ.get("CLAUDE_BIN") or shutil.which("claude")


def die(msg, code=2):
    print(msg, file=sys.stderr)
    sys.exit(code)
