#!/usr/bin/env python3
"""Render fixed-camera views of a model for the judge and for human review.

The harness renders these itself, with the same cameras and image size for
every run, so two designs are compared on equal terms (and not on whatever
views the agent chose to show). 768x576 costs ~560 image tokens per view.

  python evals/bench/render.py MODEL.scad OUT_DIR [--max-parts 8]
"""

import argparse
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import find_openscad, read_text  # noqa: E402
from scadcheck import NON_PRINT_RE, discover_parts  # noqa: E402

SIZE = "768,576"
VIEWS = {  # gimbal rotation (x, y, z); --viewall fits the distance
    "iso": "55,0,25",
    "front": "90,0,0",
    "top": "0,0,0",
    "back_iso": "55,0,205",
}


def render(binary, scad, part, view, out, timeout=600):
    cmd = [binary, "--render", "--viewall", "--autocenter", "--imgsize=" + SIZE,
           "--colorscheme=Tomorrow", "--camera=0,0,0,%s,0" % VIEWS[view], "-o", out]
    if part is not None:
        cmd += ["-D", 'part="%s"' % part]
    cmd.append(os.path.abspath(scad))
    try:
        subprocess.run(cmd, capture_output=True, timeout=timeout,
                       cwd=os.path.dirname(os.path.abspath(scad)))
    except subprocess.TimeoutExpired:
        return None
    return out if os.path.exists(out) and os.path.getsize(out) > 0 else None


def render_views(scad, outdir, max_parts=8, binary=None):
    """Default (usually the assembly) from four sides, plus an iso of each printable part."""
    binary = binary or find_openscad()
    if not binary:
        return []
    os.makedirs(outdir, exist_ok=True)
    parts = discover_parts(read_text(scad))
    default = parts[0] if parts else None
    made = []
    for view in VIEWS:
        p = render(binary, scad, default, view, os.path.join(outdir, "default_%s.png" % view))
        if p:
            made.append(p)
    printable = [p for p in parts if not NON_PRINT_RE.search(p)][:max_parts]
    for part in printable:
        if part == default:
            continue
        tag = re.sub(r"[^A-Za-z0-9_.-]+", "_", part)
        p = render(binary, scad, part, "iso", os.path.join(outdir, "part_%s_iso.png" % tag))
        if p:
            made.append(p)
    return made


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("scad")
    ap.add_argument("outdir")
    ap.add_argument("--max-parts", type=int, default=8)
    args = ap.parse_args()
    for p in render_views(args.scad, args.outdir, args.max_parts):
        print(p)


if __name__ == "__main__":
    main()
