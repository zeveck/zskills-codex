---
name: manual-testing
description: >-
  Manually verify browser or UI behavior with playwright-cli or equivalent
  real interactions, screenshots, snapshots, traces, and reproducible steps.
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


# Manual Testing

## Workflow

1. Identify the app URL and dev server command from the repo, preferring `dev_server.cmd`, `dev_server.port_script`, `dev_server.main_repo_path`, `ui.auth_bypass`, and `ui.file_patterns` from Z Skills config when present. Start the server if needed and keep track of the process.
2. Use `playwright-cli` when available for browser actions, snapshots, screenshots, and state inspection.
3. Test the actual user workflow with realistic clicks, typing, navigation, and assertions. Avoid relying only on DOM inspection.
4. Capture screenshots or traces when visual evidence matters.
5. Record browser, viewport, URL, steps performed, observed result, and pass/fail.
6. If a bug is found, provide a minimal repro and decide with the user whether to fix it now.

Load `playwright-cli` references only for advanced tasks such as tracing, request mocking, or storage state.

## Preserved Z Skills Invariants

- Use real user interactions for workflow validation.
- Use `eval` mainly for setup or read-only assertions, not as a substitute for the UI path.
- Snapshot before and after important interactions.
