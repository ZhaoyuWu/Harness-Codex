---
name: pr-description
description: Generate a standalone PR description from workflow state, evidence, and handover artifacts. Use before opening a pull request or updating its summary.
---

# PR Description

Create reviewer-facing PR text separate from handover documentation.

## Workflow

1. Read workflow artifacts:
   1. `workflow/stories.json`
   2. `workflow/quality.json`
   3. `workflow/policy.json`
2. Read handover artifacts:
   1. `handover/local/generator.md`
   2. `handover/local/evaluator.md`
   3. `handover/public.md`
3. Produce PR description sections focused on:
   1. changes
   2. validation evidence
   3. risks
   4. blockers and rollback

## Output Contract

Return exactly these sections:

1. Summary
2. What Changed
3. Why
4. Validation
5. Risks
6. Required Fixes Before Merge
7. Rollback
