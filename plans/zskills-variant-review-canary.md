# ZSkills Variant Review Canary

## Goal

Validate that `/run-plan finish auto` can complete five observable phases while producing a useful review packet comparing `zskills`, `zskills-cc`, `zskills-codex`, and `zskills-dev`, plus a practical overview for how `zskills-cc` and `zskills-codex` should apply `zskills-dev` changes when they are ready.

## Context

This canary is local-only and documentation-oriented. It should inspect this repository and any locally available notes, reports, skills, and support scripts. It should not require network access, GitHub credentials, or a checkout of every upstream variant. If a variant is not locally available, document that as an evidence gap rather than inventing facts.

The only expected project changes are under:

- `zskills-variant-review-canary/`
- `scripts/test-zskills-variant-review-canary.sh`
- `reports/plan-zskills-variant-review-canary.md`
- this plan file's progress tracker

Default ZSkills landing behavior is acceptable. If no repo config exists, `/run-plan` may use the default cherry-pick workflow.

## Non-Goals

- Do not modify skills, installer behavior, support scripts, README, existing reports, existing canary outputs, or existing plans other than this plan's progress tracker.
- Do not create cron jobs, background schedulers, GitHub PRs, or remote branches.
- Do not claim current facts about `zskills-dev` that are not supported by local evidence. Use clearly labeled assumptions or readiness placeholders where needed.
- Do not rewrite the completed `simple-three-phase-run-plan-canary` or canary 3 artifacts.

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Create review harness and inventory | ✅ Done | Created the output directory, manifest, verification script, and an evidence inventory for local ZSkills materials. |
| 2. Compare the four variants | ✅ Done | Created the structured comparison matrix for `zskills`, `zskills-cc`, `zskills-codex`, and `zskills-dev`, with local evidence separated from inference and evidence gaps called out. |
| 3. Analyze Codex and CC adoption surfaces | ⬜ Not Started | Create a focused analysis of where `zskills-cc` and `zskills-codex` would absorb upstream changes. |
| 4. Build the dev-change application plan | ⬜ Not Started | Create a non-trivial migration plan for applying `zskills-dev` changes to `zskills-cc` and `zskills-codex`. |
| 5. Produce final overview and run full verification | ⬜ Not Started | Create the final overview, update the manifest, and verify the complete review packet. |

## Phase Details

### Phase 1. Create Review Harness and Inventory

Create directory `zskills-variant-review-canary/`.

Create `zskills-variant-review-canary/manifest.txt` with exactly:

```text
phase-1-inventory.md
```

Create executable `scripts/test-zskills-variant-review-canary.sh`. The script should:

- run from the repository root;
- fail if `zskills-variant-review-canary/manifest.txt` is missing;
- read manifest lines into an array;
- allow progressive states after phase 1, 2, 3, 4, or 5;
- reject unknown manifest entries;
- reject out-of-order manifest entries;
- verify every listed file exists under `zskills-variant-review-canary/`;
- verify required headings and required keywords for every listed file;
- verify the final output directory contains no unexpected top-level files when all five phases are complete.

The expected manifest order is:

```text
phase-1-inventory.md
phase-2-variant-comparison.md
phase-3-adoption-surfaces.md
phase-4-dev-change-application-plan.md
phase-5-overview.md
```

Create `zskills-variant-review-canary/phase-1-inventory.md`. It should include:

- heading `# Phase 1 Inventory`;
- section `## Local Evidence Reviewed`;
- section `## Variant Names`;
- section `## Evidence Gaps`;
- section `## Initial Observations`;
- the exact variant names `zskills`, `zskills-cc`, `zskills-codex`, and `zskills-dev`;
- at least five local evidence paths or path patterns from this repo, such as `README.md`, `skills/`, `zskills-support/`, `plans/`, or `reports/`;
- an explicit note that missing local evidence must be treated as an evidence gap.

After phase 1, run:

```bash
bash scripts/test-zskills-variant-review-canary.sh
```

Expected result: the script passes with only `phase-1-inventory.md` listed.

### Phase 2. Compare the Four Variants

Create `zskills-variant-review-canary/phase-2-variant-comparison.md`. It should include:

- heading `# Phase 2 Variant Comparison`;
- section `## Comparison Matrix`;
- section `## Runtime Assumptions`;
- section `## Porting Differences`;
- section `## Evidence Gaps`;
- all exact variant names `zskills`, `zskills-cc`, `zskills-codex`, and `zskills-dev`;
- a markdown table comparing the variants across at least these dimensions: runtime host, instruction format, support assets, tracking model, landing model, and likely integration risk;
- a short paragraph distinguishing observed local evidence from inference.

Update `zskills-variant-review-canary/manifest.txt` to exactly:

```text
phase-1-inventory.md
phase-2-variant-comparison.md
```

Run:

```bash
bash scripts/test-zskills-variant-review-canary.sh
```

Expected result: the script passes with phases 1-2 listed in order.

### Phase 3. Analyze Codex and CC Adoption Surfaces

Create `zskills-variant-review-canary/phase-3-adoption-surfaces.md`. It should include:

