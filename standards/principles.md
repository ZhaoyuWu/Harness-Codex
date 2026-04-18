# Engineering Principles

Use these principles during evaluator audits.

## Severity Model

Use this severity model for findings:

1. `P0` critical: security breach risk, data loss, or system unavailability.
2. `P1` high: major functional failure or high-likelihood regression.
3. `P2` medium: non-critical correctness, maintainability, or performance issue.

Go or No-Go policy:

1. Any open `P0` or `P1` means `No-Go`.
2. `P2` findings may proceed only with tracked follow-up.

1. Correctness First
Ship behavior that matches requirements and avoids regressions.

2. Security by Default
Assume hostile input, protect secrets, validate boundaries, and avoid unsafe defaults.

3. Testability
Each behavior change must have tests or a clear reason why tests are not feasible.

4. Performance Budget Awareness
Avoid unnecessary allocations, repeated heavy calls, and N+1 patterns in critical paths.

5. Readability and Maintainability
Prefer clear naming, small cohesive functions, and minimal incidental complexity.

6. Observability
Critical paths must produce enough logging and error context for diagnosis.

7. Backward Compatibility
Document and guard breaking changes with migration or fallback steps.

8. Explicit Risk Communication
Unresolved risks must be documented with impact and mitigation.
