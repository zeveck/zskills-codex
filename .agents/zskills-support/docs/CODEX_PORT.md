# Z Skills Codex Port Notes

Source: `github.com/zeveck/zskills` commit `14dea81da487b2904ea7d69a27295f1869206cdf`.

This installation is a Codex-native port. Active skill files are concise wrappers installed project-locally under `.agents/skills/<name>/SKILL.md` by default; verbose upstream/Claude-oriented workflow text is archived per skill at `references/upstream-claude-adapted.md`. Shared support assets live under `.agents/zskills-support` by default; scripts in that tree are active Codex-native support only after inspection and canary coverage, while archived upstream references remain read-only compatibility material. User-level `$CODEX_HOME/skills` and `$CODEX_HOME/zskills-support` installs are explicit opt-in compatibility targets, not the default.

Codex runtime policy:
- Do not install or rely on `.claude/settings.json` for Codex.
- Do not use Claude cron tools.
- Treat Claude hooks as reference safety logic, not active enforcement.
- Project `.agents/zskills-config.json` is the normal Codex runtime config and
  should be created by new installs. Legacy fallbacks exist only for older
  repos and compatibility checks.
- Use explicit git worktrees. Implementation delegation needs explicit user authorization; verifier/reviewer sub-agents may be used only when allowed by the current Codex delegation policy. If they are unavailable or not authorized, run inline review, disclose the reduced assurance, and do not present it as fresh sub-agent verification.
- Use `.agents/zskills-support/config/zskills-config.schema.json` as the shared config schema when installed in a project. Active workflows should honor `testing.*`, `dev_server.*`, `ui.file_patterns`, and `ci.*` in addition to `execution.*`; `agents.min_model` is advisory only.

Shared landing contract:
- `execution.base_branch` defaults to `main`; `execution.remote` defaults to `origin`.
- `execution.landing: "direct"` works on the current branch/main only with clean-tree and unrelated-change checks; if `execution.main_protected` is true, active workflows must stop unless the user explicitly overrides after warning.
- `execution.landing: "cherry-pick"` works in a manual git worktree, verifies, then cherry-picks scoped commits to the configured base branch. This is the default.
- `execution.landing: "pr"` / locked-main PR works in a manual branch/worktree using `execution.branch_prefix`, pushes the branch to the configured remote, creates a PR, and never pushes directly to main.

Canonical tracking markers:
- `requires.verify-changes.<tracking-id>` before verifier handoff.
- `step.run-plan.<tracking-id>.implement`, `.verify`, `.report`, `.land`, and `fulfilled.run-plan.<tracking-id>` for plan phases.
- `handoff.run-plan.<tracking-id>` between chunked `finish` turns.
- `pipeline.fix-issues.<sprint-id>`, `step.fix-issues.<sprint-id>.*`, `issue.<issue-id>.*`, and `fulfilled.verify-changes.<sprint-id>` for issue sprints.

`.agents/zskills-support/scripts/zskills-gate.sh` is a Codex-native helper for pre-land, pre-continue, and pre-push checks. It checks ignored tracking files, required markers, persistent reports, and untracked artifacts without running destructive commands.
`.agents/zskills-support/scripts/zskills-runner.sh` is also Codex-native support code. It is not an upstream Claude cron wrapper and must stay decoupled from `.claude/settings.json`, Claude hooks, and Claude scheduler tools.

Codex does not hook-enforce these settings. Every landing-capable workflow must check the config before committing, landing, or pushing.

Chunked finish and external runner:
- Interactive `run-plan <plan> finish` executes one substantive phase and stops with a durable handoff.
- Unattended `run-plan <plan> finish auto` requires an external runner; without one, it degrades to the same one-chunk handoff.
- The Codex-native runner contract is a bounded state machine around fresh `codex exec` invocations. It must not use `codex exec resume`, in-agent recursion, or sub-agent loops to simulate re-entry.
- Runner state must be derived from plan/report hashes, `.zskills/tracking/` markers, `zskills-gate.sh`, post-run invariants, and git state rather than Codex prose or exit code alone.
- Direct mode is refused for unattended runner execution unless `runner.allow_direct_unattended` is explicitly enabled and clean-tree/main-protection checks pass.
- Dangerous bypass is not a supported default. `runner.sandbox` defaults to `workspace-write`; `danger-full-access` is only appropriate inside an external disposable sandbox.
- Completed chunks run post-land gate checks and `post-run-invariants.sh` before completion is declared.
- Terminal stops include no progress, missing handoff, missing report or verifier markers, failed gates, dirty project artifacts, stale git worktree residue, unsafe merge/rebase/cherry-pick state, nonzero child exit, max chunks, wall-clock timeout, and idle timeout.

Runner validation:
- `.agents/zskills-support/tests/runner/run.sh all` must pass after runner or shared gate changes in installed projects; in this source repo, run `zskills-support/tests/runner/run.sh all`.
- Named canaries cover multi-chunk completion, max-chunk stop, direct refusal, cherry-pick completion evidence, PR dry-run immutability, stale worktree refusal, missing report, missing verifier markers, dirty artifacts, no-progress blocking, nonzero child exit, timeout, and idle-timeout behavior.
- `update-zskills` maintenance must preserve these canaries when refreshing upstream support assets.

Validation should check skill count, frontmatter, wrapper size, archived references, support assets, and absence of active instructions to use Claude-only runtime tools.