- heading `# Phase 3 Adoption Surfaces`;
- section `## zskills-codex Surfaces`;
- section `## zskills-cc Surfaces`;
- section `## Shared Surfaces`;
- section `## Divergence Risks`;
- exact terms `skills/`, `zskills-support/`, `runner`, `tracking`, `hooks`, `installer`, and `configuration`;
- at least one table or list that maps an upstream change type to likely `zskills-codex` and `zskills-cc` touchpoints;
- a note that `zskills-codex` must preserve Codex-native behavior and must not import Claude-only runtime assumptions.

Update `zskills-variant-review-canary/manifest.txt` to exactly:

```text
phase-1-inventory.md
phase-2-variant-comparison.md
phase-3-adoption-surfaces.md
```

Run:

```bash
bash scripts/test-zskills-variant-review-canary.sh
```

Expected result: the script passes with phases 1-3 listed in order.

### Phase 4. Build the Dev-Change Application Plan

This is the non-trivial phase. Create `zskills-variant-review-canary/phase-4-dev-change-application-plan.md`. It should be substantial enough to be useful for a future maintainer applying `zskills-dev` changes to `zskills-cc` and `zskills-codex`.

It should include:

- heading `# Phase 4 Dev Change Application Plan`;
- section `## Intake Checklist`;
- section `## Change Classification`;
- section `## Application Strategy for zskills-cc`;
- section `## Application Strategy for zskills-codex`;
- section `## Compatibility Gates`;
- section `## Verification Matrix`;
- section `## Release Readiness`;
- exact terms `zskills-dev`, `zskills-cc`, `zskills-codex`, `frontmatter`, `support scripts`, `hooks`, `runner`, `tracking markers`, `config schema`, `tests`, and `reports`;
- a classification table with at least eight change categories, including skill text, support scripts, hooks, installer, config schema, tests, documentation, and runtime policy;
- a verification matrix with at least eight rows that maps change category to Codex verification and CC verification;
- a staged rollout strategy with at least five ordered steps;
- explicit guidance for when `zskills-codex` should adapt, reject, or defer a `zskills-dev` change;
- explicit guidance for when `zskills-cc` should import directly versus adapt;
- a risk section covering cross-runtime assumptions, marker compatibility, stale reports, and upstream drift;
- a clear statement that this plan is based on current local evidence and should be refreshed against the actual `zskills-dev` diff before execution.

Update `zskills-variant-review-canary/manifest.txt` to exactly:

```text
phase-1-inventory.md
phase-2-variant-comparison.md
phase-3-adoption-surfaces.md
phase-4-dev-change-application-plan.md
```

Run:

```bash
bash scripts/test-zskills-variant-review-canary.sh
```

Expected result: the script passes with phases 1-4 listed in order.

### Phase 5. Produce Final Overview and Run Full Verification

Create `zskills-variant-review-canary/phase-5-overview.md`. It should include:

- heading `# Phase 5 Overview`;
- section `## Executive Summary`;
- section `## What We Know`;
- section `## What Needs Fresh Diff Review`;
- section `## Recommended Next Steps`;
- section `## Canary Result`;
- exact variant names `zskills`, `zskills-cc`, `zskills-codex`, and `zskills-dev`;
- a concise overview of how `zskills-cc` and `zskills-codex` can apply `zskills-dev` changes when ready;
- a short list of open questions for the future `zskills-dev` diff review;
- the exact phrase `ready for fresh zskills-dev diff review`.

Update `zskills-variant-review-canary/manifest.txt` to exactly:

```text
phase-1-inventory.md
phase-2-variant-comparison.md
phase-3-adoption-surfaces.md
phase-4-dev-change-application-plan.md
phase-5-overview.md
```

Run:

```bash
bash scripts/test-zskills-variant-review-canary.sh
```

Final verification may also use:

```bash
find zskills-variant-review-canary -maxdepth 1 -type f -printf '%f\n' | sort
cat zskills-variant-review-canary/manifest.txt
git status --short
```

Expected result: the script passes with all five files listed in order.

## Acceptance Criteria

- The review packet is built progressively over five phases.
- Phase 4 is materially more detailed than the other phases and includes the required classification table, verification matrix, rollout strategy, and risk guidance.
- `scripts/test-zskills-variant-review-canary.sh` passes after every phase.
- The final `zskills-variant-review-canary/manifest.txt` contains exactly the five expected file names in order.
- The final `zskills-variant-review-canary/` directory contains exactly:
  - `manifest.txt`
  - `phase-1-inventory.md`
  - `phase-2-variant-comparison.md`
  - `phase-3-adoption-surfaces.md`
  - `phase-4-dev-change-application-plan.md`
  - `phase-5-overview.md`
- The final report at `reports/plan-zskills-variant-review-canary.md` includes a scope assessment and verification result for each phase.
- `.zskills/` tracking files remain uncommitted.

## Verification

Run this after any phase:

```bash
bash scripts/test-zskills-variant-review-canary.sh
```

Final verification:

```bash
bash scripts/test-zskills-variant-review-canary.sh
find zskills-variant-review-canary -maxdepth 1 -type f -printf '%f\n' | sort
cat zskills-variant-review-canary/manifest.txt
git status --short
```

## Risks

- The actual `zskills-dev` diff may not be locally available when the canary runs. The review packet must label this as an evidence gap instead of fabricating details.
- If `finish auto` uses cherry-pick mode, ensure each phase lands the plan, report, review packet, and verification script updates together.
- If the runner detects unrelated dirty files, run this canary in a clean worktree or disposable clone.
