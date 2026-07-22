---
name: diligence/workspace-reconciliation/inspect
description: Read the Canonical Specification and the Actual Workspace state via GitHub API. Produce a Drift Report. Does not create or update anything.
---

# WORKSPACE RECONCILIATION → INSPECT

Execute only the Inspect step of the Workspace Reconciliation capability.

**Responsabilidade:** comparar a Canonical Specification com o Actual Workspace. Inspect não cria nem atualiza nada — produz um Drift Report completo para que Reconcile possa agir.

**Dois projetos gerenciados a verificar:**
- `ProdOps — template` — template canônico da org (source para cópias)
- `ProdOps — <repo-name>` — projeto gerenciado do repositório atual

## Ação

### 0. Ler o sync manifest e a Canonical Specification

```bash
cat prodops/artifacts/governance/github-sync-manifest.md
cat prodops/framework/github-workspace.md
```

Usar o manifest como contexto de execuções anteriores. Não assumir que está atualizado — verificar via API em todos os steps.

### 1. Verificar Labels

```bash
gh label list --repo <owner>/<repo> --json name,color,description --limit 200
```

Ler spec em `prodops/framework/github-workspace.md` seção Labels. Para cada label canônica verificar:
- Existe no repositório?
- Cor corresponde à spec (sem `#`)?
- Descrição corresponde à spec?

Registrar: `LABEL AUSENTE`, `LABEL DIVERGENTE (cor)`, `LABEL DIVERGENTE (descrição)`.

### 2. Verificar Milestones

```bash
gh api /repos/<owner>/<repo>/milestones --jq '[.[] | {title, state, due_on}]'
```

Comparar com OBCs que têm release definida no Iteration Plan. Para cada Milestone ausente:

Registrar: `MILESTONE AUSENTE: <título> — dono: Product Owner`.

### 3. Verificar template canônico da org

Buscar pelo nome exato `ProdOps — template`:

```bash
gh project list --owner <owner> --format json \
  | jq '.projects[] | select(.title == "ProdOps — template") | {number, title, id}'
```

**Se não encontrado:** registrar `TEMPLATE AUSENTE`. O Reconcile criará e configurará.

**Se encontrado:** verificar visibilidade, campos e mark-template:

```bash
# Visibilidade
gh project list --owner <owner> --format json \
  | jq '.projects[] | select(.title == "ProdOps — template") | {number, public}'

# Campos canônicos
gh project field-list <template-number> --owner <owner> --format json \
  | jq '.fields[] | {name, type}'
```

Registrar: `TEMPLATE PRIVADO` se `public: false`.
Registrar: `TEMPLATE FIELD AUSENTE: <nome> (<tipo>)` para cada campo ausente.

### 4. Verificar projeto gerenciado do repositório

Buscar pelo nome `ProdOps — <repo-name>`:

```bash
gh project list --owner <owner> --format json \
  | jq '.projects[] | select(.title == "ProdOps — <repo-name>") | {number, title, id}'
```

**Se não encontrado:** registrar `PROJETO GERENCIADO AUSENTE`. O Reconcile criará via cópia do template.
Não continuar para campos e views.

**Se encontrado:** verificar visibilidade e campos canônicos:

```bash
gh project list --owner <owner> --format json \
  | jq '.projects[] | select(.title == "ProdOps — <repo-name>") | {number, public}'
```

Registrar: `GERENCIADO PRIVADO` se `public: false`.

```bash
gh project field-list <managed-number> --owner <owner> --format json \
  | jq '.fields[] | {name, type}'
```

Registrar: `FIELD AUSENTE`, `FIELD DIVERGENTE (tipo)`, `FIELD AUSENTE (CHECKBOX — limitação de API)`.

Verificar views via GraphQL:

```bash
gh api graphql -f query='
{
  organization(login: "<owner>") {
    projectV2(number: <managed-number>) {
      views(first: 20) { nodes { id name } }
    }
  }
}'
```

Registrar: `VIEW AUSENTE: <nome>`, `VIEW DIVERGENTE: encontrada "<atual>", esperado "<canônico>"`.

> Projetos com outros nomes são projetos manuais — ignorar completamente. Nunca reportar como Workspace Drift.

### 5. Verificar Issues de infraestrutura abertos

```bash
gh issue list --repo <owner>/<repo> \
  --label "operation:provision,journey:diligence" \
  --state open \
  --json number,title
```

Usar os números para anotar o Drift Report: gaps com Issue aberto incluem `(Issue #X)` — Reconcile não criará duplicata.

### 6. Produzir Drift Report consolidado

```
=== DRIFT REPORT — <data> ===

LABELS (<N> ausentes, <N> divergentes):
  LABEL AUSENTE:          operation:capture
  LABEL DIVERGENTE:       journey:delivery — cor atual #abc123, esperado #d93f0b

MILESTONES (<N> ausentes):
  MILESTONE AUSENTE:      v1.2 — OBC create-invoice tem release v1.2 no Iteration Plan

TEMPLATE (ProdOps — template):
  ✅ encontrado — #<N> (id: PVT_...)
  ⚠️ TEMPLATE AUSENTE — Reconcile criará e configurará
  TEMPLATE FIELD AUSENTE: Artifact Type (SINGLE_SELECT)

PROJETO GERENCIADO (ProdOps — payments-api):
  ✅ encontrado — #<N> (id: PVT_...)
  ⚠️ PROJETO GERENCIADO AUSENTE — Reconcile copiará do template
  FIELD AUSENTE:          Evidence Required (CHECKBOX) (Issue #57 já aberto)
  VIEW AUSENTE:           All Work Items — API impossível, criar no template (Issue #58 aberto)
  VIEW AUSENTE:           Diligence — API impossível, criar no template (Reconcile abrirá Issue)

PROJETOS MANUAIS IGNORADOS: "Turma Junho 2026" (#22), "Sprint Junho" (#17)
```

## Post-conditions

Concluído quando **todos** os itens abaixo são verdadeiros:

- Labels verificadas contra a Canonical Specification completa
- Milestones verificados contra OBCs com release no Iteration Plan
- Template `ProdOps — template` verificado (existência + campos)
- Projeto gerenciado `ProdOps — <repo-name>` verificado (existência + campos + views)
- Projetos manuais ignorados listados explicitamente no Drift Report
- Issues de infraestrutura abertos anotados no Drift Report

## Guardrails

- **Identificar projetos por nome exato, nunca por número.**
- **Nunca operar em projetos manuais** — qualquer projeto sem o prefixo `ProdOps — ` é ignorado.
- Não criar nem atualizar nada neste step.
- Verificar template antes do projeto gerenciado — o estado do template determina se a cópia é viável.
- Se o template não existir: registrar e avançar — Reconcile cuida da criação.
- Se o projeto gerenciado não existir: registrar e não tentar verificar campos/views.

## Out of scope

- `inspect` **não** cria nem atualiza nada — isso é Reconcile.
- `inspect` **não** remove labels extras — remoção requer confirmação explícita.
- `inspect` **não** verifica Issues individuais — isso é Scan (Diligence Async).
- `inspect` **não** atualiza o sync manifest — isso é Verify.
