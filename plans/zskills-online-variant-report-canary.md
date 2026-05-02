# ZSkills Online Variant Report Canary

## Goal

Validate that `run-plan finish auto` can produce a high-quality, source-backed research report comparing the current GitHub repositories `github.com/zeveck/zskills`, `github.com/zeveck/zskills-dev`, `github.com/zeveck/zskills-cc`, and `github.com/zeveck/zskills-codex`.

The final report should be useful as a real maintainer briefing, not just a mechanical canary artifact. It should explain what each repository is for, how the variants differ, what `zskills-dev` appears to contain relative to the public and compatibility repos, and what actions are recommended for `zskills-cc` and this `zskills-codex` implementation.

## Context

This is a canary plan, but it intentionally requires online research. The implementing agent should use current GitHub evidence from the `zeveck` organization/user repositories and should record enough citations for a reader to audit the claims. This local working tree is the `zskills-codex` implementation; `https://github.com/zeveck/zskills-codex` is its intended publication target. Current claims about remote repository state must come from fresh GitHub research, and current claims about this implementation may use local repository evidence.

Initial planning research on 2026-05-02 found:

- `https://github.com/zeveck/zskills` is public and describes Z Skills as 18 Claude Code skills using `.claude/skills/<name>/SKILL.md`, with `/update-zskills` writing `.claude/zskills-config.json`.
- `https://github.com/zeveck/zskills-dev` is public, labels itself the development repository, says end users should install from `github.com/zeveck/zskills`, and describes 20 skills.
- `https://github.com/zeveck/zskills-cc` is public, describes itself as a Claude/Codex compatibility conversion, and includes `.claude/skills`, `.codex/skills`, `codex-overlays/`, `local-patches/`, scripts, tests, plans, and reports.
- `https://github.com/zeveck/zskills-codex` is public but appeared empty during planning research; that should be treated as deployment context for this implementation, not as a separate product variant.

The only expected project changes are under:

- `zskills-online-variant-report-canary/`
- `scripts/test-zskills-online-variant-report-canary.sh`
- `reports/zskills-variant-research-report.md`
- `reports/plan-zskills-online-variant-report-canary.md`
- this plan file's progress tracker

## Non-Goals

- Do not modify skills, support scripts, installer behavior, README, existing canary output directories, or unrelated plans.
- Do not push to any remote, create issues, create PRs, or alter any `github.com/zeveck` repository.
- Do not rely on stale local-only assumptions when a current GitHub source is available.
- Do not clone private repositories or require credentials. If public GitHub pages or raw files are unavailable, document the access gap.
- Do not present inferred behavior as observed fact. Every repository claim should be labeled as observed, inferred, or unknown.

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Build research harness and source ledger | ✅ Done | Created the output directory, manifest, verification script, and source ledger structure for online GitHub evidence. |
| 2. Collect current repository evidence | ✅ Done | Recorded fresh GitHub and local implementation evidence, source URLs, access gaps, dates, branches, tags, commits, directories, config, hooks, tests, and reports. |
| 3. Produce comparative analysis | ✅ Done | Created the comparative analysis covering roles, runtime/client models, installation/configuration, automation, tests, release posture, strategic differences, risks, and open questions. |
| 4. Analyze dev-to-cc/codex implications | ✅ Done | Created dev-to-cc/codex implication guidance with change-surface classification, import/adapt/reject/defer decision matrices, verification commands, release recommendations, and risk notes. |
| 5. Write final report and verify quality | ⬜ Not Started | Produce `reports/zskills-variant-research-report.md`, update the manifest, and run automated quality checks. |

## Phase Details

### Phase 1. Build Research Harness and Source Ledger

Create directory `zskills-online-variant-report-canary/`.

Create `zskills-online-variant-report-canary/manifest.txt` with exactly:

```text
phase-1-source-ledger.md
```

Create executable `scripts/test-zskills-online-variant-report-canary.sh`. The script should:

- run from the repository root;
- fail if `zskills-online-variant-report-canary/manifest.txt` is missing;
- read manifest lines into an array;
- allow progressive states after phase 1, 2, 3, 4, or 5;
- reject unknown manifest entries;
- reject out-of-order manifest entries;
- verify every listed phase file exists under `zskills-online-variant-report-canary/`;
- verify required headings and required keywords for every listed file;
- when phase 5 is complete, verify `reports/zskills-variant-research-report.md` exists;
- when phase 5 is complete, verify the final report contains source URLs for all four repositories, a current-date research note, an executive summary, a comparison matrix, a `zskills-dev` implications section, recommendations, evidence gaps, and a canary result;
- when phase 5 is complete, verify the output directory contains no unexpected top-level files.

