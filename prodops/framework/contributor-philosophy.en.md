# Contributor Philosophy

This document guides anyone proposing changes to the ProdOps Framework or the reference Runtime.
It is not an approval process — it is a set of questions that helps place each change in the right layer.

---

## The layer standard

Every decision about where something belongs starts from three layers with distinct responsibilities:

```
Framework      →  defines ontology, principles, and responsibilities
Runtime        →  executes with opinionated engineering choices, open to extension
Agents/Skills  →  optimize freely for each service (Claude, Codex, Copilot…)
```

**Framework** answers the question *"what is true about this domain?"*
It does not know how you will run — it knows what exists and why.

**Runtime** answers the question *"how does a reference implementation do this?"*
It is opinionated by design: it makes concrete choices about tooling, format, and flow.
Implementors may swap any part; what does not change is the contract with the Framework.

**Agents/Skills** answer the question *"how does this specific service execute best?"*
They are free to use platform-exclusive capabilities — reasoning, long context, native tools —
without needing consistency across services.

---

## The ideal that guides each layer

> **Immutable, isolated, reproducible, detectable.**

- **Immutable**: the result of an execution must not depend on state accumulated outside the contract.
- **Isolated**: each component must be replaceable without breaking the others.
- **Reproducible**: running twice with the same input must produce the same observable effect.
- **Detectable**: failures and deviations must be visible without additional instrumentation.

These four qualifiers are the measuring stick. When a change violates any of them, the burden
is on the proposer — not the reviewer.

---

## Before proposing a change: three questions

**1. Is this a domain law or a convenience of the current implementation?**

Domain laws (what an event is, what a trail is, what a delivery phase is)
belong to the Framework.
Conveniences (how the emit script calls the GitHub API, which field the YAML uses)
belong to the Runtime or the product.

Putting conveniences in the Framework makes it brittle. Putting laws in the Runtime hides them.

**2. Is there empirical evidence, or only theoretical reasoning?**

The Framework and Runtime evolve from real experiments — not anticipation.
An abstraction never validated outside a specific product is not ready for the Framework.
Stay in the Runtime, or better yet the product, until there are two real cases.

**3. Was the smallest change that solves the problem chosen?**

Generalizing before it is needed creates complexity without benefit. The most common
anti-pattern is abstracting to the Framework something only one product uses. If there is
no second real consumer, do not generalize yet.

---

## How to evolve the Runtime

The Runtime is a reference implementation, not a library. Implementors may copy, fork,
extend, or replace any part.

The healthy evolution cycle:

```
product discovers something that works
  → extracts what is product-specific to runtime.yaml / local product
  → what remains is a RI candidate
    → validates it works for another hypothetical consumer
      → promotes to canonical Runtime
```

**Practical rule**: before generalizing, eliminate the specific. The six extraction surgeries
performed on the Runtime in August 2026 (PT → EN trail texts, hardcoded experiment IDs,
coupled credentials, hardcoded branch) are the canonical example: first we isolated what
belonged to the product, then what remained became exportable RI.

---

## On temporary inconsistencies

The Framework and Runtime evolved rapidly. For a period it will be normal to find
inconsistencies between documents, concept names, and what the code does versus what
the docs say.

The right posture is not to tolerate them — it is to **change willingly to maintain consistency**.

Inconsistency detected = immediate PR. Do not accumulate documentation debt waiting for
the "right moment." The cost of fixing early is low; the cost of letting things diverge
is high because the Framework is the source of truth that agents read before acting.

When you find a conflict between two definitions:
1. The higher layer prevails (Framework > Runtime > Agents).
2. If the conflict is within the same layer, the more recent document prevails.
3. Document the decision in `framework-gaps.md` if the conflict reveals a real gap.

---

## What belongs where: quick reference

| What | Framework | Runtime | Product | Agents/Skills |
|---|---|---|---|---|
| Event definition | ✓ | | | |
| Event schema | ✓ | | | |
| Emit script | | ✓ | | |
| Credentials and endpoints | | | ✓ | |
| Trail templates | | ✓ | | |
| Product-specific trail texts | | | ✓ | |
| Delivery phase (what it is) | ✓ | | | |
| Phase skill (how to execute) | | ✓ | | |
| Per-model prompt optimization | | | | ✓ |
| runtime.yaml | | | ✓ | |
| runtime.yaml.example | | ✓ | | |

---

---

## Community standards before custom patterns

Before inventing a format, schema, protocol, or convention for the Runtime, choose an
existing community standard — even one with low adoption.

**Why?** Community standards have already solved the edge cases you have not encountered yet.
They come with documentation, tooling, examples, and contributors who will keep evolving
the standard independently of this project.

Canonical references for the ProdOps Runtime:

| Domain | Adopted standard |
|---|---|
| HTTP API contracts | [OpenAPI](https://spec.openapis.org/oas/latest.html) |
| Async event contracts | [AsyncAPI](https://www.asyncapi.com/docs/reference/specification/latest) |
| Event envelope | [CloudEvents](https://cloudevents.io/) |
| Service level objectives | [OpenSLO](https://openslo.com/) |

When no community standard exists for the problem: document the gap in `framework-gaps.md`,
describe the minimal pattern adopted, and mark it as provisional.
Never promote a provisional pattern to canonical without an explicit review.

## File conventions

Every framework document must have a language pair:

- `name.md` — Portuguese version
- `name.en.md` — English version

Both created in the same commit. There is no "create later" — a document without its pair is incomplete.
The `.en.md` pair is what allows the Runtime to be consumed by any team and lets international agents
(Codex, Copilot, GPT) read the same contract without depending on a future translation.

→ [principles.en.md](principles.en.md) — the 8 foundational principles
→ [canonical-paths.en.md](canonical-paths.en.md) — where each artifact lives
→ [framework-gaps.md](framework-gaps.md) — known gaps and pending decisions
→ [runtime/docs/contract.md](../runtime/docs/contract.md) — Runtime contract with the Framework
