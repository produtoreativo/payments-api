---
name: finish
description: Close technical work by delivering a fully autonomous Pull Request. Emits Finish.Started and Finish.Completed via prodops_emit_event.
---

# FINISH

Use este skill para fechar uma tarefa entregando um Pull Request completamente
autônomo, com evidência de qualidade explícita.

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

O Finish **não** implementa nem lê código de produto (isso é Hack), **não**
executa a pipeline remota (isso é o CI), e **não** reescreve decisões de produto
(isso é upstream).

## Steps

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

| Step | Arquivo | Quando usar |
|---|---|---|
| `validate` | [steps/validate/SKILL.md](steps/validate/SKILL.md) | Antes do push — replicar localmente o que a pipeline remota vai executar |
| `review` | [steps/review/SKILL.md](steps/review/SKILL.md) | Confirmar que as condições para auto aprovação segura estão presentes no repositório |
| `request` | [steps/request/SKILL.md](steps/request/SKILL.md) | Abrir o PR com título e body segundo o template, com auto-merge configurado |

Quando invocado com um argumento de step (`/finish <step>`), execute apenas
aquele step. Caso contrário, execute o fluxo completo em ordem. Se o step pedido
não estiver listado, execute o fluxo completo.

## Contexto de entrada obrigatório

Antes de começar, o agente precisa ter:

- `work-item-id` — o número da issue no GitHub da Feature
- `iteration-id` — o identificador do Iteration Plan
- `actor.player` — o player atual (`claude`, `codex` ou `copilot`)
- `correlation-id` — o UUID do fluxo de Delivery fornecido pelo runner da
  cadeia. Se invocado isoladamente, gerar um novo UUID.

## Pré-condições

1. `prodops/skills/prodops-emit-event/SKILL.md` foi lido.
2. A ferramenta está disponível em `prodops/runtime/tools/emit-event/scripts/emit-event`.

## Fase: Finish.Started

**Momento**: após o contexto de entrada ser verificado, antes de qualquer
trabalho de gate de qualidade começar.

Emitir:

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

Se a ferramenta retornar `status: error`: reportar o erro, corrigir a entrada,
não prosseguir.

## Fase: Finish.Completed

**Momento**: após todos os gates de qualidade passarem e a evidência ser
registrada no Release Trail — antes de reportar sucesso.

Emitir usando o **mesmo `correlation-id`** do Finish.Started:

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

Não emitir `Finish.Completed` se qualquer gate de qualidade falhar ou se a
evidência estiver incompleta.

## Entradas

- `AGENTS.md`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- `prodops/exec/manifest.yaml` — comandos e critérios canônicos dos gates
- Diff atual e saída dos testes

## Fluxo

Quando invocado sem argumento de step, execute em ordem:

1. Verificar contexto de entrada (work-item-id, iteration-id, actor, correlation-id).
2. Emitir Finish.Started.
3. **[validate](steps/validate/SKILL.md)** — rodar a suíte de análise estática
   (format, lint, cobertura, build) mais a aceitação quando comportamento ou
   contratos mudaram. Se algum falha localmente, o passo falha e **não se
   avança**: a correção pertence ao ciclo TDD do Hack, então retorne ao
   [`hack tdd`](../hack/steps/tdd/SKILL.md) e só reexecute `validate` depois de
   fechar em verde — `validate` não escreve código. Falhar na pipeline remota
   depois de um push custa mais (retrabalho, notificações, PR vermelho) do que
   falhar localmente antes.
4. Confirmar que artefatos ProdOps foram atualizados apenas onde impactados.
5. Confirmar que evidência existe no Release Trail.
6. **[review](steps/review/SKILL.md)** — confirmar que a pipeline tem os checks
   obrigatórios, que a branch protection na branch de destino os exige, e que
   não há reviewer obrigatório bloqueando o auto-merge. Condição ausente é um
   **bloqueador** a registrar antes de ativar auto aprovação.
7. **push origin** — após `validate` limpo e `review` sem bloqueadores, publicar
   os commits na **branch de origem** (a branch da qual a atual foi derivada),
   sem force push:

   ```bash
   git push origin HEAD:<branch-de-origem>
   ```
8. **[request](steps/request/SKILL.md)** — abrir o PR com o template preenchido
   com evidências, executar auto-approval e ativar auto-merge imediatamente após
   a criação (`gh pr merge <number> --auto --squash`), e atualizar o Release
   Trail com o link do PR e o status do auto-merge. O auto-merge enfileira o
   squash para executar assim que os checks obrigatórios passarem. O agente
   **não** espera ocioso.
9. Verificar que workflows existentes estão válidos e que o repositório está apto para execução automática.
10. Registrar explicitamente qualquer item incompleto — Finish NÃO conclui com itens abertos.
11. Emitir Finish.Completed assim que o auto-merge estiver ativo, o PR confirmado
    aberto e todos os requisitos satisfeitos.

## Guardrails

- Não marcar trabalho como completo sem evidência.
- Não esconder testes pulados; registrar o motivo.
- Não expandir escopo durante o Finish.
- Se qualquer requisito não puder ser satisfeito, o Finish NÃO conclui. Parar e investigar.
- Não emitir `Finish.Completed` antes do PR estar criado e de todos os gates de qualidade passarem.
- Falhas de auto-approval e auto-merge são bloqueadores — investigar antes de prosseguir.
- Não fazer force push.
- Não fazer merge manual. Auto-merge é o único caminho de merge autorizado a
  partir do Finish.
- Não ativar auto aprovação enquanto a branch protection não estiver configurada.
- Não emitir `Finish.Completed` antes do auto-merge estar ativo no PR.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Full quality gate definitions and Definition of Done |
