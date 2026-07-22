# GitHub Sync Manifest

> Registro persistente do estado de conformidade do GitHub Workspace em relação à Canonical Specification.
> Atualizado pelo step `verify` da capability `workspace-reconciliation` ao final de cada execução.
>
> Canonical Specification: `prodops/framework/github-workspace.md`

**Repositório:** produtoreativo/payments-api
**Última verificação:** 2026-07-22

---

## Template Canônico

**Nome:** `ProdOps — template`
**Status:** `CONFORME` — 8/8 campos, 5/5 views, mark-template executado
**Última verificação:** 2026-07-22

Projeto template da org. Source para `gh project copy` ao criar projetos gerenciados por repositório.

| Campo | Valor |
|---|---|
| Nome | `ProdOps — template` |
| Número | 23 |
| ID | `PVT_kwDOAT1J1c4BeIK4` |
| URL | https://github.com/orgs/produtoreativo/projects/23 |
| is-template | executado via `gh project mark-template 23` (sem erro) |
| Visibilidade | PUBLIC ✅ |

### Custom Fields (template #23) — verificado via API 2026-07-22

| Campo | Tipo | Status |
|---|---|---|
| Artifact ID | TEXT | ✅ CONFORME |
| Artifact Type | SINGLE_SELECT | ✅ CONFORME |
| Operation | SINGLE_SELECT | ✅ CONFORME |
| Journey | SINGLE_SELECT | ✅ CONFORME |
| Execution Mode | SINGLE_SELECT | ✅ CONFORME |
| Owner | TEXT | ✅ CONFORME |
| Release | TEXT | ✅ CONFORME |
| Evidence Required | SINGLE_SELECT (`Required` / unset) | ✅ CONFORME — fallback GitOps (Issue #57 fechado) |

### Views (template #23) — verificado via GraphQL 2026-07-22

| View | ID | Filtro | Status |
|---|---|---|---|
| View 1 | PVTV_lADOAT1J1c4BeIK4zgLDics | — | ⚠️ extra (padrão do GitHub — remover manualmente) |
| test-view-api | PVTV_lADOAT1J1c4BeIK4zgLDi_Q | — | ⚠️ extra (teste — remover manualmente) |
| All Work Items | PVTV_lADOAT1J1c4BeIK4zgLDjEA | — | ✅ CONFORME |
| By Operation | PVTV_lADOAT1J1c4BeIK4zgLDjEM | — | ✅ CONFORME |
| Business Signals | PVTV_lADOAT1J1c4BeIK4zgLDjEU | label:artifact-type:business-signal | ✅ CONFORME |
| Delivery | PVTV_lADOAT1J1c4BeIK4zgLDjEY | label:journey:delivery | ✅ CONFORME |
| Diligence | PVTV_lADOAT1J1c4BeIK4zgLDjEc | label:journey:diligence | ✅ CONFORME |

Nota: `group_by` não configurável via API (REST PATCH 404, GraphQL sem mutation). Configurar na UI se desejado.

Nota: existe projeto antigo #2 `ProdOps template` (sem travessão) — não usar como source. O template canônico é o #23 `ProdOps — template` (com ` — `).

---

## Projeto Gerenciado

**Nome:** `ProdOps — payments-api`
**Status:** `CONFORME` — criado via copy do template #23, 8/8 campos, 5/5 views
**Última verificação:** 2026-07-22

Criado via `gh project copy 23 --source-owner produtoreativo --target-owner produtoreativo --title "ProdOps — payments-api"`.

| Campo | Valor |
|---|---|
| Nome | `ProdOps — payments-api` |
| Número | 24 |
| ID | `PVT_kwDOAT1J1c4BeILX` |
| URL | https://github.com/orgs/produtoreativo/projects/24 |
| Visibilidade | PUBLIC ✅ |

### Custom Fields (gerenciado #24) — verificado via API 2026-07-22

| Campo | Tipo | Status |
|---|---|---|
| Artifact ID | TEXT | ✅ CONFORME (herdado via copy) |
| Artifact Type | SINGLE_SELECT | ✅ CONFORME (herdado via copy) |
| Operation | SINGLE_SELECT | ✅ CONFORME (herdado via copy) |
| Journey | SINGLE_SELECT | ✅ CONFORME (herdado via copy) |
| Execution Mode | SINGLE_SELECT | ✅ CONFORME (herdado via copy) |
| Owner | TEXT | ✅ CONFORME (herdado via copy) |
| Release | TEXT | ✅ CONFORME (herdado via copy) |
| Evidence Required | SINGLE_SELECT (`Required` / unset) | ✅ CONFORME — fallback GitOps (Issue #57 fechado) |

### Views (gerenciado #24) — verificado via GraphQL 2026-07-22

| View | ID | Filtro | Status |
|---|---|---|---|
| View 1 | PVTV_lADOAT1J1c4BeILXzgLDifk | — | ⚠️ extra (padrão do GitHub — remover manualmente) |
| All Work Items | PVTV_lADOAT1J1c4BeILXzgLDjI4 | — | ✅ CONFORME |
| By Operation | PVTV_lADOAT1J1c4BeILXzgLDjI8 | — | ✅ CONFORME |
| Business Signals | PVTV_lADOAT1J1c4BeILXzgLDjJA | label:artifact-type:business-signal | ✅ CONFORME |
| Delivery | PVTV_lADOAT1J1c4BeILXzgLDjJE | label:journey:delivery | ✅ CONFORME |
| Diligence | PVTV_lADOAT1J1c4BeILXzgLDjJI | label:journey:diligence | ✅ CONFORME |

> **Projetos manuais (não gerenciados — não tocar):**
> - #22 — Turma Junho 2026
> - #20 — PoolCloud, #18 — Release Junho, #17 — Sprint Junho, #16 — Release Schola
> - #15 — 1.5 Gestão de Riscos, #14 — 1.4 Follow Up, #13 — 1.3 Alarmes
> - #12 — 1.6 Interface, #11 — 1.2 Gestão Inspeções, #10 — 1.1 Coleta
> - #9 — 1.7 Administração, #7 — Backlog Order, #6 — Ecommerce
> - #4 — 1.0.0, #3 — Ecommerce Old, #2 — ProdOps template (antigo, sem campos canônicos), #1 — MVP

---

## Labels

**Status:** `CONFORME`
**Última verificação:** 2026-07-22
**Total:** 38/38 labels canônicas em conformidade

Labels são do repositório, não do projeto — permanecem conformes independentemente do projeto gerenciado.

Nota: `operation:provision` está na Canonical Specification (`prodops/framework/github-workspace.md`) como label canônica desde 2026-07-22. Contagem atualizada de 37 para 38.

---

## Custom Fields

**Status (template #23):** `CONFORME` — 8/8 campos conformes
**Status (gerenciado #24):** `CONFORME` — 8/8 campos conformes
**Última verificação:** 2026-07-22

---

## Views

**Status (template #23):** `CONFORME` — 5/5 views canônicas verificadas via GraphQL
**Status (gerenciado #24):** `CONFORME` — 5/5 views canônicas verificadas via GraphQL
**Última verificação:** 2026-07-22

Views criadas via `POST /orgs/produtoreativo/projectsV2/{N}/views` em ciclo anterior (2026-07-22).

Pendência cosmética: `group_by` não configurável via API — configurar manualmente na UI se desejado.
Extras a remover manualmente: "View 1" e "test-view-api" no template #23; "View 1" no gerenciado #24.

---

## Milestones

**Status:** `N/A`
**Última verificação:** 2026-07-22

Nenhum OBC no Iteration Plan possui campo `release` com versão definida. Nenhum Milestone esperado.

---

## Issues de infraestrutura abertos

| Issue | Título | Gap | Destino |
|---|---|---|---|
| ~~#57~~ | Evidence Required CHECKBOX — FECHADO | Adotado SINGLE_SELECT como fallback GitOps | — |
| ~~#58-62~~ | views — FECHADOS | Resolvido via REST API `POST /orgs/{org}/projectsV2/{N}/views` | — |

Nenhum Issue de infraestrutura aberto neste ciclo.

---

## Histórico

| Data | Executado por | Resultado | Notas |
|---|---|---|---|
| 2026-07-22 | diligence-agent | PARCIAL | Labels ✅ 37. Fields/Views provisionados no #22 (manual). |
| 2026-07-22 | diligence-agent | PARCIAL | Re-verificação: Labels ✅ 37/37. Fields 7/8. Views 0/5 (Issues #58-62). |
| 2026-07-22 | diligence-agent | PARCIAL | Issues #57-62 criados. Label operation:provision criada. |
| 2026-07-22 | christiano.m.almeida | REVISÃO | Separação gerenciado/manual estabelecida. Projeto gerenciado "ProdOps — payments-api" ainda não criado. |
| 2026-07-22 | christiano.m.almeida | REVISÃO | Modelo de dois projetos: template canônico + gerenciado por repo. Fluxo: criar template → provisionar campos → mark-template → copy para repo. |
| 2026-07-22 | diligence-agent | PARCIAL | workspace-reconciliation completo. Template #23 criado, campos 7/8 provisionados, mark-template executado. Gerenciado #24 criado via copy. Issues #57-62 atualizados para referenciar template. Labels CONFORME 37/37. Views 0/5 PENDENTE manual. |
| 2026-07-22 | christiano.m.almeida + diligence-agent | CONFORME (views) | Views criadas via REST POST /projectsV2/{N}/views. 5/5 views em template #23 e gerenciado #24. Issues #58-62 fechados. Endpoint correto descoberto: projectsV2 (não projects). group_by não disponível via API. |
| 2026-07-22 | christiano.m.almeida | CONFORME (campos) | Evidence Required criado como SINGLE_SELECT (fallback GitOps — CHECKBOX ausente do enum). Issue #57 fechado. Template #23 e gerenciado #24 agora CONFORME 8/8 campos. |
| 2026-07-22 | diligence-agent (workspace-reconciliation — user invocation) | CONFORME | Inspect → Verify (sem drift). Labels 38/38 (operation:provision agora canônica). Template #23 e gerenciado #24 CONFORME via API. Nenhum Issue aberto. |
