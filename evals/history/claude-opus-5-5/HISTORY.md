# A/B history: claude-opus-5-5

Generated from `runs.jsonl` by `python evals/bench/history.py render`; don't edit by hand. Numbers compare only within this model, and only at the same effort. The skill column is `ref` sha · content hash (same hash = same skill text).

## Skill A/B comparisons

None yet: run `run.py` with two arms on this model.

## Per case over time

Newest first. Median $, context and calls are per run; pass is passes/trials.

### asks-printer

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 1.00 | $0.18 | 116,740 | 3 | 15 | 0% | 39,112 |  |

### caster-plug

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 0.91 | $3.22 | 2,749,432 | 34 | 1,309 | 52% | 39,112 | support_free x1 |

### review-recall

| Date | Suite | Arm | Skill | Effort | Pass | Score | Median $ | Median context | Calls | Wall s | Sub-agent share | Static tokens | Failing checks |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2026-09-28 | smoke-validate | cand | `WORKTREE` a824681 · 1d09abd8d4 | xhigh (inherited) | 1/1 | 1.00 | $1.49 | 1,353,747 | 23 | 596 | 69% | 39,112 |  |
