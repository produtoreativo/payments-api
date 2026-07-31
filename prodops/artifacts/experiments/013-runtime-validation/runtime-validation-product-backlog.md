# Runtime Validation — Product Backlog

> **Localização canônica:** `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-product-backlog.md`
>
> Este documento transforma a COR em Work Items executáveis para a Iteration IP-RUNTIME-001. Representa o backlog real da primeira Iteration do piloto. Nenhum código, GitHub Project, ou Runtime é criado aqui — apenas a definição do trabalho.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Iteration** | `IP-RUNTIME-001` |
| **Release** | `v0.1.0-runtime-pilot` |
| **COR** | [runtime-validation-cor.md](./runtime-validation-cor.md) |
| **Execution Plan** | [runtime-validation-execution-plan.md](./runtime-validation-execution-plan.md) |
| **Experimento** | [EXP-013](./experiment.md) |
| **Data de criação** | 2026-07-25 |
| **Status** | Planejado — aguarda início da Phase 1 |

---

## 1. Épica

### EPIC-RUNTIME-001 — ProdOps Runtime MVP

**Objetivo:** Executar o piloto completo de validação do Runtime do ProdOps Framework no payments-api, demonstrando que OEM, Timeline, GitHub COR e Datadog funcionam integrados durante uma Iteration real sem necessidade de alterações estruturais no Framework.

**Escopo da Épica:**

| Incluído | Excluído |
|---|---|
| 3 Features reais do domínio payments | Funcionalidades de produção novas |
| Runtime mínimo (Event Producer, Timeline, COR sync, Datadog) | Automação completa de produção |
| Delivery Journey completa (Bootstrap → Promote) | Discovery Journey formal |
| Diligence Sync + Async com Drift | Operation Journey (incidentes, SLOs) |
| GitHub COR com Custom Fields | Integração com Jira ou ferramentas externas |
| Datadog com métricas derivadas da Timeline | Assessment Journey completa |

**Critério de encerramento da Épica:**

- Discovery Report preenchido com todos os campos
- Recomendação formal registrada (OBC-RUNTIME-001 ou Evolution Plan)
- Milestone `v0.1.0-runtime-pilot` fechada

**Work Items da Épica:**

| ID | Tipo | Título |
|---|---|---|
| FTR-RUNTIME-001 | Feature | Split Payment Creation — Happy Path |
| FTR-RUNTIME-002 | Feature | Split Allocation Validation — Gate Failed + Rework |
| FTR-RUNTIME-003 | Feature | Settlement Webhook Notification — Blocking + Drift |
| RT-01 | Runtime Task | Event Producer |
| RT-02 | Runtime Task | Timeline Processor |
| RT-03 | Runtime Task | GitHub Synchronizer |
| RT-04 | Runtime Task | Datadog Integration |
| RT-05 | Runtime Task | Delivery Dashboard |
| RT-06 | Runtime Task | Diligence Dashboard |

---

## 2. Features

### FTR-RUNTIME-001 — Split Payment Creation (Happy Path)

**Mapeamento:** Feature A da COR — cenário Happy Path (Bootstrap → Promote sem interrupções)

**Objetivo:** Executar o ciclo completo de Delivery para a criação de um split payment no payments-api, registrando todos os eventos na Timeline e validando que o OEM cobre o caminho feliz sem gaps, que o Derived State é calculado corretamente em cada transição, e que o GitHub COR é sincronizado ao final.

**Contexto de domínio:** A funcionalidade de criação de split payment distribui o valor de uma transação entre múltiplos recebedores. A Feature cobre os eventos de Delivery — não a implementação da funcionalidade em si.

**Critérios de aceite:**

