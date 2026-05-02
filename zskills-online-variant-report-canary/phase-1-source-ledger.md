# Phase 1 Source Ledger

## Research Date

Research for this canary is anchored on 2026-05-02. Later phases must refresh current GitHub evidence if repository state changes after this date.

## Target Repositories

| Repository | Role to verify |
| --- | --- |
| https://github.com/zeveck/zskills | Public release repository for Z Skills. |
| https://github.com/zeveck/zskills-dev | Development repository whose current deltas must be compared against downstream variants. |
| https://github.com/zeveck/zskills-cc | Claude/Codex compatibility conversion repository. |
| https://github.com/zeveck/zskills-codex | Publication target for this Codex implementation. |

`zskills-codex` means this local implementation, while `https://github.com/zeveck/zskills-codex` is the publication target whose current remote state should be recorded as deployment context. For validation tooling, zskills-codex means this local implementation and the GitHub repository URL means publication context.

## Required Evidence Types

- GitHub repository README evidence for each visible repository.
- GitHub commit, branch, tag, and directory evidence where public pages or raw files expose it.
- Local file path evidence for this implementation, including skills, support scripts, plans, reports, configuration, and tests.
- Evidence labels for every material claim: `Observed`, `Inferred`, or `Unknown`.

## Citation Rules

Every material claim in the final report must be traceable to a GitHub URL, local file path, or clearly labeled inference. Stated another way, every material claim in the final report must be traceable before it is promoted from evidence to analysis. Prefer direct GitHub URLs to README, tree, blob, release, tag, workflow, script, and test pages when available. Use local paths only for claims about this working tree.

## Evidence Gaps

If GitHub pages, raw files, commit metadata, tags, or repository contents are unavailable, later phases must record the access limit instead of inventing facts. Unknowns should remain explicit until source evidence supports an observed or inferred conclusion.
