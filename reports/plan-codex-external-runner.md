# Codex External Runner Plan Report

## Phase 1: Contract, Schema, And Documentation

Status: verified.

Plan: `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`

Files changed:

- `/home/vscode/.codex/zskills-support/config/zskills-config.schema.json`
- `/home/vscode/.codex/zskills-support/docs/CODEX_PORT.md`
- `/home/vscode/.codex/skills/run-plan/SKILL.md`
- `/home/vscode/.codex/skills/zskills-codex/SKILL.md`
- `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`
- `/workspaces/zimulinkCodexZ/.gitignore`
- `/workspaces/zimulinkCodexZ/reports/plan-codex-external-runner.md`

Implemented:

- Added `runner.*` configuration schema for external `finish auto` orchestration.
- Documented that unattended `finish auto` requires an external fresh-invocation runner.
- Documented that interactive/no-runner `finish auto` degrades to one chunk plus a handoff.
- Added `run-plan` external runner contract and stop conditions.
- Added `zskills-codex` runner summary, safety defaults, and restart guidance.
- Added `.zskills/tracking/` to `.gitignore`.

Verification run:

- `python3 -m json.tool /home/vscode/.codex/zskills-support/config/zskills-config.schema.json >/dev/null`
- Manual scan for `CronCreate`, `CronList`, `CronDelete`, `dangerously-bypass`, and `.claude/settings` in active runner docs/wrappers. Matches are refusal/compatibility language only.
- Confirmed `.zskills/tracking/` is ignored by git.
- Fresh verifier reviewed the schema/docs/wrapper contract and found Phase 1 can be marked verified. It noted low scope drift for adding `.gitignore`; this is acknowledged as execution-repo tracking setup, not runner contract behavior.

Landing state:

- Installed Codex files updated in place under `/home/vscode/.codex/...`.
- Repository artifacts are present under `/workspaces/zimulinkCodexZ` but not committed in this chunk because the primary installed-file changes live outside the repo worktree.

Next phase:

- Phase 2: Runner CLI Skeleton.

Handoff:

- Next invocation: `run-plan /home/vscode/.codex/zskills-support/plans/codex-external-runner.md finish auto`
- Expected next phase: Phase 2, Runner CLI Skeleton.
- Blockers: none for Phase 2. Decide later whether this repo should mirror installed-file diffs or only hold reports/tracking.

## Phase 2: Runner CLI Skeleton

Status: verified.

Plan: `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`

Files changed:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`
- `/workspaces/zimulinkCodexZ/reports/plan-codex-external-runner.md`

Implemented:

- Added `zskills-runner.sh` skeleton with `--help`, `status`, `stop`, and `run-plan <plan> finish auto --dry-run`.
- Added config discovery from `.codex/zskills-config.json`, `zskills-config.json`, and legacy `.claude/zskills-config.json`.
- Added runner default resolution for max chunks, timeouts, log dir, stop marker, sandbox, approval policy, plan slug, and pipeline id.
- Added Codex binary detection and dangerous bypass refusal.
- Added non-git repository refusal.
- Added a runner test harness covering help, non-repo refusal, dry-run config resolution, missing Codex binary, and dangerous bypass refusal.

Verification run:

- `bash -n /home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh --help`
- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh run-plan plans/example.md finish auto --repo /tmp/nonrepo --dry-run` returned exit 2 with the expected non-git refusal.
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh all`
- Fresh verifier reviewed Phase 2 and found no blocking issues. It found a low parser issue for `run-plan <plan> finish auto` without options; fixed by allowing the no-option command to parse and then refuse execution as not implemented for Phase 2.
- Added test coverage for the no-option parse path.

Landing state:

- Installed Codex support files updated in place under `/home/vscode/.codex/...`.
- Repository report update pending commit.

Next phase:

- Phase 3: State Inspection, Locking, And Stop Gates.

Handoff:

- Next invocation: `run-plan /home/vscode/.codex/zskills-support/plans/codex-external-runner.md finish auto`
- Expected next phase: Phase 3, State Inspection, Locking, And Stop Gates.
- Blockers: none for Phase 3.

## Phase 3: State Inspection, Locking, And Stop Gates

Status: verified.

Plan: `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`

Files changed:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`
- `/workspaces/zimulinkCodexZ/reports/plan-codex-external-runner.md`

