# Documentation Review — Workspace Management Strategy Resolution and View Provisioning

**Data:** 2026-07-26
**Revisor:** Claude (automatizado)
**Escopo:** Strategy Resolver, Provider chain evolution, ViewProvider com Browser Automation, workspace.yaml piloto
**Antecedente:** [documentation-review-workspace-management-refactoring.md](./documentation-review-workspace-management-refactoring.md)

---

## Sumário

A Capability `Workspace Management` foi evoluída com um mecanismo de **Strategy Resolution dinâmico**. O `ViewProvider` agora proba todas as estratégias possíveis antes de cair em Manual Intervention — e nunca falha silenciosamente. O `workspace.yaml` foi atualizado com as 15 Views do Piloto IP-001 (6 existentes + 9 novas). O Doctor agora reporta conformance tipada por view: `conformant`, `drift-auto-correctable`, `drift-manual-required`, `unverifiable`.

---

## 1. Strategy Resolver — componente criado

**Localização:** `runtime/workspace/src/strategies/`

```
src/strategies/
├── strategy-result.ts       StrategyResolutionResult, ProbeOutcome
├── capability-probe.ts      Probes por tipo (GraphQL, REST, gh CLI, Browser, Manual)
└── resolver.ts              resolveStrategy() — algoritmo de seleção
```

### Algoritmo

```
Para cada estratégia na cadeia (em ordem):
  1. Executar probe (sem efeitos colaterais)
  2. Se disponível → retornar StrategyResolutionResult
  3. Se indisponível → registrar razão, continuar
```

**Invariante:** nunca cai silenciosamente em `manual-intervention`. Todas as estratégias descartadas são registradas com razão explícita em `unavailableStrategies`.

### Probes implementados

| Estratégia | Probe | Método |
|---|---|---|
| `graphql` | Introspecção de schema — verifica se a mutation existe | `gh api graphql -f query='{ __schema { mutationType ... } }'` |
| `rest` | Probe de endpoint — distingue 404 de 405 | `gh api <endpoint>` |
| `gh-cli` | Verifica se subcommand existe (sem --help: falso positivo corrigido) | `gh <subcommand>` + check "unknown command" |
| `browser-automation` | Verifica Playwright importável + `GH_BROWSER_AUTH_STATE` | filesystem check |
| `manual-intervention` | Sempre disponível como último recurso | `true` |

**Correção importante:** `probeGhCLI` inicialmente usava `--help` que retornava exit 0 para subcomandos inválidos (gh CLI cai no parent help). Corrigido para executar sem args e checar "unknown command" no stderr.

### Cache de probes

Probes são cacheados in-process via `Map<string, ProbeOutcome>`. Evita chamadas API redundantes durante uma única execução de provision/doctor. Cache nunca persiste entre execuções.

---

## 2. Probes executados no ambiente real

Resultados no ambiente atual (produtoreativo/payments-api, gh v2.95.0):

| Estratégia | Resultado | Razão |
|---|---|---|
| `graphql` | ❌ indisponível | `createProjectV2View` ausente do schema público da API GraphQL do GitHub (verificado por introspecção — não por suposição) |
| `rest` | ❌ indisponível | Endpoint `/orgs/produtoreativo/projects/24/views` retorna 404 — GitHub Projects v2 não expõe REST para views |
| `gh-cli` | ❌ indisponível | `gh project view-create` não existe em gh v2.95.0 (`unknown command`) |
| `browser-automation` | ❌ indisponível (sessão ausente) | `GH_BROWSER_AUTH_STATE` env var não definida |
| `manual-intervention` | ✅ selecionada | Último recurso |

**Conclusão:** em nenhuma estratégia automatizada está disponível neste ambiente sem `GH_BROWSER_AUTH_STATE`. Todas as 9 views pendentes requerem criação manual.

---

## 3. ProviderMeta evoluído

**Antes (estático):**
```typescript
interface ProviderMeta {
  providerName: string;
  strategyUsed: ProviderStrategy;       // campo único
  alternativeStrategy: ProviderStrategy | null;
  autoCorrectPossible: boolean;
}
```

**Depois (cadeia dinâmica):**
```typescript
interface ProviderMeta {
  providerName: string;
  strategies: ReadonlyArray<ProviderStrategy>;  // cadeia ordenada — Resolver seleciona primeira disponível
  autoCorrectPossible: boolean;
}
```

Funções `primaryStrategy(meta)` e `alternativeStrategy(meta)` preservam compatibilidade com `DriftItem.strategyUsed` e `DriftItem.alternativeStrategy`.

---

## 4. ViewProvider evoluído

**Antes:** declarava `strategyUsed: 'manual-intervention'` como constante — sem resolução dinâmica.

**Depois:** implementa:
- `ensure(owner, projectId, projectNumber, view)` — proba todas as estratégias; idempotente (retorna imediatamente se view existe)
- `validate(projectId, view)` — retorna `ViewValidationResult` com `conformance` tipada
- `list(projectId)` — delega para GraphQL (funciona)

