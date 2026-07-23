---
name: payments-api-local-testing
description: Validate, debug, and modify this repository's payment sandbox without drifting from existing architecture. Use when Codex needs to run the payments-api backend and Vite Validation Workbench, build or inspect payment payloads, validate POST /invoices or POST /payments, diagnose CORS/provider/storage failures, update prompts/skill metadata, or make changes that must follow the repo's NestJS, event, provider, storage, testing, and Vite patterns.
---

# Payments API Local Testing

## Workflow

1. Confirm the repo root is `payments-api`.
2. Read `references/repository-standards.md` before making code, prompt, skill, or metadata changes.
3. Read `references/local-runtime.md` before starting or debugging local processes.
4. Read `references/payment-contracts.md` before changing payloads, DTOs, frontend fields, or validation scripts.
5. Prefer the sandbox script over ad hoc commands:
   ```sh
   cd api
   ./scripts/start-sandbox-api.sh
   ```
6. Validate from the browser path, not only from backend unit assumptions. CORS preflight must succeed for frontend testing.
7. When the task is payload validation, run:
   ```sh
   prodops/skills/local/payments-api-local-testing/scripts/validate-local-payloads.sh
   ```

## Local Expectations

- Frontend default URL: `http://localhost:5173/`.
- Backend sandbox default URL: `http://localhost:3011`.
- Sandbox execution should avoid requiring Localstack or real Asaas calls unless the user explicitly asks for integrated infrastructure.
- For local validation, `POST /invoices` and `POST /payments` should both return `201`.
- CORS `OPTIONS` checks should return `204` for browser-origin requests from `http://localhost:5173`.

## Debugging Rules

- If `/payments` fails with `ECONNREFUSED 127.0.0.1:4566`, inspect Dynamo/local storage configuration before changing frontend payloads.
- If `/invoices` fails at provider creation, check `ASAAS_MOCK`, `ENABLED_PAYMENT_PROVIDERS`, and `DEFAULT_PAYMENT_PROVIDER`.
- If browser requests fail while curl POST works, validate `OPTIONS` preflight and allowed headers.
- Keep local mocks explicit and scoped to sandbox scripts or env flags. Do not make production defaults silently mock external systems.
- Do not invent new endpoints, providers, events, storage tables, or frontend fields when an existing DTO, service, env flag, or reference contract covers the task.

## Resources

- `references/repository-standards.md`: stack, architecture, naming, validation, and prompt guardrails extracted from this repo.
- `references/local-runtime.md`: commands, ports, env vars, and local process expectations.
- `references/payment-contracts.md`: request shapes for `POST /invoices` and `POST /payments`.
- `scripts/validate-local-payloads.sh`: deterministic smoke test for CORS, invoices, and payments.
