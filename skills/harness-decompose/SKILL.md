---
name: harness-decompose
description: Decompose a parent engineering goal into nested, ownership-based subtasks with dependencies and verification checkpoints. Use when work needs parallelization or hierarchical orchestration.
---

# Harness Decompose

Build a nested execution graph that is predictable and parallel-safe.

## Output Contract

Return exactly these sections:

1. Parent Goal
2. Decomposition Strategy
3. Task Tree (L0, L1, L2)
4. Dependency Map
5. Ownership Map
6. Verification Checkpoints
7. Escalation Rules

## Workflow

1. Define L0 as the user-visible objective.
2. Split into L1 domain tracks (for example API, data, frontend, QA).
3. Split each L1 node into L2 atomic tasks with single responsibility.
4. Mark each task as serial, parallel, or gated.
5. Assign an owner and a concrete done condition to each L2 task.
6. Add explicit verification checkpoints after each L1 branch.

## Quality Gates

Before finalizing, check:

1. No L2 task mixes multiple concerns.
2. All critical-path dependencies are explicit.
3. Every task has a done condition and evidence requirement.
4. Failure handling is defined for blocked critical tasks.
