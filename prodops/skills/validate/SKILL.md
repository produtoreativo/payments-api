---
name: validate
description: Validate release behavior with evidence, metrics, SLOs, and operational signals. Emits Validate.Started, Shared.Gate.Passed, and Validate.Completed via prodops_emit_event.
---

# VALIDATE

Use this skill to prove release readiness with evidence.

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

## Phase: Validate.Started

**Moment**: after input context is verified, before any validation work begins.

Emit:

```json
{
  "event": "Delivery.Validate.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "validate-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Shared.Gate.Passed

**Moment**: after acceptance evidence is collected and all quality gates pass — before emitting `Validate.Completed`.

Emit using the **same `correlation-id`**:

```json
{
  "event": "Shared.Gate.Passed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "validate-agent" },
  "payload": {}
}
```

## Phase: Validate.Completed

**Moment**: after `Shared.Gate.Passed` is accepted, before reporting success.

Emit using the **same `correlation-id`**:

```json
{
  "event": "Delivery.Validate.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "validate-agent" },
  "payload": {}
}
```

Do not emit `Validate.Completed` if evidence is incomplete or any quality gate fails.

## Plan Validate gate — após Validate.Completed

Após emitir `Validate.Completed` com sucesso, verificar se há contexto de Iteration Plan:

1. Resolver `ITERATION_DIR = prodops/artifacts/iterations/<iteration-id>/`.
2. Ler `ITERATION_DIR/runtime/plan-bootstrap.json` — se não existir, pular este bloco (execução standalone).
3. Ler ou criar `ITERATION_DIR/runtime/plan-validate.json`:
   ```json
   {
     "iteration-id": "<iteration-id>",
     "issues": {
       "<work-item-id>": "validated"
     }
   }
   ```
4. Marcar `issues.<work-item-id>: "validated"` e gravar o arquivo.
5. Verificar se **todos** os `issues` do plan-bootstrap estão marcados `"validated"`.
6. Se sim — todos validados:
   - Emitir `Delivery.Plan.Validated` com `subject: <iteration-id>` e `work-item-id: null` no payload, listando os issues no campo `"issues"`.
   - Atualizar `plan-validate.json` com `"status": "all-validated"` e `"all-validated-at": <timestamp>`.
   - Commitar o arquivo.
   - Reportar ao caller: `Plan Validated — todos os itens aprovados; Promote desbloqueado.`
7. Se não — ainda há issues pendentes:
   - Commitar o arquivo atualizado.
   - Reportar ao caller quais issues ainda não validaram (lista de pendentes).
   - **Não emitir** `Delivery.Plan.Validated`.
   - O Promote desta issue permanece bloqueado até o gate de plano passar.

## Inputs

- `AGENTS.md`
- Relevant OBCs under `prodops/`
- Relevant BDD Features in `prodops/artifacts/bdd/` (committed) or `prodops/artifacts/experiments/<NNN-slug>/features/` (exploratory)
- `prodops/artifacts/plans/reliability/`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`

## Flow

1. Identify the capability, OBC, or risk being validated.
2. Select tests, metrics, logs, events, or SLO evidence that prove it.
3. Run validation commands or inspect existing evidence.
4. Record exact commands, observed result, and remaining risk.
5. Update only impacted validation or reliability artifacts.
6. Append evidence to the Release Trail.

## Guardrails

- Do not invent metrics or SLOs.
- If an SLO is absent, record the gap in the appropriate ProdOps artifact.
- Prefer executable evidence over narrative claims.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Evidence standards, Definition of Done, Test Quality Gates |
| [`../references/engineering/tdd-prodops/observability.md`](../references/engineering/tdd-prodops/observability.md) | What to verify in logs, traces, and correlation IDs |