The expected manifest order is:

```text
phase-1-source-ledger.md
phase-2-current-evidence.md
phase-3-comparative-analysis.md
phase-4-dev-implications.md
phase-5-report-quality.md
```

Create `zskills-online-variant-report-canary/phase-1-source-ledger.md`. It should include:

- heading `# Phase 1 Source Ledger`;
- section `## Research Date`;
- section `## Target Repositories`;
- section `## Required Evidence Types`;
- section `## Citation Rules`;
- section `## Evidence Gaps`;
- exact repository URLs:
  - `https://github.com/zeveck/zskills`
  - `https://github.com/zeveck/zskills-dev`
  - `https://github.com/zeveck/zskills-cc`
  - `https://github.com/zeveck/zskills-codex`
- an explicit rule that every material claim in the final report must be traceable to a GitHub URL, local file path, or clearly labeled inference;
- an explicit rule that `zskills-codex` means this local implementation, while `https://github.com/zeveck/zskills-codex` is the publication target whose current remote state should be recorded as deployment context.

After phase 1, run:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
```

Expected result: the script passes with only `phase-1-source-ledger.md` listed.

### Phase 2. Collect Current Repository Evidence

Create `zskills-online-variant-report-canary/phase-2-current-evidence.md`. It should include:

- heading `# Phase 2 Current Evidence`;
- section `## zskills`;
- section `## zskills-dev`;
- section `## zskills-cc`;
- section `## zskills-codex Implementation`;
- section `## zskills-codex Publication Target`;
- section `## Evidence Gaps and Access Limits`;
- exact terms `GitHub`, `README`, `commit`, `branch`, `tags`, `skills`, `config`, `hooks`, `tests`, and `reports`;
- the four exact repository URLs;
- a table with at least these columns: repository, observed purpose, default branch, visible commit count or revision evidence, key directories/files, install/config model, tests or validation, and evidence URL;
- at least ten GitHub source URLs total across the four repositories when available;
- at least three local source paths for this repository, such as `README.md`, `skills/`, `zskills-support/`, `.codex/zskills-config.json`, `reports/`, or `plans/`;
- a note that the report must be refreshed if GitHub changes after the research date.

Update `zskills-online-variant-report-canary/manifest.txt` to exactly:

```text
phase-1-source-ledger.md
phase-2-current-evidence.md
```

Run:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
```

Expected result: the script passes with phases 1-2 listed in order.

### Phase 3. Produce Comparative Analysis

Create `zskills-online-variant-report-canary/phase-3-comparative-analysis.md`. It should include:

- heading `# Phase 3 Comparative Analysis`;
- section `## Executive Comparison`;
- section `## Repository Roles`;
- section `## Runtime and Client Model`;
- section `## Installation and Configuration`;
- section `## Support Assets and Automation`;
- section `## Testing and Release Posture`;
- section `## Risks and Open Questions`;
- exact variant names `zskills`, `zskills-dev`, `zskills-cc`, and `zskills-codex`;
- a markdown comparison matrix with at least ten rows or dimensions;
- explicit distinction between public release, development source, cross-client compatibility conversion, and this Codex implementation, including the current state of its GitHub publication target;
- evidence-backed notes on Claude-specific behavior, Codex-specific behavior, dual-client behavior, and unknowns;
- at least one paragraph explaining how `zskills-cc` differs strategically from this `zskills-codex` implementation.

Update `zskills-online-variant-report-canary/manifest.txt` to exactly:

```text
phase-1-source-ledger.md
phase-2-current-evidence.md
phase-3-comparative-analysis.md
```

Run:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
```

Expected result: the script passes with phases 1-3 listed in order.

### Phase 4. Analyze Dev-to-CC/Codex Implications

Create `zskills-online-variant-report-canary/phase-4-dev-implications.md`. It should include:

- heading `# Phase 4 Dev Implications`;
- section `## zskills-dev Change Surfaces`;
- section `## Application Strategy for zskills-cc`;
- section `## Application Strategy for zskills-codex`;
- section `## Direct Import vs Adapt vs Reject vs Defer`;
- section `## Verification Strategy`;
- section `## Release Recommendations`;
- exact terms `zskills-dev`, `zskills-cc`, `zskills-codex`, `zskills`, `frontmatter`, `hooks`, `runner`, `tracking`, `installer`, `config schema`, `tests`, `reports`, `release`, and `migration`;
- a classification table with at least ten change categories;
- a decision matrix that says when `zskills-cc` should import directly, adapt behind a client boundary, reject, or defer;
- a decision matrix that says when `zskills-codex` should import directly, adapt to Codex-native behavior, reject, or defer;
- specific verification commands or checks that should be run in `zskills-cc` and in this local `zskills-codex` repo;
- a risk section covering stale GitHub evidence, the current publication state of `https://github.com/zeveck/zskills-codex`, client-specific runtime assumptions, generated output drift, and release timing.