- [ ] Feature em estado `DONE` ao final (Derived State = `DONE` após `Promote.Completed`)
- [ ] Timeline com todos os 15 eventos esperados registrados em ordem cronológica
- [ ] Nenhum Event Type ausente no catálogo Delivery v2.0.0 para o caminho feliz (resposta parcial a Q1)
- [ ] Derived State calculado corretamente após cada `alters_state: true` (resposta parcial a Q2)
- [ ] GitHub COR com `oem:state = DONE` e `oem:last-event = Delivery.Promote.Completed` ao final
- [ ] `Shared.Gate.Passed` registrado uma vez na fase VALIDATING
- [ ] `evidence/timelines/feature-a/` com todas as Event Instances
- [ ] `evidence/derived-state-log.md` com log completo das transições de FTR-RUNTIME-001

**Dependências:**

| Depende de | Motivo |
|---|---|
| RT-01 (Event Producer) | Emissão de Event Instances em formato canônico |
| RT-02 (Timeline Processor) | Cálculo de Derived State após cada evento |
| RT-03 (GitHub Synchronizer) | Sincronização do estado no GitHub COR |
| Phase 1 do Execution Plan | GitHub Project configurado, credenciais disponíveis |

**Evidências esperadas:**

| Evidência | Localização | Critério relacionado |
|---|---|---|
| Event Instances (15 eventos) | `evidence/timelines/feature-a/` | CS-01 |
| Derived State Log (FTR-RUNTIME-001) | `evidence/derived-state-log.md` | CS-02, CS-03 |
| GitHub COR snapshot (estado final) | `evidence/github-cor-snapshot.md` | CS-03 |

---

### FTR-RUNTIME-002 — Split Allocation Validation (Gate Failed + Rework)

**Mapeamento:** Feature B da COR — cenário Gate Failed → Rework → Gate Passed

**Objetivo:** Executar a Delivery Journey para a validação de alocação de split, forçar um Gate.Failed durante VALIDATING, executar um ciclo de Rework completo, e concluir com Gate.Passed. Valida que o OEM suporta o caminho de exceção mais comum e que o Derived State representa `REWORKING` corretamente.

**Contexto de domínio:** A validação de alocação de split verifica se as regras de distribuição percentual estão corretas (soma = 100%, recebedores ativos). Quando a validação falha durante o Gate, a Feature retorna para Rework.

**Critérios de aceite:**

- [ ] Feature em estado `DONE` ao final
- [ ] `Shared.Gate.Failed` registrado durante VALIDATING
- [ ] `Delivery.Rework.Declared` registrado imediatamente após Gate.Failed
- [ ] Derived State = `REWORKING` após `Rework.Declared`
- [ ] Ciclo de Rework completo executado (pelo menos Hack + Sync + Finish + Ship)
- [ ] `Delivery.Rework.Completed` registrado — Derived State retorna a `VALIDATING`
- [ ] `Shared.Gate.Passed` registrado após Rework
- [ ] `oem:rework-count = 1` no GitHub COR após o ciclo
- [ ] GitHub COR com `oem:state = REWORKING` durante o ciclo e `DONE` ao final
- [ ] `evidence/rework-timeline.md` preenchido com narrativa e timestamps

**Dependências:**

| Depende de | Motivo |
|---|---|
| RT-01 (Event Producer) | Emissão de Gate.Failed e Rework.Declared em formato canônico |
| RT-02 (Timeline Processor) | Cálculo de Derived State para transição REWORKING |
| RT-03 (GitHub Synchronizer) | Atualização de `oem:rework-count` e `oem:state = REWORKING` |
| FTR-RUNTIME-001 | Validação do Happy Path antes de testar exceção |

**Evidências esperadas:**

| Evidência | Localização | Critério relacionado |
|---|---|---|
| Event Instances (sequência com Gate.Failed + Rework) | `evidence/timelines/feature-b/` | CS-01, CS-04 |
| Rework Timeline (narrativa) | `evidence/rework-timeline.md` | CS-04 |
| Derived State Log (FTR-RUNTIME-002) | `evidence/derived-state-log.md` | CS-02 |

---

### FTR-RUNTIME-003 — Settlement Webhook Notification (Blocking + Drift)

**Mapeamento:** Feature C da COR — cenário Blocking + Lookback + Diligence Drift

