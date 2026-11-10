---
name: obc
description: Cria ou corrige um Local OBC seguindo o template prodops/templates/obcs/local-obc.md. Use para criar um OBC novo a partir de uma decisão já tomada, ou para auditar e corrigir um OBC existente (seções faltando, Status fora do padrão, eventos que não existem no código, SLIs sem fonte). Verifica o resultado com scripts/check-obc.sh.
---
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/obc/SKILL.md
     Player:    claude
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: 2026-11-10T17:04:50Z
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill obc
-->

# OBC — criar ou corrigir um Local OBC

Esta skill produz ou corrige um **Local OBC** (`prodops/artifacts/obcs/<slug>.md`) de acordo com o template
[`prodops/templates/obcs/local-obc.md`](../../templates/obcs/local-obc.md) e a definição em
[`prodops/framework/obc.md`](../../framework/obc.md). O OBC é a fonte de verdade do contrato; esta skill nunca
gera informação paralela que o substitua.

## Quando usar

| Situação | Modo |
|---|---|
| Existe uma decisão canônica (experimento concluído, decisão de Assessment, sinal de Operation, Business Intent aprovada) e ainda não existe OBC | `create` |
| O OBC existe mas não segue o template, ou foi apontado como divergente | `fix` |
| Só quero saber o que está errado, sem alterar nada | `check` |

Não use esta skill para:
- registrar uma decisão de negócio que ainda não foi tomada — pare e peça a decisão (veja Guardrails);
- alterar BDD Features, código ou Reliability Plan — isso é Delivery/Assessment;
- OBC **global** (`global-obc.md`), que tem outra estrutura e vive no repositório de portfólio.

## Entrada necessária

- `modo`: `create`, `fix` ou `check`.
- `slug`: identificador da capability (ex.: `chargeback-handling`). Em `fix` e `check`, é o nome do arquivo existente.
- Em `create`: o **gatilho canônico** (caminho do experimento, decisão de Assessment, Business Intent ou Issue).

## Pré-leitura obrigatória

1. [`prodops/templates/obcs/local-obc.md`](../../templates/obcs/local-obc.md) — estrutura e regras (os comentários `<!-- -->` são instruções).
2. [`prodops/framework/obc.md`](../../framework/obc.md) — estados, ciclo de vida, rastreabilidade, localização.
3. Em `fix`/`check`: o OBC inteiro. Em `create`: a Business Intent, o Business Signal e o BDD (se existir).

## Onde o OBC vive

| Estado | Local |
|---|---|
| Draft / Refining dentro de um experimento Upstream | `prodops/artifacts/experiments/<NNN-slug>/obcs/<slug>.md` |
| Committed ou posterior | `prodops/artifacts/obcs/<slug>.md` |

Não mova um OBC de experimento para `artifacts/obcs/` aqui — isso é o step `upstream/move-to-downstream`.

## Fontes de verdade (de onde sai cada seção)

Nunca preencha uma seção por suposição. Cada uma tem uma fonte:

| Seção do OBC | Fonte |
|---|---|
| Metadados, Status | Iteration Plan (`prodops/artifacts/plans/iteration-plan.md`), `iterations/<vX.Y.Z>/plan.md` |
| Origem | `prodops/artifacts/business-signals/`, `business-intents/`, tracking list |
| Business Outcome, Escopo, Regras de Negócio | Business Intent, BDD Feature, decisão de origem |
| Critérios de Aceite | cenários de `prodops/artifacts/bdd/<slug>.feature` (cada critério aponta para ≥ 1 cenário) |
| Contexto Enterprise | Product Deck e Service Deck (`prodops/artifacts/product/context/`) |
| **Observable Events** | **o código** — veja a regra de nomes abaixo |
| APIs, Response Contract | controllers e DTOs em `api/src/modules/**` |
| Initial SLIs | OBC existente, Reliability Plan, métricas em `api/src/observability/metrics.ts` e `event-storming/plan.json` |
| Riscos | `prodops/artifacts/risks/risks.md`, Reliability Plan |
| Dependências | código (módulos e providers), `prodops/artifacts/architecture/overview.md` |
| Decisões | experimento, trail ou Issue que originou a mudança |

