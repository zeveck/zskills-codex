---
name: fix-report
description: >-
  Interactively review and finalize fix-issues sprint results, including
  manual sign-offs, landing decisions, issue closure, tracker updates, and
  cleanup.
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


# Fix Report

## Workflow

1. Find sprint reports, issue trackers, worktrees, and unlanded branches relevant to recent `fix-issues` work.
2. Present a concise status table: fixed, needs manual verification, failed, skipped, unlanded, tracker update needed.
3. For each pending verification item, explain the evidence required and run checks when possible.
4. Land or push changes only after the user approves that action.
5. Update trackers and close issues only with explicit approval.
6. Clean up worktrees only after confirming their commits are landed or intentionally discarded.

This workflow is intentionally interactive. Stop at decision points and wait for the user.

## Preserved Z Skills Invariants

- This skill is always interactive.
- Do not close issues, land fixes, or delete worktrees without approval.
- Treat failed or partial sprints as first-class report items.
