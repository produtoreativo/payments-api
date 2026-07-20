# Execution Mapping

**Execution Mapping** is the ProdOps Framework capability that declaratively defines how each Knowledge Space artifact type relates to GitHub execution resources.

It does not execute synchronizations. It does not create Issues. It defines the **contract**.

→ [Knowledge vs Execution](../knowledge-vs-execution.en.md) — foundational principle
→ [Mapping Matrix](matrix.en.md) — all artifacts × operations × resources
→ [Work Item Schema](work-item-schema.en.md) — canonical GitHub Project fields

---

## Why this model exists

Before Execution Mapping, the Framework had an implicit convention: each artifact had "a corresponding Issue." This created structural problems:

**Problem 1 — Identity confusion**
Asking "which Issue belongs to this OBC?" is the wrong question. An OBC can have zero Issues (during inactive periods), one Issue (active refinement), or dozens of Issues (over its operational life). There is no "the OBC's Issue."

**Problem 2 — Duplicated state**
When an artifact's state is synchronized with an Issue's state, two records of the same data exist. Which one prevails? Who updates whom? This creates drift and inconsistency.

**Problem 3 — Multiple repository impossibility**
If a Business Intent affects three products, and each product opens "the Intent's Issue," three Issues exist for the same artifact — with no declared link between them.

**Problem 4 — Implicit operations**
Without an explicit model, each team member invents which Issue type to create, which label to use, which field to fill. The Framework says nothing about what is expected.

**Problem 5 — GitHub as source of truth**
When the Issue structure mirrors the artifact structure, the team starts reading Issues to understand the product's state — instead of reading the artifacts. GitHub accidentally becomes the source of truth.

---

## What Execution Mapping solves

| Problem | Solution |
|---|---|
| "Which Issue belongs to the OBC?" | None exists. Work Items about the OBC exist. One per operation, when work is needed. |
| Duplicated state | The artifact has its own state (in Markdown). The Work Item has its own state (in GitHub). They are independent. |
| Multiple repositories | Each Work Item explicitly declares `artifact_id`. Multiple Work Items can reference the same artifact across different repos. |
| Implicit operations | Execution Mapping declares which operations are allowed for each artifact and which GitHub resources each operation can generate. |
| GitHub as source of truth | The Work Item references the artifact — it is not the artifact. Markdown always prevails. |

---

## Conceptual model

### Artifact (Knowledge Space)

Each Artifact has:
- **permanent identity** — a `slug` or ID that never changes
- **its own state** — lifecycle defined in the artifact's document
- **canonical location** — path in the git repository
- **allowed operations** — declared in Execution Mapping

### Operation (bridge)

An operation is an action performed **on** an artifact. It:
- has a beginning, middle, and end
- may generate one or more Work Items in GitHub
- may modify the artifact (via PR)
- may generate evidence that complements the artifact
- **is not the artifact** — when it ends, the Work Item stops existing as an active item

### Work Item (Execution Space)

A Work Item is a GitHub resource (Issue, PR, Discussion, Release) that:
- explicitly references one or more artifacts
- represents an operation in progress
- has its own lifecycle in GitHub (Open → Done)
- closes when the operation ends
- does not replace the artifact

### Cardinality

```
                Artifact
                   │
        ┌──────────┼──────────┐
        │          │          │
     Work Item  Work Item  Work Item
     (Sprint 1) (Sprint 4) (Sprint 9)
```

An artifact can have **zero** active Work Items (no work in progress) or **many** Work Items over its lifetime. Each Work Item is independent.

```
        Work Item
             │
   ┌─────────┼──────────┐
   │         │          │
Artifact  Artifact   Artifact
   A         B          C
```

A Work Item can affect **multiple artifacts** simultaneously. Example: a PR that updates OBC, BDD, and Architecture at the same time.

---

## Operation catalog

Operations are semantic actions performed on artifacts. They group into families:

### Family: Creation
| Operation | Description |
|---|---|
| `Create` | First instance of the artifact is created |
| `Capture` | Signal or observation is recorded (Business Signal) |
| `Define` | Exploratory artifact is defined (Experiment) |

### Family: Refinement
| Operation | Description |
|---|---|
| `Refine` | Artifact content evolves; criteria emerge |
| `Update` | Content updated with new information (evidence, decision) |
| `Prototype` | Partial model built to validate a hypothesis |

### Family: Review and Approval
| Operation | Description |
|---|---|
| `Review` | Artifact is evaluated by one or more responsible parties |
| `Approve` | Artifact receives formal approval (changes state) |
| `Validate` | Artifact is verified against objective criteria (e.g., CI) |

### Family: Structure
| Operation | Description |
|---|---|
| `Split` | Artifact originates N specializations (Global OBC → Local OBCs) |
| `Merge` | Two artifacts are consolidated into one |
| `Promote` | Artifact advances a level (Signal generates Intent, Upstream → Downstream) |

### Family: Execution
| Operation | Description |
|---|---|
| `Implement` | Code is developed against the artifact |
| `Experiment` | Formal experiment is run based on the artifact |
| `Release` | Artifact contributes to a Release |

### Family: Closure
| Operation | Description |
|---|---|
| `Archive` | Artifact closed; history preserved |
| `Deprecate` | Artifact marked obsolete; still accessible |
| `Discard` | Artifact discarded with justification |
| `Cancel` | Work on the artifact is cancelled |

---

## GitHub resources by type

| GitHub Resource | When to use |
|---|---|
| **Issue** | Track exploration, refinement, review work — work that does not result in a commit |
| **Pull Request** | Track work that results in a file modification in the repository |
| **Discussion** | Track open decisions, architectural or business — no defined artifact yet |
| **Release** | Mark a delivery point for a set of artifacts to production |
| **Workflow** (Actions) | Automated operations: BDD validation, lint, build |
| **Milestone** | Group Work Items related to a deliverable or time horizon |
| **Project Item** | Represent a Work Item within a GitHub Project for visual management |

---

## Multiple repositories

Execution Mapping natively supports multi-repository scenarios:

```
Business Intent BI-042 (Global OBC in portfolio repository)
  │
  ├─ Local OBC in payments-api      ← Work Items in payments-api
  ├─ Local OBC in webshop-api       ← Work Items in webshop-api
  └─ Local OBC in order-api         ← Work Items in order-api
```

Each repository tracks its own work via Work Items. The link between repositories is established by `artifact_id` (referencing the same Global OBC) — not by Issue mirroring.

---

## Single source of truth

```
Markdown > GitHub > External tools

prodops/artifacts/business/obcs/payments-invoice-v2.md
  = source of truth for the OBC's CONTENT and STATE

GitHub Issue #234 "Refine OBC — BDD section incomplete"
  = source of truth for ONGOING WORK on the OBC

Jira / ADO / Linear
  = optional convenience mirrors of GitHub
```

If there is a divergence between Markdown and GitHub, **Markdown prevails**. The Work Item is created to execute work that will bring the GitHub state in line with what the Markdown describes.

---

## References

→ [Knowledge vs Execution](../knowledge-vs-execution.en.md)
→ [Mapping Matrix](matrix.en.md)
→ [Work Item Schema](work-item-schema.en.md)
→ [Operating Model](../operating-model.en.md)
→ [Glossary](../glossary.en.md)
