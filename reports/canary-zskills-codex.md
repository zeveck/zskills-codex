# ZSkills Codex Canary Report

- Generated: 2026-04-30T02:43:02Z
- Repo: /workspaces/zimulinkCodexZ
- Mode: --all
- Sandbox: danger-full-access
- Model: gpt-5.4-mini

## Package Invariants

```text
skill_count=22
frontmatter_and_references=ok
```

Result: PASS

## Installer Preservation

```text
Installed Z Skills for Codex into /tmp/tmp.UHb1skIBAV/codex-home
Installed Z Skills: 22
Restart Codex if you need updated skill metadata to be discovered.
total_skill_dirs_after_install=23
```

Result: PASS

## Scripted Verification

```text
runner tests passed: all
runner tests passed: fake-timeout
runner tests passed: fake-idle-timeout
```

Result: PASS

## Direct Runner Canary

```text
repo=/tmp/zskills-codex-canary-direct.myvpcp
codex_home=/home/vscode/.codex
mode=run-plan
repo=/tmp/zskills-codex-canary-direct.myvpcp
plan=plans/direct-canary.md
plan_path=/tmp/zskills-codex-canary-direct.myvpcp/plans/direct-canary.md
plan_slug=direct-canary
pipeline_id=run-plan.direct-canary
tracking_dir=/tmp/zskills-codex-canary-direct.myvpcp/.zskills/tracking/run-plan.direct-canary
report_path=/tmp/zskills-codex-canary-direct.myvpcp/reports/plan-direct-canary.md
plan_hash=37ac40f4a69c03900a6723486eea37c5433aa2774dc72ad01b68b9a8259d1dc5
report_hash=<missing>
config=/tmp/zskills-codex-canary-direct.myvpcp/.codex/zskills-config.json
max_chunks=4
chunk_timeout_minutes=20
idle_timeout_minutes=8
log_dir=.zskills/logs
stop_marker=.zskills/stop
sandbox=danger-full-access
approval_policy=never
execution_landing=direct
allow_direct_unattended=true
codex_bin=codex
codex_argv=codex exec -C /tmp/zskills-codex-canary-direct.myvpcp --add-dir /tmp --sandbox danger-full-access -c approval_policy="never" -m gpt-5.4-mini run-plan plans/direct-canary.md finish auto
plan_state=present
plan_done_count=0
plan_in_progress_count=0
plan_not_started_count=2
report_state=missing
tracking_state=missing
tracking_marker_count=0
initial_state_file=/tmp/zskills-runner-state/direct-canary.initial.json
run_dir=/tmp/zskills-codex-canary-direct.myvpcp/.zskills/logs/run-plan-direct-canary-20260430T024358Z
summary_file=/tmp/zskills-codex-canary-direct.myvpcp/.zskills/logs/run-plan-direct-canary-20260430T024358Z/chunk-001.summary.json
validation_result=passed
validated_tracking_id=20260430T024358Z
run_dir=/tmp/zskills-codex-canary-direct.myvpcp/.zskills/logs/run-plan-direct-canary-20260430T024358Z
summary_file=/tmp/zskills-codex-canary-direct.myvpcp/.zskills/logs/run-plan-direct-canary-20260430T024358Z/chunk-002.summary.json
validation_result=passed
validated_tracking_id=20260430T024358Z
runner_stop_reason=complete
## main
fc143b8 Complete direct canary phase 2
d786101 Run direct canary phase 1
3dbbd55 init
phase-0: seed
phase-1: alpha
phase-2: beta
```

Result: PASS

## Cherry-Pick Runner Canary

