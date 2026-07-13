→ [Back to Delivery](../../README.en.md)

# Hack

---

## Overview

**What it's for:** It is the implementation phase of CI Sync. It transforms
OBC acceptance criteria and BDD scenarios into code verifiable by tests,
following the Red→Green→Yellow cycle, with evidence recorded in the Release Trail.

**How it works:**

```
Red (test fails for the right reason) → Green (minimum that passes)
→ Yellow (refactor + transversal validations) → Commit → Evidence
```

**When to use:** after Bootstrap has delivered a clean branch, a ready
environment, and a verified contract — and before Sync. Applies to Upstream
and Downstream. Hack starts directly in TDD; if the contract or acceptance
criterion is missing, return to Bootstrap.

**Position in the flow:**

```
CI Sync  →  Bootstrap → [Hack] → Sync → Finish
```

---

## Procedure

The executable Hack procedure is the skill — this README does not maintain a
second copy:

**→ [`prodops/skills/hack/SKILL.md`](../../../../skills/hack/SKILL.md)** (invocable via `/hack`)

| Step | Responsibility |
|---|---|
| [`start`](../../../../skills/hack/steps/start/SKILL.md) | Clean the stage, sync the base, and create the feature branch |
| [`tdd`](../../../../skills/hack/steps/tdd/SKILL.md) | Red → Green → Yellow cycle with artifact closure |
| [`commit`](../../../../skills/hack/steps/commit/SKILL.md) | Stage, diff review, and commit with Conventional Commit |

The steps are sequential. **Security, Quality, and Documentation validations
are not steps** — they are transversal and run in each cycle's Yellow Bar.
The canonical cycle-exit checklist (the minimum gates to commit) lives in
[quality-gates.en.md](quality-gates.en.md).

Repository quality gates (`lint`, `acceptance`, `no_mocks`), commit types, and
canonical paths: [`prodops/exec/manifest.yaml`](../../../../exec/manifest.yaml).
