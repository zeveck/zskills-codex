# ZSkills Codex

> Compatibility preview. This repository is a Codex-only port of
> `github.com/zeveck/zskills` at upstream commit
> `14dea81da487b2904ea7d69a27295f1869206cdf`.
>
> For the canonical Claude Code release, use upstream ZSkills. This repository
> is for testing and developing the Codex conversion.

This repo preserves the original ZSkills workflow intent while replacing
Claude-specific runtime mechanics with Codex-native behavior. It does not try to
be a dual Claude/Codex distribution; for that shape, compare
`github.com/zeveck/zskills-cc`.

## What This Provides

- Codex-compatible skill wrappers under `skills/`.
- Archived upstream Claude-oriented references beside each skill.
- Shared Codex-native support assets under `zskills-support/`.
- A bounded external runner for unattended `run-plan finish auto` based on
  fresh `codex exec` invocations.
- Validation canaries for tracking markers, landing gates, runner chunking,
  timeouts, dirty state, stale worktrees, and failure injection.

## Skill Set

This distribution installs 22 skills by default:

- 18 upstream core ZSkills workflows.
- `playwright-cli`, carried from upstream `.claude/skills`.
- 3 upstream block-diagram skills: `add-block`, `add-example`, and
  `model-design`.

The development-only `zskills-codex` reference skill is intentionally not part
of the default installable `skills/` tree. Its useful content lives in
`zskills-support/docs/CODEX_PORT.md`.

## Install

Install into a project checkout:

```bash
bash scripts/install.sh
```

This mirrors upstream ZSkills' project-local install model. The default install
copies the active Codex skill set and support assets into the current git repo:

```text
.agents/skills/
.agents/zskills-support/
.agents/zskills-config.json
```

Codex's documented repository skill discovery scans `.agents/skills` from the
current working directory up to the repository root, so this is the active
repo-local skill location rather than a staging directory.

This repository also checks in the generated `.agents/` install tree so a fresh
clone is immediately discoverable by Codex. Re-run `bash scripts/install.sh`
after changing source `skills/` or `zskills-support/` files.

Use `--project <path>` to install into a different repo. Existing
`.agents/zskills-config.json` files are preserved.

Use an explicit global install only when you want user-level skills under
`$CODEX_HOME`:

```bash
bash scripts/install.sh --global
bash scripts/install.sh --codex-home "$HOME/.codex"
```

Global install copies files into:

```text
$CODEX_HOME/skills/
$CODEX_HOME/zskills-support/
```

Both install modes replace this distribution's own skill directories and support
directory at the target, while preserving unrelated existing skill directories.
Project repos may also contain normal runtime artifacts created by workflows,
such as:

- `reports/plan-*.md`
- `.agents/zskills-config.json`
- ignored `.zskills/` tracking and log state

During install, bundled references to the original development Codex home are
rewritten to the selected target root, so project-local and custom Codex home
paths are supported.

## Runtime Policy

This port intentionally does not install Claude Code hooks, `.claude` runtime
settings, or Claude cron tools. Active Codex workflows use normal git commands,
manual worktrees, explicit config checks, and file-backed tracking gates.

Config lookup order:

1. project `.agents/zskills-config.json`
2. project `zskills-config.json`
3. legacy `.codex/zskills-config.json`, only if already present
4. legacy `.claude/zskills-config.json`, only if already present

Landing modes preserved from ZSkills:

- `direct`
- `cherry-pick`
- `pr` / locked-main PR

## `run-plan finish auto`

Interactive `run-plan <plan> finish` still executes one substantive phase and
stops with a durable handoff.

Unattended `finish auto` is runner-backed:

```bash
.agents/zskills-support/scripts/zskills-runner.sh \
  run-plan <plan> finish auto \
  --repo <repo>
```

The runner:

- launches a fresh top-level `codex exec` process per chunk;
- never uses `codex exec resume`;
- refuses dangerous bypass defaults;
- refuses direct unattended mode unless explicitly enabled;
- validates progress from plan/report hashes and `.zskills/tracking/` markers;
- runs ZSkills gates and post-run invariants;
- stops on no progress, missing handoff/report/verifier evidence, dirty
  artifacts, stale worktree residue, unsafe git state, child failure, max
  chunks, timeout, or idle timeout.

`runner.sandbox` defaults to `workspace-write`. Some containers do not permit
the bubblewrap/user-namespace sandbox used by Codex for that mode; in an
externally isolated canary environment, pass `--sandbox danger-full-access` or
set `runner.sandbox` accordingly.

## Verify

Run the core checks:

```bash
for f in zskills-support/scripts/{zskills-runner.sh,zskills-gate.sh,post-run-invariants.sh,land-phase.sh,worktree-add-safe.sh,clear-tracking.sh}; do
  bash -n "$f" || exit 1
done

python3 -m json.tool zskills-support/config/zskills-config.schema.json >/dev/null

zskills-support/tests/runner/run.sh all
zskills-support/tests/runner/run.sh fake-timeout
zskills-support/tests/runner/run.sh fake-idle-timeout
```

## Provenance

Upstream source: `github.com/zeveck/zskills`

Upstream tag: `2026.04.0`

Upstream commit: `14dea81da487b2904ea7d69a27295f1869206cdf`

Suggested preview tag for this repo:

```text
2026.04.0-codex.0
```
