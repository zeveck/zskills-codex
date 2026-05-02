# ZSkills Variant Research Report

Research date: 2026-05-02. GitHub evidence may change after this date; refresh branch, tag, README, and directory evidence before using this report for a release decision.

Evidence labels:

- Observed: directly visible in GitHub evidence from the listed URLs, refreshed `git ls-remote` output, or local repository paths.
- Inferred: reasoned from observed evidence, but not directly stated by a source.
- Unknown: not visible from public unauthenticated evidence during this pass.

Canary Result: the canary produced a source-backed standalone report with citations, evidence labels, comparative analysis, `zskills-dev` implications, recommendations, and explicit evidence gaps.

## Executive Summary

Observed: `zskills` at `https://github.com/zeveck/zskills` is the public Claude Code release baseline. Its README describes 18 skills, `.claude/skills/<name>/SKILL.md` skill placement, `/update-zskills`, hook installation, `.claude/zskills-config.json`, and `/run-plan` phase execution with cherry-pick, PR, or direct landing. Refreshed revision evidence on 2026-05-02 showed `main` at `14dea81da487b2904ea7d69a27295f1869206cdf` and tag `2026.04.0` resolving to the same commit.

Observed: `zskills-dev` at `https://github.com/zeveck/zskills-dev` is the development source. Its README warns that end users should install from `github.com/zeveck/zskills`, says content may be pre-release, and describes release filtering that strips dev-only artifacts. Earlier Phase 2 evidence saw `main` at `907b2bd8e2e8d14b516a6b07ccae8401bced4417`; refreshed `git ls-remote` evidence during Phase 5 saw `main` at `3e68b5e0c1352bf02dcdb56456ec8650d2fe9e0b`, confirming active movement during this canary.

Observed: `zskills-cc` at `https://github.com/zeveck/zskills-cc` is the Claude/Codex compatibility conversion. Its README says one source tree generates a Codex install with compatibility adapters and a Claude install without Codex-specific adapter text. Refreshed revision evidence showed `main` at `0791081b77999cd4410b56bdeae10a94b24486d0` and tag `2026.04.0-cc.0` resolving to `7f8b253b43ac311f4bd6998cd8a754d61963a753`.

Observed: this local checkout is the actual `zskills-codex` implementation under review. Local `README.md` identifies it as a Codex-only port of `github.com/zeveck/zskills` at upstream commit `14dea81da487b2904ea7d69a27295f1869206cdf`, with Codex-native behavior under `skills/`, `zskills-support/`, `.codex/zskills-config.json`, `scripts/`, `plans/`, and `reports/`.

Observed: `https://github.com/zeveck/zskills-codex` is the intended publication target. Public Git evidence observed during this canary showed no branch or tag refs via `git ls-remote`, and earlier API evidence recorded size `0`, no root contents, and no usable commit evidence. Inferred: the publication target is empty or unpopulated at research time, while the local repository is the implementation.

## Research Scope and Method

The research compared four targets: `zskills`, `zskills-dev`, `zskills-cc`, and `zskills-codex`. Current GitHub evidence came from repository pages, raw README files, GitHub URLs listed in `zskills-online-variant-report-canary/phase-2-current-evidence.md`, and Phase 5 `git ls-remote` checks. Local implementation evidence came from paths in this checkout, especially `README.md`, `skills/`, `zskills-support/`, `.codex/zskills-config.json`, `scripts/`, `plans/`, and `reports/`.

This report treats `zskills-codex` as two related but distinct things: the local Codex-only implementation in this working tree, and the public GitHub publication target at `https://github.com/zeveck/zskills-codex`. Claims about product behavior use local paths. Claims about remote publication state use GitHub evidence and are labeled as deployment context.

## Source Inventory

| Source | Evidence used | Label |
| --- | --- | --- |
| `https://github.com/zeveck/zskills` | Public release repository, README, skills/config/hooks/scripts/tests/reports/plans directories, branch and tag revision evidence. | Observed |
| `https://raw.githubusercontent.com/zeveck/zskills/main/README.md` | 18-skill Claude Code description, `.claude/skills`, `/update-zskills`, hooks, `.claude/zskills-config.json`, landing modes. | Observed |
| `https://github.com/zeveck/zskills-dev` | Development repository, README warning, active branches, release workflow surfaces, refreshed `main` movement. | Observed |
| `https://raw.githubusercontent.com/zeveck/zskills-dev/main/README.md` | Development warning, 20-skill README claim, pre-release and release filtering statements. | Observed |
| `https://github.com/zeveck/zskills-cc` | Compatibility conversion repository, generated Claude and Codex outputs, conversion pipeline surfaces. | Observed |
| `https://raw.githubusercontent.com/zeveck/zskills-cc/main/README.md` | Dual-client strategy, `.claude/skills`, `.codex/skills`, overlays, local patches, templates, tests, reports. | Observed |
| `https://github.com/zeveck/zskills-codex` | Publication target URL and empty or unpopulated state. | Observed |
| `README.md` | Local Codex-only purpose, upstream commit, install model, runtime policy, runner behavior. | Observed |
| `skills/` | Local installed skill wrappers and Codex skill set. | Observed |
| `zskills-support/` | Codex-native support scripts, config schema, runner, gates, post-run invariants, archived upstream references. | Observed |
| `.codex/zskills-config.json` | Local config lookup and default cherry-pick landing configuration. | Observed |
| `scripts/test-zskills-online-variant-report-canary.sh` | Report quality gates used by this canary. | Observed |

