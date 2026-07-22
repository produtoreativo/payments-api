# GitHub Sync Manifest

> Registro persistente do estado de conformidade da infraestrutura do GitHub em relação à especificação canônica.
> Atualizado pelo step `verify` do ciclo `diligence-infra` ao final de cada execução.
>
> Spec canônica: `prodops/framework/github-workspace.md`

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

### Views (template #23) — criadas via REST API 2026-07-22

| View | Número | Filtro | Status |
|---|---|---|---|
| View 1 | 1 | — | ⚠️ extra (padrão do GitHub — remover manualmente) |
| test-view-api | 2 | — | ⚠️ extra (teste — remover manualmente) |
| All Work Items | 3 | — | ✅ CONFORME |
| By Operation | 4 | — | ✅ CONFORME |
| Business Signals | 5 | label:artifact-type:business-signal | ✅ CONFORME |
| Delivery | 6 | label:journey:delivery | ✅ CONFORME |
| Diligence | 7 | label:journey:diligence | ✅ CONFORME |

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

### Views (gerenciado #24) — criadas via REST API 2026-07-22

| View | Número | Filtro | Status |
|---|---|---|---|
| View 1 | 1 | — | ⚠️ extra (padrão do GitHub — remover manualmente) |
| All Work Items | 2 | — | ✅ CONFORME |
| By Operation | 3 | — | ✅ CONFORME |
| Business Signals | 4 | label:artifact-type:business-signal | ✅ CONFORME |
| Delivery | 5 | label:journey:delivery | ✅ CONFORME |
| Diligence | 6 | label:journey:diligence | ✅ CONFORME |

> **Projetos manuais (não gerenciados — não tocar):**
> - #22 — Turma Junho 2026 — usado antes do framework
> - #20 — PoolCloud, #18 — Release Junho, #17 — Sprint Junho
> - #2 — ProdOps template (antigo, sem campos canônicos)

---

## Labels

**Status:** `CONFORME`
**Última verificação:** 2026-07-22
**Total:** 37/37 labels canônicas em conformidade (54 total no repo, extras ignoradas)

Labels são do repositório, não do projeto — permanecem conformes independentemente do projeto gerenciado.

Nota: label `operation:provision` criada para rastreamento de gaps de infra. Considerar adicionar à spec canônica em `prodops/framework/github-workspace.md`.

---

## Custom Fields

**Status (template #23):** `CONFORME` — 8/8 campos conformes
**Status (gerenciado #24):** `CONFORME` — 8/8 campos conformes
**Última verificação:** 2026-07-22

---

## Views

**Status (template #23):** `CONFORME` — 5/5 views canônicas criadas via REST API
**Status (gerenciado #24):** `CONFORME` — 5/5 views canônicas criadas via REST API
**Última verificação:** 2026-07-22

Issues #58-62 fechados em 2026-07-22. Views criadas via `POST /orgs/produtoreativo/projectsV2/{N}/views`.

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
| [#57](https://github.com/produtoreativo/payments-api/issues/57) | infra: Evidence Required CHECKBOX field not provisionable via API | Custom Field CHECKBOX | ProdOps — template #23 |
| [#57](https://github.com/produtoreativo/payments-api/issues/57) | infra: Evidence Required CHECKBOX field not provisionable via API | Custom Field CHECKBOX | ProdOps — template #23 e gerenciado #24 |
| ~~#57~~ | Evidence Required CHECKBOX — FECHADO | Adotado SINGLE_SELECT como fallback GitOps | — |
| ~~#58-62~~ | views — FECHADOS | Resolvido via REST API `POST /orgs/{org}/projectsV2/{N}/views` | — |

---

## Histórico

| Data | Executado por | Resultado | Notas |
|---|---|---|---|
| 2026-07-22 | diligence-agent | PARCIAL | Labels ✅ 37. Fields/Views provisionados no #22 (manual). |
| 2026-07-22 | diligence-agent | PARCIAL | Re-verificação: Labels ✅ 37/37. Fields 7/8. Views 0/5 (Issues #58-62). |
| 2026-07-22 | diligence-agent | PARCIAL | Issues #57-62 criados. Label operation:provision criada. |
| 2026-07-22 | christiano.m.almeida | REVISÃO | Separação gerenciado/manual estabelecida. Projeto gerenciado "ProdOps — payments-api" ainda não criado. |
| 2026-07-22 | christiano.m.almeida | REVISÃO | Modelo de dois projetos: template canônico + gerenciado por repo. Fluxo: criar template → provisionar campos → mark-template → copy para repo. |
| 2026-07-22 | diligence-agent | PARCIAL | diligence-infra completo. Template #23 criado, campos 7/8 provisionados, mark-template executado. Gerenciado #24 criado via copy. Issues #57-62 atualizados para referenciar template. Labels CONFORME 37/37. Views 0/5 PENDENTE manual. |
| 2026-07-22 | christiano.m.almeida + diligence-agent | CONFORME (views) | Views criadas via REST POST /projectsV2/{N}/views. 5/5 views em template #23 e gerenciado #24. Issues #58-62 fechados. Endpoint correto descoberto: projectsV2 (não projects). group_by não disponível via API. |
| 2026-07-22 | christiano.m.almeida | CONFORME (campos) | Evidence Required criado como SINGLE_SELECT (fallback GitOps — CHECKBOX ausente do enum). Issue #57 fechado. Template #23 e gerenciado #24 agora CONFORME 8/8 campos. |
