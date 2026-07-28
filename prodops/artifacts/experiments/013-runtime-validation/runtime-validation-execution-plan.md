# Runtime Validation Execution Plan

> **Localização canônica:** `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-execution-plan.md`
>
> Este documento transforma o EXP-013 em fases executáveis. É utilizado durante a Delivery da iniciativa. Não implementa o Runtime — define o que deve ser feito, em que ordem, e sob quais condições a execução deve avançar ou parar.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Título** | Runtime Validation Execution Plan |
| **Experimento** | [EXP-013](./experiment.md) |
| **Discovery Report** | [runtime-validation-discovery-report.md](./runtime-validation-discovery-report.md) |
| **Product Intent** | [PI-RUNTIME-001](../../business-intents/PI-RUNTIME-001.md) |
| **Business Signal** | [BS-RUNTIME-001](../../business-signals/BS-RUNTIME-001.md) |
| **Data de criação** | 2026-07-25 |
| **Status** | Planejado — aguarda início da execução |

---

## Visão geral das seis fases

```
Phase 1 — Environment Preparation
   │  Ambiente completo, Iteration vazia
   ▼
Phase 2 — Runtime Foundation
   │  Emissão de eventos, Datadog recebendo
   ▼
Phase 3 — Delivery Validation
   │  3 Features: Happy Path + Rework + Blocking
   ▼
Phase 4 — Diligence Validation
   │  Drift detectado, Findings reparados, COR sincronizado
   ▼
Phase 5 — Observability Validation
   │  Dashboards Delivery e Diligence coerentes
   ▼
Phase 6 — Discovery Consolidation
      Q1–Q8 respondidas → Opção A ou Opção B
```

Cada fase produz um conjunto de entregas que habilitam a fase seguinte. Nenhuma fase pode ser iniciada antes que o critério de saída da anterior esteja satisfeito.

---

## Phase 1 — Environment Preparation

### Objetivo

Garantir que todos os pré-requisitos de infraestrutura, acesso e estado inicial estejam satisfeitos antes de qualquer execução. Uma falha de ambiente descoberta durante a execução invalida evidências e contamina as respostas às perguntas do experimento.

### Checklist

#### payments-api

- [ ] Branch `main` sincronizado com origin
- [ ] Dependências instaladas e build passando localmente
- [ ] Todos os testes existentes passando (zero regressões)
- [ ] Nenhuma Feature em andamento — estado limpo

#### GitHub Project

- [ ] Projeto `ProdOps — payments-api` existente e acessível
- [ ] Custom Fields de Derived State criados ou confirmados:
  - `oem:state` (texto ou select) — último estado derivado da Timeline
  - `oem:last-event` (texto) — tipo do último evento `alters_state: true`
  - `oem:iteration` (texto) — identificador da Iteration de validação
- [ ] Pelo menos uma view configurada para filtrar por `oem:iteration`
- [ ] Token de acesso com permissão `project:write` disponível

#### Datadog

- [ ] Acesso ao workspace Datadog do payments-api confirmado
- [ ] API Key e APP Key disponíveis localmente
- [ ] Namespace de métricas definido: `prodops.runtime.validation.*`
- [ ] Destino das métricas definido (API direta, DogStatsD, ou pipeline existente)
- [ ] Pelo menos um dashboard de destino identificado (existente ou novo)

#### Credenciais e ambiente local

- [ ] `gh auth status` confirmado (GitHub CLI autenticado)
- [ ] Variáveis de ambiente documentadas: `GITHUB_TOKEN`, `DD_API_KEY`, `DD_APP_KEY`
- [ ] Projeto GitHub identificado pelo número (ex.: `gh project list --owner <owner>`)

#### Runtime local

- [ ] Consumer de Derived State mínimo definido:
  - Pode ser script manual, planilha, ou script auxiliar em `evidence/scripts/`
  - Não precisa ser automação completa — precisa ser executável de forma consistente
- [ ] Formato de registro de Event Instances definido:
  - JSON por evento em `evidence/timelines/<feature-id>/` ou Markdown estruturado
  - Cada instância deve ter: `type`, `occurred_at`, `work_item_id`, `alters_state`, `new_state` (se aplicável), `payload`
