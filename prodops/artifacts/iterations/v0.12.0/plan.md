# Iteration Plan — v0.12.0

> Status: Em planejamento — OBCs em Draft, BDD Features pendentes

## Objetivo

Elevar a qualidade operacional do Runtime: fechar os gaps de observabilidade do pipeline de eventos, automatizar o ciclo de vida de Iterations, estabelecer trail contínuo durante execução e evoluir os dashboards Datadog com cycle time e filtros por iteração.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status |
|---|---|---|---|---|---|---|---|
| DS-57 | #146 | rt-event-pipeline-completeness: Bootstrap intermediários no Datadog + oem-state sync | — | Draft | — | ✓ | Planejado |
| DS-58 | #147 | rt-iteration-lifecycle-automation: auto-close tracking issue + assignees no Bootstrap | — | Draft | — | ✓ | Planejado |
| DS-59 | #148 | rt-continuous-operational-trail: trail por phase durante execução do downstream | — | Draft | — | ✓ | Planejado |
| DS-60 | #149 | rt-dashboard-evolution: cycle time, iteration filter e labels canônicos no Datadog | DS-57 | Draft | — | ✓ | Planejado |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.12.0 |
|---|---|---|
| DS-57 | rt-event-pipeline-completeness | #146 |
| DS-58 | rt-iteration-lifecycle-automation | #147 |
| DS-59 | rt-continuous-operational-trail | #148 |
| DS-60 | rt-dashboard-evolution | #149 |

## Sequência de entrega

DS-57, DS-58, DS-59 em paralelo → DS-60 (bloqueado por DS-57)

## Gates pendentes antes de iniciar Delivery

| DS | Gate | Ação necessária |
|---|---|---|
| DS-57 | BDD Feature | Criar `prodops/artifacts/bdd/rt-event-pipeline-completeness.feature` |
| DS-57 | OBC Committed | Owner Approval (Tech Lead Payments) |
| DS-58 | BDD Feature | Criar `prodops/artifacts/bdd/rt-iteration-lifecycle-automation.feature` |
| DS-58 | OBC Committed | Owner Approval |
| DS-59 | BDD Feature | Criar `prodops/artifacts/bdd/rt-continuous-operational-trail.feature` |
| DS-59 | OBC Committed | Owner Approval |
| DS-60 | BDD Feature | Criar `prodops/artifacts/bdd/rt-dashboard-evolution.feature` |
| DS-60 | OBC Committed | Owner Approval |

## Critérios de saída

- [ ] PR merged para DS-57 — pipeline entrega todos os 5 eventos Bootstrap; oem-state FINISHING transitado (#146)
- [ ] PR merged para DS-58 — tracking issue fechada automaticamente; assignees preenchidos desde Bootstrap (#147)
- [ ] PR merged para DS-59 — trail por phase nos GitHub Issues durante execução (#148)
- [ ] PR merged para DS-60 — tag `iteration`, cycle time widget e labels canônicos no dashboard (#149)
- [ ] `prodops.delivery.promote.completed` emitido para cada issue (#146, #147, #148, #149)
- [ ] Issues #146, #147, #148, #149 fechadas no GitHub

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.12.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
