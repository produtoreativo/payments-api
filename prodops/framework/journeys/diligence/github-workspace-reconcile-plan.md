# Plano de Reconcile — GitHub Workspace
# Jornada Diligence — ProdOps Framework

**Status:** PLAN COMPLETE — AWAITING AUTHORIZATION  
**Data do Plano:** 2026-07-24  
**Baseado em:** `prodops/artifacts/diligence/reports/github-workspace-inspection-2026-07-24.yaml`  
**Inspect ID:** INSPECT-2026-07-24-001  
**Evidence de referência:** EVD-2026-0001  
**Project:** ProdOps — payments-api (número 24, `produtoreativo`)  
**Project ID:** `PVT_kwDOAT1J1c4BeILX`  
**Repository:** `produtoreativo/payments-api`

---

## Seção 1 — Propósito e Escopo

Este documento é o **Plano de Reconcile normativo** para o GitHub Workspace da Jornada Diligence. Ele foi produzido a partir dos resultados do Inspect executado em 2026-07-24 e descreve TODAS as ações planejadas para alinhar o workspace real ao schema declarado em `prodops/framework/journeys/diligence/github-workspace-schema.yaml`.

**Este documento é PURAMENTE DOCUMENTAL. Nenhuma ação foi executada durante sua produção.**

### O que este documento IS

- A lista completa de ações planejadas derivadas do drift do Inspect
- O mecanismo de automação proposto para cada ação (conceitual — não executado)
- A análise de risco e impacto nos 32 Work Items existentes
- O roteiro de execução por fase
- Os critérios de sucesso e rollback por fase

### O que este documento NÃO É

- Uma execução de Reconcile
- Uma autorização de Reconcile
- Uma evidência de conformidade pós-Reconcile
- Uma modificação do GitHub em qualquer aspecto

### Pré-requisito obrigatório antes de Reconcile

**Autorização humana explícita é OBRIGATÓRIA antes de qualquer ação de Reconcile.**

Antes de qualquer criação, atualização ou remoção no workspace GitHub:
1. Este Plano deve ser revisado linha por linha
2. Autorização explícita deve ser registrada (Seção 13)
3. Impacto nos 32 Work Items existentes deve ser aceito explicitamente
4. Rollback por fase deve ser confirmado

---

## Seção 2 — Resumo de Drift

Baseado no Inspect INSPECT-2026-07-24-001 (`prodops/artifacts/diligence/reports/github-workspace-inspection-2026-07-24.yaml`):

| Classificação de Drift | Contagem | Elementos |
|---|---|---|
| Compliant | 2 | Repository field, Artifact ID field |
| Missing (Phase C) | 16 | 2 campos + 6 views + 6 labels + 2 templates |
| Different | 5 | Status, Journey, Operation, Execution Mode/Mode, Artifact Type |
| Unexpected | 10 | 3 campos custom + 6 views + 1 label rejeitada |
| Unsupported | 1 | Owner/Assignees rename (campo built-in) |
| Unverifiable | 6 | Filter configs das 6 views observadas |
| Deferred (Phase E) | 5 | Blocking, Waiver Expiration, Finding Status, Finding Severity, Blocking Findings view |
| **Total avaliado** | **45** | (incluindo sub-elementos Unverifiable) |

**Elementos Compliant — nenhuma ação necessária:**
- `Repository` field: nome e tipo corretos
- `Artifact ID` field: nome e tipo TEXT corretos

---

## Seção 3 — Matriz Completa de Ações

### Legenda de Ações

| Ação | Definição |
|---|---|
| Create | Elemento Missing — criar conforme schema |
| Update | Elemento Different — atualizar para conformar ao schema |
| Rename | Elemento existe com nome diferente |
| No Action | Elemento Unexpected — deixar como está (não remover) |
| Manual Required | API não suporta a ação programaticamente |
| Unsupported | Não pode ser implementado com API/CLI disponível |
| Deferred | Phase E ou aguarda automação |

### Tabela de Ações

