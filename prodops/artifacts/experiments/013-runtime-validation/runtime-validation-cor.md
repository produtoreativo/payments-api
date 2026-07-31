# Runtime Validation — Canonical Operational Representation (COR)

> **Localização canônica:** `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-cor.md`
>
> Este documento define a representação operacional completa do piloto de validação do Runtime. O GitHub Project `ProdOps — payments-api` é a materialização desta COR. A COR é apenas leitura de estado derivado — não é fonte de verdade. A fonte de verdade é a Operational Timeline registrada durante a execução.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Experimento** | [EXP-013](./experiment.md) |
| **Execution Plan** | [runtime-validation-execution-plan.md](./runtime-validation-execution-plan.md) |
| **Discovery Report** | [runtime-validation-discovery-report.md](./runtime-validation-discovery-report.md) |
| **Product Intent** | [PI-RUNTIME-001](../../business-intents/PI-RUNTIME-001.md) |
| **Data de criação** | 2026-07-25 |
| **Status** | Definido — aguarda início da Phase 1 do Execution Plan |

---

## 1. Release

### Nome

**Payments API — Observable Delivery Pilot**

### Versão

```
v0.1.0-runtime-pilot
```

### Objetivo

Demonstrar que o ProdOps Framework é capaz de operar uma Iteration real com Timeline, GitHub COR e Datadog sincronizados — sem alterações estruturais no OEM, nos catálogos de Journey, nos Shared Types ou na COR.

Esta Release não entrega funcionalidade de negócio nova no payments-api. Ela entrega **evidência operacional**: prova de que o modelo conceitual do Framework é realizável em condição real.

### Escopo

| Incluído | Excluído |
|---|---|
| 3 Features reais do backlog do payments-api | Funcionalidades novas fora do backlog selecionado |
| Delivery Journey completa (Bootstrap → Promote) | Discovery Journey formal |
| Diligence Journey completa (Sync + Async) | Operation Journey (incidentes, SLOs em produção) |
| GitHub COR com Custom Fields de Derived State | Integração com Jira ou ferramentas externas |
| Datadog com métricas derivadas da Timeline | Generalização do Runtime para outros produtos |
| Assessment Sync opcional (ao final) | Assessment Journey completa |
| Validação do Lookback para Impediment.Resolved | Shared Types v1.1.0 (Impediment.Resolved como Shared Active) |

### Critério de encerramento

A Release está encerrada quando:

1. As três Features estão em estado `DONE` com Timelines completas
2. A Diligence Async completou pelo menos um ciclo com Drift detectado e reparado
3. O Discovery Report está preenchido com todos os campos e recomendação formal
4. Nenhum Finding em aberto com severidade Alta

---

## 2. Iteration

### Identificador

```
IP-RUNTIME-001
```

### Objetivo

Executar o ciclo completo de Delivery e Diligence para as três Features selecionadas, coletando evidências operacionais que permitam responder Q1–Q8 do EXP-013 e preencher o Discovery Report.

### Duração prevista

| Fase | Duração estimada |
|---|---|
| Phase 1 — Environment Preparation | 2–4 horas |
| Phase 2 — Runtime Foundation | 2–3 horas |
| Phase 3 — Delivery Validation | 4–6 horas |
| Phase 4 — Diligence Validation | 3–4 horas |
| Phase 5 — Observability Validation | 3–5 horas |
| Phase 6 — Discovery Consolidation | 2–3 horas |
| **Total** | **16–25 horas** |

### Compromisso da Iteration

- [ ] Feature A concluída com Happy Path completo e Timeline registrada
- [ ] Feature B concluída com ciclo de Rework completo e evidência registrada
- [ ] Feature C concluída com Blocking e Lookback executados e evidência registrada
- [ ] Diligence Sync completo para as três Features
- [ ] Diligence Async com pelo menos um Drift detectado, classificado, e reparado
- [ ] GitHub COR sincronizado em todas as transições de estado
- [ ] Pelo menos uma métrica derivada da Timeline visível no Datadog

### Critérios de conclusão

- Todos os compromissos acima marcados como concluídos
- Discovery Report com todos os campos preenchidos
- Recomendação formal registrada (Opção A ou Opção B)
- `evidence/` contendo todos os 12 artefatos de evidência definidos no Execution Plan

