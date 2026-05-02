---
name: refine-plan
description: >-
  Refine the remaining phases of a partially executed plan against completed
  work, current code, drift, and updated verification needs.
---

## Codex Runtime Rules

These Z Skills are native Codex workflows derived from `github.com/zeveck/zskills` at commit `14dea81da487b2904ea7d69a27295f1869206cdf`. They are invoked by natural language or by naming the skill; examples that look like slash commands are only shorthand for the skill name.

Use Codex behavior first:
- Read the current repository before acting. Prefer existing project scripts, config, and conventions over the upstream examples.
- Never use Claude-only tools or assumptions: no `CronCreate`, `CronList`, `CronDelete`, `Agent`/`Task` tool syntax, `allowed-tools`, `.claude/settings.json`, or automatic Claude hooks.
- Use sub-agents only when the user explicitly asks for agents, parallel work, or delegation. For Z Skills landing gates, prefer a fresh independent verification context when it is available without violating the current Codex delegation policy; otherwise run inline, disclose lower assurance, and do not auto-land unless the user accepts it.
- For isolation, create git worktrees explicitly with normal `git worktree` commands. Do not rely on an `isolation: "worktree"` parameter.
- Config lookup order is project `.agents/zskills-config.json` first, then project `zskills-config.json`, then legacy `.codex/zskills-config.json`, then legacy `.claude/zskills-config.json` only if already present. Do not create new `.claude` runtime config for Codex.
- Scheduling is not automatic in Codex. If the user asks for recurring runs, explain the schedule and ask before installing any local cron/system scheduler. For normal turns, perform the requested work now.
- Helper assets live at project `.agents/zskills-support` by default. Use project-local `scripts/*` first; fall back to `$CODEX_HOME/zskills-support` only for explicit global installs or legacy setups.
- Preserve Codex safety rules: do not revert unrelated work, stage files by name, avoid destructive git commands, and verify from actual diffs/tests.

Detailed upstream text is archived in `references/upstream-claude-adapted.md` for edge cases and future diffs. Load it only when the concise workflow below is insufficient.


# Refine Plan

## Workflow

1. Read the target plan, progress tracker, reports, commits, and current code.
2. Treat completed phase sections as byte-identical immutable history. Do not edit them or add notes inside them.
3. Check remaining phases for stale assumptions, invalid file paths, missing dependencies, changed architecture, and weak verification.
4. When allowed by the current Codex delegation policy, run an independent adversarial review of the remaining phases and incorporate or explicitly reject its findings. Otherwise perform inline adversarial review and disclose the lower assurance.
5. Rewrite only incomplete phases, preserving original intent while making them executable now.
6. Add a drift log summarizing what changed and why.
7. Save the plan and report next executable phase.

## Preserved Z Skills Invariants

- Completed phases are immutable historical record.
- Append factual notes only in Drift Log or Plan Review, outside completed phase sections.
- Compare before/after checksums for completed sections before saving.
- Remaining phases must be checked against current code, not original assumptions.
- Add a Drift Log and Plan Review notes when the plan changes materially.
