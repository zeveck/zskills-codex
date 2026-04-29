# Codex Z Skills External Runner Plan

## Goal

Add a Codex-native external runner that makes `run-plan <plan> finish auto` meaningful without collapsing multiple plan phases into one agent context. The runner repeatedly launches fresh `codex exec` invocations, validates durable state after each chunk, and stops when the plan is complete or blocked.

## Context

The upstream Z Skills `finish auto` behavior relied on Claude Code scheduling/re-entry. Codex has no built-in `CronCreate` equivalent, but the local CLI supports non-interactive fresh invocations via `codex exec -C <repo> <prompt>`. The runner should restore automatic continuation while preserving the current Codex port invariants:

- one substantive phase per top-level Codex invocation
- fresh verifier/reviewer agents inside each phase when available
- file-based `.zskills/tracking/<pipeline-id>/` gates
- reports under `reports/` as landing evidence
- direct, cherry-pick, and PR landing mode semantics
- no Claude hooks, `.claude/settings.json`, or Claude cron tools

## Non-Goals

- Do not implement an in-agent recursive loop.
- Do not use `codex exec resume`; fresh invocations are the point.
- Do not install cron, systemd timers, or CI jobs unless a user explicitly requests that later.
- Do not default to `--dangerously-bypass-approvals-and-sandbox`.
- Do not delete `.zskills/tracking/` automatically; cleanup remains an explicit recovery operation.
- Do not reinterpret landing behavior inside the runner. `run-plan` remains responsible for phase implementation and landing; the runner validates and re-enters.

## Assumptions

- The runner will live under `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh` unless a project-local script is preferred during implementation.
- Tests and fixtures can live under `/home/vscode/.codex/zskills-support/tests/runner/`.
- Config schema changes go in `/home/vscode/.codex/zskills-support/config/zskills-config.schema.json`.
- Documentation updates go in `/home/vscode/.codex/zskills-support/docs/CODEX_PORT.md`, `run-plan/SKILL.md`, `zskills-codex/SKILL.md`, and `update-zskills/SKILL.md` as needed.
- The current workspace `/workspaces/zimulinkCodexZ` is not a Git repository. `run-plan` execution therefore needs an explicit Git context: either the external repo the user is preparing, or a disposable/local Git repo created specifically to track this Codex port work.

## Execution Setup

Before running this plan with `run-plan`, choose one execution context:

1. Preferred: use the external Git repository the user is preparing for this work, then run the plan from that repo while editing the installed Codex files under `/home/vscode/.codex/...`.
2. Fallback: create a local disposable Git repository that tracks copies or patches of the zskills support files, then apply completed changes back to `/home/vscode/.codex/...` after verification.

Do not run this plan from `/workspaces/zimulinkCodexZ` unless that directory has first been initialized as the intended Git repo and configured for the work. If no Git context exists, the first action is setup, not implementation.

## Design Requirements

The runner is a bounded state machine:

1. Acquire a single-run lock for the plan/pipeline.
2. Inspect repo/config/plan/tracking/report state.
3. Refuse unsafe or ambiguous states before launching Codex.
4. Launch one fresh `codex exec` chunk.
5. Capture JSONL events, final message, timestamps, exit code, file hashes, phase state, markers, and gate results.
6. Validate durable state with support scripts and direct checks.
7. Continue only if progress is proven and the configured budget allows another chunk.
8. Stop with a terminal reason: complete, blocked, failed, timed out, stopped by user, or max chunks reached.

Suggested command:

```bash
zskills-runner.sh run-plan <plan-file-or-slug> finish auto \
  --repo <repo> \
  --max-chunks 10 \
  --chunk-timeout-min 90 \
  --idle-timeout-min 15 \
  --sandbox workspace-write
```

Codex invocation should be argv-based, not `eval`:

```bash
codex exec -C "$repo" --sandbox "$sandbox" --ask-for-approval never \
  --json -o "$chunk_dir/last-message.txt" \
  "run-plan $plan finish auto"
```

`--ask-for-approval never` is acceptable only for the non-interactive child process when paired with conservative sandboxing and runner gates. The runner must refuse `--dangerously-bypass-approvals-and-sandbox` unless a future explicit flag and external sandbox are added.

## Stop Conditions

Stop successfully when:

