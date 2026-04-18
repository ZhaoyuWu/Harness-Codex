---
name: harness-verify
description: Review implementation quality for bugs, regressions, missing tests, and release risk. Use after coding changes or when the user asks for a strict engineering review.
---

# Harness Verify

Run a high-signal engineering review with explicit severity.

## Output Contract

Return exactly these sections:

1. Verification Scope
2. Findings by Severity
3. Missing Test Coverage
4. Release Risk Summary
5. Required Fixes Before Merge
6. Optional Improvements

## Workflow

1. Identify changed behavior and impacted components.
2. Search for correctness, safety, and compatibility risks.
3. Validate tests cover happy path and edge cases.
4. Classify findings by severity with concrete impact.
5. Separate merge blockers from optional refactors.

## Quality Gates

Before finalizing, check:

1. Findings are evidence-based and reproducible.
2. Severity aligns with user impact.
3. Test gaps are specific and actionable.
4. Blockers are clearly separated from non-blockers.
