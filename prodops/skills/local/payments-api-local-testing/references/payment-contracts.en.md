# Payment Contracts

## POST /invoices

Controller: `api/src/modules/invoices/controllers/invoice.controller.ts`

Headers:

- `Content-Type: application/json`
- `Idempotency-Key: <order-id>:create`
- `X-Correlation-Id: frontend-<order-id>` optional but recommended

Payload:

```json
{
  "tenantId": "magazine-siara",
  "orderId": "MS-TEST-123",
  "customer": {
    "id": "customer-MS-TEST-123",
    "name": "Cliente Sandbox Magazine Siara",
    "document": "11144477735",
    "email": "sandbox@example.com",
    "mobilePhone": "11987654321"
  },
  "amount": 109.7,
  "currency": "BRL",
  "dueDate": "2026-07-04",
  "billingType": "PIX",
  "provider": "ASAAS",
  "description": "Pedido MS-TEST-123: 1x Camiseta ProdOps, 2x Adesivo Reliability"
}
```

Expected local response:

- HTTP `201`
- `status: "OPEN"`
- `provider: "ASAAS"`
- `providerPaymentId` starts with `pay_mock_` when `ASAAS_MOCK=true`
- `paymentUrl` is present

## POST /payments

Controller: `api/src/app.controller.ts`

Headers:

- `Content-Type: application/json`

Payload:

```json
{
  "tenantId": "magazine-siara",
  "amount": 109.7,
  "description": "Pedido MS-TEST-123: 1x Camiseta ProdOps, 2x Adesivo Reliability",
  "customer": {
    "externalId": "external-sandbox-001",
    "name": "Cliente Sandbox Magazine Siara",
    "email": "sandbox@example.com",
    "cpfCnpj": "11144477735"
  }
}
```

Expected local response:

- HTTP `201`
- `PK` starts with `TENANT#`
- `SK` starts with `PAYMENT#`
- `status: "ACTIVE"` when `ASAAS_MOCK=true`
- `asaasPaymentId` starts with `plink_mock_` when `ASAAS_MOCK=true`

## Frontend Mapping

The Vite tester in `validation-workbench/src/App.tsx` derives both payloads from the same cart state:

- Cart total maps to `amount`.
- Item summary maps to `description`.
- Invoice mode sends `/invoices` plus idempotency and correlation headers.
- Payments mode sends `/payments` without idempotency headers.
