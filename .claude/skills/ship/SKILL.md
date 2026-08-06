---
name: ship
description: Observe and orchestrate the autonomous PR flow — merge, CI, and Staging deploy. Emits Ship.Started and Ship.Completed via prodops_emit_event.
---
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/ship/SKILL.md
     Player:    claude
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: 2026-08-06T13:38:21Z
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill ship
-->

# SHIP

Use this skill to observe and orchestrate the autonomous Pull Request flow created by Finish.

For detailed Ship observation mechanics, read `references/workflow.md`.

## O que Ship é e NÃO é

**Ship NÃO realiza deploy. Ship NÃO executa CI. Ship NÃO aprova o PR.**

Ship é **orquestrador e observador**.

- Quem executa aprovação, merge e workflows: **GitHub**
- Quem executa pipelines e deploy: **GitHub Actions**
- Ship: **observa a execução, emite eventos, reage a falhas**

**Gatilho:** Pull Request criado pelo Finish.
**Ship.Started:** emitido ao detectar o PR criado — antes de observar qualquer execução.
**Ship.Completed:** emitido somente após merge realizado **E** deploy em Staging concluído com sucesso.
**Ship.Completed representa:** Feature disponível em seu ambiente de Staging (efêmero por Feature/OBC).

Se qualquer etapa do CI falhar: Ship detecta, interrompe progressão e reporta. Finish deve ser reaberto para investigação.

## Required input context

Before starting, the agent must have:

- `work-item-id` — the GitHub issue number of the Feature
- `iteration-id` — the Iteration Plan identifier
- `actor.player` — the current player (`claude`, `codex`, or `copilot`)
- `correlation-id` — the Delivery-flow UUID provided by the chain runner. If
  invoked standalone, generate a new UUID.

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.

## Phase: Ship.Started

**Moment**: after input context is verified and the PR created by Finish is detected — before observing any CI execution.

Emit:

```json
{
  "event": "Delivery.Ship.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "ship-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Ship.Completed

**Moment**: after PR merge is confirmed AND Staging deploy completes successfully — before reporting success.

Emit using the **same `correlation-id`** as Ship.Started:

```json
{
  "event": "Delivery.Ship.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "ship-agent" },
  "payload": {}
}
```

Do not emit `Ship.Completed` if PR merge has not occurred or Staging deploy has not completed successfully.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- PR criado pelo Finish (número, URL, status de checks)

## Ambientes

| Ambiente | Tipo | Propósito |
|---|---|---|
| Staging | Efêmero por Feature/OBC | Validar exclusivamente a Feature em questão. Destruído após promoção. |
| Sandbox | Compartilhado | Release Candidate. Recebe Features promovidas pelo Ship via Promote. |
| Production | Operacional | Fora da Delivery Journey. |

Ship observa o deploy para **Staging**. Sandbox e Production estão fora do escopo do Ship.

## Flow

1. Verificar contexto de entrada (work-item-id, iteration-id, actor, correlation-id).
2. Detectar o PR criado pelo Finish para o work-item correto.
3. Emitir Ship.Started.
4. Observar execução de checks e workflows do GitHub no PR.
5. Observar aprovação automática no PR (executada pelo GitHub conforme regras do repositório).
6. Observar merge automático do PR (executado pelo GitHub conforme regras do repositório).
7. Se qualquer check ou workflow falhar: detectar, interromper progressão, reportar falha. Finish deve ser reaberto.
8. Após merge confirmado: observar acionamento do pipeline de deploy para Staging.
9. Observar resultado do deploy em Staging.
10. Se deploy em Staging falhar: detectar, interromper progressão, reportar falha.
11. Após deploy em Staging concluído com sucesso: registrar evidência no Release Trail.
12. Emitir Ship.Completed.

## Guardrails

- Do not perform deploy. Deploy is executed by GitHub Actions.
- Do not approve the PR. Approval is executed by GitHub.
- Do not merge the PR. Merge is executed by GitHub.
- Do not emit Ship.Completed before merge AND Staging deploy succeed.
- If any CI step fails: stop progression. Do not proceed to Promote. Report for investigation.
- Staging is ephemeral per Feature. Do not conflate Staging with Sandbox or Production.

## Engineering References

| Reference | When to read |
|---|---|
| [`references/workflow.md`](references/workflow.md) | Ship observation mechanics — como detectar PR, observar checks, merge e deploy |
