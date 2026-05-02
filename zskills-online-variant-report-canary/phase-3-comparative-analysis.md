# Phase 3 Comparative Analysis

Research date: 2026-05-02. This analysis is source-backed by `zskills-online-variant-report-canary/phase-1-source-ledger.md`, `zskills-online-variant-report-canary/phase-2-current-evidence.md`, current GitHub URLs listed there, and local paths in this repository. GitHub evidence may change after the research date.

Evidence labels:

- Observed: directly visible in GitHub evidence or local files.
- Inferred: reasoned from observed evidence, but not directly stated by a source.
- Unknown: not visible from public unauthenticated evidence during this pass.

## Executive Comparison

Observed: `zskills` is the public release repository for Claude Code users. It presents a stable install path, 18 documented Z Skills, Claude-specific `.claude/skills/<name>/SKILL.md` placement, hook installation, and `.claude/zskills-config.json` configuration. The strongest evidence is the repository README, skills tree, config/hooks/scripts directories, tests, reports, plans, `.github/workflows/test.yml`, and tag `2026.04.0` at commit `14dea81da487b2904ea7d69a27295f1869206cdf`.

Observed: `zskills-dev` is the development source. Its README tells end users to install from `https://github.com/zeveck/zskills`, warns that content may be pre-release, and describes a release workflow that strips dev-only artifacts and publishes to production. It is newer than the public release tag in the Phase 2 evidence: `main` was observed at `907b2bd8e2e8d14b516a6b07ccae8401bced4417`, while tag `2026.04.0` still points to the public release commit.

Observed: `zskills-cc` is a cross-client compatibility conversion. Its README says one source tree generates both `.claude/skills` and `.codex/skills`, with Codex compatibility adapters and Claude output that omits Codex-specific adapter text. Its strategy is dual-client distribution and generated fidelity, not a pure Codex rewrite.

Observed: `zskills-codex` in this local checkout is the Codex-only implementation. Its README and local paths (`skills/`, `zskills-support/`, `.codex/zskills-config.json`, `scripts/install.sh`, `plans/`, `reports/`) show a port that preserves Z Skills workflow intent while replacing Claude runtime mechanics with Codex-native behavior. Unknown/Observed split: the GitHub publication target `https://github.com/zeveck/zskills-codex` was public but appeared empty or unpopulated through the API during Phase 2, so the remote is deployment context rather than evidence of the implementation.

## Repository Roles

| Dimension | zskills | zskills-dev | zskills-cc | zskills-codex |
| --- | --- | --- | --- | --- |
| Primary role | Observed public release for Claude Code Z Skills. | Observed development source for upcoming release work. | Observed cross-client compatibility conversion. | Observed Codex-only implementation in this local repository. |
| Audience | Claude Code end users. | Maintainers and contributors preparing releases. | Users or maintainers needing both Claude and Codex installs. | Codex users and maintainers evaluating a native Codex port. |
| Release posture | Public release; tag `2026.04.0` observed. | Pre-release; active branches and newer `main` observed. | Compatibility preview; tag `2026.04.0-cc.0` observed. | Local implementation exists; GitHub publication target appeared empty. |
| Runtime client | Claude-specific. | Claude-specific upstream development source. | dual-client: Claude plus Codex generated outputs. | Codex-specific. |
| Skill location | `.claude/skills/` and `skills/`. | `.claude/skills/` and `skills/`. | `.claude/skills/` plus `.codex/skills/`. | `skills/` installed to `$CODEX_HOME/skills/`. |
| Config model | `.claude/zskills-config.json`. | Release source for `.claude` config behavior. | Compatibility generation and client-specific outputs. | `.codex/zskills-config.json` with Codex-native config schema assets. |
| Automation model | Claude hooks and scripts. | Claude hooks, scripts, tests, release workflow, and canary work. | Conversion pipeline, overlays, local patches, tests, generated manifests. | Support scripts under `zskills-support/`, including runner, gate, post-run invariants, and worktree helper. |
| Testing evidence | `.github/workflows/test.yml`, `tests/`, skill verification workflows. | `.github/workflows/test.yml`, `ship-to-prod.yml`, `tests/`, plans, reports. | `tests/`, reports, generated manifests, drift/fidelity checks described in README. | `scripts/canary-zskills-codex.sh`, canary test scripts, plans, reports; local `tests/` absent. |
| Repository state evidence | Public repo page, README, trees, commit, tag. | Public repo page, README, branches, workflows, commit, tag. | Public repo page, README, generated trees, commit, tag. | Local files for implementation; GitHub API evidence for publication target. |
| Main risk | Claude-specific automation may not transfer to other clients. | Development changes may be unstable or dev-only. | Generated outputs can drift from source or hide client-specific assumptions. | Codex port can diverge from upstream and publication target is not populated. |
| Evidence confidence | High for public release shape. | High for repository role; medium for exact release contents until release packaging is inspected. | High for stated compatibility strategy; medium for workflow coverage because one workflow check was unavailable. | High for local implementation; low for remote publication contents because root contents were unavailable. |
| Recommended interpretation | Treat as canonical public release baseline. | Treat as source of candidate changes requiring triage. | Treat as bridge product with generation boundaries. | Treat as native Codex product; do not infer state from empty remote. |

