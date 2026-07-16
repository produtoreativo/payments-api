# Product Stages

ProdOps organizes the lifecycle of a product into six progressive stages divided into two macro-phases. The stage declares where the product is — and determines which delivery metrics carry the most weight at that moment.

---

## The two macro-phases

```
[ Hypothesis Validation ]  →  THESIS AND COMMITMENT  →  [ Acceleration ]
  PoC  →  MVP  →  IPR                                    MVR  →  MVT  →  MLP
```

**Hypothesis Validation:** minimized cost, fast learning, customer as validator. The goal is to prove the idea is viable before committing to scale.

**Acceleration:** standardized process, market adoption, product that delights. The goal is to grow with reliability and repeatability.

---

## The six stages

### PoC — Proof of Concept

**Objective:** Validate whether an idea or approach is viable with a real customer.

**Central characteristic:** The customer is always involved. No customer means it is not a PoC — it is a **Spike Solution** (see below).

**Expected outcome:** Confirm whether the idea is worth developing, based on real feedback from those who will use or pay for the product.

**Example:** A split payment prototype demonstrated to Magazine Siará before any development decision.

---

### MVP — Minimum Viable Product

**Objective:** Launch the simplest version of the product to validate with real users.

**Central characteristic:** Functional product, minimum features, tested in the market.

**Expected outcome:** Real user feedback and validation of business hypotheses.

**Example:** Payment gateway with Pix support only, no other payment methods.

---

### IPR — Initial Product Release

**Objective:** First functional version released for use — may have limitations, but already delivers value.

**Central characteristic:** Start of real use by an initial group of users.

**Expected outcome:** Evidence of delivered value, with learnings collected for future iterations.

**Example:** First public version of the gateway with Pix and hosted credit card.

---

### MVR — Minimum Viable Repeatability

**Objective:** Validate that the product can be repeated and scaled with a standardized process.

**Central characteristic:** Defined replication process; predictable and efficient onboarding.

**Expected outcome:** The product can be replicated for new customers without significant manual effort.

**Example:** Gateway with automated tenant onboarding, no manual configuration per customer.

---

### MVT — Minimum Viable Traction

**Objective:** Validate that there is real adoption and market demand.

**Central characteristic:** Measures engagement, growth, and initial retention.

**Expected outcome:** Evidence of real product demand — paying users or customers without heavy marketing effort.

**Example:** Gateway reaching 10 active tenants with growing transaction volume month over month.

---

### MLP — Minimum Lovable Product

**Objective:** A product that not only works, but delights users.

**Central characteristic:** Beyond functional — generates strong emotional connection. Users don't just use it; they recommend it.

**Expected outcome:** Positive Net Promoter Score; product spontaneously recommended.

**Example:** Gateway with an integration experience so simple and transparent that developers recommend it without being asked.

---

## Spike Solution

**Spike Solution is not a product stage.** It is a technical exploration instrument available at any stage and at any experiment phase — including inside a PoC or any Upstream journey.

**Critical difference from PoC:**

| Dimension | PoC | Spike Solution |
|---|---|---|
| Customer involved | Always | Never |
| Objective | Validate viability with real feedback | Answer a specific technical question |
| Produces | Customer-validated learning | Internal technical learning |
| Code | May be demonstrable to customer | Always disposable |
| When to use | Hypothesis Validation phase | Any stage, any phase |
| Recorded in | Experiment (`experiment.md`) | `prodops/journeys/discovery/spikes.md` |

A Spike Solution may occur **inside** a PoC (to answer a technical question before demonstrating to the customer) or **independently** (at any stage, whenever a technical uncertainty blocks progress).

---

## Stages and DORA metrics

Each stage defines the relative weight of the extended DORA metrics. In early stages, learning speed dominates (high Lead Time weight). In late stages, reliability dominates (high MTTR, Availability, Change Fail Rate weights).

→ See [`dora-metrics.en.md`](dora-metrics.en.md) for the full weight table per stage.

---

## References

→ [Glossary](glossary.en.md)
→ [DORA Metrics — Extended Model](dora-metrics.en.md)
→ [Framework Flow](flow.en.md)
→ [Discovery Journey](../journeys/discovery/README.md)
→ [Spikes](../journeys/discovery/spikes.md)