**Objetivo:** Executar a Delivery Journey para a notificação de webhook de liquidação, introduzir um impedimento real durante HACKING, resolver via `Delivery.Impediment.Resolved` com Lookback (`alters_state: false`), concluir a Delivery normalmente, e durante a Diligence Async introduzir um Drift deliberado nesta Feature para validar o ciclo de reparo.

**Contexto de domínio:** A notificação de webhook de liquidação avisa o sistema downstream quando uma liquidação financeira é processada. A dependência de liquidação bancária externa é uma fonte real de impedimentos — torna este cenário de Blocking naturalmente motivado pelo domínio.

**Critérios de aceite:**

- [ ] Feature em estado `DONE` ao final
- [ ] `Shared.Impediment.Declared` registrado durante HACKING com Derived State = `BLOCKED`
- [ ] `Delivery.Impediment.Resolved` registrado com `alters_state: false` e payload `{ "preBlockedState": "HACKING" }`
- [ ] Consumer executa Lookback: identifica último evento `alters_state: true` anterior ao `Impediment.Declared`
- [ ] Derived State = `HACKING` após resolução (via Lookback — não `BLOCKED`)
- [ ] `oem:blocked-since` preenchido no GitHub COR durante o bloqueio; limpo após resolução
- [ ] GitHub COR com `oem:state = HACKING` após resolução
- [ ] Drift introduzido durante Diligence Async (remoção deliberada de label canônica ou desatualização de Custom Field)
- [ ] Drift detectado pelo Scan, classificado pelo Flag, reparado pelo Repair
- [ ] `evidence/blocking-lookback-trace.md` com trace completo do Lookback
- [ ] `evidence/diligence-drift-repair.md` com descrição do Drift, ação corretora, e estado pós-repair

**Dependências:**

| Depende de | Motivo |
|---|---|
| RT-01 (Event Producer) | Emissão de Impediment.Declared e Impediment.Resolved |
| RT-02 (Timeline Processor) | Algoritmo de Lookback para `alters_state: false` |
| RT-03 (GitHub Synchronizer) | Atualização de `oem:blocked-since` e sincronização pós-Lookback |
| FTR-RUNTIME-001 | Lookback pressupõe Timeline Processor validado no Happy Path |
| FTR-RUNTIME-002 | Execução sequencial para isolamento de cenários |

**Evidências esperadas:**

| Evidência | Localização | Critério relacionado |
|---|---|---|
| Event Instances (sequência com BLOCKED + Lookback) | `evidence/timelines/feature-c/` | CS-01, CS-05 |
| Blocking + Lookback Trace | `evidence/blocking-lookback-trace.md` | CS-05 |
| Diligence Drift + Repair | `evidence/diligence-drift-repair.md` | CS-06 |
| Derived State Log (FTR-RUNTIME-003) | `evidence/derived-state-log.md` | CS-02 |

---

## 3. Runtime Tasks

### RT-01 — Event Producer

**Descrição:** Mecanismo de emissão de Event Instances em formato canônico (OEM) durante a execução das Features. Pode ser manual (operador preenche JSON a cada evento) ou script auxiliar em `evidence/scripts/`.

**Objetivo:** Garantir que cada evento da Delivery e Diligence Journey seja registrado com todos os campos obrigatórios do OEM — `type`, `occurred_at`, `work_item_id`, `iteration_id`, `alters_state`, `new_state` (quando aplicável), `payload`.

**Schema canônico de Event Instance:**

```json
{
  "type": "<Journey>.<EventType>",
  "occurred_at": "<ISO-8601>",
  "work_item_id": "<feature-id>",
  "iteration_id": "IP-RUNTIME-001",
  "alters_state": true | false,
  "new_state": "<STATE>" | null,
  "payload": { }
}
```

**Definition of Done:**

- [ ] Schema de Event Instance documentado e validado contra o catálogo Delivery v2.0.0
- [ ] Primeiro evento emitido: `Delivery.Bootstrap.Started` para FTR-RUNTIME-001
- [ ] Evento registrado em `evidence/timelines/feature-a/` e legível
- [ ] Campos obrigatórios presentes: `type`, `occurred_at`, `work_item_id`, `alters_state`
- [ ] `new_state` presente quando `alters_state: true`; ausente quando `alters_state: false`

