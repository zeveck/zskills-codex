---
name: investigate
description: >-
  Debug one complex bug with a disciplined reproduce, trace, root-cause, fix,
  and verify workflow; use when guessing would be risky.
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


# Investigate

## Workflow

1. State the bug and expected behavior in testable terms.
2. Reproduce it. If reproduction fails, document what was tried and gather more evidence before editing.
3. Trace the root cause through actual code, logs, tests, or runtime behavior.
4. Before writing the fix, explain the root cause and why the proposed change addresses it.
5. Implement the smallest correct fix.
6. Add or update regression coverage where practical.
7. Re-run the reproduction and relevant tests. Report evidence, not impressions.

Do not batch unrelated bugs into this skill. For many independent bugs, use `fix-issues`.

## Preserved Z Skills Invariants

- No fix before a root-cause statement backed by observed evidence.
- Add or identify a regression test before or alongside the fix when practical.
- One bug at a time.