Implemented:

- Added runner preflight gates before future chunk execution.
- Added per-plan lock acquisition under `.zskills/runner/<plan-slug>.lock` with automatic cleanup on exit.
- Added refusal for live lock conflicts.
- Added refusal for `CHERRY_PICK_HEAD`, `MERGE_HEAD`, `REBASE_HEAD`, rebase directories, unresolved conflicts, and `pre-cherry-pick` stash residue.
- Added `.zskills/tracking/` ignore verification when tracking exists.
- Added plan/report/tracking path and hash output to status/dry-run resolution.
- Added direct unattended refusal unless `runner.allow_direct_unattended` or `--allow-direct-unattended` is set.
- Fixed absolute Git directory handling after tests exposed that relative `.git` paths could inspect the caller repo instead of the target repo.
- Added initial state extraction and JSON recording for plan/report/tracking state without relying on chat text.
- Added direct-mode clean-tree enforcement when unattended direct mode is explicitly allowed.
- Narrowed the direct-mode clean-tree exception to the current runner-owned lock path only.

Verification run:

- `bash -n /home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh preflight`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh all`
- Manual status smoke test in `/workspaces/zimulinkCodexZ` confirmed plan/report hashes and tracking/report paths are printed.
- Fresh verifier initially found missing initial state recording; fixed and tested.
- Fresh verifier then found direct mode allowed with dirty tree; fixed and tested.
- Final fresh verifier passed Phase 3.

Landing state:

- Installed Codex support files updated in place under `/home/vscode/.codex/...`.
- Repository report update pending commit.

Next phase:

- Phase 4: Fresh Chunk Execution And Logging.

Handoff:

- Next invocation: `run-plan /home/vscode/.codex/zskills-support/plans/codex-external-runner.md finish auto`
- Expected next phase: Phase 4, Fresh Chunk Execution And Logging.
- Blockers: none for Phase 4.

## Phase 4: Fresh Chunk Execution And Logging

Status: verified.

Plan: `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`

Files changed:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/fake-codex.sh`
- `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`
- `/workspaces/zimulinkCodexZ/reports/plan-codex-external-runner.md`

Implemented:

- Added one fresh child `codex exec` invocation for `run-plan <plan> finish auto`.
- Added structured runner log directory under configured `runner.log_dir`.
- Added `chunk-001.events.jsonl`, `chunk-001.stdout.txt`, `chunk-001.last-message.txt`, `chunk-001.summary.json`, and `runner.jsonl`.
- Added summary fields for command argv, cwd, Codex version, timestamps, exit code, before/after state, gate result placeholder, and stop reason.
- Added fake Codex binary injection through `CODEX_BIN`.
- Added child process timeout and idle-timeout enforcement.
- Added fake success, failure, timeout, and idle-timeout tests.

Verification run:

- `bash -n /home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/fake-codex.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-success`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-fail`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-timeout`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-idle-timeout`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh all`
- Fresh verifier passed Phase 4 with no blocking findings.

Landing state:

- Installed Codex support files updated in place under `/home/vscode/.codex/...`.
- Repository report update pending commit.

Next phase:

- Phase 5: Post-Chunk Validation And Progress Detection.

Handoff:

- Next invocation: `run-plan /home/vscode/.codex/zskills-support/plans/codex-external-runner.md finish auto`
- Expected next phase: Phase 5, Post-Chunk Validation And Progress Detection.
- Blockers: none for Phase 5.

## Phase 5: Post-Chunk Validation And Progress Detection

Status: verified.

Plan: `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`

