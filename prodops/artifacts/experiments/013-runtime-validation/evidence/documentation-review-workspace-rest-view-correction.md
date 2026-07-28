# Documentation Review — Workspace REST View Correction

**Data:** 2026-07-26
**Revisor:** Claude (automatizado)
**Escopo:** Correção do endpoint REST para criação de Views no GitHub Projects v2
**Antecedente:** [documentation-review-workspace-strategy-resolution.md](./documentation-review-workspace-strategy-resolution.md)

---

## Sumário

O relatório anterior concluiu incorretamente que nenhuma estratégia automatizada estava disponível para criação de Views. A causa-raiz foi um probe apontando para um endpoint REST inexistente. Após correção do endpoint, as 9 Views pendentes foram criadas via REST sem necessidade de Playwright. O Workspace está com conformance estrutural OK.

---

## 1. Causa-raiz do erro

O `VIEW_PROBE_CONFIG` em `view.provider.ts` usava:

```
GET /orgs/produtoreativo/projects/24/views
```

Esse path retorna **404** — é o endpoint de Projects Classic (v1), não Projects v2.

O endpoint correto do GitHub Projects v2 é:

```
POST /orgs/{org}/projectsV2/{project_number}/views
GET  /orgs/{org}/projectsV2/{project_number}         ← probe não-destrutivo
```

O probe do tipo `GET` no endpoint de listagem não existe (a API REST não expõe listagem de views via REST — apenas criação). O probe correto é um `GET` no recurso-pai (`/projectsV2/{number}`), que retorna 200 quando o projeto é acessível e o token tem scope `project`.

**Consequência:** o Resolver concluiu que REST era indisponível e caiu em `manual-intervention`. As 9 Views foram tratadas como bloqueio manual quando podiam ser criadas automaticamente.

---

## 2. Comportamento real da REST API do GitHub Projects v2 (verificado empiricamente)

| Operação | Endpoint | Status |
|---|---|---|
| GET projeto (probe) | `GET /orgs/{org}/projectsV2/{number}` | ✅ 200 |
| Criar view | `POST /orgs/{org}/projectsV2/{number}/views` | ✅ 201 |
| Listar views | `GET /orgs/{org}/projectsV2/{number}/views` | ❌ 404 (não existe) |
| Deletar view (REST) | `DELETE /orgs/{org}/projectsV2/{number}/views/{id}` | ❌ 404 (não existe) |
| Deletar view (GraphQL) | `deleteProjectV2View` | ❌ mutation ausente do schema |
| Criar view (GraphQL) | `createProjectV2View` | ❌ mutation ausente do schema |
| Listar views (GraphQL) | `node.views(first:N)` | ✅ funciona (usado para idempotência) |

**Limitação importante:** `group_by` não pode ser definido via REST na criação. A REST API aceita `name`, `layout`, `filter` e `visible_fields`. O `groupBy` configurado no `workspace.yaml` precisa ser aplicado manualmente via GitHub UI após a criação da view.

---

## 3. Componentes alterados

### `src/github/views.rest.ts` (novo)

Adapter REST para criação de views. Usa `spawnSync` com args array para evitar problemas de shell escaping com nomes de views que contêm espaços.

```typescript
createOrganizationProjectView(owner, projectNumber, view) → RestViewResult
```

- Endpoint: `POST /orgs/{owner}/projectsV2/{projectNumber}/views`
- Header: `X-GitHub-Api-Version: 2022-11-28`
- Layout: `TABLE` → `table`, `BOARD` → `board`
- Erros classificados: 401 (auth), 403 (permission), 404 (project not found), 422 (payload inválido)
- Retorna: `{ id, number, name, layout, url, nodeId }`

### `src/providers/view.provider.ts` (reescrito)

**Cadeia de estratégias para criação:**
```
REST → Browser Automation → Manual Intervention
```

GraphQL: mantido apenas para listagem (`listViews` via GraphQL continua funcionando).