- [ ] Procedimento de sync COR definido:
  - Como o Derived State calculado será gravado nos Custom Fields do GitHub Project
  - Pode ser manual (via `gh` CLI) ou script em `evidence/scripts/`

#### Iteration de validação

- [ ] Identifier da Iteration definido: `ITER-VAL-001` (ou equivalente)
- [ ] Três Features reais do backlog selecionadas:
  - Feature A — Happy Path (sem complicações planejadas)
  - Feature B — cenário de Rework (Gate.Failed forçado em VALIDATE)
  - Feature C — cenário de Blocking (Impediment.Declared + Lookback)
- [ ] Issues GitHub criados para as três Features (ou confirmados existentes)
- [ ] Issues adicionados ao GitHub Project com `oem:iteration = ITER-VAL-001`

### Critério de saída

**Todos os itens do checklist marcados.** A execução não começa até que o ambiente esteja completamente preparado. Qualquer item não resolvido deve ser registrado como bloqueio com ação corretora antes de prosseguir.

### Entrega da Phase 1

- `evidence/environment-checklist.md` — checklist preenchido com status de cada item

---

## Phase 2 — Runtime Foundation

### Objetivo

Implementar o Runtime mínimo: emissão de Event Instances em formato canônico, cálculo de Derived State, e integração com Datadog. Esta fase valida o mecanismo fundamental antes de executar fluxos completos.

### Escopo

#### Emissão de eventos

- [ ] Definir o schema de Event Instance para esta execução (baseado no OEM):
  ```json
  {
    "type": "<Journey>.<EventType>",
    "occurred_at": "<ISO-8601>",
    "work_item_id": "<feature-id>",
    "iteration_id": "ITER-VAL-001",
    "alters_state": true | false,
    "new_state": "<STATE>" | null,
    "payload": { ... }
  }
  ```
- [ ] Emitir o primeiro evento real: `Delivery.Bootstrap.Started` para Feature A
- [ ] Registrar a instância em `evidence/timelines/feature-a/`
- [ ] Confirmar que o evento está legível e completo

#### Validação do evento

- [ ] Verificar que o campo `type` corresponde a um Event Type ativo no catálogo Delivery v2.0.0
- [ ] Verificar que `alters_state` está correto conforme o catálogo
- [ ] Verificar que `new_state` está presente (quando `alters_state: true`) ou ausente (quando `false`)
- [ ] Registrar qualquer discrepância como potencial resposta parcial a Q1 ou Q2

#### Cálculo de Derived State

- [ ] Calcular o Derived State após `Bootstrap.Started`:
  - Derived State = `new_state` do último evento com `alters_state: true` na Timeline
  - Esperado: `BOOTSTRAPPING`
- [ ] Registrar o cálculo no Consumer (script ou planilha): `evidence/derived-state-log.md`
- [ ] Sincronizar o Derived State no GitHub Project:
  - `oem:state = BOOTSTRAPPING`
  - `oem:last-event = Delivery.Bootstrap.Started`

#### Integração Datadog

- [ ] Enviar a primeira métrica ao Datadog derivada do evento:
  - Métrica: `prodops.runtime.validation.events_emitted` com tags `work_item:<feature-a>`, `event_type:Bootstrap.Started`
- [ ] Confirmar que a métrica chega ao Datadog (screenshot ou log)
- [ ] Registrar em `evidence/datadog-screenshot.md`

### Critério de saída

- Feature A com `Bootstrap.Started` registrado na Timeline
- Derived State calculado e sincronizado no GitHub Project
- Primeira métrica visível no Datadog com trace rastreável até o evento
- `evidence/derived-state-log.md` com pelo menos uma entrada
- `evidence/datadog-screenshot.md` com evidência da primeira métrica

### Entrega da Phase 2

- `evidence/timelines/feature-a/bootstrap-started.json` (ou equivalente)
- `evidence/derived-state-log.md` (primeira entrada)
- `evidence/datadog-screenshot.md` (primeira evidência)
- `evidence/environment-checklist.md` atualizado com status da Phase 2

---

## Phase 3 — Delivery Validation

### Objetivo

Executar a Delivery Journey completa para as três Features, cobrindo os três cenários definidos no EXP-013: Happy Path, Rework, e Blocking com Lookback.

