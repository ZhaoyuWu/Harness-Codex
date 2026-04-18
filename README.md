# Harness Engineering Skills

This repository provides a two-agent workflow for small engineering tasks under one parent task:

1. Generator (producer)
2. Evaluator (auditor)

## Install

Install this repository as a Codex plugin package (manifest at `.codex-plugin/plugin.json`).

## Command Mapping

Use skill mentions directly or map slash aliases to them.

1. `/generator` -> `$generator`
2. `/evaluator` -> `$evaluator`
3. `/read-handover` -> `$read-handover`
4. `/read-task` -> `$read-task`
5. `/local-handover` -> `$local-handover`
6. `/public-handover` -> `$public-handover`

## Workflow

1. Define parent task in `handover/tasks/task.md`.
2. Fill branch tasks in `handover/tasks/generator.md` and `handover/tasks/evaluator.md`.
3. In generator chat, run `/generator`.
4. Generator step: pull latest remote.
5. Generator step: read task first with `/read-task`.
6. Generator step: freeze scope (DoD, out-of-scope, constraints).
7. Generator step: read prior handover with `/read-handover`.
8. After generator phase, run `/local-handover`.
9. In evaluator chat, run `/evaluator`.
10. Evaluator step: read task first with `/read-task`.
11. Evaluator step: read local/public handover with `/read-handover`.
12. Evaluator step: audit in order security -> functionality and tests -> performance and principles.
13. Evaluator step: apply severity labels `P0/P1/P2`.
14. Evaluator step: `No-Go` if any open `P0` or `P1`.
15. After evaluator phase, run `/local-handover`.
16. Only when all audits pass, run `/public-handover`.

## Repository Conventions

1. Parent task: `handover/tasks/task.md`
2. Branch tasks: `handover/tasks/generator.md` and `handover/tasks/evaluator.md`
3. Local handovers: `handover/local/generator.md` and `handover/local/evaluator.md`
4. Shared summary: `handover/public.md`
5. Principles file: `standards/principles.md`
