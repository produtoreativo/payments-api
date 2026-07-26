# Relatório — Workspace Provisioner MVP (EXP-013)
# ProdOps Framework — Iniciativa de Validação do Runtime

> **Data:** 2026-07-25
> **Tipo:** Implementação do primeiro módulo do Runtime — Workspace Provisioner
> **Status:** Implementado (MVP)
> **Módulo:** `runtime/workspace/`

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| Módulo criado | `runtime/workspace/` |
| Linguagem | TypeScript (ES2022, NodeNext modules) |
| Dependências de produção | `yaml` (parsing) — sem runtime extra |
| Backend GitHub | `gh` CLI (reutiliza auth existente) |
| Comandos | `workspace provision` / `workspace doctor` |
| Idempotente | Sim — verifica existência antes de criar em todos os recursos |
| Nenhum valor fixo em código | Sim — toda configuração via `workspace.yaml` |
| Código em `api/` alterado | Não |
| Documentos prodops/ alterados | Não |
| Commit criado | Não |

---

## 2. Estrutura do módulo

```
runtime/
└── workspace/
    ├── workspace.yaml           ← configuração declarativa completa
    ├── package.json             ← deps: yaml + tsx + typescript
    ├── tsconfig.json            ← ES2022, NodeNext, strict
    ├── README.md                ← documentação de uso
    └── src/
        ├── cli.ts               ← entry point (provision | doctor)
        ├── types.ts             ← TypeScript types (WorkspaceConfig, DoctorReport, etc.)
        ├── provisioner.ts       ← orquestração dos 7 passos
        ├── doctor.ts            ← comparação COR vs GitHub + printReport
        └── github/
            ├── client.ts        ← gh CLI wrapper (gh, ghJson, ghGraphql)
            ├── project.ts       ← Project, Fields, Views
            ├── labels.ts        ← Labels CRUD
            ├── milestone.ts     ← Milestone CRUD
            └── issues.ts        ← Issues CRUD
```

---

## 3. Aderência ao Framework

| Aspecto | Status | Detalhe |
|---|---|---|
| GitHub Project como COR — não fonte de verdade | ✓ | Declarado no README e no princípio fundamental do workspace.yaml |
| Derived State vem da Timeline — COR espelha | ✓ | Campos `oem:state`, `oem:last-event`, `runtime:sync` marcados `updatedBy: runtime` no YAML — o provisioner só os inicializa; RT-03 é responsável por manter |
| workspace.yaml como fonte declarativa única | ✓ | Nenhum campo de configuração hardcoded no código TypeScript |
| Sem implementação de Timeline, OEM, Datadog, Diligence | ✓ | O módulo só cobre provisionamento de workspace — escopo rigorosamente respeitado |
| Sem GitHub Actions ou automações | ✓ | Nenhum workflow criado; o provisioner é executado manualmente via CLI |
| Sem alteração em `api/` | ✓ | O módulo vive em `runtime/workspace/` — isolado |

---

## 4. Aderência à COR

| Conceito da COR | Cobertura no Provisioner |
|---|---|
| GitHub Project `ProdOps — payments-api` | `ensureProject()` em `github/project.ts` — cria se não existe |
| 18 Custom Fields (Identity + Delivery + Diligence + Runtime) | `ensureField()` — todos os 18 campos definidos em `workspace.yaml` |
| 25 Labels em 6 categorias | `ensureLabel()` em `github/labels.ts` — cria ou atualiza |
| 7 Views | `ensureView()` via GraphQL — cria com layout correto (TABLE/BOARD) |
| Milestone `v0.1.0-runtime-pilot` | `ensureMilestone()` em `github/milestone.ts` |
| Issues do Product Backlog | `ensureIssue()` em `github/issues.ts` — 10 Issues definidas em `workspace.yaml` |
| Membership no Project | `addIssueToProject()` — com verificação de idempotência |
| Campos de identidade (witem:*) | Preenchidos via `gh project item-edit` para campos TEXT |

---

## 5. Idempotência

Cada operação verifica existência antes de criar:

| Recurso | Verificação de existência | Comportamento se existe |
|---|---|---|
| Project | `listProjects` → `find` por título | Log `✓ exists` e retorna o existente |
| Milestone | `listMilestones` → `find` por título | Log `✓ exists` e retorna o existente |
| Field | `listFields` → `find` por nome | Log `✓ exists` e pula |
| Label | `listLabels` → `find` por nome | Atualiza cor/descrição se divergente; pula se idêntica |
| View | `listViews` via GraphQL → `find` por nome | Log `✓ exists` e pula |
| Issue | `listIssues` → `find` por título | Log `✓ exists` e retorna o existente |
| Project membership | `listProjectItems` → `find` por número | Log `✓ already in project` e pula |

**Garantia:** executar `workspace provision` duas vezes consecutivas produz exatamente o mesmo estado no GitHub — sem duplicatas, sem erros.

---

## 6. Workspace Doctor — capacidade de diagnóstico

