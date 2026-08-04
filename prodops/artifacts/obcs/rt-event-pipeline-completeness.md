# OBC - RT Event Pipeline Completeness

## Status

Draft. Business Intent: PI-RT-001. Business Signal: #135. GitHub Issue: #142.

## Business Outcome

Todos os eventos do ciclo de vida de uma Iteration chegam ao Datadog com tags corretas e transitam o oem-state no GitHub Project sem intervenção manual — eliminando os gaps de observabilidade detectados na Iteration v0.11.0.

O pipeline emit-event é confiável de ponta a ponta: cada evento emitido por qualquer phase (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) aparece no Datadog com `issue:<work-item-id>` correto e reflete o estado atualizado no GitHub Project Board dentro de 60s.

### Em linguagem executiva

Hoje o painel Datadog mostra apenas Bootstrap.Started e Bootstrap.Completed — os 3 eventos intermediários somem silenciosamente. Além disso, o GitHub Project Board ficou preso num estado errado durante v0.11.0 e precisou de correção manual. Esse trabalho fecha os dois gaps: o pipeline passa a entregar todos os eventos e o estado do Board passa a ser confiável automaticamente.

## Premortem

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Eventos intermediários de Bootstrap não são emitidos pelo skill (não chegam ao pipeline) | Média | Alto — correção exige mudança no skill, não só no pipeline | Inspecionar skills/bootstrap/ e confirmar onde cada evento é emitido |
| github/sync.sh recebe o evento mas falha silenciosamente ao atualizar o Project | Média | Alto — oem-state divergente sem alerta | Adicionar logging de saída do `gh project item-edit`; retornar erro não-zero em falha |
| Fix quebra eventos existentes que funcionam corretamente | Baixa | Alto — regressão na observabilidade | Testes no emit-event (tests/run-all.sh) antes de mergar |
| oem-state FINISHING requer campo customizado que não existe no Project | Baixa | Médio — estado nunca transita | Validar campos do Project #25 via `gh api` antes de implementar |
| Correção no pipeline não cobre o skill que não emite o evento | Média | Médio — fix parcial, gap persiste | Tratar como dois sub-problemas independentes com critérios de aceite separados |

## Observable Events

| Evento | Tag esperada | Datadog metric |
|---|---|---|
| `Delivery.Bootstrap.Dependencies.Installed` | `issue:<id>`, `iteration:<id>` | `prodops.delivery.event` |
| `Delivery.Bootstrap.Services.Ready` | `issue:<id>`, `iteration:<id>` | `prodops.delivery.event` |
| `Delivery.Bootstrap.Smoke.Passed` | `issue:<id>`, `iteration:<id>` | `prodops.delivery.event` |
| `Delivery.<Phase>.Started` → oem-state | — | GitHub Project Board column |

## Initial SLIs

| SLI | Target |
|---|---|
| Eventos Bootstrap intermediários visíveis no Datadog por Work Item | 100% |
| Transição oem-state no GitHub Project em até 60s após evento | 100% |
| `emit-event` retorna `"github-sync": "success"` para eventos de phase | ≥ 95% |
| Nenhum estado de phase detectado como "skip" no github/sync.sh | 100% |

## Reliability Rules

- `github/sync.sh` deve retornar exit code não-zero quando `gh project item-edit` falhar.
- Evento com `work-item-id` inválido não deve silenciosamente pular o sync do GitHub.
- Qualquer novo evento de sub-phase de Bootstrap deve ser coberto por teste unitário em `tests/`.

## Scope

### Problema 1 — Eventos intermediários de Bootstrap ausentes no Datadog
Investigar se os eventos `Dependencies.Installed`, `Services.Ready`, `Smoke.Passed` são emitidos pelo skill mas não chegam ao Datadog, ou se nunca são emitidos. Corrigir na camada onde o gap ocorre.

### Problema 2 — oem-state FINISHING não transitado no GitHub Project
Investigar se o `github/sync.sh` recebe o evento `Delivery.Finish.Started` mas falha ao atualizar o Project, ou se o evento nunca chegou ao step de sync. Corrigir o mapeamento de estado e o tratamento de erro.

### Fora de escopo
- Mudanças no schema CloudEvents (contrato estável)
- Alterações nos dashboards Datadog (coberto por PI-RT-003 / RT-ICE-003)
- Eventos de outros produtos além de `payments-api`

## Critérios de aceite

| # | Critério |
|---|---|
| 1 | Os 5 eventos de Bootstrap (Started, Dependencies.Installed, Services.Ready, Smoke.Passed, Completed) aparecem no Datadog com `issue:<id>` correto na próxima execução completa |
| 2 | `github/sync.sh` transita oem-state para FINISHING quando recebe `Delivery.Finish.Started` |
| 3 | `emit-event` retorna `"github-sync": "success"` (não "skip") para eventos de phase |
| 4 | `tests/run-all.sh` passa com exit 0 após as correções |

## Related Artifacts

- Business Signal: [#135](https://github.com/produtoreativo/payments-api/issues/135)
- Business Intent: `prodops/artifacts/business-intents/PI-RT-001.md`
- GitHub Issue: [#142](https://github.com/produtoreativo/payments-api/issues/142)
- Emit-event tool: `prodops/runtime/tools/emit-event/`
- GitHub sync: `prodops/runtime/github/sync.sh`
- Emit-event tests: `prodops/runtime/tools/emit-event/tests/`
