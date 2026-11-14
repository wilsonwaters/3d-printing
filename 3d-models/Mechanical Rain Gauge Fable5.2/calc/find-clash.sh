#!/bin/bash
# List which element pairs intersect at a pose.  usage: find-clash.sh "[0,-21,0,0]"
# Element numbers are the elem(i) indices in rg-assembly.scad.
OSC=${OPENSCAD:-openscad}; P=${1:-"[0,-21,0,0]"}; N=27
cd "$(dirname "$0")/.."
for i in $(seq 0 $((N-2))); do for j in $(seq $((i+1)) $((N-1))); do
  out=$($OSC -o /tmp/pair.stl -D 'part="check_pair"' -D "ci=$i" -D "cj=$j" -D "cP=$P" mechanical-rain-gauge.scad 2>&1)
  if ! echo "$out" | grep -q "top level object is empty"; then
    echo "CLASH $i $j $(echo "$out" | grep -E "Vertices" | tr -s ' ')"; fi
done; done
