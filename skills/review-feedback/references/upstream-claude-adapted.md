---
name: review-feedback
description: >-
  Z Skills workflow adapted for Codex: Review exported feedback JSON from the
  in-app feedback panel, evaluate each pending entry, and selectively file
  GitHub issues via gh CLI. Use when the user says "review feedback", "triage
  feedback", or "file feedback issues".
---

## Codex Adaptation Notes

This is a Codex adaptation of the upstream Z Skills workflow from `github.com/zeveck/zskills` at commit `14dea81da487b2904ea7d69a27295f1869206cdf`. The original text was written for Claude Code slash commands; in Codex, treat command examples such as `/run-plan` as references to the corresponding Codex skill name, for example `run-plan`.

Runtime mappings:
- Claude `Agent` or `Task` dispatch maps to Codex sub-agents only when the current Codex session exposes `spawn_agent`/`wait_agent`. If those tools are unavailable or the task is too tightly coupled, run the workflow inline and clearly state the reduced freshness or isolation.
- Claude cron tools such as `CronCreate`, `CronList`, and `CronDelete` have no guaranteed Codex equivalent. For scheduled modes, explain the requested schedule and either implement it with available local tools after explicit user approval or ask the user to re-run the skill manually.
- Claude `isolation: "worktree"` means create/use a git worktree explicitly with normal git commands when isolation is needed.
- Claude `.claude/*`, hooks, settings, and statusline files are upstream references. Codex does not run Claude hooks or read `.claude/settings.json`. Supporting upstream assets are bundled at `/home/vscode/.codex/zskills-support` for inspection or manual project adaptation.
- If a workflow references helper commands like `scripts/briefing.cjs`, prefer project-local scripts when present. Otherwise inspect the bundled upstream copy under `/home/vscode/.codex/zskills-support/scripts` and decide whether to run it from there or copy/adapt it into the current project.
- Keep Codex’s normal safety rules in force: do not revert unrelated work, do not run destructive git commands without an explicit user request, and verify using actual diffs/tests rather than memory.


# review-feedback — Review and triage user feedback

Review exported feedback JSON from the in-app feedback panel, evaluate each
pending entry, and selectively file GitHub issues.

## Trigger

User says: "review feedback", "triage feedback", "file feedback issues",
or invokes `review-feedback`.

## Input

The exported `feedback.json` file should be in the repo root (or the user
will specify the path). This file is exported from the app via
**Feedback Panel > History > Export JSON**.

## Workflow

1. **Read** the feedback JSON file:
   ```bash
   cat feedback.json
   ```
   Or run the summary helper first:
   ```bash
   node scripts/review-feedback.js feedback.json
   ```

2. **For each pending entry**, evaluate:
   - Is it a real, actionable bug or feature request?
   - Is it a duplicate of an existing GitHub issue? Check with:
     ```bash
     gh issue list --search "keyword" --state open
     ```
   - What label(s) should it get? (`bug`, `enhancement`, `ui`, `question`)

3. **Present a summary table** to the user showing your recommendations:
   | # | Title | Type | Severity | Recommendation | Reason |
   |---|-------|------|----------|----------------|--------|
   | 1 | ... | bug | high | File | Clear repro |
   | 2 | ... | feature | low | Dismiss | Too vague |

4. **Wait for user approval** before filing anything.

5. **File approved entries** as GitHub issues:
   ```bash
   gh issue create --title "Title here" --body "$(cat <<'EOF'
   **Type:** bug
   **Severity:** high
   **Reported:** 2026-03-11

   Description here.

   ### Context
   - Model: ModelName
   - Blocks: 12
   - Sim state: idle
   - Solver: ode45
   EOF
   )" --label "bug"
   ```

6. **Update the JSON file** with filed status and issue numbers:
   - Set `status: "filed"` and `githubIssue: "#NNN"` for filed entries
   - Set `status: "dismissed"` for dismissed entries
   - Write the updated JSON back to the file

7. **Tell the user** they can re-import the updated JSON in the app
   via the browser console:
   ```js
   // In browser console:
   const store = new (await import('./src/io/FeedbackStore.js')).FeedbackStore();
   store.importJSON(await (await fetch('feedback.json')).text());
   ```

## Label Mapping

| Feedback type | GitHub label |
|--------------|-------------|
| bug | `bug` |
| ui | `bug`, `ui` |
| feature | `enhancement` |
| question | `question` |

## Rules

- Never file issues without user approval
- Check for duplicates before filing
- Include the auto-captured context in the issue body
- One GitHub issue per feedback entry (don't merge entries)
- Critical severity bugs should be flagged prominently in the summary