**Dependências:**

- Phase 1 do Execution Plan (formato de registro definido)
- Catálogos de Journey v2.0.0 (Delivery, Diligence) como referência de Event Types válidos

---

### RT-02 — Timeline Processor

**Descrição:** Consumer que calcula o Derived State a partir da Timeline de eventos. Lê Event Instances em ordem cronológica, aplica a regra de Derived State (último `alters_state: true` → `new_state`), e implementa o algoritmo de Lookback para `Delivery.Impediment.Resolved`.

**Objetivo:** Garantir que o Derived State calculado pelo Consumer corresponda ao estado real do Work Item em qualquer ponto na Timeline — incluindo o caso especial do Lookback.

**Algoritmo de Derived State:**

```
derived_state = new_state do último evento com alters_state: true na Timeline
```

**Algoritmo de Lookback (para Impediment.Resolved com alters_state: false):**

```
1. Encontrar Impediment.Resolved na Timeline
2. Encontrar o último evento alters_state: true ANTERIOR ao Impediment.Declared
3. derived_state = new_state desse evento anterior
```

**Definition of Done:**

- [ ] Derived State calculado corretamente após cada `alters_state: true` para FTR-RUNTIME-001
- [ ] Log de transições em `evidence/derived-state-log.md` com pelo menos uma entrada por transição de estado
- [ ] Replay executado para FTR-RUNTIME-001: Derived State final = `DONE` a partir de cálculo do zero (idêntico ao incremental)
- [ ] Lookback executado para FTR-RUNTIME-003: Derived State pós-resolução = `HACKING`
- [ ] Nenhuma dependência de estado externo — toda derivação vem da Timeline

**Dependências:**

- RT-01 (Event Instances disponíveis para leitura)

---

### RT-03 — GitHub Synchronizer

**Descrição:** Procedimento de sincronização do Derived State calculado pelo Timeline Processor para os Custom Fields do GitHub Project. Pode ser executado manualmente via `gh` CLI ou via script auxiliar em `evidence/scripts/`.

**Objetivo:** Manter o GitHub COR atualizado após cada transição de estado, refletindo o Derived State calculado nos campos `oem:state`, `oem:last-event`, `oem:rework-count`, `oem:blocked-since`, e `runtime:last-sync`.

**Comandos de referência:**

```bash
# Atualizar oem:state
gh project item-edit <item-id> \
  --project-id <project-id> \
  --field-id <field-id> \
  --text "HACKING"

# Verificar membership (idempotência)
gh project item-list <project-number> --owner <owner> --format json \
  | jq '.items[] | select(.content.number == <issue-number>)'

# Adicionar Issue ao projeto (se não for membro)
gh project item-add <project-number> \
  --owner <owner> \
  --url https://github.com/<owner>/<repo>/issues/<N>
```

**Definition of Done:**

- [ ] GitHub COR sincronizado com `oem:state = DONE` para FTR-RUNTIME-001 ao final
- [ ] `oem:rework-count = 1` sincronizado para FTR-RUNTIME-002 após ciclo de Rework
- [ ] `oem:blocked-since` preenchido durante BLOCKED e limpo após resolução para FTR-RUNTIME-003
- [ ] `runtime:last-sync` atualizado após cada sincronização
- [ ] Snapshot de evidência em `evidence/github-cor-snapshot.md` após cada Phase relevante
- [ ] Issues das três Features são membros do GitHub Project `ProdOps — payments-api`

**Dependências:**

- RT-02 (Derived State calculado antes de sincronizar)
- Phase 1 do Execution Plan (GitHub Project com Custom Fields configurados)

---

### RT-04 — Datadog Integration

**Descrição:** Envio de métricas derivadas da Timeline para o Datadog via API, com trace rastreável até os eventos de origem.

**Objetivo:** Garantir que pelo menos uma métrica derivada da Timeline seja visível no Datadog ao final da Phase 2, e que as métricas completas (Lead Time, Cycle Time, Block Time, Gate Failure Rate) estejam disponíveis para os dashboards na Phase 5.

