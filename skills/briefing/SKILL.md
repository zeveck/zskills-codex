---
name: briefing
description: >-
  Generate a project status briefing from git state, plan reports, open
  checkboxes, recent commits, and worktrees when the user asks for status,
  current work, reports, or cleanup readiness.
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


# Briefing

## Workflow

1. Determine the requested mode: `summary` by default; also support `report`, `verify`, `current`, `worktrees`, `stop`, and `next` as plain words in the user request.
2. Confirm the current directory is a git repository. If it is not, report that briefing needs a repo and stop.
3. Prefer a project-local helper in this order: `node scripts/briefing.cjs`, then `python3 scripts/briefing.py`. If absent, use the bundled helpers at `/home/vscode/.codex/zskills-support/scripts/briefing.cjs` or `.py`.
4. For read-only modes, run the helper and present its output with minimal summarization. If the output is short and structured, preserve it verbatim.
5. For `report`, write the report under `reports/` when the helper supports it; otherwise synthesize a markdown report from git status, recent commits, active worktrees, and open plan checkboxes.
6. For `verify`, check whether briefing artifacts are current and whether referenced worktrees/reports exist.

## Codex Differences

Do not use Claude cron tools for `stop` or `next`. If the user asks about scheduled briefings, report that Codex has no built-in Z Skills scheduler unless they explicitly want a local scheduler configured.

## Preserved Z Skills Invariants

- For helper-driven `summary`, `current`, and `worktrees`, preserve the helper's structured output instead of collapsing actionable lines.
- `verify` focuses on report checkboxes, sign-off state, and referenced artifacts.
- Node is preferred, Python is the fallback.