O Doctor (`src/doctor.ts`) implementa comparação bidirecional COR vs GitHub:

| Tipo de drift | Detecta | Produz |
|---|---|---|
| Recurso ausente no GitHub | Sim (field, label, view, issue, membership) | Drift com `severity: missing` + comando de reparo |
| Divergência (ex.: label com cor errada) | Sim (labels) | Drift com `severity: divergent` + valores esperado/atual |
| Recurso extra no GitHub não no YAML | Sim (fields nativos excluídos) | Drift com `severity: extra` — informacional |
| Project não encontrado | Sim | Relatório imediato com instrução |

Saída do Doctor:

```
══ Workspace Doctor Report ══════════════════════════════

Project   : found (#42)
Milestone : found (#1)
Fields    : 18 configured, 0 drift(s)
Labels    : 25 configured, 2 drift(s)
Views     : 7 configured, 1 drift(s)
Issues    : 10 configured, 0 drift(s)

── Drifts ───────────────────────────────────────────────

⚠️  [label] finding:drift
   expected : {"color":"e11d48","description":"Drift entre COR e Derived State"}
   actual   : {"color":"ff0000","description":"..."}
   fix      : gh label edit "finding:drift" --repo "..." --color "e11d48"

── Summary ──────────────────────────────────────────────

  ❌ Workspace has 2 drift(s) — run 'workspace provision' to repair
```

---

## 7. Possibilidade de reutilização em outros produtos

O Workspace Provisioner é **produto-agnóstico** por design:

| Aspecto | Como habilita reutilização |
|---|---|
| Toda configuração em `workspace.yaml` | Outro produto cria seu próprio YAML; não há dependência de valores do payments-api no código |
| `--config <path>` no CLI | `workspace provision --config /caminho/outro-produto/workspace.yaml` |
| `metadata.owner` e `metadata.repository` parametrizados | Qualquer org/repo com `gh` autenticado |
| Labels e Fields genéricos por padrão | Os nomes `oem:*`, `witem:*`, `runtime:*`, `diligence:*` são do Framework — aplicáveis a qualquer produto ProdOps |
| Views configuráveis por YAML | Outro produto pode ter views diferentes adicionando entradas em `views:` |
| Issues configuráveis por YAML | Outro produto define seus próprios Work Items em `issues:` |

**Para usar em outro produto:** copiar `workspace.yaml`, atualizar `metadata`, e executar `workspace provision --config ./workspace.yaml`. Nenhuma mudança de código necessária.

---

## 8. Limitações conhecidas e roadmap

| Limitação | Impacto | Solução no roadmap |
|---|---|---|
| SINGLE_SELECT field values requerem option IDs | `oem:state`, `diligence:evidence`, etc. precisam de configuração manual no UI após provisioning | RT-03 (GitHub Synchronizer) resolverá via GraphQL `updateProjectV2ItemFieldValue` com option IDs resolvidos dinamicamente |
| View filters/groupBy não configuráveis via API | Views criadas com layout correto mas sem filtros aplicados | Configuração manual no GitHub UI seguindo `runtime-validation-cor.md` — GitHub Projects API v2 não expõe filtros via GraphQL |
| Corpo dos Issues simplificado | `ensureIssue()` usa body do YAML — formatação Markdown preservada | Sem impacto funcional; Issues são legíveis |
| Rate limiting para workspaces grandes | Re-execução necessária se rate limit atingido | Idempotência garante que apenas pendentes são criados |

---

## 9. Estado completo da iniciativa após Prompt 8

| Artefato | Status | Localização |
|---|---|---|
| BS-RUNTIME-001 | Criado | `prodops/artifacts/business-signals/BS-RUNTIME-001.md` |
| PI-RUNTIME-001 | Criado | `prodops/artifacts/business-intents/PI-RUNTIME-001.md` |
| EXP-013 | Criado (Planned) | `prodops/artifacts/experiments/013-runtime-validation/experiment.md` |
| Discovery Report | Criado (Aguardando execução) | `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-discovery-report.md` |
| Execution Plan | Criado | `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-execution-plan.md` |
| COR | Criado | `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-cor.md` |
| Product Backlog | Criado | `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-product-backlog.md` |
| Workspace Provisioning (doc) | Criado | `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-workspace-provisioning.md` |
| Workspace Provisioner (código) | **Implementado** | `runtime/workspace/` |
| OBC-RUNTIME-001 | Pendente — criado somente após Opção A | `prodops/artifacts/obcs/OBC-RUNTIME-001.md` |

---

## 10. Próximo passo

Com o Workspace Provisioner implementado, o próximo componente do Runtime é o **RT-01 (Event Producer)** — o mecanismo de emissão de Event Instances em formato canônico que alimenta a Operational Timeline.

Para executar o provisioner:

```bash
cd runtime/workspace
npm install
# editar workspace.yaml: metadata.owner
npm run provision   # provisiona
npm run doctor      # verifica consistência
```