**Namespace de métricas:** `prodops.runtime.validation.*`

**Métricas mínimas:**

| Métrica | Cálculo | Feature |
|---|---|---|
| `prodops.runtime.validation.events_emitted` | Count de eventos emitidos | A, B, C |
| `prodops.runtime.validation.lead_time_seconds` | `Promote.Completed.occurred_at` − `Bootstrap.Started.occurred_at` | A |
| `prodops.runtime.validation.cycle_time_hacking_seconds` | `Hack.Completed.occurred_at` − `Hack.Started.occurred_at` | A, B |
| `prodops.runtime.validation.block_time_seconds` | `Impediment.Resolved.occurred_at` − `Impediment.Declared.occurred_at` | C |
| `prodops.runtime.validation.gate_failure_rate` | `count(Gate.Failed)` / `count(Gate.Passed + Gate.Failed)` | B |
| `prodops.runtime.validation.drift_count` | Count de `Divergence.Detected` na Iteration | C |

**Definition of Done:**

- [ ] Primeira métrica (`events_emitted`) visível no Datadog ao final da Phase 2
- [ ] Trace da métrica rastreável até o evento de origem na Timeline
- [ ] Screenshot salvo em `evidence/datadog-screenshot.md` com evidência da primeira métrica
- [ ] Todas as métricas acima calculadas e enviadas ao final da Phase 4

**Dependências:**

- RT-01 (eventos com `occurred_at` disponíveis para cálculo)
- Phase 1 do Execution Plan (Datadog configurado com API Key)

---

### RT-05 — Delivery Dashboard

**Descrição:** Construção ou validação do Dashboard de Delivery no Datadog com métricas derivadas exclusivamente da Timeline.

**Objetivo:** Demonstrar que Lead Time, Cycle Time, Block Time, e Gate Failure Rate podem ser visualizados no Datadog com trace rastreável até eventos da Timeline — respondendo Q6 do EXP-013.

**Métricas obrigatórias no Dashboard:**

| Métrica | Visualização | Feature de referência |
|---|---|---|
| Lead Time por Feature | Bar chart ou Table | A |
| Cycle Time (Hack) | Bar chart | A, B |
| Block Time | Timeseries ou Stat | C |
| Gate Failure Rate | Stat widget (%) | B |

**Definition of Done:**

- [ ] Dashboard "Delivery — IP-RUNTIME-001" criado ou validado no Datadog
- [ ] Pelo menos Lead Time e Gate Failure Rate visíveis com dados reais
- [ ] Cada widget tem descrição indicando o evento de origem da métrica
- [ ] Screenshot salvo em `evidence/datadog-screenshot.md` (seção Dashboard Delivery)

**Dependências:**

- RT-04 (métricas enviadas ao Datadog)
- Phase 3 concluída (dados reais das três Features disponíveis)

---

### RT-06 — Diligence Dashboard

**Descrição:** Construção ou validação do Dashboard de Diligence no Datadog com métricas derivadas das Timelines de Diligence.

**Objetivo:** Demonstrar que Drift Detection Rate e Repair Time podem ser calculados e visualizados no Datadog com trace rastreável até eventos da Timeline de Diligence.

**Métricas obrigatórias no Dashboard:**

| Métrica | Visualização | Feature de referência |
|---|---|---|
| Drift Detection Rate | Stat widget (count) | C |
| Repair Time | Stat widget (segundos) | C |

**Definition of Done:**

- [ ] Dashboard "Diligence — IP-RUNTIME-001" criado ou validado no Datadog
- [ ] Pelo menos Drift Detection Rate visível com dados reais
- [ ] Repair Time calculado a partir de `Repair.Completed.occurred_at − Flag.Completed.occurred_at`
- [ ] Screenshot salvo em `evidence/datadog-screenshot.md` (seção Dashboard Diligence)

**Dependências:**

- RT-04 (métricas enviadas ao Datadog)
- Phase 4 concluída (Diligence Async com Drift reparado)

---

## 4. Findings como Work Items

