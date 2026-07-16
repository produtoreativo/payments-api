# Release Trail — Legacy (pre-2026-07-14)

> This file contains all Release Trail entries produced before the adoption of the per-agent-session trail model. Entries were migrated from `prodops/artifacts/trails/release-trail.md` on 2026-07-14.
>
> **Do not add new entries here.** New deliveries must be recorded in the active session trail under `prodops/artifacts/trails/sessions/`.

---

## 2026-06-30 22:24

### Summary

Implemented in-repo Reliability Plan P0 hardening for payment confirmation: Dynamo webhook correlation now finds invoices by provider payment id or external reference, and uncorrelated provider webhooks now emit an observable event.

### Related

- Reliability Plan: `prodops/journeys/assessment/reliability-plans/README.md`
- OBC: Reliable payment confirmation for the Checkout -> Payments journey
- BDD Feature: `prodops/artifacts/bdd/payment-confirmation.feature`

### Code

- `api/src/infra/dynamo.service.ts`
- `api/src/modules/invoices/services/invoice-repository.service.ts`
- `api/src/modules/invoices/services/invoice.service.ts`

### Tests

- Tests created or updated: `api/test/criar-invoice.e2e-spec.ts`
- Validation executed: `cd api && npm run test:acceptance -- --runInBand`
- Validation executed: `cd api && npm run build`

### Artifacts Updated

- Product Deck: not changed
- Service Deck: not changed
- Repository Tracking List: not changed
- Reliability Plan: updated to reflect implemented Dynamo correlation and uncorrelated webhook observability
- OBC: not changed

### Notes

Remaining Reliability Plan items outside this change include Checkout Feature Flag readiness, retry policy for transient provider failures, required webhook token validation for release environments, Asaas timeout configuration and durable publication strategy for `payment.confirmed`.

## 2026-07-02 09:58

### Summary

Updated the repository home in `README.md` to present payments-api as the ProdOps University reference project, connecting the functional sandbox to product, reliability, observability, testing and operational artifacts.

### Related

- Reliability Plan: `prodops/journeys/assessment/reliability-plans/README.md`
- OBC: Product Deck and Service Deck OBC sections referenced in the README
- BDD Feature: not applicable — repository organization change, no product behavior changed

### Code

- `README.md`

### Tests

- Tests created or updated: none
- Validation executed: checked referenced README paths exist
- Validation executed: `git diff --check -- README.md prodops/artifacts/trails/release-trail.md`

### Artifacts Updated

- Product Deck: referenced, not changed
- Service Deck: referenced, not changed
- Repository Tracking List: referenced, not changed
- Reliability Plan: referenced, not changed
- OBC: referenced, not changed

### Notes

README now calls out educational roadmap gaps explicitly: OpenAPI, OpenSLO, dedicated runbooks, Decision Trail, postmortems, dashboards and event contracts.

## 2026-07-02 11:17

### Summary

Removed the tracked frontend `node_modules` tree from Git and updated the repository ignore rules so dependency folders are ignored at any directory depth.

### Related

- Reliability Plan: not applicable
- OBC: not applicable
- BDD Feature: not applicable

### Code

- `.gitignore`
- `validation-workbench/node_modules`

### Tests

- Tests created or updated: none, mechanical repository hygiene change
- Validation executed: `git ls-files | rg '(^|/)node_modules(/|$)' || true`
- Validation executed: `git check-ignore -v validation-workbench/node_modules/.keep api/node_modules/.keep node_modules/.keep`

### Artifacts Updated

- Product Deck: not changed
- Service Deck: not changed
- Repository Tracking List: not changed
- Reliability Plan: not changed
- OBC: not changed

### Notes

The local `validation-workbench/node_modules` directory can remain on disk for the developer environment, but it is no longer tracked by Git.

## 2026-07-02 11:38

### What changed?

Organized the repository for Claude, Codex, and Copilot agents with ProdOps as the single source of context. Added root agent guidance, Claude/Codex-specific instructions, Copilot prompts, generic execution skills, canonical ProdOps folders, and operation/diligence placeholders.

