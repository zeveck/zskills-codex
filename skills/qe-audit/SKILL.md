---
name: qe-audit
description: >-
  Audit recent commits or stress-test a feature area for quality gaps, missing
  tests, regressions, and actionable bugs.
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


# QE Audit

## Modes

- Default audit: inspect recent commits/diffs for missing tests, risky changes, and likely regressions.
- `bash` or stress mode: actively try edge cases in a specified area.

## Workflow

1. Define the audit scope: recent commits, branch diff, changed files, or named feature area.
2. Inspect actual diffs and tests. Do not rely on summaries.
3. Identify gaps as actionable findings with reproduction steps and expected/actual behavior.
4. Run targeted tests or manual checks where feasible.
5. File GitHub issues only if the user asked or the repo workflow clearly expects it; otherwise write findings to a report or response.
6. If asked to fix findings, switch to `fix-issues` or `investigate` depending on size.

Scheduling words are informational in Codex unless the user explicitly requests local scheduler setup.

## Preserved Z Skills Invariants

- Commit audit starts from real diffs.
- Stress mode should try edge cases, not only happy paths.
- Findings should be actionable enough to become issues or fix tasks.
