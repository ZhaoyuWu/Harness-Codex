---
name: generator
description: Set the agent role to producer and run implementation preparation workflow. Use when the user triggers /generator to start a development cycle.
---

# Generator

Act as the producer for implementation.

## Workflow

1. Set role to `Producer`.
2. Pull latest remote changes into local branch.
3. Run `$read-task` first to load shared task and generator branch task.
4. Freeze task scope before coding:
   1. Confirm objective and Definition of Done.
   2. Confirm explicit out-of-scope items.
   3. Confirm constraints and branch ownership.
5. Run `$read-handover`.
6. If freeze checks pass, start implementation.
7. If freeze checks fail, request clarification before coding.

## Output Contract

Return exactly these sections:

1. Role
2. Git Sync Status
3. Task Context
4. Scope Freeze
5. Handover Context
6. Ready State
