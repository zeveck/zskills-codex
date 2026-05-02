---
name: draft-plan
description: >-
  Draft an executable plan file through codebase research, review, refinement,
  acceptance criteria, and verification planning before implementation.
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


# Draft Plan

## Workflow

1. Parse optional output path and rounds from the request. Default output is `plans/<slug>.md`.
2. If an output file already exists, read it first and preserve its intent unless the user asked for replacement.
3. Research the codebase and relevant docs. For broad or risky work, explicitly map current architecture, tests, and constraints.
4. Run adversarial planning rounds. A user invocation such as `draft-plan rounds N` with `N > 0` authorizes bounded reviewer/devil's-advocate sub-agents for those rounds because independent review is part of this skill's workflow. If sub-agents are unavailable or the work is too tightly coupled, run the same roles inline and label the plan as lower-assurance before proceeding or in the result.
5. Use multiple rounds by default: draft, review, critique, refine, then repeat until no substantive new issues appear or the configured round limit is reached.
6. Write a concrete phased plan with acceptance criteria, verification commands, files likely touched, rollback/risk notes, and progress checkboxes.
7. Review the plan for overbroad phases, missing tests, hidden dependencies, and stale assumptions. Refine until each phase can be executed independently.
8. Save the plan and report the path plus the recommended next command.

## Plan Format

Prefer repo-local conventions. If none exist, use sections: Goal, Context, Non-goals, Phases, Verification, Risks, Progress Tracker.

## Preserved Z Skills Invariants

- Existing plans are research input, not disposable drafts.
- Oversized goals should be decomposed with `research-and-plan`.
- The output must be executable by `run-plan` without hidden drafting during execution.
- Preserve multiple adversarial review rounds, using separate Codex sub-agents for requested rounds unless unavailable, too tightly coupled, or the user asks for inline-only review.