### Why?

To separate product context from execution workflows and tool-specific configuration, reducing duplicated business knowledge across agent surfaces.

### Related OBC

Not applicable; repository organization change.

### Related BDD

Not applicable; no product behavior changed.

### Evidence

- Created root `AGENTS.md` flow: Current State -> Assessment -> Reliability Plan -> BDD Feature -> Skill -> Code -> Release Trail.
- Added generic skills under `skills/`.
- Moved ProdOps artifacts to canonical paths under `prodops/artifacts/product/`, `prodops/assessment/`, `prodops/execution-model/`, and `prodops/operation/`.
- Updated old ProdOps path references.
- Validation executed: expected structure presence check.
- Validation executed: old path/name reference search.
- Validation executed: root skill frontmatter check.

### Next steps

Keep future product context in `prodops/` and keep skills limited to execution procedure.

## 2026-07-02 13:42

### What changed?

Split the ProdOps workspace into Upstream and Downstream paths. Moved governed delivery evidence from `prodops/diligence/` to `prodops/execution-model/`, added the Upstream exploration workspace, added `skills/upstream/` and `skills/downstream/`, and added templates for both paths.

### Why?

To separate lightweight exploration from governed delivery while preserving the full ProdOps delivery flow for committed release work.

### Related OBC

Not applicable; repository organization change.

### Related BDD

Not applicable; no product behavior changed.

### Evidence

- Moved Release Trail, Quality Gates, and Done Criteria into `prodops/execution-model/`.
- Added `prodops/journeys/discovery/` for experiments, spikes, prototypes, learnings, and upstream trail.
- Added `prodops/downstream/delivery-flow.md` and a pointer backlog.
- Added `prodops/skills/upstream/SKILL.md` and `prodops/skills/downstream/SKILL.md`.
- Updated agent and Copilot prompts to route work through Upstream or Downstream.

### Next steps

Use Upstream for reversible exploration and Downstream for approved delivery governed by the full ProdOps flow.

## 2026-07-03 — Webhook Configuration per API Token

### What changed?

Implemented webhook configuration API, allowing API Token holders to register
HTTPS callback URLs that receive `invoice.confirmed` and `invoice.cancelled`
events. Each webhook has an auto-generated HMAC-SHA256 secret returned only at
creation. Delivery is fire-and-forget; failure never blocks the payment flow.

Canonical events `payment.confirmed` and `payment.cancelled` were enriched with
`tenantId`, `amount`, and `currency` to give downstream consumers full context
without a secondary lookup.

### Why?

Complete the integration contract: consumers using API Tokens need status
notifications without polling. Webhook configuration is the natural complement to
the API Token feature delivered earlier in this iteration.

### Related OBC

`prodops/artifacts/obcs/webhook-configuration.md`

### Related BDD

`prodops/artifacts/bdd/webhook-configuration.feature`

### Evidence

- `WebhooksModule` created at `api/src/modules/webhooks/` with:
  - `WebhookRepository` — DynamoDB-backed storage with `TenantWebhooksIndex` GSI.
  - `WebhookService` — registration, listing, deactivation; URL validation (HTTPS or localhost).
  - `WebhookDeliveryService` — listens to `payment.confirmed` / `payment.cancelled`; dispatches signed HTTP POST with 10s timeout; emits `webhook.delivery.sent` / `webhook.delivery.failed`.
  - `WebhookConfigController` — `POST /webhooks`, `GET /webhooks`, `DELETE /webhooks/:webhookId`, all behind `ApiTokenGuard`.
- `WebhooksTable` added to `api/infra/dynamodb.yaml` with `TenantWebhooksIndex` GSI.
- `payment.confirmed` and `payment.cancelled` events enriched with `tenantId`, `amount`, `currency` in `invoice.service.ts`.
- `WebhooksModule` registered in `AppModule`.
- Build: `cd api && npm run build` — passed with no errors.

### Next steps