## Repository-by-Repository Findings

### zskills

Observed: `zskills` is the public release repository for Claude Code users. The README says the distribution contains 18 skills and describes each skill as a `.claude/skills/<name>/SKILL.md` prompt file. It positions `/draft-plan`, `/run-plan`, `/update-zskills`, isolated worktrees, fresh reviewer verification, and configurable landing modes as the product workflow.

Observed: its install/config model is Claude-specific: clone `https://github.com/zeveck/zskills.git`, copy `skills/*/` into `.claude/skills/`, run `/update-zskills`, and let that command create `CLAUDE.md`, install hooks and scripts, register hooks, write `.claude/zskills-config.json`, verify dependencies, and report gaps.

Inferred: this repository is the stable baseline for downstream ports. Direct imports into Codex-specific variants are safe only when the content is client-neutral or can be adapted away from Claude hook and slash-command assumptions.

### zskills-dev

Observed: `zskills-dev` is the development source. The README explicitly says end users should install from `https://github.com/zeveck/zskills`, warns that content is pre-release, and says release workflow strips dev-only artifacts before publishing to production. The README describes 20 skills, while Phase 2 evidence noted that visible top-level skill directories require careful classification rather than treating one count as authoritative.

Observed: `zskills-dev` moved during this canary. Phase 2 recorded `main` at `907b2bd8e2e8d14b516a6b07ccae8401bced4417`; Phase 5 refreshed evidence saw `main` at `3e68b5e0c1352bf02dcdb56456ec8650d2fe9e0b`. Tag `2026.04.0` still resolved to the same upstream public release commit as `zskills`.

Inferred: `zskills-dev` is the best upstream signal for upcoming workflow changes, but it is not a drop-in dependency. Downstream maintainers should classify changes by skill content, frontmatter, hooks, runner behavior, tracking, installer behavior, config schema, tests, reports, release workflow, and migration impact.

### zskills-cc

Observed: `zskills-cc` is a compatibility conversion, not a simple fork. Its README says "CC" means Claude/Codex compatibility and says one source tree generates both a Codex install with compatibility adapters and a Claude install without Codex-specific adapter text.

Observed: its key surfaces include `.claude/skills/`, `.codex/skills/`, `codex-overlays/`, `local-patches/`, `templates/`, `scripts/`, `tests/`, `plans/`, and `reports/`. The README describes fidelity tests, drift checks, helper behavior, installation checks, generated output, upstream conformance, tracking integration, and scheduler behavior.

Inferred: the central risk for `zskills-cc` is generated output drift or client leakage. Claude output must remain Claude-native, Codex output must carry the right compatibility adapters, and shared source changes must pass both client boundaries.

### zskills-codex

Observed: this local implementation is Codex-only. It does not try to be a dual Claude/Codex distribution. Local `README.md` says it preserves ZSkills workflow intent while replacing Claude-specific runtime mechanics with Codex-native behavior.

Observed: the local install model uses `bash scripts/install.sh`, `$CODEX_HOME/skills/`, `$CODEX_HOME/zskills-support/`, and `.codex/zskills-config.json`. Runtime policy explicitly avoids Claude Code hooks, `.claude` runtime settings, and Claude cron tools. `run-plan finish auto` is runner-backed by fresh top-level `codex exec` invocations and file-backed `.zskills/tracking` gates.

Observed: local validation is represented by scripts and reports rather than a `tests/` directory in this checkout. Relevant local checks include `scripts/canary-zskills-codex.sh`, `scripts/test-simple-run-plan-canary.sh`, `scripts/test-zskills-variant-review-canary.sh`, and `scripts/test-zskills-online-variant-report-canary.sh`.

Unknown: consumers cannot audit the intended public `zskills-codex` remote implementation yet because the GitHub publication target appeared empty or unpopulated during the research window.

## Comparative Matrix

