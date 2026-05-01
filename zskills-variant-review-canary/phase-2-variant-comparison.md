# Phase 2 Variant Comparison

## Comparison Matrix

| Variant | runtime host | instruction format | support assets | tracking model | landing model | likely integration risk |
| --- | --- | --- | --- | --- | --- | --- |
| `zskills` | Observed here only as the upstream source named in `README.md`; inferred to target Claude Code because local Codex wrappers describe upstream text as Claude-oriented. | Inferred slash-command and Claude skill text, with local archived references under `skills/*/references/upstream-claude-adapted.md`. | Inferred original support scripts, hooks, templates, and docs mirrored or adapted under `zskills-support/`. | Inferred Claude-oriented hook and file tracking behavior; local evidence shows the Codex port preserves file-backed tracking gates. | Inferred upstream workflow includes worktree, PR, and landing gates; local evidence only confirms the Codex adaptation of those concepts. | Medium: upstream changes may be useful, but Claude-only assumptions need review before reuse. |
| `zskills-cc` | Mentioned in `README.md` as the dual Claude/Codex distribution shape to compare against; no local checkout is present. | Inferred to need instruction material that can serve Claude Code and Codex without importing unsupported runtime behavior into either host. | Evidence gap locally; likely needs shared support assets plus host-specific wrappers or installation paths. | Evidence gap locally; likely needs compatibility between Claude hooks and Codex file-backed tracking. | Evidence gap locally; likely must reconcile Claude Code workflows with Codex manual git and runner constraints. | High: dual-runtime support can hide host-specific assumptions unless the split is explicit. |
| `zskills-codex` | Directly observed in this repository as a Codex-only port. `README.md` says it replaces Claude-specific runtime mechanics with Codex-native behavior. | Directly observed `SKILL.md` files under `skills/` with Codex runtime rules and archived upstream references. | Directly observed `zskills-support/` scripts, config schema, docs, hooks kept as templates or guardrails, and runner support. | Directly observed `.zskills/` marker convention in the current canary run and file-backed gates described by `README.md` and `skills/run-plan/SKILL.md`. | Directly observed run-plan workflow supports direct, cherry-pick, and PR modes using normal git commands and report evidence. | Medium: the port is well documented locally, but every upstream change still needs Codex adaptation review. |
| `zskills-dev` | Not locally available as a checkout or branch in this repository. | Evidence gap; do not claim current dev instruction changes without a fresh diff. | Evidence gap; support asset changes must be refreshed from the actual `zskills-dev` diff. | Evidence gap; runner, tracking, and marker changes must be treated as unknown until reviewed. | Evidence gap; landing behavior must be reviewed from actual changes rather than inferred. | High: current facts are unavailable locally, so future adoption depends on fresh evidence. |

## Runtime Assumptions

The observed local evidence is strongest for `zskills-codex`: this repository's `README.md`, `skills/`, `zskills-support/`, `plans/`, `reports/`, and canary scripts describe a Codex-native distribution. The local files repeatedly distinguish Codex behavior from Claude-only mechanisms such as automatic Claude hooks, `.claude/settings.json`, Claude cron tools, and Claude task syntax.

For `zskills`, `zskills-cc`, and `zskills-dev`, this canary has partial evidence only. The upstream `zskills` name and source commit are referenced locally, and `zskills-cc` is mentioned as a different distribution shape, but their current trees are not checked out here. `zskills-dev` is a readiness target rather than a locally observed source of concrete changes.

## Porting Differences

`zskills-codex` should treat upstream material as source content that may need conversion. Skill text can often be adapted, but runtime policy, hooks, runner behavior, config lookup, and landing gates must preserve Codex-native behavior. That means normal git commands, explicit worktrees, file-backed tracking, and runner-backed `finish auto` remain the local compatibility baseline.

`zskills-cc` likely has a broader compatibility problem than `zskills-codex` because it must support more than one host. The local evidence does not prove how `zskills-cc` is organized, so the practical porting rule is conservative: import shared prose or support logic only when it is host-neutral, and adapt anything that depends on Claude Code or Codex runtime mechanics.

## Evidence Gaps

- No local checkout of current `zskills` was found beyond mirrored references and source attribution.
- No local checkout of `zskills-cc` was found, so dual-runtime details are inference.
- No local checkout or diff for `zskills-dev` was found, so current dev changes are unknown.
- The comparison above separates observed local evidence from inference; anything not backed by files in this repository should be refreshed before implementation.