- Add acceptance tests: webhook registration, listing, delivery on confirmed event.
- Add retry logic for failed deliveries (backoff + dead-letter queue).
- Add `WEBHOOKS_TABLE` env var to `.env.example`.
- Consider TTL for deactivated webhook records in DynamoDB.

## 2026-07-03 — API Token Validation

### What changed?

Implemented API Token authentication for the Payments API. All business routes
(`/invoices`) now require a valid `X-Api-Token` header. Webhook routes remain
excluded (they use their own `asaas-access-token` validation). A local dev token
is pre-registered via `API_TOKEN_LOCAL` env var, allowing localhost access without
external secrets infrastructure.

### Why?

Enable controlled access to the Payments API by tenant, eliminate anonymous
consumption by Checkout or integrations, and establish observable token validation
events from day one of production traffic.

### Related OBC

`prodops/artifacts/obcs/api-token-validation.md`

### Related BDD

`prodops/artifacts/bdd/api-token-validation.feature`

### Evidence

- `AuthModule` created at `api/src/modules/auth/` with `ApiTokenService` and `ApiTokenGuard`.
- `ApiTokenGuard` applied to `InvoiceController` via `@UseGuards`.
- `X-Api-Token` added to CORS allowed headers (`api/src/main.ts`).
- `X-Api-Token` added to pino log redaction paths (`api/src/app.module.ts`).
- `API_TOKEN_LOCAL` documented in `.env.example` and set in `.env` for local dev.
- Build executed: `cd api && npm run build` — passed with no errors.

### Next steps

- Add acceptance test scenarios for 401 rejection and token validation.
- Wire `API_TOKENS` env var with real Checkout token in staging before go-live.
- Evaluate token store migration to DynamoDB or SSM Parameter Store for zero-deploy revocation.

## 2026-07-08

### Summary

Implemented Boleto invoice creation on the Payments gateway: contract extended with `bankSlipUrl` and `identificationField` for `billingType=BOLETO`, `dueDate` validated as future (minimum D+1) before provider call, and provider charge contract now asserts `bankSlipUrl` presence for Boleto. The `toResponse` payload now exposes `billingType`, `dueDate`, `bankSlipUrl` and `identificationField` per the OBC response contract.

### Related OBC

`prodops/artifacts/obcs/create-invoice-boleto.md`

### Related BDD

`prodops/artifacts/bdd/create-invoice-boleto.feature` (8 scenarios)

### Iteration Plan

"Criar invoice via Boleto" — Entrou.

### Risks addressed

- B1 — `bankSlipUrl` absent: `assertProviderChargeContract` now rejects Boleto charge without `bankSlipUrl` (provider_contract_violation).
- B2 — `dueDate` past/absent: `400` validation before calling Asaas (minimum D+1).
- B4 — `identificationField` absent: added to `ProviderChargeResponse`, `InvoiceRecord` and `InvoiceResponseDto`.

### Code

- `api/src/modules/invoices/types/invoice.types.ts` — `InvoiceRecord` and `ProviderChargeResponse` gain `bankSlipUrl`/`identificationField`.
- `api/src/modules/invoices/dto/invoice-response.dto.ts` — DTO exposes `billingType`, `dueDate`, `bankSlipUrl`, `identificationField`.
- `api/src/infra/asaas.service.ts` — mock generates `bankSlipUrl`/`identificationField` for BOLETO; real response maps `identificationField`.
- `api/src/modules/invoices/services/invoice.service.ts`:
  - `validateCreateInvoice`: `dueDate` mandatory and future (≥ D+1) for BOLETO.
  - `assertProviderChargeContract`: requires `bankSlipUrl` for Boleto charge.
  - `createInvoice`: propagates `bankSlipUrl`/`identificationField` when saving OPEN.
  - `toResponse`: exposes the new fields.

### Tests

