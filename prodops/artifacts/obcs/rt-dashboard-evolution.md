# OBC - RT Dashboard Evolution

## Status

Committed. Business Intent: PI-RT-003. Business Signal: #135. GitHub Issue: #144. DS-60. Owner Approval: Context Engineer — 2026-08-04.

## Business Outcome

Os dashboards Datadog do Runtime exibem cycle time por phase, permitem filtro por Iteration ID e usam labels canônicos — tornando o painel executivo observável por iteração e por phase de entrega sem configuração manual.

### Em linguagem executiva

Hoje o painel Datadog mostra eventos, mas sem cycle time por phase, sem filtro por iteração e com labels que refletem nomes internos de CloudEvents em vez dos nomes das phases que o time usa no dia a dia. Esse trabalho acrescenta as métricas derivadas e os filtros que tornam o painel acionável por qualquer stakeholder.

## Premortem

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Tag `iteration:<id>` ausente nos eventos atuais — filtro impossível | Alta | Alto — bloqueante | Verificar tags em `send.sh` antes de qualquer widget; adicionar se ausente |
| Cycle time calculado por log-based metric tem latência alta no Datadog | Média | Médio — métrica com delay | Considerar envio explícito de duração via `send.sh` como gauge |
| Dashboards editados manualmente divergem do estado desejado na próxima atualização | Média | Médio | Codificar dashboard como JSON exportado + instruções de import |
| Labels canônicos ("Bootstrap") colidem com nomes existentes em outros dashboards | Baixa | Baixo — cosmético | Prefixar com "ProdOps:" se necessário |
| Dados históricos não têm `iteration` tag — filtro mostra vazio para iterações passadas | Alta | Médio — limitação conhecida, aceitável | Documentar que o filtro funciona a partir da data de implementação |

## Observable Events

Nenhum CloudEvent novo, mas mudanças em `send.sh`:
- Adicionar tag `iteration:<iteration-id>` em todos os eventos se ausente
- Opcionalmente: enviar gauge `prodops.phase.duration_seconds` ao completar cada phase

## Initial SLIs

| SLI | Target |
|---|---|
| Widget de cycle time por phase disponível no dashboard Runtime | Presente |
| Template variable `$iteration_id` funcional em todos os widgets do dashboard | 100% |
| Labels dos widgets usam nomes canônicos (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) | 100% |

## Reliability Rules

- Tag `iteration:<id>` deve estar presente em **todos** os eventos enviados ao Datadog antes de ativar o filtro.
- Cycle time deve ser calculado de `.Started` a `.Completed` da mesma phase, para o mesmo `work-item-id`.
- Alterações no dashboard devem ser exportadas como JSON e commitadas em `prodops/runtime/datadog/`.

## Scope

### Step 1 — Tag `iteration` nos eventos (pré-requisito)
Verificar se `send.sh` já envia `iteration:<id>`. Se não, adicionar. Sem essa tag, o filtro por iteração é impossível.

### Step 2 — Template variable `$iteration_id`
Adicionar template variable no dashboard Runtime que filtra todos os widgets por `iteration:$iteration_id`.

### Step 3 — Widget de cycle time por phase
Adicionar widget(s) de cycle time calculando a duração média entre `<Phase>.Started` e `<Phase>.Completed` por work-item, agrupado por phase — usando log-based metric ou gauge explícito.

### Step 4 — Labels canônicos
Atualizar labels de widgets existentes: substituir nomes internos (`prodops.delivery.bootstrap.started`) pelos nomes canônicos das phases (`Bootstrap`, `Hack`, etc.).

### Fora de escopo
- Novos tipos de métricas além de cycle time e lead time
- Alertas baseados em cycle time
- Dashboards para outros produtos além de `payments-api`
- Dados históricos anteriores à implementação da tag `iteration`

## Critérios de aceite

| # | Critério |
|---|---|
| 1 | `send.sh` envia tag `iteration:<id>` em todos os eventos |
| 2 | Template variable `$iteration_id` disponível e funcional no dashboard Runtime |
| 3 | Widget de cycle time por phase exibe duração média de Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote |
| 4 | Labels dos widgets usam nomes canônicos — não nomes internos de CloudEvents |
| 5 | Dashboard exportado como JSON em `prodops/runtime/datadog/` |

## Related Artifacts

- Business Signal: [#135](https://github.com/produtoreativo/payments-api/issues/135)
- Business Intent: `prodops/artifacts/business-intents/PI-RT-003.md`
- GitHub Issue: [#144](https://github.com/produtoreativo/payments-api/issues/144)
- Datadog send script: `prodops/runtime/datadog/send.sh`
- Dependência: PI-RT-001 (RT-ICE-001) — pipeline deve ser completo antes de medir cycle time
