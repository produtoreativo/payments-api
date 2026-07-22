# OBC - Observabilidade com Datadog em Produção

## Status

Downstream. Status `Entrou` em `prodops/artifacts/governance/plans/iteration-plan.md` — capacidade operacional derivada do EXP-010.

## Business Outcome

A Payments API emite traces, métricas e logs estruturados para o Datadog em produção. O time consegue diagnosticar falhas por `correlationId`, `invoiceId` e `tenantId` diretamente no Datadog sem consultar o CloudWatch manualmente. O tempo médio de diagnóstico de incidentes reduz porque a jornada de pagamento completa — criação, confirmação, webhook — é rastreável em um único painel.

### Em linguagem executiva

Hoje, quando um cliente reclama que o pagamento não foi confirmado, o time precisa consultar logs brutos no CloudWatch sem contexto de negócio. Com o Datadog ativo, cada requisição gera um trace que conecta a chamada do Checkout à resposta do provedor Asaas — o time vê exatamente onde a jornada parou, em segundos, sem precisar de acesso manual ao banco.

É a diferença entre procurar um problema num arquivo de texto e ver o mapa do problema numa tela.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `dd.trace.request` | Requisição à API rastreada ponta a ponta no Datadog APM. | `service`, `env`, `http.method`, `http.url`, `correlationId`, `tenantId` |
| `dd.log.injected` | Log estruturado com `dd.trace_id` injetado — correlação log ↔ trace automática. | `dd.trace_id`, `dd.span_id`, `invoiceId`, `correlationId` |
| `dd.metric.runtime` | Métricas de runtime Lambda emitidas (memória, cold starts, duração). | `service`, `env`, `function_name` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Requisições à API com trace visível no Datadog APM em até 60s. | 99% |
| Logs com `dd.trace_id` injetado — correlação log ↔ trace ativa. | 100% |
| Métricas de runtime Lambda disponíveis no Datadog. | 99% |
| Nenhum secret ou payload sensível exposto em traces ou logs do Datadog. | 100% |

## Reliability Rules

- `DD_LOGS_INJECTION=true` e `DD_TRACE_ENABLED=true` devem estar presentes no ambiente Lambda de produção em todos os deploys.
- A `DatadogApiKey` deve ser injetada apenas via secret de deploy — nunca armazenada em `samconfig.toml` ou commitada no repositório.
- A Datadog Extension Layer (`Datadog-Extension:97`) deve ser declarada como parâmetro de versão explícito — sem `latest` para evitar atualizações não controladas.
- O serviço deve ser identificado como `payments-api` com `DD_ENV=production` e `DD_VERSION` correspondente à versão deployada.
- Falha na extensão Datadog não deve impedir o Lambda de responder — a extensão opera como sidecar, não como dependência crítica da função.

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/observability-datadog.feature`
- Experiment: `prodops/artifacts/experiments/010-datadog-activation/experiment.md`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- OBCs relacionados: `prodops/artifacts/business/obcs/production-cicd-pipeline.md`
