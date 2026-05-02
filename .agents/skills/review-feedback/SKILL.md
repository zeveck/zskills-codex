---
name: review-feedback
description: >-
  Triage exported product feedback JSON, check duplicates and actionability,
  present recommendations, and file approved GitHub issues.
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


# Review Feedback

## Workflow

1. Locate the feedback JSON file from the user request or repo root.
2. Parse it with a JSON tool or project helper; do not edit it with ad hoc text operations.
3. For each pending entry, classify type, severity, actionability, duplicates, and suggested labels.
4. Present a recommendation table before filing anything.
5. File GitHub issues only after user approval. Use `gh issue create` if available.
6. Update the JSON statuses structurally: filed, dismissed, duplicate, or needs-info.
7. Tell the user what changed and how to re-import if the project requires that.

## Preserved Z Skills Invariants

- Check for duplicate issues before recommending filing.
- Never file without user approval.
- Update JSON with structured statuses rather than free-text edits.
