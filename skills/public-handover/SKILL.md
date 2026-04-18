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

## Rules

1. Precondition gate before writing:
   1. Security audit passed
   2. Functionality and tests audit passed
   3. Performance and principles audit passed
   4. No open `P0` or `P1` findings
2. If any precondition fails, do not publish and return `Blocked`.
3. Include both generator and evaluator changes.
4. Include accepted tests and audit outcomes.
5. Include unresolved risks, if any.
6. Include immediate next action owner.

## Output Contract

Return exactly these sections:

1. Source Files
2. Preconditions Check
3. Shared Summary
4. Final Status
5. Next Owner
