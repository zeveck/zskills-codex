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
- Use sub-agents only when the user explicitly asks for agents, parallel work, or delegation, or when the user explicitly invokes a Z Skill step whose workflow requires an independent reviewer, devil's-advocate critique, or fresh verification context. Keep those skill-required agents bounded to that workflow step. If agents are unavailable or the work is too tightly coupled, run inline, disclose lower assurance before or in the result, and do not auto-land unless the user accepts it.
- For isolation, create git worktrees explicitly with normal `git worktree` commands. Do not rely on an `isolation: "worktree"` parameter.
- Config lookup order is project `.agents/zskills-config.json` first, then project `zskills-config.json`, then legacy `.codex/zskills-config.json`, then legacy `.claude/zskills-config.json` only if already present. Do not create new `.claude` runtime config for Codex.
- Scheduling is not automatic in Codex. If the user asks for recurring runs, explain the schedule and ask before installing any local cron/system scheduler. For normal turns, perform the requested work now.
- Helper assets live at project `.agents/zskills-support` by default. Use project-local `scripts/*` first; fall back to `$CODEX_HOME/zskills-support` only for explicit global installs or legacy setups.
- Preserve Codex safety rules: do not revert unrelated work, stage files by name, avoid destructive git commands, and verify from actual diffs/tests.

Detailed upstream text is archived in `references/upstream-claude-adapted.md` for edge cases and future diffs. Load it only when the concise workflow below is insufficient.


# Run Plan

## Workflow

1. Parse the request: plan file, optional phase, `status`, `finish`, `auto`, `pr`, or `direct`.
2. Read the plan and current progress. For `status`, report phases, next work, blockers, and stop.
3. If the request is `finish auto` and it is not a runner-managed child prompt, start the external runner immediately when `.agents/zskills-support/scripts/zskills-runner.sh` or `$CODEX_HOME/zskills-support/scripts/zskills-runner.sh` exists. Run it as a shell command with the requested plan and `--repo <repo-root>`, relay the runner result, and do not manually execute a phase in the parent turn. This is the normal unattended entrypoint.
4. Treat prompts containing `RUNNER-MANAGED CHUNK` or `External ZSkills runner contract for this chunk` as child chunks launched by `zskills-runner.sh`; in that case do not start the runner again. Execute exactly one incomplete phase and follow the supplied runner contract. In `finish auto`, use the shared finish-auto worktree/branch supplied by the runner for every chunk unless the contract explicitly says otherwise.
5. Determine landing mode from explicit request, then config lookup order: `.agents/zskills-config.json`, `zskills-config.json`, legacy `.codex/zskills-config.json`, legacy `.claude/zskills-config.json`, fallback `cherry-pick`. Also read `execution.base_branch`, `execution.remote`, `testing.*`, `ci.*`, and `dev_server.*` before choosing commands.
6. Identify the next incomplete phase unless a phase was specified.
7. Validate scope: phase text, expected files, tests, and risks. If the phase is too broad, stop and recommend splitting or `refine-plan`.
8. Execution mode:
   - `direct`: work in the current tree only when not protected and explicitly requested.
   - default/cherry-pick, single-phase run: create a manual git worktree under `/tmp/<project>-cp-<plan>-phase-<phase>` on a named branch.
   - default/cherry-pick, `finish auto`: create or reuse the runner-supplied shared plan-level worktree/branch across chunks; commit each chunk there and land once after all remaining phases pass final verification.
   - `pr`: create or reuse one branch/worktree suitable for the plan PR; in `finish auto`, keep all chunks on that branch.
9. Implement the phase. If the user explicitly requested agents, delegate implementation to a worker with the worktree path; otherwise implement inline.
10. Verify from actual diffs with a fresh verification context before landing. Use a separate verifier only when that is available under the current Codex delegation policy; otherwise run inline verification, disclose the lower assurance, and do not auto-land unless the user explicitly accepts inline verification.
11. Update the plan progress tracker and write or update `reports/plan-<slug>.md`.
12. Land only after verification passes and the requested mode allows it. Stage explicit files, avoid unrelated changes, and preserve user work.
13. For `finish` without `auto`, preserve chunking: execute at most one substantive phase per top-level Codex turn unless the user explicitly says to continue in the same turn after seeing the phase result.

## Chunked Finish

`finish` means "keep advancing this plan until done," not "merge all phases into one long context." After each phase:

1. Persist state in the plan progress tracker and `reports/plan-<slug>.md`.
2. Write a concise handoff: completed phase, branch/worktree, tests, landing state, next phase, blockers, and exact suggested next invocation.
3. Stop the turn unless the user explicitly requested same-turn continuation and the remaining context/risk is small, or this is `finish auto` in the parent turn and the external runner is available.
4. For `finish auto`, prefer resumable top-level turns over long in-context loops. Unattended completion is runner-backed by `.agents/zskills-support/scripts/zskills-runner.sh` or `$CODEX_HOME/zskills-support/scripts/zskills-runner.sh`; the skill must invoke that runner directly when available. The runner launches fresh `codex exec` invocations and validates durable state between chunks. In cherry-pick and PR modes, those chunks share one plan-level worktree/branch so later phases build on earlier phases without repeated landing cycles. Without that external runner, `finish auto` degrades to one chunk plus a handoff; Codex has no built-in Z Skills cron.
5. Never combine multiple plan phases into one implementation chunk just to reduce orchestration overhead.

## Codex-Native Replacements

