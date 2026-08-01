---
name: downstream
description: Orquestra a execução do fluxo de entrega governado do ProdOps. Sem argumentos, lê o Iteration Plan e executa os itens com status Entrou em ordem de prioridade. Com Downstream ID, executa apenas aquele item.
---

# DOWNSTREAM

Downstream é o modo de compromisso do Framework ProdOps. Toda entrega passa obrigatoriamente pelos gates de readiness e pelos ciclos CI Sync e CI Async. O orchestrator nunca bypassa pré-requisitos nem inventa artefatos.

## Downstream ID

Cada item do Downstream possui um **Downstream ID** — o identificador estável da feature ao longo das iterações:

```
DS-<feature-slug-number>
```

O DS-ID identifica a **feature** (estável), não a GitHub Issue (efêmera — muda a cada iteração). O mapeamento `DS-ID → issue` é declarado no `plan.md` da iteração ativa. O agente resolve `DS-39 → issue #106` lendo a tabela de mapeamento do plano, nunca inferindo do número do DS-ID.

## Iteration Directory

Ao iniciar qualquer execução, o agente resolve o **ITERATION_DIR** a partir do `iteration-id` declarado no plano ativo:

```
ITERATION_DIR = prodops/artifacts/iterations/<iteration-id>/
```

Todos os artefatos de runtime desta iteração vivem exclusivamente dentro deste diretório:
- Timelines: `ITERATION_DIR/runtime/timelines/<issue>.json`
- Plan Bootstrap: `ITERATION_DIR/runtime/plan-bootstrap.json`
- Plan Validate: `ITERATION_DIR/runtime/plan-validate.json`
- Context capsules: `ITERATION_DIR/cards/<slug>/context.md`
- Session trails: `ITERATION_DIR/trails/`

O `--iteration-id` é propagado para todas as chamadas de `emit-event`, `append.sh`, `derive-state.sh` e `derive-diligence-state.sh`. Nenhum artefato de runtime é escrito fora do ITERATION_DIR da iteração corrente.

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

1. Ler `prodops/artifacts/plans/iteration-plan.md` → identificar a versão ativa (ex: `v0.6.0`).
2. Ler `prodops/artifacts/iterations/<version>/plan.md` → resolver `ITERATION_ID` e coletar todos os itens com status `Entrou` da tabela de escopo, usando a tabela de mapeamento DS-ID → Issue para obter os números de issue corretos.
3. Apresentar a fila de execução na ordem em que aparecem no Iteration Plan (ordem de prioridade do PM/PO):

```
Fila Downstream — Iteration Plan ativo
────────────────────────────────────────
1. DS-40  create-invoice-boleto
...
```

4. **Plan Bootstrap** — executar uma única vez antes do loop de issues:
   a. Verificar se `ITERATION_DIR/runtime/plan-bootstrap.json` já existe com `"status": "completed"`. Se sim, pular para o passo 5 (ambiente já pronto).
   b. Emitir `Delivery.Plan.Bootstrap.Started` com `subject: <iteration-id>`, `work-item-id: null` e `--iteration-id <iteration-id>`.
   c. Executar o Bootstrap work: instalar dependências, verificar runtimes e serviços locais, confirmar variáveis de ambiente, executar o smoke gate do manifest.
   d. Se qualquer etapa falhar: reportar o bloqueio e **parar toda a fila** — não iniciar nenhum issue.
   e. Emitir `Delivery.Plan.Bootstrap.Completed` com `subject: <iteration-id>` e `--iteration-id <iteration-id>`.
   f. Escrever `ITERATION_DIR/runtime/plan-bootstrap.json`:
   ```json
   {
     "iteration-id": "<iteration-id>",
     "status": "completed",
     "correlation-id": "<uuid-gerado-no-started>",
     "completed-at": "<timestamp-iso8601>",
     "issues": ["<issue-1>", "<issue-2>", "..."]
   }
   ```
   g. Commitar o arquivo no repositório antes de iniciar o loop.

