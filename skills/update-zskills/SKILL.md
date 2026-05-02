---
name: update-zskills
description: >-
  Update an installed Codex Z Skills project from github.com/zeveck/zskills-codex,
  then perform maintainer upstream-sync checks when working in the port repo.
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


# Update Z Skills

## Purpose

This is the update workflow for installed Codex Z Skills. For normal users, its first job is to make the current project's repo-local `.agents/` install current with `github.com/zeveck/zskills-codex`. For maintainers working inside the `zskills-codex` source repo, it can also compare against upstream `github.com/zeveck/zskills`.

## Workflow

1. Determine the target project root with `git rev-parse --show-toplevel`; default to the current repository. Inspect `git status --short` before changing files.
2. If the target has uncommitted changes outside `.agents/`, stop and ask unless the user explicitly requested an update despite local work. Do not overwrite unrelated work.
3. Obtain the latest `zskills-codex` source:
   - If the current repo is `zskills-codex` source and has `scripts/install.sh`, run `git fetch` and fast-forward/pull only when the working tree is clean and the user requested updating the source checkout.
   - Otherwise clone or fetch `https://github.com/zeveck/zskills-codex` into a temporary directory or use a user-provided local checkout.
   - Record the `zskills-codex` commit used.
4. Run the source installer against the target project: `bash scripts/install.sh --project <target-root>`. This refreshes `.agents/skills/` and `.agents/zskills-support/` and preserves an existing `.agents/zskills-config.json`.
5. Verify the installed tree: 22 `SKILL.md` files under `.agents/skills`, required support scripts present, `.agents/zskills-config.json` valid JSON, and no rewritten development absolute paths in active wrappers or support scripts.
6. Run focused validation from the installed support tree when present: `.agents/zskills-support/tests/runner/run.sh fake-success` and `.agents/zskills-support/tests/runner/run.sh all` when runtime cost is acceptable. If tests are skipped, say why.
7. Report changed installed files, source commit, verification results, whether the target project should commit the `.agents/` update, and that Codex should be restarted or a new session opened to reload skill metadata.

## Maintainer Upstream Sync

When explicitly maintaining this `zskills-codex` port rather than updating an installed project:

1. Fetch or clone `github.com/zeveck/zskills` to a temporary location and record the commit.
2. Compare upstream skill folders, block-diagram add-ons, `playwright-cli`, scripts, hooks, config schema, and docs against the Codex source copy.
3. Preserve Codex-native `SKILL.md` wrappers unless upstream changed the workflow intent.
4. Refresh `references/upstream-claude-adapted.md` for changed skills and refresh source `zskills-support` assets, then run `bash scripts/install.sh --project <repo-root>` to refresh the checked-in `.agents/` tree.
5. Keep Claude-only mechanics out of active Codex instructions: no `.claude/settings.json`, no Claude hooks as runtime config, no Claude cron tools, no `allowed-tools` frontmatter.
6. Re-run validation: frontmatter, skill count, reference existence, no temp paths, no Claude-only executable instructions in active wrappers, and line counts.
7. Run or refresh the external runner canaries from `zskills-support/tests/runner/run.sh` and the installed `.agents/zskills-support/tests/runner/run.sh`: `all`, plus any slow/optional cases called out by the current runner plan. At minimum this must cover multi-chunk `finish auto`, direct unattended refusal, cherry-pick completion evidence, PR dry-run immutability, tracking/report gates, post-run invariants, no-progress blocking, stale worktree refusal, dirty artifact blocking, missing report/verifier markers, nonzero child exit, and timeout/idle-timeout stops.
8. Run or refresh the broader Codex canary parity checklist: direct refusal/protection, cherry-pick landing, PR mode dry run, chunked `finish`, tracking marker enforcement, report landing, final verification, CI fix cycle where feasible, and at least one failure-injection stop.
9. Report changed skills, upstream commit, compatibility risks, runner canary result, broader canary result, and whether Codex should be restarted.

## Project Setup Checks

When adapting a project to use Z Skills, ensure `.zskills/tracking/` is ignored by git. Tracking markers are runtime gates, not source artifacts. Reports under `reports/` are project artifacts unless the repository uses a different report convention.
Treat support scripts as Codex-native only after inspection confirms they do not require Claude hooks or `.claude` runtime state. Archive Claude-only behavior in references instead of exposing it as active Codex behavior.
The installed external runner is Codex-native support code, not upstream Claude runtime. When upstream refreshes support assets, preserve `.agents/zskills-support/scripts/zskills-runner.sh` or `$CODEX_HOME/zskills-support/scripts/zskills-runner.sh` and its tests unless deliberately updating them with equivalent or stronger canary coverage.

## Do Not

Do not copy upstream `update-zskills` instructions directly into active Codex behavior. Do not create `.claude` project config for Codex unless the user explicitly wants legacy compatibility files.

## Preserved Z Skills Invariants

- Preserve upstream provenance and commit ID.
- Keep archived upstream references diffable.
- Refresh support assets without making Claude hooks active Codex runtime.
- Tell the user to restart Codex when skill metadata changes.