### Feature A — Happy Path

Executar a sequência completa sem interrupções planejadas:

| Evento | Estado resultante | Notas |
|---|---|---|
| `Bootstrap.Started` | `BOOTSTRAPPING` | Phase 2 já registrou |
| `Bootstrap.Completed` | `BOOTSTRAPPING` | `alters_state: false` — Derived State não muda |
| `Hack.Started` | `HACKING` | |
| `Hack.Completed` | `HACKING` | `alters_state: false` |
| `Sync.Started` | `SYNCING` | |
| `Sync.Completed` | `SYNCING` | `alters_state: false` |
| `Finish.Started` | `FINISHING` | |
| `Finish.Completed` | `FINISHING` | `alters_state: false` |
| `Ship.Started` | `SHIPPING` | |
| `Ship.Completed` | `SHIPPING` | `alters_state: false` |
| `Validate.Started` | `VALIDATING` | |
| `Shared.Gate.Passed` | `VALIDATING` | Shared Type — `alters_state: false` |
| `Validate.Completed` | `VALIDATING` | `alters_state: false` |
| `Promote.Started` | `PROMOTING` | |
| `Promote.Completed` | `DONE` | |

Checklist Feature A:
- [ ] Todos os eventos registrados em `evidence/timelines/feature-a/`
- [ ] Derived State calculado após cada `alters_state: true`
- [ ] GitHub COR sincronizado após cada transição de estado
- [ ] Feature A em estado `DONE` ao final

### Feature B — Rework

Executar até `Validate.Started`, forçar um `Shared.Gate.Failed`, executar ciclo de Rework, e completar:

| Evento | Estado resultante | Notas |
|---|---|---|
| `Bootstrap.Started` → `Validate.Started` | `VALIDATING` | Sequência Happy Path até aqui |
| `Shared.Gate.Failed` | `VALIDATING` | Gate falhou — Shared Type |
| `Rework.Declared` | `REWORKING` | |
| *[ciclo de Hack/Sync/Finish/Ship]* | — | Rework executado |
| `Rework.Completed` | `VALIDATING` | Retorna a VALIDATING |
| `Shared.Gate.Passed` | `VALIDATING` | Gate aprovado após Rework |
| `Validate.Completed` → `Promote.Completed` | `DONE` | Sequência final |

Checklist Feature B:
- [ ] `Shared.Gate.Failed` registrado na Timeline
- [ ] `Rework.Declared` e `Rework.Completed` registrados
- [ ] Derived State em `REWORKING` após `Rework.Declared`
- [ ] Derived State retorna a `VALIDATING` após `Rework.Completed`
- [ ] GitHub COR refletindo `REWORKING` durante o ciclo
- [ ] `evidence/rework-timeline.md` preenchido

### Feature C — Blocking com Lookback

Executar até `Hack.Started`, forçar `Shared.Impediment.Declared` (BLOCKED), aplicar Lookback para `Impediment.Resolved`, e continuar:

| Evento | Estado resultante | Notas |
|---|---|---|
| `Bootstrap.Started` → `Hack.Started` | `HACKING` | Sequência até aqui |
| `Shared.Impediment.Declared` | `BLOCKED` | Bloqueio — Shared Type |
| — *[aguardar resolução]* — | `BLOCKED` | Estado persiste até resolução |
| `Delivery.Impediment.Resolved` | Lookback | `alters_state: false` — Derived State reverte via Lookback |
| *[Lookback: `preBlockedState = HACKING`]* | `HACKING` | Derived State calculado por Lookback |
| `Hack.Completed` → `Promote.Completed` | `DONE` | Sequência final |

**Procedimento de Lookback para `Impediment.Resolved`:**
1. Registrar `Impediment.Resolved` com `alters_state: false` e `preBlockedState: HACKING`
2. O Consumer deve calcular o Derived State como: encontrar o último evento `alters_state: true` **anterior** ao `Impediment.Declared` → `new_state` desse evento = estado resultante
3. Resultado esperado: Derived State = `HACKING` (não `BLOCKED`)
4. Registrar o trace completo em `evidence/blocking-lookback-trace.md`

