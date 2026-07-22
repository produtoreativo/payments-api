→ [Back to Delivery](../../README.md)

# Sync

---

## Overview

**What it's for:** Consistency checkpoint between Hack and Finish. Sync covers **two distinct and complementary integrities**:

- **Repository integrity** (`rebase`) — make the repository ready for merge by incorporating the latest base state into the feature branch without conflicts.
- **ProdOps artifact integrity** (`align`) — ensure the canonical artifacts in `prodops/` faithfully reflect what was implemented.

These two integrities are pre-conditions for Finish: Finish cannot open a reliable PR over a divergent repository or over artifacts inconsistent with the diff.

**How it works:**

```
sync rebase: Remote fetch → Update base (fast-forward) → Integrate into feature
              → Resolve conflicts (both sides) → Preserve TDD → Validate → Clean branch
              [repository integrity]

sync align:  Review diff (main...HEAD) → List what changed
              → Identify the canonical artifact for each change
              → Update only inconsistent artifacts → Release Trail when meaningful
              [ProdOps artifact integrity]
```

The two steps are independent — they can be executed in whichever order makes sense, or individually as needed. `rebase` is **git work**; `align` is **traceability work**. One does not replace the other.

**Main guardrails:**

- Never discard local work or rewrite shared history
- Do not weaken tests to make the sync pass
- Conflicts are inspected from both sides before any editing
- Do not rewrite product decisions during artifact alignment work — align the artifact to the code, not the other way around

**Position in the flow:**

```
CI Sync  →  Bootstrap → Hack → [Sync] → Finish
                                   ├── rebase  (repository integrity)
                                   └── align   (ProdOps artifact integrity)
```

---

## What Sync does (and does not)

Sync has a precise boundary. Mixing responsibilities with Hack and Finish produces workarounds that mask divergences.

### Is Sync's responsibility

| Step | What it guarantees |
|---|---|
| `rebase` | Clean working tree, up-to-date base, feature branch integrated with the base, tests passing on the integrated history, no assertion removed to resolve a conflict. |
| `align` | No ProdOps artifact (BDD, Event Storming, architecture, OBC) is inconsistent with the branch diff; Release Trail records the alignment when meaningful. |

### **Not** Sync's responsibility

- **Sync does not validate code quality gates.** Lint, formatting, and behavioral tests belong to Hack (Yellow Bar) and Finish. `rebase` runs tests/lint only to verify that the **integration** did not break the previously green history — not to add coverage or fix inherited code smells.
- **Sync does not open a PR.** Opening the pull request, describing the change, and triggering review is Finish.
- **Sync does not run the full pipeline.** Ship runs the async pipeline on environments; Sync runs only the minimal local post-integration validation.
- **Sync does not rewrite product decisions.** If the diff diverges from an upstream decision, `align` records the divergence; the decision itself is adjusted upstream or in Finish, never during Sync.

---

## Steps

Sync is composed of two independent steps, executed via `/sync <step>`:

| Step | Responsibility |
|---|---|
| [`rebase`](../../../../../skills/sync/steps/rebase/SKILL.md) | **Repository integrity:** fetch, fast-forward the base, integrate into the feature branch (rebase or merge), resolve conflicts inspecting both sides, preserve TDD, validate post-integration. |
| [`align`](../../../../../skills/sync/steps/align/SKILL.md) | **ProdOps artifact integrity:** review the diff, map each change to its canonical artifact (BDD, Event Storming, architecture, OBC), and update only the inconsistent ones. |

For complete execution mechanics, see [`prodops/skills/sync/`](../../../../../skills/sync/).

---

## Completion criteria

### sync rebase — repository integrity

Complete when: clean working tree + local base up-to-date with `origin` + feature branch incorporates the latest base + tests/lint pass on the integrated history + no assertion was removed to resolve a conflict.

### sync align — artifact integrity

Complete when: no canonical ProdOps artifact is inconsistent with what is in the branch diff (`git diff main...HEAD`), and the Release Trail received an entry when the alignment was meaningful.

---

## Checklist

### sync rebase

- [ ] Branch updated from the most recent base.
- [ ] Conflicts resolved with both sides inspected.
- [ ] Tests pass on the integrated history.
- [ ] No tests were removed or weakened to complete the sync.
- [ ] Working tree clean at the end.

### sync align

- [ ] BDD Feature reflects the implemented behavior.
- [ ] OBC acceptance criteria are satisfied by the tests.
- [ ] Architecture diagram updated if the change was structural.
- [ ] Event Storming updated if events were added, removed, or renamed.
- [ ] Release Trail entry drafted with evidence when the alignment was meaningful.