- the plan progress tracker has no incomplete phases, or
- `reports/plan-<slug>.md` indicates no remaining phases and the final markers are consistent.

Stop blocked when:

- `codex exec` exits nonzero
- no durable progress occurred
- the same next phase appears twice with unchanged plan/report hashes
- the handoff marker is missing after a chunk
- `zskills-gate.sh` fails
- `post-run-invariants.sh` fails after landing
- unexpected dirty or untracked project artifacts remain
- verifier/report markers are missing
- direct mode is requested for unattended running without explicit runner opt-in
- PR mode reaches a waiting, failed, or ambiguous terminal state
- merge, rebase, cherry-pick, or stash residue exists
- max chunks, wall-clock timeout, idle timeout, or stop marker is reached

## Config Additions

Extend the shared schema with:

```json
{
  "runner": {
    "max_chunks": 10,
    "chunk_timeout_minutes": 90,
    "idle_timeout_minutes": 15,
    "log_dir": ".zskills/logs",
    "stop_marker": ".zskills/stop",
    "require_handoff": true,
    "require_progress_hash_change": true,
    "sandbox": "workspace-write",
    "approval_policy": "never",
    "allow_direct_unattended": false,
    "pr_max_rechecks": 0
  }
}
```

The runner should continue to honor existing `execution.*`, `testing.*`, `dev_server.*`, `ui.*`, and `ci.*` by passing control to `run-plan`, not duplicating its logic.

## Phases

### Phase 1: Contract, Schema, And Documentation

Define the runner contract before implementation.

Likely files:

- `/home/vscode/.codex/zskills-support/config/zskills-config.schema.json`
- `/home/vscode/.codex/zskills-support/docs/CODEX_PORT.md`
- `/home/vscode/.codex/skills/run-plan/SKILL.md`
- `/home/vscode/.codex/skills/zskills-codex/SKILL.md`

Acceptance criteria:

- Schema includes `runner.*` defaults and descriptions.
- Docs distinguish interactive `finish` from runner-backed `finish auto`.
- Docs say the runner is an external fresh-invocation state machine, not an in-agent loop.
- Docs state direct mode is refused for unattended runs unless explicitly enabled.
- No `.claude` runtime paths or Claude cron/tool assumptions are introduced.

Verification:

```bash
python3 -m json.tool /home/vscode/.codex/zskills-support/config/zskills-config.schema.json >/dev/null
```

Manual review: search active docs/wrappers for `CronCreate`, `CronList`, `CronDelete`, `dangerously-bypass`, and `.claude/settings`; any matches must be refusal/compatibility language, not executable instructions or defaults.

Rollback:

- Revert schema/docs changes only. No runtime behavior exists yet.

### Phase 2: Runner CLI Skeleton

Add the runner script with argument parsing, config discovery, dry-run, status, and stop-marker support.

Likely files:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/scripts/sanitize-pipeline-id.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/`

Acceptance criteria:

- `zskills-runner.sh --help` documents commands and safety defaults.
- `run-plan <plan> finish auto --dry-run` prints resolved repo, plan slug, config, log dir, stop marker, and intended `codex exec` argv.
- Refuses outside a Git repository unless a future explicit fixture flag is used.
- Refuses missing `codex` CLI.
- Refuses unsafe CLI combinations, especially dangerous bypass.
- Does not mutate files in dry-run.

Verification:

```bash
bash -n /home/vscode/.codex/zskills-support/scripts/zskills-runner.sh
/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh --help
/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh run-plan plans/example.md finish auto --repo /tmp/nonrepo --dry-run
```

Rollback:

- Delete the runner script and tests.

### Phase 3: State Inspection, Locking, And Stop Gates

Implement preflight checks before any `codex exec` launch.

Likely files:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/fixtures/`

Acceptance criteria:

- Acquires a lock under `.zskills/runner/<plan-slug>.lock` or equivalent and releases it on exit.
- Refuses if another live runner owns the lock.
- Refuses unresolved Git states: `CHERRY_PICK_HEAD`, `MERGE_HEAD`, `REBASE_HEAD`, unresolved conflicts, or pre-cherry-pick stash residue.
- Confirms `.zskills/tracking/` is ignored when present.
- Computes plan/report hashes before launch.
- Records initial phase/tracking/report state without relying on chat text.
- Refuses direct unattended mode unless `runner.allow_direct_unattended` is true and tree checks pass.

