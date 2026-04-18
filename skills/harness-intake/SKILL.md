---
name: harness-intake
description: Convert vague product or engineering requests into a constrained, testable implementation brief. Use when requirements are ambiguous, scope is unstable, or the user asks for a plan before coding.
---

# Harness Intake

Use this workflow to produce a deterministic implementation brief before execution.

## Output Contract

Return exactly these sections:

1. Objective
2. In Scope
3. Out of Scope
4. Constraints
5. Acceptance Criteria
6. Risks and Open Questions
7. Proposed Task Tree

## Workflow

1. Restate the requested outcome in one sentence.
2. Extract explicit constraints from user text and repository context.
3. Infer missing constraints conservatively and mark them as assumptions.
4. Define measurable acceptance criteria using observable behavior.
5. Identify non-obvious risks: integration, rollback, migration, and testability.
6. Produce a small task tree suitable for nested execution.

## Quality Gates

Before finalizing, check:

1. Every acceptance criterion is testable.
2. Scope boundaries are explicit.
3. Each risk has an owner or mitigation path.
4. The task tree has no step larger than one focused coding session.
