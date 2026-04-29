---
name: update-zskills
description: >-
  Maintain this Codex port of Z Skills by checking upstream changes,
  refreshing references/support assets, and preserving Codex-native wrappers.
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


# Update Z Skills

## Purpose

This is a Codex maintenance workflow for the installed port. It is not the upstream Claude Code installer.

## Workflow

1. Fetch or clone `github.com/zeveck/zskills` to a temporary location and record the commit.
2. Compare upstream skill folders, block-diagram add-ons, `playwright-cli`, scripts, hooks, config schema, and docs against the installed Codex copy.
3. Preserve Codex-native `SKILL.md` wrappers unless upstream changed the workflow intent.
4. Refresh `references/upstream-claude-adapted.md` for changed skills and refresh `/home/vscode/.codex/zskills-support` assets.
5. Keep Claude-only mechanics out of active Codex instructions: no `.claude/settings.json`, no Claude hooks as runtime config, no Claude cron tools, no `allowed-tools` frontmatter.
6. Re-run validation: frontmatter, skill count, reference existence, no temp paths, no Claude-only executable instructions in active wrappers, and line counts.
7. Run or refresh the external runner canaries from `/home/vscode/.codex/zskills-support/tests/runner/run.sh`: `all`, plus any slow/optional cases called out by the current runner plan. At minimum this must cover multi-chunk `finish auto`, direct unattended refusal, cherry-pick completion evidence, PR dry-run immutability, tracking/report gates, post-run invariants, no-progress blocking, stale worktree refusal, dirty artifact blocking, missing report/verifier markers, nonzero child exit, and timeout/idle-timeout stops.
8. Run or refresh the broader Codex canary parity checklist: direct refusal/protection, cherry-pick landing, PR mode dry run, chunked `finish`, tracking marker enforcement, report landing, final verification, CI fix cycle where feasible, and at least one failure-injection stop.
9. Report changed skills, upstream commit, compatibility risks, runner canary result, broader canary result, and whether Codex should be restarted.

## Project Setup Checks

When adapting a project to use Z Skills, ensure `.zskills/tracking/` is ignored by git. Tracking markers are runtime gates, not source artifacts. Reports under `reports/` are project artifacts unless the repository uses a different report convention.
Treat support scripts as Codex-native only after inspection confirms they do not require Claude hooks or `.claude` runtime state. Archive Claude-only behavior in references instead of exposing it as active Codex behavior.
The installed external runner is Codex-native support code, not upstream Claude runtime. When upstream refreshes support assets, preserve `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh` and its tests unless deliberately updating them with equivalent or stronger canary coverage.

## Do Not

Do not copy upstream `update-zskills` instructions directly into active Codex behavior. Do not create `.claude` project config for Codex unless the user explicitly wants legacy compatibility files.

## Preserved Z Skills Invariants

- Preserve upstream provenance and commit ID.
- Keep archived upstream references diffable.
- Refresh support assets without making Claude hooks active Codex runtime.
- Tell the user to restart Codex when skill metadata changes.
