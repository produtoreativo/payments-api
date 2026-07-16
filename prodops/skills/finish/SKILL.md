---
name: finish
description: Close technical work with quality gates. Emits Finish.Started and Finish.Completed via prodops_emit_event.
---

# FINISH

Use este skill para fechar o CI Sync: validar a qualidade localmente, garantir
que as regras de PR automático estão válidas, publicar os commits e abrir o PR
em modo auto aprovação.

O Finish tem **três steps invocáveis** mais um passo de publicação, cada um com
responsabilidade única e uma fronteira explícita do que **não** é sua
responsabilidade — para que cada passo seja auditável isoladamente, sem efeitos
colaterais cruzados (um passo de validação não commita, um passo de review não
executa pipeline, etc.):

- **`validate` — análise estática de qualidade** (roda todos os passos de
  análise estática; a exceção dinâmica única é a aceitação/integração).
- **`review` — inspeção da pipeline** (garante que as regras para um PR
  automático estão válidas, sem executar a pipeline).
- **push origin** — publica os commits na branch de origem (git, sem force push).
- **`request` — abre o PR em modo auto aprovação** (auto-merge se o CI aprovar).

Quando invocado com um argumento de step (`/finish <step>`), execute apenas
aquele step. Caso contrário, execute o fluxo completo em ordem.

O Finish **não** implementa nem lê código de produto (isso é Hack), **não**
executa a pipeline remota (isso é o CI), e **não** reescreve decisões de produto
(isso é upstream).

## Steps

| Step | File | When to use |
|---|---|---|
| `validate` | [steps/validate/SKILL.md](steps/validate/SKILL.md) | Antes do push — replicar localmente o que a pipeline remota vai executar |
| `review` | [steps/review/SKILL.md](steps/review/SKILL.md) | Confirmar que as condições para auto aprovação segura estão presentes no repositório |
| `request` | [steps/request/SKILL.md](steps/request/SKILL.md) | Abrir o PR com título e body segundo o template, com auto-merge configurado |

Se o step pedido não estiver listado, execute o fluxo completo.

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
- `prodops/exec/manifest.yaml` — comandos e critérios canônicos dos gates
- Current diff and test output

## Flow

Quando invocado sem argumento de step, execute em ordem:

1. **[validate](steps/validate/SKILL.md)** — rodar a suíte de análise estática
   (format, lint, cobertura, build) mais a aceitação quando comportamento ou
   contratos mudaram. Se algum falha localmente, o passo falha e **não se
   avança**: a correção pertence ao ciclo TDD do Hack, então retorne ao
   [`hack tdd`](../hack/steps/tdd/SKILL.md) e só reexecute `validate` depois de
   fechar em verde — `validate` não escreve código. Falhar na pipeline remota
   depois de um push custa mais (retrabalho, notificações, PR vermelho) do que
   falhar localmente antes.
2. **[review](steps/review/SKILL.md)** — confirmar que a pipeline tem os checks
   obrigatórios, que a branch protection na branch de destino os exige, e que
   não há reviewer obrigatório bloqueando o auto-merge. Condição ausente é um
   **bloqueador** a registrar antes de ativar auto aprovação.
3. **push origin** — após `validate` limpo e `review` sem bloqueadores, publicar
   os commits na **branch de origem** (a branch da qual a atual foi derivada),
   sem force push:

   ```bash
   git push origin HEAD:<branch-de-origem>
   ```
4. **[request](steps/request/SKILL.md)** — abrir o PR com o template preenchido
   com evidências e ativar auto-merge imediatamente após a criação
   (`gh pr merge <number> --auto --squash`), e atualizar o Release Trail com o
   link do PR e o status do auto-merge. O auto-merge enfileira o squash para
   executar assim que os checks obrigatórios passarem. O agente **não** espera
   ocioso — emite `Finish.Completed` assim que o auto-merge estiver ativo e o PR
   confirmado aberto.

## Guardrails

- Não marcar trabalho completo sem evidência.
- Não esconder testes pulados; registrar o motivo.
- Não expandir escopo durante o Finish.
- Não fazer force push.
- Não fazer merge manual. Auto-merge é o único caminho de merge autorizado a
  partir do Finish.
- Não ativar auto aprovação enquanto a branch protection não estiver configurada.
- Não emitir `Finish.Completed` antes do auto-merge estar ativo no PR.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Full quality gate definitions and Definition of Done |
