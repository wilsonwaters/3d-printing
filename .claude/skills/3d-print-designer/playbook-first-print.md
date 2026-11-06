# First Print and Test Fit (lessons learned)

Read this before the first full print of a part that mates with hardware, and again when the user reports back after a print.

## Print a coupon before the part

Before the first full print, offer a cheap slice of the critical interface, so the hardware can be dropped in. For example, the bottom 10 mm of a box with its walls, slots and pads.

- **The case for it:** ten minutes instead of ninety. A coupon of the board's bay would have found the jack's flange screws that stopped a first full base.
- **Material:** print it in whatever is loaded, PLA included. The fit is under test, not the material.
- **Keep it in the model:** add it as a `coupon_*` part value, e.g. the base intersected with a slab. It stays in the model and gets regenerated after every change.

## Review the model against reality

After a print, don't ask "does it fit?". Ask for a structured test fit, built from the model's "Not verified" list:

1. **Seating.** Does each part drop in and sit flat? If not, where does it catch?
2. **Measurements.** One per uncertain dimension (the gap to a wall, a centre by the A/B method), each with the model's value next to it. Say which result means "no change".
3. **Moving parts.** Latches click, flaps move, the lid pulls off with a fingernail, nothing binds.
4. **Hands-on with the lid closed.** Cables and connectors plugged in, buttons pressable.

Write the results into the README (sources and "Not verified") before changing any geometry. Then the next session sees what reality said.

## One batch of fixes, one reprint

Collect every finding before the next print. Change the model once, run the gate, reprint once. Reprinting after each finding costs more than waiting for the whole test fit.

The existing print can often still serve that test fit after a fix by hand. Give the user:

- **Where to cut,** as numbers from a datum the user can find: the outside of a named wall, the underside.
- **What to leave alone,** e.g. a latch groove 1.1 mm away.
- **A tool:**
  - oscillating multitool with a fine-tooth plunge blade at low speed;
  - rotary tool at 5,000–10,000 rpm;
  - knife and file.

  PETG smears at high speed.
- **For carbon-fibre filled plastics:** a mask, a vacuum cleaner, and cutting outdoors.

## Explain with a drawing

When asking for a measurement or explaining a change, send an annotated top view to scale. Show the parts, the changes numbered with a legend, and the measurement arrows with the model's values. A paragraph of coordinates gets misread; a drawing doesn't. Build it as an SVG from the model's own numbers, then render it to PNG for a phone.

## Material choice per part

Name the material per part, not per project:

- **Parts that flex** (latches, flaps, hinges): PETG.
- **Stiff, stable bodies:** PETG-CF or PLA.
- **Fit tests and coupons:** PLA.

Say what changes if the user swaps one in. For example, a PETG-CF lid has stiffer latches and loses the second colour.
