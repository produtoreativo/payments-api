# ProdOps Principles

## 1. Product context first
No code change begins without context compatible with its execution mode. Upstream is permissive, experimental and carries no delivery commitment. Downstream is complete: before Delivery execution, it requires every readiness artifact and gate defined by the Framework. Agents must not invent missing business context.

## 2. Upstream before commitment
Upstream is not a journey: it is the no-delivery-commitment mode, where any journey may operate with experimental rigor and variable maturity. Code is disposable until promoted to Downstream. Downstream may also execute any journey, but applies every current quality gate. See [AGENTS.md Upstream Path](../../AGENTS.md).

## 3. Contracts before implementation
Identify or create a verifiable contract (OpenAPI, AsyncAPI, BDD Feature, schema) before writing production code. The contract is the shared language between test and implementation.

## 4. Observability as a deliverable
Logs, errors, metrics, and traceability are part of the implementation, not add-ons added afterward. A feature is not done if its behavior cannot be observed in production.

## 5. Evidence-based decisions
Every delivery decision — promote, revert, accept risk — must be backed by recorded evidence. See [release-trail](../artifacts/trails/release-trail.md) and [operation/](journeys/operation/).

## 6. Reliability is a first-class concern
Reliability objectives are defined before implementation, tracked via OBCs and SLOs, and validated before promotion. See [reliability-plans](../artifacts/plans/reliability/).

## 7. No shortcuts in production code
Production code must not contain test-only branches, environment-specific hacks, or hidden overrides that alter behavior in tests. Designed behavior modes (e.g., external provider mock) are valid exceptions when explicitly declared as an intentional product feature — not as a test shortcut.

## 8. Automation First
An agent must always attempt to execute an action itself before instructing a human to do it. Manual intervention is a last resort (a documented **Manual Exception**), never the default path. Canonical order of attempts: API → MCP → CLI → SDK → Browser Automation → Manual Exception only when all else fails. Phrases like "do it manually", "access the UI", or "configure manually" are prohibited unless all automation options have been demonstrably exhausted and recorded in a tracking Issue. See [automation-first.md](automation-first.md) for the full decision tree.