## Regra de nomes de evento (a mais importante)

Eventos de negócio seguem a convenção **`payments.<agregado>.<fato>`** (minúsculas, snake_case, inglês) — regras, catálogo e duplicatas eliminadas em [`prodops/artifacts/architecture/domain-events.md`](../../artifacts/architecture/domain-events.md). A fonte única dos nomes no código é `api/src/events/payments-events.ts`.

O nome na coluna `Event` deve ser **idêntico** ao evento realmente emitido no código. Chaves de observabilidade (`event_key`) e tipos de webhook externo não seguem esta convenção. Para descobrir o que existe:

```bash
# eventos de domínio (EventEmitter)
grep -rn "\.emit(" api/src --include='*.ts' | grep -v '\.spec\.'
# chaves de observabilidade em português (emitObservable) e event_key em inglês
grep -rhoE "'pagamento(\.[a-z_]+)+'" api/src | sort -u
grep -rn "event_key:" api/src | grep -v '\.spec\.'
# eventos já mapeados para o dashboard
jq -r '.customEvents[].title' prodops/artifacts/event-storming/plan.json | sort -u
```

Para cada evento do OBC, classifique a coluna **Situação**:

| Situação | Quando |
|---|---|
| `Emitido` | o nome exato existe no código |
| `Planejado` | o contrato promete o evento, mas o código ainda não o emite |

**Nunca** renomeie um evento do OBC "para ficar parecido" com o do código sem confirmar que é o mesmo comportamento, e **nunca** invente um nome. Se o evento prometido não existe, marque `Planejado` e registre a divergência no relatório — decidir entre implementar o evento ou remover a promessa é decisão do dono do OBC, não da skill. Um OBC `Operational` não pode ter eventos `Planejado`.

## Fluxo — modo `create`

1. **Confirmar o gatilho canônico.** Se não houver experimento concluído, decisão de Assessment, sinal de Operation ou Business Intent aprovada, **pare** e peça ao usuário. Não crie OBC sem gatilho.
2. **Verificar duplicidade**: `ls prodops/artifacts/obcs prodops/artifacts/experiments/*/obcs` — se já existir OBC da capability, mude para `fix`.
3. **Copiar o template** para o local do estado (tabela acima), renomeando para `<slug>.md`.
4. **Preencher cada seção** a partir da sua fonte. O que não tiver fonte documentada vira `[apurar]` — nunca um valor inventado (SLO, meta, nome de stakeholder, data).
5. **Estado inicial**: `Draft` (ou `Refining`). Passar para `Committed` exige aprovação do Owner (PM + Tech Lead) e todas as seções "obrigatórias para Committed" completas — a skill **não** promove sozinha.
6. **Remover** as seções opcionais que não se aplicam (APIs, Response Contract, "Em linguagem executiva") e os comentários `<!-- -->`.
7. **Rodar a verificação** (abaixo) e corrigir até não haver falhas que dependam só de edição.
8. **Criar a versão EN** (`<slug>.en.md`) apenas se o projeto mantiver par PT/EN para os OBCs; caso contrário, registre no relatório que ela não foi gerada.

## Fluxo — modo `fix`

1. **Auditar**: `scripts/check-obc.sh prodops/artifacts/obcs/<slug>.md` e guardar a saída como relatório "antes".
2. **Mapear o conteúdo existente para o template**, sem perder informação:

   | Se o OBC tem… | Mover para… |
   |---|---|
   | `**Status:** x`, `DS-ID`, `Iteration`, `Last updated` no topo | `## Metadados` e `## Status` |
   | "Trigger", "Pre-conditions", "Observable Behavior Contract" | `## Business Outcome`, `## Regras de Negócio`, `## Escopo` |
   | "Premortem" | `## Riscos` |
   | "Fora de escopo" / "Scope" | `## Escopo` |
   | texto longo após o estado em `## Status` ("Downstream. Status `Entrou` em…") | linha `**Rastreado em:**`; o estado fica sozinho |
   | tabela de eventos sem Situação | adicionar a coluna e classificar cada linha |
   | tabela de SLIs sem Fonte | adicionar a coluna `Fonte` |

