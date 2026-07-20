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
| `evidence_location` | string | Path where evidence will be stored | `artifacts/business/obcs/payments-invoice-v2.md#evidence` |

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
[Operation] — [Artifact Type] [Artifact ID]: [concise description]
```

Examples:
```
Refine — Local OBC payments-invoice-v2: BDD section incomplete
Review — Local OBC payments-invoice-v2: pre-Downstream Assessment
Implement — Local OBC payments-invoice-v2: PIX payment split
Update — Architecture overview: new WebhookWorker module
Split — Global OBC platform-billing-v3: decompose into 3 Local OBCs
Validate — BDD Feature payments-invoice.feature: pre-release CI gate
Promote — Business Signal SIG-089: generate Business Intent
```

This pattern:
- identifies the artifact without ambiguity
- names the operation without using "Issue for X"
- enables search and filter by artifact or operation in GitHub

---

## Validation

A Work Item is correctly structured when:
- [ ] `artifact_type` is filled with a canonical value
- [ ] `artifact_id` references an artifact that exists in the repository
- [ ] `operation` is filled with an operation allowed for that artifact type (see [Matrix](matrix.en.md))
- [ ] `journey` is filled
- [ ] The title follows the pattern `[Operation] — [Artifact Type] [Artifact ID]: ...`

---

## References

→ [Execution Mapping](README.en.md)
→ [Mapping Matrix](matrix.en.md)
→ [Knowledge vs Execution](../knowledge-vs-execution.en.md)
