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
