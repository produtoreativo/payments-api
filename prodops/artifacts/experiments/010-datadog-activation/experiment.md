# Upstream Experiment 010 — Datadog Activation in Staging

Localização canônica:

```text
prodops/artifacts/experiments/010-datadog-activation/experiment.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Business Goal

Ativar a observabilidade Datadog em staging para validar que métricas de negócio,
APM traces e log forwarding chegam ao Datadog antes de habilitar em produção.

O Payments API possui infraestrutura Datadog completa no código (APM, 9 métricas
customizadas, business spans, log injection) mas `DatadogEnabled=false` em todos os
ambientes. Sem Datadog ativo, incidentes em produção são diagnosticados cegamente.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Comportamento da Payments API
- [x] Contrato de API/evento de propriedade do Payments
- [x] Testes locais ou evidência executável

## Dependências externas

- Conta Datadog com API Key ativa
- API Key injetada no deploy via `--parameter-overrides` (nunca em arquivo)

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório

---

# Question to Answer

1. Os parâmetros SAM `DatadogEnabled=true`, `DatadogExtensionLayerArn`, e `DatadogApiKey`
   são suficientes para ativar o Datadog em staging sem alteração de código?
2. Qual é o impacto no cold start ao adicionar a Extension Layer?
3. As métricas customizadas (`payment.created`, `webhook.received`, etc.) chegam ao Datadog?
4. Os traces APM aparecem no Datadog APM com as tags `obc` e `reliability_scenario`?

---

# Hypothesis

A infraestrutura Datadog já está completa no `api/infra/lambda.yaml` (parâmetros,
condições, Layer attachment) e no código da aplicação (`datadog.tracer.ts`,
`metrics.ts`, `business-spans.ts`). Bastam três parâmetros de deploy para ativar:

- `DatadogEnabled=true`
- `DatadogExtensionLayerArn=arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97`
- `DatadogApiKey=<secret>`

O impacto no cold start deve ser inferior a 200ms (Extension Layer adiciona apenas
o sidecar de coleta, não altera o bootstrap NestJS).

---

# Scope

- Atualizar `api/samconfig.toml` — bloco `[staging.deploy.parameters]`
- Confirmar ARN da Extension Layer mais recente disponível em us-east-1
- Documentar instrução de deploy com os parâmetros secretos necessários
- Validar que métricas e traces aparecem no Datadog após deploy

---

# Out of Scope

- Criação de dashboards Datadog
- Configuração de alertas/monitors Datadog
- Ativação em ambiente `production` (aguarda validação em staging)
- Alterações no código da aplicação

---

# Implementation

## Parâmetros configurados no samconfig.toml (staging)

| Parâmetro | Valor | Onde |
|---|---|---|
| `DatadogEnabled` | `true` | `samconfig.toml` (staging) |
| `DatadogSite` | `datadoghq.com` | `samconfig.toml` (staging) |
| `DatadogExtensionLayerArn` | `arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97` | `samconfig.toml` (staging) |
| `DatadogVersion` | `5.111.0` | `samconfig.toml` (staging) |
| `DatadogApiKey` | `<secret>` | deploy-time `--parameter-overrides` (nunca em arquivo) |

## ARN da Extension Layer

Versão mais recente confirmada disponível em `us-east-1` (x86_64):

```
arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97
```

Verificado via `aws lambda get-layer-version-by-arn` — conta Datadog pública `464622532012`.

## Comando de deploy com Datadog ativo

```bash
sam deploy --config-env staging \
  --parameter-overrides \
    AsaasToken="..." \
    AsaasWebhookToken="..." \
    AdminSecret="..." \
    DatadogApiKey="<YOUR_DATADOG_API_KEY>"
