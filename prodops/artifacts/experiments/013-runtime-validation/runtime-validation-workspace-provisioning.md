# Runtime Validation — Workspace Provisioning

> **Localização canônica:** `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-workspace-provisioning.md`
>
> Este documento define o provisionamento completo do Workspace GitHub para o piloto de validação do Runtime. O resultado esperado é um GitHub Project vazio de execução, porém completamente preparado para receber os Work Items do Product Backlog. Nenhum código, Runtime, ou integração é criado aqui.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **COR** | [runtime-validation-cor.md](./runtime-validation-cor.md) |
| **Product Backlog** | [runtime-validation-product-backlog.md](./runtime-validation-product-backlog.md) |
| **Execution Plan** | [runtime-validation-execution-plan.md](./runtime-validation-execution-plan.md) |
| **Experimento** | [EXP-013](./experiment.md) |
| **Data de criação** | 2026-07-25 |
| **Status** | Planejado — aguarda execução da Phase 1 do Execution Plan |

---

## 1. GitHub Project

### Definição

| Campo | Valor |
|---|---|
| **Nome** | `ProdOps — payments-api` |
| **Descrição** | Canonical Operational Representation do ProdOps Runtime no payments-api. Espelho de Derived State calculado a partir da Operational Timeline — não é fonte de verdade. |
| **Owner** | `<org-or-user>` (substituir pelo owner real do repositório payments-api) |
| **Repository** | `payments-api` |
| **Template** | Nenhum template padrão do GitHub — configuração manual para garantir alinhamento com a COR |
| **Visibilidade** | Private (padrão para projetos operacionais) |

### Princípio fundamental

> O GitHub Project `ProdOps — payments-api` é uma **superfície de visualização**. Os valores dos Custom Fields são calculados a partir da Operational Timeline e sincronizados pelo RT-03 (GitHub Synchronizer). Nunca devem ser editados diretamente como fonte de dados — apenas como resultado de uma sincronização.

### Critérios para considerar o Project provisionado

- [ ] Project `ProdOps — payments-api` criado e acessível pelo time
- [ ] Descrição registrada corretamente
- [ ] Todos os 19 Custom Fields criados com tipos e valores corretos (Seção 3)
- [ ] Todas as Labels criadas no repositório `payments-api` (Seção 4)
- [ ] Todas as 7 Views configuradas (Seção 5)
- [ ] Milestone `v0.1.0-runtime-pilot` criada (Seção 2)
- [ ] Iteration `IP-RUNTIME-001` representada via campo `witem:iteration` (Seção 6)
- [ ] Regras de Membership definidas e conhecidas pelo time (Seção 7)

### Comandos de criação

```bash
# Criar o projeto
gh project create \
  --owner <owner> \
  --title "ProdOps — payments-api" \
  --format json

# Capturar o número do projeto para uso nos demais comandos
PROJECT_NUMBER=$(gh project list --owner <owner> --format json \
  | jq '.projects[] | select(.title == "ProdOps — payments-api") | .number')

echo "Project number: $PROJECT_NUMBER"
```

---

## 2. Milestone

### Definição

| Campo | Valor |
|---|---|
| **Nome** | `v0.1.0-runtime-pilot — Runtime Validation Pilot` |
| **Título curto (GitHub)** | `v0.1.0-runtime-pilot` |
| **Descrição** | Milestone de encerramento do piloto de validação do ProdOps Runtime (EXP-013). Agrupa as três Features (FTR-RUNTIME-001/002/003), as seis Runtime Tasks (RT-01..RT-06), e todos os Findings da Iteration IP-RUNTIME-001. |
| **Data de início** | Início da Phase 1 do Execution Plan |
| **Data de encerramento** | Estimada: início + 25 horas de execução (ver Execution Plan) |

### Objetivo

Agrupar todos os Work Items do piloto para visão executiva de Release — qual é o progresso relativo ao fechamento da Milestone `v0.1.0-runtime-pilot`.

### Critério de encerramento

A Milestone é fechada quando:

- [ ] FTR-RUNTIME-001, FTR-RUNTIME-002, FTR-RUNTIME-003 — Issues fechadas com estado `DONE`
- [ ] RT-01..RT-06 — Issues fechadas (DoD satisfeito)
- [ ] Todos os Findings — Issues fechadas ou critério de encerramento satisfeito
- [ ] Discovery Report preenchido com recomendação formal registrada
- [ ] Nenhum Finding com `severity:high` em aberto