| Dimension | zskills | zskills-dev | zskills-cc | zskills-codex |
| --- | --- | --- | --- | --- |
| Primary role | Public Claude Code release. | Development source for future release work. | Cross-client compatibility conversion. | Codex-only implementation in this local checkout. |
| Audience | Claude Code users. | Maintainers. | Maintainers and testers of Claude/Codex compatibility. | Codex users and maintainers. |
| Runtime model | Claude Code skills and hooks. | Claude Code development workflow, possibly pre-release. | Generated Claude and Codex outputs. | Codex-native skills, runner, and gates. |
| Skill location | `.claude/skills` after install; source `skills/`. | `.claude/skills` and source `skills/`. | Checked-in `.claude/skills` and `.codex/skills`. | Source `skills/`, installed to `$CODEX_HOME/skills`. |
| Config path | `.claude/zskills-config.json`. | `.claude/zskills-config.json` in release model. | Client-scoped `.claude` and `.codex` config. | `.codex/zskills-config.json`. |
| Hooks | Claude hooks installed by `/update-zskills`. | Hook changes may be active or experimental. | Must keep hook assumptions client-scoped. | Claude hooks rejected; manual gates and runner scripts replace them. |
| Runner behavior | `/run-plan` with worktrees and verifier agents. | Candidate changes to runner behavior. | Compatibility text and helpers for both clients. | `zskills-runner.sh`, fresh `codex exec`, tracking markers. |
| Automation assets | `config/`, `hooks/`, `scripts/`, `tests/`, `reports/`, `plans/`. | Adds release workflow, canaries, branches, and in-progress reports. | `codex-overlays/`, `local-patches/`, `templates/`, generation scripts, tests. | `zskills-support/`, installer, canary scripts, plans, reports. |
| Release posture | Public baseline tag `2026.04.0`. | Moving main; pre-release. | Compatibility preview tag `2026.04.0-cc.0`. | Local implementation ready for validation; public target empty. |
| Main risk | Claude-specific assumptions copied into non-Claude contexts. | Importing experimental or dev-only content prematurely. | Generated output drift and client leakage. | Diverging from upstream without enough publication and validation evidence. |
| Recommended use | Treat as canonical public release baseline. | Mine for candidate changes after classification. | Preserve source-to-output fidelity and client boundaries. | Maintain directly as Codex-native, not as a dual-client generator. |

## zskills-dev Implications

`zskills-dev` should be treated as an intake stream. Its changes need classification before they are applied to either `zskills-cc` or `zskills-codex`.

| Change surface | zskills-cc action | zskills-codex action |
| --- | --- | --- |
| Client-neutral skill body improvements | Import directly if generated outputs remain valid. | Import directly if Codex skill semantics are unchanged. |
| Claude-specific hook behavior | Adapt behind a client boundary. | Reject direct hook assumptions or adapt to Codex gates. |
| Runner and tracking changes | Adapt separately for Claude and Codex outputs. | Adapt to `zskills-runner.sh`, top-level `codex exec`, and canonical markers. |
| Installer/config changes | Generate separate `.claude` and `.codex` paths. | Rewrite to `$CODEX_HOME`, `.codex`, and local support scripts. |
| Unsupported frontmatter | Map or reject per generated client. | Reject if Codex skill loading cannot support it. |
| Dev-only canaries and release machinery | Defer unless adopted by compatibility release policy. | Defer until publication target and release process are established. |
| Tests and report conventions | Import concepts and add drift/fidelity checks. | Import or adapt shell canaries and parser-stable report headings. |

Recommended verification for `zskills-cc`:

```bash
git status --short
bash tests/test-zskills-fidelity.sh
bash tests/test-zskills-helpers.sh
bash tests/test-zskills-scheduler.sh
bash tests/test-zskills-install.sh
python scripts/verify-generated-zskills.py --allow-local-upstream --patch-queue-entry clear-tracking-recursive
```

Recommended verification for this `zskills-codex` implementation:

```bash
git status --short
bash scripts/canary-zskills-codex.sh
bash scripts/test-simple-run-plan-canary.sh
bash scripts/test-zskills-variant-review-canary.sh
bash scripts/test-zskills-online-variant-report-canary.sh
bash zskills-support/scripts/zskills-gate.sh --help
```

## Recommendations

For `zskills-cc`: keep the compatibility boundary explicit. Every imported `zskills-dev` change should prove that generated Claude output remains free of Codex adapter text and generated Codex output keeps the right Codex compatibility instructions. Add or update drift checks whenever overlays, templates, local patches, or generated skill outputs change.

For `zskills-codex`: preserve workflow intent, but adapt runtime mechanics to Codex-native behavior. Do not import Claude hooks, `.claude` config paths, Claude cron assumptions, or slash-command-only instructions without rewriting them into the local Codex skill, runner, support-script, and report model.

For maintainers of both downstream variants: refresh GitHub evidence immediately before release migration. `zskills-dev` moved during this canary, which is concrete evidence that stale branch claims can become wrong within a single run.

