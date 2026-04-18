---
name: read-task
description: Read parent task and role-specific branch task definitions from handover task files. Use when /read-task is triggered by generator or evaluator.
---

# Read Task

Read task assignment from the shared parent task and role branch task.

## Rules

1. Always read shared parent task file `handover/tasks/task.md`.
2. If current role is producer, also read `handover/tasks/generator.md`.
3. If current role is auditor, also read `handover/tasks/evaluator.md`.
4. If role is unknown, read both branch files and state ambiguity.
5. Validate that branch tasks align with parent task objective and constraints.
6. If files are missing, return a template to fill.

## Output Contract

Return exactly these sections:

1. Role Detection
2. Parent Task Context
3. Branch Task Context
4. Alignment Check
5. Missing Information
6. Suggested Next Step
