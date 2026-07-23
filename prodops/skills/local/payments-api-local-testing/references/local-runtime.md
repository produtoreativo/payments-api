# Local Runtime

## Processes

Run the backend sandbox from the API directory:

```sh
cd api
./scripts/start-sandbox-api.sh
```

Run the Validation Workbench:

```sh
cd validation-workbench
npm run dev
```

## Defaults

- Backend: `http://localhost:3011`
- Frontend: `http://localhost:5173`
- Repository sandbox script should set:
  - `PORT=3011`
  - `INVOICE_REPOSITORY=memory`
  - `DYNAMO_MOCK=true`
  - `ASAAS_MOCK=true`
  - `ENABLED_PAYMENT_PROVIDERS=ASAAS`
  - `DEFAULT_PAYMENT_PROVIDER=ASAAS`

## Validation Commands

Build backend:

```sh
cd api
npm run build
```

Build frontend:

```sh
cd validation-workbench
npm run build
```

Smoke-test payloads:

```sh
prodops/skills/local/payments-api-local-testing/scripts/validate-local-payloads.sh
```

Override API URL:

```sh
API_URL=http://localhost:3011 prodops/skills/local/payments-api-local-testing/scripts/validate-local-payloads.sh
```

## Common Failures

- `ECONNREFUSED 127.0.0.1:4566`: backend tried to use Localstack/DynamoDB; use sandbox env mocks unless testing infrastructure.
- Browser CORS error: run an `OPTIONS` check for `/invoices` or `/payments` with `Origin: http://localhost:5173`.
- Provider failure: verify `ASAAS_MOCK=true` for local sandbox, or validate real `ASAAS_TOKEN` and `ASAAS_URL` only when doing external integration tests.