For publication: populate `https://github.com/zeveck/zskills-codex` before treating it as an auditable distribution. Until then, release notes should say the remote target is empty or unpopulated and direct reviewers to the local implementation evidence.

## Evidence Gaps and Risks

Observed risk: GitHub evidence may change after 2026-05-02. This already happened for `zskills-dev` `main` during the canary.

Observed risk: the `https://github.com/zeveck/zskills-codex` publication target appeared empty or unpopulated. The report can evaluate the local implementation, but external consumers cannot yet audit that remote.

Observed constraint: this local checkout has no configured `origin` remote even though `.codex/zskills-config.json` names `origin`; remote freshness for the local repo could not be checked through the configured remote.

Inferred risk: Claude-specific behavior, especially hooks, `.claude` paths, slash-command language, scheduler assumptions, and verifier-agent language, can break when copied into Codex without adaptation.

Inferred risk: `zskills-cc` can regress through generated output drift even when source changes are correct. Its tests need to prove both client outputs remain valid.

Unknown: unauthenticated public evidence does not prove every private release setting, issue state, or workflow run result. It also does not prove that every runtime behavior works in both Claude and Codex clients without executing repository-local tests.

Open questions:

- Which `zskills-dev` changes after public tag `2026.04.0` are intended for the next public `zskills` release?
- Should `zskills-cc` remain a compatibility preview or become the preferred dual-client distribution?
- When will `https://github.com/zeveck/zskills-codex` be populated, and what release gate should certify it?
- Should this Codex-only repository add a first-class `tests/` directory or continue organizing validation through scripts and reports?

## Appendix: Sources

GitHub repository URLs:

- `https://github.com/zeveck/zskills`
- `https://github.com/zeveck/zskills-dev`
- `https://github.com/zeveck/zskills-cc`
- `https://github.com/zeveck/zskills-codex`

Raw README URLs:

- `https://raw.githubusercontent.com/zeveck/zskills/main/README.md`
- `https://raw.githubusercontent.com/zeveck/zskills-dev/main/README.md`
- `https://raw.githubusercontent.com/zeveck/zskills-cc/main/README.md`

Directory and file evidence URLs recorded in Phase 2:

- `https://github.com/zeveck/zskills/tree/main/skills`
- `https://github.com/zeveck/zskills/tree/main/.claude/skills`
- `https://github.com/zeveck/zskills/tree/main/config`
- `https://github.com/zeveck/zskills/tree/main/hooks`
- `https://github.com/zeveck/zskills/tree/main/scripts`
- `https://github.com/zeveck/zskills/tree/main/tests`
- `https://github.com/zeveck/zskills/blob/main/.github/workflows/test.yml`
- `https://github.com/zeveck/zskills-dev/blob/main/RELEASING.md`
- `https://github.com/zeveck/zskills-dev/blob/main/.github/workflows/ship-to-prod.yml`
- `https://github.com/zeveck/zskills-dev/blob/main/.github/workflows/test.yml`
- `https://github.com/zeveck/zskills-cc/tree/main/.codex/skills`
- `https://github.com/zeveck/zskills-cc/tree/main/.claude/skills`
- `https://github.com/zeveck/zskills-cc/tree/main/codex-overlays`
- `https://github.com/zeveck/zskills-cc/tree/main/local-patches`
- `https://github.com/zeveck/zskills-cc/tree/main/templates`
- `https://github.com/zeveck/zskills-cc/tree/main/tests`
- `https://github.com/zeveck/zskills-cc/tree/main/reports`

Refreshed revision evidence from Phase 5 `git ls-remote`:

- `https://github.com/zeveck/zskills.git`: `main` at `14dea81da487b2904ea7d69a27295f1869206cdf`; tag `2026.04.0` resolves to that commit.
- `https://github.com/zeveck/zskills-dev.git`: `main` at `3e68b5e0c1352bf02dcdb56456ec8650d2fe9e0b`; tag `2026.04.0` resolves to `14dea81da487b2904ea7d69a27295f1869206cdf`.
- `https://github.com/zeveck/zskills-cc.git`: `main` at `0791081b77999cd4410b56bdeae10a94b24486d0`; tag `2026.04.0-cc.0` resolves to `7f8b253b43ac311f4bd6998cd8a754d61963a753`.
- `https://github.com/zeveck/zskills-codex.git`: no branch or tag refs returned during this pass.

Local source paths:

- `README.md`
- `skills/`
- `zskills-support/`
- `.codex/zskills-config.json`
- `scripts/install.sh`
- `scripts/canary-zskills-codex.sh`
- `scripts/test-zskills-online-variant-report-canary.sh`
- `plans/zskills-online-variant-report-canary.md`
- `reports/plan-zskills-online-variant-report-canary.md`
