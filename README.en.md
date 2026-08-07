# Payments API — ProdOps Framework Reference Implementation

> **This repository is a Reference Implementation (RI) of the [ProdOps Framework](prodops/framework/README.en.md).**
> The product (Payments API) is the vehicle — the goal is to demonstrate the Framework running on real infrastructure.
> If you want to understand the product, start with `api/`. If you want to understand the Framework, start with `prodops/`.

> **Framework status:** The Framework already has its canonical repository at [produtoreativo/prodops-framework](https://github.com/produtoreativo/prodops-framework) with an installer for any repo. For now, Framework and Runtime are being developed here in the RI and in the canonical repo in parallel — synchronized at every change — while the content matures toward Release Candidate. Once RC is declared, this RI becomes a pure consumer.
>
> → Canonical repo: [produtoreativo/prodops-framework](https://github.com/produtoreativo/prodops-framework)
> → Latest release: [v1.3.0](https://github.com/produtoreativo/prodops-framework/releases/tag/v1.3.0)
> → Install in a new repo: `bash <(curl -fsSL https://raw.githubusercontent.com/produtoreativo/prodops-framework/master/prodops/scripts/install-prodops.sh) --version v1.3.0`
> → This RI: [produtoreativo/payments-api](https://github.com/produtoreativo/payments-api)

Payments API is a reference project from [ProdOps University](https://prodops.university/) that demonstrates how code, contracts, specifications, observability, reliability, operation, and product artifacts connect in the evolution of a digital product — following the ProdOps Framework end to end.

→ **ProdOps Framework:** [prodops/README.en.md](prodops/README.en.md)
→ **Contributor philosophy:** [prodops/framework/contributor-philosophy.en.md](prodops/framework/contributor-philosophy.en.md)

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
git config core.hooksPath prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
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
3. [prodops/framework/journeys/delivery/README.en.md](prodops/framework/journeys/delivery/README.en.md) — CI Sync and CI Async

---

## License and Usage

Educational project from ProdOps University. Does not represent a production-ready solution.

Apache License 2.0 — see [LICENSE](LICENSE).