Checklist Feature C:
- [ ] `Shared.Impediment.Declared` registrado com Derived State = `BLOCKED`
- [ ] `Delivery.Impediment.Resolved` registrado com `alters_state: false`
- [ ] Lookback executado com `preBlockedState` correto
- [ ] Derived State = `HACKING` após resolução (calculado pelo Lookback)
- [ ] GitHub COR sincronizado com estado pós-Lookback
- [ ] `evidence/blocking-lookback-trace.md` preenchido

### Critério de saída da Phase 3

- Três Features em estado `DONE`
- `evidence/timelines/` com entradas para feature-a, feature-b, feature-c
- `evidence/rework-timeline.md` preenchido
- `evidence/blocking-lookback-trace.md` preenchido
- `evidence/derived-state-log.md` atualizado com todas as transições
- GitHub COR com Custom Fields atualizados para as três Features

---

## Phase 4 — Diligence Validation

### Objetivo

Executar a Diligence Journey completa sobre os Work Items produzidos pela Phase 3, validando Drift, Findings, Repair, e COR.

### Diligence Sync

Executar o ciclo `Capture → Attach → Promote → Close` para as três Features:

- [ ] **Capture:** identificar as três Features concluídas como Work Items de Diligence
- [ ] **Attach:** verificar que cada Feature possui Issue no GitHub com labels canônicas:
  - `journey:diligence`
  - `operation:promote` (ou equivalente para o estado da Diligence)
- [ ] **Verificar membership no GitHub Project:** cada Issue deve ser membro do projeto `ProdOps — payments-api`
  ```bash
  gh project item-list <project-number> --owner <owner> --format json \
    | jq '.items[] | select(.content.number == <issue-number>)'
  ```
  Se não for membro — adicionar:
  ```bash
  gh project item-add <project-number> --owner <owner> \
    --url https://github.com/<owner>/<repo>/issues/<issue-number>
  ```
- [ ] **Promote:** registrar `Diligence.Promote.Completed` nas Timelines Diligence
- [ ] **Close:** registrar `Diligence.Close.Completed`
- [ ] Timelines Diligence criadas em `evidence/timelines/diligence-<feature>/`

### Diligence Async — ciclo completo com Drift

Executar pelo menos um ciclo `Scan → Flag → Repair` com Drift detectado:

**Scan:**
- [ ] Executar scan completo sobre as três Features pós-Promote
- [ ] Verificar: labels corretas, membership no GitHub Project, Custom Fields atualizados
- [ ] Introduzir deliberadamente um Drift para validar o ciclo Async:
  - Exemplo: remover uma label canônica de um Issue manualmente
  - Exemplo: deixar Custom Field `oem:state` desatualizado
- [ ] Registrar Drift encontrado com severidade e ação corretora esperada

**Flag:**
- [ ] Classificar o Drift na tabela de Flag:
  - Tipo, severidade, ação corretora, responsável
- [ ] Registrar `Diligence.Flag.Completed` na Timeline Diligence

**Repair:**
- [ ] Executar a ação corretora definida no Flag
- [ ] Re-aplicar label, membership, ou Custom Field conforme o tipo de Drift
- [ ] Confirmar que o estado pós-repair está conforme
- [ ] Registrar `Diligence.Repair.Completed` na Timeline Diligence

Checklist Diligence Async:
- [ ] Pelo menos um Drift detectado e documentado
- [ ] Drift classificado com Flag
- [ ] Drift reparado com Repair
- [ ] `evidence/diligence-drift-repair.md` preenchido com: tipo de Drift, severidade, ação corretora executada, estado pós-repair

### Verificação COR pós-Diligence

- [ ] Custom Fields dos três Issues atualizados após Diligence Promote
- [ ] `evidence/github-cor-snapshot.md` atualizado com snapshot pós-Diligence
- [ ] Confirmar que GitHub Project reflete apenas Derived State — não é consultado como fonte de verdade em nenhum momento do ciclo

### Critério de saída da Phase 4

- Diligence Sync completo para as três Features
- Pelo menos um ciclo Async com Drift detectado, classificado, e reparado
- `evidence/diligence-drift-repair.md` preenchido
- `evidence/github-cor-snapshot.md` com snapshot pós-Diligence
- Timelines Diligence em `evidence/timelines/diligence-*/`

