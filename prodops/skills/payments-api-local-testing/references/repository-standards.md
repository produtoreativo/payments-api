# Repository Standards

Use these standards to keep prompt iterations and code changes aligned with this repository.

## Stack

- Backend lives in `api/`.
- Backend framework: NestJS 11 with TypeScript 5.7.
- Backend runtime targets Node.js 22 in CI.
- HTTP server entrypoint: `api/src/main.ts`.
- Lambda/serverless entrypoint: `api/src/lambda.ts`.
- Local Validation Workbench lives in `validation-workbench/`.
- Frontend framework: Vite 6, React 19, TypeScript, `lucide-react`.
- Tests use Jest, `ts-jest`, and Supertest.
- Formatting/linting use Prettier and ESLint flat config in `api/eslint.config.mjs`.
- Infra uses AWS SAM YAML, AWS SDK v3, Localstack-oriented scripts, and Terraform/Kong/Keycloak under `api/infra/iac`.

## Backend Shape

- Keep NestJS modules organized as controller + service + DTO + type files.
- The current domain module is `api/src/modules/invoices`.
- `InvoiceController` owns `POST /invoices` and delegates to `InvoiceService`.
- `AppController` still owns legacy/general routes: `POST /payments`, `POST /webhook/payments`, `GET /queue/process`, `POST /keycloak-test`.
- Put provider-facing Asaas integration in `api/src/infra/asaas.service.ts`.
- Put DynamoDB access in `api/src/infra/dynamo.service.ts`.
- Put provider selection in `ProviderRouterService`; do not duplicate provider enablement logic elsewhere.

## Payment Domain Rules

- Prefer `/invoices` for the current payment flow.
- Keep `/payments` compatible because the Validation Workbench can still exercise it.
- `CreateInvoiceDto` is the source of truth for invoice payload shape.
- `CreatePaymentDto` is the source of truth for legacy payment-link payload shape.
- Supported providers are the `PaymentProvider` union: `ASAAS` and `ITAU`.
- `ITAU` is declared but intentionally not implemented in this gateway.
- Provider routing must respect `ENABLED_PAYMENT_PROVIDERS` and `DEFAULT_PAYMENT_PROVIDER`.
- Invoice statuses must use the `InvoiceStatus` union in `invoice.types.ts`.
- Billing types must use `BOLETO`, `PIX`, `CREDIT_CARD`, or `UNDEFINED`.

## Event and Observability Pattern

- Preserve existing event naming families:
  - Internal events use names like `payments.invoice.created`.
  - Observable/business events use Portuguese dotted names like `pagamento.processamento.pagamentos.fatura.criada`.
- Preserve correlation support through `X-Correlation-Id`.
- Preserve idempotency through `Idempotency-Key` on `POST /invoices`.
- Keep the invoice flow sequence: create invoice record, emit payment intention, resolve/create provider customer, create provider charge, update invoice to `OPEN`, emit final created/opened events.

## Storage Pattern

- `InvoiceRepository` supports memory and Dynamo modes through `INVOICE_REPOSITORY`.
- `INVOICE_REPOSITORY=memory` is the default for sandbox and CI acceptance flow.
- Dynamo items use partition/sort keys such as `TENANT#...`, `INVOICE#...`, `PAYMENT#...`, `IDEMPOTENCY#...`.
- Local sandbox can use `DYNAMO_MOCK=true` to avoid Localstack for legacy `/payments`.
- Do not make production behavior silently depend on in-memory storage or mocks.

## Local Runtime Pattern

- Use `api/scripts/start-sandbox-api.sh` for local backend validation.
- Local backend default: `http://localhost:3011`.
- Local frontend default: `http://localhost:5173`.
- Sandbox should set `ASAAS_MOCK=true`, `DYNAMO_MOCK=true`, `INVOICE_REPOSITORY=memory`, `ENABLED_PAYMENT_PROVIDERS=ASAAS`, and `DEFAULT_PAYMENT_PROVIDER=ASAAS`.
- Browser validation requires CORS preflight for `Content-Type`, `Idempotency-Key`, `X-Correlation-Id`, and `X-Tenant-Id` when using invoice cancellation.

## Validation Workbench Pattern

- Keep the Validation Workbench under `validation-workbench/`; do not move it into `api/`.
- Keep payload generation derived from cart state.
- Keep a JSON editor path so testers can adjust payloads before sending.
- Invoice mode posts to `/invoices` and sends idempotency/correlation headers.
- Payments mode posts to `/payments` without invoice headers.
- Keep UI dependencies minimal and aligned with Vite, React, TypeScript, and `lucide-react`.

## Validation Pattern

- Backend build: `cd api && npm run build`.
- Backend acceptance test: `cd api && npm run test:acceptance` (requires LocalStack running).
- Frontend build: `cd validation-workbench && npm run build`.
- Local payload smoke test: `prodops/skills/payments-api-local-testing/scripts/validate-local-payloads.sh`.
- CI acceptance tests run against LocalStack (real DynamoDB API) with `ASAAS_MOCK=true`.
- Local acceptance test setup: `./scripts/test-acceptance.sh` (starts LocalStack if needed, sets env vars, runs Jest).

## Acceptance Test Rules

These rules apply to everything under `api/test/` and are enforced by `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`.

**No test doubles.** `jest.fn()` as a service replacement, `jest.spyOn(...).mockXxx()`, and `.overrideProvider()` are prohibited. Tests must use the real NestJS application with the real service instances.

**`ASAAS_MOCK=true` is the Asaas boundary.** The real `AsaasService` is instantiated. The env flag controls which internal branch runs (mock returns / real HTTP). This is a designed service mode, not a test double.

**Real DynamoDB.** LocalStack provides a real DynamoDB-compatible API. `INVOICE_REPOSITORY=memory` and `DYNAMO_MOCK=true` must not appear in acceptance test setup.

**Shared app per file.** `beforeAll` creates the app once; `afterAll` tears it down; `beforeEach` truncates DynamoDB tables. App recreation per test is prohibited.

**Error injection is a unit test concern.** Forcing provider failures (timeouts, bad responses) requires replacing real behavior and therefore belongs in service-layer unit tests, not acceptance specs.

## Prompt Guardrails

- Read source files before proposing new architecture.
- Prefer existing DTOs, event names, env vars, scripts, and service boundaries.
- Do not invent payment fields outside the DTOs unless the user asks for a contract change.
- Do not invent new providers beyond `ASAAS` and `ITAU`; `ITAU` must remain not implemented unless explicitly requested.
- Do not replace the existing NestJS/EventEmitter/Repository pattern with a different architecture for small fixes.
- Do not require Localstack or real Asaas credentials for local frontend/backend validation unless the user explicitly asks for integration testing.
- When updating skills or prompts, keep long operational rules in `references/` and keep `openai.yaml` limited to UI metadata and the default invocation prompt.
