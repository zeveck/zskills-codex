# Simple Three Phase Run-Plan Canary

## Goal

Validate that `/run-plan finish auto` can complete three small phases in a fresh session by producing deterministic canary files, updating a manifest, and running a simple verification script after each phase.

## Context

This plan is intentionally small and local-only. It should not modify the ZSkills port source, installer, support scripts, README, existing reports, or existing plans. The only expected project changes are under:

- `canary-output/`
- `scripts/test-simple-run-plan-canary.sh`
- `reports/plan-simple-three-phase-run-plan-canary.md`
- this plan file's progress tracker

Default ZSkills landing behavior is acceptable. If no repo config exists, `/run-plan` may use the default cherry-pick workflow.

## Non-Goals

- Do not test GitHub PR creation.
- Do not change package metadata, skill wrappers, installer behavior, or runner code.
- Do not create cron jobs or background schedulers.
- Do not remove or weaken skill frontmatter/YAML.

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Create alpha canary file | ✅ Done | Created `canary-output/phase-1-alpha.txt`, initialized `canary-output/manifest.txt`, created the verification script, and verified phase 1. |
| 2. Create beta canary file | ✅ Done | Created `canary-output/phase-2-beta.txt`, appended it to the manifest, and verified phases 1-2. |
| 3. Create gamma canary file | ⬜ Not Started | Create `canary-output/phase-3-gamma.txt`, append it to the manifest, and verify phases 1-3. |

## Phase Details

### Phase 1. Create Alpha Canary File

Create `canary-output/phase-1-alpha.txt` with exactly:

```text
phase=1
name=alpha
status=complete
```

Create `canary-output/manifest.txt` with exactly:

```text
phase-1-alpha.txt
```

Create executable `scripts/test-simple-run-plan-canary.sh`. The script should:

- run from the repository root;
- fail if `canary-output/manifest.txt` is missing;
- read the manifest lines;
- for each manifest entry, verify that the referenced file exists;
- verify the exact contents for every listed file;
- allow progressive states after phase 1, phase 2, or phase 3;
- reject unknown manifest entries or out-of-order manifest entries.

After phase 1, run:

```bash
bash scripts/test-simple-run-plan-canary.sh
```

Expected result: the script passes with only `phase-1-alpha.txt` listed.

### Phase 2. Create Beta Canary File

Create `canary-output/phase-2-beta.txt` with exactly:

```text
phase=2
name=beta
status=complete
```

Update `canary-output/manifest.txt` to exactly:

```text
phase-1-alpha.txt
phase-2-beta.txt
```

Run:

```bash
bash scripts/test-simple-run-plan-canary.sh
```

Expected result: the script passes with phases 1-2 listed in order.

### Phase 3. Create Gamma Canary File

Create `canary-output/phase-3-gamma.txt` with exactly:

```text
phase=3
name=gamma
status=complete
```

Update `canary-output/manifest.txt` to exactly:

```text
phase-1-alpha.txt
phase-2-beta.txt
phase-3-gamma.txt
```

Run:

```bash
bash scripts/test-simple-run-plan-canary.sh
```

Expected result: the script passes with phases 1-3 listed in order.

## Acceptance Criteria

- Each phase produces only the files described for that phase, plus the normal plan/report updates required by `/run-plan`.
- `scripts/test-simple-run-plan-canary.sh` passes after every phase.
- The final `canary-output/manifest.txt` contains exactly the three expected file names in order.
- The final `canary-output/` directory contains exactly:
  - `manifest.txt`
  - `phase-1-alpha.txt`
  - `phase-2-beta.txt`
  - `phase-3-gamma.txt`
- The final report at `reports/plan-simple-three-phase-run-plan-canary.md` includes a scope assessment and verification result for each phase.
- `.zskills/` tracking files remain uncommitted.

## Verification

Run this after any phase:

```bash
bash scripts/test-simple-run-plan-canary.sh
```

Final verification may also use:

```bash
find canary-output -maxdepth 1 -type f -printf '%f\n' | sort
cat canary-output/manifest.txt
git status --short
```

## Risks

- If run through an unattended external runner in an environment where Codex `workspace-write` sandboxing is blocked by bubblewrap/user-namespace restrictions, use the runner's documented `--sandbox danger-full-access` option only in an externally isolated disposable environment.
- If the run uses cherry-pick mode, ensure the plan, report, canary files, and test script all land together for each phase.
