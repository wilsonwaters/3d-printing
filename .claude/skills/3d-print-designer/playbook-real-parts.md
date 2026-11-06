# Designing Around Real Parts (lessons learned)

Read this when the part holds, clamps or mates with something that exists: a board, a module, a connector, a screw. A drawing is where you start; the real part is what decides. Every rule below cost a reprint once.

## Before modelling: ask for the real part

- **Ask for measurements, not just the drawing:** the outline, the hole spacing, the height, and everything that sticks out on the faces the design touches. Drawings leave out screws (corner screws on the top face, two screws in an SMA jack's flange), posts inside open shells, connector housings and labels. Ask "what sticks out on the side facing the wall, the floor, the lid?"
- **Ask for square-on photos** with a ruler or a known pitch in frame. A 2.54 mm header is a good scale. Never take geometry from an oblique photo: perspective moved a clamp by 1.5 mm once.
- **Ask what varies between batches,** such as Dupont housing length (12 or 14 mm), wire diameter and screw head height. Then either design for the measured value with a tolerance, or make it a parameter and export one variant per value.
- **Record each measured value** with its instrument and uncertainty (ruler ±0.5 mm, caliper ±0.05 mm). It goes in the model header and in the README's sources.

## Measuring a centre with a ruler: the A/B method

You can't measure a centre directly, whether it's a jack's axis or a hole. Instead, measure from one datum edge to the near side (A) and to the far side (B):

- The centre is at (A + B) / 2.
- B − A should equal the feature's known diameter. The gap between the two is the measurement's uncertainty: 5 mm measured on a 6.35 mm thread means about ±0.5 mm.

Send the user a drawing that marks the datum, A and B (playbook-first-print.md, "Explain with a drawing").

## Locate on what you measured

- **Use measured surfaces.** Locate a part by its outline against walls and stops, with about 0.3 mm of play per side. Don't locate it with pins in holes you haven't seen from that side. Pins of 2.8 mm in 3.1 mm holes (0.15 mm per side) missed on a first print, because the frame under the holes wasn't as drawn.
- **One master per axis.** If a jack in a slot and a wall both locate the same axis, they fight. Give one of them generous clearance.
- **Sweep the part across its play.** Run the clash checks with the part shifted to each end of its play, not only at the nominal position, and report the margin, e.g. "the lid's tubes clear the screws from −0.4 to +0.5 mm".
- **Model the unknown-but-present.** Model a feature you know is there but can't pin down (a screw head) as a volume swept over its measured range. Add a clash check for the path the part takes on the way in: a module dropped in from above drags its protrusions down the wall, so the wall needs a groove or a slot all the way to the rim.

## Slender features break

- **Freestanding plates and posts:** a plate or post more than about 10× taller than it is thick, joined only at its foot, snaps in handling (a 1.35 mm stop 26 mm tall). Tie it to a neighbour with a web, gusset or rib, or thicken it. Assert height/thickness ≤ 10 for anything that stands alone.
- **Long fingers on a narrow base** (latch tabs, tongues, hooks) need a root fillet or gusset, and should flex in the layer plane where they can.

## Supporting a part with an open underside

A module with an open shell underneath rests on its rim; its posts, connectors and bosses sit inside. Supports should carry the rim and leave the inside free. To check, ask the user to lay the part open side down on a flat table: does it rock or stand on something?