Cada tipo de Finding é um Work Item independente criado durante a execução quando a condição correspondente é identificada. São Issues no GitHub com `witem:type = Finding`.

### FIND-TYPE-001 — Drift

**Descrição:** Divergência entre o Derived State calculado pelo Timeline Processor e o estado registrado no GitHub COR.

**Quando criar:** Quando RT-03 detecta que `oem:state` no GitHub não corresponde ao Derived State atual, ou quando o Scan da Diligence Async identifica divergência.

**Campos do Work Item:**

| Campo | Valor |
|---|---|
| `witem:type` | `Finding` |
| `finding:type` | `drift` |
| `severity` | Média |
| `diligence:status` | `Non-Compliant` → `Repair In Progress` → `Compliant` |
| `runtime:sync` | `Drift Detected` → `Repair In Progress` → `Reconciled` |

**Critério de encerramento:** `Diligence.Repair.Completed` registrado; GitHub COR sincronizado; Issue fechado.

---

### FIND-TYPE-002 — Missing Evidence

**Descrição:** Evidência obrigatória definida no Execution Plan ausente ou incompleta ao final de uma Phase.

**Quando criar:** Ao encerrar qualquer Phase e verificar que algum arquivo em `evidence/` está ausente ou incompleto.

**Campos do Work Item:**

| Campo | Valor |
|---|---|
| `witem:type` | `Finding` |
| `finding:type` | `missing-evidence` |
| `severity` | Alta |
| `diligence:evidence` | `Missing` → `Partial` → `Complete` |

**Critério de encerramento:** Arquivo de evidência completo; `diligence:evidence = Complete`; Issue fechado.

---

### FIND-TYPE-003 — Missing Event

**Descrição:** Evento esperado na Timeline ausente — por omissão do operador (severidade Média) ou por ausência de Event Type no catálogo (severidade Alta).

**Quando criar:** Ao revisar a Timeline de qualquer Feature e identificar evento esperado ausente.

**Campos do Work Item:**

| Campo | Valor |
|---|---|
| `witem:type` | `Finding` |
| `finding:type` | `missing-event` |
| `severity` | Alta (gap estrutural) / Média (erro operacional) |

**Critério de encerramento:**
- Severidade Média: evento registrado retroativamente; Timeline completa; Issue fechado.
- Severidade Alta: registrado em `evidence/framework-gaps.md`; avaliação de interrupção do experimento.

---

### FIND-TYPE-004 — Runtime Error

**Descrição:** Falha no mecanismo do Runtime — Consumer produz Derived State incorreto, GitHub Synchronizer falha, ou emissão de evento produz payload inválido.

**Quando criar:** Quando RT-02 ou RT-03 produz resultado incorreto e o erro não é trivialmente corrigível.

**Campos do Work Item:**

| Campo | Valor |
|---|---|
| `witem:type` | `Finding` |
| `finding:type` | `runtime-error` |
| `severity` | Alta (estrutural) / Baixa (operacional) |

**Critério de encerramento:**
- Severidade Baixa: correção aplicada; resultado verificado; Issue fechado.
- Severidade Alta: avaliação de critério de fracasso (CF-01, CF-03); Issue pode permanecer aberto como evidência.

---

### FIND-TYPE-005 — Manual Review

**Descrição:** Ambiguidade que requer decisão humana — Event Type correto incerto, interpretação de `alters_state` dúbia, ou cenário inesperado sem cobertura clara no catálogo.

**Quando criar:** Quando o operador encontra situação que não pode ser resolvida por consulta direta ao catálogo.

**Campos do Work Item:**

| Campo | Valor |
|---|---|
| `witem:type` | `Finding` |
| `finding:type` | `manual-review` |
| `severity` | Baixa |

**Critério de encerramento:** Decisão registrada em `evidence/decisions.md`; interpretação aplicada consistentemente; Issue fechado.

---

## 5. Grafo de dependências

