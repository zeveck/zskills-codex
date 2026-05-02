---
name: add-block
description: >-
  Add a new block type to a block-diagram style app with runtime behavior,
  UI/editor integration, serialization, tests, docs, examples, and
  verification.
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


# Add Block

## Workflow

1. Confirm the target project actually has a block registry/model system. If not, adapt the concept to the local architecture or stop.
2. Identify the block category, ports, parameters, runtime semantics, serialization, codegen needs, and UI/editor representation.
3. Implement in the established local patterns: registry, runtime/evaluator, rendering, inspector/editor UI, serialization, tests, and docs as applicable.
4. For multiple blocks, build shared infrastructure first, then add blocks in small batches.
5. Add focused unit tests plus integration/codegen tests if the project supports them.
6. Create or update examples using `add-example` semantics when useful.
7. Manually verify the editor workflow if UI changed.
8. Report files changed, tests, screenshots/manual checks, and any unsupported semantics.

For block-diagram repositories, load `references/upstream-claude-adapted.md` and complete the original 12-step checklist before landing. At minimum, cover registry/type definitions, runtime semantics, editor/rendering UI, inspector parameters, serialization/migration, codegen/export if present, examples, unit tests, integration tests, manual editor verification, documentation, and final self-audit.

## Preserved Z Skills Invariants

- Require a concrete plan before broad block-system changes.
- Complete runtime, UI, serialization, tests, docs, and examples as applicable.
- Do not land with unresolved sign-off items.
