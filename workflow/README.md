# Workflow Files

## `stories.json`

Machine-readable story state.

Fields:

1. `taskId`: parent task id
2. `status`: `in_progress` | `complete` | `blocked`
3. `iteration`: completed loop count
4. `maxIterations`: stop condition
5. `consecutiveNoGo`: current No-Go streak
6. `consecutiveNoGoLimit`: stop condition
7. `governance`: policy and quality references
8. `stories[]`: ordered story list with dependencies and governance fields

Story status values:

1. `todo`
2. `in_progress`
3. `done`
4. `blocked`

Per-story governance fields:

1. `ownerRole`
2. `acceptance[]`
3. `requiredEvidence[]`
4. `evidence{}`
5. `gateStatus`: `pending` | `approved` | `rejected`
6. `findings`: `P0`/`P1`/`P2`
7. `quality`: required-check result snapshot

## `quality.json`

Shared quality gates executed by `scripts/workflow-loop.ps1 -Action run-quality`.

Top-level policy fields:

1. `coverageMin`
2. `forbidP0P1`
3. `allowBypass`
4. `requiredChecks[]`

Each command entry has:

1. `name`
2. `command`
3. `required` (if true, failure blocks progression)

## `policy.json`

Governance and permission policy executed by script guards.

Sections:

1. `roles`: role-to-action permissions
2. `constraints`: optional hard limits
3. `blockedActions`: explicitly forbidden actions
4. `gates`: required pass criteria
