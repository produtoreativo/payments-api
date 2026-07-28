---
name: bootstrap
description: Prepare the local environment required by a ProdOps execution before Git flow, tests, or implementation begin. Emits Bootstrap.Started, Bootstrap.Dependencies.Installed, Bootstrap.Services.Ready, Bootstrap.Smoke.Passed, and Bootstrap.Completed via prodops_emit_event.
---

# BOOTSTRAP

Bootstrap prepares the execution environment and records its lifecycle via `prodops_emit_event`. It does not assess product readiness, read implementation code or tests, create branches, or implement behavior.

Product readiness belongs to the `/downstream` orchestrator. Git flow belongs to `/hack start`.

## Required input context

Before starting, read the context capsule at
`prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`.
All fields below must be available — either from the capsule or explicitly provided by the caller:

- `work-item-id` — from capsule field `work-item-id` (issue number da iteração corrente)
- `iteration-id` — from capsule field `iteration-id`
- `correlation-id` — from capsule field `correlation-id` (gerado em `Delivery.Plan.Bootstrap.Issue.Entered`)
- `actor.player` — from capsule field `actor-player`
- `plan-bootstrap-path` — from capsule field `plan-bootstrap-path`

If the capsule is absent or any field is blank, ask the caller to provide them before proceeding. Do not generate placeholder values.

## Fast path — Plan Bootstrap already ran

Before executing any Bootstrap work, read `plan-bootstrap-path` da capsule (ou resolver `ITERATION_DIR/runtime/plan-bootstrap.json`) e verificar:

If the file exists and contains `"status": "completed"`:

1. Emit `Delivery.Bootstrap.Started` with `"fast-path": true` in the payload.
2. Emit `Delivery.Bootstrap.Completed` with `"fast-path": true` in the payload — using the same `correlation-id`.
3. Report to caller: `Bootstrap fast path — environment ready from Plan Bootstrap (iteration: <iteration-id>)`.
4. Stop. Do not run Bootstrap work below.

If the file does not exist or `status != "completed"`: proceed with the full flow below.

---

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read and the agent understands how to invoke the tool.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.
3. The repository is accessible from the current working directory.

## Phase: Bootstrap.Started

**Moment**: after input context is verified, before any Bootstrap work begins.

Generate a correlation ID (UUID) for this Bootstrap execution. Use this same UUID for the Bootstrap.Completed call.

Emit:

```json
{
  "event": "Delivery.Bootstrap.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<generated-uuid>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

If the tool returns `status: error` (exit 1 or 2): report the error to the caller, fix the input, and do not proceed with Bootstrap work until the event is accepted.

If the tool returns `status: accepted` (exit 0): record the `event-id` for tracing and proceed.

## Bootstrap work

Execute as etapas abaixo em ordem. Cada etapa tem um evento de checkpoint — não emitir o evento se a etapa falhar. Em caso de falha, emitir `Delivery.Block.Declared` e parar.

### Etapa 1 — Verificar runtimes e CLIs

Identificar os pacotes e serviços requeridos pelo repositório. Verificar que os runtimes e ferramentas de linha de comando necessários estão disponíveis (ex: `node`, `npm`, `docker`). Esta etapa não emite evento — falha coberta por `Block.Declared`.

### Etapa 2 — Instalar dependências

Instalar dependências usando o gerenciador de pacotes declarado pelo repositório.

**Momento**: após a instalação completar sem erros.

Emitir `Delivery.Bootstrap.Dependencies.Installed`:

```json
{
  "event": "Delivery.Bootstrap.Dependencies.Installed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

### Etapa 3 — Subir infraestrutura local

Preparar a infraestrutura local através dos scripts de setup do repositório (ex: Docker, LocalStack, banco local), que também ativam os Git hooks do Commit Workflow (`core.hooksPath`). Verificar que todos os serviços requeridos estão reachable.

**Momento**: após todos os serviços estarem acessíveis.

Emitir `Delivery.Bootstrap.Services.Ready`:

```json
{
  "event": "Delivery.Bootstrap.Services.Ready",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

### Etapa 4 — Verificar variáveis de ambiente

Confirmar que os nomes das variáveis de ambiente requeridas existem. Não ler nem expor valores, tokens, credenciais ou PII. Esta etapa não emite evento — falha coberta por `Block.Declared`.

### Etapa 5 — Executar smoke gate

Executar o smoke gate definido em `prodops/exec/manifest.yaml`.

**Momento**: após o smoke gate passar sem erros.

Emitir `Delivery.Bootstrap.Smoke.Passed`:

```json
{
  "event": "Delivery.Bootstrap.Smoke.Passed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

## Phase: Bootstrap.Completed

**Momento**: após `Bootstrap.Smoke.Passed` ser aceito — todas as etapas completaram com sucesso.

Emitir usando o mesmo `correlation-id` gerado em Bootstrap.Started:

```json
{
  "event": "Delivery.Bootstrap.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

Se o tool retornar `status: error` para Bootstrap.Completed: reportar o erro explicitamente. Não inventar um evento `Completed`; a timeline mostrará apenas `Bootstrap.Started` e os checkpoints até onde chegou.

Se o tool retornar `status: skipped` (exit 4): o evento já foi registrado. Aceitável se o Bootstrap rodou duas vezes com o mesmo correlation ID; continuar.

## Guardrails

- Do not read or modify production implementation code.
- Do not inspect or execute behavior tests; those belong to Hack and Finish.
- Do not create, switch, merge, rebase, stash, or delete Git branches.
- Do not read or create OBCs, BDD Features, risks, Reliability Plans or Iteration Plan entries.
- Do not generate a context capsule.
- Do not expose `.env` values, tokens, credentials or PII.
- Do not silently discard local work.
- Do not call GitHub, Datadog, or any external service directly. All external state is managed by `prodops_emit_event`.
- Do not construct a CloudEvent manually.
- Do not emit Bootstrap.Completed if the completion gate has not been reached.

## Post-conditions

- Dependencies are installed.
- Required local services are available.
- The Commit Workflow Git hooks are active (`core.hooksPath` set to the
  capability's `hooks/` directory).
- Environment configuration requirements are known without secrets being exposed.
- The smoke gate passes, or the environment blocker is explicit.
- Timeline for `work-item-id` contains `Delivery.Bootstrap.Started`, `Bootstrap.Dependencies.Installed`, `Bootstrap.Services.Ready`, `Bootstrap.Smoke.Passed`, and `Delivery.Bootstrap.Completed`.
- GitHub Project shows `oem-state: BOOTSTRAPPING` updated after Started; last-event updated after Completed.
- `/hack start` can establish the Git flow after Downstream readiness is reached.