- Test created: `api/test/criar-invoice-boleto.e2e-spec.ts` — 8 BDD scenarios covered.
- Red Bar confirmed (4 behavioral failures: bankSlipUrl/identificationField absent in response, future dueDate not validated).
- Green Bar: `npx jest --config ./test/jest-e2e.json test/criar-invoice-boleto.e2e-spec.ts` — 8 passed.
- Full suite without regression: `criar-invoice`, `cancelar-invoice`, `confirmar-pagamento`, `api-token`, `criar-invoice-boleto` — 38 passed, 5 suites.
- Lint: `cd api && npm run lint` — exit 0 (0 errors).
- Build: `cd api && npm run build` — passed.

### Artifacts Updated

- Product Deck: not changed.
- Service Deck: not changed.
- Iteration Plan: not changed (entry already with status In).
- OBC: not changed.
- BDD Feature: not changed.
- Risks: not changed (B1/B2/B4 mitigations covered by implementation).

### Notes / Decision Trail

- `externalReference`: the BDD Feature (scenario "Create boleto successfully") indicates that the `externalReference` sent to Asaas should contain the order identifier (`MS-200010`). The current code uses `externalReference = invoiceId` (`inv_ulid`) and `assertProviderChargeContract` validates consistency against that value. Changing this semantics would break the already-stabilized PIX/card contract and their acceptance tests. The existing rule was preserved (`externalReference = invoiceId`); alignment with the Boleto BDD remains as a registered divergence for later decision at the Delivery Sync, per the Context Rules in AGENTS.md ("preserve the existing and record in Decision Trail").
- `payment.boleto.expired` (Risk B3) not implemented in this delivery — depends on the provider's `PAYMENT_OVERDUE` webhook, currently mapped as an ignored event. The asynchronous expiry journey remains outside this slice.

## 2026-07-08 — Fix: test-acceptance.sh did not run the Boleto suite

### Summary

`scripts/test-acceptance.sh` did not include `test/criar-invoice-boleto.e2e-spec.ts` in any filter — neither in the default suite (no argument), nor as a named option (`criar`, `cancelar`, `confirmar`, `token`). The 8 Boleto BDD scenarios, implemented and committed in the previous trail entry, were never executed by the acceptance test wrapper. Added `boleto` filter and inclusion in the default suite.

Also fixed a container detection bug: `docker inspect` on a non-existent container emits an empty line on stdout (behavior observed in Docker CLI 29.6.1) in addition to the error on stderr; combined with `set -o pipefail`, this caused the script to exit silently before reaching the `missing` fallback, preventing automatic LocalStack container creation when absent.

### Related OBC

`prodops/artifacts/obcs/create-invoice-boleto.md`

### Related BDD

`prodops/artifacts/bdd/create-invoice-boleto.feature` (8 scenarios — already covered by `api/test/criar-invoice-boleto.e2e-spec.ts`, now effectively executed)

### Evidence

- `scripts/test-acceptance.sh`:
  - Container state detection line: normalizes `docker inspect` output (`tr -d '[:space:]'`) and neutralizes the pipeline exit code (`|| true`) before applying the `missing` fallback, fixing the interaction with `set -euo pipefail`.
  - `boleto` filter added, mapping to `test/criar-invoice-boleto.e2e-spec.ts`.
  - Default suite (`FILTER=""`) now includes `test/criar-invoice-boleto.e2e-spec.ts`.
  - Usage comment and invalid filter error message updated.
- Validation executed: `localstack` container manually removed (`docker rm -f localstack`) and `./scripts/test-acceptance.sh` re-executed from scratch — script correctly detected `missing` state, recreated the container, waited for health, and ran the full suite.
- Full suite without regression: `criar-invoice`, `criar-invoice-boleto`, `cancelar-invoice`, `confirmar-pagamento`, `api-token` — 38 passed, 5 suites.

### Artifacts Updated

- Product Deck: not changed.
- Service Deck: not changed.
- Iteration Plan: not changed.
- OBC: not changed.
- BDD Feature: not changed — the gap was in execution (wrapper script), not in scenario coverage.

### Notes

