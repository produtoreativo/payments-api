---
name: downstream
description: Orquestra a execução do fluxo de entrega governado do ProdOps. Sem argumentos, lê o Iteration Plan e executa os itens com status Entrou em ordem de prioridade. Com Downstream ID, executa apenas aquele item.
---

# DOWNSTREAM

Downstream é o modo de compromisso do Framework ProdOps. Toda entrega passa obrigatoriamente pelos gates de readiness e pelos ciclos CI Sync e CI Async. O orchestrator nunca bypassa pré-requisitos nem inventa artefatos.

## Downstream ID

Cada item do Downstream possui um **Downstream ID** — o identificador canônico usado pelo skill e por humanos para referenciar um item específico. O Downstream ID é composto pelo número da GitHub Issue associada à capability:

```
DS-<issue-number>
```

Exemplos: `DS-40` (create-invoice-boleto), `DS-76` (create-invoice-pix).

O Downstream ID é resolvido pelo `/readiness` durante o gate de readiness e registrado no `context.md`. Humanos podem usá-lo diretamente nos comandos abaixo.

## Comandos

| Comando | Escopo |
|---|---|
| `/downstream` | Lê o Iteration Plan, lista os itens `Entrou` em ordem de prioridade e executa CI Sync um a um |
| `/downstream <DS-ID>` | Executa CI Sync apenas para o item com aquele Downstream ID (ex: `/downstream DS-40`) |
| `/downstream ci-sync <DS-ID ou capability>` | Readiness → Bootstrap → Hack → Sync → Finish para o item indicado |
| `/downstream ci-async <DS-ID ou capability>` | Verifica evidências do CI Sync → Ship → Validate → Promote |
| `/downstream full <DS-ID ou capability>` | CI Sync completo → CI Async completo |
| `/readiness <capability>` | Verifica pré-requisitos e gera context capsule — sem iniciar implementação |

Use `/readiness` quando quiser verificar gates e preparar o context capsule sem iniciar implementação. Use `/downstream <DS-ID>` quando estiver pronto para iniciar Bootstrap e Hack de um item específico.

## Modo sem argumentos — `/downstream`

Quando invocado sem argumentos:

1. Ler `prodops/artifacts/plans/iteration-plan.md`.
2. Coletar todos os itens com status `Entrou` na tabela "Iteration Plan recomendado".
3. Apresentar a fila de execução na ordem em que aparecem no Iteration Plan (ordem de prioridade do PM/PO):

```
Fila Downstream — Iteration Plan ativo
────────────────────────────────────────
1. DS-40  create-invoice-boleto
...
```

4. Para cada item na fila, em ordem, sem pedir confirmação entre eles:
   a. Executar `/readiness <capability>` — se falhar, reportar blockers e **parar toda a fila**.
   b. Executar CI Sync: Bootstrap → Hack → Sync → Finish.
   c. Reportar evidências do item concluído e avançar automaticamente para o próximo.

Parar apenas quando: (1) um readiness falhar, (2) um gate de qualidade não passar, (3) a fila se esgotar.

## Modo por Downstream ID — `/downstream DS-<n>`

Quando invocado com um Downstream ID:

1. Resolver a capability a partir do número de issue (`DS-40` → issue #40 → `create-invoice-boleto`).
2. Verificar que o item consta no Iteration Plan com status `Entrou`.
3. Executar `/readiness <capability>`.
4. Se Ready: confirmar com o usuário e executar CI Sync.

## Gate de readiness

Antes de executar qualquer ciclo, avaliar a capability contra todos os pré-requisitos atuais do Downstream:

1. OBC committed em `prodops/artifacts/obcs/`.
2. BDD Feature committed em `prodops/artifacts/bdd/`.
3. Riscos documentados em `prodops/artifacts/risks/risks.md`.
4. Item no Iteration Plan com status `Entrou`.
5. Reliability Plan (quando há movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração de persistência/segurança).

Tratar como **Downstream Declared** enquanto houver pré-requisitos ausentes. Declarar **Downstream Ready** apenas após todos os gates passarem. **Delivery Started** começa somente quando o Bootstrap inicia.

Quando todos os pré-requisitos existirem:

1. Gerar `prodops/exec/cards/<card-slug>/context.md` a partir de `prodops/templates/delivery/context-capsule.md`. O capsule é gerado pelo readiness do Downstream, não pelo Bootstrap.
2. Emitir o evento `Delivery.Plan.Entered` para a issue, definindo `oem-state = PENDING` no GitHub Project. Isso posiciona o item na coluna PENDING do board antes do Bootstrap iniciar.

```json
{
  "event": "Delivery.Plan.Entered",
  "work-item-id": "<issue-number>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<new-uuid>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

O `correlation-id` gerado aqui é o correlation-id do flow inteiro — propagado para Bootstrap, Hack, Sync, Finish, Ship, Validate e Promote.

## CI Sync

1. **Bootstrap** — preparar dependências, infra local e smoke gate apenas.
2. **Hack** — executar `start`, `tdd` e `commit`; `start` é dono do Git flow e da criação de branch.
3. **Sync** — sincronizar a branch e alinhar artefatos ProdOps impactados.
4. **Finish** — executar quality gates finais e preparar o PR.

## CI Async

1. Confirmar que evidências do CI Sync existem e foram aprovadas.
2. **Ship** — build, publicação e deploy conforme a política de release atual. Acionar `staging-deploy.yml` via `gh workflow run` e aguardar conclusão antes de Validate.
3. **Validate** — validar BDD, OBC, observabilidade, SLOs e riscos no ambiente alvo.
4. **Promote** — aplicar gates de aprovação e registrar no Release Trail.

## Guardrails

- Não iniciar uma fase de Delivery enquanto o readiness estiver incompleto.
- Não tratar uma entrada no Iteration Plan sozinha como readiness.
- Não inventar OBCs, cenários BDD, riscos, reliability targets ou critérios de aceite.
- Não fazer o Bootstrap executar Git flow ou trabalho de contexto de produto.
- Não fazer ship de trabalho suportado apenas por evidência Upstream.
- Não pular quality gates sem decisão explícita registrada e aceite de risco.
- Não promover itens com risco alto não resolvido sem aceite explícito.
- Não criar GitHub Issues ou PRs sem declarar artifact_type, artifact_id, operation e journey.
- No modo sem argumentos, parar apenas em falha de readiness ou falha de gate — nunca aguardar confirmação entre itens.
- Usar o padrão canônico de título de Work Item: `[Artifact ID]: descrição`.

## Referências

→ [Readiness SKILL.md](../readiness/SKILL.md)
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)
→ [Iteration Plan](../../artifacts/plans/iteration-plan.md)
