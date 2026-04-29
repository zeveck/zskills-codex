---
name: commit
description: >-
  Safely commit only the relevant current changes, protecting unrelated user
  or agent work; also handle requested push, land, or PR follow-through.
---

## Codex Runtime Rules

These Z Skills are native Codex workflows derived from `github.com/zeveck/zskills` at commit `14dea81da487b2904ea7d69a27295f1869206cdf`. They are invoked by natural language or by naming the skill; examples that look like slash commands are only shorthand for the skill name.

Use Codex behavior first:
- Read the current repository before acting. Prefer existing project scripts, config, and conventions over the upstream examples.
- Never use Claude-only tools or assumptions: no `CronCreate`, `CronList`, `CronDelete`, `Agent`/`Task` tool syntax, `allowed-tools`, `.claude/settings.json`, or automatic Claude hooks.
- Use sub-agents for implementation only when the user explicitly asks for agents, parallel work, or delegation. Z Skills landing-gate verifiers and adversarial reviewers are workflow-required fresh-check exceptions when Codex sub-agents are available; otherwise run inline, disclose lower assurance, and do not auto-land unless the user accepts it.
- For isolation, create git worktrees explicitly with normal `git worktree` commands. Do not rely on an `isolation: "worktree"` parameter.
- Config lookup order is project `.codex/zskills-config.json` first, then project `zskills-config.json`, then legacy `.claude/zskills-config.json` only if already present. Do not create new `.claude` runtime config for Codex.
- Scheduling is not automatic in Codex. If the user asks for recurring runs, explain the schedule and ask before installing any local cron/system scheduler. For normal turns, perform the requested work now.
- Helper assets from upstream live at `/home/vscode/.codex/zskills-support`. Use project-local `scripts/*` first; inspect or copy/adapt support scripts only when needed.
- Preserve Codex safety rules: do not revert unrelated work, stage files by name, avoid destructive git commands, and verify from actual diffs/tests.

Detailed upstream text is archived in `references/upstream-claude-adapted.md` for edge cases and future diffs. Load it only when the concise workflow below is insufficient.


# Commit

## Workflow

1. Inventory first: run `git status -s`, inspect unstaged and staged diffs, check the current branch, and identify whether this is a worktree.
2. Classify every changed file as related or unrelated to the requested scope. Leave unrelated files untouched.
3. If a file contains mixed related/unrelated hunks, or a related hunk depends on an unstaged config/test/source change, stop and split the change or ask. Do not create a commit that passes path filtering but breaks the dependency chain.
4. If the scope is ambiguous, infer conservatively from diffs and recent conversation. Ask only when committing would risk including unrelated work.
5. Run relevant tests or at least explain why no tests apply.
6. Stage files by explicit path. Do not use `git add .`.
7. Compare the staged file list/count to the paths just staged and stop on extras.
8. Review the staged diff before committing. When Codex sub-agents are available, use a fresh read-only staged-diff reviewer as a workflow-required exception; if unavailable, disclose inline self-review and the lower assurance.
9. Commit with a concise message matching the repository style.
10. Only push, land, or open a PR if the user requested it or the current workflow explicitly requires it.

## Modes

- `push`: push the current branch after a successful commit.
- `land`: from an isolated worktree, cherry-pick the scoped commit back to `${execution.base_branch:-main}` only after verification unless the config/user explicitly selected another landing mode.
- `pr`: require a clean working tree after the commit, push the branch to `${execution.remote:-origin}`, and create a PR using `gh` if available; otherwise report the branch and exact next command.

## Landing Modes

Use the shared Z Skills config lookup order: `.codex/zskills-config.json`, `zskills-config.json`, then legacy `.claude/zskills-config.json`.

- `direct`: commit on the current branch. If the branch is `${execution.base_branch:-main}` and `execution.main_protected` is true, stop and require explicit user override.
- `cherry-pick`: commit in the current worktree/branch, verify, then cherry-pick the scoped commit to `${execution.base_branch:-main}` when landing is requested.
- `pr` / `locked-main-pr`: push the feature branch to `${execution.remote:-origin}` and create a PR. Do not push directly to the base branch.

## Guardrails

Never amend, rebase, reset, or force-push unless the user explicitly asks. If the worktree is dirty with unrelated changes, commit only the related paths.
Do not use stash as part of commit safety.
Before `land`, `push`, or `pr`, use project-local gate helpers when available; otherwise run `/home/vscode/.codex/zskills-support/scripts/zskills-gate.sh` in the relevant mode when the repo uses Z Skills tracking.

## Preserved Z Skills Invariants

- Classify from actual diffs, not memory.
- Treat pre-staged unrelated files as a stop-and-ask condition.
- PR mode is explicit: treat `commit pr` as PR mode only when `pr` is the first token.
- Verify the staged index exactly matches intended paths before committing.