### Comando de criação

```bash
gh api repos/<owner>/payments-api/milestones \
  --method POST \
  --field title="v0.1.0-runtime-pilot" \
  --field description="Runtime Validation Pilot — EXP-013. Agrupa Features, Runtime Tasks e Findings da Iteration IP-RUNTIME-001." \
  --field state="open"
```

---

## 3. Fields

Todos os campos abaixo são Custom Fields do GitHub Project `ProdOps — payments-api`. São materializações dos campos definidos na COR. Campos marcados como **Runtime** são atualizados pelo RT-03 (GitHub Synchronizer). Campos marcados como **Manual** são preenchidos pelo operador no momento da criação ou da fase relevante.

### 3.1 Identity Fields

#### `witem:type`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `witem:type` |
| **Valores** | `Feature`, `Runtime Task`, `Finding` |
| **Obrigatório** | Sim |
| **Atualização** | Manual (no momento da criação do Issue) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "witem:type" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Feature,Runtime Task,Finding"
```

---

#### `witem:repository`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Text |
| **Nome do campo** | `witem:repository` |
| **Valores** | `payments-api` (valor fixo para este piloto) |
| **Obrigatório** | Sim |
| **Atualização** | Manual (no momento da criação) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "witem:repository" \
  --data-type "TEXT"
```

---

#### `witem:feature`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Text |
| **Nome do campo** | `witem:feature` |
| **Valores** | `FTR-RUNTIME-001`, `FTR-RUNTIME-002`, `FTR-RUNTIME-003`, `RT-01`..`RT-06`, ou identificador do Finding |
| **Obrigatório** | Sim |
| **Atualização** | Manual |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "witem:feature" \
  --data-type "TEXT"
```

---

#### `witem:obc`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Text |
| **Nome do campo** | `witem:obc` |
| **Valores** | `EXP-013` (para todos os itens do piloto) |
| **Obrigatório** | Sim |
| **Atualização** | Manual |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "witem:obc" \
  --data-type "TEXT"
```

---

#### `witem:release`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Text |
| **Nome do campo** | `witem:release` |
| **Valores** | `v0.1.0-runtime-pilot` |
| **Obrigatório** | Sim |
| **Atualização** | Manual (no momento da criação) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "witem:release" \
  --data-type "TEXT"
```

---

#### `witem:iteration`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Text |
| **Nome do campo** | `witem:iteration` |
| **Valores** | `IP-RUNTIME-001` |
| **Obrigatório** | Sim |
| **Atualização** | Manual (no momento da criação) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "witem:iteration" \
  --data-type "TEXT"
```

---

### 3.2 Delivery Fields

#### `oem:journey`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `oem:journey` |
| **Valores** | `Delivery`, `Diligence`, `Assessment` |
| **Obrigatório** | Sim |
| **Atualização** | Manual |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "oem:journey" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Delivery,Diligence,Assessment"
```

---

#### `oem:cycle`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `oem:cycle` |
| **Valores** | `Bootstrap`, `Hack`, `Sync`, `Finish`, `Ship`, `Validate`, `Promote`, `Rework` |
| **Obrigatório** | Não (opcional — representa a fase corrente) |
| **Atualização** | Manual ou Runtime |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "oem:cycle" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Bootstrap,Hack,Sync,Finish,Ship,Validate,Promote,Rework"
```

---

#### `oem:phase`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `oem:phase` |
| **Valores** | `Started`, `Completed` |
| **Obrigatório** | Não (opcional) |
| **Atualização** | Manual ou Runtime |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "oem:phase" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Started,Completed"
```

---

#### `oem:state`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `oem:state` |
| **Valores** | `BOOTSTRAPPING`, `HACKING`, `SYNCING`, `FINISHING`, `SHIPPING`, `VALIDATING`, `PROMOTING`, `DONE`, `BLOCKED`, `REWORKING` |
| **Obrigatório** | Sim |
| **Atualização** | **Runtime** (RT-03 — atualizado após cada `alters_state: true`) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "oem:state" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "BOOTSTRAPPING,HACKING,SYNCING,FINISHING,SHIPPING,VALIDATING,PROMOTING,DONE,BLOCKED,REWORKING"
```

