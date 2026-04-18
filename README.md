# Harness Engineering Skills

Harness Engineering Skills is a lightweight, governed AI workflow for personal projects and small teams.

It uses a two-branch model under one parent task:

1. `generator` branch: implement changes
2. `evaluator` branch: audit, test, and gate release decisions

The repository includes:

1. Skill definitions for Codex
2. Slash-command templates for `.claude/commands`
3. A machine-readable workflow state (`stories.json`)
4. Policy and quality gates
5. A PowerShell workflow loop with enforcement
6. CI governance checks
7. Story autopilot and task archive scripts
8. Standalone PR description generation (separate from handover)

## Quick Start

1. Clone this repository.
2. Install dependencies.
3. Install slash commands into your project.

```bash
npm install
node promptm.js install .
```

List templates:

```bash
node promptm.js templates
```

You now have a broader command pack (core workflow + audit/build/session helpers).

Show one template:

```bash
node promptm.js show generator
```

## CLI Installation Options

Use local CLI in this repository:

```bash
node promptm.js install .
```

Optional global install from this repo:

```bash
npm install -g .
harnessprompt install .
```

## Codex Plugin Install

Install as a Codex plugin package using:

`/.codex-plugin/plugin.json`

## Core Commands

Slash command to skill mapping:

1. `/generator` -> `$generator`
2. `/evaluator` -> `$evaluator`
3. `/read-handover` -> `$read-handover`
4. `/read-task` -> `$read-task`
5. `/local-handover` -> `$local-handover`
6. `/public-handover` -> `$public-handover`
7. `/strategic-next` -> `$strategic-next`
8. `/verify-thorough` -> `$verify-thorough`
9. `/pr-description` -> `$pr-description`

## Minimal Story Flow

1. Define parent and branch tasks:
   `handover/tasks/task.md`, `handover/tasks/generator.md`, `handover/tasks/evaluator.md`
2. Define stories in `workflow/stories.json`
3. Get next ready story:
   `powershell -File scripts/workflow-loop.ps1 -Action next -Role orchestrator`
4. Start implementation:
   `powershell -File scripts/workflow-loop.ps1 -Action start -StoryId US-001 -Role generator`
5. Run quality gates:
   `powershell -File scripts/workflow-loop.ps1 -Action run-quality -StoryId US-001 -Role generator`
6. Record evaluator audit findings and evidence:
   `powershell -File scripts/workflow-loop.ps1 -Action record-audit -StoryId US-001 -Severity P1 -Count 1 -Role evaluator`
   `powershell -File scripts/workflow-loop.ps1 -Action record-evidence -StoryId US-001 -EvidenceKey principles-check -EvidenceValue "pass" -Role evaluator`
7. Approve or reject gate:
   `powershell -File scripts/workflow-loop.ps1 -Action approve-gate -StoryId US-001 -Role evaluator`
   or
   `powershell -File scripts/workflow-loop.ps1 -Action reject-gate -StoryId US-001 -Reason "P1 regression" -Role evaluator`
8. Pass or No-Go:
   `powershell -File scripts/workflow-loop.ps1 -Action pass -StoryId US-001 -Reason "all checks passed" -Role orchestrator`
   or
   `powershell -File scripts/workflow-loop.ps1 -Action nogo -StoryId US-001 -Reason "P1 regression" -Role evaluator`
9. Run governance check:
   `powershell -File scripts/workflow-loop.ps1 -Action governance-check -Role orchestrator`

## Ralph-Like Automation Helpers

Autopilot next story (status + suggested checklist):

```bash
powershell -ExecutionPolicy Bypass -File scripts/story-autopilot.ps1
```

Autopilot and immediately start next story:

```bash
powershell -ExecutionPolicy Bypass -File scripts/story-autopilot.ps1 -StartNext
```

Archive task state snapshots (handover + workflow files):

```bash
powershell -ExecutionPolicy Bypass -File scripts/archive-task.ps1
```

## PR Description (Separated from Handover)

Handover is for session continuity. PR description is for reviewers.
They are intentionally separate in this workflow.

Generate PR description markdown from workflow + handover artifacts:

```bash
powershell -ExecutionPolicy Bypass -File scripts/generate-pr-description.ps1
```

Or use npm script:

```bash
npm run pr:generate
```

Default output:

`docs/pr/PR_DESCRIPTION.md`

Print to terminal only:

```bash
powershell -ExecutionPolicy Bypass -File scripts/generate-pr-description.ps1 -PrintOnly
```

## Workflow Stop Conditions

1. `COMPLETE`: all stories have `passes: true`
2. `BLOCKED`: `iteration >= maxIterations`
3. `BLOCKED`: `consecutiveNoGo >= consecutiveNoGoLimit`

## Governance and Quality

1. Story state: `workflow/stories.json`
2. Quality policy: `workflow/quality.json`
3. Governance policy: `workflow/policy.json`
4. Enforcement script: `scripts/workflow-loop.ps1`
5. CI gates: `.github/workflows/governance.yml`

## Repository Structure

1. Parent task: `handover/tasks/task.md`
2. Branch tasks: `handover/tasks/generator.md`, `handover/tasks/evaluator.md`
3. Local handovers: `handover/local/generator.md`, `handover/local/evaluator.md`
4. Public handover: `handover/public.md`
5. Principles: `standards/principles.md`
6. Slash templates: `templates/*.md`
7. Local CLI: `promptm.js`
8. Autopilot script: `scripts/story-autopilot.ps1`
9. Archive script: `scripts/archive-task.ps1`
10. PR generator script: `scripts/generate-pr-description.ps1`
11. PR template: `.github/PULL_REQUEST_TEMPLATE.md`

Windows note:
If script execution is blocked, run:

`powershell -ExecutionPolicy Bypass -File scripts/workflow-loop.ps1 -Action status -Role orchestrator`