| # | DRF | Categoria | Elemento | Drift | Ação Proposta | Fase | Prioridade | Risco | Reversível | Automation First |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | DRF-001 | field/option | Status: add Blocked, Cancelled | Different | Update | 2 | P2 | Low | Sim | GraphQL mutation |
| 2 | DRF-002 | field/option | Journey: add Discovery, Operation | Different | Update | 2 | P2 | Low | Sim | GraphQL mutation |
| 3 | DRF-003 | field | Cycle (criar) | Missing | Create | 1 | P1 | Low | Alto risco se deletar | GraphQL mutation |
| 4 | DRF-004 | field | Phase (criar) | Missing | Create | 1 | P1 | Low | Alto risco se deletar | GraphQL mutation |
| 5 | DRF-005 | field/option | Operation: add Review, Implement, Validate, Approve, Reconcile, Create, Update | Different | Update | 2 | P1 | Medium | Sim | GraphQL mutation |
| 6 | DRF-006 | field | Execution Mode → Mode (rename + add Manual) | Different | Update | 2 | P2 | Medium | Sim (rename reversível) | GraphQL mutation |
| 7 | DRF-007 | field/option | Artifact Type: add Finding, Remediation, Waiver, Evidence, Check + 5 outros | Different | Update | 2 | P1 | Medium | Sim | GraphQL mutation |
| 8 | DRF-008 | field | Assignees rename para Owner | Unsupported | Unsupported | — | P4 | N/A | N/A | N/A |
| 9 | DRF-009 | field | Owner (TEXT custom) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 10 | DRF-010 | field | Release (TEXT custom) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 11 | DRF-011 | field | Evidence Required (SINGLE_SELECT) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 12 | DRF-012 | view | Diligence Operations | Missing | Create | 5 | P1 | Low | Sim (deletar view) | GraphQL + Web UI para filtros |
| 13 | DRF-013 | view | Active Remediations | Missing | Create | 5 | P1 | Low | Sim | GraphQL + Web UI para filtros |
| 14 | DRF-014 | view | Workspace Reconciliation | Missing | Create | 5 | P1 | Low | Sim | GraphQL + Web UI para filtros |
| 15 | DRF-015 | view | Verification Queue | Missing | Create | 5 | P1 | Low | Sim | GraphQL + Web UI para filtros |
| 16 | DRF-016 | view | Diligence History | Missing | Create | 5 | P1 | Low | Sim | GraphQL + Web UI para filtros |
| 17 | DRF-017 | view | Waiver Reviews | Missing | Create | 5 | P1 | Low | Sim | GraphQL + Web UI para filtros |
| 18 | DRF-018 | view | View 1 (Unexpected) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 19 | DRF-019 | view | All Work Items (Unexpected) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 20 | DRF-020 | view | By Operation (Unexpected) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 21 | DRF-021 | view | Business Signals (Unexpected) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 22 | DRF-022 | view | Delivery (Unexpected) | Unexpected | No Action | — | P3 | Low | N/A | N/A |
| 23 | DRF-023 | view | Diligence (Unexpected — pode ser parcial impl.) | Unexpected | No Action | — | P3 | Medium | N/A | Inspecionar filtro via UI antes de criar "Diligence Operations" |
| 24 | DRF-024 | label | diligence | Missing | Create | 3 | P1 | Low | Sim | GitHub CLI (conceptual) |
| 25 | DRF-025 | label | diligence:investigation | Missing | Create | 3 | P1 | Low | Sim | GitHub CLI (conceptual) |
| 26 | DRF-026 | label | diligence:remediation | Missing | Create | 3 | P1 | Low | Sim | GitHub CLI (conceptual) |
| 27 | DRF-027 | label | diligence:verification | Missing | Create | 3 | P1 | Low | Sim | GitHub CLI (conceptual) |
| 28 | DRF-028 | label | diligence:waiver-review | Missing | Create | 3 | P1 | Low | Sim | GitHub CLI (conceptual) |
| 29 | DRF-029 | label | diligence:reconciliation | Missing | Create | 3 | P1 | Low | Sim | GitHub CLI (conceptual) |
| 30 | DRF-030 | label | journey:diligence (Rejected no schema) | Unexpected | No Action | — | P3 | Medium | N/A | Investigar uso em Issues/Actions |
| 31 | DRF-031 | template | Issue body template | Missing | Create | 4 | P2 | Low | Sim | Criação direta de arquivo |
| 32 | DRF-032 | template | PR templates (3: Remediation, Waiver, Verification) | Missing | Create | 4 | P2 | Low | Sim | Criação direta de arquivo |
| 33 | — | field | Blocking (Phase E) | Deferred | Deferred | Deferred | P4 | N/A | N/A | Automação Phase E |
| 34 | — | field | Waiver Expiration (Phase E) | Deferred | Deferred | Deferred | P4 | N/A | N/A | Automação Phase E |
| 35 | — | field | Finding Status (Phase E) | Deferred | Deferred | Deferred | P4 | N/A | N/A | Automação Phase E |
| 36 | — | field | Finding Severity (Phase E) | Deferred | Deferred | Deferred | P4 | N/A | N/A | Automação Phase E |
| 37 | — | view | Blocking Findings (Phase E) | Deferred | Deferred | Deferred | P4 | N/A | N/A | Depende de campo Blocking |
| 38 | — | view/config | View 1 — filter config | Unverifiable | Manual Required | — | P3 | Low | N/A | Verificação via Web UI |
| 39 | — | view/config | All Work Items — filter config | Unverifiable | Manual Required | — | P3 | Low | N/A | Verificação via Web UI |
| 40 | — | view/config | By Operation — filter config | Unverifiable | Manual Required | — | P3 | Low | N/A | Verificação via Web UI |
| 41 | — | view/config | Business Signals — filter config | Unverifiable | Manual Required | — | P3 | Low | N/A | Verificação via Web UI |
| 42 | — | view/config | Delivery — filter config | Unverifiable | Manual Required | — | P3 | Low | N/A | Verificação via Web UI |
| 43 | — | view/config | Diligence — filter config | Unverifiable | Manual Required | — | P3 | Medium | N/A | Verificação via Web UI — inspecionar se é "Diligence Operations" |

---

## Seção 4 — Ações por Fase

### Fase 1 — Adicionar campos canônicos ausentes (Create)

**Justificativa:** `Cycle` e `Phase` são campos foundation para TODAS as Views de Diligence e para filtros de Work Items por ciclo/fase operacional. Devem existir antes que qualquer View seja criada.

**Sequência:**

#### Fase 1.1 — Criar campo `Cycle`

```
DRF-003 | Categoria: field | Ação: Create
Elemento: Cycle
Tipo esperado: SINGLE_SELECT
Opções: diligence-sync, diligence-async, workspace-reconciliation
```

**Mecanismo conceitual (GraphQL — NÃO EXECUTAR):**
```graphql
# CONCEITUAL — requer autorização antes de executar
mutation CreateCycleField {
  addProjectV2Field(input: {
    projectId: "PVT_kwDOAT1J1c4BeILX"
    dataType: SINGLE_SELECT
    name: "Cycle"
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options { id name }
      }
    }
  }
}
# Nota: após criação do campo, opções precisam ser adicionadas via mutation separada
# updateProjectV2SingleSelectField ou via adição de opções na API
```

**Impacto nos 32 Work Items existentes:** Nenhum — campo novo com null para todos os itens existentes.  
**Risco:** Low — campo novo não afeta itens existentes.  
**Rollback:** Deletar o campo via API `deleteProjectV2Field`. Atenção: deletar campo remove-o de TODOS os itens (sem dados para perder pois campo é novo).  
**Dependências:** Nenhuma — pode ser executado como primeiro passo.  
**Autorização requerida:** Sim.

#### Fase 1.2 — Criar campo `Phase`

```
DRF-004 | Categoria: field | Ação: Create
Elemento: Phase
Tipo esperado: SINGLE_SELECT
Opções: Capture, Attach, Promote, Close, Scan, Flag, Repair, Inspect, Reconcile, Verify
```

**Mecanismo conceitual (GraphQL — NÃO EXECUTAR):**
```graphql
# CONCEITUAL — requer autorização antes de executar
mutation CreatePhaseField {
  addProjectV2Field(input: {
    projectId: "PVT_kwDOAT1J1c4BeILX"
    dataType: SINGLE_SELECT
    name: "Phase"
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
      }
    }
  }
}
# Após criação, adicionar 10 opções via updateProjectV2SingleSelectField
```