Verification:

```bash
bash -n /home/vscode/.codex/zskills-support/scripts/zskills-runner.sh
# fixture tests should cover lock conflict, non-git repo, dirty tree, merge residue, and direct-mode refusal
/home/vscode/.codex/zskills-support/tests/runner/run.sh preflight
```

Rollback:

- Disable runner execution path while preserving `--help` and docs.

### Phase 4: Fresh Chunk Execution And Logging

Wire one fresh `codex exec` chunk with structured logs.

Likely files:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/fake-codex.sh`

Acceptance criteria:

- Each chunk uses a new `codex exec`, not resume/fork/sub-agent recursion.
- Runner captures:
  - `chunk-NNN.events.jsonl`
  - `chunk-NNN.last-message.txt`
  - `chunk-NNN.summary.json`
  - `runner.jsonl`
- Summary includes command argv, cwd, codex version, start/end timestamps, exit code, phase before/after, plan/report hashes, markers found, gate result, and stop reason.
- Supports test injection via `CODEX_BIN=<fake-codex>` without changing production behavior.
- Enforces chunk timeout and idle timeout.

Verification:

```bash
/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-success
/home/vscode/.codex/zskills-support/tests/runner/run.sh fake-timeout
python3 -m json.tool <chunk-summary.json> >/dev/null
```

Rollback:

- Keep preflight/status functionality and disable execution with a feature flag.

### Phase 5: Post-Chunk Validation And Progress Detection

Validate one completed chunk and decide whether another fresh invocation is allowed.

Likely files:

- `/home/vscode/.codex/zskills-support/scripts/zskills-runner.sh`
- `/home/vscode/.codex/zskills-support/scripts/zskills-gate.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/fixtures/`

Acceptance criteria:

- Successful `codex exec` exit is not enough to continue.
- Runner verifies durable progress via at least one of:
  - plan tracker changed
  - report hash changed
  - new `fulfilled.run-plan.*` marker
  - new `handoff.run-plan.*` marker
- Runner requires `handoff.run-plan.<tracking-id>` between chunks unless plan is complete.
- Runner runs `zskills-gate.sh --mode pre-continue` when tracking IDs are known.
- Runner runs `post-run-invariants.sh` when a landed state is detected and required args are available.
- Runner blocks on missing verification report, missing scope assessment, missing verifier markers, or unexpected dirty artifacts.

Verification:

```bash
/home/vscode/.codex/zskills-support/tests/runner/run.sh progress-detected
/home/vscode/.codex/zskills-support/tests/runner/run.sh no-progress-blocks
/home/vscode/.codex/zskills-support/tests/runner/run.sh missing-handoff-blocks
/home/vscode/.codex/zskills-support/scripts/zskills-gate.sh --repo /tmp/zskills-codex-canary --mode pre-continue --pipeline run-plan.canary-plan --tracking-id canary-plan.phase-2 --plan-slug canary-plan
```

Rollback:

- Disable auto-continuation while preserving logs for diagnosis.

### Phase 6: Multi-Chunk Canary And Landing Modes

Exercise the runner against disposable repos for direct refusal, cherry-pick, and PR dry-run semantics.

Likely files:

- `/home/vscode/.codex/zskills-support/tests/runner/run.sh`
- `/home/vscode/.codex/zskills-support/tests/runner/fixtures/`
- `/home/vscode/.codex/zskills-support/docs/CODEX_PORT.md`

Acceptance criteria:

- Multi-phase fixture completes via separate `codex exec` invocations.
- `finish auto` with runner completes all phases or stops on a defined terminal reason.
- Direct mode unattended is refused by default.
- Cherry-pick mode validates worktree creation, gate markers, report landing, and post-run invariants.
- PR mode dry run does not push main and stops at a bounded `needs-human` or configured PR terminal state.
- Failure injection covers missing report, missing verifier marker, dirty tree, stale branch/worktree, no progress, and Codex nonzero exit.

Verification:

```bash
/home/vscode/.codex/zskills-support/tests/runner/run.sh all
```

Manual review: search support scripts and active `SKILL.md` wrappers for dangerous bypass and Claude scheduling terms. Legitimate matches must be explicit refusal/safety text; executable defaults or positive instructions are blockers.

Rollback:

- Keep runner available only in `--dry-run` until failing canaries are fixed.

### Phase 7: Update Workflow Integration

Make the runner part of the Codex Z Skills maintenance contract.

Likely files:

- `/home/vscode/.codex/skills/update-zskills/SKILL.md`
- `/home/vscode/.codex/skills/zskills-codex/SKILL.md`
- `/home/vscode/.codex/zskills-support/docs/CODEX_PORT.md`

Acceptance criteria:

- `update-zskills` validation includes runner canaries.
- `zskills-codex` documents runner location, safety defaults, and when a Codex restart is needed.
- `run-plan` says `finish auto` is runner-backed for unattended completion; without a runner it remains a one-chunk resumable handoff.
- Maintenance docs distinguish support scripts that are Codex-native from upstream-only archived material.

Verification:

Manual review checklist:

- `update-zskills/SKILL.md` explicitly requires runner canaries during maintenance.
- `zskills-codex/SKILL.md` documents `zskills-runner.sh`, safety defaults, and restart guidance if metadata changes.
- `run-plan/SKILL.md` states that unattended `finish auto` requires the external runner; without it, `finish` remains a one-chunk handoff.
- `CODEX_PORT.md` distinguishes Codex-native support scripts from upstream-only archived material and documents the runner contract.

Rollback:

- Revert docs/skill wrapper changes independently from runner code.

## Verification Strategy

Minimum checks before completion:

```bash
for f in /home/vscode/.codex/zskills-support/scripts/{zskills-runner.sh,zskills-gate.sh,post-run-invariants.sh,land-phase.sh,worktree-add-safe.sh,clear-tracking.sh}; do
  bash -n "$f" || exit 1
