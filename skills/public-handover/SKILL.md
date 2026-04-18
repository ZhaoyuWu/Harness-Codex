---
name: public-handover
description: Publish shared handover summary that merges generator and evaluator updates after audits pass. Use when /public-handover is triggered.
---

# Public Handover

Write final shared summary for team continuity.

## Inputs

1. `handover/local/generator.md`
2. `handover/local/evaluator.md`

## Output File

1. `handover/public.md`
2. `handover/session-<session-id>.md`
3. `handover/history/session-<session-id>.md`

## Rules

1. Precondition gate before writing:
   1. Security audit passed
   2. Functionality and tests audit passed
   3. Performance and principles audit passed
   4. No open `P0` or `P1` findings
2. If any precondition fails, do not publish and return `Blocked`.
3. Allocate the next session number in `session-0001` format.
4. Write numbered session handover to `handover/session-<session-id>.md`.
5. Write the same content to `handover/history/session-<session-id>.md`.
6. Update `handover/public.md` as latest index with session metadata.
7. Include both generator and evaluator changes.
8. Include accepted tests and audit outcomes.
9. Include unresolved risks, if any.
10. Include immediate next action owner.

## Output Contract

Return exactly these sections:

1. Source Files
2. Preconditions Check
3. Session ID
4. Output Files
5. Shared Summary
6. Final Status
7. Next Owner
