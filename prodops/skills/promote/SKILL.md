---
name: promote
description: Approve and close a release stage. Emits Promote.Started and Promote.Completed via prodops_emit_event.
---

# PROMOTE

Use this skill to move a release to the next stage or close it.

## Required input context

Ler a context capsule em `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`.
Todos os campos abaixo devem estar disponíveis na capsule:

- `work-item-id` — campo `work-item-id` da capsule (issue da iteração corrente)
- `iteration-id` — campo `iteration-id`
- `correlation-id` — campo `correlation-id` (gerado em `Delivery.Plan.Bootstrap.Issue.Entered`)
- `actor-player` — campo `actor-player`
- `plan-bootstrap-path` — campo `plan-bootstrap-path`
- `plan-validate-path` — campo `plan-validate-path`
- `timeline-path` — campo `timeline-path` (para o cálculo de lead-time)
- `reliability-path` — campo `reliability-path` (opcional; consultar riscos se `!= "none"`)

Se invocado standalone (sem capsule), gerar novo `correlation-id`.

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.

## Plan Promote gate — verificar antes de Promote.Started

Se `plan-bootstrap-path` da capsule existir com `"status": "completed"` (execução dentro de um Iteration Plan):

1. Ler `plan-validate-path` da capsule.
2. Se o arquivo não existir ou `status != "all-validated"`: **bloquear**. Não emitir `Promote.Started`. Reportar quais issues do plano ainda não completaram Validate e aguardar.
3. Se `status == "all-validated"`: prosseguir com o fluxo abaixo normalmente.

Se o arquivo plan-bootstrap não existir (execução standalone): prosseguir sem verificação de plano.

## Phase: Promote.Started

**Moment**: after input context is verified, before any promotion work begins.

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

Do not emit `Promote.Completed` if evidence is missing, risks are unresolved, or operational readiness is not confirmed.

## Lead-time automático

Ao emitir `Promote.Completed`, o `emit-event` tool calcula automaticamente o
lead-time da Feature e envia a métrica `runtime.delivery.lead_time_days` para
o Datadog — sem ação manual.

Como funciona:
1. Localiza o primeiro `Bootstrap.Started` no timeline da issue (`timelines/<issue>.json`)
2. Calcula `delta = Promote.Completed.timestamp − Bootstrap.Started.timestamp` em dias
3. Emite gauge `runtime.delivery.lead_time_days` via Datadog sync (não-fatal — falha silenciosa)

O agente não precisa calcular nem enviar esta métrica manualmente. Basta garantir
que `Bootstrap.Started` esteja presente no timeline (emitido corretamente pelo
skill Bootstrap). Se ausente, o cálculo é ignorado e um warning é logado.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- `prodops/framework/journeys/operation/`

## Flow

1. Confirm required validation and quality gates are complete.
2. Confirm unresolved risks are accepted, mitigated, or moved to follow-up.
3. Check operational readiness: incidents, runbooks, postmortems, and
   operational trail.
4. Record approval, evidence, and remaining next steps.
5. Append promotion or closure notes to the Release Trail.
6. Close the GitHub Issue:
   ```bash
   gh issue close <work-item-id> --comment "Entrega concluída — Promote.Completed emitido. PR #<pr-number> mergeado em master."
   ```
   This is the canonical close point. The issue must have remained open through
   Ship and Validate — closing here signals full delivery, not just code merge.

## Guardrails

- Do not promote when required evidence is missing.
- Do not silently accept unresolved high-risk items.
- Do not replace Release Trail history; append a new entry.
