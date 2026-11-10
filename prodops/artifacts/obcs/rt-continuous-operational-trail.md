# OBC - RT Continuous Operational Trail

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-59 |
| Iteração | v0.12.0 (suspensa) |
| Última atualização | 2026-11-10 |

## Status

**Estado:** Committed
**Rastreado em:** DS-59 (#148) — v0.12.0 (suspensa). Registro anterior: Committed. Business Intent: PI-RT-002. Business Signal: #135. GitHub Issue: #143. DS-59. Owner Approval: Context Engineer — 2026-08-04.
**Pendência:** iteração suspensa; permanece `Committed` até retomada. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [#135](https://github.com/produtoreativa/payments-api/issues/135) — Qualidade operacional do Runtime v0.11.0 |
| Business Intent | [PI-RT-002](../business-intents/PI-RT-002.md) ([#143](https://github.com/produtoreativa/payments-api/issues/143)) |
| Product Tracking Item | issue #148 (DS-59), ver `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | RT-ICE-002 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |

## Business Outcome

O trail operacional de cada Feature é uma narrativa contínua da execução — com uma entrada após cada phase, e o downstream-agent documentando suas ações no GitHub Issue à medida que avança pelo loop — permitindo auditoria em tempo real e diagnóstico de falhas mid-flight.

### Em linguagem executiva

Hoje o trail de uma Feature aparece apenas ao final da iteração — se a execução falhar no meio, não há registro de qual phase completou e qual falhou. Esse trabalho faz com que cada phase deixe rastro imediatamente ao concluir, e que o agent registre no GitHub Issue o que está executando em tempo real.

## Escopo

### Mudança 1 — Trail contínuo por phase no downstream-agent
Após cada phase completada no loop de issues (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote), o downstream-agent escreve uma entry no GitHub Issue comment antes de avançar à próxima issue ou próxima phase.

### Mudança 2 — Documentação de ações do agent durante execução
O downstream-agent registra no GitHub Issue comment o que está executando: qual phase iniciou, qual concluiu, qual issue está processando. Atualizar `SKILL.md` do downstream com essa instrução como requisito.

### Fora de escopo
- Mudanças no formato CloudEvents
- Integração do trail com Datadog (coberto por PI-RT-003 / RT-ICE-003)
- Trail para fases de plan (Bootstrap.Plan e Iteration Closure)

## Regras de Negócio

- [apurar]

## Critérios de Aceite

| # | Critério |
|---|---|
| 1 | Ao término de cada phase, uma entry é adicionada ao GitHub Issue comment antes de avançar |
| 2 | Entry contém: phase name, work-item-id, status (completed/failed), timestamp |
| 3 | Um trail parcial de execução interrompida mid-flight permite diagnosticar até a última phase |
| 4 | `SKILL.md` do downstream instrui explicitamente o agent a registrar actions por phase |

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | n/a — capacidade de plataforma/framework, não é Product Service |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

Nenhum CloudEvent novo — o trail é escrito via `gh issue comment` ou append em arquivo local. A continuidade do trail é verificável auditando os comments na GitHub Issue.

## Initial SLIs

| SLI | Target | Fonte |
|---|---|---|
| Issues com entry de trail para cada phase completada | ≥ 90% | [apurar] |
| Trail parcial disponível após falha mid-flight contendo última phase executada | 100% | [apurar] |
| downstream-agent registra qual issue está processando no início de cada phase | ≥ 95% | [apurar] |

## Reliability Rules

- Uma entry de trail deve ser escrita **antes** de avançar à próxima phase — não como step opcional ou post-hoc.
- Trail entry deve identificar: phase, work-item-id, status (iniciado/concluído/falhou), timestamp.
- Falha ao escrever trail entry não deve bloquear a execução da phase (não-fatal).

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Trail entries duplicadas se phase for reiniciada (restart protocol) | Média | Baixo — trail verbose, não corrompido | Prefixar entry com timestamp e fase; duplicatas são visíveis mas não bloqueantes |
| GitHub API rate limit ao comentar em muitas issues em rápida sequência | Baixa | Médio — agent bloqueado | Usar `gh issue edit` em vez de `comment` quando possível; throttle se necessário |
| Trail no arquivo vs trail no GitHub Issue criam divergência | Média | Médio — auditoria fragmentada | Decisão explícita no critério de aceite: trail canônico no GitHub Issue comment |
| Entries de trail tornam o GitHub Issue verboso demais para leitura humana | Média | Baixo | Usar comment de trail separado do comment de encerramento (PI-RT-004) |
| Instrução ao agent nem sempre é seguida em todas as phases | Média | Médio — trail incompleto | Codificar em SKILL.md como requisito explícito, não sugestão |

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
- Business Intent: `prodops/artifacts/business-intents/PI-RT-002.md`
- GitHub Issue: [#143](https://github.com/produtoreativo/payments-api/issues/143)
- Downstream SKILL: `prodops/skills/downstream/SKILL.md`
