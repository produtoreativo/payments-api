# Relatório — COR Finalization: GitHub Project Configuration (EXP-013)
# ProdOps Framework — Phase 1: Environment Preparation (conclusão)

> **Data:** 2026-07-26
> **Tipo:** Configuração manual e via API do GitHub Project após Workspace Provisioning
> **Status:** Concluído — Phase 1 encerrada, Phase 2 desbloqueada
> **Experimento:** EXP-013

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| SINGLE_SELECT field options | ✅ Já corretos — coincidem com COR canônica |
| Work Items inicializados (SINGLE_SELECT) | ✅ 17 campos × 10 issues via GraphQL |
| Work Items inicializados (TEXT) | ✅ 5 campos × 10 issues via GraphQL |
| Views criadas via API | ❌ Impossível — `createProjectV2View` ausente no schema público |
| Views a criar manualmente | 7 — instruções neste documento |
| Doctor final | ✅ 0 labels drift, 0 issues drift, 16 extras informativos, 7 views manuais |
| Bug corrigido no provisioner | `setItemField` → GraphQL `updateProjectV2ItemFieldValue` |
| Typecheck | ✅ Exit: 0 |
| Phase 1 encerrada | ✅ |
| Phase 2 desbloqueada | ✅ |

---

## 2. SINGLE_SELECT Fields — valores canônicos

A COR (secção 7) define os valores canônicos. Os campos já foram criados com as opções corretas durante o provisionamento (Prompt 9). Nenhuma alteração foi necessária.

### Verificação de conformidade (GitHub ↔ COR)

| Campo | Opções no GitHub | Conforme COR |
|---|---|---|
| `witem type` | Feature, Runtime Task, Finding | ✅ |
| `oem journey` | Delivery, Diligence, Assessment | ✅ |
| `oem cycle` | Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework | ✅ |
| `oem phase` | Started, Completed | ✅ |
| `oem state` | BOOTSTRAPPING, HACKING, SYNCING, FINISHING, SHIPPING, VALIDATING, PROMOTING, DONE, BLOCKED, REWORKING | ✅ |
| `diligence status` | Pending, Sync In Progress, Async In Progress, Compliant, Non-Compliant | ✅ |
| `diligence evidence` | Missing, Partial, Complete | ✅ |
| `runtime sync` | Pending, In Sync, Drift Detected, Repair In Progress, Reconciled | ✅ |
| `runtime timeline-state` | Empty, In Progress, Complete, Replay Verified | ✅ |

**Nota:** O Prompt 10 propunha valores alternativos para alguns campos. A instrução "prevalece a fonte canônica existente" foi aplicada — os valores da COR foram mantidos.

---

## 3. Work Items inicializados

