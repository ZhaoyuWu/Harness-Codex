---
name: read-handover
description: Read local and shared handover memory for continuity between generator and evaluator. Use when /read-handover is triggered.
---

# Read Handover

Load durable context from handover files.

## Files

1. `handover/local/generator.md`
2. `handover/local/evaluator.md`
3. `handover/public.md`

## Rules

1. Read all existing files in the list.
2. If a file is missing, mark it as not initialized.
3. Merge key decisions, open risks, and pending work into one summary.

## Output Contract

Return exactly these sections:

1. Files Read
2. Key Decisions
3. Open Risks
4. Pending Work
5. Continuity Notes
