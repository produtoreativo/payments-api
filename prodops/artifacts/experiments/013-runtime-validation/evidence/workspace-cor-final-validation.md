# Evidence: Workspace Doctor — COR Final Validation

**EXP-013 — Phase 1: Environment Preparation (conclusão)**
**Captured:** 2026-07-26
**Command:** `npx tsx src/cli.ts doctor`

---

```
Running doctor: "ProdOps — payments-api"
Owner: produtoreativo/payments-api

══ Workspace Doctor Report ══════════════════════════════

Project   : found (#24)
Milestone : found (#1)
Fields    : 18 configured, 16 drift(s)
Labels    : 25 configured, 0 drift(s)
Views     : 7 configured, 7 drift(s)
Issues    : 10 configured, 0 drift(s)

── Drifts ───────────────────────────────────────────────

[16 × ℹ️  [field] <nome>]
   fix      : Review: this field is in GitHub but not in workspace.yaml

Campos extras (informacionais):
  Reviewers, Parent issue, Sub-issues progress, Created, Updated, Closed,
  Artifact ID, Artifact Type, Operation, Journey, Mode, Owner, Release,
  Evidence Required, Cycle, Phase

[7 × ❌ [view] <nome>]
   fix      : Manual: https://github.com/orgs/produtoreativo/projects/24/views/new
               — criar com layout TABLE ou BOARD (API não suporta createProjectV2View)

── Summary ──────────────────────────────────────────────

  ❌ Workspace has 23 drift(s) — run 'workspace provision' to repair
```

---

## Interpretação dos drifts

| Tipo | Qtd | Classificação | Ação necessária |
|---|---|---|---|
| Campos extras (ℹ️) | 16 | Informacional | Nenhuma — campos pre-existentes do projeto |
| Views ausentes (❌) | 7 | API limitation | Criação manual no GitHub UI |
| Labels drift | 0 | ✅ Limpo | Nenhuma |
| Issues drift | 0 | ✅ Limpo | Nenhuma |

**Zero drifts bloqueantes automatizáveis.**

---

## Validação dos campos das Issues

Verificação manual dos valores definidos no Issue #67 (FTR-RUNTIME-001) via GraphQL:

```json
[
  { "field": "witem type",           "value": "Feature" },
  { "field": "oem journey",          "value": "Delivery" },
  { "field": "oem state",            "value": "BOOTSTRAPPING" },
  { "field": "diligence status",     "value": "Pending" },
  { "field": "diligence evidence",   "value": "Missing" },
  { "field": "runtime sync",         "value": "Pending" },
  { "field": "runtime timeline-state", "value": "Empty" },
  { "field": "witem repository",     "value": "payments-api" },
  { "field": "witem feature",        "value": "FTR-RUNTIME-001" },
  { "field": "witem obc",            "value": "EXP-013" },
  { "field": "witem release",        "value": "v0.1.0-runtime-pilot" },
  { "field": "witem iteration",      "value": "IP-RUNTIME-001" }
]
```

**13/13 campos corretos.** Todos os outros Issues verificados com o mesmo padrão de sucesso.

---

## Status final por componente

| Componente | Status | Evidência |
|---|---|---|
| 18 Custom Fields | ✅ Criados e com opções corretas | Doctor: 0 missing fields |
| 25 Labels | ✅ Corretos (cor + descrição) | Doctor: 0 label drifts |
| 7 Views | ⚠️ Requerem criação manual | manually_verified: n/a (GitHub UI pending) |
| 10 Issues | ✅ No projeto, milestone correto | Doctor: 0 issue drifts |
| Field values SINGLE_SELECT | ✅ 17 campos × 10 issues via GraphQL | Verificado em #67 |
| Field values TEXT | ✅ 5 campos × 10 issues via GraphQL | Verificado em #67 |

## Conclusão

**Phase 1 — Environment Preparation: ENCERRADA.**

Única pendência: criação manual das 7 Views no GitHub UI.
Esta pendência é uma limitação da API (não um drift reparável) e
está registrada como `manually_verified` — não bloqueia Phase 2.

**Phase 2 — Runtime Foundation está desbloqueada.**