**Probe config (dinâmico por chamada):**
```typescript
function makeProbeConfig(owner, projectNumber): ResolverProbeConfig {
  return {
    rest: { endpoint: `/orgs/${owner}/projectsV2/${projectNumber}`, method: 'GET' },
    browser: true,
  };
}
```

**Assinatura de `validate` atualizada:**
```typescript
validate(owner, projectId, projectNumber, view) → ViewValidationResult
```

`ViewValidationResult` agora inclui `exists: boolean` para distinguir:
- `exists: false` → view ausente (pode ser auto-corrigida via REST)
- `exists: true, layoutMatch: false` → layout errado (manual — delete não disponível via API)
- `exists: true, layoutMatch: true` → unverifiable

**`meta.autoCorrectPossible: true`** — REST está disponível.

### `src/strategies/capability-probe.ts` (patch)

Removida mensagem hardcoded `"GitHub Projects v2 does not expose REST for views"` — substituída por mensagem genérica para 404.

### `src/doctor.ts` (atualizado)

- Assinatura de `WMC.view.validate(owner, project.id, project.number, expected)`
- Lógica do drift de views refatorada com campo `exists` (separação clara entre missing e wrong-layout)
- Recomendação de missing view agora inclui endpoint REST correto
- Views missing agora reportadas como `drift-auto-correctable` (não mais `drift-manual-required`)

### `package.json` (atualizado)

`playwright` movido de `dependencies` para `optionalDependencies`. Playwright não é requisito para nenhuma operação atual.

---

## 4. Permissões verificadas

```bash
gh auth status
# Token scopes: 'project', 'repo', 'admin:org', ...
```

Scope `project` presente. `POST /orgs/produtoreativo/projectsV2/24/views` retornou 201.

**Permissão necessária:** `Projects organization permission: write` (coberta pelo scope `project` do token atual).

Se o token retornar 403, o ViewProvider reporta claramente a permissão faltante e NÃO cai em Browser Automation — distingue entre "permissão ausente" e "endpoint indisponível".

---

## 5. Views criadas no Project #24

Provisão executada em 2026-07-26. Todas as 9 Views criadas via REST:

| View | Layout | View # | Endpoint |
|---|---|---|---|
| Business Intent Backlog | TABLE | #10 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Roadmap | TABLE | #11 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Release Backlog | TABLE | #12 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Iteration Backlog | TABLE | #13 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Delivery Board | BOARD | #14 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Delivery Done | TABLE | #15 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Delivery Blocked | TABLE | #16 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Diligence Board | BOARD | #17 | `POST /orgs/produtoreativo/projectsV2/24/views` |
| Findings | TABLE | #18 | `POST /orgs/produtoreativo/projectsV2/24/views` |

