# OBC - Observabilidade com Datadog em Produção

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-50 |
| Iteração | v0.9.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-50 (#44) — v0.9.0, PR #122 e PR #123. Registro anterior: Downstream. Status `Entrou` em `prodops/artifacts/plans/iteration-plan.md` — capacidade operacional derivada do EXP-010.
**Pendência:** iteração concluída (PR #122 e PR #123); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-004](../business-signals/BS-004.md) |
| Business Intent | [PI-010](../business-intents/PI-010.md) |
| Product Tracking Item | issue #44 (DS-50), ver `prodops/artifacts/plans/iteration-plan.md` |
| Experimento | [EXP-010](../experiments/010-datadog-activation/experiment.md) |

## Business Outcome

A Payments API emite traces, métricas e logs estruturados para o Datadog em produção. O time consegue diagnosticar falhas por `correlationId`, `invoiceId` e `tenantId` diretamente no Datadog sem consultar o CloudWatch manualmente. O tempo médio de diagnóstico de incidentes reduz porque a jornada de pagamento completa — criação, confirmação, webhook — é rastreável em um único painel.

### Em linguagem executiva

Hoje, quando um cliente reclama que o pagamento não foi confirmado, o time precisa consultar logs brutos no CloudWatch sem contexto de negócio. Com o Datadog ativo, cada requisição gera um trace que conecta a chamada do Checkout à resposta do provedor Asaas — o time vê exatamente onde a jornada parou, em segundos, sem precisar de acesso manual ao banco.

É a diferença entre procurar um problema num arquivo de texto e ver o mapa do problema numa tela.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/observability-datadog.feature`; marcar após verificação.

- [ ] Requisicao gera trace visivel no Datadog APM
- [ ] Log estruturado contem dd.trace_id injetado
- [ ] Metricas de runtime Lambda aparecem no Datadog
- [ ] DatadogApiKey nao e exposta em logs ou traces
- [ ] Falha na extensao Datadog nao impede resposta da API

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | n/a — capacidade de plataforma/framework, não é Product Service |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `dd.trace.request` | [apurar] | Requisição à API rastreada ponta a ponta no Datadog APM. | `service`, `env`, `http.method`, `http.url`, `correlationId`, `tenantId` |
| `dd.log.injected` | [apurar] | Log estruturado com `dd.trace_id` injetado — correlação log ↔ trace automática. | `dd.trace_id`, `dd.span_id`, `invoiceId`, `correlationId` |
| `dd.metric.runtime` | [apurar] | Métricas de runtime Lambda emitidas (memória, cold starts, duração). | `service`, `env`, `function_name` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Requisições à API com trace visível no Datadog APM em até 60s. | 99% | [apurar] |
| Logs com `dd.trace_id` injetado — correlação log ↔ trace ativa. | 100% | [apurar] |
| Métricas de runtime Lambda disponíveis no Datadog. | 99% | [apurar] |
| Nenhum secret ou payload sensível exposto em traces ou logs do Datadog. | 100% | [apurar] |

## Reliability Rules

- `DD_LOGS_INJECTION=true` e `DD_TRACE_ENABLED=true` devem estar presentes no ambiente Lambda de produção em todos os deploys.
- A `DatadogApiKey` deve ser injetada apenas via secret de deploy — nunca armazenada em `samconfig.toml` ou commitada no repositório.
- A Datadog Extension Layer (`Datadog-Extension:97`) deve ser declarada como parâmetro de versão explícito — sem `latest` para evitar atualizações não controladas.
- O serviço deve ser identificado como `payments-api` com `DD_ENV=production` e `DD_VERSION` correspondente à versão deployada.
- Falha na extensão Datadog não deve impedir o Lambda de responder — a extensão opera como sidecar, não como dependência crítica da função.

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| — | [apurar] | [apurar] |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/observability-datadog.feature`
- Experiment: `prodops/artifacts/experiments/010-datadog-activation/experiment.md`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- OBCs relacionados: `prodops/artifacts/obcs/production-cicd-pipeline.md`