---

#### `oem:rework-count`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Number |
| **Nome do campo** | `oem:rework-count` |
| **Valores** | 0, 1, 2, ... |
| **Obrigatório** | Não (default: 0) |
| **Atualização** | **Runtime** (RT-03 — incrementado a cada `Rework.Declared`) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "oem:rework-count" \
  --data-type "NUMBER"
```

---

#### `oem:blocked-since`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Date |
| **Nome do campo** | `oem:blocked-since` |
| **Valores** | ISO-8601 date (ex.: `2026-07-25`) |
| **Obrigatório** | Não (preenchido apenas quando BLOCKED) |
| **Atualização** | **Runtime** (RT-03 — preenchido em `Impediment.Declared`; limpo em `Impediment.Resolved`) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "oem:blocked-since" \
  --data-type "DATE"
```

---

### 3.3 Diligence Fields

#### `diligence:status`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `diligence:status` |
| **Valores** | `Pending`, `Sync In Progress`, `Async In Progress`, `Compliant`, `Non-Compliant` |
| **Obrigatório** | Sim (para Features) |
| **Atualização** | **Runtime** (RT-03 — atualizado após eventos Diligence) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "diligence:status" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Pending,Sync In Progress,Async In Progress,Compliant,Non-Compliant"
```

---

#### `diligence:evidence`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `diligence:evidence` |
| **Valores** | `Missing`, `Partial`, `Complete` |
| **Obrigatório** | Sim (para Features) |
| **Atualização** | Manual (operador atualiza após coletar evidências) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "diligence:evidence" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Missing,Partial,Complete"
```

---

### 3.4 Runtime Fields

#### `runtime:sync`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `runtime:sync` |
| **Valores** | `Pending`, `In Sync`, `Drift Detected`, `Repair In Progress`, `Reconciled` |
| **Obrigatório** | Sim |
| **Atualização** | **Runtime** (RT-03 — atualizado após cada verificação de COR) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "runtime:sync" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Pending,In Sync,Drift Detected,Repair In Progress,Reconciled"
```

---

#### `runtime:timeline-state`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Single Select |
| **Nome do campo** | `runtime:timeline-state` |
| **Valores** | `Empty`, `In Progress`, `Complete`, `Replay Verified` |
| **Obrigatório** | Sim |
| **Atualização** | Manual (operador atualiza após cada Phase relevante) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "runtime:timeline-state" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Empty,In Progress,Complete,Replay Verified"
```

---

#### `oem:last-event`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Text |
| **Nome do campo** | `oem:last-event` |
| **Valores** | Tipo do último evento registrado (ex.: `Delivery.Hack.Started`) |
| **Obrigatório** | Sim |
| **Atualização** | **Runtime** (RT-03 — atualizado após cada evento) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "oem:last-event" \
  --data-type "TEXT"
```

---

#### `runtime:last-sync`

| Atributo | Valor |
|---|---|
| **Tipo GitHub** | Date |
| **Nome do campo** | `runtime:last-sync` |
| **Valores** | ISO-8601 datetime da última sincronização do RT-03 |
| **Obrigatório** | Não |
| **Atualização** | **Runtime** (RT-03 — automaticamente a cada sync) |

```bash
gh project field-create $PROJECT_NUMBER \
  --owner <owner> \
  --name "runtime:last-sync" \
  --data-type "DATE"
