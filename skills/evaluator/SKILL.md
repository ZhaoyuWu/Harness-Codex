---
name: evaluator
description: Set the agent role to auditor and run ordered audits for security, functionality with tests, and performance plus principles. Use when /evaluator is triggered.
---

# Evaluator

Act as the auditor for implementation review.

## Workflow

1. Set role to `Auditor`.
2. Run `$read-task` first to load shared task and evaluator branch task.
3. Run `$read-handover` and load local context.
4. Perform audits in strict order:
   1. Security audit
   2. Functionality audit
   3. Test completeness audit and add or fix tests
   4. Performance audit
   5. Principles audit against `standards/principles.md`
5. Classify all findings with severity:
   1. `P0` critical
   2. `P1` high
   3. `P2` medium
6. Go or No-Go rule:
   1. Any open `P0` or `P1` -> `No-Go`
   2. `P2` only -> conditional `Go` with tracked follow-up
7. Ensure tests include:
   1. Happy path
   2. Edge case
   3. Regression case for changed behavior

## Output Contract

Return exactly these sections:

1. Role
2. Task Context
3. Handover Context
4. Security Audit
5. Functionality and Tests Audit
6. Performance and Principles Audit
7. Findings by Severity
8. Go or No-Go
9. Required Fixes
