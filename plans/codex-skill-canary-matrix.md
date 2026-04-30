# Codex Skill Canary Matrix

## Goal

Build and run a local canary suite that raises confidence in the Codex Z Skills port across all 22 installable skills without touching real user repositories.

## Context

- The distribution installs 22 skills under `skills/`.
- `run-plan finish auto` has real direct and cherry-pick canaries, plus scripted runner tests.
- `workspace-write` child Codex sandboxing can fail in this container because bubblewrap/user namespaces are unavailable. Canary runner invocations may use `--sandbox danger-full-access` only against disposable local repositories.
- GitHub PR canaries require a disposable remote plus `gh` authentication. Local-only PR checks can validate branch/report/gate behavior but cannot fully prove GitHub PR creation.

## Non-Goals

- Do not modify skill frontmatter to bypass agent or tool restrictions.
- Do not install cron or OS schedules.
- Do not push to `github.com/zeveck/zskills-codex` during canary execution.
- Do not require every skill to perform a full production task; use behavior-appropriate smoke canaries where full execution would be destructive, external-service-bound, or UI/auth-bound.

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Build disposable canary harness | ✅ Done | Added `scripts/canary-zskills-codex.sh` with package, installer, scripted-runner, direct-runner, and cherry-pick-runner checks. |
| 2. Validate package-wide invariants | ✅ Done | `--all` verified 22 skills, frontmatter/reference shape, no `.claude`, no installable `social-seo`, installer preservation, path rewrites, schema, and support script syntax. |
| 3. Run low-risk skill smoke canaries | ✅ Done | Accounted for every skill in `reports/canary-zskills-codex.md`; static/reference checks cover lower-risk and fixture-dependent skills, with explicit deferred canaries noted. |
| 4. Run workflow canaries | ✅ Done | Real direct `finish auto` completed two fresh chunks; real cherry-pick canary landed one scoped commit with canonical tracking markers. |
| 5. Evaluate gaps and update release readiness | ✅ Done | Report records passed checks and residual gaps: PR/GitHub, block-diagram app fixtures, browser fixture, issue/feedback fixtures, and broad research workflows. |

## Acceptance Criteria

- The canary suite uses only temporary repositories unless explicitly configured otherwise.
- The suite can be run with one command from this repo.
- Every installed skill is accounted for as `passed`, `covered-by-invariant`, `skipped-with-reason`, or `failed`.
- Real runner canaries include at least one direct multi-chunk run and one cherry-pick run.
- Reports include exact commands, temp repo paths, pass/fail results, and residual risks.
- Any fixes discovered by the canaries are committed, and `2026.04.0-codex.0` is retagged to the verified commit before release.

## Verification

Run after implementation:

```bash
bash scripts/canary-zskills-codex.sh --quick
bash scripts/canary-zskills-codex.sh --runner
for f in zskills-support/scripts/{zskills-runner.sh,zskills-gate.sh,post-run-invariants.sh,land-phase.sh,worktree-add-safe.sh,clear-tracking.sh} scripts/install.sh scripts/canary-zskills-codex.sh; do
  bash -n "$f" || exit 1
done
zskills-support/tests/runner/run.sh all
zskills-support/tests/runner/run.sh fake-timeout
zskills-support/tests/runner/run.sh fake-idle-timeout
```

## Risks

- Noninteractive `codex exec` can consume meaningful tokens/time; keep canaries small and bounded.
- Some skills are inherently advisory or UI/browser-specific. Those should get invariant checks and one representative smoke path rather than artificial full execution.
- PR mode cannot be fully proven without GitHub credentials and a disposable remote. Document this separately from local branch/worktree validation.
