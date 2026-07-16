# Payments API — ProdOps University Reference Project

Payments API is a reference project from [ProdOps University](https://prodops.university/) that demonstrates how code, contracts, specifications, observability, reliability, operation, and product artifacts connect in the evolution of a digital product.

→ **ProdOps Framework documentation:** [prodops/README.en.md](prodops/README.en.md)

> **Language note:** This project is authored in Portuguese. See [why this project is in Portuguese](prodops/language.md).

---

## Quick Start

### Prerequisites

- Node.js 22+
- Docker (for LocalStack)
- AWS SAM CLI
- `jq` (for simulation scripts)

### Run locally

```bash
# Install dependencies
cd api && npm ci && cp .env.example .env

# Fast sandbox mode (in-memory, mocked Asaas, port 3011)
cd api && ./scripts/start-sandbox-api.sh

# Validation Workbench (in another terminal)
cd validation-workbench && npm ci && npm run dev
# → http://localhost:5173/
```

### Run tests

```bash
cd api && npm run test              # unit tests
cd api && npm run test:acceptance   # acceptance tests
cd api && npm run lint              # lint + format check
./scripts/test-acceptance.sh        # acceptance tests (requires LocalStack)
```

### Set up Commit Workflow

```bash
git config core.hooksPath prodops/journeys/delivery/capabilities/commit-workflow/hooks
```

### Additional modes

| Mode | Script |
|---|---|
| Real Asaas sandbox | `api/scripts/start-asaas-sandbox-real.sh` |
| NestJS + LocalStack/DynamoDB | `api/scripts/start-localstack-api.sh` |
| SAM + LocalStack serverless | `api/scripts/build.sh` + `api/scripts/deploy.sh` |

For details on each mode, environment variables and Datadog instrumentation: see the README git history before this refactor or `api/scripts/`.

---

## Repository structure

```
api/                NestJS API — backend (port 3011)
prodops/            ProdOps Framework — artifacts, flows, documentation, skills
scripts/            Setup, deploy and test scripts
validation-workbench/  Upstream workbench for validating flows (port 5173)
```

---

## ProdOps Framework

This repository materializes the ProdOps Framework. To understand how the framework is organized, read in order:

1. [prodops/README.en.md](prodops/README.en.md) — portal and navigation map
2. [prodops/framework/principles.en.md](prodops/framework/principles.en.md) — principles
3. [prodops/journeys/delivery/README.en.md](prodops/journeys/delivery/README.en.md) — CI Sync and CI Async

---

## License and Usage

Educational project from ProdOps University. Does not represent a production-ready solution.

Apache License 2.0 — see [LICENSE](LICENSE).