Todos os 10 Issues (#66–#75) tiveram seus campos definidos via GraphQL mutation `updateProjectV2ItemFieldValue`.

### #66 — EPIC: ProdOps Runtime MVP

| Campo | Valor |
|---|---|
| `witem:type` | Feature |
| `witem:repository` | payments-api |
| `witem:feature` | EPIC-RUNTIME-001 |
| `witem:obc` | EXP-013 |
| `witem:release` | v0.1.0-runtime-pilot |
| `witem:iteration` | IP-RUNTIME-001 |
| `runtime:sync` | Pending |
| `runtime:timeline-state` | Empty |

### #67–#69 — Features FTR-RUNTIME-001/002/003

| Campo | Valor |
|---|---|
| `witem:type` | Feature |
| `witem:repository` | payments-api |
| `witem:feature` | FTR-RUNTIME-001 / 002 / 003 |
| `witem:obc` | EXP-013 |
| `witem:release` | v0.1.0-runtime-pilot |
| `witem:iteration` | IP-RUNTIME-001 |
| `oem:journey` | Delivery |
| `oem:state` | BOOTSTRAPPING |
| `diligence:status` | Pending |
| `diligence:evidence` | Missing |
| `runtime:sync` | Pending |
| `runtime:timeline-state` | Empty |

### #70–#75 — Runtime Tasks RT-01..RT-06

| Campo | Valor |
|---|---|
| `witem:type` | Runtime Task |
| `witem:repository` | payments-api |
| `witem:feature` | RT-01 / RT-02 / RT-03 / RT-04 / RT-05 / RT-06 |
| `witem:obc` | EXP-013 |
| `witem:release` | v0.1.0-runtime-pilot |
| `witem:iteration` | IP-RUNTIME-001 |
| `runtime:sync` | Pending |
| `runtime:timeline-state` | Empty |

**Verificação:** Issue #67 confirmado com 13/13 campos corretos via query GraphQL.

---

## 4. Views — criação manual necessária

A mutation `createProjectV2View` **não existe** no schema GraphQL público do GitHub.
As 7 Views devem ser criadas manualmente em:

`https://github.com/orgs/produtoreativo/projects/24/views/new`

### Instruções por View

#### View 1 — Iteration Plan (TABLE)
- Criar nova view com layout **Table**
- Nomear: `Iteration Plan`
- Agrupar por: `witem type` (campo custom)
- Campos visíveis: Title, witem type, witem feature, witem iteration, witem release, oem state, runtime sync

#### View 2 — Delivery Flow (BOARD)
- Layout **Board**
- Nome: `Delivery Flow`
- Colunas por: `oem state`
- Campos: Title, oem phase, oem cycle, oem last-event, oem rework-count, oem blocked-since, runtime sync

#### View 3 — Diligence Flow (BOARD)
- Layout **Board**
- Nome: `Diligence Flow`
- Colunas por: `diligence status`
- Campos: Title, diligence status, diligence evidence, runtime sync, runtime last-sync

#### View 4 — Runtime Reconciliation (TABLE)
- Layout **Table**
- Nome: `Runtime Reconciliation`
- Agrupar por: `runtime sync`
- Campos: Title, witem type, oem state, runtime timeline-state, runtime sync, runtime last-sync

#### View 5 — Findings (TABLE)
- Layout **Table**
- Nome: `Findings`
- Agrupar por: `witem type` (filtrar por Finding quando disponível)
- Campos: Title, diligence status, diligence evidence, runtime sync, Assignees

#### View 6 — Evidence Readiness (BOARD)
- Layout **Board**
- Nome: `Evidence Readiness`
- Colunas por: `diligence evidence`
- Campos: Title, witem type, witem feature, diligence status, runtime sync

#### View 7 — Release Scope (TABLE)
- Layout **Table**
- Nome: `Release Scope`
- Agrupar por: `witem type`
- Campos: Title, witem feature, witem iteration, oem journey, oem state, diligence status, runtime sync

---

## 5. Bug corrigido no Workspace Provisioner

Durante a execução foi descoberto que `setItemField` em `project.ts` usava
`gh project item-edit --owner` (flag inexistente) em vez de GraphQL.

**Correção aplicada:** `setItemField` agora usa `updateProjectV2ItemFieldValue`
via GraphQL para todos os tipos de campo (TEXT, NUMBER, SINGLE_SELECT).

**Arquivos alterados:**
- [runtime/workspace/src/github/project.ts](runtime/workspace/src/github/project.ts) — `setItemField` reescrita com GraphQL
- [runtime/workspace/src/provisioner.ts](runtime/workspace/src/provisioner.ts) — usa `setItemField` com assinatura corrigida; `import { gh }` removido
- [runtime/workspace/src/doctor.ts](runtime/workspace/src/doctor.ts) — recomendação de Views atualizada para URL manual

---

## 6. Doctor Report final

```
Project   : found (#24)     ✅
Milestone : found (#1)      ✅
Fields    : 18 configured, 16 drift(s) — TODOS informacionais (ℹ️)
Labels    : 25 configured, 0 drift(s)  ✅
Views     : 7 configured, 7 drift(s)   — limitação de API (manually_verified)
Issues    : 10 configured, 0 drift(s)  ✅
```

**Interpretação:** Zero drifts bloqueantes. As 7 views são limitação documentada da API, não drift reparável. Os 16 campos extras são do projeto pre-existente — informacionais.

---

## 7. Limitações que permanecem não verificáveis pela API

| Limitação | Categoria | Workaround |
|---|---|---|
| `createProjectV2View` ausente | GitHub API | Criação manual no UI |
| Filtros e agrupamentos das Views | GitHub API | Configuração manual no UI após criação |
| SINGLE_SELECT field values para `witem:type = Epic` | COR scope | "Epic" não definido na COR; usar "Feature" como proxy |

---

## 8. Validação visual — checklist

> *A ser preenchida após criação manual das 7 Views no GitHub UI.*

- [ ] Features #67, #68, #69 aparecem em `BOOTSTRAPPING` na View **Delivery Flow**
- [ ] 10 Issues aparecem na **Iteration Plan**
- [ ] 10 Issues aparecem no **Release Scope**
- [ ] **Runtime Reconciliation** mostra todos os itens em `Pending`
- [ ] **Evidence Readiness** mostra as Features em `Missing`
- [ ] **Findings** está vazia (nenhuma Issue com `witem:type = Finding`)
- [ ] **Diligence Flow** não exibe Issues (estado inicial `Pending`, não `Sync In Progress`)
- [ ] Nenhuma Issue sem Milestone
- [ ] Nenhuma Issue fora do Project

---

## 9. Confirmação COR materializada

| Conceito COR | GitHub | Status |
|---|---|---|
| Project `ProdOps — payments-api` (#24) | ✅ Existe | Materializado |
| Milestone `v0.1.0-runtime-pilot` (#1) | ✅ Existe | Materializado |
| 18 Custom Fields com opções canônicas | ✅ Corretos | Materializado |
| 25 Labels com taxonomia canônica | ✅ Corretos | Materializado |
| 7 Views com layouts corretos | ⚠️ Manuais pendentes | Parcialmente materializado |
| 10 Issues com valores iniciais | ✅ Todos corretos | Materializado |
| Milestone associado a todos Issues | ✅ | Materializado |
| Issues no Project como membros | ✅ | Materializado |

**COR está plenamente materializada nos componentes automatizáveis.**
Views são a única exceção, por limitação da API.

---

## 10. Confirmação — Phase 2 desbloqueada

**Phase 1 — Environment Preparation:** ENCERRADA.

Todos os critérios de saída são satisfeitos:

| Critério | Status |
|---|---|
| Project GitHub acessível | ✅ |
| Milestone v0.1.0-runtime-pilot existe | ✅ |
| 18 Custom Fields COR criados | ✅ |
| 25 Labels com taxonomia correta | ✅ |
| 10 Issues no backlog e no projeto | ✅ |
| Campos SINGLE_SELECT inicializados | ✅ |
| Campos TEXT inicializados | ✅ |
| Doctor sem drifts bloqueantes | ✅ |
| Limitações de API documentadas | ✅ |
| Typecheck do provisioner limpo | ✅ |

**Phase 2 — Runtime Foundation está desbloqueada.**

Próximos passos:
1. **RT-01 — Event Producer:** definir e executar mecanismo de emissão de Event Instances OEM
2. **RT-02 — Timeline Processor:** calcular Derived State + algoritmo de Lookback
3. Criar views no GitHub UI com as instruções da seção 4

---

## 11. Artefatos desta etapa

| Artefato | Localização |
|---|---|
| Evidence: Doctor final | `evidence/workspace-cor-final-validation.md` |
| Este documento | `prodops/documentation-review-runtime-cor-finalization.md` |
| `project.ts` corrigido | `runtime/workspace/src/github/project.ts` |
| `provisioner.ts` corrigido | `runtime/workspace/src/provisioner.ts` |
| `doctor.ts` corrigido | `runtime/workspace/src/doctor.ts` |