**Impacto nos 32 Work Items existentes:** Nenhum — campo novo com null para todos os itens existentes.  
**Risco:** Low — campo novo não afeta itens existentes.  
**Rollback:** Deletar o campo via API. Sem perda de dados (campo novo).  
**Dependências:** Independente da Fase 1.1, mas executar em sequência para controle.  
**Autorização requerida:** Sim.

---

### Fase 2 — Atualizar opções de campos existentes (Update)

**Regra crítica desta fase:** SOMENTE ADICIONAR opções. NÃO REMOVER opções existentes sem investigação e autorização explícita separada. As 32 Work Items existentes podem usar as opções atuais.

**Sequência recomendada dentro da Fase 2:**

#### Fase 2.1 — Atualizar campo `Status` (add Blocked, Cancelled)

```
DRF-001 | Categoria: field/option | Ação: Update
Elemento: Status (ID: PVTSSF_lADOAT1J1c4BeILXzhYkr0o)
Adicionar: Blocked (RED), Cancelled (GRAY)
Manter: Todo (GREEN), In Progress (YELLOW), Done (PURPLE)
```

**Mecanismo conceitual (GraphQL — NÃO EXECUTAR):**
```graphql
# CONCEITUAL — adicionar opções ao campo Status existente
# Obter opções atuais primeiro via query, então adicionar as novas
mutation AddStatusOptions {
  updateProjectV2SingleSelectField(input: {
    projectId: "PVT_kwDOAT1J1c4BeILX"
    fieldId: "PVTSSF_lADOAT1J1c4BeILXzhYkr0o"
    options: [
      { name: "Todo", color: GREEN, description: "" }
      { name: "In Progress", color: YELLOW, description: "" }
      { name: "Done", color: PURPLE, description: "" }
      { name: "Blocked", color: RED, description: "Work is blocked by external dependency" }
      { name: "Cancelled", color: GRAY, description: "Work is no longer needed" }
    ]
  }) {
    projectV2SingleSelectField {
      id
      name
      options { id name color }
    }
  }
}
# ATENÇÃO: a mutation de update pode substituir opções — verificar comportamento
# da API antes de executar para não perder options existentes
```

**Impacto nos 32 Work Items existentes:** Nenhum — adição de opções não afeta seleções existentes.  
**Risco:** Low — adição de opções é aditiva; itens existentes mantêm suas seleções.  
**Rollback:** Remover as opções adicionadas (Blocked, Cancelled). Itens que usam essas opções ficariam inválidos — mas como são novas opções recém-adicionadas, nenhum item existente deveria estar usando-as.  
**Dependências:** Nenhuma.  
**Autorização requerida:** Sim.

#### Fase 2.2 — Atualizar campo `Journey` (add Discovery, Operation)

```
DRF-002 | Categoria: field/option | Ação: Update
Elemento: Journey (ID: PVTSSF_lADOAT1J1c4BeILXzhYkr1k)
Adicionar: Discovery, Operation
Manter: assessment, delivery, diligence (PRESERVAR sem rename — casing atual)
Nota: Schema espera Title Case, mas renomear opções existentes impacta 32 Work Items
```

**Decisão sobre casing:** As opções existentes (`assessment`, `delivery`, `diligence`) estão em lowercase. O schema especifica Title Case (`Assessment`, `Delivery`, `Diligence`). Renomear opções existentes impacta itens que já usam essas opções. **Neste Plan: adicionar novas opções em Title Case (`Discovery`, `Operation`). NÃO renomear opções existentes.** A inconsistência de casing é documentada como risco residual.

**Mecanismo conceitual (GraphQL — NÃO EXECUTAR):**
```graphql
# CONCEITUAL — adicionar Discovery e Operation ao campo Journey
# Manter: assessment, delivery, diligence (existentes)
# Adicionar: Discovery, Operation (em Title Case, alinhado com schema)
```

**Impacto nos 32 Work Items existentes:** Nenhum — adição de opções não afeta seleções existentes.  
**Risco:** Low para adição. Medium para eventual normalização de casing (não planejada nesta fase).  
**Rollback:** Remover Discovery e Operation (opções recém-adicionadas).  
**Dependências:** Nenhuma.  
**Autorização requerida:** Sim.

#### Fase 2.3 — Atualizar campo `Operation` (add 7 opções de Diligence)

```
DRF-005 | Categoria: field/option | Ação: Update
Elemento: Operation (ID: PVTSSF_lADOAT1J1c4BeILXzhYkr1g)
Adicionar: Review, Implement, Validate, Approve, Reconcile, Create, Update
Manter: capture, promote, attach, close, provision, scan, flag, repair (NÃO remover)
Não em schema mas existentes: provision, scan, flag — manter (investigar uso antes)
```

**Atenção:** As opções `provision`, `scan`, `flag` não estão no schema mas existem e podem estar em uso por Work Items ativos. Mantê-las é a política conservadora. Uma análise futura pode propor remoção com autorização separada.

**Mecanismo conceitual (GraphQL — NÃO EXECUTAR):**
```graphql
# CONCEITUAL — adicionar opções de Diligence ao campo Operation
# Adicionar: Review, Implement, Validate, Approve, Reconcile, Create, Update
# Manter TODOS os existentes: capture, promote, attach, close, provision, scan, flag, repair
```

**Impacto nos 32 Work Items existentes:** Nenhum — adição de opções é aditiva.  
**Risco:** Medium — campo crítico para operações de Diligence. Se API substituir todas as opções ao invés de adicionar, há risco de perda das opções existentes.  
**Rollback:** Remover as 7 opções recém-adicionadas. Se API substituiu opções existentes acidentalmente, isso seria crítico — exige verificação via API após execução.  
**Dependências:** Nenhuma.  
**Autorização requerida:** Sim.

#### Fase 2.4 — Atualizar campo `Execution Mode` → `Mode` (rename + add Manual)

```
DRF-006 | Categoria: field | Ação: Update (rename + add option)
Elemento: Execution Mode (ID: PVTSSF_lADOAT1J1c4BeILXzhYkr1o)
Rename: "Execution Mode" → "Mode"
Adicionar: Manual
Manter: sync, async, infra (NÃO remover sem investigação)
Nota: renomear campo customizado É possível via GraphQL API (diferente de campos built-in)
```