---

## 3. Features

### Feature A — Happy Path

**Nome:** `FEAT-A — Delivery Happy Path`

**Objetivo:** Executar a sequência completa de Delivery sem interrupções para estabelecer o baseline operacional do Runtime e validar que o OEM cobre todos os eventos do caminho feliz.

**Cenário operacional:**

Uma Feature real do backlog do payments-api percorre todas as fases da Delivery Journey sem Gate.Failed, sem Impediment, sem Rework. O Consumer de Derived State acompanha cada transição. O GitHub COR é sincronizado após cada estado `alters_state: true`.

**Critérios de aceite:**

- [ ] Feature em estado `DONE` ao final (Derived State = `DONE` após `Promote.Completed`)
- [ ] Timeline com todos os eventos esperados (sem gaps)
- [ ] Derived State correto em cada ponto da Timeline
- [ ] GitHub COR sincronizado com Derived State correto ao final
- [ ] Nenhum Event Type ausente no catálogo Delivery v2.0.0 para o caminho feliz

**Eventos esperados:**

| Evento | `alters_state` | `new_state` |
|---|---|---|
| `Delivery.Bootstrap.Started` | true | `BOOTSTRAPPING` |
| `Delivery.Bootstrap.Completed` | false | — |
| `Delivery.Hack.Started` | true | `HACKING` |
| `Delivery.Hack.Completed` | false | — |
| `Delivery.Sync.Started` | true | `SYNCING` |
| `Delivery.Sync.Completed` | false | — |
| `Delivery.Finish.Started` | true | `FINISHING` |
| `Delivery.Finish.Completed` | false | — |
| `Delivery.Ship.Started` | true | `SHIPPING` |
| `Delivery.Ship.Completed` | false | — |
| `Delivery.Validate.Started` | true | `VALIDATING` |
| `Shared.Gate.Passed` | false | — |
| `Delivery.Validate.Completed` | false | — |
| `Delivery.Promote.Started` | true | `PROMOTING` |
| `Delivery.Promote.Completed` | true | `DONE` |

**Evidências obrigatórias:**

- `evidence/timelines/feature-a/` — sequência completa de Event Instances
- `evidence/derived-state-log.md` — log com todas as transições de Feature A
- `evidence/github-cor-snapshot.md` — snapshot do GitHub COR ao final (estado: `DONE`)

---

### Feature B — Rework

**Nome:** `FEAT-B — Delivery with Gate Failure and Rework`

**Objetivo:** Executar um ciclo completo com Gate.Failed em VALIDATING e recuperação via Rework, validando que o OEM suporta o caminho de exceção mais comum e que o Derived State representa corretamente o estado `REWORKING`.

**Cenário operacional:**

A Feature executa o Happy Path até `Validate.Started`. Um Gate falha (`Shared.Gate.Failed`). Um ciclo de Rework é declarado e executado. Após o Rework, a Feature retorna a VALIDATING, o Gate passa, e a Feature conclui normalmente.

**Critérios de aceite:**

- [ ] Feature em estado `DONE` ao final
- [ ] `Shared.Gate.Failed` registrado na Timeline
- [ ] `Delivery.Rework.Declared` e `Delivery.Rework.Completed` registrados
- [ ] Derived State = `REWORKING` após `Rework.Declared`
- [ ] Derived State retorna a `VALIDATING` após `Rework.Completed`
- [ ] GitHub COR refletindo `REWORKING` durante o ciclo de Rework
- [ ] Rework Count atualizado no GitHub Project (campo `oem:rework-count`)

**Eventos esperados:**

| Evento | `alters_state` | `new_state` |
|---|---|---|
| `Delivery.Bootstrap.Started` → `Delivery.Validate.Started` | — | *(sequência Happy Path)* |
| `Shared.Gate.Failed` | false | — |
| `Delivery.Rework.Declared` | true | `REWORKING` |
| `Delivery.Hack.Started` | true | `HACKING` |
| `Delivery.Hack.Completed` | false | — |
| `Delivery.Sync.Started` → `Delivery.Ship.Completed` | — | *(ciclo de Rework)* |
| `Delivery.Rework.Completed` | true | `VALIDATING` |
| `Shared.Gate.Passed` | false | — |
| `Delivery.Validate.Completed` → `Delivery.Promote.Completed` | — | *(sequência final)* |

