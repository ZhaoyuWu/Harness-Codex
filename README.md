# Harness Engineering Skills

This repository provides a two-agent workflow for small engineering tasks under one parent task:

1. Generator (producer)
2. Evaluator (auditor)

## Install

Install this repository as a Codex plugin package (manifest at `.codex-plugin/plugin.json`).

## Slash Command Installer

Install markdown slash commands into `.claude/commands`:

1. `node promptm.js install .`
2. Check available templates: `node promptm.js templates`
3. View one template: `node promptm.js show generator`

## Command Mapping

Use skill mentions directly or map slash aliases to them.

1. `/generator` -> `$generator`
2. `/evaluator` -> `$evaluator`
3. `/read-handover` -> `$read-handover`
4. `/read-task` -> `$read-task`
5. `/local-handover` -> `$local-handover`
6. `/public-handover` -> `$public-handover`
7. `/strategic-next` -> `$strategic-next`
8. `/verify-thorough` -> `$verify-thorough`

## Workflow

1. Define parent task in `handover/tasks/task.md`.
2. Fill branch tasks in `handover/tasks/generator.md` and `handover/tasks/evaluator.md`.
3. Define machine-readable stories in `workflow/stories.json`.
4. Get next ready story:
`powershell -File scripts/workflow-loop.ps1 -Action next`
5. In generator chat, run `/generator`, implement story, then run:
`powershell -File scripts/workflow-loop.ps1 -Action start -StoryId US-001`
6. Run shared quality gates:
`powershell -File scripts/workflow-loop.ps1 -Action run-quality -StoryId US-001 -Role generator`
7. In evaluator chat, run `/evaluator` and perform audits.
8. Record evaluator findings and evidence:
`powershell -File scripts/workflow-loop.ps1 -Action record-audit -StoryId US-001 -Severity P1 -Count 1 -Role evaluator`
`powershell -File scripts/workflow-loop.ps1 -Action record-evidence -StoryId US-001 -EvidenceKey principles-check -EvidenceValue "pass" -Role evaluator`
9. If audit passes, approve gate then pass:
`powershell -File scripts/workflow-loop.ps1 -Action approve-gate -StoryId US-001 -Role evaluator`
`powershell -File scripts/workflow-loop.ps1 -Action pass -StoryId US-001 -Reason "all checks passed" -Role orchestrator`
10. If audit fails (No-Go):
`powershell -File scripts/workflow-loop.ps1 -Action reject-gate -StoryId US-001 -Reason "P1 regression" -Role evaluator`
`powershell -File scripts/workflow-loop.ps1 -Action nogo -StoryId US-001 -Reason "P1 regression" -Role evaluator`
11. Write local handovers with `/local-handover`.
12. Run deep verification with `/verify-thorough` for high-risk stories.
13. When all stories pass, publish `/public-handover`.
14. Run governance check at any time:
`powershell -File scripts/workflow-loop.ps1 -Action governance-check -Role orchestrator`

## Stop Conditions

1. `COMPLETE`: all stories in `workflow/stories.json` have `passes: true`.
2. `BLOCKED`: iteration reaches `maxIterations`.
3. `BLOCKED`: consecutive No-Go reaches `consecutiveNoGoLimit`.

## Repository Conventions

1. Parent task: `handover/tasks/task.md`
2. Branch tasks: `handover/tasks/generator.md` and `handover/tasks/evaluator.md`
3. Local handovers: `handover/local/generator.md` and `handover/local/evaluator.md`
4. Shared summary: `handover/public.md`
5. Principles file: `standards/principles.md`
6. Story state machine: `workflow/stories.json`
7. Shared quality commands: `workflow/quality.json`
8. Governance policy: `workflow/policy.json`
9. Loop executor: `scripts/workflow-loop.ps1`
10. Slash templates: `templates/*.md`
11. Local installer CLI: `promptm.js`
12. CI gates: `.github/workflows/governance.yml`

Windows note: if script execution is blocked, use:
`powershell -ExecutionPolicy Bypass -File scripts/workflow-loop.ps1 -Action status`