**Cadeia de estratégias do ViewProvider:**
```
graphql → rest → gh-cli → browser-automation → manual-intervention
```

**Extensão futura:** quando o GitHub publicar `createProjectV2View` na API GraphQL, apenas a probe de `graphql` começará a retornar `available: true` — o Resolver selecionará automaticamente. Nenhum outro arquivo precisa ser alterado.

---

## 5. Browser Automation — adapter criado

**Localização:** `runtime/workspace/src/github/views.browser.ts`

Implementa:
- `ensureViewViaBrowser(owner, projectNumber, view)` — cria view via Playwright
- `listViewsViaBrowser(owner, projectNumber)` — lista views via Playwright (para validação)

**Requisitos:**
- Playwright instalado (agora em `dependencies`)
- `GH_BROWSER_AUTH_STATE` env var → path para arquivo de storage state do Playwright
- Gerar auth state: `npx playwright codegen --save-storage=auth.json github.com`

**Segurança:**
- Arquivo de auth state nunca lido ou logado em código
- Credenciais nunca armazenadas no repositório
- `.gitignore` deve incluir `*.playwright-auth.json`
- Falha explícita quando `GH_BROWSER_AUTH_STATE` não está definida

---

## 6. IterationProvider — decisão documentada

**Decisão:** IP-001 usa campo `witem:iteration` do tipo TEXT (não o campo nativo Iteration do GitHub Projects).

**Consequência:** IterationProvider não tem operações ativas. O campo é criado por FieldProvider e preenchido por MembershipProvider. IterationProvider permanece como `manual-intervention` apenas para documentar a decisão e prover ponto de extensão quando o GitHub expuser API para Iteration cycles.

**Não foi criado conceito paralelo.** O FieldProvider existente é reutilizado para o padrão TEXT field do piloto.

---

## 7. workspace.yaml — Views atualizadas

**Views anteriores (7):** Iteration Plan, Delivery Flow, Diligence Flow, Runtime Reconciliation, Findings, Evidence Readiness, Release Scope.

**Views após atualização (15):**

### Existentes (idempotentes) — 6

| View | Layout | Status |
|---|---|---|
| Business Signals | TABLE | ✅ exists — unverifiable |
| All Work Items | TABLE | ✅ exists — unverifiable |
| By Operation | TABLE | ✅ exists — unverifiable |
| Delivery | TABLE | ✅ exists — unverifiable |
| Diligence | TABLE | ✅ exists — unverifiable |
| Workspace Reconciliation | TABLE | ✅ exists — unverifiable |

### Novas do Piloto IP-001 — 9

Source: `prodops/artifacts/product/github-project-template-pilot.md`

| View | Layout | Status | Ação necessária |
|---|---|---|---|
| Business Intent Backlog | TABLE | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Roadmap | TABLE | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Release Backlog | TABLE | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Iteration Backlog | TABLE | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Delivery Board | BOARD | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Delivery Done | TABLE | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Delivery Blocked | TABLE | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Diligence Board | BOARD | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |
| Findings | TABLE | ❌ missing | Manual via UI ou `GH_BROWSER_AUTH_STATE` |

**Reconciliação com o template:** As views acima correspondem às seções de Backlog, Delivery e Diligence do `github-project-template-pilot.md`. Não foi criada View separada por coluna — um Board agrupado por `oem:state` representa o fluxo completo do CI Sync.

---

## 8. Doctor antes e depois

### Doctor ANTES da evolução

O Doctor anterior reportava apenas `missing` com uma mensagem de texto genérica "API does not support createProjectV2View". Não havia:
- Prova por introspecção de qual mutation foi testada
- Registro das estratégias tentadas
- Conformance tipada

### Doctor DEPOIS (resultado real executado)

```
Project   : found (#24)
Milestone : found (#1)
Fields    : 18 configured, 22 extra (informational — campos do GitHub fora do workspace.yaml)
Labels    : 25 configured, 0 drift(s)
Views     : 15 configured, 15 result(s)
Issues    : 10 configured, 0 drift(s)

Blocking Drifts: 9 (todas views — drift-manual-required)
Views Unverifiable: 6 (Business Signals, All Work Items, By Operation, Delivery, Diligence, Workspace Reconciliation)

Trace por view bloqueante:
  skipped: graphql (createProjectV2View absent from public API schema — introspection verified)
           rest (/orgs/produtoreativo/projects/24/views → 404)
           gh-cli (gh project view-create not available in gh v2.95.0)
           browser-automation (GH_BROWSER_AUTH_STATE not set)
  selected: manual-intervention

Exit code: 1 (esperado — 9 blocking drifts pendentes de ação manual)
```

Estados de conformance por view:

| Estado | Significado | Tratamento |
|---|---|---|
| `conformant` | View existe, layout correto, tudo verificável | OK |
| `drift-auto-correctable` | Drift detectado, estratégia automatizável disponível | `workspace provision` corrige |
| `drift-manual-required` | Drift detectado, apenas manual disponível | Ação do operador |
| `unverifiable` | View existe, layout OK, filter/groupBy não verificável via API | **Não tratado como conformant** — sinalizado explicitamente |