```

---

### Resumo de todos os Fields

| Campo | Tipo | Atualização | Obrigatório |
|---|---|---|---|
| `witem:type` | Single Select | Manual | Sim |
| `witem:repository` | Text | Manual | Sim |
| `witem:feature` | Text | Manual | Sim |
| `witem:obc` | Text | Manual | Sim |
| `witem:release` | Text | Manual | Sim |
| `witem:iteration` | Text | Manual | Sim |
| `oem:journey` | Single Select | Manual | Sim |
| `oem:cycle` | Single Select | Manual/Runtime | Não |
| `oem:phase` | Single Select | Manual/Runtime | Não |
| `oem:state` | Single Select | **Runtime** | Sim |
| `oem:rework-count` | Number | **Runtime** | Não |
| `oem:blocked-since` | Date | **Runtime** | Não |
| `diligence:status` | Single Select | **Runtime** | Sim (Features) |
| `diligence:evidence` | Single Select | Manual | Sim (Features) |
| `runtime:sync` | Single Select | **Runtime** | Sim |
| `runtime:timeline-state` | Single Select | Manual | Sim |
| `oem:last-event` | Text | **Runtime** | Sim |
| `runtime:last-sync` | Date | **Runtime** | Não |

**Total: 18 Custom Fields.** Os campos `Title`, `Assignees`, `Status` (nativo), `Labels`, e `Milestone` são fornecidos nativamente pelo GitHub e não precisam ser criados como Custom Fields.

---

## 4. Labels

Todas as Labels abaixo são criadas no repositório `payments-api`. Labels são estáveis — classificam o tipo e a natureza do Issue. Não são redundantes com os Custom Fields, que armazenam estado derivado.

### 4.1 Journey

| Label | Cor sugerida | Descrição |
|---|---|---|
| `journey:delivery` | `#0075ca` (azul) | Issue pertence à Delivery Journey |
| `journey:diligence` | `#e4e669` (amarelo) | Issue pertence à Diligence Journey |
| `journey:assessment` | `#d93f0b` (laranja) | Issue pertence à Assessment Journey |

```bash
gh label create "journey:delivery"    --repo <owner>/payments-api --color "0075ca" --description "Delivery Journey"
gh label create "journey:diligence"   --repo <owner>/payments-api --color "e4e669" --description "Diligence Journey"
gh label create "journey:assessment"  --repo <owner>/payments-api --color "d93f0b" --description "Assessment Journey"
```

---

### 4.2 Phase

| Label | Cor sugerida | Descrição |
|---|---|---|
| `phase:bootstrap` | `#bfd4f2` (azul claro) | Fase Bootstrap |
| `phase:hack` | `#bfd4f2` | Fase Hack |
| `phase:sync` | `#bfd4f2` | Fase Sync |
| `phase:finish` | `#bfd4f2` | Fase Finish |
| `phase:ship` | `#bfd4f2` | Fase Ship |
| `phase:validate` | `#bfd4f2` | Fase Validate |
| `phase:promote` | `#bfd4f2` | Fase Promote |

```bash
for PHASE in bootstrap hack sync finish ship validate promote; do
  gh label create "phase:$PHASE" \
    --repo <owner>/payments-api \
    --color "bfd4f2" \
    --description "Fase $PHASE"
done
```

---

### 4.3 Runtime

| Label | Cor sugerida | Descrição |
|---|---|---|
| `runtime:pilot` | `#5319e7` (roxo) | Issue faz parte do piloto EXP-013 |
| `runtime:task` | `#8b5cf6` (roxo claro) | Issue é uma Runtime Task (RT-01..RT-06) |
| `runtime:blocked` | `#b60205` (vermelho) | Issue em estado BLOCKED (Impediment.Declared ativo) |
| `runtime:rework` | `#fbca04` (amarelo-âmbar) | Issue passou por pelo menos um ciclo de Rework |

```bash
gh label create "runtime:pilot"   --repo <owner>/payments-api --color "5319e7" --description "Piloto EXP-013"
gh label create "runtime:task"    --repo <owner>/payments-api --color "8b5cf6" --description "Runtime Task"
gh label create "runtime:blocked" --repo <owner>/payments-api --color "b60205" --description "BLOCKED — Impediment ativo"
gh label create "runtime:rework"  --repo <owner>/payments-api --color "fbca04" --description "Passou por ciclo de Rework"
```

---

### 4.4 Severity

| Label | Cor sugerida | Descrição |
|---|---|---|
| `severity:high` | `#b60205` (vermelho) | Severidade Alta — bloqueia fase ou critério de fracasso |
| `severity:medium` | `#fbca04` (amarelo) | Severidade Média — reparável; não bloqueia automaticamente |
| `severity:low` | `#0e8a16` (verde) | Severidade Baixa — observacional |

```bash
gh label create "severity:high"   --repo <owner>/payments-api --color "b60205" --description "Severidade Alta"
gh label create "severity:medium" --repo <owner>/payments-api --color "fbca04" --description "Severidade Média"
gh label create "severity:low"    --repo <owner>/payments-api --color "0e8a16" --description "Severidade Baixa"
```