**Evidências obrigatórias:**

- `evidence/timelines/feature-b/` — sequência completa incluindo Gate.Failed e Rework
- `evidence/rework-timeline.md` — narrativa do cenário com timestamps e Derived State em cada ponto
- `evidence/derived-state-log.md` — log com transições de Feature B (incluindo `REWORKING`)

---

### Feature C — Blocking + Drift

**Nome:** `FEAT-C — Delivery with Blocking, Lookback, and Diligence Drift`

**Objetivo:** Executar um cenário de Blocking com Impediment.Resolved via Lookback (`alters_state: false`) e, durante a Diligence, introduzir um Drift deliberado para validar o ciclo Async.

**Cenário operacional:**

A Feature executa o Happy Path até `Hack.Started`. Um impedimento é declarado (`Shared.Impediment.Declared`) e a Feature entra em `BLOCKED`. Após resolução, `Delivery.Impediment.Resolved` é registrado com `alters_state: false` — o Consumer executa Lookback para determinar o estado anterior ao bloqueio (`HACKING`). A Feature retoma de `HACKING` e conclui normalmente. Durante a Diligence Async, um Drift é introduzido deliberadamente nesta Feature para validar o ciclo de reparo.

**Critérios de aceite:**

- [ ] Feature em estado `DONE` ao final
- [ ] `Shared.Impediment.Declared` registrado com Derived State = `BLOCKED`
- [ ] `Delivery.Impediment.Resolved` registrado com `alters_state: false`
- [ ] Lookback executado: Consumer identifica `preBlockedState = HACKING`
- [ ] Derived State = `HACKING` após resolução (via Lookback — não `BLOCKED`)
- [ ] GitHub COR refletindo `HACKING` após resolução
- [ ] `Blocked Since` atualizado no GitHub Project durante o período de bloqueio
- [ ] Drift introduzido na Diligence Async detectado, classificado, e reparado

**Eventos esperados:**

| Evento | `alters_state` | `new_state` | Nota |
|---|---|---|---|
| `Delivery.Bootstrap.Started` → `Delivery.Hack.Started` | — | *(sequência Happy Path até HACKING)* | |
| `Shared.Impediment.Declared` | true | `BLOCKED` | Bloqueio |
| `Delivery.Impediment.Resolved` | false | — | Lookback: `preBlockedState = HACKING` |
| `Delivery.Hack.Completed` → `Delivery.Promote.Completed` | — | *(sequência a partir de HACKING)* | |

**Procedimento de Lookback:**
1. Registrar `Impediment.Resolved` com `alters_state: false` e payload `{ "preBlockedState": "HACKING" }`
2. Consumer busca o último evento `alters_state: true` **anterior** ao `Impediment.Declared` na Timeline
3. `new_state` desse evento = Derived State resultante = `HACKING`
4. Consumer atualiza GitHub COR: `oem:state = HACKING`

**Evidências obrigatórias:**

- `evidence/timelines/feature-c/` — sequência completa incluindo BLOCKED e Lookback
- `evidence/blocking-lookback-trace.md` — trace detalhado do Lookback com: evento anterior identificado, `preBlockedState`, Derived State resultante
- `evidence/diligence-drift-repair.md` — Drift introduzido nesta Feature, classificado, e reparado
- `evidence/derived-state-log.md` — log com transições de Feature C

---

## 4. Runtime Tasks

As Runtime Tasks são atividades técnicas necessárias para executar o piloto. Não são Features de produto — são habilitadores do experimento.

### RT-01 — Runtime Event Producer

**Objetivo:** Definir e executar o mecanismo de emissão de Event Instances em formato canônico (OEM) durante a execução das Features.

**Responsabilidade:** Pode ser manual (operador preenche JSON a cada evento) ou script auxiliar em `evidence/scripts/`. Não precisa ser automação completa.

**Dependências:** Phase 1 (schema de Event Instance definido)

**Features relacionadas:** A, B, C

