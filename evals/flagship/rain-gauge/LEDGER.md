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

### Measuring an interactive run from inside its own chat

Paste this into the chat that made the design. The first line is a marker:
`--stop-at` drops everything from that message on, so the measuring isn't
counted. Interactive transcripts don't record dollars, so the cost column
stays "–" unless you add the figure `/cost` shows you.

```text
LEDGER-CUTOFF-RG — measure this session's rain gauge run for the eval ledger in
evals/flagship/rain-gauge/LEDGER.md. Don't change any design files.

1. Tools: if evals/bench/transcript.py exists in this checkout, set T=. Otherwise
   run `git fetch origin main` and `git worktree add --detach ../eval-tools origin/main`,
   set T=../eval-tools, and remove it with `git worktree remove ../eval-tools` when
   you're done.
2. Find this session's transcript: the .jsonl under ~/.claude/projects/ containing
   "LEDGER-CUTOFF-RG" (grep -rl). If the design spanned earlier sessions (resumed or
   restarted), also include the session files containing "tipping bucket mechanism
   to mechanically turn the dials".
3. Run: python $T/evals/bench/transcript.py <session files> --stop-at LEDGER-CUTOFF-RG --json tokens.json
   (write tokens.json and grade.json to a temp dir, not the repo)
4. Run: python $T/evals/bench/grade.py "<this project's folder>" --case $T/evals/flagship/rain-gauge
   --scad "<final .scad file name>" --json grade.json
   It needs the OpenSCAD nightly; set OPENSCAD=<path to openscad.exe> if it isn't found.
5. Skill version: git log -1 --format=%h --before="<first timestamp from step 3>" -- .claude/skills
6. Reply with the full output of steps 3 and 4, then one ledger row with these columns:
   Date | Model | Skill | How | Cost $ | Context tok | Wall | Parts (printable) | Gate |
   Sloped overhang mm² | Flat ceiling mm² | Structure | Asserts | Human /30 | Notes
   Take Model from "models:", Context tok from "context", Wall as the elapsed span
   (it includes time waiting on me), and the design columns from grade.json "quality".
   Leave Cost $ as "–" and Human /30 blank; I score that from the rubric. In Notes,
   give the number of design versions, anything printed or test-fitted, and known
   open issues.
```

| Date | Model | Skill | How | Cost $ | Context tok | Wall | Parts (printable) | Gate | Sloped overhang mm² | Flat ceiling mm² | Structure | Asserts | Human /30 | Notes |
|---|---|---|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---|
| 2026-06-28 | unrecorded | pre-2026-07 | interactive | – | – | – | 11 (10) | pass | 456 | 1,157 | 0.85 | 8 | | `Mechanical Rain Gauge` v1: mechanism core only; `bucket` sits 2 mm below z=0 |
| 2026-07-20 | Fable 5 | 2026-07 | interactive, 4 versions | – | – | – | 21 (18) | pass | 12,269 | 14,138 | 0.89 | 17 | | `…Fable` v4; v1 bucket printed, 4 faults fixed in v2 |
| 2026-07-26 | Opus 5 | 2026-07 | interactive | – | – | – | 19 (16) | pass | 12,491 | 8,277 | 0.96 | 50 | | `…Opus5.0` v1; clash checks clear; superseded |
| 2026-08-03 | Opus 5 | 2026-08 | interactive, v2 | – | – | – | 23 (19) | pass | 4,824 | 6,740 | 0.96 | 61 | | `…Opus5.0 v2`; README showcase; fit-test ladder printed 3x, hole comp measured 0.30 |
| 2026-09-28 | claude-opus-5-5 (+ claude-fable-5-1 reviews) | f268aea | interactive, 5 sub-agents | – | 152,406,860 | 68 h 40 m | 29 (24) | pass | 396 | 6,044 | 0.89 | 54 | | `…Opus5.5` v1: 200 cm² collector, face-ratchet drive, heart-cam reset with cam-driven lock bolt; 3 design versions in one v1 (draft + two review rounds); nothing printed or test-fitted. Open: bucket thrust-boss relief not modelled (208 mm² of the sloped overhang), screen inner roof at 47°; tip volume, pointer grip, reset reliability and return-leaf creep need a test print. 526 calls, 1.14 M output tokens |

Backfilled rows were measured on 2026-09-28 with OpenSCAD 2026.09.23 and a
256 mm build volume. Their token cost wasn't recorded at the time; for new
interactive runs, keep the session id so `transcript.py` can recover it.
Overhang and ceiling areas are summed over every printable part (print-plate
layouts left out, so nothing is counted twice), so they compare designs of
similar part count; they are not "needs supports" verdicts, since bridges and
designed-in chamfers land in the same bucket.
