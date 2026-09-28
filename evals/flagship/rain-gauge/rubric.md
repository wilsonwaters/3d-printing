# Rain gauge: human scoring sheet

Score each row 0-5 after looking at the renders, the build guide and the
source. Anchors: **1** = missing or would not work, **3** = present and
plausible but with a problem you'd have to fix before printing, **5** = you'd
print it as is. Total /30. Record the total and a one-line note per row in
[LEDGER.md](LEDGER.md).

| # | Dimension | What a 5 looks like |
|---|---|---|
| 1 | **Counter** | Four 0-9 dials that carry like an odometer from 0000 to 9999; the carry can't slip or jam at 0999 → 1000. |
| 2 | **Drive** | The tipping bucket drives the counter mechanically, one count per tip, and can't double-count on the bounce or miss a tip at low flow. |
| 3 | **Reset** | A button or knob returns all four dials to zero without disassembly. |
| 4 | **Calibration** | Collector size chosen and justified (200 cm² / Ø159.6, 203 mm / 8 in, or ~150 mm); chamber volume = area (cm²) × mm per tip ÷ 10; gearing makes one units-dial step = 1 mm, and the numbers are stated. |
| 5 | **Printability** | Every part fits the X1C, sits flat, prints without supports; tolerances suit PETG; nothing paper-thin. |
| 6 | **Buildability** | Parts list, print list and assembly steps you could follow; the .scad header lets a later session change it. |

## Print evidence (when you print it)

These outrank everything above. Note them in the ledger's notes column.

- Parts that printed first time / needed a reprint (and why)
- Did the bucket tip cleanly and reset? Measured mL per tip vs design
- Did the counter carry correctly through a full 0-9-0 on each dial?
- Measured calibration: pour a known volume, compare to the dials

## Using the judge instead of (or before) scoring by hand

`evals/bench/judge.py` compares two runs pairwise on the same criteria (see
`case.json` → `judge_criteria`). Before trusting it on this case, score a few
pairs yourself and check the judge agrees with you. The existing Fable,
Opus5.0 and Opus5.0 v2 designs are ready-made pairs for that calibration.