The roles should remain distinct. `zskills` is the public release; `zskills-dev` is the development source; `zskills-cc` is a cross-client compatibility conversion; and `zskills-codex` is this Codex implementation, with the current state of its GitHub publication target recorded separately as empty or unpopulated deployment context.

## Runtime and Client Model

Observed Claude-specific behavior appears in `zskills` and `zskills-dev`: skills are documented as `.claude/skills/<name>/SKILL.md`, installation centers on `/update-zskills`, and the config target is `.claude/zskills-config.json`. The Phase 2 evidence also records hooks and scripts directories, which are part of the Claude-oriented automation surface.

Observed Codex-specific behavior appears in this local `zskills-codex` implementation: the README describes a Codex-only port, installation uses `bash scripts/install.sh`, skills are installed into `$CODEX_HOME/skills/`, support assets are installed into `$CODEX_HOME/zskills-support/`, and project runtime config is `.codex/zskills-config.json`. The local support tree includes Codex-native runner, gate, post-run invariant, and worktree helper scripts.

Observed dual-client behavior appears in `zskills-cc`: checked-in `.claude/skills` and `.codex/skills` make a fresh clone usable by both clients, while source directories such as `codex-overlays/`, `local-patches/`, `templates/`, `scripts/`, `tests/`, `plans/`, and `reports/` support a compatibility conversion pipeline.

Unknown: public unauthenticated evidence does not prove that all runtime assumptions behave identically across clients. Hooks, frontmatter, sub-agent/delegation language, runner contracts, and tracking marker semantics should be tested in each client-specific repository before being promoted downstream; those cross-client behaviors remain unknown until direct verification proves them.

## Installation and Configuration

Observed: `zskills` instructs users to clone `https://github.com/zeveck/zskills.git`, copy skill directories into `.claude/skills/`, and run `/update-zskills`. The install/config model writes `.claude/zskills-config.json`, installs hooks and scripts, verifies dependencies, and reports gaps.

Observed: `zskills-dev` uses the same public install destination in its README for end users, but as a development source it also carries release machinery such as `RELEASING.md` and `.github/workflows/ship-to-prod.yml`. Inferred: installation behavior from `zskills-dev` should not be copied directly to downstream products until release filtering and dev-only artifacts are understood.

Observed: `zskills-cc` is designed around generated client outputs. Inferred: its installation and configuration model should preserve a client boundary, because the README explicitly distinguishes Codex output with compatibility adapters from Claude output without Codex adapter text.