---

### 4.5 Finding

| Label | Cor sugerida | Descrição |
|---|---|---|
| `finding:drift` | `#e11d48` (rosa-vermelho) | Finding: Drift entre COR e Derived State |
| `finding:missing-evidence` | `#dc2626` (vermelho escuro) | Finding: Evidência obrigatória ausente |
| `finding:missing-event` | `#ea580c` (laranja escuro) | Finding: Evento esperado ausente na Timeline |
| `finding:runtime-error` | `#991b1b` (vermelho muito escuro) | Finding: Falha no mecanismo do Runtime |
| `finding:manual-review` | `#6b7280` (cinza) | Finding: Revisão manual necessária |

```bash
gh label create "finding:drift"             --repo <owner>/payments-api --color "e11d48" --description "Drift COR/Derived State"
gh label create "finding:missing-evidence"  --repo <owner>/payments-api --color "dc2626" --description "Evidência ausente"
gh label create "finding:missing-event"     --repo <owner>/payments-api --color "ea580c" --description "Evento ausente na Timeline"
gh label create "finding:runtime-error"     --repo <owner>/payments-api --color "991b1b" --description "Falha no Runtime"
gh label create "finding:manual-review"     --repo <owner>/payments-api --color "6b7280" --description "Revisão manual necessária"
```

---

### 4.6 Evidence

| Label | Cor sugerida | Descrição |
|---|---|---|
| `evidence:missing` | `#b60205` (vermelho) | Evidência obrigatória ainda não coletada |
| `evidence:partial` | `#fbca04` (amarelo) | Evidência coletada parcialmente |
| `evidence:complete` | `#0e8a16` (verde) | Evidência completa e verificada |

```bash
gh label create "evidence:missing"  --repo <owner>/payments-api --color "b60205" --description "Evidência ausente"
gh label create "evidence:partial"  --repo <owner>/payments-api --color "fbca04" --description "Evidência parcial"
gh label create "evidence:complete" --repo <owner>/payments-api --color "0e8a16" --description "Evidência completa"
```

---

### Resumo de Labels

| Categoria | Quantidade |
|---|---|
| Journey | 3 |
| Phase | 7 |
| Runtime | 4 |
| Severity | 3 |
| Finding | 5 |
| Evidence | 3 |
| **Total** | **25** |

---

## 5. Views

Todas as Views são configuradas no GitHub Project `ProdOps — payments-api`. A configuração é manual via interface do GitHub Projects ou via API GraphQL.

### View 1 — Iteration Plan

**Objetivo:** Visão consolidada de todos os Work Items da IP-RUNTIME-001, com estado atual e progresso.

| Atributo | Configuração |
|---|---|
| **Tipo de View** | Table (tabela) |
| **Filtro** | `witem:iteration = IP-RUNTIME-001` |
| **Agrupamento** | Por `witem:type` (Feature → Runtime Task → Finding) |
| **Ordenação** | Por `witem:feature` dentro de cada grupo |
| **Colunas exibidas** | `Title`, `witem:feature`, `witem:type`, `oem:state`, `oem:journey`, `diligence:status`, `runtime:sync` |
| **Responsável** | Tech Lead |

---

### View 2 — Delivery Flow

**Objetivo:** Acompanhar o progresso das Features pela Delivery Journey em tempo real.

| Atributo | Configuração |
|---|---|
| **Tipo de View** | Board (kanban) |
| **Filtro** | `witem:type = Feature` AND `oem:journey = Delivery` AND `witem:iteration = IP-RUNTIME-001` |
| **Agrupamento** | Por `oem:state` (colunas) |
| **Colunas** | `BOOTSTRAPPING` → `HACKING` → `SYNCING` → `FINISHING` → `SHIPPING` → `VALIDATING` → `PROMOTING` → `DONE` |
| **Campos exibidos em card** | `witem:feature`, `oem:last-event`, `oem:rework-count`, `oem:blocked-since` |
| **Responsável** | Operador da Delivery |

---

### View 3 — Diligence Flow

**Objetivo:** Acompanhar o estado de conformidade das Features pela Diligence Journey.

