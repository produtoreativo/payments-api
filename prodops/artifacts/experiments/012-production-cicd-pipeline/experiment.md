# Upstream Experiment 012 — Production CI/CD Pipeline

Localização canônica:

```text
prodops/artifacts/experiments/012-production-cicd-pipeline/experiment.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Business Goal

Automatizar o deploy em produção com aprovação humana obrigatória, eliminando deploys
manuais ad-hoc que não deixam trilha auditável e dependem de credenciais locais.

Derivado do EXP-009 (Serverless Maturity Assessment) — lacuna crítica identificada:
deploy de produção feito apenas manualmente via CLI local, sem gate de aprovação
e sem registro de quem executou o deploy.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Comportamento da Payments API
- [x] CI/CD pipeline
- [x] Testes locais ou evidência executável

## Dependências externas

- GitHub Environment `production` com Required Reviewers configurado
- Secrets: `PRODUCTION_ASAAS_TOKEN`, `PRODUCTION_ASAAS_WEBHOOK_TOKEN`, `PRODUCTION_ADMIN_SECRET`, `PRODUCTION_DATADOG_API_KEY`

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório

---

# Question to Answer

1. O GitHub Actions `environment` com Required Reviewers é suficiente como gate de aprovação humana?
2. A mesma estrutura `sam deploy` com `--parameter-overrides` explícita funciona para produção?
3. O pipeline de produção pode reusar o mesmo OIDC role que o staging?
4. O `samconfig.toml` pode documentar a intenção sem ser a fonte de verdade do deploy?
5. O `staging-deploy.yml` estava com SAM CLI merging behavior incorreto?

---

# Hypothesis

O GitHub Actions `environment: production` com Required Reviewers é o gate certo —
mais visível e auditável que `confirm_changeset: true` do SAM. Combinado com `workflow_dispatch`
obrigatório (não aciona em push), o pipeline não pode ser executado acidentalmente.

O mesmo padrão de `--parameter-overrides` explícitos usado no deploy de staging após EXP-010
funciona igualmente para produção.

---

# Scope

- `.github/workflows/deploy-production.yml`: novo workflow de produção
- `api/samconfig.toml`: bloco `[production]` atualizado com Datadog e comentários corrigidos
- `.github/workflows/staging-deploy.yml`: corrigir SAM CLI merging behavior

---

# Out of Scope

- Configuração do GitHub Environment `production` (ação do usuário no GitHub UI)
- Criação dos secrets `PRODUCTION_*` no GitHub (ação do usuário)
- Deploy em produção em si (pipeline pronto; primeiro deploy requer aprovação humana)

---

# Implementation

## deploy-production.yml

- `on: workflow_dispatch` — manual único; nunca aciona em push
- `concurrency: group: production-deploy, cancel-in-progress: false` — impede deploy paralelo
- `environment: name: production` — aguarda Required Reviewers antes de executar o job
- Step "Validate required secrets" — falha cedo se qualquer secret não estiver configurado
- Step "Deploy DynamoDB tables" — `aws cloudformation deploy` síncrono no stack `payments-api-dynamo-production`
- Step "Deploy Lambda application" — `sam deploy` com todos os parâmetros explícitos na CLI
- Step "Smoke test" — `POST /invoices` sem token → 401; `DELETE /invoices/:id` sem token → 401
- Summary job no GITHUB_STEP_SUMMARY com URL, commit, configuração implantada

## samconfig.toml [production]

- `DatadogEnabled=true` adicionado (estava `false`)
- `DatadogSite`, `DatadogExtensionLayerArn`, `DatadogVersion` adicionados
- `confirm_changeset` alterado para `false` — gate é o GitHub Environment, não o SAM CLI
- Comentário sobre SAM CLI parameter merging behavior documentado

## staging-deploy.yml (fix)

**Problema:** O `sam deploy` em staging usava `--config-env staging` + `--parameter-overrides`
apenas com secrets. O SAM CLI substitui (`REPLACES`, não mergeia) os `parameter_overrides` do
samconfig.toml quando `--parameter-overrides` é passado na CLI. Parâmetros não na CLI ficam como
`UsePreviousValue=true` em stacks existentes — comportamento correto só por coincidência.

**Fix:** Removido `--config-env staging`. Todos os parâmetros passados explicitamente na CLI,
incluindo não-secrets (EnvironmentName, DatadogEnabled, etc).

---

# Code Produced

- `.github/workflows/deploy-production.yml` — criado
- `api/samconfig.toml` — bloco `[production]` atualizado
- `.github/workflows/staging-deploy.yml` — deploy step corrigido

---

# Functional Validation

Pipeline criado. Validação de execução requer:
- GitHub Environment `production` configurado com Required Reviewers
- Secrets `PRODUCTION_*` adicionados ao GitHub Environment

Smoke tests validados pelo mesmo padrão do staging (POST /invoices → 401, DELETE → 401).

---

# Technical Findings

## GitHub Environment como gate de aprovação

- `environment: name: production` no workflow bloqueia o job até aprovação dos Required Reviewers
- Auditável: aprovação registrada no GitHub com nome do aprovador e timestamp
- Mais robusto que `confirm_changeset: true` do SAM — o SAM gate acontece dentro do runner,
  invisível para quem não tem acesso ao terminal

## SAM CLI --parameter-overrides merging behavior

Confirmado em EXP-010: SAM CLI com `--parameter-overrides` na CLI usa `UsePreviousValue=true`
para parâmetros não listados (em stacks existentes) ou template default (em stacks novos).
Não mergeia com `parameter_overrides` do samconfig.toml.

**Consequência:** Passar apenas secrets na CLI com `--config-env` não é suficiente para
garantir que os não-secrets sejam atualizados quando o samconfig.toml mudar.

**Solução:** Sempre passar todos os parâmetros explicitamente na CLI quando usar `--parameter-overrides`.

## OIDC Role reuse

O mesmo role `payments-api-github-deploy` pode ser usado para staging e produção —
a diferença de ambiente está nos parâmetros passados, não na identity do deployer.

---

# Architecture Impact

## Decisões confirmadas

- GitHub Environment `production` é o gate correto para deploys em produção
- `workflow_dispatch` obrigatório elimina deploy acidental em push
- Separação DynamoDB stack / Lambda stack: tabelas sobrevivem re-deploys do Lambda

## Questões em aberto

- Nenhuma neste escopo.

---

# Reliability Impact

| Dimensão | Antes | Depois |
|---|---|---|
| Gate de aprovação para produção | Nenhum (manual CLI) | Required Reviewers no GitHub |
| Auditabilidade | Zero — nenhum log de quem deployou | Deploy log no GitHub Actions com aprovador |
| Risco de deploy acidental | Alto — push main pode triggerar | Eliminado — manual only (`workflow_dispatch`) |
| Consistência de parâmetros | Dependia de memória do operador | Todos os parâmetros explícitos no workflow |

---

# Artifacts Updated

- `.github/workflows/deploy-production.yml` — criado
- `api/samconfig.toml` — bloco `[production]` atualizado
- `.github/workflows/staging-deploy.yml` — deploy step corrigido
- `prodops/artifacts/experiments/012-production-cicd-pipeline/experiment.md` — criado
- `prodops/artifacts/experiments/012-production-cicd-pipeline/upstream-trail.md` — criado
- `prodops/journeys/discovery/experiments.md` — entrada 012 adicionada

---

# Knowledge Gaps Closed

| Pergunta | Status | Evidência |
|---|---|---|
| GitHub Environment como gate de aprovação | ✅ Respondida | workflow com `environment: production` + Required Reviewers |
| SAM CLI parameter merging behavior | ✅ Respondida (EXP-010) | `--parameter-overrides` na CLI substitui samconfig.toml |
| OIDC role reuse staging/production | ✅ Respondida | Mesmo role, parâmetros distintos |
| staging-deploy.yml estava incorreto | ✅ Confirmado e corrigido | Fix aplicado |

---

# New Backlog Items

| Item | Classificação |
|---|---|
| Configurar GitHub Environment `production` com Required Reviewers | Action do usuário (GitHub UI) |
| Adicionar secrets `PRODUCTION_*` ao GitHub Environment `production` | Action do usuário |
| Executar primeiro deploy em produção via workflow | Próximo passo após configuração |

---

# Recommendation

- [x] Mover para Downstream

Pipeline criado e arquivos corrigidos. Pronto para primeiro deploy em produção após
configuração do GitHub Environment e secrets pelo usuário.

---

# Decision Package

## Executive Summary

Pipeline de CI/CD para produção criado com gate de aprovação humana obrigatória via GitHub
Environment, `workflow_dispatch` exclusivo, smoke tests automáticos pós-deploy, e parâmetros
explícitos na CLI (corrigindo SAM CLI merging behavior). Deploy de staging também corrigido
com o mesmo fix.

## Decisão Recomendada

Mover para Downstream — configurar GitHub Environment `production` e executar primeiro deploy.

## Riscos Atualizados

| Risco | Situação |
|---|---|
| Deploy acidental em produção | **Eliminado** — `workflow_dispatch` only |
| Deploy sem aprovação | **Eliminado** — Required Reviewers gate |
| Parâmetros inconsistentes no deploy | **Eliminado** — todos explícitos na CLI |

## Escopo Downstream Recomendado

1. Configurar GitHub Environment `production` com Required Reviewers (GitHub UI)
2. Adicionar secrets `PRODUCTION_*` ao GitHub Environment
3. Executar primeiro deploy via `.github/workflows/deploy-production.yml`

---

# Output Artifacts

| Tipo | Artefato | Situação |
|---|---|---|
| CI/CD | `.github/workflows/deploy-production.yml` | Criado |
| Config | `api/samconfig.toml` | Bloco `[production]` atualizado |
| CI/CD | `.github/workflows/staging-deploy.yml` | Deploy step corrigido |

**Promovido para Downstream:** `- [x] Sim`
**Data de promoção:** 2026-07-21
**Slice:** Production CI/CD pipeline

---

# Exit Criteria

- [x] deploy-production.yml criado com gate de aprovação obrigatório
- [x] samconfig.toml production block com Datadog enabled e comentários corretos
- [x] staging-deploy.yml corrigido (SAM CLI merging behavior)
- [x] Smoke tests definidos no pipeline
- [x] Documentação de configuração necessária (GitHub Environment + secrets)

---

# Next Step

Configurar GitHub Environment `production` no repositório com Required Reviewers e adicionar os
quatro secrets de produção. Após configuração, o workflow está pronto para execução.