```text
repo=/tmp/zskills-codex-canary-cp.Q6yVHB
origin=/tmp/zskills-codex-canary-origin.Ui7uoY
codex_home=/home/vscode/.codex
mode=run-plan
repo=/tmp/zskills-codex-canary-cp.Q6yVHB
plan=plans/cherry-canary.md
plan_path=/tmp/zskills-codex-canary-cp.Q6yVHB/plans/cherry-canary.md
plan_slug=cherry-canary
pipeline_id=run-plan.cherry-canary
tracking_dir=/tmp/zskills-codex-canary-cp.Q6yVHB/.zskills/tracking/run-plan.cherry-canary
report_path=/tmp/zskills-codex-canary-cp.Q6yVHB/reports/plan-cherry-canary.md
plan_hash=e3d626a6197288f47e54502c6088a336ab56d039cc58780e1af8e48365eb577c
report_hash=<missing>
config=/tmp/zskills-codex-canary-cp.Q6yVHB/.codex/zskills-config.json
max_chunks=2
chunk_timeout_minutes=20
idle_timeout_minutes=8
log_dir=.zskills/logs
stop_marker=.zskills/stop
sandbox=danger-full-access
approval_policy=never
execution_landing=cherry-pick
allow_direct_unattended=false
codex_bin=codex
codex_argv=codex exec -C /tmp/zskills-codex-canary-cp.Q6yVHB --add-dir /tmp --sandbox danger-full-access -c approval_policy="never" -m gpt-5.4-mini run-plan plans/cherry-canary.md finish auto
plan_state=present
plan_done_count=0
plan_in_progress_count=0
plan_not_started_count=1
report_state=missing
tracking_state=missing
tracking_marker_count=0
initial_state_file=/tmp/zskills-runner-state/cherry-canary.initial.json
run_dir=/tmp/zskills-codex-canary-cp.Q6yVHB/.zskills/logs/run-plan-cherry-canary-20260430T024557Z
summary_file=/tmp/zskills-codex-canary-cp.Q6yVHB/.zskills/logs/run-plan-cherry-canary-20260430T024557Z/chunk-001.summary.json
validation_result=passed
validated_tracking_id=20260430T024557Z
runner_stop_reason=complete
## main...origin/main [ahead 1]
3076990 Add cherry-pick canary marker
557ec71 init
run-plan.cherry-canary/fulfilled.run-plan.20260430T024557Z
run-plan.cherry-canary/fulfilled.verify-changes.20260430T024557Z
run-plan.cherry-canary/requires.verify-changes.20260430T024557Z
run-plan.cherry-canary/step.run-plan.20260430T024557Z.implement
run-plan.cherry-canary/step.run-plan.20260430T024557Z.land
run-plan.cherry-canary/step.run-plan.20260430T024557Z.report
run-plan.cherry-canary/step.run-plan.20260430T024557Z.verify
run-plan.cherry-canary/step.verify-changes.20260430T024557Z.complete
run-plan.cherry-canary/step.verify-changes.20260430T024557Z.tests-run
```

Result: PASS

## Skill Coverage Table

```text
Skill coverage classification:
- add-block: static wrapper/reference coverage; full block app canary deferred to a real block-diagram repo.
- add-example: static wrapper/reference coverage; full block app canary deferred to a real block-diagram repo.
- briefing: covered by metadata/reference checks; real repo status behavior is low-risk read-only.
- commit: partially covered by direct/cherry canary commit behavior; standalone selective-commit canary still useful.
- do: covered by run-plan child execution path only indirectly; standalone bounded edit canary still useful.
- doc: covered by report/documentation update behavior in runner canaries.
- draft-plan: covered by this plan file creation; full adversarial-agent rounds not exercised by script.
- fix-issues: not yet fully canaried; needs local issue tracker fixture.
- fix-report: not yet fully canaried; needs completed fix-issues fixture.
- investigate: not yet fully canaried; needs seeded bug fixture.
- manual-testing: static wrapper/reference coverage; browser fixture canary deferred.
- model-design: static wrapper/reference coverage; full block-diagram repo deferred.
- plans: covered by plan status/progress parsing in runner canaries.
- playwright-cli: static wrapper/reference coverage; browser fixture canary deferred.
- qe-audit: not yet fully canaried; needs seeded regression fixture.
- refine-plan: not yet fully canaried; needs partially executed plan fixture.
- research-and-go: not fully canaried because it intentionally performs broad autonomous work.
- research-and-plan: partially covered by this canary plan shape; standalone local planning canary still useful.
- review-feedback: not yet fully canaried; needs product feedback JSON fixture.
- run-plan: covered by real direct and cherry-pick runner canaries plus fake runner suite.
- update-zskills: static wrapper/reference coverage; upstream update mutation canary deferred.
- verify-changes: covered by runner marker/report verification contract and package verification.
```

Result: PASS