| Atributo | Configuração |
|---|---|
| **Tipo de View** | Board (kanban) |
| **Filtro** | `witem:type = Feature` AND `witem:iteration = IP-RUNTIME-001` |
| **Agrupamento** | Por `diligence:status` (colunas) |
| **Colunas** | `Pending` → `Sync In Progress` → `Async In Progress` → `Compliant` → `Non-Compliant` |
| **Campos exibidos em card** | `witem:feature`, `diligence:evidence`, `runtime:sync`, `runtime:timeline-state` |
| **Responsável** | Operador da Diligence |

---

### View 4 — Runtime Reconciliation

**Objetivo:** Detectar e acompanhar divergências entre Derived State e GitHub COR.

| Atributo | Configuração |
|---|---|
| **Tipo de View** | Table (tabela) |
| **Filtro** | `witem:iteration = IP-RUNTIME-001` AND `runtime:sync != In Sync` |
| **Agrupamento** | Por `runtime:sync` |
| **Ordenação** | Por `runtime:last-sync` (mais antigo primeiro — mais urgente) |
| **Colunas exibidas** | `Title`, `witem:feature`, `oem:state`, `oem:last-event`, `runtime:sync`, `runtime:last-sync` |
| **Responsável** | Diligence (verificado a cada ciclo Async) |

---

### View 5 — Findings

**Objetivo:** Listar e acompanhar todos os Findings do piloto por severidade.

| Atributo | Configuração |
|---|---|
| **Tipo de View** | Table (tabela) |
| **Filtro** | `witem:type = Finding` AND `witem:iteration = IP-RUNTIME-001` |
| **Agrupamento** | Por `severity` (Alta → Média → Baixa) |
| **Ordenação** | Por data de criação do Issue (mais recente primeiro) |
| **Colunas exibidas** | `Title`, `witem:feature`, `diligence:status`, `runtime:sync`, Labels (`finding:*`, `severity:*`) |
| **Responsável** | Tech Lead (revisado antes de encerrar cada Phase) |

---

### View 6 — Evidence Readiness

**Objetivo:** Verificar quais evidências obrigatórias estão completas antes da Phase 6.

| Atributo | Configuração |
|---|---|
| **Tipo de View** | Board (kanban) |
| **Filtro** | `witem:type = Feature` AND `witem:iteration = IP-RUNTIME-001` |
| **Agrupamento** | Por `diligence:evidence` (colunas) |
| **Colunas** | `Missing` → `Partial` → `Complete` |
| **Campos exibidos em card** | `witem:feature`, `runtime:timeline-state`, `oem:state` |
| **Responsável** | Operador (verificado antes de iniciar Phase 6) |

---

### View 7 — Release Scope

**Objetivo:** Visão executiva de todos os Work Items da Release para fechamento da Milestone.

| Atributo | Configuração |
|---|---|
| **Tipo de View** | Table (tabela) |
| **Filtro** | `witem:release = v0.1.0-runtime-pilot` |
| **Agrupamento** | Por `witem:type` |
| **Ordenação** | Por `witem:feature` dentro de cada grupo |
| **Colunas exibidas** | `Title`, `witem:type`, `witem:feature`, `oem:state`, `diligence:status`, `diligence:evidence`, Status do Issue (Open/Closed) |
| **Responsável** | Tech Lead (revisado antes de fechar a Milestone) |

---

## 6. Iteration

### Definição de IP-RUNTIME-001

A Iteration do piloto não é um objeto nativo do GitHub Projects — é representada pelo valor do campo `witem:iteration = IP-RUNTIME-001` em todos os Issues do piloto.

| Campo | Valor |
|---|---|
| **Identificador** | `IP-RUNTIME-001` |
| **Campo GitHub** | `witem:iteration` (Text) |
| **Valor nos Issues** | `IP-RUNTIME-001` (preenchido manualmente no momento da criação) |

### Associação com Milestone

Todos os Issues da Iteration `IP-RUNTIME-001` devem estar associados à Milestone `v0.1.0-runtime-pilot`. A relação é:

```
Milestone v0.1.0-runtime-pilot  ←→  witem:iteration = IP-RUNTIME-001
```

