# Phase 4 Dev Implications

Research date: 2026-05-02. This analysis uses the source ledger, current evidence, and comparative analysis in `zskills-online-variant-report-canary/phase-1-source-ledger.md`, `zskills-online-variant-report-canary/phase-2-current-evidence.md`, and `zskills-online-variant-report-canary/phase-3-comparative-analysis.md`. GitHub evidence may change after the research date.

Evidence labels:

- Observed: directly visible in GitHub evidence or local files.
- Inferred: reasoned from observed evidence, but not directly stated by a source.
- Unknown: not visible from public unauthenticated evidence during this pass.

## zskills-dev Change Surfaces

Observed: `zskills-dev` is the development source for `zskills`, not the end-user install repository. Its README points end users to `https://github.com/zeveck/zskills`, warns that content may be pre-release, and describes release filtering. Inferred: downstream consumers should treat `zskills-dev` as an upstream intake queue whose changes require classification before they move to `zskills-cc` or `zskills-codex`.

| Change category | Evidence surface | zskills-cc implication | zskills-codex implication | Recommended disposition |
| --- | --- | --- | --- | --- |
| Skill prompt body updates | `skills/*/SKILL.md`, `.claude/skills/*/SKILL.md` | Adapt behind a client boundary if text mentions Claude-only tools, hooks, slash commands, or agents. | Adapt to Codex-native behavior when runtime instructions mention Claude-only mechanics. | Import directly only when client-neutral. |
| Skill frontmatter | Skill `SKILL.md` frontmatter | Preserve Claude output compatibility and map unsupported Codex fields deliberately. | Keep only fields supported by Codex skill loading. | Adapt or reject unsupported fields. |
| Hooks | `hooks/`, README install behavior | Keep Claude hooks in Claude output; convert only if a compatibility adapter exists. | Reject direct hook assumptions; use Codex runner/gate tracking instead. | Adapt or reject. |
| Runner behavior | `scripts/`, plans, runner contracts | Maintain generated dual-client runner text and client-specific execution paths. | Adapt to Codex-native `zskills-runner.sh`, top-level `codex exec`, and tracking markers. | Adapt. |
| Tracking markers | Plans, reports, `.zskills` conventions | Keep marker names stable across generated outputs while avoiding client leakage. | Preserve canonical `.zskills/tracking` contract for runner parsing. | Import directly for shared state names; adapt mechanics. |
| Installer behavior | README, install/update scripts | Generate separate Claude and Codex install instructions. | Adapt to `bash scripts/install.sh`, `$CODEX_HOME/skills/`, `$CODEX_HOME/zskills-support/`, and `.codex`. | Adapt. |
| Config schema | `config/`, `.claude/zskills-config.json`, release config | Map schema fields into compatibility outputs and document client-only fields. | Adapt to `.codex/zskills-config.json` and `zskills-support/config/zskills-config.schema.json`. | Adapt. |
| Tests | `tests/`, `.github/workflows/test.yml`, canary scripts | Add or update generation, drift, and fidelity tests. | Add or update shell canaries and report-quality checks. | Import concepts; adapt commands. |
| Reports | `reports/` and plan reports | Keep report format compatible with both clients and generated output checks. | Keep report headings and status lines stable for Codex runner parsing. | Import structure when neutral. |
| Release workflow | `RELEASING.md`, `ship-to-prod.yml`, tags | Defer unless the compatibility repository adopts the same release train. | Defer until the publication target is populated and release mechanics exist. | Defer. |
| Migration notes | README, plans, canaries | Translate into dual-client migration guidance. | Translate into Codex-only migration guidance. | Adapt. |
| Dev-only canaries | `plans/`, canary output, experimental branches | Reject from released output unless promoted by policy. | Reject or defer unless they validate this port directly. | Reject or defer. |

## Application Strategy for zskills-cc

Inferred: `zskills-cc` should optimize for preserving one source of truth while generating usable `.claude/skills` and `.codex/skills` outputs. A `zskills-dev` change is safe to import directly only when it is client-neutral and does not mention Claude-only hook behavior, Codex-only runner behavior, unsupported frontmatter, or repository-specific paths.