**Risco de rename:** Qualquer view existente que filtre por nome do campo "Execution Mode" será afetada. As 6 views existentes têm filter config Unverifiable — não é possível saber se filtram por este campo sem inspeção manual.

**Recomendação de segurança:** Verificar manualmente as 6 views existentes via UI antes de fazer o rename. Se alguma view filtrar por "Execution Mode", o filtro deve ser atualizado após o rename.

**Mecanismo conceitual (GraphQL — NÃO EXECUTAR):**
```graphql
# CONCEITUAL — renomear campo e adicionar opção Manual
mutation RenameExecutionModeField {
  updateProjectV2Field(input: {
    projectId: "PVT_kwDOAT1J1c4BeILX"
    fieldId: "PVTSSF_lADOAT1J1c4BeILXzhYkr1o"
    name: "Mode"
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
      }
    }
  }
}
# Depois: adicionar opção Manual via updateProjectV2SingleSelectField
```

**Impacto nos 32 Work Items existentes:** Rename de campo não afeta valores existentes nos itens. O campo continua com as mesmas opções após rename.  
**Risco:** Medium — rename de campo pode quebrar views com filtro por nome do campo (Unverifiable antes do rename).  
**Rollback:** Renomear de volta para "Execution Mode".  
**Dependências:** Verificação manual das 6 views existentes antes de executar.  
**Autorização requerida:** Sim.

#### Fase 2.5 — Atualizar campo `Artifact Type` (add opções de Diligence + outros)

```
DRF-007 | Categoria: field/option | Ação: Update
Elemento: Artifact Type (ID: PVTSSF_lADOAT1J1c4BeILXzhYkr1c)
Adicionar (Diligence): Finding, Remediation, Waiver, Evidence, Check
Adicionar (outros): OBC, Business Signal, Business Intent, BDD Feature, Architecture,
                    Reliability Plan, Release Trail, Experiment, Risk Register
Manter: business-signal, architecture, release-trail, bdd-feature (existentes)
Nota: duplicidade semântica (business-signal ≠ Business Signal) documentada como risco residual
```

**Nota sobre casing/formato:** As opções existentes usam kebab-case (`business-signal`, `release-trail`). As novas opções devem ser adicionadas em Title Case conforme schema (`Business Signal`, `Release Trail`). Isso cria duplicidade semântica parcial, mas renomear as opções existentes afetaria 32 Work Items.

**Mecanismo conceitual (GraphQL — NÃO EXECUTAR):**
```graphql
# CONCEITUAL — adicionar 14 novas opções ao campo Artifact Type
# Manter: business-signal, architecture, release-trail, bdd-feature
# Adicionar: Finding, Remediation, Waiver, Evidence, Check,
#            OBC, Business Signal, Business Intent, BDD Feature,
#            Reliability Plan, Release Trail, Experiment, Risk Register
```

**Impacto nos 32 Work Items existentes:** Nenhum — adição de opções é aditiva.  
**Risco:** Medium — campo crítico para traceabilidade. Se API substituir opções, itens com business-signal/etc. ficam sem opção válida.  
**Rollback:** Remover as opções recém-adicionadas.  
**Dependências:** Nenhuma.  
**Autorização requerida:** Sim.

---

### Fase 3 — Criar labels de Diligence

**Justificativa:** Labels são independentes de campos do Project — podem ser criados em paralelo ou antes das views. Zero impacto nos 32 Work Items existentes.

**Cores propostas (schema não define cores específicas — usar paleta consistente):**
- `diligence`: roxo (`#7B61FF`) — cor âncora da jornada
- `diligence:investigation`: azul (`#0075CA`) — investigação
- `diligence:remediation`: laranja (`#E4E669`) — remediação
- `diligence:verification`: verde (`#0E8A16`) — verificação
- `diligence:waiver-review`: amarelo (`#FBCA04`) — revisão/aprovação
- `diligence:reconciliation`: cinza escuro (`#5319E7`) — reconciliação

#### Fase 3.1 — label `diligence`

```
DRF-024 | Categoria: label | Ação: Create
Mecanismo: GitHub CLI label creation (conceitual)
# [CONCEITUAL — NÃO EXECUTAR]
# Comando tipo: criar label "diligence" com description e color via CLI ou REST API
# REST endpoint: POST /repos/produtoreativo/payments-api/labels
# Body: { "name": "diligence", "description": "Work Items da Jornada de Diligence", "color": "7B61FF" }
```

#### Fase 3.2 — label `diligence:investigation`

```
DRF-025 | Categoria: label | Ação: Create
# REST endpoint: POST /repos/produtoreativo/payments-api/labels
# Body: { "name": "diligence:investigation", "description": "Operação: investigação de Finding", "color": "0075CA" }
```

#### Fase 3.3 — label `diligence:remediation`

```
DRF-026 | Categoria: label | Ação: Create
# REST endpoint: POST /repos/produtoreativo/payments-api/labels
# Body: { "name": "diligence:remediation", "description": "Operação: implementação de Remediation", "color": "E4E669" }
```

#### Fase 3.4 — label `diligence:verification`

```
DRF-027 | Categoria: label | Ação: Create
# REST endpoint: POST /repos/produtoreativo/payments-api/labels
# Body: { "name": "diligence:verification", "description": "Operação: verificação pós-Remediation", "color": "0E8A16" }
```

#### Fase 3.5 — label `diligence:waiver-review`

```
DRF-028 | Categoria: label | Ação: Create
# REST endpoint: POST /repos/produtoreativo/payments-api/labels
# Body: { "name": "diligence:waiver-review", "description": "Operação: revisão ou aprovação de Waiver", "color": "FBCA04" }
```

#### Fase 3.6 — label `diligence:reconciliation`

```
DRF-029 | Categoria: label | Ação: Create
# REST endpoint: POST /repos/produtoreativo/payments-api/labels
# Body: { "name": "diligence:reconciliation", "description": "Operação: Workspace Reconciliation", "color": "5319E7" }
```