**Nota sobre view extra:** Durante a investigação do endpoint, foi criada uma view de teste `"Test-probe-delete-me"` (#9) que não pode ser deletada programaticamente (REST 404, GraphQL mutation ausente). Remover manualmente via GitHub UI: https://github.com/orgs/produtoreativo/projects/24

**Nota sobre `groupBy`:** REST API não suporta `group_by` na criação. As views foram criadas com nome e layout corretos. Configurar `groupBy` manualmente via GitHub UI para cada view conforme definido no `workspace.yaml`.

---

## 6. Doctor antes e depois

### Antes da correção (relatório anterior)
```
ViewProvider: checked=15 drifts=9 strategy=graphql auto-correct=no ⚠
9 blocking drifts — conformance: drift-manual-required para todas as 9 views
```

### Depois da correção

**Doctor antes da provisão:**
```
ViewProvider: checked=15 drifts=9 strategy=rest auto-correct=yes
9 views: conformance: drift-auto-correctable
fix: Run 'workspace provision' to create via rest [POST /orgs/produtoreativo/projectsV2/24/views]
```

**Doctor após provisão:**
```
ViewProvider: checked=15 drifts=0 strategy=rest auto-correct=yes
15 views: unverifiable (layout OK, filter/groupBy não verificável via API)
✅ Workspace structural conformance OK — 15 view(s) exist but filter/groupBy unverifiable via API
```

Zero blocking drifts.

---

## 7. Idempotência

Segunda execução do Provisioner (após criação das 9 views):

```
[5/7] Views
  ✓ View exists: "Business Signals"
  ...
  ✓ View exists: "Business Intent Backlog"
  ✓ View exists: "Roadmap"
  ✓ View exists: "Release Backlog"
  ✓ View exists: "Iteration Backlog"
  ✓ View exists: "Delivery Board"
  ✓ View exists: "Delivery Done"
  ✓ View exists: "Delivery Blocked"
  ✓ View exists: "Diligence Board"
  ✓ View exists: "Findings"
```

Zero views criadas. Zero duplicadas. Todos `✓`.

---

## 8. Papel residual do Playwright

`views.browser.ts` permanece como fallback na cadeia (posição 2, após REST). Atua somente quando:
- REST probe falha (403 — permissão, ou 404 — projeto não encontrado)
- `GH_BROWSER_AUTH_STATE` está definida e aponta para arquivo válido

Playwright movido para `optionalDependencies`. Ausência de `GH_BROWSER_AUTH_STATE` não impede operação normal — REST é o caminho primário.

---

## 9. Testes

```bash
npm test && npm run typecheck
# ✅ 2 test files — 21 tests passed — Exit 0
# ✅ typecheck Exit 0
```

Testes atualizados:

| Suite | Testes |
|---|---|
| `resolver.test.ts` | 7 testes — sem alteração |
| `view.provider.test.ts` | 14 testes — REST como estratégia primária, probe correto, fallback REST→Browser→Manual, conformance com `exists`, unverifiable ≠ conformant |

Testes removidos: os que assumiam que REST era indisponível para views.

---

## 10. Conformidade com restrições

| Restrição | Status |
|---|---|
| NÃO implementar Delivery, Diligence, Runtime Events | ✅ |
| NÃO alterar OEM, SDK, Event Catalogs, Discovery | ✅ |
| NÃO versionar credenciais ou sessões | ✅ |
| NÃO criar commit | ✅ |
| Typecheck Exit 0 | ✅ |
| npm test: 0 falhas | ✅ — 21 testes |
| Playwright não é requisito para criação | ✅ — movido para optionalDependencies |
| 9 Views criadas via REST | ✅ |
| Segunda provisão não duplica | ✅ |
| Doctor sem blocking drifts | ✅ |

---

## 11. Confirmação — Piloto pode prosseguir

O Workspace está estruturalmente conformante. O único passo pendente antes de iniciar F-01 (Invoice PIX) é configurar `groupBy` nas views via GitHub UI:

| View | groupBy esperado |
|---|---|
| Business Intent Backlog | `oem:journey` |
| Roadmap | `witem:feature` |
| Release Backlog | `oem:state` |
| Iteration Backlog | `oem:state` |
| Delivery Board | `oem:state` |
| Delivery Done | `oem:state` |
| Delivery Blocked | `witem:feature` |
| Diligence Board | `diligence:status` |
| Findings | `diligence:evidence` |

URL do projeto: https://github.com/orgs/produtoreativo/projects/24

---

## 12. Rastreabilidade

| Artefato | Localização |
|---|---|
| REST adapter | `runtime/workspace/src/github/views.rest.ts` |
| ViewProvider corrigido | `runtime/workspace/src/providers/view.provider.ts` |
| Capability Probe (patch) | `runtime/workspace/src/strategies/capability-probe.ts` |
| Doctor atualizado | `runtime/workspace/src/doctor.ts` |
| Testes atualizados | `runtime/workspace/src/providers/__tests__/view.provider.test.ts` |
| package.json | `runtime/workspace/package.json` |
| Relatório anterior | `prodops/documentation-review-workspace-strategy-resolution.md` |
| GitHub Project #24 | https://github.com/orgs/produtoreativo/projects/24 |
