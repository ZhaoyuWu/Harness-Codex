---
name: harness-implement
description: Execute a single engineering task with strict scope control, code-change evidence, and self-checking. Use when coding work is approved and needs deterministic delivery.
---

# Harness Implement

Use this skill for one scoped implementation unit at a time.

## Output Contract

Return exactly these sections:

1. Task Intent
2. Files Changed
3. Implementation Notes
4. Verification Performed
5. Residual Risks
6. Next Atomic Task

## Workflow

1. Confirm scope and done condition.
2. Inspect only files required for the current task.
3. Implement minimal changes to satisfy acceptance criteria.
4. Run focused verification commands tied to the changed behavior.
5. Summarize evidence from test or lint output.
6. Record residual risks and handoff-ready next step.

## Quality Gates

Before finalizing, check:

1. No unrelated file edits are included.
2. Verification is relevant to the change.
3. Claims are backed by command evidence.
4. Remaining risks are explicit, not implied.