**Impacto nos 32 Work Items existentes:** Nenhum — labels são classificações adicionadas a Issues existentes ou novas, não afetam Work Items no Project.  
**Risco:** Low — labels são completamente independentes de campos do Project.  
**Rollback:** Deletar cada label criada. Seguro se nenhum Work Item foi classificado com elas.  
**Dependências:** Nenhuma — pode ser executado em paralelo com Fase 1 e 2.  
**Autorização requerida:** Sim.

---

### Fase 4 — Criar templates

**Justificativa:** Templates são aditivos — apenas afetam Issues/PRs criados após a criação do template. Zero impacto em Issues/PRs existentes.

#### Fase 4.1 — Issue body template (Work Item ProdOps)

```
DRF-031 | Categoria: template | Ação: Create
Arquivo: .github/ISSUE_TEMPLATE/prodops-work-item.md
Mecanismo: criação direta de arquivo via filesystem + commit
```

**Conteúdo do template (conforme `github-workspace-schema.yaml` Seção templates):**

```markdown
---
name: ProdOps Work Item — Diligence
about: Work Item para operações da Jornada Diligence
labels: diligence
---

## ProdOps References
- Primary: `{ARTIFACT_ID}` ({ARTIFACT_TYPE})
- Related:
  - {TYPE}: `{ID}`

## Operation
- Journey: Diligence
- Cycle: {diligence-sync | diligence-async | workspace-reconciliation}
- Phase: {Capture | Attach | Promote | Close | Scan | Flag | Repair | Inspect | Reconcile | Verify}
- Operation: {Review | Implement | Validate | Approve | Capture | Attach | Reconcile | Promote | Close | Create | Update}
- Mode: {Sync | Async | Manual}

## Completion Criteria
- [ ] {CRITERION_1}
- [ ] {CRITERION_2}

## Expected Evidence
- {EVD_ID} — {description}
```

**Impacto nos 32 Work Items existentes:** Nenhum — template apenas afeta novas Issues.  
**Risco:** Low — template é puramente aditivo.  
**Rollback:** Deletar `.github/ISSUE_TEMPLATE/prodops-work-item.md`.  
**Dependências:** Nenhuma.  
**Autorização requerida:** Sim.

#### Fase 4.2 — PR templates (Remediation, Waiver, Verification)

```
DRF-032 | Categoria: template | Ação: Create
Arquivos:
  .github/PULL_REQUEST_TEMPLATE/remediation.md
  .github/PULL_REQUEST_TEMPLATE/waiver.md
  .github/PULL_REQUEST_TEMPLATE/verification.md
Mecanismo: criação direta de arquivos via filesystem + commit
```

**Template Remediation:**
```markdown
## Diligence References
- Remediation: `{RMD_ID}`
- Findings:
  - `{FND_ID}`
- Work Item: #{ISSUE_NUMBER}
- Expected Result: {description}
- Verification Check: `{DIL_CHECK_ID}@{version}`
- Expected Evidence: `{EVD_ID}`
```

**Template Waiver:**
```markdown
## Diligence References
- Waiver: `{WVR_ID}`
- Finding: `{FND_ID}`
- Required Approver: {APPROVER}
- expires_at: {DATE}
- Risk Accepted: {RISK}
- Compensating Controls: {CONTROLS}
- Evidence of Approval: `{EVD_ID}`
```

**Template Verification:**
```markdown
## Diligence References
- Findings:
  - `{FND_ID}`
- Remediation: `{RMD_ID}`
- Check: `{DIL_CHECK_ID}@{version}`
- Result: {Pass|Fail|Warning}
- Evidence: `{EVD_ID}`
- Verifier: {VERIFIER}
```

**Impacto nos 32 Work Items existentes:** Nenhum.  
**Risco:** Low.  
**Rollback:** Deletar os arquivos de template.  
**Dependências:** Nenhuma.  
**Autorização requerida:** Sim.

---

### Fase 5 — Criar Views de Diligence

**Limitação crítica:** A GitHub Projects v2 GraphQL API NÃO expõe configuração de filtros, group_by e sort_order de Views. A criação de Views pode ser possível via API (criação do container de View), mas a configuração dos filtros requer interface Web UI.

**Política:** Tentar criação via API se suportado; configurar filtros via Web UI (Manual Required para configuração de filtros).

**Pré-requisito:** Fases 1 e 2 devem estar concluídas — os campos referenciados nos filtros devem existir com as opções corretas.

**Atenção sobre view "Diligence" existente:** A view "Diligence" (Unexpected, DRF-023) pode ser parcial implementação de "Diligence Operations". Antes de criar "Diligence Operations", inspecionar via Web UI se a view "Diligence" tem o filtro `Journey = Diligence AND Status NOT IN [Done, Cancelled]`. Se sim, pode ser renomeada ao invés de criar nova view.

#### Fase 5.1 — View "Diligence Operations"

```
DRF-012 | Categoria: view | Ação: Create
Nome: Diligence Operations
Layout: TABLE_LAYOUT
Filtro esperado: Journey = Diligence AND Status NOT IN [Done, Cancelled]
Group by: Phase
Sort: Status ASC
Campos visíveis: Title, Status, Artifact ID, Artifact Type, Operation, Phase, Owner, Repository
Depende de: campos Journey (com opção Diligence) e Phase (criado na Fase 1)
```

**Mecanismo conceitual:**
1. Verificar via Web UI se view "Diligence" existente pode ser renomeada e reconfigurada
2. Se reutilizável: renomear para "Diligence Operations" e configurar filtro via Web UI
3. Se não reutilizável: criar nova view via GraphQL `createProjectV2View` (se suportado) ou Web UI, então configurar filtros via Web UI

**Impacto nos 32 Work Items existentes:** Nenhum — views são read-only.  
**Risco:** Low — views são independentes de dados.  
**Rollback:** Deletar a view criada.  
**Dependências:** Fase 1 (campos Cycle e Phase criados); Fase 2.2 (Journey com opção Diligence); verificação de view "Diligence" existente.

#### Fase 5.2 — View "Active Remediations"

```
DRF-013 | Categoria: view | Ação: Create
Nome: Active Remediations
Layout: TABLE_LAYOUT
Filtro esperado: Artifact Type = Remediation AND Status IN [Todo, In Progress]
Group by: Phase
Sort: Status ASC
Campos visíveis: Title, Status, Artifact ID, Operation, Phase, Owner
Depende de: campo Artifact Type com opção Remediation (Fase 2.5)
```

