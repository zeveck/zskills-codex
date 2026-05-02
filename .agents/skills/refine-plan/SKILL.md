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
- Use sub-agents only when the user explicitly asks for agents, parallel work, or delegation, or when the user explicitly invokes a Z Skill step whose workflow requires an independent reviewer, devil's-advocate critique, or fresh verification context. Keep those skill-required agents bounded to that workflow step. If agents are unavailable or the work is too tightly coupled, run inline, disclose lower assurance before or in the result, and do not auto-land unless the user accepts it.
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
4. Run the requested adversarial review rounds. A user invocation such as `refine-plan rounds N` with `N > 0` authorizes bounded reviewer sub-agents for those rounds because independent review is part of this skill's workflow. If sub-agents are unavailable or the review is too tightly coupled, state the inline lower-assurance mode before proceeding or in the result.
5. Incorporate reviewer findings or explicitly reject them with rationale.
6. Rewrite only incomplete phases, preserving original intent while making them executable now.
7. Add a drift log summarizing what changed and why.
8. Save the plan and report next executable phase.

## Preserved Z Skills Invariants

- Completed phases are immutable historical record.
- Append factual notes only in Drift Log or Plan Review, outside completed phase sections.
- Compare before/after checksums for completed sections before saving.
- Remaining phases must be checked against current code, not original assumptions.
- Add a Drift Log and Plan Review notes when the plan changes materially.
