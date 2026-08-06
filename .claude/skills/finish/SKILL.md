---
name: finish
description: Close technical work by delivering a fully autonomous Pull Request. Emits Finish.Started and Finish.Completed via prodops_emit_event.
---
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/finish/SKILL.md
     Player:    claude
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: 2026-08-06T13:38:19Z
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill finish
-->

# FINISH

Use this skill to close a task by delivering a fully autonomous Pull Request with explicit quality evidence.

## O que Finish é e NÃO é

**Finish NÃO entrega software.**

Finish entrega um Pull Request completamente autônomo — um PR que percorre todo o restante do fluxo (Ship → Validate → Promote) **sem intervenção humana**.

Para isso, Finish garante:

- commits finais organizados e válidos
- evidências de qualidade registradas
- gates de qualidade satisfeitos (lint, build, testes, contratos)
- PR criado com narrativa completa
- auto-approval configurado e executado (quando o repositório suportar)
- auto-merge habilitado (quando o repositório suportar)
- workflows existentes verificados e válidos
- repositório apto para execução automática confirmado

**Se qualquer requisito não puder ser satisfeito: Finish NÃO conclui. Interrompe para investigação.**

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

## Phase: Finish.Started

**Moment**: after input context is verified, before any quality gate work begins.

Emit:

```json
{
  "event": "Delivery.Finish.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "finish-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Finish.Completed

**Moment**: after all quality gates pass and Release Trail evidence is appended — before reporting success.

Emit using the **same `correlation-id`** as Finish.Started:

```json
{
  "event": "Delivery.Finish.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "finish-agent" },
  "payload": {}
}
```

Do not emit `Finish.Completed` if any quality gate fails or evidence is incomplete.

## Inputs

- `AGENTS.md`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- Current diff and test output

## Flow

1. Verificar contexto de entrada (work-item-id, iteration-id, actor, correlation-id).
2. Emitir Finish.Started.
3. Revisar arquivos alterados e confirmar escopo.
4. Verificar gates de qualidade relevantes à tarefa (lint, build, testes, contratos).
5. Executar validação focada e, quando o risco justificar, validação mais ampla.
6. Confirmar que artefatos ProdOps foram atualizados apenas onde impactados.
7. Confirmar que evidência existe no Release Trail.
8. Criar o Pull Request preenchendo o template com evidências.
9. Executar auto-approval no PR (quando o repositório suportar; registrar resultado).
10. Habilitar auto-merge no PR (quando o repositório suportar; registrar resultado).
11. Verificar que workflows existentes estão válidos e que o repositório está apto para execução automática.
12. Registrar explicitamente qualquer item incompleto — Finish NÃO conclui com itens abertos.
13. Emitir Finish.Completed após todos os requisitos satisfeitos.

## Guardrails

- Do not mark work complete without evidence.
- Do not hide skipped tests; record why they were skipped.
- Do not expand scope during finish work.
- If any requirement cannot be satisfied, Finish does NOT complete. Stop and investigate.
- Do not emit Finish.Completed before the PR is created and all quality gates pass.
- Auto-approval and auto-merge failures are blockers — investigate before proceeding.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Full quality gate definitions and Definition of Done |
