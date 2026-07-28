# Relatório — Execução e Validação do Workspace Provisioning (EXP-013)
# ProdOps Framework — Phase 1: Environment Preparation

> **Data:** 2026-07-25
> **Tipo:** Execução do Workspace Provisioner contra `produtoreativo/payments-api`
> **Status:** Concluído — Phase 1 finalizada
> **Experimento:** EXP-013

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| Project GitHub encontrado | ✅ `ProdOps — payments-api` (#24) |
| Milestone criado | ✅ `v0.1.0-runtime-pilot` (#1) |
| Custom Fields (18) | ✅ Todos criados e confirmados |
| Labels (25) | ✅ Todos corretos (cor + descrição) |
| Views (7) | ⚠️ Requerem criação manual (API limitation) |
| Issues (10) | ✅ #66–#75, todos no projeto |
| Idempotência | ✅ Segunda execução: zero criações |
| Doctor after | ✅ 0 labels drift, 0 issues drift |
| Bugs resolvidos | 4 (listados abaixo) |
| EXP-013 status | Atualizado: `Planned` → `In Progress` |

---

## 2. Bugs descobertos e corrigidos durante execução real

A execução contra o repositório real revelou 4 bugs não detectáveis via typecheck:

### Bug 1 — `listFields` com limit default truncando campos

**Erro:** `gh project field-list` tem default `--limit 30`. O projeto já tinha 30 campos pré-existentes. Campos criados apareciam como "Name has already been taken" mas não apareciam na listagem.

**Correção:** `project.ts:listFields` → adicionado `--limit 100`.

**Impacto COR:** Sem essa correção, campos novos seriam criados cegamente sem verificação de existência, violando a idempotência.

---

### Bug 2 — Rate limiting por N chamadas `listFields`

**Erro:** `ensureField` chamava `listFields` internamente para cada campo (18 chamadas sequenciais). Com `--limit 100` aumentando o volume de dados por chamada, o GitHub retornou `GraphQL: API rate limit exceeded`.

**Correção:** `ensureField` agora aceita `existingNames?: Set<string>`. `provisioner.ts` chama `listFields` uma única vez antes do loop e passa o conjunto.

**Impacto COR:** Provisioner agora é executável sem rate limiting para qualquer workspace dentro da escala esperada.

---

### Bug 3 — `createProjectV2View` ausente no schema GraphQL público

**Erro:** `gh: Field 'createProjectV2View' doesn't exist on type 'Mutation'`. A mutation não existe no schema público do GitHub GraphQL API.

**Correção:** `ensureView` reformulada para logar instrução de criação manual em vez de tentar a chamada API.

**Impacto COR:** Views são a única categoria de recursos COR que requerem intervenção manual. Documentado como limitação conhecida da API. RT-03 poderá atualizar campos de views via outros mecanismos.

---

### Bug 4 — `gh issue create --milestone` rejeita número

**Erro:** `could not add to milestone '1': '1' not found`. O flag `--milestone` aceita o nome, não o número.

**Correção:** `issues.ts:ensureIssue` — parâmetro renomeado de `milestoneNumber: number` para `milestoneTitle: string`; `provisioner.ts` passa `milestone.title`.

---

## 3. Estado do GitHub após provisionamento

### 3.1 Custom Fields (18/18)

| Categoria | Fields | Status |
|---|---|---|
| Identity | witem type, witem repository, witem feature, witem obc, witem release, witem iteration | ✅ |
| Delivery | oem journey, oem cycle, oem phase, oem state, oem rework-count, oem blocked-since, oem last-event | ✅ |
| Diligence | diligence status, diligence evidence | ✅ |
| Runtime | runtime sync, runtime timeline-state, runtime last-sync | ✅ |

**Nota COR:** Campos SINGLE_SELECT (oem state, oem cycle, etc.) requerem configuração dos valores via GitHub UI — option IDs são project-specific e não podem ser definidos via `gh project field-create`. Este é o escopo de RT-03.

### 3.2 Labels (25/25)

Todos criados com cor e descrição canônicas conforme `workspace.yaml`.

| Categoria | Qtd |
|---|---|
| journey:* | 3 |
| phase:* | 7 |
| runtime:* | 4 |
| severity:* | 3 |
| finding:* | 5 |
| evidence:* | 3 |

### 3.3 Views (0/7 — manual)

Todos os 7 views precisam ser criados manualmente em:
`https://github.com/orgs/produtoreativo/projects/24/views/new`

| View | Layout | groupBy |
|---|---|---|
| Iteration Plan | TABLE | witem type |
| Delivery Flow | BOARD | oem state |
| Diligence Flow | BOARD | diligence status |
| Runtime Reconciliation | TABLE | runtime sync |
| Findings | TABLE | witem type |
| Evidence Readiness | BOARD | diligence evidence |
| Release Scope | TABLE | witem type |

### 3.4 Issues (10/10)

| Issue | # | Milestone | No projeto |
|---|---|---|---|
| EPIC: ProdOps Runtime MVP | #66 | ✅ | ✅ |
| FTR-RUNTIME-001 | #67 | ✅ | ✅ |
| FTR-RUNTIME-002 | #68 | ✅ | ✅ |
| FTR-RUNTIME-003 | #69 | ✅ | ✅ |
| RT-01 | #70 | ✅ | ✅ |
| RT-02 | #71 | ✅ | ✅ |
| RT-03 | #72 | ✅ | ✅ |
| RT-04 | #73 | ✅ | ✅ |
| RT-05 | #74 | ✅ | ✅ |
| RT-06 | #75 | ✅ | ✅ |

---

## 4. Validação de idempotência

Segunda execução (`npm run provision`) produziu:
- **0** campos criados (18/18 `✓ Field exists`)
- **0** labels criadas/atualizadas (25/25 `✓ Label exists`)
- **0** issues criados (10/10 `✓ Issue exists`)
- **0** project memberships adicionados (10/10 `✓ Already in project`)

**Conclusão:** Idempotência confirmada — o provisioner pode ser re-executado seguramente a qualquer momento.

---

## 5. Doctor Report — interpretação

```
Fields    : 18 configured, 16 drift(s)   ← todos informacionais (ℹ️)
Labels    : 25 configured, 0 drift(s)    ← ✅ limpo
Views     : 7 configured, 7 drift(s)     ← ❌ limitação de API (criação manual)
Issues    : 10 configured, 0 drift(s)    ← ✅ limpo
```

Os 16 "drifts" de campos são campos extra do projeto pré-existente
(Artifact ID, Journey, Cycle, Phase, etc.) — informacionais, não problemáticos.

**Doctor efetivo após provisionamento: limpo para labels e issues.**

---

## 6. Limitações descobertas durante execução

| Limitação | Origem | Impacto | Workaround |
|---|---|---|---|
| `createProjectV2View` ausente na API pública | GitHub GraphQL schema | 7 views não automatizáveis | Criação manual no GitHub UI |
| SINGLE_SELECT field values requerem option IDs | GitHub Projects v2 | Valores de oem:state, etc. não configuráveis via CLI | RT-03 usa GraphQL `updateProjectV2ItemFieldValue` com IDs resolvidos |
| Rate limit com N chamadas sequenciais | GitHub GraphQL 5000 req/h | Provisioning interrompido durante desenvolvimento | Refatoração para 1 chamada listFields por step |
| `gh project field-list --limit` default 30 | gh CLI | Campos > 30 invisíveis para verificação de existência | `--limit 100` aplicado |

---

## 7. Critérios de Phase 1 — checklist final

| Critério | Status |
|---|---|
| Projeto GitHub criado/encontrado | ✅ |
| Milestone `v0.1.0-runtime-pilot` existe | ✅ |
| 18 Custom Fields COR criados | ✅ |
| 25 Labels com taxonomia canônica | ✅ |
| 10 Issues no backlog e no projeto | ✅ |
| Doctor confirma 0 drifts críticos | ✅ (apenas informacionais + API limitation) |
| Idempotência validada | ✅ |
| EXP-013 status atualizado | ✅ (`In Progress`) |
| Evidence files criados | ✅ (4 arquivos em `evidence/`) |
| Provisioner typecheck limpo | ✅ (`tsc --noEmit` Exit: 0) |

**Phase 1 — Environment Preparation: CONCLUÍDA.**

---

## 8. Próximas etapas

Com Phase 1 concluída, o EXP-013 avança para:

**Phase 2 — Runtime Foundation** (RT-01 + RT-02):
- RT-01: implementar Event Producer (emissão de Event Instances OEM)
- RT-02: implementar Timeline Processor (Derived State + Lookback)
- Primeiro evento emitido e registrado em `evidence/timelines/`

**Pendências manuais antes de Phase 2:**
1. Criar as 7 Views no GitHub UI (`https://github.com/orgs/produtoreativo/projects/24/views/new`)
2. Configurar valores SINGLE_SELECT dos campos COR no GitHub UI
   (oem:state, oem:cycle, oem:phase, diligence:status, diligence:evidence, runtime:sync, runtime:timeline-state)

---

## 9. Artefatos criados nesta execução

| Artefato | Localização |
|---|---|
| Evidence: Doctor before | `evidence/workspace-doctor-before.md` |
| Evidence: Provision run | `evidence/workspace-provision-run.md` |
| Evidence: Idempotência | `evidence/workspace-idempotency.md` |
| Evidence: Doctor after | `evidence/workspace-doctor-after.md` |
| Este documento | `prodops/documentation-review-runtime-workspace-execution.md` |
| EXP-013 status | Atualizado para `In Progress` |
| `runtime/workspace/src/github/project.ts` | Corrigido: `--limit 100`, `ensureField` refatorado, `ensureView` degradada graciosamente |
| `runtime/workspace/src/github/issues.ts` | Corrigido: milestone por título |
| `runtime/workspace/src/provisioner.ts` | Refatorado: `listFields` chamada única, `milestone.title` |
