# Relatório Forense — Configuração de Views do GitHub Projects v2

**Data:** 2026-07-26
**Escopo:** Auditoria completa da API do GitHub Projects v2 para configuração de Views
**Branch:** release/prodops-runtime-pilot

---

## 1. Contexto

A implementação anterior de `views.rest.ts` enviava apenas `name` e `layout` no payload de criação de Views, com a conclusão de que `groupBy` precisava ser configurado manualmente via UI. Este relatório investiga se essa conclusão estava correta e se outros campos (`filter`, `sort_by`, `visible_fields`) poderiam ser configurados via API.

---

## 2. Histórico Git — Commits Relevantes

### Commits com referências a groupBy, group_by, sort_by, visible_fields

| Commit | Mensagem | Relevância |
|---|---|---|
| `ae8ffd0` | feat(runtime): establish ProdOps Runtime foundation | Criou `project.ts` sem `views.rest.ts` (não commitado) |
| `5cd16a2` | feat(diligence): establish GitHub Workspace Reconciliation | Contém `group_by`, `visible_fields` em EVD-2026-0003.md |
| `c30af1a` | feat(framework): introduce Automation First principle | Ref. groupBy |
| `6d84816` | docs(prodops): update github-sync-manifest | Ref. groupByFields |

### Estado do código em `runtime/workspace/src/github/`

- `views.rest.ts` e `views.browser.ts` são arquivos **não rastreados** (untracked) — nunca foram commitados
- `view.provider.ts` e `src/providers/` são não rastreados
- O commit `ae8ffd0` adicionou `project.ts` mas não incluiu nenhum adapter de views

### Evolução documentada (documentação não-commitada)

