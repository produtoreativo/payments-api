# Work Item Schema

A **Work Item** is any GitHub resource (Issue, PR, Discussion, Release) that represents an operation being executed on one or more Knowledge Space Artifacts.

Every Work Item must explicitly declare its canonical fields.

→ [Execution Mapping](README.en.md)
→ [Mapping Matrix](matrix.en.md)

---

## Canonical fields

### Mandatory fields

| Field | Type | Description | Example |
|---|---|---|---|
| `artifact_type` | enum | Type of the primary affected artifact | `Local OBC` |
| `artifact_id` | string | Identifier or path of the artifact | `payments-invoice-v2` |
| `operation` | enum | Operation being executed | `Refine` |
| `journey` | enum | ProdOps journey in progress | `Discovery` |

### Contextual fields

| Field | Type | Description | Example |
|---|---|---|---|
| `execution_mode` | enum | Execution mode | `Upstream` |
| `owner` | string | Primary responsible party | `Product Manager` |
| `status` | enum | Work Item state | `In Progress` |
| `priority` | enum | Priority | `High` |
| `release` | string | Target release (when applicable) | `v2.1.0` |
| `repository` | string | Repository containing the artifact | `payments-api` |

### Traceability fields

| Field | Type | Description | Example |
|---|---|---|---|
| `depends_on` | list | Work Items that must be completed first | `[#234, #198]` |
| `blocked_by` | list | Work Items blocking this one | `[#301]` |
| `related_artifacts` | list | Secondary artifacts also affected | `[bdd/payments-invoice.feature]` |

### Evidence fields

| Field | Type | Description | Example |
|---|---|---|---|
| `evidence_required` | boolean | Whether the operation should produce evidence | `true` |
| `evidence_location` | string | Path where evidence will be stored | `artifacts/obcs/payments-invoice-v2.md#evidence` |

---

## Canonical enums

### artifact_type
```
Business Signal
Business Intent
Global OBC
Local OBC
BDD Feature
Architecture
Iteration Plan
Reliability Plan
Release Trail
Experiment
Evidence
Risk Register
Context Capsule
```

### operation
```
# Family: Creation
Create
Capture
Define

# Family: Refinement
Refine
Update
Prototype

# Family: Review and Approval
Review
Approve
Validate

# Family: Structure
Split
Merge
Promote

# Family: Execution
Implement
Experiment
Release

# Family: Closure
Archive
Deprecate
Discard
Cancel
```

### journey
```
Discovery
Assessment
Delivery
Operation
Diligence
```

### execution_mode
```
Upstream
Downstream
N/A
```

### status
```
Open
In Progress
Blocked
In Review
Done
Cancelled
```

### priority
```
Critical
High
Medium
Low
```

---

## GitHub Project — Recommended configuration

For the **Portfolio GitHub Project** and the **Product Repository GitHub Project**, the recommended custom fields are:

```yaml
custom_fields:
  - name: Artifact Type
    type: single_select
    options: [Business Signal, Business Intent, Global OBC, Local OBC, BDD Feature, Architecture, Iteration Plan, Reliability Plan, Release Trail, Experiment, Evidence, Risk Register]

  - name: Artifact ID
    type: text
    description: "Slug or relative path of the artifact (e.g., payments-invoice-v2)"

  - name: Operation
    type: single_select
    options: [Create, Capture, Define, Refine, Update, Prototype, Review, Approve, Validate, Split, Merge, Promote, Implement, Experiment, Release, Archive, Deprecate, Discard, Cancel]

  - name: Journey
    type: single_select
    options: [Discovery, Assessment, Delivery, Operation, Diligence]

  - name: Execution Mode
    type: single_select
    options: [Upstream, Downstream, "N/A"]

  - name: Owner
    type: text

  - name: Release
    type: text
    description: "Target version (e.g., v2.1.0)"

  - name: Evidence Required
    type: checkbox
```

GitHub Project's native fields (`Status`, `Priority`, `Assignees`, `Milestone`) complement the custom fields above.

---

## Canonical Work Item title

A Work Item title should follow the pattern:

```
[Artifact ID]: concise description
```

The title is object-oriented — it describes what is being worked on. `Operation` and `Artifact Type` are process details that belong in labels and the body, where they can be read with context.

Examples:
```
payments-invoice-v2: BDD section incomplete
payments-invoice-v2: pre-Downstream Assessment
payments-invoice-v2: PIX payment split
architecture-overview: new WebhookWorker module
platform-billing-v3: decompose into 3 Local OBCs
payments-invoice.feature: pre-release CI gate
SIG-089: generate Business Intent
```

---

## Canonical Work Item labels

`Operation` and `Artifact Type` are declared as labels to enable search and filter via `gh issue list` and GitHub search.

### Label pattern

```
operation:<value>       # e.g. operation:refine, operation:promote, operation:capture
artifact-type:<value>   # e.g. artifact-type:local-obc, artifact-type:business-signal
```

Values follow the canonical enums in lowercase with hyphens.

### Examples

```bash
gh issue list --label "operation:promote"
gh issue list --label "artifact-type:local-obc"
gh issue list --label "operation:capture" --label "artifact-type:business-signal"
```

### Required labels per Work Item

| Label | Required | Values |
|---|---|---|
| `operation:<value>` | Yes | enums from the `operation` family |
| `artifact-type:<value>` | Yes | enums from `artifact_type` |
| `journey:<value>` | Recommended | enums from `journey` |

---

## Validation

A Work Item is correctly structured when:
- [ ] `artifact_type` is filled with a canonical value
- [ ] `artifact_id` references an artifact that exists in the repository
- [ ] `operation` is filled with an operation allowed for that artifact type (see [Matrix](matrix.en.md))
- [ ] `journey` is filled
- [ ] The title follows the pattern `[Artifact ID]: concise description`
- [ ] Labels `operation:<value>` and `artifact-type:<value>` are present on the Issue

---

## References

→ [Execution Mapping](README.en.md)
→ [Mapping Matrix](matrix.en.md)
→ [Knowledge vs Execution](../knowledge-vs-execution.en.md)