**Entrega:** Event Instances registradas em `evidence/timelines/<feature>/` após cada evento da Delivery Journey

---

### RT-02 — Timeline Processor

**Objetivo:** Calcular o Derived State após cada `alters_state: true` na Timeline, incluindo o algoritmo de Lookback para `Impediment.Resolved`.

**Responsabilidade:** Consumer manual, script, ou planilha — executado pelo operador após cada evento relevante.

**Dependências:** RT-01 (eventos disponíveis para processamento)

**Features relacionadas:** A (Derived State padrão), B (transição REWORKING), C (Lookback)

**Entrega:** `evidence/derived-state-log.md` com log completo de transições de estado para as três Features

---

### RT-03 — GitHub Synchronizer

**Objetivo:** Atualizar os Custom Fields do GitHub Project com o Derived State calculado pelo Timeline Processor após cada transição de estado.

**Mecanismo:** Via `gh` CLI:
```bash
gh project item-edit <item-id> \
  --project-id <project-id> \
  --field-id <field-id-oem-state> \
  --text "HACKING"
```

**Dependências:** RT-02 (Derived State calculado), GitHub Project com Custom Fields configurados (Phase 1)

**Features relacionadas:** A, B, C

**Entrega:** GitHub COR com `oem:state`, `oem:last-event`, e `oem:iteration` atualizados após cada transição

---

### RT-04 — Datadog Integration

**Objetivo:** Enviar métricas derivadas da Timeline para o Datadog via API, com trace rastreável até os eventos da Timeline.

**Mecanismo:** Via API Datadog (curl ou SDK) com namespace `prodops.runtime.validation.*`

**Dependências:** RT-01 (eventos com timestamps), Datadog configurado (Phase 1)

**Features relacionadas:** A (Lead Time, Cycle Time), B (Gate Failure Rate), C (Block Time)

**Entrega:** Pelo menos uma métrica visível no Datadog ao final da Phase 2; dashboards completos ao final da Phase 5

---

### RT-05 — Delivery Dashboard

**Objetivo:** Construir ou validar o Dashboard de Delivery no Datadog com métricas derivadas da Timeline.

**Métricas mínimas:**
- Lead Time por Feature = `Promote.Completed.occurred_at` − `Bootstrap.Started.occurred_at`
- Cycle Time = tempo em `HACKING`
- Block Time = tempo em `BLOCKED` (Feature C)
- Gate Failure Rate = `Gate.Failed` / (`Gate.Passed` + `Gate.Failed`)

**Dependências:** RT-04 (métricas no Datadog)

**Features relacionadas:** A (baseline), B (Gate Failure Rate), C (Block Time)

**Entrega:** `evidence/datadog-screenshot.md` com screenshots do Dashboard Delivery

---

### RT-06 — Diligence Dashboard

**Objetivo:** Construir ou validar o Dashboard de Diligence no Datadog com métricas derivadas das Timelines de Diligence.

**Métricas mínimas:**
- Drift Detection Rate = count de `Divergence.Detected` na Iteration
- Repair Time = `Repair.Completed.occurred_at` − `Flag.Completed.occurred_at`

**Dependências:** RT-04 (métricas no Datadog), Phase 4 concluída

**Features relacionadas:** C (Drift Diligence Async)

**Entrega:** `evidence/datadog-screenshot.md` com screenshots do Dashboard Diligence (seção separada)

---

## 5. Findings

Findings representam divergências, lacunas ou anomalias identificadas durante a execução do piloto. São registrados em `evidence/framework-gaps.md` (gaps estruturais) ou no GitHub Project como Issues com label `type:finding`.

### Classificações

#### Drift

**Descrição:** Divergência entre o estado do Work Item na COR (GitHub) e o Derived State calculado a partir da Timeline.

**Severidade:** Média (reparável pela Diligence Async)

**Responsável:** Diligence

**Critério de encerramento:** `Diligence.Repair.Completed` registrado na Timeline Diligence; GitHub COR sincronizado com o Derived State correto

---

#### Missing Evidence

**Descrição:** Evidência obrigatória definida no Execution Plan ausente ou incompleta ao final de uma Phase.

**Severidade:** Alta (bloqueia Phase seguinte)