```
EPIC-RUNTIME-001
│
├── RT-01 Event Producer ────────────────────────────────────────┐
│       │                                                         │
│       ▼                                                         │
├── RT-02 Timeline Processor ───────────────────────────────┐    │
│       │                                                    │    │
│       ▼                                                    │    │
├── RT-03 GitHub Synchronizer                               │    │
│       │                                                    │    │
│       └─── depende de RT-02 (Derived State calculado)     │    │
│                                                            │    │
├── RT-04 Datadog Integration ────────────────────┐          │    │
│       │  depende de RT-01 (timestamps)          │          │    │
│       │                                         │          │    │
│       ▼                                         │          │    │
├── RT-05 Delivery Dashboard ◄────────────────────┤          │    │
│       │  depende de RT-04 + Phase 3 completa    │          │    │
│       │                                         │          │    │
├── RT-06 Diligence Dashboard ◄───────────────────┘          │    │
│       │  depende de RT-04 + Phase 4 completa               │    │
│       │                                                     │    │
│       │                                                     │    │
├── FTR-RUNTIME-001 (Feature A — Happy Path) ◄───────────────┤    │
│       │  depende de RT-01, RT-02, RT-03                    │    │
│       │  [valida: OEM suficiente? Derived State correto?]  │    │
│       │                                                     │    │
├── FTR-RUNTIME-002 (Feature B — Rework) ◄───────────────────┤    │
│       │  depende de RT-01, RT-02, RT-03, FTR-RUNTIME-001  │    │
│       │  [valida: Rework cycle, Gate.Failed, REWORKING]    │    │
│       │                                                     │    │
└── FTR-RUNTIME-003 (Feature C — Blocking + Drift) ◄─────────┘    │
        │  depende de RT-01, RT-02, RT-03, FTR-RUNTIME-001        │
        │  [valida: Lookback, Diligence Async, Drift reparo]       │
        │                                                           │
        └── FINDINGS ◄─────────────────────────────────────────────┘
                │  criados durante execução de qualquer Work Item
                │  encerrados via Diligence Async (Drift)
                │  ou por ação direta do operador
                │
                └── RT-05 / RT-06 (Dashboards)
                        │  encerram a evidence collection
                        │  habilitam Phase 6 (Discovery Consolidation)
```

**Dependências críticas (bloqueantes):**

| Work Item | Bloqueia | Motivo |
|---|---|---|
| RT-01 | RT-02, RT-04, todas as Features | Sem eventos não há Timeline nem métricas |
| RT-02 | RT-03, todas as Features | Derived State precisa ser calculado antes de sincronizar |
| RT-03 | FTR-RUNTIME-002, FTR-RUNTIME-003 | Rework Count e Blocked Since exigem sync funcional |
| FTR-RUNTIME-001 | FTR-RUNTIME-002, FTR-RUNTIME-003 | Happy Path valida Runtime antes de testar exceções |
| Phase 3 (completa) | RT-05 | Dashboard Delivery precisa de dados reais das 3 Features |
| Phase 4 (completa) | RT-06 | Dashboard Diligence precisa de Drift detectado e reparado |

---

## 6. Ordem sugerida de implementação

A sequência abaixo minimiza retrabalho e garante que cada etapa valida o substrato da próxima.

| # | Work Item | Phase | Objetivo da etapa |
|---|---|---|---|
| 1 | RT-01 — Event Producer | Phase 2 | Emitir primeiro evento; validar schema do OEM |
| 2 | RT-04 — Datadog Integration | Phase 2 | Primeira métrica no Datadog; validar pipeline de observabilidade |
| 3 | RT-02 — Timeline Processor | Phase 2–3 | Calcular Derived State; validar algoritmo padrão |
| 4 | RT-03 — GitHub Synchronizer | Phase 2–3 | Sincronizar COR; validar que GitHub é apenas espelho |
| 5 | FTR-RUNTIME-001 — Happy Path | Phase 3 | Validar OEM completo, Derived State, Timeline Replay |
| 6 | FTR-RUNTIME-002 — Rework | Phase 3 | Validar Gate.Failed, Rework cycle, REWORKING state |
| 7 | FTR-RUNTIME-003 — Blocking + Drift | Phase 3–4 | Validar Lookback, Impediment, Diligence Async |
| 8 | RT-05 — Delivery Dashboard | Phase 5 | Construir Dashboard; validar Q6 (métricas da Timeline) |
| 9 | RT-06 — Diligence Dashboard | Phase 5 | Completar observabilidade; fechar evidence collection |