3. **Corrigir o Status**: exatamente um de `Draft | Refining | Committed | In Delivery | Operational | Archived`. Escolha pelo que está **comprovado** (Iteration Plan, PR mergeado, release trail) — não deixe um OBC entregue como `Committed`/"Entrou" se há evidência de que está em produção, mas confirme com o usuário antes de marcar `Operational`.
4. **Reconciliar os eventos** com o código (regra de nomes) e classificar a Situação.
5. **Preencher o que falta** com `[apurar]` quando não houver fonte (Origem, Contexto Enterprise, Riscos, Dependências, Decisões).
6. **Preservar o idioma e o estilo** do OBC existente; manter o par `.en.md` em sincronia se existir (ou avisar que ficou defasado).
7. **Registrar a mudança** em `## Decisões` (data, o que foi corrigido, por quê, fonte).
8. **Rodar a verificação** e produzir o relatório "depois".

## Fluxo — modo `check`

Apenas executa a verificação e reporta. Não edita nenhum arquivo.

## Verificação

```bash
prodops/skills/obc/scripts/check-obc.sh prodops/artifacts/obcs/<slug>.md
# OBCs de plataforma/framework, cujos eventos não são emitidos por api/src:
prodops/skills/obc/scripts/check-obc.sh prodops/artifacts/obcs/<slug>.md --skip-code-events
```

O script confere: seções obrigatórias, estado único e válido, Origem rastreável, ausência de placeholders `<...>` (a partir de Committed), coluna Situação, nomes de evento contra o código, coluna Fonte nos SLIs, BDD existente e caminhos `prodops/…` citados. Exit 0 = sem falhas.

Falhas que **não** se resolvem só editando o OBC (ex.: evento prometido que o código não emite, BDD inexistente) não bloqueiam a skill: elas vão para o relatório como **pendências de decisão**.

## Saída esperada (relatório)

```
OBC: <slug>   modo: <create|fix|check>
Antes:  <N falhas, M avisos>      Depois: <N falhas, M avisos>
Alterado: <seções criadas/movidas/corrigidas>
[apurar]: <campos sem fonte, para o dono preencher>
Pendências de decisão:
  - <evento X prometido e não emitido: implementar ou remover a promessa?>
  - <estado Operational a confirmar com evidência Y>
```

## Guardrails

- **Não inventar** decisões de negócio, SLOs, metas, stakeholders, datas ou nomes. Sem fonte → `[apurar]`.
- **Não promover** o estado para `Committed`/`Operational` sem evidência e confirmação do Owner.
- **Não alterar código, testes, BDD Features ou Reliability Plan.** Se um evento precisa passar a ser emitido, isso é um item de Delivery, não desta skill.
- **Não apagar conteúdo** do OBC existente: tudo que não encaixa no template vai para a seção mais próxima ou para `## Decisões`.
- **Não editar o template** (`templates/obcs/*.md`) a partir desta skill.
- **Commit** só quando quem chamou autorizar (ex.: `diligence/capture`, `upstream/move-to-downstream`). Mensagem: `docs(obc): <create|fix> <slug>`.
- Se a criação/correção exigir uma decisão de produto que não está documentada, **pare e exponha como bloqueador**.

## Integração com outras skills

- `diligence/capture` — ao criar OBC novo, deve chamar esta skill em modo `create` em vez de copiar o template à mão.
- `upstream/move-to-downstream` — antes de promover um OBC para `artifacts/obcs/`, rodar `check` e exigir exit 0.
- `downstream` — o pré-requisito "OBC committed" pode ser validado com `check`.

Esta skill não emite eventos de Delivery (`prodops_emit_event`): ela não é uma fase do CI Sync/Async.