Files changed:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/fake-codex.sh`
- `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`
- `/workspaces/zimulinkCodexZ/reports/plan-codex-external-runner.md`

Scope Assessment:

- Phase 5 was limited to validating a completed single chunk before any future continuation.
- No multi-chunk loop, PR canary, or maintenance-doc integration was implemented; those remain Phase 6 and Phase 7 work.
- Landing behavior remains owned by `run-plan`; the runner validates durable state and gates before permitting another fresh invocation.

Implemented:

- Added post-chunk durable progress validation after child `codex exec` exits successfully.
- Progress now requires at least one durable signal: plan hash change, report hash change, new `fulfilled.run-plan.*`, or new `handoff.run-plan.*`.
- Added mandatory handoff enforcement unless the plan tracker is complete.
- Added derived tracking ID validation so report-only progress cannot bypass verifier marker checks.
- Added report evidence checks requiring a report with a scope assessment.
- Added verifier marker checks for `requires.verify-changes`, `step.verify-changes.*.complete`, and `fulfilled.verify-changes`.
- Added `zskills-gate.sh --mode pre-continue` execution once a tracking ID is derived.
- Added explicit dirty-artifact blocking through the pre-continue gate and runner dirty-state check.
- Recorded validation result, reason, progress signals, tracking ID, gate result, and post-run invariant status in `chunk-001.summary.json`.
- Added fake Codex modes and tests for progress success, no progress, missing handoff, missing report, missing scope assessment, missing verifier markers, and dirty artifacts.

Verification run:

- `bash -n /home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/fake-codex.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh progress-detected`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh no-progress-blocks`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh missing-handoff-blocks`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh missing-report-blocks`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh missing-scope-blocks`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh missing-verifier-blocks`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh dirty-artifact-blocks`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-timeout`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-idle-timeout`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh all`

Verifier result:

- Fresh verifier initially found that the implementation checks were present but blocker coverage was incomplete.
- Added named tests for missing report, missing scope assessment, missing verifier markers, and dirty artifacts.
- Fresh verifier re-ran Phase 5 review and reported no blocking findings.

Landing state:

- Installed Codex support files updated in place under `/home/vscode/.codex/...`.
- Repository report update pending commit.

Next phase:

- Phase 6: Multi-Chunk Canary And Landing Modes.

Handoff:

- Next invocation: `run-plan /home/vscode/.codex/zskills-support/plans/codex-external-runner.md finish auto`
- Expected next phase: Phase 6, Multi-Chunk Canary And Landing Modes.
- Blockers: none for Phase 6.

## Phase 6: Multi-Chunk Canary And Landing Modes

Status: verified.

Plan: `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`

Files changed:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/fake-codex.sh`
- `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`
- `/workspaces/zimulinkCodexZ/reports/plan-codex-external-runner.md`

Scope Assessment:

- Phase 6 was limited to runner canaries and landing-mode/failure coverage.
- Documentation and maintenance wrapper integration remain Phase 7 work.
- The canaries use disposable Git repositories and fake Codex child processes; no external remote or GitHub PR is required.

Implemented:

- Added bounded multi-chunk execution over fresh `codex exec` child invocations.
- Added completion detection from durable plan state and a `runner_stop_reason=complete` terminal state.
- Added `runner_stop_reason=max-chunks` for bounded incomplete runs.
- Added per-chunk numbered summaries/logs across multiple chunks.
- Added post-land gate mode for completed chunks.
- Added actual `post-run-invariants.sh` invocation for landed/complete chunks with available runner arguments.
- Added stale git worktree residue refusal before launching child Codex.
- Added multi-phase fake Codex progress mode that advances one phase per fresh child invocation.
- Added canaries for multi-chunk completion, max-chunk stop, cherry-pick completion evidence, PR dry-run immutability, and stale worktree refusal.
- Strengthened the cherry-pick canary to assert final summary `gate_result`, `runner_stop_reason`, and `post_run_invariants_result`.

Verification run:

- `bash -n /home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `bash -n /home/vscode/.codex/zskills-support/tests/runner/fake-codex.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh multi-chunk`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh max-chunks`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh cherry-pick-canary`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh pr-dry-run`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh stale-worktree`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh preflight`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-timeout`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-idle-timeout`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh all`