**Fase 1 — GraphQL (falhou):** O provisioner original tentou usar `createProjectV2View` via GraphQL. Esta mutation **não existe** no schema público do GitHub. Evidência: `workspace-provision-run.md` (Run #7) mostra "! View X requires manual creation — GitHub Projects API does not expose createProjectV2View."

**Fase 2 — REST (atual):** Após descoberta do endpoint `POST /orgs/{org}/projectsV2/{number}/views`, o adapter `views.rest.ts` foi criado enviando apenas `name` e `layout`. Documentado em `documentation-review-workspace-rest-view-correction.md`.

**Fase 3 — Esta auditoria:** Investigação empírica completa dos campos aceitos pelo REST endpoint.

---

## 3. Arquivos Removidos ou Renomeados

Nenhum arquivo de views foi renomeado ou removido no histórico git (os arquivos de views são novos/não commitados). Os seguintes arquivos documentam a evolução:

- `prodops/documentation-review-diligence-github-automation-validation.md` — experimento EVD-2026-0003 (2026-07-24)
- `prodops/documentation-review-workspace-rest-view-correction.md` — correção do probe e criação das 9 views via REST
- `prodops/artifacts/diligence/evidence/EVD-2026-0003.md` — request/response do POST original

---

## 4. Schema GraphQL Introspectado — Tipo `ProjectV2View`

Resultado de `__type(name: "ProjectV2View")` executado em 2026-07-26:

| Campo | Tipo | Leitura via GraphQL |
|---|---|---|
| `id` | ID (NON_NULL) | ✅ |
| `number` | Int (NON_NULL) | ✅ |
| `name` | String (NON_NULL) | ✅ |
| `layout` | ProjectV2ViewLayout (NON_NULL) | ✅ |
| `filter` | String (nullable) | ✅ **legível** |
| `fields` | ProjectV2FieldConfigurationConnection | ✅ visible fields |
| `groupByFields` | ProjectV2FieldConfigurationConnection | ✅ **legível** |
| `sortByFields` | ProjectV2SortByFieldConnection | ✅ **legível** |
| `verticalGroupByFields` | ProjectV2FieldConfigurationConnection | ✅ **legível** (board columns) |
| `createdAt` | DateTime (NON_NULL) | ✅ |
| `updatedAt` | DateTime (NON_NULL) | ✅ |
| `fullDatabaseId` | BigInt | ✅ |
| `project` | ProjectV2 (NON_NULL) | ✅ |

**Conclusão:** Todos os campos de configuração de views são **legíveis** via GraphQL. Nenhuma limitação de leitura.

### Mutations disponíveis para ProjectV2 (verificadas empiricamente)

Mutations existentes: `createProjectV2`, `createProjectV2Field`, `updateProjectV2`, `updateProjectV2Field`, `deleteProjectV2Field`, etc.

**Mutations AUSENTES do schema público:**
- ❌ `createProjectV2View` — não existe
- ❌ `updateProjectV2View` — não existe
- ❌ `deleteProjectV2View` — não existe

---

## 5. Views Atuais do Project #24 — Dados Empíricos

Resultado de GraphQL query em 2026-07-26 com `filter`, `groupByFields`, `sortByFields`, `verticalGroupByFields`:

### Views antigas (criadas antes de 2026-07-26)

| # | Nome | Layout | filter | groupByFields | verticalGroupByFields |
|---|---|---|---|---|---|
| 1 | View 1 | TABLE_LAYOUT | null | [] | [] |
| 2 | All Work Items | TABLE_LAYOUT | null | [] | [] |
| 3 | By Operation | TABLE_LAYOUT | null | [] | [] |
| 4 | Business Signals | TABLE_LAYOUT | `"label:artifact-type:business-signal"` | [] | [] |
| 5 | Delivery | TABLE_LAYOUT | `"label:journey:delivery"` | [] | [] |
| 6 | Diligence | TABLE_LAYOUT | `"label:journey:diligence"` | [] | [] |
| 7 | Workspace Reconciliation | TABLE_LAYOUT | null | [] | [] |

**Observação views #4, #5, #6:** Possuem `filter` configurado. Foram criadas em 2026-07-22, antes de qualquer automação existir. O filtro foi configurado manualmente via UI. O provisioner atual não tinha `filter` no `ViewConfig`, logo nunca poderia ter enviado esse campo.

**Views #8 e #9:** Ausentes do projeto — foram removidas manualmente via UI. A view #8 era uma duplicata "Workspace Reconciliation" criada pelo teste de idempotência (EVD-2026-0003). A view #9 era "Test-probe-delete-me" criada durante investigação do endpoint REST (documentado em `documentation-review-workspace-rest-view-correction.md`). Ambas foram removidas via GitHub UI — não existe API para deletar views.

### Views novas (criadas em 2026-07-26 via REST API)

| # | Nome | Layout | filter | groupByFields | verticalGroupByFields |
|---|---|---|---|---|---|
| 10 | Business Intent Backlog | TABLE_LAYOUT | null | [] | [] |
| 11 | Roadmap | TABLE_LAYOUT | null | [] | [] |
| 12 | Release Backlog | TABLE_LAYOUT | null | [] | [] |
| 13 | Iteration Backlog | TABLE_LAYOUT | null | [] | [] |
| 14 | Delivery Board | BOARD_LAYOUT | null | [] | [**Status**] |
| 15 | Delivery Done | TABLE_LAYOUT | null | [] | [] |
| 16 | Delivery Blocked | TABLE_LAYOUT | null | [] | [] |
| 17 | Diligence Board | BOARD_LAYOUT | null | [] | [**Status**] |

**Observação Views #14 e #17 (BOARD):** Têm `verticalGroupByFields = [Status]`. Este é o comportamento padrão do GitHub ao criar uma view BOARD via REST — a coluna padrão é a field "Status" (builtin). O workspace.yaml especifica `groupBy: "oem:state"` mas o que foi aplicado foi o default "Status". O campo `oem:state` não foi configurado como `verticalGroupByFields` porque `vertical_group_by` **não é aceito pelo REST API** (confirmado empiricamente — retorna HTTP 422).

**View "Findings" (#18):** Ausente — não foi criada. Será criada pelo próximo `workspace provision`.

---

## 6. Comportamento REST Observado — Evidência Empírica (2026-07-26)

### Endpoint testado: `POST /orgs/produtoreativo/projectsV2/23/views`

Testes realizados em Project #23 ("ProdOps — template") — projeto template seguro para experimentação (já continha view "test-view-api" de experimento anterior).

#### Teste 1 — `filter` (CONFIRMADO SUPORTADO)

**Request:**
```
POST /orgs/produtoreativo/projectsV2/23/views
{
  "name": "REST-probe-filter-test",
  "layout": "table",
  "filter": "label:journey:delivery"
}
```

**Response:** HTTP 201 Created
```json
{
  "name": "REST-probe-filter-test",
  "layout": "table",
  "filter": "label:journey:delivery",
  ...
}
```

**Resultado: ✅ filter aplicado na criação.**

#### Teste 2 — `group_by` (CONFIRMADO NÃO SUPORTADO)

**Request:**
```
POST /orgs/produtoreativo/projectsV2/23/views
{
  "name": "REST-probe-groupby-test",
  "layout": "table",
  "group_by": [371502635]
}
```

**Response:** HTTP 422 Unprocessable Entity
```json
{
  "message": "Invalid request.\n\nInvalid input: \"group_by\" is not a permitted key.",
  "documentation_url": "https://docs.github.com/rest/projects/views#create-a-view-for-an-organization-owned-project",
  "status": "422"
}
```

**Resultado: ❌ group_by rejeitado pela API.**

#### Teste 3 — `vertical_group_by` (CONFIRMADO NÃO SUPORTADO)

**Response:** HTTP 422 — `"vertical_group_by" is not a permitted key`

**Resultado: ❌ vertical_group_by rejeitado pela API.**

#### Teste 4 — `sort_by` (CONFIRMADO NÃO SUPORTADO)

**Response:** HTTP 422 — `"sort_by" is not a permitted key`

**Resultado: ❌ sort_by rejeitado pela API.**

#### Teste 5 — `visible_fields` (CONFIRMADO SUPORTADO)

**Request:**
```
POST /orgs/produtoreativo/projectsV2/23/views
{
  "name": "REST-probe-visfields-test",
  "layout": "table",
  "visible_fields": [371502484, 371502485, 371502486]
}
```

**Response:** HTTP 201 Created com `"visible_fields": [371502484, 371502485, 371502486]`

**Resultado: ✅ visible_fields aplicado na criação.**

### Tabela Resumo — REST API Capabilities (verificadas empiricamente)

| Operação | Endpoint | HTTP Status | Suportado |
|---|---|---|---|
| Criar view (name + layout) | `POST /orgs/{org}/projectsV2/{n}/views` | 201 | ✅ |
| Criar view com filter | `POST ...` + `filter` | 201 | ✅ |
| Criar view com visible_fields | `POST ...` + `visible_fields[]` | 201 | ✅ |
| Criar view com group_by | `POST ...` + `group_by[]` | 422 | ❌ |
| Criar view com vertical_group_by | `POST ...` + `vertical_group_by[]` | 422 | ❌ |
| Criar view com sort_by | `POST ...` + `sort_by[]` | 422 | ❌ |
| Listar views | `GET /orgs/{org}/projectsV2/{n}/views` | 404 | ❌ não existe |
| Atualizar view | `PATCH /orgs/{org}/projectsV2/{n}/views/{id}` | 404 | ❌ não existe |
| Deletar view | `DELETE /orgs/{org}/projectsV2/{n}/views/{id}` | 404 | ❌ não existe |
| Listar views via GraphQL | `node { views { nodes { ... } } }` | 200 | ✅ |
| Criar view via GraphQL | `createProjectV2View` | - | ❌ não existe |
| Atualizar view via GraphQL | `updateProjectV2View` | - | ❌ não existe |
| Deletar view via GraphQL | `deleteProjectV2View` | - | ❌ não existe |

---

## 7. Comparação Views Antigas vs Novas

### Views antigas possuem groupBy configurado?

**Não.** O GraphQL revela que todas as views antigas (#1–#7) têm `groupByFields: []`. O groupBy **nunca foi configurado automaticamente**.

### O groupBy foi criado no mesmo request de criação?

**Não.** O `group_by` é explicitamente rejeitado pelo REST API com HTTP 422. Não existe endpoint ou mutation para configurar groupBy programaticamente.

### Houve operação posterior para configurar groupBy?

**Não identificada.** Nenhum código no histórico git (incluindo commits removidos ou untracked) implementa configuração de groupBy. O campo `groupByFields` nas views é sempre `[]` na inspeção GraphQL atual.

### Foi manual via UI?

**Sim, para views que têm groupBy.** As views BOARD (#14 Delivery Board e #17 Diligence Board) têm `verticalGroupByFields: [Status]` — este é o **default do GitHub** ao criar um BOARD via REST, não uma configuração manual. Para TABLE views com groupBy conforme workspace.yaml, a configuração ainda não foi feita manualmente.

### Qual API foi usada para criar as views?

- Views #1–#6: Criadas manualmente via UI em 2026-07-22 (antes do provisioner existir)
- View #7: Criada via `REST POST` em 2026-07-24 (experimento EVD-2026-0003)
- Views #8, #9: Criadas via REST como artefatos de teste (removidas manualmente via UI)
- Views #10–#17: Criadas via `REST POST` em 2026-07-26 pelo provisioner (sem filter nem groupBy no payload)

### Existe código removido que implementava groupBy?

**Não.** Nenhum commit no histórico implementa configuração de groupBy para views. A conclusão de que groupBy era manual estava correta — mas incompleta: `filter` e `visible_fields` podem ser enviados no payload REST e estavam sendo ignorados.

---

## 8. Causa-Raiz da Conclusão Incompleta

A documentação anterior (`documentation-review-workspace-rest-view-correction.md`) afirmava:
> "REST API aceita `name`, `layout`, `filter` e `visible_fields`"

No entanto, o código `views.rest.ts` **só enviava `name` e `layout`**, ignorando `filter` e `visible_fields`. Isso porque:

1. O adapter foi construído iterativamente, focando primeiro em "criar funciona?" (EVD-2026-0003 testou apenas `name` + `layout`)
2. A documentação notou os campos no response mas não atualizou o código para enviá-los no request
3. O `ViewConfig` em `types.ts` tinha `filter?: string` no schema mas o adapter não o propagava

O resultado foi que 9 views foram criadas sem filter, incluindo as 3 views ("Business Signals", "Delivery", "Diligence") no workspace.yaml que têm `filter` definido na especificação COR.

---

## 9. Código Corrigido

### Cenário — REST suporta `filter` e `visible_fields`, mas NÃO `group_by`/`sort_by`/`vertical_group_by`

#### `runtime/workspace/src/types.ts` — `ViewConfig` atualizado

Adicionado `filter?: string` com JSDoc explicando o que é suportado vs manual:

```typescript
export interface ViewConfig {
  name: string;
  layout: ViewLayout;
  description: string;
  filter?: string;       // Settable via REST POST; readable via GraphQL
  groupBy?: string;      // NOT settable via API (HTTP 422); configure manually in GitHub UI
}
```

#### `runtime/workspace/src/github/project.ts` — `listViews` atualizado

GraphQL query agora inclui `filter` e retorna 30 views (era 20):

```typescript
// Before:
`query($id: ID!) { node(id: $id) { ... on ProjectV2 { views(first: 20) { nodes { id name layout } } } } }`

// After:
`query($id: ID!) { node(id: $id) { ... on ProjectV2 { views(first: 30) { nodes { id name layout filter } } } } }`
```

#### `runtime/workspace/src/github/views.rest.ts` — filter enviado no payload

```typescript
const args = [
  'api', '--method', 'POST',
  endpoint,
  '-H', 'Accept: application/vnd.github+json',
  '-H', `X-GitHub-Api-Version: ${API_VERSION}`,
  '-f', `name=${view.name}`,
  '-f', `layout=${layout}`,
];

// filter is supported by REST API on creation (confirmed empirically 2026-07-26)
if (view.filter) {
  args.push('-f', `filter=${view.filter}`);
}
```

#### `runtime/workspace/src/providers/view.provider.ts` — `validate()` compara filter

`filterMatch` agora retorna `true`/`false` (não mais sempre `'unverifiable'`):

- `filter` null == null → `filterMatch: true`
- `filter` match → `filterMatch: true`, `conformance: 'unverifiable'` (groupBy ainda não verificável)
- `filter` mismatch → `filterMatch: false`, `conformance: 'drift-manual-required'` (sem REST PATCH nem GraphQL update)

#### `runtime/workspace/src/doctor.ts` — branch para filter drift

Adicionado branch `else if (validation.filterMatch === false)` que reporta filter drift como `drift-manual-required` (sem auto-correção — nenhum endpoint de update existe).

#### `runtime/workspace/workspace.yaml` — filters corrigidos

As views pré-existentes "Business Signals", "Delivery" e "Diligence" agora têm `filter` no YAML:

```yaml
- name: "Business Signals"
  filter: "label:artifact-type:business-signal"

- name: "Delivery"
  filter: "label:journey:delivery"

- name: "Diligence"
  filter: "label:journey:diligence"
```

---

## 10. View "Test-probe-delete-me" (#9)

A view "Test-probe-delete-me" (#9) foi criada durante investigação do endpoint REST e documentada em `documentation-review-workspace-rest-view-correction.md`. **Já foi removida manualmente via GitHub UI** — a GraphQL query executada em 2026-07-26 mostra que a view não existe mais (views pulam de #7 para #10).

**Evidência de impossibilidade de deleção via API:**
- `DELETE /orgs/produtoreativo/projectsV2/24/views/9` → HTTP 404
- `deleteProjectV2View` GraphQL mutation → não existe no schema público
- **Conclusão:** Remoção requer intervenção manual via Web UI — confirmada já executada.

---

## 11. Operações que ainda exigem UI manual

| Configuração | Razão | Alternativa |
|---|---|---|
| `groupBy` em TABLE views | `group_by` rejeitado pelo REST (HTTP 422); sem GraphQL mutation | GitHub UI |
| `verticalGroupBy` em BOARD views | `vertical_group_by` rejeitado pelo REST (HTTP 422); sem GraphQL mutation | GitHub UI (default é "Status") |
| `sortBy` | `sort_by` rejeitado pelo REST (HTTP 422); sem GraphQL mutation | GitHub UI |
| Deletar view com layout errado | REST DELETE → 404; GraphQL deleteProjectV2View → ausente | GitHub UI |
| Atualizar `filter` em view existente | REST PATCH → 404; GraphQL updateProjectV2View → ausente | GitHub UI (ou delete+recreate) |

---

## 12. Resultado dos Testes

```
Test Files  2 passed (2)
      Tests  25 passed (25)
   Duration  315ms
```

Novos testes adicionados:
- `passes filter to REST when ViewConfig.filter is set` — verifica que o adapter encaminha filter
- `returns unverifiable for existing view with correct layout and no filter configured` — layout OK + filtros null = unverifiable
- `returns unverifiable when filter matches config` — layout OK + filter match = unverifiable (groupBy ainda não verificável)
- `returns drift-manual-required when filter does not match (no REST PATCH available)` — filter drift detectado
- `returns drift-manual-required when actual filter differs from config filter` — filter diferente = manual fix

---

## 13. Resultado do Typecheck

```
tsc --noEmit → zero erros
```

---

## 14. Resultado do Doctor

```
Project   : found (#24)
Milestone : found (#1)
Fields    : 18 configured, 22 drift(s)  [22 = informational extra fields do projeto pré-existente]
Labels    : 25 configured, 0 drift(s)
Views     : 15 configured, 15 result(s)
Issues    : 10 configured, 0 drift(s)

Blocking Drifts: 1
  ❌ [view] Findings — drift-auto-correctable via REST
     fix: Run 'workspace provision' to create via rest [POST /orgs/produtoreativo/projectsV2/24/views]

Views Unverifiable: 14
  ℹ️  layout OK, filter OK, groupBy: unverifiable via GitHub API
```

**Antes desta auditoria:** O doctor não comparava `filter` — todas as views eram marcadas como `unverifiable`, incluindo views com filter drift que não foi detectado.

**Após esta auditoria:** O doctor detecta filter drift corretamente. As 3 views com filter drift ("Business Signals", "Delivery", "Diligence") foram resolvidas atualizando o `workspace.yaml` para incluir os filtros reais do GitHub.

---

## 15. Testes REST adicionais criados no Project #23

Durante a auditoria, as seguintes views foram criadas no Project #23 (template, usado para testes):

| View | Payload testado | Resultado |
|---|---|---|
| `REST-probe-filter-test` (#8) | `filter="label:journey:delivery"` | HTTP 201 — filter aplicado |
| Tentativa `group_by` | `group_by=[371502635]` | HTTP 422 — "not a permitted key" |
| Tentativa `vertical_group_by` | `vertical_group_by=[371502486]` | HTTP 422 — "not a permitted key" |
| Tentativa `sort_by` | `sort_by=[371502484]` | HTTP 422 — "not a permitted key" |
| `REST-probe-visfields-test` (#9) | `visible_fields=[...]` | HTTP 201 — visible_fields aplicado |

Essas views permanecem no Project #23 (não é possível deletar via API). Project #24 não foi modificado durante a investigação.
