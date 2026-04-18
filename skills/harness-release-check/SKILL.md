---
name: harness-release-check
description: Execute pre-release readiness checks for config, migrations, observability, rollback, and operational safety. Use before merge, deployment, or handoff to operations.
---

# Harness Release Check

Use this workflow before shipping changes to shared environments.

## Output Contract

Return exactly these sections:

1. Release Candidate Summary
2. Preflight Checklist
3. Migration and Data Risk
4. Observability and Alerting
5. Rollback Readiness
6. Go or No-Go Decision
7. Immediate Next Actions

## Workflow

1. Confirm build and dependency integrity.
2. Validate environment configuration and secret assumptions.
3. Review migrations for backward compatibility and rollback path.
4. Verify logs, metrics, and alerts for new or changed behavior.
5. Document release gates and make a clear go or no-go call.

## Quality Gates

Before finalizing, check:

1. Every checklist item has a status.
2. Any no-go reason is tied to concrete risk.
3. Rollback path is operationally actionable.
4. Next actions are ordered by urgency.