- Do not use `CronCreate`, `CronList`, or `CronDelete`. For `every`, `next`, or `stop`, explain that Codex has no built-in scheduler and ask before creating an external schedule.
- Do not use Claude `Agent` prompts or `isolation` parameters. Use Codex sub-agents only when explicitly authorized by the current Codex delegation policy.
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

Use one shared config contract across Z Skills. Read `.agents/zskills-config.json`, then `zskills-config.json`, then legacy `.codex/zskills-config.json`, then legacy `.claude/zskills-config.json`.

- `execution.landing: "direct"`: work on the current branch/main only with a clean tree, no unrelated changes, explicit current-turn authorization for broad/autonomous work, and `execution.main_protected` false or explicitly overridden after warning.
- `execution.landing: "cherry-pick"`: for a single phase, work in a manual git worktree, commit the phase there, verify, then cherry-pick the scoped commit back to `${execution.base_branch:-main}` from `${execution.remote:-origin}`. For `finish auto`, reuse one shared plan-level worktree across chunks and cherry-pick/land once after all remaining phases pass final verification. This is the default.
- `execution.landing: "pr"`: work in a manual git worktree on `${execution.branch_prefix}...`, push to `${execution.remote:-origin}`, create a PR with `gh` if available, and do not push directly to main. For `finish auto`, use one branch/worktree for the whole plan.

Explicit request words `direct` or `pr` override config for the current invocation. `locked-main-pr` means `execution.landing: "pr"` plus `execution.main_protected: true`.

## Landing Helper Contract

Use project-local helpers first. If absent, inspect `.agents/zskills-support/scripts/*` or `$CODEX_HOME/zskills-support/scripts/*` before relying on prose:

- `worktree-add-safe.sh`: create isolated worktrees and reject branch/path poisoning.
- `write-landed.sh` and `land-phase.sh`: record scoped landing state and cleanup only expected ephemeral files.
- `post-run-invariants.sh`: check base freshness, landing evidence, report state, and dirty tree after landing.
- `zskills-gate.sh`: Codex-native pre-land/pre-continue/pre-push gate for reports, tracking markers, ignored tracking files, and untracked artifacts.

Do not run support scripts blindly when a project has different branch names or report paths; pass config-derived base/remote values or adapt a project-local copy.

## Minimum Report

Every executed phase should report: plan, phase, branch/worktree, files changed, tests run, verification result, landing result, and remaining phases.
Do not claim that work was committed, cherry-picked, pushed, or fully landed until that git operation has actually succeeded. Before landing, use pending language; after landing, update the report with the real landed state.
Verification reports used as landing evidence are project artifacts; keep them under `reports/` and land them with the phase report unless the repository has an explicit external-report convention.

## Tracking And Gates

Retain file-based tracking even though Codex does not run Claude hooks:

1. Create `.zskills/tracking/<pipeline-id>/` for the plan run.
2. Before verification, write `requires.verify-changes.<tracking-id>` with phase, diff base, and expected report path.
3. During the phase, write canonical markers: `step.run-plan.<tracking-id>.implement`, `step.run-plan.<tracking-id>.verify`, and `step.run-plan.<tracking-id>.report`.
4. For `finish`, if another phase remains, write `handoff.run-plan.<tracking-id>` after the phase so the next top-level turn can resume without relying on conversation memory. In `finish auto` cherry-pick/PR mode, keep source, plan, and report progress committed in the shared worktree/branch for the next chunk. Do not leave `step.run-plan.<tracking-id>.land` or `fulfilled.run-plan.<tracking-id>` present for a non-final chunk.
5. Only when the plan is complete, write `step.run-plan.<tracking-id>.land` and finally `fulfilled.run-plan.<tracking-id>`, and remove any stale `handoff.run-plan.<tracking-id>`.
6. Before landing, check the `implement`, `verify`, and `report` markers plus the persistent verification report. Treat missing or inconsistent markers as a stop condition unless the user explicitly chooses manual recovery.

Tracking files are ephemeral gates. Do not include `.zskills/`, `.zskills-tracked`, or other tracking marker files in landed commits or PRs unless the user explicitly asks to version them.

## Post-Landing Gates

- Before landing, pushing, scheduling another chunk, or declaring completion, re-check whether main/base moved since verification. If it moved, re-run verification on the current diff.
- After landing, run project-local `scripts/post-run-invariants.sh` when available. If absent, inspect or adapt `.agents/zskills-support/scripts/post-run-invariants.sh` or `$CODEX_HOME/zskills-support/scripts/post-run-invariants.sh` when the project uses Z Skills tracking. Do not schedule the next chunk or declare completion if invariants fail.
- Before declaring a phase complete, inspect `git status --short`. Only expected ephemeral tracking files may remain uncommitted. Untracked reports, source files, tests, plans, or config files are a stop condition.

## Preserved Z Skills Invariants

- Extract and follow the phase text exactly, but challenge unsafe or impossible instructions.
- Write/update the phase report before landing.
- Require a separate verifier per phase when it is available under the current Codex delegation policy; otherwise disclose inline verification and reduced assurance.
- Block auto-landing when verification fails, user sign-off is required, scope changed materially, or unrelated changes are present.
- Preserve delegate/direct/worktree/PR modes with Codex-native mechanics.
- Preserve chunking to reduce context fatigue and resource anxiety; do not collapse remaining phases into one mega-phase.
- Preserve tracking-file gates as manual Codex checks, even without hook enforcement.
- Keep tracking files out of landed commits and PRs by default.
- Re-run verification when the base moved and run post-run invariants before continuing.
- Do not leave verification reports or other project artifacts untracked after landing.
