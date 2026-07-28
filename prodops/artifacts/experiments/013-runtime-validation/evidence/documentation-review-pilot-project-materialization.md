# Documentation Review — GitHub Project Materialization (Piloto Operacional Fase 2)

**Data:** 2026-07-26
**Revisor:** Claude (automatizado)
**Escopo:** Prompt 03 — Materialização do GitHub Project para IP-001
**Antecedente:** [documentation-review-pilot-release-planning.md](./documentation-review-pilot-release-planning.md)

---

## Sumário

GitHub Project #24 (`ProdOps — payments-api`) materializado para o Piloto Operacional Fase 2. Foram criados 6 Custom Fields novos, 6 Issues (FTR-001 a FTR-006) e todos foram adicionados ao project com campos preenchidos.

As Views não puderam ser criadas via API GraphQL (mutação `createProjectV2View` não existe na API pública do GitHub). As views necessárias estão documentadas neste relatório com instruções para criação manual via UI.

Nenhum arquivo de Runtime, SDK, OEM, Timeline ou catálogo foi alterado.

---

## 1. O que foi materializado via API

### Custom Fields criados

| Campo | Tipo | ID | Opções / Formato |
|---|---|---|---|
| **State** | SINGLE_SELECT | `PVTSSF_lADOAT1J1c4BeILXzhY7Lmw` | BOOTSTRAPPING · HACKING · SYNCING · FINISHING · SHIPPING · VALIDATING · PROMOTING · DONE · BLOCKED · REWORKING |
| **Rework Count** | NUMBER | `PVTF_lADOAT1J1c4BeILXzhY7Log` | Inteiro ≥ 0 |
| **Blocked Since** | DATE | `PVTF_lADOAT1J1c4BeILXzhY7Lok` | ISO-8601 |
| **Last Event Type** | TEXT | `PVTF_lADOAT1J1c4BeILXzhY7Lr8` | Ex.: `Delivery.Hack.Completed` |
| **Computed At** | DATE | `PVTF_lADOAT1J1c4BeILXzhY7LsA` | ISO-8601 |
| **Has Corrections** | SINGLE_SELECT | `PVTSSF_lADOAT1J1c4BeILXzhY7LsE` | false · true |

**Campos existentes reutilizados (não criados):**

| Campo | ID | Uso no piloto |
|---|---|---|
| `oem journey` | `PVTSSF_lADOAT1J1c4BeILXzhY3H4c` | Delivery (para todas as 6 Features) |
| `Phase` | `PVTSSF_lADOAT1J1c4BeILXzhYxZeI` | Fase atual da Feature |
| `witem feature` | `PVTF_lADOAT1J1c4BeILXzhY3H1s` | PI-PILOT-001 a PI-PILOT-006 |
| `witem release` | `PVTF_lADOAT1J1c4BeILXzhY3H2s` | REL-PILOT-v1 |
| `witem iteration` | `PVTF_lADOAT1J1c4BeILXzhY3H4Y` | IP-001 |
| `witem obc` | `PVTF_lADOAT1J1c4BeILXzhY3H2o` | PI-PILOT-001 a PI-PILOT-006 |

---

### Issues criadas

| Issue | Número | URL | Feature | Labels |
|---|---|---|---|---|
| FTR-001 | #76 | https://github.com/produtoreativo/payments-api/issues/76 | PI-PILOT-001 | journey:delivery · pilot:fase-2 · feature:happy-path |
| FTR-002 | #77 | https://github.com/produtoreativo/payments-api/issues/77 | PI-PILOT-002 | journey:delivery · pilot:fase-2 · feature:happy-path |
| FTR-003 | #78 | https://github.com/produtoreativo/payments-api/issues/78 | PI-PILOT-003 | journey:delivery · pilot:fase-2 · feature:happy-path |
| FTR-004 | #79 | https://github.com/produtoreativo/payments-api/issues/79 | PI-PILOT-004 | journey:delivery · pilot:fase-2 · feature:exception |
| FTR-005 | #80 | https://github.com/produtoreativo/payments-api/issues/80 | PI-PILOT-005 | journey:delivery · pilot:fase-2 · feature:exception |
| FTR-006 | #81 | https://github.com/produtoreativo/payments-api/issues/81 | PI-PILOT-006 | journey:delivery · pilot:fase-2 · feature:exception |

**Campos preenchidos para cada Issue:**

| Campo | Valor |
|---|---|
| `oem journey` | Delivery |
| `witem feature` | PI-PILOT-001 a PI-PILOT-006 (conforme Issue) |
| `witem release` | REL-PILOT-v1 |
| `witem iteration` | IP-001 |
| `witem obc` | PI-PILOT-001 a PI-PILOT-006 (conforme Issue) |

**Campos deixados em branco** (a serem preenchidos durante a execução via RT-02):

| Campo | Quando preencher |
|---|---|
| `State` | Após cada evento de fase — valor derivado do RT-02 |
| `Phase` | Junto com State |
| `Rework Count` | Quando `Rework.Started` ocorrer |
| `Blocked Since` | Quando `Impediment.Raised` ocorrer |
| `Last Event Type` | Após cada evento emitido via RT-01 |
| `Computed At` | Junto com Last Event Type |
| `Has Corrections` | Quando `Event.Corrected` ocorrer |

**Invariante preservada:** nenhuma Feature inicia automaticamente. O campo `State` permanece em branco até que `Bootstrap.Started` seja emitido pelo operador via RT-01 — não há automação que inicie uma Feature.

---

## 2. Views — Limitação da API