**Responsável:** Operador da Phase

**Critério de encerramento:** Evidência coletada e arquivo em `evidence/` completo; Phase não avança sem encerramento

---

#### Missing Event

**Descrição:** Evento esperado na Timeline de uma Feature ausente — seja por omissão do operador ou por ausência de Event Type correspondente no catálogo.

**Severidade:**
- Alta — se Event Type não existe no catálogo (potencial resposta negativa para Q1)
- Média — se Event Type existe mas não foi registrado (erro operacional, recuperável)

**Responsável:**
- Alta: Framework — registrar em `evidence/framework-gaps.md`
- Média: Operador — registrar o evento retroativamente com `occurred_at` correto

**Critério de encerramento:**
- Alta: registrado como critério de fracasso CF-02 potencial; interrupção avaliada
- Média: evento registrado; Timeline completa

---

#### Runtime Error

**Descrição:** Falha no mecanismo do Runtime durante a execução — Consumer produz Derived State incorreto, GitHub Synchronizer falha, ou emissão de evento produz payload inválido.

**Severidade:**
- Alta — se o erro é estrutural (não pode ser corrigido sem alterar o OEM ou o Consumer)
- Baixa — se o erro é operacional (correção no script ou procedimento)

**Responsável:**
- Alta: Framework — avaliar interrupção (potencial CF-01, CF-03)
- Baixa: Operador — corrigir e re-executar

**Critério de encerramento:**
- Alta: avaliação de interrupção concluída; Decision registrada no Discovery Report
- Baixa: correção aplicada; resultado verificado

---

#### Manual Review

**Descrição:** Situação que requer revisão humana explícita antes de prosseguir — ambiguidade no Event Type correto, dúvida sobre `alters_state`, ou interpretação do cenário.

**Severidade:** Baixa (não bloqueia automaticamente)

**Responsável:** Operador + Tech Lead

**Critério de encerramento:** Decisão registrada em `evidence/decisions.md`; interpretação aplicada de forma consistente ao restante da execução

---

## 6. Milestone

### Nome

```
v0.1.0-runtime-pilot — Runtime Validation Pilot
```

### Descrição

Milestone de encerramento do piloto de validação do Runtime ProdOps. Agrupa todas as Issues das três Features (A, B, C), Runtime Tasks, e Findings do experimento EXP-013. Fechada quando o Discovery Report estiver completo e a recomendação formal (Downstream ou Evolution Plan) estiver registrada.

### Critérios para fechamento

- [ ] Feature A (`FEAT-A`) — Issue fechada com estado `DONE`
- [ ] Feature B (`FEAT-B`) — Issue fechada com estado `DONE`
- [ ] Feature C (`FEAT-C`) — Issue fechada com estado `DONE`
- [ ] Todas as Runtime Tasks (RT-01 a RT-06) — Issues fechadas
- [ ] Todos os Findings — Issues fechadas ou com critério de encerramento satisfeito
- [ ] Discovery Report preenchido e recomendação registrada
- [ ] Nenhum Finding com severidade Alta em aberto

---

## 7. Fields

Todos os campos abaixo são Custom Fields do GitHub Project. São campos de **visualização** — espelham o Derived State calculado a partir da Timeline. Não são fonte de verdade.

### Identity

| Campo | Tipo | Valores permitidos | Obrigatório | Atualizado por |
|---|---|---|---|---|
| `witem:type` | Select | `Feature`, `Runtime Task`, `Finding` | Sim | Operador (no momento da criação do Issue) |
| `witem:repository` | Text | `payments-api` | Sim | Operador (no momento da criação) |
| `witem:feature` | Text | `FEAT-A`, `FEAT-B`, `FEAT-C`, ou identificador da Runtime Task/Finding | Sim | Operador |
| `witem:obc` | Text | Identificador do OBC (ex.: `OBC-PAYMENTS-001`) ou `EXP-013` para itens do piloto | Sim | Operador |
| `witem:release` | Text | `v0.1.0-runtime-pilot` | Sim | Operador (no momento da criação) |
| `witem:iteration` | Text | `IP-RUNTIME-001` | Sim | Operador (no momento da criação) |

### Delivery