done
python3 -m json.tool /home/vscode/.codex/zskills-support/config/zskills-config.schema.json >/dev/null
/home/vscode/.codex/zskills-support/tests/runner/run.sh all
```

Manual review:

- Confirm no active Codex wrapper instructs use of Claude-only tools.
- Confirm the runner never defaults to dangerous bypass.
- Confirm `finish auto` documentation no longer overclaims unattended completion without a runner.
- Confirm tracking files remain ignored and uncommitted.

## Risks

- A naive runner could re-enter a failed phase repeatedly. Mitigation: lock, hashes, retry counters, terminal stop reasons.
- Codex exit code may not prove success. Mitigation: durable artifact checks are mandatory.
- Direct mode has ambiguous user consent in unattended runs. Mitigation: refuse by default.
- PR mode can wait forever. Mitigation: bounded PR rechecks and `needs-human` terminal state.
- Support scripts may drift from active wrapper contracts. Mitigation: add runner canaries to `update-zskills`.
- Non-default base/remote can be mishandled. Mitigation: pass `execution.base_branch` and `execution.remote` through all support script calls.

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Contract, Schema, And Documentation | ✅ Done | Schema/docs/wrappers updated and fresh verifier passed; `.gitignore` added in execution repo for tracking support. |
| 2. Runner CLI Skeleton | ✅ Done | Skeleton and tests added; fresh verifier passed and low parser issue fixed. |
| 3. State Inspection, Locking, And Stop Gates | ✅ Done | Preflight gates, initial state recording, and tests added; fresh verifier passed. |
| 4. Fresh Chunk Execution And Logging | ✅ Done | Single-chunk execution and structured logs added; fresh verifier passed. |
| 5. Post-Chunk Validation And Progress Detection | ✅ Done | Durable progress validation, pre-continue gate, blocker checks, and negative tests added; fresh verifier passed. |
| 6. Multi-Chunk Canary And Landing Modes | ✅ Done | Multi-chunk loop, completion/max-chunk stops, landing-mode canaries, stale worktree refusal, and post-run invariant execution added; fresh verifier passed. |
| 7. Update Workflow Integration | ✅ Done | Maintenance docs and active wrappers document runner canaries, safety defaults, restart guidance, and Codex-native support boundaries; fresh verifier passed. |

## Recommended Next Command

After the external Git repo is available:

```bash
cd <target-git-repo>
run-plan /home/vscode/.codex/zskills-support/plans/codex-external-runner.md phase 1
```

If no target repo is available yet, first create or choose the Git execution context described in **Execution Setup**.