5. Para cada item na fila, em ordem, sem pedir confirmação entre eles:
   a. Executar `/readiness <capability>` — se falhar, reportar blockers e **parar toda a fila**.
   b. Executar CI Sync: Bootstrap (fast path via plan-bootstrap) → Hack → Sync → Finish.
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

1. Gerar `ITERATION_DIR/cards/<card-slug>/context.md` a partir de `prodops/templates/delivery/context-capsule.md`. O capsule é gerado pelo readiness do Downstream, não pelo Bootstrap. `ITERATION_DIR` = `prodops/artifacts/iterations/<iteration-id>/`.
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

1. **Bootstrap** — quando invocado dentro do loop do `/downstream` (modo sem argumentos ou por DS-ID a partir de um plano), o Bootstrap opera em fast path se o Plan Bootstrap já completou: emite apenas os eventos Started/Completed sem re-executar dependências ou smoke gate. Em execuções isoladas (sem Plan Bootstrap), executa o fluxo completo.
2. **Hack** — executar `start`, `tdd` e `commit`; `start` é dono do Git flow e da criação de branch.
3. **Sync** — sincronizar a branch e alinhar artefatos ProdOps impactados.
4. **Finish** — executar quality gates finais e preparar o PR.

## CI Async

O CI Async opera em três fases sequenciais sobre todos os itens do plano:

**Fase 1 — Ship (por issue, em sequência)**
Para cada issue na fila do plano, em ordem:
1. Confirmar que evidências do CI Sync existem e foram aprovadas.
2. Acionar `staging-deploy.yml` via `gh workflow run` e aguardar conclusão.
3. Avançar para a próxima issue sem aguardar Validate.

**Fase 2 — Validate (por issue, em sequência)**
Para cada issue na fila do plano, em ordem:
1. Validar BDD, OBC, observabilidade, SLOs e riscos no ambiente alvo.
2. Após `Validate.Completed`: atualizar `plan-validate-<iteration-id>.json` marcando a issue como validada.
3. Após a última issue validar: emitir `Delivery.Plan.Validated` — o gate de plano passa.
4. Se qualquer Validate falhar: **parar toda a fase 3**. Nenhum Promote ocorre enquanto houver issues pendentes.

**Fase 3 — Promote (por issue, em sequência — gate de plano obrigatório)**
Só iniciada após `Delivery.Plan.Validated` emitido:
1. Para cada issue na fila do plano, em ordem: aplicar gates de aprovação e registrar no Release Trail.
2. O Promote de cada issue verifica `plan-validate-<iteration-id>.json` antes de emitir `Promote.Started`.

**Nota sobre execuções standalone** (`/downstream ci-async DS-<n>`): sem contexto de Iteration Plan, o CI Async opera por issue de forma independente (Ship → Validate → Promote) sem gate de plano.

## Protocolo de exceção — bloqueios

Quando uma fase não pode avançar (permissão negada, gate falhou, timeout, bloqueio externo):

1. Emitir `Delivery.Block.Declared` **antes de parar**, registrando o motivo no payload:

```json
{
  "event": "Delivery.Block.Declared",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

Isso seta `oem-state = BLOCKED` no GitHub Project e aciona automaticamente o Diligence Sync (`diligence.capture`) via dispatcher.

2. Reportar o bloqueio ao caller com: fase em que ocorreu, motivo, e ação necessária para resolução.

Quando o bloqueio é resolvido e o flow retoma:

3. Emitir `Delivery.Block.Resolved` **antes de continuar**, usando o mesmo `correlation-id`:

```json
{
  "event": "Delivery.Block.Resolved",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

Isso seta `oem-state = PENDING` e permite que o Bootstrap inicie novamente.

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
- Nunca parar silenciosamente — todo bloqueio deve emitir `Delivery.Block.Declared` antes de reportar ao caller.

## Referências

→ [Readiness SKILL.md](../readiness/SKILL.md)
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)
→ [Iteration Plan](../../artifacts/plans/iteration-plan.md)
