[English](README.en.md)

# Payments API — Implementação de Referência do ProdOps Framework

> **Este repositório é uma RI (Referência de Implementação) do [ProdOps Framework](prodops/framework/README.md).**
> O produto (Payments API) é o veículo — o objetivo é demonstrar o Framework em operação real.
> Se você quer entender o produto, comece por `api/`. Se quer entender o Framework, comece por `prodops/`.

> **Status do Framework:** O Framework já tem repositório canônico em [produtoreativo/prodops-framework](https://github.com/produtoreativo/prodops-framework) com instalador para qualquer repo. Por enquanto, Framework e Runtime são desenvolvidos aqui na RI e no repo canônico em paralelo — sincronizados a cada alteração — enquanto o conteúdo amadurece para Release Candidate. Quando o RC for declarado, esta RI passa a ser consumidora pura.
>
> → Repo canônico: [produtoreativo/prodops-framework](https://github.com/produtoreativo/prodops-framework)
> → Última release: [v1.3.0](https://github.com/produtoreativo/prodops-framework/releases/tag/v1.3.0)
> → Instalar em um novo repo: `bash <(curl -fsSL https://raw.githubusercontent.com/produtoreativo/prodops-framework/master/prodops/scripts/install-prodops.sh) --version v1.3.0`
> → Esta RI: [produtoreativo/payments-api](https://github.com/produtoreativo/payments-api)

Payments API é um projeto de referência da [ProdOps University](https://prodops.university/) que demonstra como código, contratos, especificações, observabilidade, confiabilidade, operação e artefatos de produto se conectam na evolução de um produto digital — seguindo o ProdOps Framework do início ao fim.

→ **Framework ProdOps:** [prodops/README.md](prodops/README.md)
→ **Filosofia de contribuição:** [prodops/framework/contributor-philosophy.md](prodops/framework/contributor-philosophy.md)

---

## Início Rápido

### Pré-requisitos

- Node.js 22+
- Docker (para LocalStack)
- AWS SAM CLI
- `jq` (para scripts de simulação)

### Executar localmente

```bash
# Instalar dependências
cd api && npm ci && cp .env.example .env

# Modo sandbox rápido (memória, Asaas mockado, porta 3011)
cd api && ./scripts/start-sandbox-api.sh

# Validation Workbench (em outro terminal)
cd validation-workbench && npm ci && npm run dev
# → http://localhost:5173/
```

### Executar testes

```bash
cd api && npm run test              # unit tests
cd api && npm run test:acceptance   # acceptance tests
cd api && npm run lint              # lint + format check
./scripts/test-acceptance.sh        # acceptance tests (requer LocalStack)
```

### Configurar Commit Workflow

```bash
git config core.hooksPath prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
```

### Modos adicionais

| Modo | Script |
|---|---|
| Sandbox real Asaas | `api/scripts/start-asaas-sandbox-real.sh` |
| NestJS + LocalStack/DynamoDB | `api/scripts/start-localstack-api.sh` |
| SAM + LocalStack serverless | `api/scripts/build.sh` + `api/scripts/deploy.sh` |

Para detalhes de cada modo, variáveis de ambiente e instrumentação Datadog: ver histórico do README antes desta refatoração ou `api/scripts/`.

---

## Estrutura do repositório

```
api/                NestJS API — backend (porta 3011)
prodops/            Framework ProdOps — artefatos, fluxos, documentação, skills
scripts/            Scripts de setup, deploy e testes
validation-workbench/  Bancada Upstream para validar fluxos (porta 5173)
```

---

## ProdOps Framework

Este repositório materializa o Framework ProdOps. Para entender como o framework está organizado, ler em ordem:

1. [prodops/README.md](prodops/README.md) — portal e mapa de navegação
2. [prodops/framework/principles.md](prodops/framework/principles.md) — princípios
3. [prodops/framework/journeys/delivery/README.md](prodops/framework/journeys/delivery/README.md) — CI Sync e CI Async

---

## Licença e Uso

Projeto educacional da ProdOps University. Não representa solução pronta para produção.

Apache License 2.0 — ver [LICENSE](LICENSE).