São equivalentes neste piloto — a Milestone representa a Release; o campo `witem:iteration` representa a Iteration de execução dentro da Release.

### Work Items associados à IP-RUNTIME-001

| Work Item | `witem:type` | `witem:feature` | Milestone |
|---|---|---|---|
| EPIC-RUNTIME-001 | Feature | `EPIC-RUNTIME-001` | `v0.1.0-runtime-pilot` |
| FTR-RUNTIME-001 | Feature | `FTR-RUNTIME-001` | `v0.1.0-runtime-pilot` |
| FTR-RUNTIME-002 | Feature | `FTR-RUNTIME-002` | `v0.1.0-runtime-pilot` |
| FTR-RUNTIME-003 | Feature | `FTR-RUNTIME-003` | `v0.1.0-runtime-pilot` |
| RT-01 | Runtime Task | `RT-01` | `v0.1.0-runtime-pilot` |
| RT-02 | Runtime Task | `RT-02` | `v0.1.0-runtime-pilot` |
| RT-03 | Runtime Task | `RT-03` | `v0.1.0-runtime-pilot` |
| RT-04 | Runtime Task | `RT-04` | `v0.1.0-runtime-pilot` |
| RT-05 | Runtime Task | `RT-05` | `v0.1.0-runtime-pilot` |
| RT-06 | Runtime Task | `RT-06` | `v0.1.0-runtime-pilot` |
| Findings (criados durante execução) | Finding | `FIND-<N>` | `v0.1.0-runtime-pilot` |

---

## 7. Membership

### Quando uma Issue deve entrar no Project

Uma Issue do repositório `payments-api` deve ser adicionada ao projeto `ProdOps — payments-api` quando **todas** as condições abaixo forem verdadeiras:

1. Possui a label `runtime:pilot`
2. Possui `witem:iteration = IP-RUNTIME-001` (campo preenchido após adição)
3. Foi criada no contexto da Iteration IP-RUNTIME-001

**Regra geral:** toda Issue criada para o piloto deve entrar no Project imediatamente após criação.

**Verificação de membership via CLI:**

```bash
gh project item-list $PROJECT_NUMBER --owner <owner> --format json \
  | jq '.items[] | select(.content.number == <issue-number>)'
```

**Adição ao projeto:**

```bash
gh project item-add $PROJECT_NUMBER \
  --owner <owner> \
  --url https://github.com/<owner>/payments-api/issues/<N>
```

### Quando uma Issue deve sair do Project

Issues **não são removidas** do Project durante o piloto — apenas fechadas. A View "Release Scope" usa o estado Open/Closed das Issues para distinguir trabalho concluído de pendente.

Uma Issue pode ser removida do Project somente se:
- Foi criada por engano e não pertence ao piloto (não tem label `runtime:pilot`)
- Foi duplicata de outro Issue e foi fechada como duplicata

### Quem é responsável pela associação

| Situação | Responsável |
|---|---|
| Issues de Features (FTR-RUNTIME-001/002/003) | Operador (no momento da criação — Phase 1) |
| Issues de Runtime Tasks (RT-01..RT-06) | Operador (no momento da criação — Phase 1) |
| Issues de Findings (criados durante a execução) | Quem identificou o Finding — deve adicionar ao Project imediatamente |
| Verificação de membership durante Diligence Sync | Operador da Diligence (Scan verifica membership de todos os Issues com labels canônicas) |
| Reparo de membership ausente | Operador da Diligence via RT-03 (Repair) |

---

## 8. Validation Checklist

Este checklist deve ser executado ao final da Phase 1 do Execution Plan, antes de iniciar a Phase 2 (Runtime Foundation). O Workspace só está pronto quando todos os itens abaixo estão marcados.

### GitHub Project

- [ ] Projeto `ProdOps — payments-api` criado e acessível
- [ ] Número do projeto capturado e disponível para os comandos do RT-03
- [ ] Descrição registrada: *"Canonical Operational Representation do ProdOps Runtime no payments-api..."*

### Milestone

- [ ] Milestone `v0.1.0-runtime-pilot` criada no repositório `payments-api`
- [ ] Milestone acessível via `gh api repos/<owner>/payments-api/milestones`

### Fields