**A mutação `createProjectV2View` não existe na API GraphQL pública do GitHub.** Confirmado com:
```
{"errors":[{"message":"Field 'createProjectV2View' doesn't exist on type 'Mutation'"}]}
```

As Views devem ser criadas manualmente via UI em https://github.com/orgs/produtoreativo/projects/24.

### Views já existentes (não alterar)

| View | Layout | Uso |
|---|---|---|
| All Work Items | TABLE | Todos os itens do project |
| By Operation | TABLE | Agrupado por Operation |
| Business Signals | TABLE | Business Signals |
| Delivery | TABLE | Visão de Delivery |
| Diligence | TABLE | Visão de Diligence |
| Workspace Reconciliation | TABLE | Reconciliação do workspace |

### Views a criar via UI — Backlog

| View a criar | Layout | Filtro sugerido | Agrupamento |
|---|---|---|---|
| **Business Intent Backlog** | Table | `witem obc` contém `PI-PILOT` | Por `oem journey` |
| **Roadmap** | Table | `witem release = REL-PILOT-v1` | Por `witem feature` |
| **Release Backlog** | Table | `witem release = REL-PILOT-v1` | Por `State` |
| **Iteration Backlog** | Table | `witem iteration = IP-001` | Por `State` |

### Views a criar via UI — Delivery (Board)

| View a criar | Layout | Colunas (campo State) |
|---|---|---|
| **Bootstrap** | Board | Coluna: BOOTSTRAPPING |
| **Hack** | Board | Coluna: HACKING |
| **Sync** | Board | Coluna: SYNCING |
| **Finish** | Board | Coluna: FINISHING |
| **Blocked** | Board | Coluna: BLOCKED |
| **Done** | Board | Coluna: DONE |

### Views a criar via UI — Diligence (Board)

| View a criar | Layout | Campo de coluna | Semântica |
|---|---|---|---|
| **Pending** | Board | `State` = BOOTSTRAPPING | Aguardando início do Diligence Sync |
| **Running** | Board | `State` ∈ {HACKING, SYNCING, FINISHING} | Diligence Sync em andamento |
| **Failed** | Board | `State` = BLOCKED | Diligence com impedimento |
| **Reconciled** | Board | `State` = DONE | Diligence concluído |

---

## 3. Labels criadas

| Label | Cor | Descrição |
|---|---|---|
| `pilot:fase-2` | `#0075ca` | Piloto Operacional ProdOps Fase 2 — IP-001 |
| `feature:happy-path` | `#0e8a16` | Feature de happy path (PI-001 a PI-003) |
| `feature:exception` | `#e4e669` | Feature de exceção — Gate.Failed, Rework ou Blocking |

---

## 4. Conformidade com restrições

| Restrição | Status |
|---|---|
| Não implementar Runtime | ✅ Nenhum arquivo de runtime alterado |
| Não alterar SDK, OEM, Timeline ou catálogos | ✅ Confirmado |
| Não implementar `/delivery` | ✅ Ausente |
| Não criar GitHub Actions | ✅ Nenhuma Action criada |
| Não criar dashboards Datadog | ✅ Ausente |
| Não alterar Discovery, Roadmap, Release ou Iteration Plan | ✅ Confirmado |
| GitHub Project continua sendo apenas representação operacional | ✅ State vazio em todos os Issues — nenhuma Feature inicia automaticamente |
| Todas as Features aparecem na Iteration Backlog | ✅ Todos os 6 Issues com `witem iteration = IP-001` |
| Nenhuma Feature inicia automaticamente | ✅ Campos de State e Phase vazios — execução inicia via RT-01 pelo operador |

---

## 5. Project URL

**GitHub Project #24:** https://github.com/orgs/produtoreativo/projects/24

---

## 6. Próximos passos

### Para o operador (manual — via UI)

1. Criar as 13 Views pendentes (4 Backlog + 6 Delivery + 4 Diligence) via UI em https://github.com/orgs/produtoreativo/projects/24
2. Configurar os filtros e agrupamentos de cada View conforme a tabela acima
3. Verificar que todos os 6 Issues (#76 a #81) aparecem na View "Iteration Backlog" (filtro: `witem iteration = IP-001`)

### Para o piloto (aguarda próximo prompt)

4. Verificar o Entry Gate da Release (Release Plan — Seção 2)
5. Iniciar FTR-001 (Invoice PIX) via RT-01: emitir `Delivery.Bootstrap.Started`
6. Atualizar o campo `State` do Issue #76 para `BOOTSTRAPPING` após o primeiro evento

---

## 7. Rastreabilidade

| Artefato | Localização |
|---|---|
| GitHub Project | https://github.com/orgs/produtoreativo/projects/24 |
| FTR-001 Issue | https://github.com/produtoreativo/payments-api/issues/76 |
| FTR-002 Issue | https://github.com/produtoreativo/payments-api/issues/77 |
| FTR-003 Issue | https://github.com/produtoreativo/payments-api/issues/78 |
| FTR-004 Issue | https://github.com/produtoreativo/payments-api/issues/79 |
| FTR-005 Issue | https://github.com/produtoreativo/payments-api/issues/80 |
| FTR-006 Issue | https://github.com/produtoreativo/payments-api/issues/81 |
| GitHub Project Template (conceitual) | `prodops/artifacts/product/github-project-template-pilot.md` |
| Release Plan | `prodops/artifacts/product/release-plan-pilot.md` |
| Iteration Plan | `prodops/artifacts/plans/iteration-plan-pilot.md` |
| doc-review anterior (Release Planning) | `prodops/documentation-review-pilot-release-planning.md` |