Update `zskills-online-variant-report-canary/manifest.txt` to exactly:

```text
phase-1-source-ledger.md
phase-2-current-evidence.md
phase-3-comparative-analysis.md
phase-4-dev-implications.md
```

Run:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
```

Expected result: the script passes with phases 1-4 listed in order.

### Phase 5. Write Final Report and Verify Quality

Create `zskills-online-variant-report-canary/phase-5-report-quality.md`. It should include:

- heading `# Phase 5 Report Quality`;
- section `## Final Report Path`;
- section `## Quality Checks`;
- section `## Verification Commands`;
- section `## Canary Result`;
- the exact phrase `ready for maintainer review`;
- a concise checklist showing that the final report includes citations, evidence labels, comparison matrix, dev implications, recommendations, risks, and open questions.

Create `reports/zskills-variant-research-report.md`. It should be a polished standalone report with:

- heading `# ZSkills Variant Research Report`;
- section `## Executive Summary`;
- section `## Research Scope and Method`;
- section `## Source Inventory`;
- section `## Repository-by-Repository Findings`;
- section `## Comparative Matrix`;
- section `## zskills-dev Implications`;
- section `## Recommendations`;
- section `## Evidence Gaps and Risks`;
- section `## Appendix: Sources`;
- all exact names `zskills`, `zskills-dev`, `zskills-cc`, and `zskills-codex`;
- all four exact GitHub repository URLs;
- the research date and a statement that GitHub evidence may change;
- enough source URLs and local paths for a maintainer to audit major claims;
- explicit evidence labels, such as `Observed`, `Inferred`, and `Unknown`;
- recommendations for both `zskills-cc` and `zskills-codex`;
- an honest statement about whether the `github.com/zeveck/zskills-codex` publication target is populated or empty at research time.

Update `zskills-online-variant-report-canary/manifest.txt` to exactly:

```text
phase-1-source-ledger.md
phase-2-current-evidence.md
phase-3-comparative-analysis.md
phase-4-dev-implications.md
phase-5-report-quality.md
```

Run:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
find zskills-online-variant-report-canary -maxdepth 1 -type f -printf '%f\n' | sort
git status --short
```

Expected result: the script passes with all five files listed in order and the final report present.

## Acceptance Criteria

- The canary produces a standalone, source-backed report at `reports/zskills-variant-research-report.md`.
- The report uses current online GitHub evidence for all four `github.com/zeveck` repositories.
- The report treats this local working tree as `zskills-codex` and records the current remote `github.com/zeveck/zskills-codex` state as publication context.
- Every material claim is traceable to a URL, local path, or an explicit evidence label.
- The comparison covers repository purpose, audience, runtime/client model, install/config model, skills, support assets, tests, release posture, and risks.
- The `zskills-dev` implications section gives concrete import/adapt/reject/defer guidance for both `zskills-cc` and `zskills-codex`.
- `scripts/test-zskills-online-variant-report-canary.sh` passes after every phase.
- The final report includes an appendix of sources.
- `.zskills/` tracking files remain uncommitted.

## Verification

Run this after any phase:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
```

Final verification:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
find zskills-online-variant-report-canary -maxdepth 1 -type f -printf '%f\n' | sort
git status --short
```

Optional manual review:

```bash
sed -n '1,260p' reports/zskills-variant-research-report.md
rg -n 'Observed|Inferred|Unknown|https://github.com/zeveck' reports/zskills-variant-research-report.md
```

## Risks

- GitHub repository contents may change between plan drafting and execution; record the research date and revision evidence.
- GitHub HTML pages may omit details that raw files or API responses expose; prefer raw README/config/script URLs when available.
- If network access fails during execution, stop with an evidence-gap report rather than inventing current facts.
- The final report can be high quality only if phase 2 gathers enough source evidence; do not shortcut the online research.
