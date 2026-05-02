---
name: research-and-go
description: >-
  Research, decompose, plan, and execute a broad goal end-to-end when the user
  explicitly wants autonomous planning plus implementation.
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


# Research And Go

## Workflow

1. Confirm the user wants execution, not just a plan. This skill is for end-to-end work.
2. Decompose the broad goal into focused sub-problems with dependencies and verification gates.
3. Draft sub-plans using `draft-plan` semantics.
4. Execute in dependency order using `run-plan` semantics. Stop on failed verification, unsafe git state, unclear scope, or user approval requirements.
5. Use agents only when the user explicitly requested agentic/parallel execution. Otherwise execute sequentially inline.
6. Keep persistent reports under `reports/` and update plan progress as work lands.
7. At kickoff, record final branch-scope verification as a required completion gate in the meta-plan/report and `.zskills/tracking/research-and-go.<scope>/`.
8. Maintain `.zskills/tracking/research-and-go.<scope>/` markers for decomposition, sub-plan drafting, execution, and final verification.

Prefer `research-and-plan` when the user wants control before implementation.

## Preserved Z Skills Invariants

- This is high-agency execution; use only when the user clearly wants implementation.
- Carry landing-mode hints through sub-plans.
- End with cross-plan verification and a cleanup/status report.
- Do not mark the pipeline complete until final cross-branch verification has a tracking marker and report entry.
- Final branch-scope `verify-changes` is mandatory before marking the meta-plan complete or cleaning up.
