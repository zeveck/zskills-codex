# Phase 3 Adoption Surfaces

This phase maps likely adoption touchpoints for `zskills-codex` and `zskills-cc` when future `zskills-dev` changes are ready for review. The map is based on local evidence in this repository plus clearly labeled inference for variants that are not checked out locally.

## zskills-codex Surfaces

`zskills-codex` has direct local evidence in this repository. The primary adoption surfaces are:

- `skills/`: Codex skill frontmatter, Codex runtime rules, workflow steps, and archived upstream references.
- `zskills-support/`: runner support, gate scripts, report helpers, installer references, docs, hook templates, and reusable support scripts.
- `scripts/`: project-facing installer and canary verification scripts that exercise local behavior.
- `plans/` and `reports/`: examples of durable progress tracking, verification reports, and landing evidence.
- `.zskills/` runtime state: local tracking markers used by runner-backed workflows, kept out of commits.
- configuration lookup: `.codex/zskills-config.json`, `zskills-config.json`, and legacy `.claude/zskills-config.json` compatibility rules described by local skill text.

For `zskills-codex`, upstream changes should be applied only after checking whether they preserve Codex-native behavior. The port must keep normal git commands, explicit worktree handling, file-backed tracking, runner-backed automation, and Codex-compatible configuration semantics.

## zskills-cc Surfaces

`zskills-cc` is not locally checked out, so this section is an inference from the local comparison material. A dual-runtime distribution would likely need these adoption surfaces:

- shared skill source or generated skill text that can target both Claude Code and Codex.
- host-specific wrappers for instruction format, runtime policy, configuration, hooks, and runner behavior.
- support scripts that separate portable shell logic from host-specific command invocation.
- installer logic that places skills, support assets, hooks, and configuration in the correct host locations.
- tracking compatibility rules that make marker names and report expectations stable across both hosts.
- test fixtures that prove the same upstream change does not silently depend on one runtime.

The main `zskills-cc` concern is deciding what can be imported directly as shared behavior and what must be adapted behind host-specific boundaries.

## Shared Surfaces

| Upstream change type | Likely `zskills-codex` touchpoints | Likely `zskills-cc` touchpoints |
| --- | --- | --- |
| Skill prose or checklist updates | Update `skills/*/SKILL.md` and preserve Codex-specific runtime rules. | Update shared source text, then regenerate or adapt Claude and Codex variants. |
| Frontmatter metadata changes | Verify Codex skill loader compatibility before changing `skills/` frontmatter. | Verify both host loaders accept the metadata or split host-specific frontmatter. |
| Support script behavior | Review `zskills-support/scripts/` for shell portability, direct-mode safety, and runner contract changes. | Keep portable script logic shared, with host-specific wrappers for invocation and paths. |
| Runner changes | Adapt `zskills-support/scripts/zskills-runner.sh` only if it still uses top-level Codex invocations and file markers. | Define separate runner adapters for Claude Code and Codex when process launching differs. |
| Tracking marker changes | Preserve `.zskills/tracking/<pipeline-id>/` marker compatibility or add migration guidance. | Establish a compatibility layer so shared reports and markers remain parseable by both hosts. |
| Hooks changes | Treat hooks as templates or manual guardrails unless Codex has an equivalent supported mechanism. | Keep Claude hooks available for Claude Code while documenting Codex fallback behavior. |
| Installer updates | Update local installer paths and avoid creating unsupported `.claude` runtime state for Codex-only installs. | Route installer output by host, including skills, support assets, hooks, and configuration files. |
| Configuration schema changes | Keep Codex lookup order and validate direct, cherry-pick, PR, testing, CI, and dev server fields. | Validate a shared config schema plus host-specific defaults and unsupported-field handling. |
| Report format changes | Update `reports/` expectations and canary scripts so verification evidence remains durable. | Keep report headings and status lines stable for both host parsers. |
| Test harness changes | Extend canaries and support tests around Codex-native execution paths. | Run equivalent tests against both host variants and shared support assets. |

## Divergence Risks

- Cross-runtime assumptions: `zskills-codex` must preserve Codex-native behavior and must not import Claude-only runtime assumptions such as Claude task syntax, automatic Claude hooks, or `.claude/settings.json` requirements.
- Tracking drift: runner and tracking changes can break automation if marker names, directories, handoff files, or report headings diverge without a compatibility plan.
- Installer ambiguity: host-neutral installer language can still be unsafe if it writes hooks or configuration to the wrong runtime location.
- Hook semantics: `hooks` may be active automation in one host but only manual guardrails in another, so adoption notes must say which behavior is expected.
- Configuration mismatch: a shared `configuration` field can carry different defaults in each runtime unless the config schema explicitly defines unsupported or ignored fields.
- Evidence gaps: without a local `zskills-dev` diff or `zskills-cc` checkout, this surface map should guide review rather than claim current implementation facts.
