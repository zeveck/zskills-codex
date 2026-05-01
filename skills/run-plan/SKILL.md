---
name: run-plan
description: >-
  Execute one phase or all remaining phases of a plan with scoped
  implementation, optional worktree isolation, verification, reporting, and
  landing.
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


# Run Plan

## Workflow

1. Parse the request: plan file, optional phase, `status`, `finish`, `auto`, `pr`, or `direct`.
2. Read the plan and current progress. For `status`, report phases, next work, blockers, and stop.
3. Determine landing mode from explicit request, then config lookup order: `.codex/zskills-config.json`, `zskills-config.json`, legacy `.claude/zskills-config.json`, fallback `cherry-pick`. Also read `execution.base_branch`, `execution.remote`, `testing.*`, `ci.*`, and `dev_server.*` before choosing commands.
4. Identify the next incomplete phase unless a phase was specified.
5. Validate scope: phase text, expected files, tests, and risks. If the phase is too broad, stop and recommend splitting or `refine-plan`.
6. Execution mode:
   - `direct`: work in the current tree only when not protected and explicitly requested.
   - default/cherry-pick: create a manual git worktree under `/tmp/<project>-cp-<plan>-phase-<phase>` on a named branch.
   - `pr`: create a branch/worktree suitable for a PR.
7. Implement the phase. If the user explicitly requested agents, delegate implementation to a worker with the worktree path; otherwise implement inline.
8. Verify from actual diffs with a fresh verification context before landing. When Codex sub-agents are available, dispatch a separate verifier for each phase. If sub-agents are unavailable, run inline verification, disclose the lower assurance, and do not auto-land unless the user explicitly accepts inline verification.
9. Update the plan progress tracker and write or update `reports/plan-<slug>.md`.
10. Land only after verification passes and the requested mode allows it. Stage explicit files, avoid unrelated changes, and preserve user work.
11. For `finish`, preserve chunking: execute at most one substantive phase per top-level Codex turn unless the user explicitly says to continue in the same turn after seeing the phase result.

## Chunked Finish

`finish` means "keep advancing this plan until done," not "merge all phases into one long context." After each phase:

1. Persist state in the plan progress tracker and `reports/plan-<slug>.md`.
2. Write a concise handoff: completed phase, branch/worktree, tests, landing state, next phase, blockers, and exact suggested next invocation.
3. Stop the turn unless the user explicitly requested same-turn continuation and the remaining context/risk is small.
4. For `finish auto`, prefer resumable top-level turns over long in-context loops. Unattended completion is runner-backed by `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`, which launches fresh `codex exec` invocations and validates durable state between chunks. Without that external runner, `finish auto` degrades to one chunk plus a handoff; Codex has no built-in Z Skills cron.
5. Never combine multiple plan phases into one implementation chunk just to reduce orchestration overhead.

## Codex-Native Replacements

- Do not use `CronCreate`, `CronList`, or `CronDelete`. For `every`, `next`, or `stop`, explain that Codex has no built-in scheduler and ask before creating an external schedule.
- Do not use Claude `Agent` prompts or `isolation` parameters. Use Codex sub-agents for implementation only when explicitly authorized; required verifier/reviewer agents follow the runtime exception above.
- Treat upstream hook checks as manual guardrails. Codex does not run Z Skills hooks automatically.

## External Runner Contract

An external runner may automate `finish auto` only by starting a new top-level `codex exec` process for each chunk. The runner must:

- acquire a per-plan lock before launching Codex;
- refuse unsafe git states such as merge, rebase, cherry-pick, conflicts, or unexpected dirty files;
- run with conservative child Codex flags and never default to dangerous bypass;
- derive progress from plan/report hashes and `.zskills/tracking/` markers, not from chat text alone;
- run `zskills-gate.sh` and post-run invariants before scheduling the next chunk;
- stop on no progress, missing reports/markers, direct-mode ambiguity, PR/CI waiting states, timeouts, or max chunk limits.

If no runner is active, report the exact next invocation instead of trying to continue multiple phases in one context.

## Landing Modes

Use one shared config contract across Z Skills. Read `.codex/zskills-config.json`, then `zskills-config.json`, then legacy `.claude/zskills-config.json`.

