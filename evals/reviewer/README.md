# Reviewer model comparison

Which model should run the skill's design review? The skill's full A/B can't answer that. There, the author changes the design, triages the review, and only then is graded, so a weak reviewer and a strong author look the same as the reverse. This benchmark holds the design fixed and changes only the reviewer.

Results are in **[RESULTS.md](RESULTS.md)**, one section per suite. The raw rows are in `runs.jsonl`.

## What it has shown so far

2026-09-29: Sonnet 5.5 against Fable 5.1, both at effort `high`, 6 fixtures × 3 trials.

- **Vital defects:** Sonnet found 29/30 and Fable 30/30.
- **Minor defects:** Sonnet found 26/27 and Fable 27/27.
- **Extra real findings:** a similar number per review from each.
- **False alarms:** neither raised a serious false alarm on the clean control.
- **Cost:** Sonnet's reviews cost a seventh as much ($0.14 against $0.98 median) and took half the time.

Sonnet's one vital miss was a judgement call, not an oversight. In 1 of 3 trials it looked at the saucer's 0.8 mm floor and called it "fine for water". Fable flagged it every time.

That supports the skill's policy: Sonnet for every review, and Fable for one final review per project. The Fable review is automatic for complex work; for a simple part it is offered to the user at hand-off, and it falls back to Sonnet when Fable isn't available. Two caveats:

- **Ceiling effect.** Both models found nearly everything, so these textbook defects are easier than a real design's.
- **Complex projects weren't tested.** Multi-part fit and mechanisms, where the Fable review is kept, need fixtures of their own.

## How it works

`fixtures/` holds small single-part designs, written like the skill's own output, that all pass the build gate (`verify-model.py`). Each fixture has:

- `model.scad`: the design;
- `brief.json`: the printer, material and numbered acceptance criteria the reviewer is given;
- `answers.json`: the seeded defects, each marked **vital** or **minor**.
  - **Vital:** the part won't work or won't print. For example, screw holes too small for the screws, an arm loaded across its layers, a PLA snap strained to 6%, a flat unsupported lip, or a heat-set insert hole at tap size.
  - **Minor:** a rule or quality slip, such as a round horizontal hole, a coincident cut, an unused `ef_chamfer`, or a wall that isn't whole perimeters.

`coat-hook` is a clean control with no seeded defects. It measures false alarms.

For each fixture, reviewer model and trial, `bench/review_models.py` gives the reviewer exactly the brief the skill's author sends its review sub-agent (SKILL.md, Design Review): the `.scad` and OpenSCAD paths, printer and material, the criteria, and "read design-review.md, your complete brief; the gate has passed." The reviewer runs in its own temp folder with the current skill files, read/bash tools and a fixed effort.

A fixed judge model then reads the brief, the `.scad`, the answer key and the review, and returns structured JSON:

- which seeded defects were clearly identified;
- the reviewer's other findings, each rated real, debatable or wrong, with whether the reviewer called it serious.

```sh
python evals/bench/review_models.py --reviewers sonnet=claude-sonnet-5-5,fable=claude-fable-5-1 \
    --trials 3 --effort high -j 3 --label "what this suite tests"
python evals/bench/review_models.py --render      # rebuild RESULTS.md from runs.jsonl
```

A suite is recorded only when every run has finished. If the account's usage limit hits, the script stops launching runs; repeat the command with the same `--out` after the reset and it picks up where it stopped.

Costs are US dollars at Anthropic's [list API prices](https://platform.claude.com/docs/en/about-claude/pricing), as Claude Code reports them. On a subscription the runs draw on usage limits instead.

## Reading the results

- **Vital recall** is the headline: a reviewer that misses vital defects lets broken parts through.
- **Serious false alarms**, meaning findings the judge rates wrong that the reviewer called critical or major, cost the author time and can talk it into a worse design. The control counts them where no defect exists.
- **Extra real findings** are genuine issues outside the answer key. The fixtures were written to be clean apart from the seeded defects, but a sharp reviewer can still find more.

## Limits

- **Small sample.** Six fixtures, and a few trials per model. Reviews vary a lot from run to run, so a difference of one or two finds is noise. Look at the per-defect table.
- **The judge is a model.** Its structured verdicts are saved per run (`judge.json`, next to `review.md` in the results folder); spot-read a few before trusting a close result.
- **Written by the same hand as the brief.** The fixtures were written alongside the current `design-review.md`, so both reviewers may find the seeded defects easier than real ones. The comparison between models is still fair: same brief, same fixtures. When tuning `design-review.md`, don't read `answers.json`, or the fixtures stop measuring anything.
- **Standalone, not a sub-agent.** Each reviewer runs as its own `claude -p` session rather than through the Agent tool, so it has the main session's system prompt and the effort set here.