---

## Phase 5 — Observability Validation

### Objetivo

Construir e validar os dashboards de Delivery e Diligence, confirmando que Timeline, Derived State, e métricas são coerentes e deriváveis exclusivamente dos eventos registrados.

### Dashboard Delivery

Construir ou validar no Datadog:

- [ ] **Métrica: Lead Time por Feature** — `occurred_at(Promote.Completed)` − `occurred_at(Bootstrap.Started)`
  - Calculada a partir de eventos da Timeline; registrar trace no `evidence/derived-state-log.md`
- [ ] **Métrica: Cycle Time** — tempo em `HACKING` (Hack.Started → Hack.Completed)
- [ ] **Métrica: Block Time** — tempo em `BLOCKED` (Impediment.Declared → Impediment.Resolved)
  - Feature C como referência
- [ ] **Métrica: Gate Failure Rate** — count de `Gate.Failed` / count total de `Gate.Passed + Gate.Failed`
  - Feature B como referência
- [ ] Dashboard com pelo menos duas métricas visíveis com trace rastreável até eventos da Timeline
- [ ] Screenshot salvo em `evidence/datadog-screenshot.md`

### Dashboard Diligence

Construir ou validar no Datadog:

- [ ] **Métrica: Drift Detection Rate** — count de `Divergence.Detected` por Iteration
- [ ] **Métrica: Repair Time** — tempo entre `Flag.Completed` e `Repair.Completed`
- [ ] Dashboard com pelo menos uma métrica Diligence visível com trace rastreável

### Validação da Timeline (Replay)

Confirmar que a Timeline pode ser reconstruída sem estado externo:

- [ ] Selecionar a Timeline completa de Feature A (`Bootstrap.Started` → `Promote.Completed`)
- [ ] Executar Replay: calcular Derived State do zero, evento por evento, na ordem cronológica
- [ ] Confirmar que o Derived State final = `DONE` (idêntico ao calculado incrementalmente)
- [ ] Registrar o trace do Replay em `evidence/derived-state-log.md` como seção separada

### Validação do Derived State

- [ ] Para cada Feature: o Derived State registrado no GitHub COR corresponde ao Derived State calculado pelo Consumer
- [ ] Para Feature C (Lookback): o Derived State após `Impediment.Resolved` = `HACKING` (via Lookback) é consistente entre o Consumer e o GitHub COR

### Critério de saída da Phase 5

- Dashboard Delivery com pelo menos Lead Time e Gate Failure Rate visíveis no Datadog
- Dashboard Diligence com pelo menos uma métrica visível
- Replay executado com sucesso para Feature A
- `evidence/datadog-screenshot.md` com screenshots dos dashboards
- `evidence/derived-state-log.md` com seção de Replay

---

## Phase 6 — Discovery Consolidation

### Objetivo

Preencher o Discovery Report com os resultados das phases 1–5, responder Q1–Q8 com base em evidência, e produzir a recomendação formal: Downstream (OBC-RUNTIME-001) ou Evolution Plan.

### Checklist de consolidação

#### Hipótese

- [ ] Classificar a hipótese principal:
  - **Confirmada** → todos CS-01..CS-08 satisfeitos, nenhum CF-01..CF-07 acionado
  - **Parcialmente confirmada** → maioria de CS satisfeitos, gaps não-estruturais com workaround
  - **Refutada** → pelo menos um CF acionado

#### Q1–Q8

Para cada pergunta, preencher no Discovery Report:
- [ ] Q1 — OEM suficiente? (evidência: `timelines/`)
- [ ] Q2 — Derived State suficiente? (evidência: `derived-state-log.md`)
- [ ] Q3 — Timeline reconstruível por Replay? (evidência: seção Replay em `derived-state-log.md`)
- [ ] Q4 — GitHub permanece apenas COR? (evidência: `github-cor-snapshot.md`)
- [ ] Q5 — Diligence reconcilou todo o fluxo? (evidência: `diligence-drift-repair.md`)
- [ ] Q6 — Métricas deriváveis exclusivamente da Timeline? (evidência: `datadog-screenshot.md`)
- [ ] Q7 — Shared Types suficientes? (evidência: timelines das 3 Features)
- [ ] Q8 — Runtime exigiu novos conceitos? (evidência: `framework-gaps.md`)