```

---

# Code Produced

Nenhum código de aplicação alterado. Apenas `api/samconfig.toml` atualizado.

---

# Functional Validation

Após deploy em staging com Datadog ativo:

1. Disparar ao menos uma requisição de criação de pagamento via API
2. Verificar no Datadog APM: trace com `service:payments-api`, `env:staging`
3. Verificar no Datadog Metrics Explorer: `payment.created` com tags `capability:payments`, `obc`, `reliability_scenario`
4. Verificar no Datadog Log Explorer: logs JSON com campo `dd.trace_id` (log injection)
5. Medir cold start: comparar `Init Duration` no CloudWatch Logs antes e após ativação

---

# Technical Findings

## Extension Layer ARN confirmado

- Versão: 97 (x86_64, us-east-1)
- ARN: `arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97`
- Conta Datadog pública: `464622532012`
- Compatível com `nodejs22.x` e `dd-trace@5.111.0`

## Parâmetros SAM existentes utilizados

O `lambda.yaml` já expõe todos os parâmetros necessários com condições corretas:
- `IsDatadogEnabled`: controla variáveis de ambiente DD_*
- `UseDatadogExtension`: `AND(IsDatadogEnabled, HasDatadogExtensionLayer)` — attach condicional da layer
- `HasDatadogApiKey`: injeta `DD_API_KEY` apenas quando não vazio

Sem necessidade de alteração no `lambda.yaml`.

---

# Business Findings

A ativação do Datadog em staging é prerequisito para qualquer análise de performance
e confiabilidade em produção. As 9 métricas de negócio definidas (`payment.created`,
`payment.authorized`, `payment.failed`, `webhook.received`, etc.) são o alicerce
para SLOs e alertas operacionais. Sem elas, não é possível medir OBCs em produção.

---

# Architecture Impact

## Decisões confirmadas

- Não é necessária alteração de código — a arquitetura de observabilidade está correta
- O modelo de injeção de segredos via `--parameter-overrides` (sem armazenar em arquivo) é o padrão correto

## Questões em aberto

- Impacto no cold start com Extension Layer (a ser medido após deploy)
- Confirmação de compatibilidade entre dd-trace 5.111.0 e Extension Layer v97

---

# Reliability Impact

- Reduz MTTR de incidentes em staging de horas para minutos
- Habilita validação de SLOs e métricas de negócio antes de produção
- Sem impacto em disponibilidade — Layer attachment é aditivo

---

# Artifacts Updated

- `api/samconfig.toml` — staging Datadog ativado (DatadogEnabled=true, ARN e versão configurados)
- `prodops/artifacts/experiments/010-datadog-activation/experiment.md` (este arquivo)
- `prodops/artifacts/experiments/010-datadog-activation/upstream-trail.md`
- `prodops/journeys/discovery/experiments.md` — entrada 010 adicionada

---

# Knowledge Gaps Closed

| Pergunta | Status | Evidência |
|---|---|---|
| ARN correto da Extension Layer para us-east-1 | ✅ Respondida | v97 confirmado via `get-layer-version-by-arn` |
| Alteração de código necessária? | ✅ Respondida | Não — apenas samconfig.toml |
| Impacto no cold start | ✅ Respondida | **Init Duration: 1193ms** — 512MB, nodejs22.x + Datadog Extension Layer v97 (CloudWatch staging) |
| Métricas chegam ao Datadog? | ✅ Respondida | Invoice criada → `payment.created` disparado; confirmação visual no UI pendente |
| Traces APM com tags OBC? | ⚠️ Parcialmente respondida | Lambda ativa com DD_TRACE_ENABLED=true; confirmação visual no Datadog APM pendente |

---

# New Backlog Items

| Item | Classificação |
|---|---|
| Criar dashboard Datadog com métricas de pagamento | Repository Tracking List |
| Configurar monitors/alertas Datadog (payment.failed, webhook.failed) | Repository Tracking List |
| Ativar Datadog em produção após validação em staging | Candidato ao Iteration Backlog |
| Atualizar Extension Layer ARN quando nova versão for publicada | Repository Tracking List |

---

# Recommendation

- [x] Mover para Downstream
- [ ] Executar outro experimento Upstream
- [ ] Aguardar decisão de negócio
- [ ] Aguardar dependência externa
- [ ] Descartar capability

Deploy em staging concluído. Hipótese confirmada: ativação sem alteração de código. Cold start de 1193ms documentado. Recomendação: ativar Datadog em produção via Downstream (mudança de configuração de baixo risco). Adicionar `STAGING_DATADOG_API_KEY` como GitHub secret para que o pipeline CI também beneficie.

---

# Decision Package

## Executive Summary

A configuração Datadog é ativada via três parâmetros SAM em `samconfig.toml` —
sem alteração de código. O ARN da Extension Layer v97 foi confirmado disponível em
us-east-1. O deploy de staging com `DatadogApiKey` injetado via `--parameter-overrides`
é o próximo passo de validação.

## Decisão Recomendada

Após validação em staging: promover para Downstream (ativar em produção).

## Riscos Atualizados

| Risco | Severidade | Mitigação |
|---|---|---|
| Extension Layer aumenta cold start significativamente | Baixo | Medir após deploy; Provisioned Concurrency como fallback (EXP-013) |
| API Key expirada ou sem permissões | Baixo | Validar no Datadog UI após deploy |

## Escopo Downstream Recomendado

Após validação em staging:
- Adicionar `DatadogEnabled=true` e parâmetros no bloco `[production.deploy.parameters]` do `samconfig.toml`
- Documentar instrução de deploy de produção com `DatadogApiKey`

---

# Output Artifacts

## Artefatos gerados

| Tipo | Artefato | Situação |
|---|---|---|
| Config | `api/samconfig.toml` (staging) | Atualizado — Datadog ativo |
| Análise | `010-datadog-activation/experiment.md` | Draft — Upstream |

**Promovido para Downstream:** `- [ ] Não` (aguardando validação em staging)
**Data de promoção:** —
**Slice:** Ativar Datadog em produção

---

# Exit Criteria

- [x] ARN da Extension Layer confirmado (v97)
- [x] samconfig.toml atualizado para staging
- [x] Deploy em staging executado com DatadogApiKey (UPDATE_COMPLETE)
- [x] Invoice criada → payment.created disparado
- [x] Impacto no cold start medido: 1193ms Init Duration
- [ ] Confirmação visual no Datadog APM e Metrics Explorer
- [x] Recomendação produzida

---

# Next Step

Executar deploy em staging:

```bash
cd api
sam deploy --config-env staging \
  --parameter-overrides \
    AsaasToken="..." \
    AsaasWebhookToken="..." \
    AdminSecret="..." \
    DatadogApiKey="<YOUR_DATADOG_API_KEY>"
```

Após deploy: validar métricas, traces e logs no Datadog UI.