Observed: `zskills-codex` uses `bash scripts/install.sh`, `$CODEX_HOME/skills/`, `$CODEX_HOME/zskills-support/`, and `.codex/zskills-config.json`. Inferred: changes from upstream that mention `.claude`, hooks, or Claude-only scheduling need Codex-native adaptation before import.

## Support Assets and Automation

Observed: `zskills` and `zskills-dev` include config, hooks, scripts, tests, reports, and plans. These are part of the Claude release and development automation story.

Observed: `zskills-dev` includes additional release and development evidence, including `RELEASING.md`, `.github/workflows/ship-to-prod.yml`, active feature/fix/doc branches, canary plans, and reports. Inferred: `zskills-dev` is the right place to discover upcoming change surfaces, but not every change belongs in public or downstream variants.

Observed: `zskills-cc` has compatibility-specific support assets: `codex-overlays/`, `local-patches/`, `templates/`, generated `.codex/skills`, generated `.claude/skills`, tests, reports, and a generation manifest. Inferred: its automation must validate source-to-output fidelity and ensure Codex adapter text does not contaminate Claude output.

Observed: this `zskills-codex` implementation has `zskills-support/` assets, including `zskills-runner.sh`, `zskills-gate.sh`, `post-run-invariants.sh`, `worktree-add-safe.sh`, and a Codex config schema. Inferred: those are native product surfaces, not temporary compatibility overlays, so they should be maintained directly rather than regenerated from a dual-client tree unless the project chooses to converge with `zskills-cc`.

## Testing and Release Posture

Observed: `zskills` has public release evidence and CI/test evidence through `.github/workflows/test.yml` and `tests/`. Its release posture is the canonical public Claude baseline.

Observed: `zskills-dev` has the most active release posture: newer `main`, active branches, `RELEASING.md`, `ship-to-prod.yml`, tests, reports, and plans. Its content should be treated as candidate upstream input with pre-release risk.

Observed: `zskills-cc` has a compatibility preview posture with generated client outputs, tests, reports, and tag `2026.04.0-cc.0`. Unknown: one workflow path was not verified in Phase 2, so workflow claims should stay limited to observed tests/reports/manifests and README-described validation.

Observed: this local `zskills-codex` implementation has canary scripts and reports but no local `tests/` directory. Inferred: its release posture depends on scripts, plan canaries, skill-by-skill verification, and post-run tracking invariants. The current GitHub publication target being empty increases release risk because consumers cannot audit the intended remote content yet.

`zskills-cc` differs strategically from this `zskills-codex` implementation because it is a bridge and conversion system: it preserves Claude and Codex outputs side by side and must keep generated artifacts aligned with source, overlays, and local patches. This `zskills-codex` repository is strategically narrower: it can replace Claude assumptions directly with Codex-native instructions, support scripts, config paths, and runner behavior without preserving Claude install fidelity. That gives `zskills-codex` a simpler runtime contract, but it also means divergence from upstream must be tracked deliberately because there is no dual-output generation pipeline to expose drift automatically.

## Risks and Open Questions

- Observed risk: GitHub evidence may change after 2026-05-02, so current repository claims need refresh before maintainer decisions.
- Observed risk: `https://github.com/zeveck/zskills-codex` appeared empty or unpopulated; publishing this local implementation remains a deployment gap.
- Inferred risk: `zskills-dev` may include experimental, canary, or dev-only artifacts that should not be imported wholesale into `zskills-cc` or `zskills-codex`.
- Inferred risk: Claude-specific hooks, `.claude` config paths, slash-command language, and automation assumptions require adaptation for Codex-specific behavior.
- Inferred risk: `zskills-cc` needs generated-output drift checks because it has both `.claude/skills` and `.codex/skills`.
- Unknown: exact compatibility of every skill frontmatter field, hook behavior, and runner state transition across Claude and Codex clients has not been proven by Phase 3 analysis.
- Unknown: unauthenticated GitHub evidence did not provide complete commit counts and did not expose populated contents for the `zskills-codex` publication target.