#### Avaliação do Framework

- [ ] Preencher tabela de 8 componentes (SIM/NÃO) com justificativa baseada em evidência

#### Recomendação

- [ ] Escolher exatamente uma:
  - **Opção A** — Criar OBC-RUNTIME-001 (apenas se todos CS satisfeitos e nenhum CF acionado)
  - **Opção B** — Criar Evolution Plan (se qualquer CF acionado)

#### Exit Criteria do Discovery Report

- [ ] Hipótese classificada
- [ ] Q1–Q8 respondidas
- [ ] Evidências organizadas
- [ ] Gaps documentados (ou "nenhum gap estrutural")
- [ ] Avaliação do Framework completa
- [ ] Recomendação única escolhida
- [ ] Próximos passos declarados

### Critério de saída da Phase 6

Discovery Report preenchido com todos os campos — nenhum `*A preencher*` remanescente. Recomendação formal registrada. A fase termina com a iniciativa em estado decidido: Downstream ou Evolution Plan.

---

## Matriz de dependências

| Fase | Bloqueia... | Produz | Consome |
|---|---|---|---|
| **Phase 1** | Phase 2 não começa até Environment Preparation completo | `evidence/environment-checklist.md` | — |
| **Phase 2** | Phase 3 não começa sem Datadog recebendo eventos | `evidence/timelines/feature-a/bootstrap-started.json`, `evidence/derived-state-log.md` (1ª entrada), `evidence/datadog-screenshot.md` (1ª evidência) | `evidence/environment-checklist.md` |
| **Phase 3** | Phase 4 não começa sem três Features em `DONE` | `evidence/timelines/feature-{a,b,c}/`, `evidence/rework-timeline.md`, `evidence/blocking-lookback-trace.md` | `evidence/derived-state-log.md`, GitHub Project |
| **Phase 4** | Phase 5 não começa sem Diligence Async concluída | `evidence/diligence-drift-repair.md`, `evidence/github-cor-snapshot.md` | `evidence/timelines/`, GitHub Project |
| **Phase 5** | Phase 6 não começa sem Dashboards Delivery e Diligence validados e Replay bem-sucedido | `evidence/datadog-screenshot.md` (dashboards), `evidence/derived-state-log.md` (seção Replay), `evidence/framework-gaps.md` | `evidence/timelines/`, `evidence/derived-state-log.md`, Datadog |
| **Phase 6** | Encerramento — nenhuma fase posterior | `runtime-validation-discovery-report.md` (preenchido), OBC-RUNTIME-001 ou Evolution Plan | Todas as evidências de `evidence/` |

**Dependências transversais:**

- `evidence/derived-state-log.md` é atualizado em todas as phases (2–5)
- `evidence/github-cor-snapshot.md` é atualizado nas phases 3 e 4
- `evidence/datadog-screenshot.md` é atualizado nas phases 2 e 5
- `evidence/framework-gaps.md` pode ser atualizado em qualquer phase — vazio se CS-08 satisfeito

---

## Critérios de interrupção

O experimento deve ser **interrompido imediatamente** e o Discovery Report preenchido parcialmente com o critério de fracasso acionado quando qualquer uma das seguintes condições for verificada durante a execução:

| # | Condição de interrupção | Critério de fracasso | Impacto |
|---|---|---|---|
| I-01 | OEM não possui Event Types necessários para cobrir eventos reais observados durante a execução (gap crítico sem workaround operacional) | CF-02 | Catálogos de Journey requerem revisão estrutural — Evolution Plan necessário |
| I-02 | A Timeline precisa de estado externo para representar o Work Item corretamente — o OEM não é suficiente como fonte de verdade | CF-01 | Mecanismo de Timeline requer revisão estrutural |
| I-03 | O Consumer de Derived State produz resultado incorreto que não pode ser corrigido por ajuste no algoritmo de cálculo — a especificação de Derived State é insuficiente | CF-03 | Especificação de Derived State requer revisão no OEM |
| I-04 | O GitHub Projects precisa ser consultado como fonte de verdade (não apenas espelho de Derived State) para que o Runtime funcione | CF-04 | Definição de COR requer revisão — GitHub não pode ser fonte de verdade |
| I-05 | A operação do Runtime exige um conceito estrutural novo não previsto no Framework atual (nova Journey, nova Category, novo mecanismo do OEM, novo Shared Type de natureza diferente dos existentes) | CF-05 | Framework requer extensão estrutural — Evolution Plan necessário antes de qualquer Downstream |
| I-06 | A Diligence Journey é incapaz de reconciliar corretamente o fluxo de conformidade dos Work Items Delivery — ciclo Sync ou Async apresenta falha estrutural | CF-06 | Journey Diligence requer revisão |
| I-07 | As métricas operacionais não podem ser calculadas apenas a partir dos eventos da Timeline — exigem uma fonte de dados externa | CF-07 | Modelo de métricas requer revisão no OEM |
| I-08 | *(Operacional — não bloqueia)* Drift no GitHub COR que pode ser reparado pela Diligence Async | — | Registrar como evidência positiva de que a Diligence funciona — não interromper |
| I-09 | *(Operacional — não bloqueia)* Fricção no procedimento de Lookback que pode ser resolvida com ajuste operacional (ex.: Consumer script) sem alterar o OEM | — | Registrar como Finding operacional — não interromper |

**Procedimento de interrupção:**

1. Parar imediatamente a execução da fase em curso
2. Registrar em `evidence/framework-gaps.md`: condição de interrupção, fase, evidência coletada até o momento
3. Preencher o Discovery Report parcialmente até a seção da Q correspondente ao critério de fracasso acionado
4. Classificar a hipótese como **Refutada**
5. Selecionar Opção B no Discovery Report
6. Declarar Evolution Plan como próximo artefato

**Regra de ouro:** fricção operacional (procedimento, script, sequência de comandos) nunca justifica interrupção. Apenas gaps estruturais no OEM, nas Journeys, nos Shared Types, ou no COR justificam a interrupção.

---

## Estimativa de esforço

| Fase | Esforço estimado | Risco de atraso |
|---|---|---|
| Phase 1 — Environment Preparation | 2–4 horas | Médio — acesso a Datadog e GitHub Project podem exigir configuração |
| Phase 2 — Runtime Foundation | 2–3 horas | Baixo — emissão do primeiro evento e primeira métrica |
| Phase 3 — Delivery Validation | 4–6 horas | Médio — Lookback exige cuidado na implementação do Consumer |
| Phase 4 — Diligence Validation | 3–4 horas | Baixo — ciclo Async é controlado (Drift introduzido deliberadamente) |
| Phase 5 — Observability Validation | 3–5 horas | Médio — configuração de Dashboard no Datadog pode ser variável |
| Phase 6 — Discovery Consolidation | 2–3 horas | Baixo — todas as evidências já estão coletadas; consolidação e decisão |
| **Total** | **16–25 horas** | — |

---

## Artefatos de evidência esperados ao final

| Evidência | Fase produtora | Critério relacionado |
|---|---|---|
| `evidence/environment-checklist.md` | Phase 1 | Pré-condição |
| `evidence/timelines/feature-a/` | Phases 2–3 | CS-01, CS-02 |
| `evidence/timelines/feature-b/` | Phase 3 | CS-01, CS-04 |
| `evidence/timelines/feature-c/` | Phase 3 | CS-01, CS-05 |
| `evidence/derived-state-log.md` | Phases 2–5 | CS-02, CS-03 |
| `evidence/rework-timeline.md` | Phase 3 | CS-04 |
| `evidence/blocking-lookback-trace.md` | Phase 3 | CS-05 |
| `evidence/timelines/diligence-*/` | Phase 4 | CS-06 |
| `evidence/diligence-drift-repair.md` | Phase 4 | CS-06 |
| `evidence/github-cor-snapshot.md` | Phases 3–4 | CS-03 |
| `evidence/datadog-screenshot.md` | Phases 2 e 5 | CS-07 |
| `evidence/framework-gaps.md` | Qualquer fase | CS-08 (vazio se satisfeito) |
| `runtime-validation-discovery-report.md` (preenchido) | Phase 6 | Exit Criteria completo |
