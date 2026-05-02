---
name: research-and-plan
description: >-
  Research a broad goal, decompose it into executable sub-plans, and write a
  meta-plan without immediately implementing it.
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


# Research And Plan

## Workflow

1. Parse optional output path. Default is `plans/<slug>_META.md`.
2. Research current architecture, domain boundaries, tests, and known constraints.
3. Decompose into sub-problems sized for independent execution. Identify dependencies and parallelizable work.
4. Present the decomposition unless the user requested fully automatic drafting.
5. Draft each sub-plan with concrete phases, acceptance criteria, and verification commands.
6. Write a meta-plan that delegates each phase to the relevant sub-plan or skill.
7. Report the generated files and recommended execution order.

Use sub-agents for decomposition/review only when explicitly authorized by the user.

## Preserved Z Skills Invariants

- Draft sub-plans as top-level skill workflows, not hidden nested agent tasks.
- Cap concurrent work to what can be reviewed coherently.
- Fix cross-plan inconsistencies in the sub-plan files, not only the meta-plan.