**Regra de sequência:** os itens 1–4 (Runtime Tasks de infraestrutura) devem estar operacionais antes de iniciar qualquer Feature. As Features seguem a ordem A → B → C para isolamento progressivo de complexidade. Os Dashboards são construídos após todas as Features — dependem de dados reais.

**Findings** não têm posição na sequência — são criados à medida que identificados durante qualquer etapa e encerrados assim que a ação corretora for concluída.

---

## 7. Mapeamento para GitHub

Todos os Work Items abaixo virarão Issues no GitHub Project `ProdOps — payments-api`, associados à Milestone `v0.1.0-runtime-pilot` e ao campo `witem:iteration = IP-RUNTIME-001`.

| Work Item | GitHub Issue | Labels | Milestone | Iteration |
|---|---|---|---|---|
| EPIC-RUNTIME-001 | Issue "ProdOps Runtime MVP" (Epic) | `runtime:pilot`, `journey:delivery` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FTR-RUNTIME-001 | Issue "Split Payment Creation — Happy Path" | `runtime:pilot`, `journey:delivery`, `phase:bootstrap` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FTR-RUNTIME-002 | Issue "Split Allocation Validation — Gate Failed + Rework" | `runtime:pilot`, `journey:delivery`, `runtime:rework` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FTR-RUNTIME-003 | Issue "Settlement Webhook Notification — Blocking + Drift" | `runtime:pilot`, `journey:delivery`, `runtime:blocked`, `journey:diligence` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| RT-01 | Issue "RT-01: Event Producer" | `runtime:pilot`, `runtime:task` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| RT-02 | Issue "RT-02: Timeline Processor" | `runtime:pilot`, `runtime:task` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| RT-03 | Issue "RT-03: GitHub Synchronizer" | `runtime:pilot`, `runtime:task` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| RT-04 | Issue "RT-04: Datadog Integration" | `runtime:pilot`, `runtime:task` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| RT-05 | Issue "RT-05: Delivery Dashboard" | `runtime:pilot`, `runtime:task` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| RT-06 | Issue "RT-06: Diligence Dashboard" | `runtime:pilot`, `runtime:task` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FIND-TYPE-001 | Issue "Finding: Drift — [descrição]" (criado quando identificado) | `runtime:pilot`, `finding:drift`, `severity:medium` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FIND-TYPE-002 | Issue "Finding: Missing Evidence — [evidência]" | `runtime:pilot`, `finding:missing-evidence`, `severity:high` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FIND-TYPE-003 | Issue "Finding: Missing Event — [evento]" | `runtime:pilot`, `finding:missing-event`, `severity:high`/`medium` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FIND-TYPE-004 | Issue "Finding: Runtime Error — [descrição]" | `runtime:pilot`, `finding:runtime-error`, `severity:high`/`low` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |
| FIND-TYPE-005 | Issue "Finding: Manual Review — [decisão pendente]" | `runtime:pilot`, `finding:manual-review`, `severity:low` | `v0.1.0-runtime-pilot` | `IP-RUNTIME-001` |

**Convenção de título:** `[Tipo]: [Descrição concisa]` — ex.: `FTR: Split Payment Creation — Happy Path`, `RT: Event Producer`, `FIND: Drift — oem:state desatualizado após Rework`

**Organização no GitHub Project:**

- Todos os Issues acima são itens do projeto `ProdOps — payments-api`
- View "Iteration Plan" filtra por `witem:iteration = IP-RUNTIME-001` e exibe todos
- View "Delivery Flow" filtra Features e agrupa por `oem:state`
- View "Findings" filtra `witem:type = Finding` e ordena por severidade
- Milestone `v0.1.0-runtime-pilot` agrupa todos os Issues para visão executiva de Release