| Campo | Tipo | Valores permitidos | Obrigatório | Atualizado por |
|---|---|---|---|---|
| `oem:journey` | Select | `Delivery`, `Diligence`, `Assessment` | Sim | Operador |
| `oem:cycle` | Select | `Bootstrap`, `Hack`, `Sync`, `Finish`, `Ship`, `Validate`, `Promote`, `Rework` | Não (opcional) | Operador |
| `oem:phase` | Select | `Started`, `Completed` | Não (opcional) | Operador |
| `oem:state` | Select | `BOOTSTRAPPING`, `HACKING`, `SYNCING`, `FINISHING`, `SHIPPING`, `VALIDATING`, `PROMOTING`, `DONE`, `BLOCKED`, `REWORKING` | Sim | RT-03 (GitHub Synchronizer) |
| `oem:rework-count` | Number | 0, 1, 2, ... | Não | RT-03 — incrementado a cada `Rework.Declared` |
| `oem:blocked-since` | Date | ISO-8601 date | Não | RT-03 — preenchido em `Impediment.Declared`; limpo em `Impediment.Resolved` |

### Diligence

| Campo | Tipo | Valores permitidos | Obrigatório | Atualizado por |
|---|---|---|---|---|
| `diligence:status` | Select | `Pending`, `Sync In Progress`, `Async In Progress`, `Compliant`, `Non-Compliant` | Sim (para Features) | RT-03 após Diligence events |
| `diligence:evidence` | Select | `Missing`, `Partial`, `Complete` | Sim (para Features) | Operador após coleta de evidências |

### Runtime

| Campo | Tipo | Valores permitidos | Obrigatório | Atualizado por |
|---|---|---|---|---|
| `runtime:sync` | Select | `Pending`, `In Sync`, `Drift Detected`, `Repair In Progress`, `Reconciled` | Sim | RT-03 — atualizado após cada verificação de COR |
| `runtime:timeline-state` | Select | `Empty`, `In Progress`, `Complete`, `Replay Verified` | Sim | Operador após Phase 5 |
| `oem:last-event` | Text | Tipo do último evento registrado (ex.: `Delivery.Hack.Started`) | Sim | RT-03 após cada evento |
| `runtime:last-sync` | Date | ISO-8601 datetime da última sincronização COR | Não | RT-03 automaticamente |

---

## 8. Labels

Labels classificam os Issues no GitHub. São complementares aos Fields — não redundantes. Enquanto Fields armazenam estado derivado (valores que mudam), Labels classificam o tipo e a natureza do Issue (valores estáveis na maioria do ciclo de vida).

### Journey

| Label | Descrição |
|---|---|
| `journey:delivery` | Issue pertence à Delivery Journey |
| `journey:diligence` | Issue pertence à Diligence Journey |
| `journey:assessment` | Issue pertence à Assessment Journey |

### Phase

| Label | Descrição |
|---|---|
| `phase:bootstrap` | Issue está na fase Bootstrap |
| `phase:hack` | Issue está na fase Hack |
| `phase:sync` | Issue está na fase Sync |
| `phase:finish` | Issue está na fase Finish |
| `phase:ship` | Issue está na fase Ship |
| `phase:validate` | Issue está na fase Validate |
| `phase:promote` | Issue está na fase Promote |

### Runtime

| Label | Descrição |
|---|---|
| `runtime:pilot` | Issue faz parte do piloto EXP-013 |
| `runtime:task` | Issue é uma Runtime Task (RT-01 a RT-06) |
| `runtime:blocked` | Issue em estado BLOCKED (Impediment.Declared ativo) |
| `runtime:rework` | Issue passou por pelo menos um ciclo de Rework |

### Severity

| Label | Descrição |
|---|---|
| `severity:high` | Severidade Alta — bloqueia fase ou representa critério de fracasso potencial |
| `severity:medium` | Severidade Média — reparável; não bloqueia automaticamente |
| `severity:low` | Severidade Baixa — observacional; não bloqueia |

### Finding

| Label | Descrição |
|---|---|
| `finding:drift` | Finding do tipo Drift |
| `finding:missing-evidence` | Finding do tipo Missing Evidence |
| `finding:missing-event` | Finding do tipo Missing Event |
| `finding:runtime-error` | Finding do tipo Runtime Error |
| `finding:manual-review` | Finding do tipo Manual Review |