| zskills-dev change type | zskills-cc action | Rationale |
| --- | --- | --- |
| Wording-only skill improvements with no runtime assumptions | import directly | They improve both generated clients without changing behavior. |
| Shared plan/report schema language | import directly | Stable report and tracking vocabulary helps both outputs. |
| Claude-specific hooks or `.claude` config changes | adapt behind a client boundary | Claude output needs the behavior; Codex output needs adapter language or omission. |
| Codex-compatible runner concepts discovered in dev plans | adapt behind a client boundary | The compatibility repo should express client-specific execution without contaminating Claude output. |
| Unsupported or client-specific frontmatter | adapt behind a client boundary | Generated outputs need valid metadata per client. |
| Experimental dev-only skills or canaries | defer | README evidence says development content can be pre-release. |
| Release-only scripts for publishing `zskills` | defer | `zskills-cc` has a different distribution strategy and tags. |
| Claude-only tool assumptions with no adapter path | reject | Direct import would create broken Codex instructions. |
| Generated output drift fixes | import directly | They protect the compatibility conversion contract. |
| Evidence claims about repository state | defer until refreshed | GitHub evidence may be stale after the research date. |

The key rule for `zskills-cc` is to adapt behind a client boundary whenever behavior depends on Claude versus Codex. Direct import is for text, workflow concepts, tests, or report structures that are demonstrably client-neutral.

## Application Strategy for zskills-codex

Inferred: this `zskills-codex` implementation should optimize for native Codex behavior rather than preserving Claude compatibility. Changes from `zskills-dev` should be reviewed for useful workflow intent, then rewritten to match Codex tools, `$CODEX_HOME`, `.codex/zskills-config.json`, `.zskills/tracking`, and the local support scripts.

| zskills-dev change type | zskills-codex action | Rationale |
| --- | --- | --- |
| Client-neutral skill reasoning or acceptance criteria | import directly | Workflow quality can transfer without runtime changes. |
| Report heading and runner parsing conventions | import directly | Stable reports improve unattended chunking and canary checks. |
| Claude hook installation, hook registration, or `.claude` paths | adapt to Codex-native behavior | Codex does not run Claude hooks and uses `.codex` project config. |
| Slash-command-only instructions | adapt to Codex-native behavior | Codex skills are invoked by natural language and local instructions, not Claude slash commands. |
| Agent/delegation instructions tied to Claude tools | adapt to Codex-native behavior | Codex uses sub-agents only under its own tool and policy constraints. |
| Unsupported frontmatter or metadata | reject | Invalid skill metadata can make installation or loading unreliable. |
| Development-only release machinery | defer | This repository has an empty publication target and needs its own release process first. |
| Compatibility generation overlays from `zskills-cc` | defer | A Codex-only port should not add a dual-client generation pipeline without a product decision. |
| Test concepts that validate behavior | import directly or adapt | The command surface differs, but the risk being tested may transfer. |
| Claims based on current GitHub state | defer until refreshed | Repository state can change and should not be frozen into product docs without a refresh. |

The key rule for `zskills-codex` is to adapt to Codex-native behavior whenever `zskills-dev` describes hooks, runner state, installer paths, config schema paths, or client-specific runtime assumptions. Direct import should be reserved for durable workflow intent, evidence standards, and client-neutral skill content.

## Direct Import vs Adapt vs Reject vs Defer

