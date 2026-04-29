---
name: model-design
description: >-
  Apply readable block-diagram and state-chart layout rules such as left-to-
  right flow, grid alignment, spacing, orthogonal routing, and connected
  ports.
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


# Model Design

## Core Rules

- Prefer left-to-right signal flow.
- Stack parallel paths top-to-bottom.
- Route feedback below the forward path when possible.
- Align equivalent blocks into visual columns.
- Keep enough spacing for labels, ports, and signal lines.
- Use consistent grid positions and stable block sizes.
- Label important signals and expose important parameters.
- Avoid crossings, hidden dependencies, and cramped diagrams.
- Use a 10px grid when the project has no stronger convention.
- Leave at least 80px horizontal clearance between neighboring blocks and at least 40px vertical clearance between parallel rows unless local renderer constraints require different values.
- Leave at least 20px clearance around routed wires and labels; move labels before accepting overlaps.
- Align ports exactly on shared y-coordinates for straight horizontal connections and on shared x-coordinates for vertical buses.

## Workflow

1. Inspect the target model schema and renderer constraints.
2. Lay out blocks according to the local coordinate system and defaults.
3. Validate model syntax with project tools.
4. Open or render the model when possible to check readability.
5. For state charts, keep states hierarchically organized with clear transitions and guard labels.

Detailed source citations and domain-specific spacing guidance remain in `references/upstream-claude-adapted.md`.

## Preserved Z Skills Invariants

- Use a 10px grid where the project has no stronger convention.
- Keep signal flow left-to-right and feedback visually distinct.
- Avoid overlaps, unconnected ports, and ambiguous labels.
