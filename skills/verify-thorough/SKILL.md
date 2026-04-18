---
name: verify-thorough
description: Perform a strict multi-layer falsification review with evidence, severity labels, and calibrated confidence. Use before passing a story or shipping risky changes.
---

# Verify Thorough

Run a deep verification sweep before pass/go decisions.

## Workflow

1. Surface assumptions and invariants.
2. Verify logic, context fit, and completeness.
3. Run empirical checks with executable evidence.
4. Run adversarial checks for abuse and failure modes.
5. Run meta-verification to identify blind spots.
6. Report findings with severity and confidence.

## Output Contract

Return exactly these sections:

1. Verification Target
2. Layer Results
3. Findings by Severity
4. Evidence
5. Cannot Verify
6. Confidence
