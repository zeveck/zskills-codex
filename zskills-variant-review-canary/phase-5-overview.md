# Phase 5 Overview

## Executive Summary

This canary review packet is ready for fresh zskills-dev diff review. It establishes a local evidence inventory, compares `zskills`, `zskills-cc`, `zskills-codex`, and `zskills-dev`, maps likely adoption surfaces, and provides a practical application plan for future dev changes.

The strongest local evidence is for `zskills-codex`, because this repository contains its Codex-native skills, support assets, plans, reports, runner guidance, and tracking conventions. `zskills-cc` and `zskills-dev` are not locally checked out, so their current behavior must be confirmed from the actual target trees before any import or adaptation work begins.

## What We Know

- `zskills-codex` should keep Codex-native behavior: normal git commands, explicit worktrees when needed, file-backed tracking markers, durable reports, and runner-backed chunking for `finish auto`.
- `zskills-cc` likely needs a split between host-neutral content and host-specific adapters, because dual-runtime behavior cannot safely assume one runtime's hooks, agents, scheduler, installer paths, or configuration defaults.
- `zskills` is locally represented through attribution and archived upstream references, not as a current checkout.
- `zskills-dev` is the future source of changes to review, but current dev facts are an evidence gap until a pinned diff is available.
- The Phase 4 plan gives the working model for applying changes: classify each hunk, decide whether it is shared or runtime-specific, apply low-risk shared material first, adapt execution mechanics per host, and verify reports, tests, markers, and installer behavior before release.

## What Needs Fresh Diff Review

- Which `zskills-dev` changes are skill text, frontmatter, support scripts, hooks, runner, tracking markers, config schema, tests, documentation, installer, reports, or runtime policy.
- Whether any `zskills-dev` change assumes Claude-only automation, Codex-only behavior, or a shared mechanism that `zskills-cc` must split.
- Whether marker names, report headings, progress tracker statuses, and handoff semantics remain parser-compatible.
- Whether support scripts and runner changes preserve direct, cherry-pick, PR, and `finish auto` behavior for the relevant host.
- Whether documentation claims are backed by the current `zskills-dev`, `zskills-cc`, and `zskills-codex` trees rather than inference.

Open questions for the future diff review:

- Does `zskills-dev` introduce new runtime primitives or only refine existing workflows?
- Does `zskills-cc` currently generate host-specific outputs from shared source, or maintain separate trees?
- Are any hook or runner changes intended as required automation, optional templates, or manual guardrails?
- Do config schema changes need migration notes for existing user installations?
- Which tests prove the shared contract across Claude Code and Codex rather than only one runtime?

## Recommended Next Steps

1. Pin the exact `zskills-dev` revision and collect the target `zskills-cc` and `zskills-codex` revisions.
2. Re-run the Phase 4 classification against the actual diff and record observed evidence separately from inference.
3. Directly import only host-neutral changes into `zskills-cc`; adapt anything involving hooks, runner behavior, tracking markers, installer paths, config schema, or runtime policy.
4. Adapt useful workflow changes into `zskills-codex` only when they preserve Codex-native behavior; reject or defer changes that require unavailable host primitives or lack enough evidence.
5. Verify with targeted tests, canary runs, report parsing, marker inspection, and installer or runner dry-runs before release.

## Canary Result

The review packet now contains all five planned files in manifest order and is ready for fresh zskills-dev diff review. The final packet should be used as a decision guide, not as a substitute for reviewing the actual `zskills-dev` diff.
