# Mocking Policy — No Mocks Rule

> **Authority hierarchy:**
> - Enforcement gate (what blocks merge): [`journeys/delivery/phases/finish/quality-gates.md`](../../../../framework/journeys/delivery/phases/finish/quality-gates.md)
> - Canonical technical definition: [`prodops/skills/hack/references/workflow.md § No Mocks Rule`](../../../hack/references/workflow.md)
> - This file: engineering reference — consolidates the policy with examples and Yellow Bar patterns

---

## Prohibited in `api/test/`

The following patterns are **banned** and block merge when found in any file under `api/test/`:

```typescript
// BANNED — service replacement via jest.fn()
const invoiceService = { create: jest.fn().mockResolvedValue({ invoiceId: '123' }) };

// BANNED — spyOn with mock implementation
jest.spyOn(asaasService, 'createCharge').mockResolvedValue({ id: 'asaas-001' });
jest.spyOn(invoiceRepository, 'findById').mockReturnValue(null);
jest.spyOn(logger, 'error').mockImplementation(() => {});

// BANNED — overrideProvider in test module
Test.createTestingModule({ imports: [AppModule] })
  .overrideProvider(InvoiceService)
  .useValue({ create: jest.fn() })
  .compile();
```

**Why:** These patterns substitute real owned code with stubs. They allow the test to pass while
the real integration is broken. A mock on `InvoiceRepository` hides whether the DynamoDB call
works, which attributes are stored, or whether the GSI query returns the right items.

---

## Permitted

### `ASAAS_MOCK=true`

This is **not a mock** — it is a designed behavior mode of the real `AsaasService`. When the env
var is set, the real service is instantiated and runs its real code path, which internally branches
to return deterministic data without calling the Asaas API. Use it in all acceptance specs.

```bash
ASAAS_MOCK=true ./scripts/test-acceptance.sh
```

### Mock Servers Based on Published Contracts

Temporary infrastructure that simulates an external system using its OpenAPI or AsyncAPI contract
(e.g., WireMock, Prism). These are infrastructure stubs, not code-level mocks, and are acceptable
while the real system is unavailable in the test environment.

### Yellow Bar Mock Object — Technical Dependencies Only

In unit tests, Mock Objects are acceptable **only for technical dependencies** that do not carry
business logic:

```typescript
// PERMITTED — logger is a technical dep, not business logic
const logger = { log: jest.fn(), error: jest.fn(), warn: jest.fn() };

// PERMITTED — clock abstraction for deterministic time in unit tests
const clock = { now: jest.fn().mockReturnValue(new Date('2025-01-01')) };

// PERMITTED — UUID generator for predictable IDs in unit tests
const uuidGenerator = { generate: jest.fn().mockReturnValue('fixed-uuid-001') };
```

**Rule:** A Mock Object is acceptable only when it does not hide business behavior. If the mock
substitutes logic that real code would execute differently, it hides a defect.

---

## Enforcement

Quality gate runs on every PR. Any `jest.fn()`, `spyOn(...).mock*`, or `.overrideProvider()` found
in `api/test/` **blocks merge**, no exceptions. Fix by writing a real integration test or moving
the scenario to a unit test in `api/src/`.
