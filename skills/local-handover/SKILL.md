---
name: local-handover
description: Write phase summary to role-local handover file for continuity. Use when /local-handover is triggered after generator or evaluator completes a phase.
---

# Local Handover

Persist current phase status to local handover memory.

## Target Files

1. Producer role -> `handover/local/generator.md`
2. Auditor role -> `handover/local/evaluator.md`

## Required Content

1. Scope completed
2. Files changed
3. Validation evidence (commands and key results)
4. Tests run and outcomes
5. Known unresolved risks with impact and mitigation
6. Known blockers
7. Decision (`continue` | `block` | `escalate`)
8. Next recommended step

## Output Contract

Return exactly these sections:

1. Role
2. Target File
3. Summary Written
4. Validation Evidence
5. Unresolved Risks
6. Decision
7. Follow-up Actions
