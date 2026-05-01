# Phase 4 Dev Change Application Plan

This plan describes how a future maintainer should apply `zskills-dev` changes to `zskills-cc` and `zskills-codex`. It is based on current local evidence in this repository and should be refreshed against the actual zskills-dev diff before execution.

## Intake Checklist

1. Capture the exact `zskills-dev` source revision, comparison base, and diff command used for review.
2. Record which variant trees are available locally: `zskills-dev`, `zskills-cc`, and `zskills-codex`.
3. Split the diff into skill text, frontmatter, support scripts, hooks, runner, tracking markers, config schema, tests, documentation, installer, reports, and runtime policy changes.
4. Identify whether each change is host-neutral, Claude-specific, Codex-specific, or dual-runtime.
5. Compare every behavior change with local `zskills-codex` evidence under `skills/`, `zskills-support/`, `plans/`, `reports/`, and runner tracking conventions.
6. For `zskills-cc`, confirm whether the target architecture has shared source plus generated host variants, or separately maintained Claude and Codex trees.
7. Define verification before editing, including canary plans, support script tests, installer dry-runs, and report parsing checks.
8. Preserve evidence labels: observed local evidence, direct upstream diff evidence, and inference must stay separate in review notes.

## Change Classification

| Change category | Typical files or signals | Importability | Review focus |
| --- | --- | --- | --- |
| skill text | `SKILL.md`, workflow prose, checklists, examples | Usually adaptable | Preserve useful workflow changes while keeping host-specific runtime rules explicit. |
| frontmatter | skill metadata, names, descriptions, trigger text | Conditional | Confirm both loaders accept the metadata shape before sharing it. |
| support scripts | shell helpers, gates, runner helpers, report writers | Conditional | Check path assumptions, process launch behavior, direct-mode safety, and shell portability. |
| hooks | pre-run, post-run, tracking, or validation hooks | Usually adapt | Treat Claude hooks and Codex manual guardrails as different runtime mechanisms. |
| runner | `finish auto`, chunk orchestration, lock handling, child command flags | Usually adapt | Confirm external runner behavior still uses durable reports and tracking markers. |
| tracking markers | `.zskills/tracking`, handoff files, fulfilled files, step files | Conditional | Preserve parser stability and provide migration guidance for renamed markers. |
| installer | install scripts, package manifests, target directories | Conditional | Route files to the correct host locations and avoid creating unsupported runtime state. |
| config schema | landing, testing, CI, dev server, branch, remote, scheduler fields | Conditional | Keep shared fields stable and document host-specific defaults or unsupported values. |
| tests | canaries, shell tests, fixtures, parser checks | Usually import then adapt | Run both shared tests and host-specific execution tests. |
| documentation | README, usage guides, reports, migration notes | Usually adaptable | Keep user-facing instructions accurate for the target runtime. |
| runtime policy | safety rules, agent delegation, approval model, git semantics | Usually adapt or reject | Do not copy behavior that depends on unavailable host primitives. |
| reports | report templates, status lines, progress tracker wording | Conditional | Keep parser-sensitive headings, `Status:` lines, and `✅ Done` tracker values stable. |

## Application Strategy for zskills-cc

`zskills-cc` should import directly when a `zskills-dev` change is host-neutral and does not depend on Claude-only or Codex-only runtime behavior. Good direct-import candidates include typo fixes, clearer acceptance criteria, host-neutral skill text, portable support scripts, documentation that names both runtimes accurately, and tests that assert shared file formats.

`zskills-cc` should adapt when the change touches execution mechanics. Runner launch commands, hooks, installer destinations, config schema defaults, tracking markers, and reports should go through a compatibility layer so Claude Code and Codex behavior can differ without changing the shared contract. If `zskills-cc` has generated outputs, update the shared source first, regenerate both runtime variants, and review generated diffs separately.

`zskills-cc` should avoid direct import when a change assumes a single runtime host. Examples include Claude task syntax, Codex sub-agent policy, `.claude/settings.json` requirements, `.codex` config defaults, shell wrappers that launch one CLI, or hooks that are active automation in one host but only manual guardrails in another. These changes should be split into shared intent plus host-specific adapters.

## Application Strategy for zskills-codex

`zskills-codex` should adapt a `zskills-dev` change when the underlying workflow improvement is useful but the implementation assumes Claude Code mechanics. The adaptation must preserve Codex-native behavior: normal git commands, explicit worktree creation, no Claude-only task syntax, no automatic Claude hooks, no new `.claude` runtime dependency, file-backed tracking markers, durable reports, and runner-backed chunking for `finish auto`.

`zskills-codex` should reject a change when it requires unavailable host primitives or weakens local safety rules. Reject changes that require implicit background scheduling, destructive git defaults, untracked report artifacts, automatic hook execution that Codex cannot guarantee, or broad source rewrites outside a phase's allowed scope.

`zskills-codex` should defer a change when the local evidence is insufficient. Defer changes that depend on the current shape of `zskills-dev`, `zskills-cc`, or upstream `zskills` unless the actual diff, target tree, tests, and migration impact are available. Deferred items should land as explicit review notes rather than hidden assumptions.