| Decision | Use for zskills-cc when | Use for zskills-codex when | Required evidence |
| --- | --- | --- | --- |
| import directly | The change is client-neutral, generation-safe, and valid in both `.claude/skills` and `.codex/skills`. | The change is Codex-valid as written and does not depend on Claude hooks, `.claude`, or slash-command mechanics. | Source diff, generated-output check for `zskills-cc`, local canary or focused review for `zskills-codex`. |
| adapt behind a client boundary | The behavior is useful but must differ between Claude and Codex outputs. | Not usually applicable as a product strategy, except when documenting external compatibility differences. | Explicit mapping of source behavior to each generated client output. |
| adapt to Codex-native behavior | The Codex generated output needs rewritten runner, tracking, installer, or config language. | The workflow intent is good but must use Codex tools, support scripts, `.codex` config, and local reports. | Local path references and passing Codex verification commands. |
| reject | The change is invalid for one client and no boundary or adapter can preserve correctness. | The change depends on unavailable Claude-only automation or unsupported frontmatter. | Rejection note with source URL or local path and the broken assumption. |
| defer | The change is experimental, release-only, or based on stale GitHub evidence. | The change depends on publication, release timing, or unverified generated output drift. | Follow-up issue, plan, or report entry with refresh criteria. |

This matrix should be applied before merging any `zskills-dev` migration into `zskills-cc` or `zskills-codex`. It keeps public `zskills` release behavior, compatibility conversion behavior, and Codex-only behavior from collapsing into one ambiguous runtime model.

## Verification Strategy

For `zskills-cc`, run checks that prove both generated clients remain valid and that generated output drift is intentional:

```bash
git status --short
bash tests/run-all.sh
python3 .codex/skills/verify-zskills-codex.py
git diff -- .claude/skills .codex/skills codex-overlays local-patches templates scripts tests reports plans
```

If exact script names differ in the repository, use the closest repository-local tests first and record the access gap. Verification should confirm that Codex adapter text appears only in Codex output, Claude output remains Claude-native, frontmatter is valid for each client, and reports identify any generated output drift.

For this local `zskills-codex` repository, run checks that prove Codex-native behavior still works and that report artifacts remain parseable:

```bash
git status --short
bash scripts/canary-zskills-codex.sh
bash scripts/test-simple-run-plan-canary.sh
bash scripts/test-zskills-variant-review-canary.sh
bash scripts/test-zskills-online-variant-report-canary.sh
bash zskills-support/scripts/zskills-gate.sh --help
```

For this Phase 4 canary chunk, the required focused verification command is:

```bash
bash scripts/test-zskills-online-variant-report-canary.sh
```

Observed local constraint: this checkout has no configured `origin` remote even though `.codex/zskills-config.json` names `origin`. Remote freshness checks should either configure the intended remote before release work or record the access gap in reports.

## Release Recommendations

- Treat `zskills` as the public release baseline and `zskills-dev` as the candidate source, not as a drop-in dependency.
- For `zskills-cc`, maintain explicit client boundaries, run generated-output drift checks, and require proof that Claude and Codex outputs each keep valid runtime assumptions.
- For `zskills-codex`, preserve workflow intent but rewrite runtime mechanics into Codex-native instructions, support scripts, installer behavior, tracking markers, reports, and config schema paths.
- Do not publish claims that `https://github.com/zeveck/zskills-codex` is populated until a refreshed GitHub check confirms content exists there.
- Before release migration, refresh GitHub evidence for all four repositories and record branch, commit, tag, README, tests, reports, and release workflow state.
- Defer release automation imported from `zskills-dev` until release timing and publication ownership for `zskills-cc` and `zskills-codex` are explicit.

Risk notes:

- Stale GitHub evidence: repository descriptions, README content, branches, tags, and commits may change after 2026-05-02.
- publication state: `https://github.com/zeveck/zskills-codex` appeared empty or unpopulated during Phase 2, so consumers cannot yet audit the intended remote implementation.
- Client-specific runtime assumptions: hooks, runner behavior, tracking files, installer paths, frontmatter, config schema, and slash-command language can break when copied across Claude, dual-client, and Codex-only variants.
- Generated output drift: `zskills-cc` must prove generated `.claude/skills` and `.codex/skills` match intended source, overlays, and local patches.
- Release timing: `zskills-dev` can move faster than public `zskills`, compatibility `zskills-cc`, or local `zskills-codex`, so migration should happen through reviewed batches with tests and reports.
