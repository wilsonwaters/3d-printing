# Evaluating the 3d-print-designer skill

The goal: make the skill cheaper to run **without making the designs worse**,
and be able to show both halves of that claim. Every number here is measured
by tools in this folder from the files and transcripts a run leaves behind,
never taken from what the agent says about its own work.

```
evals/
  bench/            the harness (Python 3.8+ standard library only)
    footprint.py      static context cost of the skill: free, every commit
    scadcheck.py      compile + mesh + structure checker for one .scad
    selftest.py       grader calibration on shapes with hand-computed answers
    fixtures.py       re-measure existing 3d-models/ against a snapshot
    run.py            A/B runner: cases x skill versions x trials via claude -p
    grade.py          per-case requirement checks on a finished output folder
    transcript.py     tokens/cost/behaviour from a run or an interactive session
    render.py         fixed-camera views for the judge and for you
    judge.py          blind, order-swapped pairwise judge (optional, costs tokens)
    report.py         per-arm tables, paired ratios, bootstrap CIs, renders
  cases/            benchmark cases: task.md (the prompt) + case.json (checks)
  flagship/         the rain gauge: task, human rubric, cross-model ledger
  native/           trigger suite for `claude plugin eval` (first-party runner)
  fixtures.json     snapshot for fixtures.py
  footprint-profiles.json   which files a run loads, per path through the skill
  baselines/footprint.json  the committed context budget (the ratchet)
  results/          run output (git-ignored)
```

## What gets measured

### Cost

| Metric | Source | Why it matters |
|---|---|---|
| **Cost $** | `total_cost_usd` on the last result event | The bottom line. A list-price estimate, including sub-agents. |
| **Context tokens** | input + cache read + cache write, all models | What skill trimming reduces. Every turn re-reads the whole context (mostly from cache), so this is roughly *context size × number of calls*. |
| **Output tokens** | `modelUsage` | Code, prose and thinking; priced at 5× input. |
| **API calls** | de-duplicated assistant messages | Fewer turns shrinks the multiplier on everything already in context. Often the biggest lever. |
| **Wall time** | harness clock | What you wait for. |
| **Sub-agent share** | per-call usage, split by parent | How much the design-review sub-agent costs relative to the author. |
| **Skill text read** | the Skill tool, plus Read or `cat` of files in the skill dir | Which reference files a run actually opened. |
| **Images viewed, openscad calls** | tool calls | Render size and count are direct token levers (a 1024² image costs about 1.4k tokens). |
| **Static footprint** | `footprint.py`, no model call | Tokens of skill text on each load path. Noise-free, so small changes show. |

Two transcript facts the tools handle for you. First, a result event's
`usage` covers only the last top-level turn; the totals that include
sub-agents are `modelUsage` and `total_cost_usd`. Second, per-message
`output_tokens` in the stream is a placeholder, so output totals come from
`modelUsage`.

### Quality

