# Evidence: Workspace Doctor — After Provisioning

**EXP-013 — Phase 1: Environment Preparation**
**Captured:** 2026-07-25
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

Campos extras (informacionais — pertencentes ao projeto pré-existente):
  Reviewers, Parent issue, Sub-issues progress, Created, Updated, Closed,
  Artifact ID, Artifact Type, Operation, Journey, Mode, Owner, Release,
  Evidence Required, Cycle, Phase

[7 × ❌ [view] <nome>]
   fix      : gh api graphql ... createProjectV2View (API não disponível)

── Summary ──────────────────────────────────────────────

  ❌ Workspace has 23 drift(s) — run 'workspace provision' to repair
```

---

## Interpretação dos drifts

| Tipo | Qtd | Severidade real | Explicação |
|---|---|---|---|
| Campos extras | 16 | Informacional (ℹ️) | Campos de configuração anterior do projeto — não são problemas; o workspace.yaml não os gerencia |
| Views ausentes | 7 | API limitation | `createProjectV2View` não existe no schema GraphQL público do GitHub — criação manual necessária |
| Labels drift | 0 | — | Todos os 25 labels estão corretos ✅ |
| Issues drift | 0 | — | Todos os 10 issues existem e estão no projeto ✅ |

## Estado efetivo após provisionamento

| Componente | Configurado | Estado |
|---|---|---|
| Project | ✅ | `ProdOps — payments-api` (#24) |
| Milestone | ✅ | `v0.1.0-runtime-pilot` (#1) |
| 18 Custom Fields COR | ✅ | Todos criados |
| 25 Labels | ✅ | Todos corretos (cor + descrição) |
| 7 Views | ⚠️ | Requerem criação manual em https://github.com/orgs/produtoreativo/projects/24/views/new |
| 10 Issues | ✅ | #66–#75, todos no projeto com milestone correto |

## Conclusão Phase 1

O Workspace Provisioner materializou a COR no GitHub com sucesso.
As únicas pendências são as Views (limitação documentada da API) e
configuração de valores SINGLE_SELECT (requer IDs de opção — tarefa de RT-03).

**Phase 1 — Environment Preparation: CONCLUÍDA.**
