---
name: playwright-cli
description: >-
  Use playwright-cli for browser automation, UI testing, form filling,
  screenshots, snapshots, tracing, storage state, request mocking, and test
  generation.
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


# Playwright CLI

## Quick Workflow

1. Start or identify the target web app URL.
2. Open a browser: `playwright-cli open <url>`.
3. Use `playwright-cli snapshot` to get element refs before interacting.
4. Interact with refs: `click`, `fill`, `type`, `press`, `select`, `drag`, `upload`, `hover`.
5. Capture evidence with `screenshot`, `tracing-start`/`tracing-stop`, or snapshots when useful.
6. Close or detach sessions when done.

## References

Load only the relevant reference for advanced tasks:
- Request mocking: `references/request-mocking.md`
- Running Playwright code: `references/running-code.md`
- Session management: `references/session-management.md`
- Storage state: `references/storage-state.md`
- Test generation: `references/test-generation.md`
- Tracing: `references/tracing.md`
- Video recording: `references/video-recording.md`

The `playwright-cli` binary is available in this environment; still check `playwright-cli --help` if syntax is uncertain.

## Preserved Z Skills Invariants

- Snapshot/ref workflow comes before interactions.
- Use storage/session references for auth and persistent state.
- If the global binary fails, try the project-local or `npx playwright-cli` equivalent.