- [ ] `witem:type` criado (Single Select: Feature, Runtime Task, Finding)
- [ ] `witem:repository` criado (Text)
- [ ] `witem:feature` criado (Text)
- [ ] `witem:obc` criado (Text)
- [ ] `witem:release` criado (Text)
- [ ] `witem:iteration` criado (Text)
- [ ] `oem:journey` criado (Single Select: Delivery, Diligence, Assessment)
- [ ] `oem:cycle` criado (Single Select: 8 valores)
- [ ] `oem:phase` criado (Single Select: Started, Completed)
- [ ] `oem:state` criado (Single Select: 10 estados)
- [ ] `oem:rework-count` criado (Number)
- [ ] `oem:blocked-since` criado (Date)
- [ ] `diligence:status` criado (Single Select: 5 valores)
- [ ] `diligence:evidence` criado (Single Select: Missing, Partial, Complete)
- [ ] `runtime:sync` criado (Single Select: 5 valores)
- [ ] `runtime:timeline-state` criado (Single Select: 4 valores)
- [ ] `oem:last-event` criado (Text)
- [ ] `runtime:last-sync` criado (Date)

### Labels

- [ ] 3 labels `journey:*` criadas
- [ ] 7 labels `phase:*` criadas
- [ ] 4 labels `runtime:*` criadas
- [ ] 3 labels `severity:*` criadas
- [ ] 5 labels `finding:*` criadas
- [ ] 3 labels `evidence:*` criadas
- [ ] Total: 25 labels criadas no repositório `payments-api`

### Views

- [ ] View 1 — Iteration Plan (Table) configurada
- [ ] View 2 — Delivery Flow (Board por `oem:state`) configurada
- [ ] View 3 — Diligence Flow (Board por `diligence:status`) configurada
- [ ] View 4 — Runtime Reconciliation (Table filtrada por `runtime:sync != In Sync`) configurada
- [ ] View 5 — Findings (Table filtrada por `witem:type = Finding`) configurada
- [ ] View 6 — Evidence Readiness (Board por `diligence:evidence`) configurada
- [ ] View 7 — Release Scope (Table filtrada por `witem:release`) configurada

### Issues iniciais (Iteration IP-RUNTIME-001)

- [ ] Issue criada para EPIC-RUNTIME-001 com labels e campos corretos
- [ ] Issue criada para FTR-RUNTIME-001 com labels `runtime:pilot`, `journey:delivery`, `phase:bootstrap`
- [ ] Issue criada para FTR-RUNTIME-002 com labels `runtime:pilot`, `journey:delivery`, `runtime:rework`
- [ ] Issue criada para FTR-RUNTIME-003 com labels `runtime:pilot`, `journey:delivery`, `runtime:blocked`, `journey:diligence`
- [ ] Issues criadas para RT-01..RT-06 com labels `runtime:pilot`, `runtime:task`
- [ ] Todos os Issues associados à Milestone `v0.1.0-runtime-pilot`
- [ ] Todos os Issues adicionados ao Project `ProdOps — payments-api`
- [ ] Campos `witem:type`, `witem:feature`, `witem:obc`, `witem:release`, `witem:iteration`, `oem:journey` preenchidos em todos os Issues
- [ ] Campos `oem:state` com valor inicial `BOOTSTRAPPING` nas Features; campo vazio nas Runtime Tasks
- [ ] Campos `diligence:evidence = Missing` e `runtime:timeline-state = Empty` nas Features
- [ ] Campos `runtime:sync = Pending` em todos os Issues

### COR representada corretamente

- [ ] View "Delivery Flow" mostra FTR-RUNTIME-001/002/003 na coluna `BOOTSTRAPPING`
- [ ] View "Diligence Flow" mostra FTR-RUNTIME-001/002/003 na coluna `Pending`
- [ ] View "Runtime Reconciliation" está vazia (nenhum Drift detectado ainda)
- [ ] View "Findings" está vazia (nenhum Finding criado ainda)
- [ ] View "Evidence Readiness" mostra as três Features em `Missing`
- [ ] View "Release Scope" mostra todos os 10+ Issues em estado Open
- [ ] View "Iteration Plan" mostra todos os Work Items organizados por `witem:type`

**O Workspace está pronto para iniciar a Phase 2 (Runtime Foundation) quando todos os itens acima estiverem marcados.**