This gap would not have been caught by CI, since `.github/workflows/staging-deploy.yml` invokes the specs directly via `npx jest` (not via `test-acceptance.sh`) — the wrapper is used only in the local flow. It is worth considering, in a future Sync, whether CI and the local script should share the same spec list to prevent this class of divergence from recurring.

## 2026-07-12 — Consolidação e remoção de `docs/`

### Summary

Removed the legacy `docs/` document tree after triage. Valid context was consolidated into canonical sources without modifying code or promoting new behaviors.

### Artifacts Updated

- Product Deck: incorporated the view of Payments as System of Record and Asaas as external PSP.
- Architecture Overview: recorded the Payments ↔ PSP responsibility boundary.
- Decision Trail: recorded the consolidation and discarded alternatives.
- BDD index: added the card feature and corrected the path for exploratory features.
- OBC index: reinforced that every committed OBC has its own file.
- API README: replaced the generic NestJS content with Payments API-specific instructions and Asaas integration.
- Reliability Plan: replaced references to legacy contracts with current paths.

### Validation

- No committed BDD was replaced by the alternative spec found in `docs/`.
- The canonical Event Storming at `prodops/journeys/assessment/event-storming/plan.json` was preserved.
- The change is exclusively documentary; application tests are not required.

## 2026-07-13 — refine(sync): rebase as repo integrity, align as ProdOps artifact integrity

### Summary

Conceptual refinement of the Sync phase in `prodops/journeys/delivery/phases/sync/`. The two steps gained precisely articulated responsibilities: `rebase` is **git repository integrity** (making the repo ready for merge, without weakening tests), and `align` is **ProdOps artifact integrity** (BDD, Event Storming, architecture, OBC and Release Trail reflect the branch diff). Boundaries of Sync with Hack (quality gates/Yellow Bar), Finish (PR opening) and Ship (async pipeline) were made explicit, along with completion criteria for each step and the canonical change → artifact table.

### Related

- Phase: `prodops/journeys/delivery/phases/sync/README.md` (and `.en.md`)
- Skills: `prodops/skills/sync/steps/rebase/SKILL.md`, `prodops/skills/sync/steps/align/SKILL.md` (and `.en.md` versions)
- Copilot prompts: `.github/prompts/sync-rebase.prompt.md`, `.github/prompts/sync-align.prompt.md`

### Artifacts Updated

- Product Deck: not changed.
- Service Deck: not changed.
- Iteration Plan: not changed.
- OBC: not changed.
- BDD Feature: not changed.
- Risks: not changed.

### Validation

- Exclusively documentary change; no application code or tests affected.
- Internal links of the 10 changed files verified — all resolve (`python3` check, exit 0).
- No path renames, no contract breaks.

## 2026-07-13 — Mode alignment, readiness and CI Sync

### Summary

Aligned the ProdOps model to distinguish execution mode from journey and prepare the closure of Claude CI Sync automation.

### Decisions implemented

- `/downstream` now offers `ci-sync`, `ci-async` and `full`; while CI Async is evolving, absence of scope defaults to `ci-sync` and informs the default.
- Upstream is permissive, experimental and without delivery commitment; Downstream has commitment, guides the item to readiness and only executes Delivery with all gates satisfied.
- OBC is born as Draft at the Business Intent Backlog (global flow) or Product Intent Backlog (local flow), refined through Discovery in the Icebox until reaching Minimum OBC, becomes Active during Delivery and Operational in Operation.
- Assessment is cross-cutting and produces risks and Reliability Plan before commitment in the Iteration Plan.
- Discovery exists in Upstream and Downstream; it is not synonymous with Upstream.
- Bootstrap only prepares dependencies, local infrastructure, configuration and smoke gate.
- Downstream readiness generates the context capsule; Hack Start decides branch and Git flow.

### Deferred

- Operational detail of the Assessment and Diligence journeys.
- Complete rigor matrix by journey and mode.
- Remaining manifest, doctor, test policy and CI Async automation adjustments.

### Validation

- `prodops/scripts/validate-manifest.sh`: passed.
- `git diff --check`: passed.
- Changes exclusively in documentation and agent orchestration; application code was not changed.
