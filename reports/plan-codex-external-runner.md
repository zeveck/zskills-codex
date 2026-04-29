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
