#!/bin/bash
# Rebuild the Bambu Studio projects after a model change.  usage: OPENSCAD=/path/to/openscad calc/make-3mf.sh /path/to/make-bambu-3mf.py
T=${1:?path to make-bambu-3mf.py}; O=${OPENSCAD:-openscad}; cd "$(dirname "$0")/.."
mk(){ part=$1; shift; python3 "$T" --scad mechanical-rain-gauge.scad -D "part=\"$part\"" --printer X1C --openscad "$O" --supports off --scatter-seed 7 --out "mechanical-rain-gauge-$part.3mf" "$@" 2>&1 | grep -E "verify|WARN|rror" | sed "s/^/$part: /"; }
G="--layer-height 0.2 --walls 4 --infill 20 --infill-pattern gyroid"
mk collector $G --brim outer_only --set brim_width=8
mk base $G
mk bucket --layer-height 0.2 --walls 4 --infill 100
mk anchor --layer-height 0.2 --walls 4 --infill 100
mk back_plate $G
mk dial_plate $G
mk dial_card $G
mk slide $G
mk plate_register --layer-height 0.16 --walls 4 --infill 100