| Layer | How | Decides pass? |
|---|---|---|
| **Gate** | Every `part=` value compiles clean with the OpenSCAD nightly, using the same fatal phrases as the skill's verification gate. Interference-check parts (`clash`, `fit`, `*interference*`) must render empty. | yes, automatic |
| **Manifold** | Every edge of every printable part is shared by exactly two faces. Edge-only contact passes OpenSCAD but Bambu Studio flags it. | yes, automatic |
| **Fits the printer** | Printable-part bounding boxes against the case's build volume. | yes, automatic |
| **Requirements** | Case checks written from the brief: size envelopes, part counts, on the plate, one body per part, STL/3MF produced (see `grade.py`'s docstring). | yes, per check |
| **Printability** | Sloped overhang area past 45°, flat ceiling area (bridges), bed contact, shells. | optional thresholds |
| **Skill conformance** | Headers, PRINT SETTINGS fields, asserts, `$fn`, fudge, part selector. | optional |
| **Behaviour** | Skill invoked, OpenSCAD run, review sub-agent spawned. | never (weight 0, shown in the report) |
| **Judge** | `judge.py`: which of two designs better meets the brief, order swapped, a design wins only if it wins both ways. | reported separately |
| **You** | The renders in `report.md`, and for the flagship, [rubric.md](flagship/rain-gauge/rubric.md). | final say |

The deterministic layers catch "doesn't build / won't print / wrong size".
They can't tell a clever mechanism from a clumsy one, so that is what the
judge and you are for.

## Tiers

| Tier | What | When | Cost |
|---|---|---|---|
| **0: static** | `footprint.py --check`, `selftest.py`, `fixtures.py` | every push (CI: `.github/workflows/skill-evals.yml`) | free |
| **1a: triggers** | `claude plugin eval .` on `native/`: fires on natural phrasing, stays quiet on near misses, asks for the printer first; with and without the skill | when the description or Step 0 changes | a few dollars (~$0.11 a run) |
| **1b: smoke A/B** | `run.py --tier smoke`: caster plug, ask-for-printer, seeded-defect review | each skill edit | ~$5 per arm per trial ([measured](#cost-per-case)) |
| **1c: standard A/B** | `run.py --tier standard`: all 7 cases, including 2 held out | before you merge a skill change | est. $100-150 for 3 trials × 2 arms |
| **2: flagship** | the rain gauge, 1 trial per model | a new model, or a major skill rewrite | tens of dollars |

## Quick start

Prerequisites: Python 3.8+, the OpenSCAD **nightly** (the grader relies on the
Manifold backend and `--summary`; found automatically on PATH or in
`C:\Program Files\OpenSCAD*`, or set `OPENSCAD`), and a logged-in `claude`
CLI (v2.1.269+ for `plugin eval`).

```sh
# free
python evals/bench/footprint.py            # where the skill's tokens are, plus lint
python evals/bench/selftest.py             # is the grader right?
python evals/bench/fixtures.py             # did anything shift on the existing models?
python evals/bench/scadcheck.py path/to/model.scad --build-volume 256x256x256

# costs tokens
python evals/bench/run.py --list
python evals/bench/run.py --tier smoke --arms base=main,cand=WORKTREE --trials 3 \
    --model claude-opus-5-5 --effort high --max-cost-usd 40
python evals/bench/judge.py evals/results/<timestamp> --a base --b cand --judge-model sonnet
python evals/bench/report.py evals/results/<timestamp>     # rebuild report.md with judge results
claude plugin eval . --runs 2 --no-publish                 # trigger suite (native/)
```

Arms are `NAME=REF[@MODEL]`. `REF` is any git ref, `WORKTREE` (the skill as it
is on disk) or `none` (no skill, vanilla Claude). A run is resumable: repeat the
command with the same `--out` and finished runs are skipped.

## The workflow for a token-optimisation change

1. **Static first (free).** Run `footprint.py`: the tokens saved on each load
   path are exact, so you know what the change is worth at best before spending
   anything. The duplication list is a good place to start: text repeated
   across files gets paid twice when both are loaded.
2. **Smoke A/B.** `--arms base=main,cand=WORKTREE --trials 3`, with the model
   and effort pinned. Read the paired table: cost as a ratio (×0.80 = 20%
   cheaper) with a 95% interval, and quality as a difference.
3. **Standard A/B + judge** before merging. Look at the renders side by side.
4. **Accept when all hold:**
   - no must-pass check that passed on `base` fails on `cand` (look at the per-case table, not just the average);
   - the cost ratio's interval sits below 1.0, or the static saving is large and the run cost is no worse;
   - the judge does not prefer `base` (count `cand` wins plus ties against `base` wins);
   - you've looked at the renders.
5. `footprint.py --update` and commit the new baseline with the change, so CI
   holds the saving.

One change at a time: if a trim and a restructure go in together and quality
drops, you won't know which did it.

### How many trials?

Run-to-run noise in agent token use is large. The trials needed per arm to
detect a real change (paired, log scale, 80% power, α = 0.05):

| Run-to-run spread (CV) | 20% change | 10% change |
|---|---:|---:|
| 0.2 | 13 | ~60 |
| 0.3 | 28 | ~125 |
| 0.5 | 71 | ~320 |

So 3 trials × 3 smoke cases (9 per arm) catches a large cut (30%+) reliably
and a 20% cut only if runs are consistent. Measure your actual spread once with
an **A/A run** (`--arms a=main,b=main`): whatever difference that shows is the
noise floor, and any A/B result smaller than it means nothing. Pass/fail rates
are worse still: going from 80% to 60% takes about 80 trials per arm to see, so
lean on the continuous check score, the per-case table and the judge, and treat
pass rates as a tripwire. The report's intervals come from resampling trials
within each case, so they widen honestly when you have few runs.

### Keeping the eval honest

- **Held-out cases.** `pi4-case` and `cable-clip-3mf` are tagged `holdout`.
  When an agent is optimising the skill, don't let it read `evals/cases/`, and
  judge it on the holdout as well as the tier it tuned on. Add new briefs from
  time to time and retire ones the skill has saturated.
- **Checks come from the brief, not the skill.** No check names a skill file
  (`skill_file_read` exists for diagnosis only), so merging or renaming
  references can't fail a case by itself.
- **Pin the model and effort.** A skill A/B across two models measures the models.
- **Interleaving.** Arms run interleaved, with their order rotated per trial,
  so drift during a session (cache warmth, API load) hits both.
- **A vanilla baseline now and then** (`--arms skill=WORKTREE,vanilla=none`)
  shows what the skill adds at all, and catches the day the model outgrows it.

## Isolation

Each run starts in an empty temp directory outside the repo:

```
claude -p <task> --plugin-dir <this arm's copy of the skill> --setting-sources project \
  --no-session-persistence --permission-mode acceptEdits --output-format stream-json ...
```

- **`--setting-sources project`** keeps out user settings, user skills,
  CLAUDE.md and memory. Without it, an installed copy of the skill (for example
  `anthropic-skills:3d-print-designer` synced from claude.ai) loads in every arm.
- **Skill discovery is blocked.** `SearchSkills`, `ListSkills` and
  `SuggestSkills` are disallowed, because they can reach the claude.ai copy.
- **Preflight check.** Before the suite starts, each arm opens a one-turn
  session and must see exactly its own skill; the vanilla arm must see none.
  Otherwise nothing runs. This isn't hypothetical: the first smoke run here
  silently ran without the skill.
- **Nobody to answer.** Plan mode and AskUserQuestion need a person, so they
  are disabled, and the same short note is appended to the system prompt in
  every arm: make reasonable assumptions and finish. Cases put the printer and
  material in the prompt. `asks-printer` turns the note off to test Step 0.
- **Not sandboxed.** The agent runs Bash as you, in its temp directory. The
  native `claude plugin eval` runner sandboxes Bash (bubblewrap on Linux) but
  can't compile and measure the output independently. That is why the bench
  exists alongside it.

## Cases

| Case | Tiers | Tests | Must pass |
|---|---|---|---|
| `caster-plug` | smoke, standard | small single part with a fit problem that failed twice in real prints | gate, manifold, fits, ≤45 mm envelope, on plate, 1 body, STL |
| `asks-printer` | smoke, standard | Step 0: no printer given → ask before designing | reply asks about the printer; no .scad yet |
| `review-recall` | smoke, standard | design review on [bracket.scad](cases/review-recall/bracket.scad) with 6 seeded defects | finds ≥3 of 6 (per-defect recall in the score); file untouched |
| `pot-stand` | standard | large load-bearing part, drainage, first layer | ≥160×160 footprint, 25 mm lift, ≤256 mm, on plate, 1 body |
| `pot-stand-edit` | standard | modify the real `3d-models/outdoor-plant-pot-stand` from its header | grew for 230 mm pots, still fits, asserts kept |
| `pi4-case` | standard, holdout | two-part snap-fit assembly with positional features | ≥2 parts, holds an 85×56 board, on plate |
| `cable-clip-3mf` | standard, holdout | PLA on a P1S through the Bambu 3MF export | valid Bambu project 3MF |
| `rain-gauge` | flagship | multi-part mechanism with research | ≥8 parts, a ≥150 mm collector part, STL, fits |

The seeded defects in `bracket.scad`: round horizontal holes (no teardrop),
printed in its use orientation (the shelf arm is an 80 mm unsupported ledge),
a 1.5 mm wall (not a whole number of 0.45 mm extrusion widths), a cut
coincident with the back face (no fudge), sharp internal corners at the
gusset, and no elephant-foot chamfer. The review sub-agent is one of the
skill's biggest costs, and this case measures what it catches as you slim it.

### Cost per case

Measured on the current skill with Opus 5.5 (single trials, so treat as ±50%):

| Case | Cost | Wall | API calls (sub-agent) | Context tokens | Output (thinking) | Result |
|---|---:|---:|---:|---:|---:|---|
| `asks-printer` | $0.18 | 15 s | 3 (0) | 117k | 0.8k | pass |
| `review-recall` | $1.49 | 10 min | 23 (15) | 1.35M | 56k | pass, 6/6 defects |
| `caster-plug` | $3.22 | 22 min | 34 (20) | 2.75M | 110k (89k) | pass; used a printed M8 thread (see below) |

These were run at effort `xhigh` (inherited from the session that ran them;
the harness now sets effort only through `--effort`). So a smoke A/B at 3 trials
is about **2 arms × 3 × $5 ≈ $30**. The standard tier adds larger parts (not
yet priced); budget roughly **$100-150** for a 3-trial A/B and set
`--max-cost-usd`. The flagship hasn't been run through the harness yet; expect
tens of dollars per run.

## Using the designs already in `3d-models/`

- **Grader calibration**: `fixtures.py` re-measures 11 of them, each chosen
  for a known property. Examples: printed and failed (caster v2), known-bad
  (hand-pump bracket 3 is 300 mm tall but its header claims it fits the bed),
  non-manifold contacts Bambu flagged (Fable tile v1), and interference checks
  that must render empty (Opus5.0 rain gauge, tile v2).
- **An edit case**: `pot-stand-edit` starts from the real pot stand, which
  also tests the DESCRIPTION header's promise that a fresh session can modify
  a model from it.
- **Flagship backfill**: the four existing rain gauges are measured in
  [LEDGER.md](flagship/rain-gauge/LEDGER.md).
- **Judge calibration**: the Fable / Opus5.0 / Opus5.0 v2 rain gauges and the
  acoustic tile variants are ready-made pairs. Score a few yourself, run the
  judge on the same pairs, and check it agrees before relying on it.

## The flagship

The rain gauge is too expensive to run routinely, so it's a case study per
model or major skill version, recorded in the ledger. Two ways to run it:

- **Harness:** `python evals/bench/run.py --cases rain-gauge --arms opus55=WORKTREE@claude-opus-5-5 --trials 1 --max-cost-usd 150`
  (add another `@model` arm to compare models on the same skill).
- **Interactively, as you do now**, then measure it:
  `python evals/bench/grade.py "3d-models/<folder>" --case evals/flagship/rain-gauge --scad "<final>.scad"`
  and `python evals/bench/transcript.py ~/.claude/projects/<project>/<session-id>.jsonl`
  (on Windows, `%USERPROFILE%\.claude\projects\…`; sub-agent transcripts are
  picked up from the session's `subagents/` folder).

Score it with [rubric.md](flagship/rain-gauge/rubric.md) and add a row to the
ledger. A print result outranks every other column.

## Background: why it's built this way

- **Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)**:
  tasks, trials, graders and transcripts. It favours code-based graders where
  they work, model graders calibrated against people, and human review as the
  anchor. It says to grade outcomes not paths, isolate every trial, separate
  capability suites from regression suites, and use pass^k when consistency
  matters.
- **Anthropic, [A statistical approach to model evaluations](https://www.anthropic.com/research/statistical-approach-to-model-evals)**:
  report error bars, cluster by task, compare versions as paired differences,
  and resample several runs per task. That is what `report.py` does.
- **[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)**:
  build evaluations before editing, compare against a no-skill baseline, keep
  SKILL.md under 500 lines, and keep references one level deep.
  `footprint.py` lints the last two.
- **[Claude Code plugin evals](https://code.claude.com/docs/en/plugin-evals)**:
  the first-party runner used for `native/`. It has a with/without-plugin
  baseline, but graders only read the transcript and files, so it can't
  compile and measure a model; hence the bench.
- **[SkillReducer](https://arxiv.org/abs/2603.29919)** (2026): across 55k
  public skills, over 60% of body text was non-actionable. Cutting bodies by
  39% (with progressive disclosure) *raised* task quality 2.8%. There is room
  to cut, and it has to be measured, not assumed.
- **[SkillsBench](https://arxiv.org/abs/2602.12670)**: paired skill vs
  no-skill runs as the basic unit of skill evaluation.
- **CAD-specific.** [CADCodeVerify](https://arxiv.org/abs/2410.05340) (ICLR
  2025) has a VLM check renders against questions drawn from the prompt, which
  is close to this skill's design review. [CADTests](https://arxiv.org/abs/2605.07807)
  uses executable tests of a prompt's geometric requirements, with no
  reference mesh; the case checks here are the same idea. With open-ended
  briefs there is no ground-truth mesh, so mesh-distance metrics (Chamfer,
  IoU) don't apply.

## What building this already turned up

These are for the skill review:

- **Static load.** A typical PETG + Bambu run reads about **39k tokens** of
  skill text before designing anything: SKILL.md ~9.4k, the six author-path
  files ~30k, plus design-review and bambu-export. After that, it is re-read
  from cache on every call.
- **Repetition.** `printer-profiles.md` is 53% repeated text, the same spec
  rows per printer. Longer passages are also duplicated between SKILL.md and
  verification.md, between design-review.md and verification.md (the OpenSCAD
  discovery commands), and between the material files.
- **A false fail in the skill's gate.** verification.md lists `(PolySet)` as
  a fatal phrase, but the current nightly prints it for any bare primitive (a
  lone `cube()` or `cylinder()` part), so a simple spacer fails the gate. The
  bench reports it but doesn't fail on it.
- **In the existing models.** Fable tile v2's `logo` part still has 3
  non-manifold edges, which Bambu Studio may flag. Gate latch v4's `lever`
  part is modelled off the plate.
- **From the smoke run (Opus 5.5, current skill):**
  - *Where the money goes.* On the two design runs, output plus thinking was
    about 46-48% of cost, cache writes about 30% and cache reads about 20%. The
    caster run produced 89k thinking tokens against 21k of visible output.
  - *The review is expensive.* The review sub-agent accounted for 52% of all
    context on the caster run (69% on the review-only case). It is the biggest
    single structural cost. It also isn't infallible: in the review case, the
    author caught a defect the reviewer missed (the gusset blocks the upper
    screw hole).
  - *Every mandatory reference is read.* The caster run read about 103 KB of
    skill text (about 37k tokens): all 6 mandatory files, `mechanical.md`, and
    `design-review.md` twice. It read them with `cat` in two Bash calls, which
    keeps the call count down.
  - *A lesson the skill hasn't learned.* The caster design uses a printed
    M8×1.25 thread in a cone nut. That is the approach that failed in the real
    v1 print (the thread didn't form). SKILL.md allows printed threads for "M4+",
    which permits it. The deterministic checks can't catch this; the judge
    criterion for the case names it.

## Known limits

- **Validated on single trials.** The pipeline has run end to end (smoke tier,
  one trial each, graded and reported), but nothing has been A/B-tested yet.
  Run an A/A once to learn the noise floor before trusting a small difference.
- **The review case is saturated.** The current skill found 6 of 6 seeded
  defects, so the case can catch a regression when design-review.md is slimmed,
  but it can't show an improvement. Seed subtler defects when you need that.
- **Regex grading of free text** (`review-recall`, `asks-printer`) can be
  fooled by a reply that mentions a term without flagging the problem. Spot-read
  the `final_message.md` of any run whose score surprises you.
- **The judge is uncalibrated** until you've checked it against your own
  verdicts on a handful of pairs.
- **Overhang area can't tell a bridge from an overhang**, and it counts
  deliberate chamfers at exactly 45° as fine. Compare it between arms; don't
  read it as a support verdict.
- **Unattended ≠ interactive.** Plan mode and clarifying questions are
  switched off (except in `asks-printer`), so the skill's plan-mode step for
  complex parts isn't exercised. The flagship run interactively is the check
  on that path.
- **Model and effort dominate cost.** Output plus thinking was about half of
  each design run's cost. Compare skill versions only at the same model and
  `--effort`, and consider effort as a lever alongside trimming text.
