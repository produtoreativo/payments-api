---
name: diligence/trail
description: Post a phase trail comment on the iteration tracking issue whenever a key Delivery event is received. Triggered by the dispatcher — never invoked directly by Delivery skills.
---

# DILIGENCE SYNC → TRAIL

**Responsabilidade:** manter o histórico de fases na issue de acompanhamento da iteração. Trail é a única skill que escreve nessa issue — Delivery nunca comenta nela diretamente.

Trail não emite eventos Diligence. Não altera OBCs, backlogs ou timelines. Apenas posta o comentário certo, no momento certo, na issue certa.

## Contexto de entrada

O dispatcher invoca Trail com o contexto do evento Delivery que o acionou:

| Campo | Origem |
|---|---|
| `cloud-event-type` | tipo do evento que disparou o trail |
| `work-item-id` | número da issue da feature (pode ser `null` para eventos de plano) |
| `iteration-id` | versão da iteração (ex: `v0.10.0`) |
| `correlation-id` | UUID da execução corrente |
| `actor.player` | agente em execução |

## Ação

### 1. Localizar a issue de acompanhamento

Resolver `ITERATION_DIR = prodops/artifacts/iterations/<iteration-id>/runtime/` e ler `plan-bootstrap.json`:

```bash
PLAN_BOOTSTRAP="prodops/artifacts/iterations/<iteration-id>/runtime/plan-bootstrap.json"
PLAN_ISSUE=$(jq -r '."plan-issue"' "$PLAN_BOOTSTRAP")
```

Se `plan-bootstrap.json` não existir ou `plan-issue` for nulo: **parar silenciosamente** — não há issue de acompanhamento registrada ainda. Não criar issue, não emitir erro.

### 2. Selecionar o template de comentário pelo evento

| `cloud-event-type` | Título do comentário | Emoji |
|---|---|---|
| `prodops.delivery.plan.bootstrap.completed` | Plan Bootstrap — Concluído | 🚀 |
| `prodops.delivery.plan.bootstrap.issue.entered` | Issue Entrou no Plano | 📋 |
| `prodops.delivery.bootstrap.completed` | Bootstrap — Concluído | ⚙️ |
| `prodops.delivery.hack.completed` | Hack — Implementação Concluída | 🔨 |
| `prodops.delivery.sync.completed` | Sync — PR Aprovado e Merged | 🔀 |
| `prodops.delivery.finish.completed` | Finish — Quality Gates Passaram | ✅ |
| `prodops.delivery.ship.completed` | Ship — Deploy Staging Concluído | 🚢 |
| `prodops.delivery.validate.completed` | Validate — Critérios Confirmados | 🔍 |
| `prodops.delivery.plan.validated` | Plan Validated — Gate de Promote Aberto | 🎯 |
| `prodops.delivery.promote.completed` | Promote — DONE | 🏁 |
| `prodops.delivery.block.declared` | ⚠️ BLOQUEIO DECLARADO | 🚨 |
| `prodops.delivery.block.resolved` | Bloqueio Resolvido | ✅ |
| `prodops.delivery.restart.completed` | Restart Concluído | 🔄 |

### 3. Postar o comentário

```bash
gh issue comment "$PLAN_ISSUE" --body "$(cat <<'COMMENT'
## <emoji> <título> — <YYYY-MM-DD HH:MM UTC>

**Issue:** #<work-item-id> (<DS-ID> · <capability-slug>)
**Event:** `<cloud-event-type>`
**correlation-id:** `<correlation-id>`

<resumo em até 3 linhas: o que aconteceu nesta fase, evidências principais>

---
*iteration: <iteration-id> · actor: <actor.player> · diligence.trail*
COMMENT
)"
```

**Casos especiais:**

- **`plan.bootstrap.completed`** — `work-item-id` é null; omitir linha de Issue. Listar as issues do plano extraídas do `plan-bootstrap.json`:
  ```
  **Issues no plano:** #<issue-1> (<DS-ID-1>), #<issue-2> (<DS-ID-2>)
  ```

- **`plan.bootstrap.issue.entered`** — uma chamada por issue. Informar DS-ID e slug da issue que entrou.

- **`plan.validated`** — `work-item-id` é null; omitir linha de Issue. Informar que o gate de Promote está aberto para todas as issues.

- **`block.declared`** — incluir motivo do bloqueio (campo `payload.reason` do evento se disponível). Usar título com emoji vermelho para destacar urgência.

- **`promote.completed`** — incluir estado final `DONE` e confirmar que a issue foi fechada no GitHub.

### 4. Verificar saída

Se `gh issue comment` retornar erro:
- Registrar no log: `⚠️ diligence.trail: falha ao comentar na issue #<PLAN_ISSUE> — <mensagem de erro>`
- **Não propagar o erro** — falha de trail não deve interromper o fluxo Delivery.

## Post-conditions

- Comentário postado na `plan-issue` com contexto do evento que o acionou.
- Nenhum artefato do repositório modificado.
- Nenhum evento Diligence emitido.

## Guardrails

- Não comentar em `work-item-id` — Trail escreve exclusivamente na `plan-issue`.
- Não criar a `plan-issue` se ela não existir — isso é responsabilidade do Plan Bootstrap.
- Não emitir eventos Diligence.
- Não modificar OBCs, backlogs, timelines ou context capsules.
- Parar silenciosamente se `plan-bootstrap.json` não existir — Trail não bloqueia o fluxo.
- Não tentar postar um comentário genérico quando o evento não constar na tabela da Seção 2 — ignorar silenciosamente.

## Out of scope

- `trail` **não** captura estado de OBC — isso é Capture.
- `trail` **não** cria Work Items — isso é Attach.
- `trail` **não** move itens no backlog — isso é Promote.
- `trail` **não** escaneia divergências — isso é Scan.
- `trail` **não** comenta nas issues das features (`work-item-id`) — isso é responsabilidade do Downstream orchestrator (passo 6b-ii).
