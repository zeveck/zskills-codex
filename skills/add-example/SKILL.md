---
name: add-example
description: >-
  Create a complete example model for one or more block types, including model
  layout, registration, tests, screenshots, docs, and verification.
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


# Add Example

## Workflow

1. Identify the block types and the real-world concept the example should demonstrate.
2. Inspect existing example format, registry, naming, screenshots, and tests.
3. Build the model using valid local schema and layout conventions. Use `model-design` for diagram readability.
4. Register the example wherever the app discovers examples.
5. Add tests for loading, validation, simulation/codegen, or snapshot behavior as applicable.
6. Add docs and screenshots when the project expects them.
7. Verify the example in the app or with project loaders.
8. Report how to open/run the example.

## Preserved Z Skills Invariants

- Use exact registry/schema parameter keys.
- Prefer a realistic model concept over a toy wiring demo.
- Tests should assert meaningful outputs, not just file existence.
