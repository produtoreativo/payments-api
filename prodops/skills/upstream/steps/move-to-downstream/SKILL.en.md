---
name: upstream/move-to-downstream
description: Promote a completed upstream experiment to the Downstream delivery flow. Use after the Decision Package is complete and the Product Manager + Tech Lead have approved the capability for delivery.
---

# UPSTREAM → MOVE-TO-DOWNSTREAM

Execute only the promotion step of the Upstream flow.

This step moves a validated experiment from the Discovery track into the
Downstream delivery flow by relocating its artifacts to their committed
locations and registering the capability in the Iteration Plan.

## Action

1. Read the experiment's `experiment.md` and confirm the Decision Package has
   recommendation `Promover` or `Promover com restrição`.
2. Move the BDD Feature:
   - From: `prodops/journeys/discovery/experiments/<NNN-slug>/features/<slug>.feature`
   - To: `prodops/artifacts/business/bdd/<slug>.feature`
3. Move the OBC:
   - From: `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md`
   - To: `prodops/artifacts/business/obcs/<slug>.md`
   - Remove any "Upstream draft only" marking from the file.
4. Add an entry to the Iteration Plan at
   `prodops/artifacts/governance/plans/iteration-plan.md` with decision status `In`
   in the main plan table — not merely in "Identified Iteration Backlog".
   This satisfies the Downstream pre-condition that requires status `In`
   before Bootstrap can begin.
5. If the capability had a Repository Tracking List entry, update its status to
   "Promoted to Downstream" in `prodops/artifacts/product/backlogs/tracking-list.md`.
6. Append a promotion entry to the experiment's trail:
   `prodops/journeys/discovery/experiments/<NNN-slug>/upstream-trail.md`
   — include date, decision, participants, and next steps.
7. Append a high-level entry to the global upstream trail:
   `prodops/journeys/discovery/upstream-trail.md`
   — one line: what was promoted and when.

## Post-conditions

- BDD Feature is in `prodops/artifacts/business/bdd/`.
- OBC is in `prodops/artifacts/business/obcs/` with no draft marking.
- Iteration Plan has the capability entry.
- Both trails are updated.

## Guardrails

- Do not execute this step if the Decision Package recommendation is not
  `Promover` or `Promover com restrição`.
- Do not move artifacts partially — all four moves (BDD, OBC, Iteration Plan,
  trails) must complete in the same action.
- Do not start Downstream implementation before this step is complete.
- If the recommendation is `Promover com restrição`, move only the approved
  scope; leave restricted parts in Upstream.
