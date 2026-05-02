---
name: plans
description: >-
  Build, inspect, or refresh a dashboard of plan files, classify plan status,
  identify next ready work, or execute a bounded number of plans.
---

## Codex Runtime Rules

These Z Skills are native Codex workflows derived from `github.com/zeveck/zskills` at commit `14dea81da487b2904ea7d69a27295f1869206cdf`. They are invoked by natural language or by naming the skill; examples that look like slash commands are only shorthand for the skill name.

Use Codex behavior first:
- Read the current repository before acting. Prefer existing project scripts, config, and conventions over the upstream examples.
- Never use Claude-only tools or assumptions: no `CronCreate`, `CronList`, `CronDelete`, `Agent`/`Task` tool syntax, `allowed-tools`, `.claude/settings.json`, or automatic Claude hooks.
- Use sub-agents only when the user explicitly asks for agents, parallel work, or delegation, or when the user explicitly invokes a Z Skill step whose workflow requires an independent reviewer, devil's-advocate critique, or fresh verification context. Keep those skill-required agents bounded to that workflow step. If agents are unavailable or the work is too tightly coupled, run inline, disclose lower assurance before or in the result, and do not auto-land unless the user accepts it.
- For isolation, create git worktrees explicitly with normal `git worktree` commands. Do not rely on an `isolation: "worktree"` parameter.
- Config lookup order is project `.agents/zskills-config.json` first, then project `zskills-config.json`, then legacy `.codex/zskills-config.json`, then legacy `.claude/zskills-config.json` only if already present. Do not create new `.claude` runtime config for Codex.
- Scheduling is not automatic in Codex. If the user asks for recurring runs, explain the schedule and ask before installing any local cron/system scheduler. For normal turns, perform the requested work now.
- Helper assets live at project `.agents/zskills-support` by default. Use project-local `scripts/*` first; fall back to `$CODEX_HOME/zskills-support` only for explicit global installs or legacy setups.
- Preserve Codex safety rules: do not revert unrelated work, stage files by name, avoid destructive git commands, and verify from actual diffs/tests.

Detailed upstream text is archived in `references/upstream-claude-adapted.md` for edge cases and future diffs. Load it only when the concise workflow below is insufficient.


# Plans

## Workflow

1. Discover plan files under `plans/` and any repo-specific planning directories.
2. Classify each plan: ready, in progress, blocked, complete, stale, meta-plan, tracker, or reference.
3. For `rebuild`, regenerate `plans/PLAN_INDEX.md` with concise status, next phase, priority, and blockers.
4. For `next`, recommend the highest-value ready plan and explain why.
5. For `details`, show a fuller status table.
6. For `work N`, execute only if the user clearly asked for execution; use `run-plan` semantics and stop on failures.

No automatic scheduling is available unless the user explicitly asks to configure an external scheduler.

## Preserved Z Skills Invariants

- Auto-rebuild the index if it is missing and the user asks for plan status.
- Classify issue trackers separately from executable plans.
- Distinguish meta-plans, reference plans, blocked plans, and ready plans.
