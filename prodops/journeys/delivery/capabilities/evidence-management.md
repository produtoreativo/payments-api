# Capability — Evidence Management

## Objetivo

Capturar, preservar e apresentar evidências de cada etapa do fluxo de entrega, garantindo rastreabilidade da decisão ao deploy.

## Responsabilidades

- Registrar evidências de testes (Red Bar confirmado, Green Bar, aceitação)
- Registrar evidências de lint e build
- Atualizar o Release Trail após cada etapa relevante do Downstream
- Registrar evidência de validação pós-deploy
- Registrar promoção com aprovação formal

## Flows consumidores

| Flow | Evidência produzida |
|---|---|
| Hack | Red Bar confirmado, Green Bar, lint |
| Finish | Evidência de Quality Gates (lint, testes, build) |
| Validate | Logs, métricas, SLO signals, BDD cenários em staging |
| Promote | Entrada no Release Trail, aprovação, Rollback Readiness |

## Artefatos produzidos

- Entradas no Release Trail: `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md` (trail da sessão ativa)
- Entradas no Upstream Trail: `prodops/journeys/discovery/experiments/<id>/upstream-trail.md`
- PR preenchido com evidências (template: `prodops/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md`)

## Dependências

- Release Trail: `prodops/artifacts/governance/trails/sessions/` (trail da sessão ativa)
- Task-closing template: `prodops/journeys/delivery/capabilities/commit-workflow/templates/task-closing.md`
