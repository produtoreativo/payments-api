# Cards — Context Capsules

Each directory here corresponds to **one card** and contains its **context capsule**
(`<card-slug>/context.md`): the compressed summary (~1k tokens) that the
`/downstream` readiness gate generates from the OBC, the BDD Feature, the risks, and the Reliability Plan. The
following phases (Hack, Sync, Finish) read the capsule instead of walking the
artifact tree — the "reading tax" is paid only once, at Downstream readiness.

Rules:

- **Generated, not handwritten.** Capsules are produced by `/downstream`
  following `prodops/templates/delivery/context-capsule.md`. Do not edit
  directly; if the context changed, run Downstream readiness again.
- **One directory per card.** `prodops/exec/cards/<card-slug>/context.md`.
- **Safe to regenerate.** The capsule is derived from the canonical artifacts —
  it can be recreated at any time without information loss.
- **Committing is the team's call.** Committed capsules double as onboarding
  evidence (they show the context the implementation saw); the recommendation
  is to commit them.