### Evidence

| Label | Descrição |
|---|---|
| `evidence:missing` | Evidência obrigatória ainda não coletada |
| `evidence:partial` | Evidência coletada parcialmente |
| `evidence:complete` | Evidência completa e verificada |

---

## 9. Views

Todas as Views são configuradas no GitHub Project `ProdOps — payments-api`. São filtros de leitura sobre o estado da COR — não alteram dados.

### View 1 — Iteration Plan

**Objetivo:** Visão consolidada de todos os Work Items da IP-RUNTIME-001, com estado atual e progresso da Iteration.

**Filtros:** `witem:iteration = IP-RUNTIME-001`

**Agrupamento:** Por `witem:type` (Feature → Runtime Task → Finding)

**Ordenação:** Por `witem:feature` (FEAT-A, FEAT-B, FEAT-C, depois RT, depois Findings)

**Campos exibidos:** `witem:feature`, `witem:type`, `oem:state`, `oem:journey`, `diligence:status`, `runtime:sync`

**Responsável:** Tech Lead (revisão diária durante a execução)

---

### View 2 — Delivery Flow

**Objetivo:** Acompanhar o progresso das três Features pela Delivery Journey em tempo real.

**Filtros:** `witem:type = Feature` AND `oem:journey = Delivery` AND `witem:iteration = IP-RUNTIME-001`

**Agrupamento:** Por `oem:state` (colunas: BOOTSTRAPPING → HACKING → SYNCING → FINISHING → SHIPPING → VALIDATING → PROMOTING → DONE)

**Ordenação:** Por `witem:feature` dentro de cada coluna

**Campos exibidos:** `witem:feature`, `oem:state`, `oem:last-event`, `oem:rework-count`, `runtime:sync`, `oem:blocked-since`

**Responsável:** Operador da Delivery (atualizado após cada evento)

---

### View 3 — Diligence Flow

**Objetivo:** Acompanhar o estado de conformidade das Features pela Diligence Journey.

**Filtros:** `witem:type = Feature` AND `witem:iteration = IP-RUNTIME-001`

**Agrupamento:** Por `diligence:status` (colunas: Pending → Sync In Progress → Async In Progress → Compliant → Non-Compliant)

**Ordenação:** Por `witem:feature`

**Campos exibidos:** `witem:feature`, `diligence:status`, `diligence:evidence`, `runtime:sync`, `runtime:timeline-state`

**Responsável:** Operador da Diligence

---

### View 4 — Runtime Reconciliation

**Objetivo:** Detectar divergências entre o Derived State calculado e o estado registrado no GitHub COR. Ferramenta operacional do ciclo de Sync da Diligence.

**Filtros:** `witem:iteration = IP-RUNTIME-001` AND `runtime:sync != In Sync`

**Agrupamento:** Por `runtime:sync` (Drift Detected, Repair In Progress, Pending)

**Ordenação:** Por `oem:last-event` (mais recente primeiro)

**Campos exibidos:** `witem:feature`, `oem:state`, `oem:last-event`, `runtime:sync`, `runtime:last-sync`

**Responsável:** Diligence (verificado a cada ciclo Async)

---

### View 5 — Findings

**Objetivo:** Listar e acompanhar todos os Findings abertos durante o piloto, com severidade e status de encerramento.

**Filtros:** `witem:type = Finding` AND `witem:iteration = IP-RUNTIME-001`

**Agrupamento:** Por `severity:*` (Alta primeiro, depois Média, depois Baixa)

**Ordenação:** Por data de abertura (mais recente primeiro)

**Campos exibidos:** `witem:feature`, `finding:*` (tipo), `severity:*`, `diligence:status` (se Drift), estado do Issue (Open/Closed)

**Responsável:** Tech Lead (revisão antes de encerrar cada Phase)

---

### View 6 — Evidence Readiness

**Objetivo:** Verificar quais evidências obrigatórias estão completas, parciais, ou ausentes antes de avançar para a Phase 6 (Discovery Consolidation).