## Compatibility Gates

- Frontmatter gate: validate skill metadata against each target loader before changing names, descriptions, or trigger fields.
- Support scripts gate: run shell checks and focused behavior tests for changed scripts, including direct, cherry-pick, and PR path handling where relevant.
- Hooks gate: classify each hook as active automation, optional template, or manual guardrail for each runtime.
- Runner gate: prove chunked `finish auto` writes reports, canonical markers, handoff files, and lock state in the expected locations.
- Tracking markers gate: verify marker names, tracking directories, and parser-sensitive status files remain backward-compatible or have a documented migration.
- Config schema gate: validate lookup order, defaults, unsupported fields, and host-specific overrides.
- Reports gate: verify report headings, `Status:` lines, tests run, verification result, landing result, remaining phases, and scope assessment stay parseable.
- Installer gate: dry-run install paths and confirm `zskills-codex` does not create unsupported `.claude` runtime files.

## Verification Matrix

| Change category | Codex verification | CC verification |
| --- | --- | --- |
| skill text | Read the target `SKILL.md`, run affected canary workflows, and confirm Codex runtime rules still override upstream Claude assumptions. | Generate or inspect both host variants and verify shared text did not erase host-specific policy. |
| frontmatter | Load or lint Codex skill metadata and confirm trigger discovery still works. | Validate both Claude and Codex metadata outputs, splitting fields that one host rejects. |
| support scripts | Run focused shell tests plus the relevant canary script from the repository root. | Run shared script tests, then host-wrapper tests for both runtimes. |
| hooks | Confirm Codex docs and reports describe hooks as templates or guardrails unless supported automation exists. | Test Claude hook installation separately from Codex fallback behavior. |
| runner | Execute or dry-run one chunk with canonical tracking markers and report updates. | Run equivalent chunk orchestration for both hosts, checking lock and handoff compatibility. |
| tracking markers | Inspect `.zskills/tracking/<pipeline-id>/` outputs and parser behavior after a phase. | Verify both hosts write and read the same durable marker contract or a documented adapter. |
| installer | Run installer dry-runs into a temporary home and inspect installed paths. | Run dual-host install tests and confirm no host receives the wrong config or hook files. |
| config schema | Validate `.codex/zskills-config.json`, root config, and legacy fallback behavior. | Validate shared schema plus host-specific defaults and unsupported-field handling. |
| tests | Run changed test scripts and any plan-specific verification commands. | Run shared tests once and host-specific tests for generated or adapted outputs. |
| documentation | Check commands, paths, and claims against local Codex files. | Check docs describe both runtimes without implying one host's automation exists in the other. |
| runtime policy | Review safety, git, agent, scheduler, and approval assumptions against Codex rules. | Review runtime policy sections for clear shared intent and host-specific implementation. |
| reports | Run a plan/report parser or canary verification script and inspect final report text. | Verify both hosts can produce parser-stable reports and progress tracker rows. |

## Staged Rollout Strategy

1. Baseline: record current tests, canary outputs, report parser expectations, and known evidence gaps before applying the `zskills-dev` diff.
2. Classify: label every changed hunk by category, runtime specificity, direct-import eligibility, and required verification.
3. Apply shared changes: land host-neutral prose, tests, and support logic first, with minimal behavior changes.
4. Adapt runtime changes: implement `zskills-codex` and `zskills-cc` host-specific wrappers, runner behavior, hooks handling, tracking markers, and config schema updates.
5. Verify progressively: run narrow tests after each group, then full canaries and report checks for the affected workflows.
6. Document drift: update release notes or review reports with imported, adapted, rejected, and deferred changes.
7. Release gate: require clean git state, committed reports, passing tests, and explicit open risks before publishing or handing off.

## Risk Review

- cross-runtime assumptions: a `zskills-dev` improvement may be correct for one host but unsafe for another if it assumes Claude tasks, Codex agents, automatic hooks, local scheduler behavior, or CLI-specific flags.
- marker compatibility: renamed tracking markers, moved tracking directories, or changed handoff semantics can break runner continuation even when source tests pass.
- stale reports: old reports may claim verification for workflows that changed after the report was written; refresh report evidence whenever runner, tests, or landing behavior changes.
- upstream drift: `zskills-dev` can move between intake and application, so pin the diff and re-check before release.
- Config ambiguity: shared config schema fields can carry different meanings if defaults are not documented per runtime.
- Installer bleed: a dual-runtime installer can accidentally write hooks, skills, or config into the wrong host directory.

## Release Readiness

Release readiness requires more than a clean diff. The maintainer should have a pinned `zskills-dev` diff, a completed classification table, applied or deferred decisions for `zskills-cc` and `zskills-codex`, passing tests, updated reports, and a clear list of residual risks.

For `zskills-codex`, readiness means the port still behaves as a Codex-native workflow after the changes. For `zskills-cc`, readiness means shared changes remain portable and each host-specific path has been verified independently. Any unresolved evidence gap should block release or be documented as an explicit deferred follow-up.
