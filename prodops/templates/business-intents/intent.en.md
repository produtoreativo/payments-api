# Business Intent — [Title]

Canonical location: `prodops/artifacts/business/intents/<slug>.md`

> A **Business Intent** records a strategic decision to pursue value — born from one or more Business Signals. It is not a commitment to implementation. It is the formal entry point of the Framework before deciding whether the work goes through Upstream (exploration) or Downstream (governed delivery). Entities never change identity: a Business Signal **generates** a Business Intent; a Business Intent **has** an OBC as its contract document.

---

## Identification

| Field | Content |
|---|---|
| Title | |
| Origin Stream | Business / Enterprise / Team / Technology |
| Registration date | YYYY-MM-DD |
| Requester | |
| Product owner | |

> **Origin Stream:** Classify the origin of the Business Signal that generated this Business Intent. Choose exactly one:
> - **Business** — market, customer, product (conversion, adoption, revenue, retention)
> - **Enterprise** — compliance, regulation, audit, partners, governance
> - **Team** — process, productivity, onboarding, automations, workflow
> - **Technology** — platform, security, infrastructure, observability, reliability
>
> See [`framework/origin-streams.md`](../../framework/origin-streams.md) for definitions and examples.

---

## Intention

Describe in one or two sentences the value intended to be generated.

> "We want [actor] to be able to [action] in order to [business outcome / operational improvement]."

---

## Context

Why did this intention arise now? What pressure, opportunity, or problem motivated it?

---

## Hypotheses

List the hypotheses that motivate this intention and that must be confirmed, refined, or discarded during exploration.

A hypothesis must represent a belief about the business, user, process, or system — not an implementation decision.

Examples:

- [ ] The current limitation reduces conversion / generates operational cost / creates risk.
- [ ] Solving this problem will generate measurable value.
- [ ] There is sufficient demand to justify the investment.

---

## Open questions

What needs to be answered before committing to implementation?

- [ ]
- [ ]

---

## Suggested execution mode

- [ ] **Upstream** — there is sufficient uncertainty to explore before committing
- [ ] **Downstream** — there is sufficient clarity; OBC and BDD can be written now

Justification:

---

## Next step

- If Upstream: create experiment in `prodops/journeys/discovery/experiments/`
- If Downstream: create OBC in `prodops/artifacts/business/obcs/` and BDD Feature in `prodops/artifacts/business/bdd/`

---

## Generated artifacts

| Artifact | Location |
|---|---|
| | |