### Idempotência comprovada

Segunda execução do Provisioner produz exatamente o mesmo output — zero recursos duplicados:
- Todos os 18 campos: `✓ Field exists`
- Todas as 25 labels: `✓ Label exists`
- Todas as 6 views existentes: `✓ View exists`
- Todos os 10 issues: `✓ Already in project`

---

## 9. Testes — 19 passando, 0 falhas

```bash
npm test && npm run typecheck
# ✅ 2 test files — 19 tests passed — Exit 0
# ✅ typecheck Exit 0
```

| Suite | Testes |
|---|---|
| `resolver.test.ts` | selects graphql first; fallback chain; never silent to manual; records all skipped; manual-only; no probe config; autoCorrect=false for manual |
| `view.provider.test.ts` | idempotency (exists); idempotency (2nd call); manual fallback when no browser; browser-automation when Playwright ready; records skipped before browser; unverifiable for existing+correct; drift-manual-required for missing; drift-auto-correctable when browser available; unverifiable ≠ conformant; IterationProvider text-field pattern; IterationProvider manual-intervention |

---

## 10. Estratégia selecionada por recurso

| Recurso | Estratégia atual | Motivo |
|---|---|---|
| Views (listagem) | `graphql` | `ProjectV2.views` query funciona |
| Views (criação) | `manual-intervention` | Nenhuma das 4 estratégias automatizadas disponível neste ambiente sem `GH_BROWSER_AUTH_STATE` |
| Views (criação com session) | `browser-automation` | Quando `GH_BROWSER_AUTH_STATE` definido e Playwright disponível |
| Iteration (IP-001) | N/A — TEXT field | `witem:iteration` é campo TEXT — gerenciado por FieldProvider + MembershipProvider |

---

## 11. Itens ainda manuais — justificativa técnica comprovada

| Item | Justificativa | Como habilitar automação |
|---|---|---|
| Criação de Views | `createProjectV2View` ausente do schema GraphQL público do GitHub (provado por introspecção). REST 404. CLI `unknown command`. Browser requer sessão autenticada. | Definir `GH_BROWSER_AUTH_STATE` → arquivo gerado por `npx playwright codegen github.com` |
| Criação de Iterations (GitHub nativo) | API GraphQL não expõe mutation para Iteration cycles. Irrelevante para IP-001 que usa campo TEXT. | Aguardar GitHub expor API ou usar campo TEXT existente |

---

## 12. Conformidade com restrições

| Restrição | Status |
|---|---|
| NÃO implementar Delivery, Diligence, Runtime Events | ✅ |
| NÃO alterar OEM, SDK, Event Catalogs, Discovery, Release, Iteration Plan | ✅ |
| NÃO criar outro Workspace Runtime | ✅ — `github/` adapters preservados; Providers são wrappers |
| NÃO duplicar adaptadores GitHub | ✅ — views.browser.ts é novo adapter, não duplica existentes |
| NÃO versionar credenciais, tokens, cookies | ✅ — auth state nunca lido ou logado em código |
| NÃO criar commit | ✅ |
| Typecheck Exit 0 | ✅ |
| npm test: 0 falhas | ✅ — 19 testes |

---

## 13. Confirmação — Piloto pode ser retomado

O Piloto IP-001 pode continuar. O único bloqueador operacional são as 9 Views pendentes:

**Opção A — Browser Automation (recomendada):**
```bash
# Gerar auth state (uma vez, com GitHub já logado no browser):
npx playwright codegen --save-storage=github-auth.json https://github.com/orgs/produtoreativo/projects/24

# Criar as views:
export GH_BROWSER_AUTH_STATE=./github-auth.json
npm run provision

# Confirmar:
npm run doctor
```

**Opção B — Manual via UI:**
- Acessar https://github.com/orgs/produtoreativo/projects/24
- Criar as 9 views pendentes com os layouts especificados no `workspace.yaml`
- Executar `npm run doctor` para confirmar

Após views criadas, Entry Gate da Release pode ser verificado e F-01 (Invoice PIX) pode iniciar.

---

## 14. Rastreabilidade

| Artefato | Localização |
|---|---|
| Strategy Resolver | `runtime/workspace/src/strategies/resolver.ts` |
| Capability Probes | `runtime/workspace/src/strategies/capability-probe.ts` |
| Browser Adapter | `runtime/workspace/src/github/views.browser.ts` |
| ViewProvider evoluído | `runtime/workspace/src/providers/view.provider.ts` |
| IterationProvider revisado | `runtime/workspace/src/providers/iteration.provider.ts` |
| workspace.yaml (15 views) | `runtime/workspace/workspace.yaml` |
| Testes — Resolver | `runtime/workspace/src/strategies/__tests__/resolver.test.ts` |
| Testes — ViewProvider | `runtime/workspace/src/providers/__tests__/view.provider.test.ts` |
| doc-review anterior | `prodops/documentation-review-workspace-management-refactoring.md` |
| GitHub Project #24 | https://github.com/orgs/produtoreativo/projects/24 |
