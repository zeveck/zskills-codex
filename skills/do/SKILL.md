---
name: do
description: >-
  Execute a bounded ad-hoc engineering task such as a small fix, refactor,
  docs update, or example without the full run-plan process.
---

## Codex Runtime Rules

These Z Skills are native Codex workflows derived from `github.com/zeveck/zskills` at commit `14dea81da487b2904ea7d69a27295f1869206cdf`. They are invoked by natural language or by naming the skill; examples that look like slash commands are only shorthand for the skill name.

Use Codex behavior first:
- Read the current repository before acting. Prefer existing project scripts, config, and conventions over the upstream examples.
- Never use Claude-only tools or assumptions: no `CronCreate`, `CronList`, `CronDelete`, `Agent`/`Task` tool syntax, `allowed-tools`, `.claude/settings.json`, or automatic Claude hooks.
- Use sub-agents only when the user explicitly asks for agents, parallel work, or delegation. For Z Skills landing gates, prefer a fresh independent verification context when it is available without violating the current Codex delegation policy; otherwise run inline, disclose lower assurance, and do not auto-land unless the user accepts it.
- For isolation, create git worktrees explicitly with normal `git worktree` commands. Do not rely on an `isolation: "worktree"` parameter.
- Config lookup order is project `.codex/zskills-config.json` first, then project `zskills-config.json`, then legacy `.claude/zskills-config.json` only if already present. Do not create new `.claude` runtime config for Codex.
- Scheduling is not automatic in Codex. If the user asks for recurring runs, explain the schedule and ask before installing any local cron/system scheduler. For normal turns, perform the requested work now.
- Helper assets from upstream live at `/home/vscode/.codex/zskills-support`. Use project-local `scripts/*` first; inspect or copy/adapt support scripts only when needed.
- Preserve Codex safety rules: do not revert unrelated work, stage files by name, avoid destructive git commands, and verify from actual diffs/tests.

Detailed upstream text is archived in `references/upstream-claude-adapted.md` for edge cases and future diffs. Load it only when the concise workflow below is insufficient.


# Do

## Workflow

1. Parse the user request as the task description plus optional mode words: `worktree`, `push`, `pr`, or `now`. Ignore `every` as scheduling unless the user explicitly asks to configure a local scheduler.
2. Decide whether the task is small enough for `do`. If it needs multiple dependent phases, switch to `draft-plan` or `run-plan` and say why.
3. Choose execution mode:
   - Default: work in the current repository.
   - `worktree` or `pr`: create a git worktree manually under `/tmp/<project>-do-<slug>` on a named branch.
   - `push`: verify before pushing.
4. Implement using normal Codex coding discipline: inspect files, make scoped edits, and avoid unrelated changes.
5. Verify with the smallest meaningful test set, plus lint/typecheck/manual checks when relevant.
6. Commit or push only if requested.

## Landing Modes

Use the shared Z Skills config lookup order: `.codex/zskills-config.json`, `zskills-config.json`, then legacy `.claude/zskills-config.json`.

- `direct`: work in the current tree. Refuse direct main commits when `execution.main_protected` is true unless the user explicitly overrides after warning.
- `cherry-pick`: for worktree mode, create a manual worktree, commit there, verify, then cherry-pick the scoped commit back to main.
- `pr` / `locked-main-pr`: create a manual worktree branch using `execution.branch_prefix`, push it, and create a PR with `gh` if available. Do not push to main.

## Scheduling

Codex has no built-in Z Skills cron tools. For `every`, `next`, or `stop`, explain that no Codex schedule exists by default. Configure system cron only after a clear user request.

## Agents

Use sub-agents only when the user explicitly asked for agent delegation or when a fresh verifier is allowed by the current Codex delegation policy for a Z Skills landing gate or explicit verification. Otherwise execute inline and disclose the review mode.

## Preserved Z Skills Invariants

- Keep this lighter than `run-plan`; escalate multi-phase work.
- Parse trailing mode words conservatively.
- `push` requires verification first.
- PR mode uses an isolated branch/worktree unless the user asks otherwise.