Manual review:

- Searched active scripts/docs/wrappers for dangerous bypass and Claude scheduling terms.
- Active matches were refusal or compatibility text only.
- Archived upstream references still contain Claude-era cron text, as expected, but they are not active Codex instructions.

Verifier result:

- Fresh verifier initially found missing post-run-invariant execution and thin stale-worktree/cherry-pick assertions.
- Added actual invariant invocation, stale worktree refusal, stale-worktree test, and stronger final summary assertions.
- Fresh verifier re-ran Phase 6 review and reported no remaining blockers.

Landing state:

- Installed Codex support files updated in place under `/home/vscode/.codex/...`.
- Repository report update pending commit.

Next phase:

- Phase 7: Update Workflow Integration.

Handoff:

- Next invocation: `run-plan /home/vscode/.codex/zskills-support/plans/codex-external-runner.md finish auto`
- Expected next phase: Phase 7, Update Workflow Integration.
- Blockers: none for Phase 7.

## Phase 7: Update Workflow Integration

Status: verified.

Plan: `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`

Files changed:

- `/home/vscode/.codex/skills/update-zskills/SKILL.md`
- `/home/vscode/.codex/skills/zskills-codex/SKILL.md`
- `/home/vscode/.codex/skills/run-plan/SKILL.md`
- `/home/vscode/.codex/zskills-support/docs/CODEX_PORT.md`
- `/home/vscode/.codex/zskills-support/plans/codex-external-runner.md`
- `/workspaces/zimulinkCodexZ/reports/plan-codex-external-runner.md`

Scope Assessment:

- Phase 7 was limited to active documentation and maintenance workflow integration.
- No runner runtime behavior changed in this phase.
- Because active skill metadata changed, Codex may need a restart before updated descriptions or trigger metadata are visible in a new session.

Implemented:

- Updated `update-zskills` to require external runner canaries during maintenance.
- Updated `update-zskills` to preserve `zskills-runner.sh` and tests when refreshing upstream support assets unless replaced with equivalent or stronger canary coverage.
- Updated `zskills-codex` to document the implemented runner location, unattended role, safety defaults, terminal stop conditions, validation tests, and restart guidance.
- Updated `run-plan` to state that unattended `finish auto` is runner-backed and otherwise degrades to a one-chunk handoff.
- Updated `CODEX_PORT.md` to distinguish Codex-native support scripts from archived upstream material.
- Updated `CODEX_PORT.md` with the implemented runner contract, terminal stops, and validation canaries.

Verification run:

- `rg` manual checklist over active docs/wrappers for runner canaries, runner location, restart guidance, one-chunk fallback, Codex-native support boundaries, and archived upstream material.
- `for f in /home/vscode/.codex/zskills-support/scripts/{zskills-runner.sh,zskills-gate.sh,post-run-invariants.sh,land-phase.sh,worktree-add-safe.sh,clear-tracking.sh}; do bash -n "$f" || exit 1; done`
- `python3 -m json.tool /home/vscode/.codex/zskills-support/config/zskills-config.schema.json >/dev/null`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh all`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-timeout`
- `/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-idle-timeout`

Verifier result:

- Fresh verifier reported no findings.
- Verifier confirmed all Phase 7 acceptance criteria were met.
- Verifier re-ran runner syntax and canary checks successfully.

Landing state:

- Installed Codex support files updated in place under `/home/vscode/.codex/...`.
- Repository report update pending commit.

Plan completion:

- All seven phases are complete and verified.
- External runner work is now integrated into the Codex Z Skills maintenance contract.

Handoff:

- No remaining phases.
- For future maintenance, use `update-zskills` and run the documented runner canaries.
- Restart Codex if you need active skill metadata changes to be picked up in a fresh session.
