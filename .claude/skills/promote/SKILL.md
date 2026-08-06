---
name: promote
description: Promote the Feature from Staging to Sandbox (Release Candidate). Emits Promote.Started and Promote.Completed via prodops_emit_event.
---
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/promote/SKILL.md
     Player:    claude
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: 2026-08-06T13:38:24Z
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill promote
-->

# PROMOTE

Use this skill to promote a Feature from its ephemeral Staging environment to the shared Sandbox environment (Release Candidate).

## O que Promote é e NÃO é

**Promote NÃO publica em Production.**

**Promote inicia somente após Ship.Completed.**

Responsabilidades do Promote:

- Confirmar que Ship.Completed foi emitido antes de iniciar
- Promover a Feature do ambiente de Staging para o ambiente de Sandbox
- Sandbox representa o **Release Candidate** — é compartilhado e recebe apenas Features promovidas pelo Ship
- Registrar evidência da promoção no Release Trail

**Production permanece fora da Delivery Journey.** Production pertence ao processo operacional posterior.

## Ambientes

| Ambiente | Tipo | Propósito |
|---|---|---|
| Staging | Efêmero por Feature/OBC | Validação exclusiva da Feature. Destruído após promoção. |
| Sandbox | Compartilhado | Release Candidate. Origem da promoção para Production. |
| Production | Operacional | Fora da Delivery Journey. |

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

## Phase: Promote.Started

**Moment**: after input context is verified and Ship.Completed is confirmed — before any promotion work begins.

Emit:

```json
{
  "event": "Delivery.Promote.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "promote-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Promote.Completed

**Moment**: after all promotion steps complete and Release Trail is updated — before reporting success.

Emit using the **same `correlation-id`** as Promote.Started:

```json
{
  "event": "Delivery.Promote.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "promote-agent" },
  "payload": {}
}
```

Do not emit `Promote.Completed` if evidence is missing, risks are unresolved, or Staging→Sandbox promotion has not executed.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- Evidência de Ship.Completed para o work-item

## Flow

1. Confirmar que Ship.Completed foi emitido para o work-item correto.
2. Confirmar que validation e quality gates estão completos.
3. Confirmar que riscos não resolvidos estão aceitos, mitigados, ou movidos para follow-up.
4. Executar promoção da Feature de Staging para Sandbox.
5. Registrar aprovação, evidência e próximos passos.
6. Adicionar entrada de promoção ao Release Trail.

## Guardrails

- Do not promote when required evidence is missing.
- Do not promote before Ship.Completed is confirmed.
- Do not silently accept unresolved high-risk items.
- Do not replace Release Trail history; append a new entry.
- Do not promote to Production. Promote targets Sandbox only. Production is outside the Delivery Journey.
- Sandbox is the Release Candidate. It receives only Ship-promoted Features.
