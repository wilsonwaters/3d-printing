# Rain gauge flagship ledger

One row per full run of [task.md](task.md). This is a case study across
models and skill versions, not a statistic: with one or two runs per model,
a difference smaller than the gap between two runs of the same model means
nothing. Record it anyway; the trend over releases is the value.

Measured columns come from the tools, not from the run's own claims:

```sh
# grade the output folder (compiles every part, measures every mesh)
python evals/bench/grade.py "3d-models/<project folder>" --case evals/flagship/rain-gauge --scad "<final>.scad"
# tokens for an interactive run: point at the session file (sub-agents are picked up)
python evals/bench/transcript.py ~/.claude/projects/<project>/<session-id>.jsonl
```

For a harness run (`run.py --cases rain-gauge`) both are in `runs/rain-gauge/<arm>/t1/run.json`.

| Date | Model | Skill | How | Cost $ | Context tok | Wall | Parts (printable) | Gate | Sloped overhang mm² | Flat ceiling mm² | Structure | Asserts | Human /30 | Notes |
|---|---|---|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---|
| 2026-06-28 | unrecorded | pre-2026-07 | interactive | – | – | – | 11 (10) | pass | 456 | 1,157 | 0.85 | 8 | | `Mechanical Rain Gauge` v1: mechanism core only; `bucket` sits 2 mm below z=0 |
| 2026-07-20 | Fable 5 | 2026-07 | interactive, 4 versions | – | – | – | 21 (20) | pass | 12,609 | 18,553 | 0.89 | 17 | | `…Fable` v4; v1 bucket printed, 4 faults fixed in v2 |
| 2026-07-26 | Opus 5 | 2026-07 | interactive | – | – | – | 19 (16) | pass | 12,491 | 8,277 | 0.96 | 50 | | `…Opus5.0` v1; clash checks clear; superseded |
| 2026-08-03 | Opus 5 | 2026-08 | interactive, v2 | – | – | – | 23 (21) | pass | 5,637 | 11,143 | 0.96 | 61 | | `…Opus5.0 v2`; README showcase; fit-test ladder printed 3x, hole comp measured 0.30 |

Backfilled rows were measured on 2026-09-28 with OpenSCAD 2026.09.23 and a
256 mm build volume. Their token cost wasn't recorded at the time; for new
interactive runs, keep the session id so `transcript.py` can recover it.
Overhang and ceiling areas are summed over every printable part (print
plates included), so they compare designs of similar part count; they are
not "needs supports" verdicts, since bridges and designed-in chamfers land
in the same bucket.
