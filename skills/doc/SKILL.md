---
name: doc
description: >-
  Audit and update documentation for recent changes, examples, block
  libraries, guides, READMEs, presentations, or newsletter entries.
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


# Doc

## Workflow

1. Identify the documentation target: recent changes, `blocks`, `examples`, `newsletter`, or a free-form subject.
2. Inspect the repo's actual documentation structure. Do not assume the upstream block-diagram project layout exists.
3. Compare behavior/code changes with docs. Look for stale names, missing examples, setup instructions, screenshots, and references.
4. Make scoped documentation edits in the repo's existing style.
5. Verify links, generated docs commands, markdown formatting, and any examples you changed.
6. Summarize what changed and any docs gaps intentionally left open.

## Domain Add-on

If the repository is the block-diagram project or has similar concepts, the archived upstream reference contains detailed block/example checklists.

## Preserved Z Skills Invariants

- Mechanically discover existing documentation surfaces before editing large files.
- Newsletter-style entries should lead with user-facing value and follow the repo's ordering convention.
- Verify generated docs, links, or examples after editing.
