---
name: strategic-next
description: Choose the highest-impact next story using readiness, dependencies, effort, and risk reduction. Use when deciding what to execute next in a multi-story task.
---

# Strategic Next

Determine the best next story before execution.

## Workflow

1. Read `workflow/stories.json` and identify ready stories.
2. Read `handover/public.md` and local handovers for current risk and context.
3. Score each ready story by:
   1. impact
   2. effort
   3. urgency
   4. risk reduction
4. Recommend one story and explain trade-offs.

## Output Contract

Return exactly these sections:

1. Candidate Stories
2. Scoring Matrix
3. Recommended Next Story
4. Trade-offs
5. Deferred Stories