- `execution.landing: "direct"`: work on the current branch/main only with a clean tree, no unrelated changes, explicit current-turn authorization for broad/autonomous work, and `execution.main_protected` false or explicitly overridden after warning.
- `execution.landing: "cherry-pick"`: work in a manual git worktree, commit the phase there, verify, then cherry-pick the scoped commit back to `${execution.base_branch:-main}` from `${execution.remote:-origin}`. This is the default.
- `execution.landing: "pr"`: work in a manual git worktree on `${execution.branch_prefix}...`, push to `${execution.remote:-origin}`, create a PR with `gh` if available, and do not push directly to main.

Explicit request words `direct` or `pr` override config for the current invocation. `locked-main-pr` means `execution.landing: "pr"` plus `execution.main_protected: true`.

## Landing Helper Contract

Use project-local helpers first. If absent, inspect or adapt `/home/vscode/.codex/zskills-support/scripts/*` before relying on prose:

- `worktree-add-safe.sh`: create isolated worktrees and reject branch/path poisoning.
- `write-landed.sh` and `land-phase.sh`: record scoped landing state and cleanup only expected ephemeral files.
- `post-run-invariants.sh`: check base freshness, landing evidence, report state, and dirty tree after landing.
- `zskills-gate.sh`: Codex-native pre-land/pre-continue/pre-push gate for reports, tracking markers, ignored tracking files, and untracked artifacts.

Do not run support scripts blindly when a project has different branch names or report paths; pass config-derived base/remote values or adapt a project-local copy.

## Minimum Report

Every executed phase should report: plan, phase, branch/worktree, files changed, tests run, verification result, landing result, and remaining phases.
Verification reports used as landing evidence are project artifacts; keep them under `reports/` and land them with the phase report unless the repository has an explicit external-report convention.

## Tracking And Gates

Retain file-based tracking even though Codex does not run Claude hooks:

1. Create `.zskills/tracking/<pipeline-id>/` for the plan run.
2. Before verification, write `requires.verify-changes.<tracking-id>` with phase, diff base, and expected report path.
3. During the phase, write canonical markers: `step.run-plan.<tracking-id>.implement`, `step.run-plan.<tracking-id>.verify`, and `step.run-plan.<tracking-id>.report`.
4. For `finish`, if another phase remains, write `handoff.run-plan.<tracking-id>` after the phase so the next top-level turn can resume without relying on conversation memory. Do not leave `step.run-plan.<tracking-id>.land` or `fulfilled.run-plan.<tracking-id>` present for a non-final chunk.
5. Only when the plan is complete, write `step.run-plan.<tracking-id>.land` and finally `fulfilled.run-plan.<tracking-id>`, and remove any stale `handoff.run-plan.<tracking-id>`.
6. Before landing, check the `implement`, `verify`, and `report` markers plus the persistent verification report. Treat missing or inconsistent markers as a stop condition unless the user explicitly chooses manual recovery.

Tracking files are ephemeral gates. Do not include `.zskills/`, `.zskills-tracked`, or other tracking marker files in landed commits or PRs unless the user explicitly asks to version them.

## Post-Landing Gates

- Before landing, pushing, scheduling another chunk, or declaring completion, re-check whether main/base moved since verification. If it moved, re-run verification on the current diff.
- After landing, run project-local `scripts/post-run-invariants.sh` when available. If absent, inspect or adapt `/home/vscode/.codex/zskills-support/scripts/post-run-invariants.sh` when the project uses Z Skills tracking. Do not schedule the next chunk or declare completion if invariants fail.
- Before declaring a phase complete, inspect `git status --short`. Only expected ephemeral tracking files may remain uncommitted. Untracked reports, source files, tests, plans, or config files are a stop condition.

## Preserved Z Skills Invariants

- Extract and follow the phase text exactly, but challenge unsafe or impossible instructions.
- Write/update the phase report before landing.
- Require a separate verifier per phase when Codex sub-agents are available.
- Block auto-landing when verification fails, user sign-off is required, scope changed materially, or unrelated changes are present.
- Preserve delegate/direct/worktree/PR modes with Codex-native mechanics.
- Preserve chunking to reduce context fatigue and resource anxiety; do not collapse remaining phases into one mega-phase.
- Preserve tracking-file gates as manual Codex checks, even without hook enforcement.
- Keep tracking files out of landed commits and PRs by default.
- Re-run verification when the base moved and run post-run invariants before continuing.
- Do not leave verification reports or other project artifacts untracked after landing.
