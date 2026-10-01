# Reviewer model comparison

Generated from `runs.jsonl` by `python evals/bench/review_models.py --render`; don't edit by hand. How it works is in [README.md](README.md).

Each run gives one reviewer model the skill's design-review brief for one fixed fixture, then a judge model maps its findings onto the fixture's seeded defects. **Vital** defects would stop the part working or printing; **minor** ones are rule or quality slips. Costs are US dollars at Anthropic's [list API prices](https://platform.claude.com/docs/en/about-claude/pricing), as Claude Code reports them (reviewer only; judging is listed separately). On a subscription they draw on usage limits instead.

## reviewer-pattern-fasteners

pattern-fasteners pointer: Sonnet on all six fixtures. Skill `27dd91c` · 3a63900f0f, effort `high`, judged by `claude-opus-5-5`. 18 runs.

| Reviewer | Model | Vital defects found | Minor found | Extra real findings per review | Serious false alarms per review | Control: serious false alarms | Median $ per review | Median minutes |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| sonnet | `claude-sonnet-5-5` | 29/30 (97%) | 27/27 (100%) | 1.2 | 0.06 | 0 in 3 | 0.14 | 1.1 |

Per seeded defect (reviews that found it):

| Fixture | Defect | Severity | sonnet |
|---|---|---|---:|
| d-shaft-knob | bore_no_compensation | vital | 3/3 |
| d-shaft-knob | grub_thread_in_pla | vital | 3/3 |
| d-shaft-knob | ribs_too_thin | minor | 3/3 |
| d-shaft-knob | grub_hole_no_teardrop | minor | 3/3 |
| insert-standoff | insert_hole_too_small | vital | 3/3 |
| insert-standoff | boss_wall_too_thin | vital | 3/3 |
| insert-standoff | insert_hole_too_shallow | vital | 3/3 |
| insert-standoff | sharp_boss_root | minor | 3/3 |
| pipe-clip | snap_strain | vital | 3/3 |
| pipe-clip | screw_hole_no_teardrop | minor | 3/3 |
| pipe-clip | coincident_cut | minor | 3/3 |
| planter-saucer | flat_lip_overhang | vital | 3/3 |
| planter-saucer | not_watertight | vital | 2/3 |
| planter-saucer | wall_not_multiple | minor | 3/3 |
| planter-saucer | ef_chamfer_unused | minor | 3/3 |
| shelf-bracket | layer_orientation | vital | 3/3 |
| shelf-bracket | screw_hole_too_small | vital | 3/3 |
| shelf-bracket | sharp_internal_corner | minor | 3/3 |
| shelf-bracket | ef_chamfer_unused | minor | 3/3 |

Spend: $2.83 on reviews, $1.63 on judging.

## reviewer-2026-09-29

Sonnet vs Fable full reviews on simple parts. Skill `a639e84` · 0e05372622, effort `high`, judged by `claude-opus-5-5`. 36 runs.

| Reviewer | Model | Vital defects found | Minor found | Extra real findings per review | Serious false alarms per review | Control: serious false alarms | Median $ per review | Median minutes |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| fable | `claude-fable-5-1` | 30/30 (100%) | 27/27 (100%) | 1.2 | 0.06 | 0 in 3 | 0.98 | 2.5 |
| sonnet | `claude-sonnet-5-5` | 29/30 (97%) | 26/27 (96%) | 1.1 | 0.00 | 0 in 3 | 0.14 | 1.2 |

Per seeded defect (reviews that found it):

| Fixture | Defect | Severity | fable | sonnet |
|---|---|---|---:|---:|
| d-shaft-knob | bore_no_compensation | vital | 3/3 | 3/3 |
| d-shaft-knob | grub_thread_in_pla | vital | 3/3 | 3/3 |
| d-shaft-knob | ribs_too_thin | minor | 3/3 | 3/3 |
| d-shaft-knob | grub_hole_no_teardrop | minor | 3/3 | 3/3 |
| insert-standoff | insert_hole_too_small | vital | 3/3 | 3/3 |
| insert-standoff | boss_wall_too_thin | vital | 3/3 | 3/3 |
| insert-standoff | insert_hole_too_shallow | vital | 3/3 | 3/3 |
| insert-standoff | sharp_boss_root | minor | 3/3 | 2/3 |
| pipe-clip | snap_strain | vital | 3/3 | 3/3 |
| pipe-clip | screw_hole_no_teardrop | minor | 3/3 | 3/3 |
| pipe-clip | coincident_cut | minor | 3/3 | 3/3 |
| planter-saucer | flat_lip_overhang | vital | 3/3 | 3/3 |
| planter-saucer | not_watertight | vital | 3/3 | 2/3 |
| planter-saucer | wall_not_multiple | minor | 3/3 | 3/3 |
| planter-saucer | ef_chamfer_unused | minor | 3/3 | 3/3 |
| shelf-bracket | layer_orientation | vital | 3/3 | 3/3 |
| shelf-bracket | screw_hole_too_small | vital | 3/3 | 3/3 |
| shelf-bracket | sharp_internal_corner | minor | 3/3 | 3/3 |
| shelf-bracket | ef_chamfer_unused | minor | 3/3 | 3/3 |

Spend: $19.87 on reviews, $2.98 on judging.

