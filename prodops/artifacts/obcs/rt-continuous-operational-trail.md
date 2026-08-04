# OBC - RT Continuous Operational Trail

## Status

Committed. Business Intent: PI-RT-002. Business Signal: #135. GitHub Issue: #143. DS-59. Owner Approval: Context Engineer — 2026-08-04.

## Business Outcome

O trail operacional de cada Feature é uma narrativa contínua da execução — com uma entrada após cada phase, e o downstream-agent documentando suas ações no GitHub Issue à medida que avança pelo loop — permitindo auditoria em tempo real e diagnóstico de falhas mid-flight.

### Em linguagem executiva

Hoje o trail de uma Feature aparece apenas ao final da iteração — se a execução falhar no meio, não há registro de qual phase completou e qual falhou. Esse trabalho faz com que cada phase deixe rastro imediatamente ao concluir, e que o agent registre no GitHub Issue o que está executando em tempo real.

## Premortem

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Trail entries duplicadas se phase for reiniciada (restart protocol) | Média | Baixo — trail verbose, não corrompido | Prefixar entry com timestamp e fase; duplicatas são visíveis mas não bloqueantes |
| GitHub API rate limit ao comentar em muitas issues em rápida sequência | Baixa | Médio — agent bloqueado | Usar `gh issue edit` em vez de `comment` quando possível; throttle se necessário |
| Trail no arquivo vs trail no GitHub Issue criam divergência | Média | Médio — auditoria fragmentada | Decisão explícita no critério de aceite: trail canônico no GitHub Issue comment |
| Entries de trail tornam o GitHub Issue verboso demais para leitura humana | Média | Baixo | Usar comment de trail separado do comment de encerramento (PI-RT-004) |
| Instrução ao agent nem sempre é seguida em todas as phases | Média | Médio — trail incompleto | Codificar em SKILL.md como requisito explícito, não sugestão |

## Observable Events

Nenhum CloudEvent novo — o trail é escrito via `gh issue comment` ou append em arquivo local. A continuidade do trail é verificável auditando os comments na GitHub Issue.

## Initial SLIs

| SLI | Target |
|---|---|
| Issues com entry de trail para cada phase completada | ≥ 90% |
| Trail parcial disponível após falha mid-flight contendo última phase executada | 100% |
| downstream-agent registra qual issue está processando no início de cada phase | ≥ 95% |

## Reliability Rules

- Uma entry de trail deve ser escrita **antes** de avançar à próxima phase — não como step opcional ou post-hoc.
- Trail entry deve identificar: phase, work-item-id, status (iniciado/concluído/falhou), timestamp.
- Falha ao escrever trail entry não deve bloquear a execução da phase (não-fatal).

## Scope

### Mudança 1 — Trail contínuo por phase no downstream-agent
Após cada phase completada no loop de issues (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote), o downstream-agent escreve uma entry no GitHub Issue comment antes de avançar à próxima issue ou próxima phase.

### Mudança 2 — Documentação de ações do agent durante execução
O downstream-agent registra no GitHub Issue comment o que está executando: qual phase iniciou, qual concluiu, qual issue está processando. Atualizar `SKILL.md` do downstream com essa instrução como requisito.

### Fora de escopo
- Mudanças no formato CloudEvents
- Integração do trail com Datadog (coberto por PI-RT-003 / RT-ICE-003)
- Trail para fases de plan (Bootstrap.Plan e Iteration Closure)

## Critérios de aceite

| # | Critério |
|---|---|
| 1 | Ao término de cada phase, uma entry é adicionada ao GitHub Issue comment antes de avançar |
| 2 | Entry contém: phase name, work-item-id, status (completed/failed), timestamp |
| 3 | Um trail parcial de execução interrompida mid-flight permite diagnosticar até a última phase |
| 4 | `SKILL.md` do downstream instrui explicitamente o agent a registrar actions por phase |

## Related Artifacts

- Business Signal: [#135](https://github.com/produtoreativo/payments-api/issues/135)
- Business Intent: `prodops/artifacts/business-intents/PI-RT-002.md`
- GitHub Issue: [#143](https://github.com/produtoreativo/payments-api/issues/143)
- Downstream SKILL: `prodops/skills/downstream/SKILL.md`