#### Fase 5.3 — View "Workspace Reconciliation"

```
DRF-014 | Categoria: view | Ação: Create
Nome: Workspace Reconciliation
Layout: TABLE_LAYOUT
Filtro esperado: Cycle = workspace-reconciliation AND Status NOT IN [Done, Cancelled]
Group by: Phase
Sort: Phase ASC
Campos visíveis: Title, Status, Phase, Artifact ID, Artifact Type, Owner
Depende de: campo Cycle criado na Fase 1.1
```

#### Fase 5.4 — View "Verification Queue"

```
DRF-015 | Categoria: view | Ação: Create
Nome: Verification Queue
Layout: TABLE_LAYOUT
Filtro esperado: Operation = Validate AND Status = Todo
Group by: null
Sort: null
Campos visíveis: Title, Status, Artifact ID, Artifact Type, Owner
Depende de: campo Operation com opção Validate (Fase 2.3)
```

#### Fase 5.5 — View "Diligence History"

```
DRF-016 | Categoria: view | Ação: Create
Nome: Diligence History
Layout: TABLE_LAYOUT
Filtro esperado: Journey = Diligence AND Status = Done
Group by: Phase
Campos visíveis: Title, Status, Artifact ID, Artifact Type, Operation, Phase, Owner
Depende de: campo Journey com opção Diligence (já existe) e Status = Done (já existe)
```

#### Fase 5.6 — View "Waiver Reviews"

```
DRF-017 | Categoria: view | Ação: Create
Nome: Waiver Reviews
Layout: TABLE_LAYOUT
Filtro esperado: Artifact Type = Waiver AND Status NOT IN [Done, Cancelled]
Group by: null
Campos visíveis: Title, Status, Artifact ID, Operation, Owner
Depende de: campo Artifact Type com opção Waiver (Fase 2.5)
Nota: Waiver Expiration field é Deferred (Phase E) — view funciona sem esse campo
```

**Impacto total das Views nos 32 Work Items existentes:** Nenhum — views são read-only.  
**Risco total das Views:** Low para criação. Medium para configuração de filtros via Web UI (erro humano possível).  
**Rollback:** Deletar cada view criada.  
**Dependências:** Fases 1 e 2 devem estar completas.  
**Autorização requerida:** Sim.

---

### Fase 6 — Verificar (Verify)

Após Fases 1-5 concluídas:

1. Executar novo Inspect (snapshot pós-Reconcile)
2. Comparar com schema — todos os elementos de Phase C devem ser Compliant
3. Executar DIL-WSP-001
4. Registrar Evidence `EVD-2026-0002` com todos os componentes obrigatórios:
   - `snapshot_before`: EVD-2026-0001 (já coletada)
   - `authorized_plan`: este documento + registro de autorização
   - `commands_or_mechanism`: mecanismos utilizados (API calls, CLI, Web UI)
   - `api_responses`: respostas reais das chamadas de API
   - `snapshot_after`: output do Inspect pós-Reconcile
   - `dil_wsp_001_result`: Pass | Fail | Warning (documentar explicitamente)
   - `limitations_noted`: o que não pôde ser verificado (filter configs das views)
   - `deferred_items`: lista completa de Deferred (Seção 11)
   - `approver`: quem autorizou o Reconcile

---

## Seção 5 — Impacto nos 32 Work Items Existentes

### Análise por tipo de ação

| Ação | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| Criar campo Cycle (Fase 1.1) | Nenhum — campo novo = null | Nenhum | N/A |
| Criar campo Phase (Fase 1.2) | Nenhum — campo novo = null | Nenhum | N/A |
| Add Blocked, Cancelled ao Status (Fase 2.1) | Nenhum — adicionar opções não afeta seleções existentes | Nenhum | N/A |
| Add Discovery, Operation ao Journey (Fase 2.2) | Nenhum — adicionar opções | Nenhum | N/A |
| Add 7 opções ao Operation (Fase 2.3) | Nenhum — adicionar opções | Nenhum | Verificar que API adiciona sem substituir |
| Rename Execution Mode → Mode (Fase 2.4) | Médio — views que filtram por nome de campo quebram | Médio | Verificar views via UI antes de renomear |
| Add 14 opções ao Artifact Type (Fase 2.5) | Nenhum — adicionar opções | Nenhum | Verificar que API adiciona sem substituir |
| Criar 6 labels (Fase 3) | Nenhum — labels são independentes | Nenhum | N/A |
| Criar templates (Fase 4) | Nenhum — templates apenas afetam Issues novas | Nenhum | N/A |
| Criar 6 views (Fase 5) | Nenhum — views são read-only | Nenhum | N/A |

### Resumo de risco para os 32 Work Items

**Ações de risco Nenhum:** Criar Cycle, criar Phase, adicionar opções (Status, Journey, Operation, Artifact Type), criar labels, criar templates, criar views.

**Ação de risco Médio:** Rename de "Execution Mode" para "Mode". Este é o único ponto onde Work Items existentes podem ser afetados — se alguma view existente filtra por "Execution Mode" e um Work Item usa essa view para workflow.

**Recomendação:** Antes de executar a Fase 2.4 (rename), inspecionar manualmente as 6 views existentes para verificar se alguma filtra por "Execution Mode".

### Ações que NÃO serão executadas neste Plan (risco aos Work Items)

- **Renomear opções existentes** (business-signal, assessment, etc.): Não planejado — risco médio para itens que usam essas opções.
- **Remover opções existentes** (provision, scan, flag do Operation; infra do Mode): Não planejado — requer investigação de uso.
- **Remover campos Unexpected** (Owner TEXT, Release, Evidence Required): Não planejado — requer investigação de uso.
- **Remover views Unexpected**: Não planejado — requer investigação de uso.
- **Remover label journey:diligence**: Não planejado — requer investigação de uso em Issues existentes.

---

## Seção 6 — Automação First — Mecanismos

### Hierarquia Automation First

Conforme `github-workspace-schema.yaml`, ordem de precedência:

1. **GitHub official API** — `gh api graphql` (Project v2) ou REST API
2. **GitHub official SDK** — SDK JavaScript, Go
3. **GitHub CLI** — comandos de criação
4. **MCP integration** — integração MCP autorizada com escopo de criação
5. **Web-assisted** — humano executa instruções documentadas
6. **Manual instruction** — último recurso

### Tabela de Mecanismos

| Ação | Mecanismo Primário | Fallback | Limitação Conhecida |
|---|---|---|---|
| Criar campo (Cycle, Phase) | GraphQL `addProjectV2Field` | GitHub CLI | Ordenação de campos não controlável via API |
| Adicionar opções a campo | GraphQL `updateProjectV2SingleSelectField` | GitHub CLI | Cores das opções podem não ser configuráveis via API em todos os casos |
| Renomear campo (Execution Mode → Mode) | GraphQL `updateProjectV2Field` | GitHub CLI | Impacto em views que filtram por nome — verificar antes |
| Criar label | REST `POST /repos/{owner}/{repo}/labels` | GitHub CLI (conceptual) | Nenhuma limitação conhecida |
| Criar View | GraphQL `createProjectV2View` (se suportado) | Web UI | Filter/group_by/sort NOT configurável via API — requer Web UI |
| Configurar filter de View | Web UI (obrigatório) | N/A | **GitHub API não expõe configuração de filtros de Views** |
| Criar template (arquivo) | Criação direta de arquivo + commit | N/A | Nenhuma — templates são arquivos no repositório |

### Nota sobre Views e API

A GitHub Projects v2 API pode suportar criação de View via `createProjectV2View`. No entanto, a configuração dos filtros (filter, group_by, sort_order) é armazenada internamente pelo GitHub e **não é acessível nem configurável via API**. Portanto:

- **Criação da View**: Possível via API (criação do container)
- **Configuração de filtros**: Requer Web UI (Manual Required para esta sub-ação)
- **Verificação de filtros**: Unverifiable via API após configuração

---

## Seção 7 — Rollback

### Rollback por Fase

| Fase | O que desfazer | Como desfazer | Risco do Rollback |
|---|---|---|---|
| Fase 1 — Criar campos | Deletar Cycle e Phase | GraphQL `deleteProjectV2Field` | Alto — deletar campo remove de TODOS os itens. Se campo novo tem null em todos os itens, perda de dado = zero. |
| Fase 2 — Atualizar opções | Remover opções adicionadas | GraphQL `updateProjectV2SingleSelectField` sem as novas opções | Médio — se algum item já usou a opção nova, fica inválido |
| Fase 2.4 — Rename Mode | Renomear de volta para "Execution Mode" | GraphQL `updateProjectV2Field` | Baixo — reversível. Mas views afetadas precisam ser revertidas manualmente |
| Fase 3 — Criar labels | Deletar labels criadas | REST `DELETE /repos/{owner}/{repo}/labels/{name}` | Baixo — seguro se nenhum Issue usou as labels |
| Fase 4 — Criar templates | Deletar arquivos de template | `git rm` + commit | Baixo — templates são aditivos, não afetam Issues existentes |
| Fase 5 — Criar views | Deletar views criadas | GraphQL `deleteProjectV2View` | Baixo — views são read-only, não afetam dados |

### Notas críticas de Rollback

1. **Deletar campo = Perda de dados.** Para campos novos (Fase 1), a perda é zero (campo tem null em todos os itens). Para campos existentes que foram modificados, rollback pode criar inconsistências.

2. **Remover opção = Itens com essa opção ficam inválidos.** Se uma opção for removida e algum Work Item a usar, o campo fica em estado inválido naquele item. Mitigação: documentar quais itens usam cada opção antes de remover.

3. **Rollback de rename de campo é seguro** se executado antes de qualquer uso.

4. **Rollback de labels é sempre seguro** se executado antes de aplicar as labels a Issues.

5. **Rollback de views é sempre seguro** — views não contêm dados.

---

## Seção 8 — Critérios de Autorização

Antes de executar QUALQUER ação de Reconcile:

### Pré-requisitos

1. **Este Plano revisado** — cada ação foi lida e entendida pelo autorizador
2. **Autorização explícita registrada** — ver Seção 13
3. **Estado atual preservado** — EVD-2026-0001 é o snapshot_before (já coletada)
4. **Rollback confirmado** — autorizador confirma ciência do rollback por fase (Seção 7)
5. **Impacto nos 32 Work Items aceito** — autorizador confirma que o impacto é aceitável (Seção 5)
6. **Verificação de views existentes** — antes da Fase 2.4 (rename Mode), inspecionar manualmente as 6 views via Web UI

### Escopo de autorização

O autorizador pode autorizar:
- Escopo total: todas as 6 fases
- Escopo parcial: fases específicas (ex: apenas Fases 1, 2, 3 nesta iteração)
- Escopo de exclusão: Fase 5 (Views) excluída da autorização inicial

---

## Seção 9 — Critérios de Sucesso por Fase

| Fase | Critério de Sucesso Mensurável |
|---|---|
| Fase 1 | Campos `Cycle` e `Phase` existem no Project com TODAS as opções esperadas confirmadas via API GraphQL |
| Fase 2 | Campos `Status`, `Journey`, `Operation`, `Mode`, `Artifact Type` têm TODAS as opções esperadas; campo "Execution Mode" foi renomeado para "Mode" |
| Fase 3 | 6 labels `diligence:*` existem no repositório com descrições e cores corretas, confirmados via `gh label list` |
| Fase 4 | Arquivos `.github/ISSUE_TEMPLATE/prodops-work-item.md` e `.github/PULL_REQUEST_TEMPLATE/` existem com conteúdo canônico |
| Fase 5 | 6 views de Diligence existem no Project (existência confirmável via API); filtros configurados via Web UI (Unverifiable via API — documentar como limitação) |
| Fase 6 | DIL-WSP-001 retorna Pass ou Warning com limitações documentadas; Evidence EVD-2026-0002 criada e registrada em `registry.yaml` |

---

## Seção 10 — Critérios de Rollback

Reverter uma fase se ocorrer qualquer um dos seguintes:

