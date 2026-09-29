# A/B history: claude-opus-5-5

Generated from `runs.jsonl` by `python evals/bench/history.py render`; don't edit by hand. Numbers compare only within this model, and only at the same effort. The skill column is `ref` sha · content hash (same hash = same skill text).

## Skill A/B comparisons

None yet: run `run.py` with two arms on this model.

## Per case over time

Newest first. Median $, context and calls are per run; pass is passes/trials.

### asks-printer

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 2/3 | 0.67 | $0.43 | 162,959 | 4 | 36 | 0% | 39,112 | asks_printer x1, is_a_question x1, no_premature_scad x1 |
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 1.00 | $0.18 | 116,740 | 3 | 15 | 0% | 39,112 |  |

### cable-clip-3mf

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 2/3 | 0.97 | $7.17 | 9,952,185 | 78 | 1,990 | 13% | 39,112 | bambu_3mf x1 |

### caster-plug

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 1/3 | 0.61 | $4.54 (3 est.) | 1,620,932 | 16 | 2,700 | 2% | 39,112 | file_structure x1, fits_build_volume x1, gate x1, has_asserts x1, manifold x1, on_plate x1, parts_min x1, ran_openscad x1, shells_max x1, small_part x1, spawned_review x1, stl_exported x2, support_free x2, timeout x3 |
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 0.91 | $3.22 | 2,749,432 | 34 | 1,309 | 52% | 39,112 | support_free x1 |

### pi4-case

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 1/3 | 0.94 | $9.09 (1 est.) | 7,174,097 | 55 | 3,454 | 39% | 39,112 | stl_exported x2, timeout x1 |

### pot-stand

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 3/3 | 0.97 | $3.33 | 2,802,487 | 32 | 1,009 | 28% | 39,112 | covers_base x1 |

### pot-stand-edit

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 3/3 | 1.00 | $3.67 | 4,760,676 | 47 | 778 | 22% | 39,112 |  |

### review-recall

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 3/3 | 0.79 | $2.93 | 2,502,507 | 31 | 700 | 42% | 39,112 | coincident x3, elephant_foot x2 |
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 1.00 | $1.49 | 1,353,747 | 23 | 596 | 69% | 39,112 |  |
