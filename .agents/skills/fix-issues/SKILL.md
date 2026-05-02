---
name: fix-issues
description: >-
  Triage and fix a batch of issues from GitHub or tracker files, with
  reproduction, prioritization, verification, reporting, and tracker updates.
---

## Codex Runtime Rules

These Z Skills are native Codex workflows derived from `github.com/zeveck/zskills` at commit `14dea81da487b2904ea7d69a27295f1869206cdf`. They are invoked by natural language or by naming the skill; examples that look like slash commands are only shorthand for the skill name.

Use Codex behavior first:
- Read the current repository before acting. Prefer existing project scripts, config, and conventions over the upstream examples.
- Never use Claude-only tools or assumptions: no `CronCreate`, `CronList`, `CronDelete`, `Agent`/`Task` tool syntax, `allowed-tools`, `.claude/settings.json`, or automatic Claude hooks.
- Use sub-agents only when the user explicitly asks for agents, parallel work, or delegation, or when the user explicitly invokes a Z Skill step whose workflow requires an independent reviewer, devil's-advocate critique, or fresh verification context. Keep those skill-required agents bounded to that workflow step. If agents are unavailable or the work is too tightly coupled, run inline, disclose lower assurance before or in the result, and do not auto-land unless the user accepts it.
- For isolation, create git worktrees explicitly with normal `git worktree` commands. Do not rely on an `isolation: "worktree"` parameter.
- Config lookup order is project `.agents/zskills-config.json` first, then project `zskills-config.json`, then legacy `.codex/zskills-config.json`, then legacy `.claude/zskills-config.json` only if already present. Do not create new `.claude` runtime config for Codex.
- Scheduling is not automatic in Codex. If the user asks for recurring runs, explain the schedule and ask before installing any local cron/system scheduler. For normal turns, perform the requested work now.
- Helper assets live at project `.agents/zskills-support` by default. Use project-local `scripts/*` first; fall back to `$CODEX_HOME/zskills-support` only for explicit global installs or legacy setups.
- Preserve Codex safety rules: do not revert unrelated work, stage files by name, avoid destructive git commands, and verify from actual diffs/tests.

Detailed upstream text is archived in `references/upstream-claude-adapted.md` for edge cases and future diffs. Load it only when the concise workflow below is insufficient.


# Fix Issues

## Workflow

1. Determine mode: sprint (`N` issues), `sync`, or `plan`.
2. Discover issue sources: GitHub issues via `gh`, repo trackers like `plans/*ISSUES*.md`, failing tests, or user-provided lists.
3. Prioritize by severity, reproducibility, dependency order, and requested focus.
4. For each selected issue, reproduce or prove the bug before editing. Skip issues that are too vague, too large, or blocked; document why.
5. Fix in sprint-safe batches. For sprint mode, use isolated worktrees for cherry-pick or PR landing unless `direct` was explicitly selected and allowed. Keep one issue or tightly grouped root cause per commit.
6. Verify each fix with targeted tests and, when allowed by the current Codex delegation policy, a fresh verifier for the issue or batch before landing. Otherwise run inline verification and disclose the lower assurance.
7. Append `SPRINT_REPORT.md` before landing. Sprint mode does not close GitHub issues, finalize tracker state, or remove worktrees; `fix-report` owns those decisions.

## Landing Modes

Resolve landing mode from explicit request first, then `.agents/zskills-config.json`, `zskills-config.json`, legacy `.codex/zskills-config.json`, legacy `.claude/zskills-config.json`, and finally `cherry-pick`.

- `direct`: fix issues in the current tree only with a clean tree, no unrelated changes, and main not protected unless the user explicitly accepts the risk in the current turn.
- `cherry-pick`: fix each issue or small batch in a manual worktree, verify, write `SPRINT_REPORT.md`, then cherry-pick scoped commits back to `${execution.base_branch:-main}`.
- `pr` / `locked-main-pr`: create one branch/PR per issue or grouped root cause using `fix/issue-NNN` naming when an issue number exists. Push to `${execution.remote:-origin}`. Do not reuse the general plan branch prefix for sprint issue branches. Never push directly to main.

## Automation Limits

`auto` means proceed through obvious internal gates in this turn; it does not authorize unsafe git operations, force pushes, or unattended local schedulers.

## Tracking And Gates

Retain sprint tracking as active files:

1. Create `.zskills/tracking/fix-issues.<sprint-id>/` at sprint start and write `pipeline.fix-issues.<sprint-id>`.
2. Write sprint markers `step.fix-issues.<sprint-id>.preflight`, `.prioritize`, `.execute`, `.verify`, `.report`, and `.land`.
3. Write per-issue markers `issue.<issue-id>.selected`, `.reproduced` or `.skipped`, `.fixed`, `.verified`, `.landed`, and `.reported`.
4. Before verification, write `requires.verify-changes.<sprint-id>` and require the verifier to produce `fulfilled.verify-changes.<sprint-id>`.
5. Write `SPRINT_REPORT.md` before landing or closing issues. Treat missing verification/report markers as a stop condition for auto-landing.

Run project-local `scripts/zskills-gate.sh`, `.agents/zskills-support/scripts/zskills-gate.sh`, or `$CODEX_HOME/zskills-support/scripts/zskills-gate.sh` before sprint landing when available.

## Preserved Z Skills Invariants

- `sync` is interactive before closing or mutating remote issues.
- Read each issue body and tracker research before fixing; titles alone are not a spec.
- Skipped issues need explicit reasons.
- Write a sprint report before any landing/closure decisions.
- Preserve requested landing mode: `pr`, `direct`, or cherry-pick-style local landing.
- Preserve file tracking gates for sprint state and landing readiness.