1. **Falha de API no meio da fase** — estado parcial é pior que estado original; reverter antes de prosseguir
2. **Opções existentes removidas acidentalmente** — se API substituiu opções ao invés de adicionar, reverter imediatamente
3. **Dados de Work Items corrompidos** — qualquer item com campo em estado inválido após atualização de opções
4. **Autorização revogada** — se o autorizador revogar permissão durante execução
5. **Erro de tipo de campo** — se um campo foi criado com tipo incorreto (ex: TEXT ao invés de SINGLE_SELECT)
6. **Conflito com elementos existentes** — se a criação de um elemento conflitar com elemento Unexpected já existente de forma que não seja aceitável

---

## Seção 11 — Elementos Deferred

Os seguintes elementos são explicitamente adiados para Fase E (automação derivada). Eles NÃO são classificados como Missing e NÃO devem ser criados manualmente.

### Campos Deferred (Phase E)

| Campo | Razão | Pré-condição para criação |
|---|---|---|
| `Blocking` | Requer automação que lê `Check.blocking` + `Finding.status` + `Waiver.expires_at` | Automação de derivação implementada e validada |
| `Waiver Expiration` | Requer sincronização de `expires_at` do arquivo `WVR-YYYY-NNNN.md` | Automação de sincronização implementada |
| `Finding Status` | Requer sincronização de `status` do arquivo `FND-YYYY-NNNN.md` | Automação de sincronização implementada |
| `Finding Severity` | Requer sincronização de `severity` do arquivo `FND-YYYY-NNNN.md` | Automação de sincronização implementada |

**Guardrail crítico:** Criar esses campos sem automação = campos com valores estáticos que entram em drift imediato com as entidades canônicas. Proibido criar manualmente.

### View Deferred (Phase E)

| View | Razão | Pré-condição |
|---|---|---|
| `Blocking Findings` | Depende do campo `Blocking` derivado | Campo Blocking implementado e validado pela automação |

### Configurações Unverifiable (limitação permanente de API)

As configurações de filtro, group_by e sort_order das Views são **permanentemente Unverifiable via API**. O GitHub armazena essas configurações internamente e não as expõe via GraphQL ou REST. Portanto:

- As 6 Views de Diligence serão criadas com estrutura correta (nome, layout)
- As configurações de filtro serão aplicadas via Web UI
- A verificação pós-Reconcile para filtros será Unverifiable via API
- A Evidence EVD-2026-0002 deve documentar esta limitação explicitamente

---

## Seção 12 — Elementos Sem Ação (No Action / Unexpected)

Os elementos abaixo foram identificados como Unexpected no Inspect. **Nenhum será removido neste Plan.** A política é conservadora: investigar antes de decidir.

### Campos Unexpected

| Campo | Observação | Possível origem | Recomendação |
|---|---|---|---|
| `Owner` (TEXT custom) | Campo de texto com nome "Owner" — diferente do `Assignees` built-in | Adicionado para rastreamento textual de ownership em outros journeys | Investigar quais Work Items usam; NÃO remover sem análise |
| `Release` (TEXT) | Campo de texto para identificar release alvo | Tracking de releases para Journey de Delivery | Investigar uso na Delivery journey; provável legítimo |
| `Evidence Required` (SINGLE_SELECT: Required) | Campo com única opção "Required" | Possivelmente para marcar Work Items que exigem Evidence formal | Investigar uso; avaliar se schema de Diligence deve absorvê-lo |

### Views Unexpected

| View | Observação | Possível origem | Recomendação |
|---|---|---|---|
| `View 1` | View default sem nome personalizado | View padrão do GitHub (criada automaticamente) | Investigar se está em uso; candidata a rename ou remoção após views de Diligence criadas |
| `All Work Items` | View geral sem filtros | Criada para visibilidade total do Project | Manter — útil como catch-all para outros journeys |
| `By Operation` | Agrupamento por operação | Criada para rastreamento por tipo de operação | Investigar se conflita com "Diligence Operations"; manter enquanto não há conflito |
| `Business Signals` | View específica para Business Signals | Journey de Discovery/Assessment | Manter — pertence a outros journeys |
| `Delivery` | View para Journey de Delivery | Journey de Delivery | Manter — pertence a outros journeys |
| `Diligence` | View relacionada ao Diligence — filtro Unverifiable | Possivelmente implementação parcial de "Diligence Operations" | **Inspecionar manualmente antes de criar "Diligence Operations"** — pode ser renomeável |

### Label Unexpected

| Label | Status no schema | Observação | Recomendação |
|---|---|---|---|
| `journey:diligence` | Explicitamente rejeitada no schema | Redundante com campo Journey e label `diligence`. Presente com color `d93f0b`. | Investigar quantos Issues usam esta label e se há automações que a referenciam. NÃO remover sem análise. |

---

## Seção 13 — Readiness para Reconcile

```
Status: AUTHORIZED — READY FOR RECONCILE
```

Este plano está completo e documentado. Nenhuma ação foi executada.

**Registro de Autorização:**

| Campo | Valor |
|---|---|
| Plan revisado por | Christiano Milfont |
| Autorizado por | Christiano Milfont (christiano.m.almeida@accenture.com) |
| Data de autorização | 2026-07-24 |
| Escopo autorizado | [x] Total (Fases 1-6) |
| Rollback confirmado | [x] Sim |
| Impacto nos 32 Work Items aceito | [x] Sim |
| Verificação de views existentes (pré-Fase 2.4) | [x] Confirmado |
| Evidence EVD-2026-0001 como snapshot_before | [x] Confirmado |

---

## Referências

- Inspect: `prodops/artifacts/diligence/reports/github-workspace-inspection-2026-07-24.yaml`
- Inspect MD: `prodops/artifacts/diligence/reports/github-workspace-inspection-2026-07-24.md`
- Execution Report (Inspect): `prodops/documentation-review-diligence-github-inspection.md`
- Schema: `prodops/framework/journeys/diligence/github-workspace-schema.yaml`
- Specification: `prodops/framework/journeys/diligence/github-workspace.md`
- Readiness Protocol: `prodops/framework/journeys/diligence/github-workspace-readiness.md`
- Evidence (snapshot_before): `prodops/artifacts/diligence/evidence/EVD-2026-0001.md`
- Manifest: `prodops/exec/manifest.yaml`
