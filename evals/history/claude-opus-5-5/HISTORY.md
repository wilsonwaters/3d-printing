# A/B history: claude-opus-5-5

Generated from `runs.jsonl` by `python evals/bench/history.py render`; don't edit by hand. Numbers compare only within this model, and only at the same effort. The skill column is `ref` sha · content hash (same hash = same skill text).

## Skill A/B comparisons

| Date | Suite | Change | Effort | Base → Cand | Cases × trials | Pass rate | Check score Δ | Cost ratio [95% CI] | Context ratio [95% CI] | Judge cand/base/tie |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | skill review: gate + 3MF tools, 3MF by default, Sonnet/Fable reviews, leaner refs | xhigh | `origin/main` 2d8f6e1 · 1d09abd8d4 → `c76ad10` c76ad10 · 344f91ff10 | 7 × 3 | 0.67 → 0.81 | +0.20 [+0.14, +0.28] better | x0.68 [0.61-0.77] lower | x0.46 [0.36-0.59] lower | - |

## Per case over time

Newest first. Median $, context and calls are per run; pass is passes/trials.

### asks-printer

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | cand | `c76ad10` c76ad10 · 344f91ff10 | xhigh | 3/3 | 1.00 | $0.12 | 71,124 | 2 | 15 | 0% | 26,714 |  |
| 2026-09-29 | skill-review-v2-2026-09-29 | base | `origin/main` 2d8f6e1 · 1d09abd8d4 | xhigh | 0/3 | 0.00 | $1.95 (3 est.) | 1,075,479 | 12 | 600 | 8% | 33,767 | asks_printer x3, is_a_question x3, no_premature_scad x3, timeout x3 |
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 2/3 | 0.67 | $0.43 | 162,959 | 4 | 36 | 0% | 39,112 | asks_printer x1, is_a_question x1, no_premature_scad x1 |
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 1.00 | $0.18 | 116,740 | 3 | 15 | 0% | 39,112 |  |

### cable-clip-3mf

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | cand | `c76ad10` c76ad10 · 344f91ff10 | xhigh | 2/3 | 0.97 | $7.58 | 4,139,146 | 39 | 1,619 | 12% | 26,714 | gate x1 |
| 2026-09-29 | skill-review-v2-2026-09-29 | base | `origin/main` 2d8f6e1 · 1d09abd8d4 | xhigh | 2/3 | 0.97 | $5.58 | 6,676,196 | 51 | 1,611 | 21% | 33,767 | bambu_3mf x1 |
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 2/3 | 0.97 | $7.17 | 9,952,185 | 78 | 1,990 | 13% | 39,112 | bambu_3mf x1 |

### caster-plug

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | cand | `c76ad10` c76ad10 · 344f91ff10 | xhigh | 3/3 | 1.00 | $7.63 | 3,797,701 | 36 | 1,606 | 11% | 26,714 |  |
| 2026-09-29 | skill-review-v2-2026-09-29 | base | `origin/main` 2d8f6e1 · 1d09abd8d4 | xhigh | 2/3 | 0.61 | $6.55 (2 est.) | 4,988,785 | 34 | 2,700 | 18% | 33,767 | file_structure x1, fits_build_volume x1, gate x1, has_asserts x1, manifold x1, on_plate x1, parts_min x1, ran_openscad x1, shells_max x1, small_part x1, spawned_review x1, stl_exported x1, support_free x3, timeout x2 |
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 1/3 | 0.61 | $4.54 (3 est.) | 1,620,932 | 16 | 2,700 | 2% | 39,112 | file_structure x1, fits_build_volume x1, gate x1, has_asserts x1, manifold x1, on_plate x1, parts_min x1, ran_openscad x1, shells_max x1, small_part x1, spawned_review x1, stl_exported x2, support_free x2, timeout x3 |
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 0.91 | $3.22 | 2,749,432 | 34 | 1,309 | 52% | 39,112 | support_free x1 |

### pi4-case

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | cand | `c76ad10` c76ad10 · 344f91ff10 | xhigh | 0/3 | 0.92 | $10.47 (2 est.) | 9,815,325 | 58 | 3,600 | 16% | 26,714 | gate x3, timeout x2 |
| 2026-09-29 | skill-review-v2-2026-09-29 | base | `origin/main` 2d8f6e1 · 1d09abd8d4 | xhigh | 1/3 | 0.94 | $11.78 (2 est.) | 17,049,891 | 102 | 3,600 | 36% | 33,767 | stl_exported x2, timeout x2 |
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 1/3 | 0.94 | $9.09 (1 est.) | 7,174,097 | 55 | 3,454 | 39% | 39,112 | stl_exported x2, timeout x1 |

### pot-stand

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | cand | `c76ad10` c76ad10 · 344f91ff10 | xhigh | 3/3 | 0.94 | $3.71 | 1,208,635 | 18 | 807 | 27% | 26,714 | covers_base x2, ran_openscad x1 |
| 2026-09-29 | skill-review-v2-2026-09-29 | base | `origin/main` 2d8f6e1 · 1d09abd8d4 | xhigh | 3/3 | 1.00 | $4.31 | 2,911,449 | 33 | 1,271 | 26% | 33,767 |  |
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 3/3 | 0.97 | $3.33 | 2,802,487 | 32 | 1,009 | 28% | 39,112 | covers_base x1 |

### pot-stand-edit

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | cand | `c76ad10` c76ad10 · 344f91ff10 | xhigh | 3/3 | 1.00 | $1.79 | 1,680,011 | 22 | 401 | 0% | 26,714 |  |
| 2026-09-29 | skill-review-v2-2026-09-29 | base | `origin/main` 2d8f6e1 · 1d09abd8d4 | xhigh | 3/3 | 1.00 | $3.44 | 4,408,932 | 47 | 776 | 15% | 33,767 |  |
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 3/3 | 1.00 | $3.67 | 4,760,676 | 47 | 778 | 22% | 39,112 |  |

### review-recall

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-29 | skill-review-v2-2026-09-29 | cand | `c76ad10` c76ad10 · 344f91ff10 | xhigh | 3/3 | 0.83 | $3.70 | 1,029,928 | 17 | 669 | 35% | 26,714 | coincident x3, fillet x1 |
| 2026-09-29 | skill-review-v2-2026-09-29 | base | `origin/main` 2d8f6e1 · 1d09abd8d4 | xhigh | 3/3 | 0.75 | $2.78 | 2,678,926 | 34 | 654 | 40% | 33,767 | coincident x3, elephant_foot x2, teardrop x1 |
| 2026-09-28 | baseline-2026-09-29 | main | `main` 10746b0 · 1d09abd8d4 | xhigh | 3/3 | 0.79 | $2.93 | 2,502,507 | 31 | 700 | 42% | 39,112 | coincident x3, elephant_foot x2 |
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 1.00 | $1.49 | 1,353,747 | 23 | 596 | 69% | 39,112 |  |