**Filtros:** `witem:type = Feature` AND `witem:iteration = IP-RUNTIME-001`

**Agrupamento:** Por `diligence:evidence` (colunas: Missing → Partial → Complete)

**Ordenação:** Por `witem:feature`

**Campos exibidos:** `witem:feature`, `diligence:evidence`, `runtime:timeline-state`, `oem:state`

**Responsável:** Operador (verificado ao final da Phase 5 antes de iniciar Phase 6)

---

### View 7 — Release Scope

**Objetivo:** Visão executiva do escopo completo da Release `v0.1.0-runtime-pilot` — Features, Runtime Tasks, e estado de encerramento para fechamento da Milestone.

**Filtros:** `witem:release = v0.1.0-runtime-pilot`

**Agrupamento:** Por `witem:type`

**Ordenação:** Por `witem:feature`

**Campos exibidos:** `witem:type`, `witem:feature`, `oem:state`, `diligence:status`, `diligence:evidence`, estado do Issue (Open/Closed)

**Responsável:** Tech Lead (revisado antes de fechar a Milestone)

---

## 10. Mapeamento COR → GitHub

| Conceito COR | Materialização GitHub | Observação |
|---|---|---|
| **Release** | Milestone | `v0.1.0-runtime-pilot — Runtime Validation Pilot` |
| **Iteration** | Campo `witem:iteration` + Milestone | `IP-RUNTIME-001` — todos os Issues da Iteration têm este valor no campo |
| **Feature** | Issue com `witem:type = Feature` | Um Issue por Feature (FEAT-A, FEAT-B, FEAT-C) |
| **Runtime Task** | Issue com `witem:type = Runtime Task` | Um Issue por RT-01..RT-06 |
| **Finding** | Issue com `witem:type = Finding` | Aberto pelo operador quando identificado |
| **Derived State** | Campo `oem:state` (Select) | Espelho do Derived State calculado — não fonte de verdade |
| **Journey** | Campo `oem:journey` + Label `journey:*` | Campo para filtros; Label para visualização rápida |
| **Cycle** | Campo `oem:cycle` | Opcional — representa a fase corrente dentro da Journey |
| **Phase** | Campo `oem:phase` + Label `phase:*` | Campo para filtros; Label para visualização rápida |
| **Rework Count** | Campo `oem:rework-count` (Number) | Incrementado a cada `Rework.Declared` |
| **Blocked Since** | Campo `oem:blocked-since` (Date) | Preenchido em `Impediment.Declared`; limpo em `Impediment.Resolved` |
| **Diligence Status** | Campo `diligence:status` (Select) | Estado do ciclo Diligence para a Feature |
| **Evidence Status** | Campo `diligence:evidence` (Select) + Label `evidence:*` | Campo para filtros de View 6; Label para visualização |
| **Runtime Sync** | Campo `runtime:sync` (Select) | Estado de sincronização COR — vira `Drift Detected` quando divergência identificada |
| **Timeline State** | Campo `runtime:timeline-state` (Select) | Estado da Timeline no `evidence/` — atualizado pelo operador |
| **Last Event** | Campo `oem:last-event` (Text) | Tipo do último evento registrado |
| **Last Synchronization** | Campo `runtime:last-sync` (Date) | Datetime da última sync do RT-03 |
| **Finding Type** | Label `finding:*` | `drift`, `missing-evidence`, `missing-event`, `runtime-error`, `manual-review` |
| **Severity** | Label `severity:*` | `high`, `medium`, `low` |
| **Pilot Marker** | Label `runtime:pilot` | Todos os Issues do EXP-013 recebem esta label |
| **Views** | GitHub Project Views | 7 views definidas neste documento |

---

## Princípio fundamental da COR

> **O GitHub Project não é fonte de verdade. É uma superfície de visualização.**

O Derived State registrado em `oem:state` é calculado a partir da Timeline de eventos registrada em `evidence/timelines/`. Se houver divergência entre o GitHub COR e o Derived State calculado da Timeline, o valor correto é sempre o da Timeline.

A Diligence Async existe para detectar e reparar essas divergências. A View 4 (Runtime Reconciliation) é o instrumento de detecção. RT-03 (GitHub Synchronizer) é o instrumento de reparo.
