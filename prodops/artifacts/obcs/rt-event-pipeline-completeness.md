# OBC - RT Event Pipeline Completeness

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-57 |
| Iteração | v0.12.0 (suspensa) |
| Última atualização | 2026-11-10 |

## Status

**Estado:** Committed
**Rastreado em:** DS-57 (#146) — v0.12.0 (suspensa). Registro anterior: Committed. Business Intent: PI-RT-001. Business Signal: #135. GitHub Issue: #142. DS-57. Owner Approval: Context Engineer — 2026-08-04.
**Pendência:** iteração suspensa; permanece `Committed` até retomada. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [#135](https://github.com/produtoreativa/payments-api/issues/135) — Qualidade operacional do Runtime v0.11.0 |
| Business Intent | [PI-RT-001](../business-intents/PI-RT-001.md) ([#142](https://github.com/produtoreativa/payments-api/issues/142)) |
| Product Tracking Item | issue #146 (DS-57), ver `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | RT-ICE-001 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |

## Business Outcome

Todos os eventos do ciclo de vida de uma Iteration chegam ao Datadog com tags corretas e transitam o oem-state no GitHub Project sem intervenção manual — eliminando os gaps de observabilidade detectados na Iteration v0.11.0.

O pipeline emit-event é confiável de ponta a ponta: cada evento emitido por qualquer phase (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) aparece no Datadog com `issue:<work-item-id>` correto e reflete o estado atualizado no GitHub Project Board dentro de 60s.

### Em linguagem executiva

Hoje o painel Datadog mostra apenas Bootstrap.Started e Bootstrap.Completed — os 3 eventos intermediários somem silenciosamente. Além disso, o GitHub Project Board ficou preso num estado errado durante v0.11.0 e precisou de correção manual. Esse trabalho fecha os dois gaps: o pipeline passa a entregar todos os eventos e o estado do Board passa a ser confiável automaticamente.

## Escopo

### Problema 1 — Eventos intermediários de Bootstrap ausentes no Datadog
Investigar se os eventos `Dependencies.Installed`, `Services.Ready`, `Smoke.Passed` são emitidos pelo skill mas não chegam ao Datadog, ou se nunca são emitidos. Corrigir na camada onde o gap ocorre.

### Problema 2 — oem-state FINISHING não transitado no GitHub Project
Investigar se o `github/sync.sh` recebe o evento `Delivery.Finish.Started` mas falha ao atualizar o Project, ou se o evento nunca chegou ao step de sync. Corrigir o mapeamento de estado e o tratamento de erro.

### Fora de escopo
- Mudanças no schema CloudEvents (contrato estável)
- Alterações nos dashboards Datadog (coberto por PI-RT-003 / RT-ICE-003)
- Eventos de outros produtos além de `payments-api`

## Regras de Negócio

- [apurar]

## Critérios de Aceite

| # | Critério |
|---|---|
| 1 | Os 5 eventos de Bootstrap (Started, Dependencies.Installed, Services.Ready, Smoke.Passed, Completed) aparecem no Datadog com `issue:<id>` correto na próxima execução completa |
| 2 | `github/sync.sh` transita oem-state para FINISHING quando recebe `Delivery.Finish.Started` |
| 3 | `emit-event` retorna `"github-sync": "success"` (não "skip") para eventos de phase |
| 4 | `tests/run-all.sh` passa com exit 0 após as correções |

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | n/a — capacidade de plataforma/framework, não é Product Service |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Evento | Situação | Tag esperada | Datadog metric |
|---|---|---|---|
| `Delivery.Bootstrap.Dependencies.Installed` | [apurar] | `issue:<id>`, `iteration:<id>` | `prodops.delivery.event` |
| `Delivery.Bootstrap.Services.Ready` | [apurar] | `issue:<id>`, `iteration:<id>` | `prodops.delivery.event` |
| `Delivery.Bootstrap.Smoke.Passed` | [apurar] | `issue:<id>`, `iteration:<id>` | `prodops.delivery.event` |
| `Delivery.<Phase>.Started` → oem-state | [apurar] | — | GitHub Project Board column |

## Initial SLIs

| SLI | Target | Fonte |
|---|---|---|
| Eventos Bootstrap intermediários visíveis no Datadog por Work Item | 100% | [apurar] |
| Transição oem-state no GitHub Project em até 60s após evento | 100% | [apurar] |
| `emit-event` retorna `"github-sync": "success"` para eventos de phase | ≥ 95% | [apurar] |
| Nenhum estado de phase detectado como "skip" no github/sync.sh | 100% | [apurar] |

## Reliability Rules

- `github/sync.sh` deve retornar exit code não-zero quando `gh project item-edit` falhar.
- Evento com `work-item-id` inválido não deve silenciosamente pular o sync do GitHub.
- Qualquer novo evento de sub-phase de Bootstrap deve ser coberto por teste unitário em `tests/`.

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Eventos intermediários de Bootstrap não são emitidos pelo skill (não chegam ao pipeline) | Média | Alto — correção exige mudança no skill, não só no pipeline | Inspecionar skills/bootstrap/ e confirmar onde cada evento é emitido |
| github/sync.sh recebe o evento mas falha silenciosamente ao atualizar o Project | Média | Alto — oem-state divergente sem alerta | Adicionar logging de saída do `gh project item-edit`; retornar erro não-zero em falha |
| Fix quebra eventos existentes que funcionam corretamente | Baixa | Alto — regressão na observabilidade | Testes no emit-event (tests/run-all.sh) antes de mergar |
| oem-state FINISHING requer campo customizado que não existe no Project | Baixa | Médio — estado nunca transita | Validar campos do Project #25 via `gh api` antes de implementar |
| Correção no pipeline não cobre o skill que não emite o evento | Média | Médio — fix parcial, gap persiste | Tratar como dois sub-problemas independentes com critérios de aceite separados |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| — | [apurar] | [apurar] |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- Business Signal: [#135](https://github.com/produtoreativo/payments-api/issues/135)
- Business Intent: `prodops/artifacts/business-intents/PI-RT-001.md`
- GitHub Issue: [#142](https://github.com/produtoreativo/payments-api/issues/142)
- Emit-event tool: `prodops/runtime/tools/emit-event/`
- GitHub sync: `prodops/runtime/github/sync.sh`
- Emit-event tests: `prodops/runtime/tools/emit-event/tests/`
