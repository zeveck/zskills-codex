---
name: verify-changes
description: >-
  Verify recent changes from actual diffs with coverage review, tests, manual
  UI checks when needed, fixes when requested, and residual-risk reporting.
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


# Verify Changes

## Workflow

1. Determine scope: working tree, branch diff, last N commits, or user-specified files.
2. Read actual diffs, relevant code, and config from `.codex/zskills-config.json`, `zskills-config.json`, or legacy `.claude/zskills-config.json`. Prefer `testing.unit_cmd`, `testing.full_cmd`, `testing.output_file`, `ui.file_patterns`, `dev_server.*`, and `ci.*` over guessed commands.
3. Check whether tests cover the changed behavior. Identify missing or weak tests.
4. Run targeted tests first, then broader tests when risk warrants it.
5. For UI changes, use `manual-testing` or `playwright-cli` to exercise real workflows when possible.
6. If invoked as a Z Skills landing gate and fixes are authorized by the parent workflow, fix discovered issues and re-verify; otherwise block landing with findings. For ad-hoc verification, fix only when the user asked for fixes.
7. Produce a verification report: scope, files reviewed, tests run, results, issues found/fixed, and residual risk. Landing-gate reports are persistent artifacts under `reports/verify-<scope>.md` unless the repo has a documented alternative.

## Scope Assessment

For plan, branch, or worktree verification, include a scope assessment before declaring clean verification: compare every changed file, deletion, rewrite, and generated artifact against the plan goal, issue body, acceptance criteria, or user request. Any unexplained out-of-scope row means verification is not clean and landing must stop.

## Freshness

When this skill is invoked by `run-plan`, `fix-issues`, or another Z Skills landing gate, use a fresh verifier sub-agent whenever Codex sub-agents are available. If unavailable, run inline verification, disclose the lower assurance, and recommend human approval before landing.

## Tracking Markers

When invoked as a landing gate, preserve exact marker names in `.zskills/tracking/<pipeline-id>/`:

- Read `requires.verify-changes.<tracking-id>` from the caller before starting.
- Write `step.verify-changes.<tracking-id>.tests-run` after automated checks.
- Write `step.verify-changes.<tracking-id>.manual-verified` when UI/manual checks are required and completed.
- Write `step.verify-changes.<tracking-id>.complete` and `fulfilled.verify-changes.<tracking-id>` only after scope assessment, tests, and report are complete.
- For final plan or sprint gates, use `fulfilled.verify-changes.final.<meta-id>` as the final marker.

## Preserved Z Skills Invariants

- Never verify from memory.
- Disclose freshness mode: independent sub-agent, inline review, or mixed.
- UI changes need real browser/manual verification when feasible.
- Fixes discovered during verification require re-verification.
- Z Skills landing gates require verification evidence that can be recorded in reports or `.zskills/tracking` markers.
- Verification reports must include scope assessment results when used as a landing gate.
