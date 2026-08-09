---
name: diligence/workspace-reconciliation/reconcile
description: Create or update Labels, Template project, and Managed project to match the Canonical Specification. Tries every API path. On API failure, creates a tracking Issue. Never leaves a gap without a trail entry. Never touches manual projects. Idempotent.
---

# WORKSPACE RECONCILIATION → RECONCILE

Execute only the Reconcile step of the Workspace Reconciliation capability.

**Responsabilidade:** executar o que pode ser automatizado e, para o que não puder, registrar um Issue de rastreamento. Nunca termina sem declarar o status de todas as categorias. É idempotente — pode ser re-executado sem efeitos colaterais.

**Princípio:** nenhum gap sem Issue de rastreamento. Nenhuma instrução flutuante — a instrução para o humano vai no corpo do Issue.

**Ordem de execução obrigatória:** Labels → Template → Projeto Gerenciado → Milestones. O projeto gerenciado depende do template — nunca inverter.

## Ação

### 1. Ler o Drift Report do Inspect

Obter o Drift Report produzido pelo step Inspect. Se Inspect não foi executado neste ciclo, executá-lo primeiro.

### 2. Labels — criar ausentes e corrigir divergentes

Para cada `LABEL AUSENTE`, criar em ordem: família `operation:` → `artifact-type:` → `journey:`:

```bash
gh label create "<nome>" \
  --repo <owner>/<repo> \
  --color "<cor-sem-hash>" \
  --description "<descrição>"
```

Para cada `LABEL DIVERGENTE`:

```bash
gh label edit "<nome>" \
  --repo <owner>/<repo> \
  --color "<cor-correta>" \
  --description "<descrição-correta>"
```

### 3. Template canônico — criar, configurar e marcar

#### 3a. Se `TEMPLATE AUSENTE` no Drift Report — criar projeto vazio e tornar público

```bash
NUMBER=$(gh project create \
  --owner <owner> \
  --title "ProdOps — template" \
  --format json | jq '.number')

# PUBLIC por default — privado somente com diretiva explícita
gh project edit $NUMBER --owner <owner> --visibility PUBLIC
```

Registrar o número retornado para os próximos sub-steps.

Se `TEMPLATE PRIVADO` no Drift Report (projeto existe mas está privado):

```bash
gh project edit <template-number> --owner <owner> --visibility PUBLIC
```

#### 3b. Provisionar campos canônicos no template

Para cada campo canônico ausente no template (seja recém-criado ou desatualizado):

**Prioridade 1 — CLI:**

```bash
gh project field-create <template-number> \
  --owner <owner> \
  --name "<nome>" \
  --data-type "<TEXT|SINGLE_SELECT|NUMBER|DATE|ITERATION>"
```

**Prioridade 2 — GraphQL `createProjectV2Field` (fallback):**

```bash
gh api graphql -f query='
  mutation {
    createProjectV2Field(input: {
      projectId: "<template-id>"
      dataType: <TEXT|SINGLE_SELECT|NUMBER|DATE|ITERATION>
      name: "<nome>"
    }) { projectV2Field { ... on ProjectV2Field { id name dataType } } }
  }'
```

**Prioridade 3 — Verificar enum antes de desistir:**

```bash
gh api graphql -f query='{ __type(name: "ProjectV2CustomFieldType") { enumValues { name } } }'
```

Se o tipo necessário aparecer no enum: re-tentar com Prioridade 2.

**Para `Evidence Required`:** criar como SINGLE_SELECT com opção `Required` (color: RED):

```bash
gh api graphql -f query='
  mutation {
    createProjectV2Field(input: {
      projectId: "<project-id>"
      dataType: SINGLE_SELECT
      name: "Evidence Required"
      singleSelectOptions: [{ name: "Required", color: RED, description: "Evidence is required (true)" }]
    }) { projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } } }
  }'
```

> **Decisão GitOps (2026-07-22):** CHECKBOX não está no enum `ProjectV2CustomFieldType`. Adotado SINGLE_SELECT como fallback permanente até a API evoluir. Campo vazio = false; `Required` = true. Modelo conceitual do ProdOps inalterado. Ver Issue #57 (fechado) para justificativa completa.
>
> Monitorar: `gh api graphql -f query='{ __type(name: "ProjectV2CustomFieldType") { enumValues { name } } }'` — se CHECKBOX aparecer no enum, migrar.

#### 3c. Marcar o template como template

```bash
gh project mark-template <template-number> --owner <owner>
```

Se o comando não existir ou falhar:

```bash
gh api graphql -f query='
  mutation {
    markProjectV2AsTemplate(input: { projectId: "<template-id>" }) {
      projectV2 { id title }
    }
  }' 2>&1
```

Se ambos falharem: registrar como nota no manifest — não cria Issue (é informativo, não bloqueia a cópia).

#### 3d. Views no template — criar via REST API

> **Verificado 2026-07-22:** views são criáveis via REST `POST /orgs/{org}/projectsV2/{N}/views`. Endpoint correto: `projectsV2` (não `projects`). GraphQL não tem mutation equivalente.

Para cada view canônica ausente no template:

```bash
curl -s -X POST \
  "https://api.github.com/orgs/<owner>/projectsV2/<template-number>/views" \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  -d '{"name": "<nome>", "layout": "table", "filter": "<filtro-ou-omitir>"}'
```

Views canônicas a criar no template:

```bash
TOKEN=$(gh auth token)
N=<template-number>

# All Work Items (sem filtro)
curl -s -X POST "https://api.github.com/orgs/<owner>/projectsV2/$N/views" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  -d '{"name":"All Work Items","layout":"table"}'

# By Operation (sem filtro)
curl -s -X POST "https://api.github.com/orgs/<owner>/projectsV2/$N/views" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  -d '{"name":"By Operation","layout":"table"}'

# Business Signals
curl -s -X POST "https://api.github.com/orgs/<owner>/projectsV2/$N/views" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  -d '{"name":"Business Signals","layout":"table","filter":"label:artifact-type:business-signal"}'

# Delivery
curl -s -X POST "https://api.github.com/orgs/<owner>/projectsV2/$N/views" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  -d '{"name":"Delivery","layout":"table","filter":"label:journey:delivery"}'

# Diligence
curl -s -X POST "https://api.github.com/orgs/<owner>/projectsV2/$N/views" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  -d '{"name":"Diligence","layout":"table","filter":"label:journey:diligence"}'
```

**`group_by`:** Known Platform Limitation — GitHub API não suporta configuração de `group_by` em views (REST PATCH retorna 404, GraphQL sem mutation existente). Registrar no Conformance Report em "Known Platform Limitations". Automation Opportunity: configuração pode ser realizada via Browser Automation — registrar em "Automation Opportunities" e solicitar autorização ao usuário antes de executar. Nunca instruir o usuário a configurar manualmente. Ver Princípio 8 — [Automation First](../../../../../framework/automation-first.md).

### 4. Projeto gerenciado — criar via cópia ou provisionar campos ausentes

#### 4a. Se `PROJETO GERENCIADO AUSENTE` — copiar do template e tornar público

**Pré-requisito:** o template deve existir (step 3 concluído).

```bash
NUMBER=$(gh project copy <template-number> \
  --source-owner <owner> \
  --target-owner <owner> \
  --title "ProdOps — <repo-name>" \
  --format json | jq '.number')

# PUBLIC por default — gh project copy herda visibilidade do source, verificar e forçar
gh project edit $NUMBER --owner <owner> --visibility PUBLIC
```

Registrar o número retornado no sync manifest.

**Obrigatório após copy — vincular o projeto ao repositório:**

> `gh project copy` copia campos e views, mas **não** vincula o projeto ao repositório. O vínculo deve ser criado explicitamente via GraphQL.

```bash
# Obter IDs do projeto recém-criado e do repositório
PROJECT_ID=$(gh api graphql -f query='
  { organization(login: "<owner>") { projectV2(number: '"$NUMBER"') { id } } }
' --jq '.data.organization.projectV2.id')

REPO_ID=$(gh api graphql -f query='
  { repository(owner: "<owner>", name: "<repo-name>") { id } }
' --jq '.data.repository.id')

# Vincular
gh api graphql -f query='
  mutation {
    linkProjectV2ToRepository(input: {
      projectId: "'"$PROJECT_ID"'"
      repositoryId: "'"$REPO_ID"'"
    }) {
      repository { nameWithOwner }
    }
  }'
```

Verificar vínculo após criação:
```bash
gh api graphql -f query='
  { organization(login: "<owner>") {
      projectV2(number: '"$NUMBER"') {
        repositories(first: 5) { nodes { nameWithOwner } }
      }
  }}'
```

Registrar no sync manifest: `Repo link: <owner>/<repo-name> ✅`.

Se `GERENCIADO PRIVADO` no Drift Report (projeto existe mas está privado):

```bash
gh project edit <managed-number> --owner <owner> --visibility PUBLIC
```

#### 4b. Se projeto gerenciado existe mas tem `FIELD AUSENTE`

Seguir a mesma sequência de prioridades do step 3b (CLI → GraphQL → enum check → Issue).

#### 4c. Views no projeto gerenciado

Para cada view canônica ausente, criar via REST (mesma lógica do step 3d, substituindo o número do template pelo do projeto gerenciado):

```bash
curl -s -X POST \
  "https://api.github.com/orgs/<owner>/projectsV2/<managed-number>/views" \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  -d '{"name": "<nome>", "layout": "table", "filter": "<filtro>"}'
```

Verificar após criação via GraphQL:
```bash
gh api graphql -f query='{ organization(login: "<owner>") { projectV2(number: <N>) { views(first: 20) { nodes { name filter } } } } }'
```

### 5. Milestones — registrar Issue para Product Owner

Para cada `MILESTONE AUSENTE` no Drift Report:

```bash
gh issue list --repo <owner>/<repo> \
  --search "infra: Milestone <versão>" --json number,title,state
# Se não existir:
gh issue create \
  --repo <owner>/<repo> \
  --title "infra: Milestone <versão> required for OBC <obc-id>" \
  --label "operation:provision,artifact-type:release-trail,journey:diligence" \
  --body "## Context
OBC <obc-id> has release <versão> in the Iteration Plan but no Milestone exists.

## Required action (Product Owner)
gh milestone create \"<versão>\" --repo <owner>/<repo> --description \"Release <versão>\"

## Resolution
When created: close this Issue."
```

### 6. Labels extras — listar sem remover

Para cada label fora da Canonical Specification, reportar como nota. Nunca remover automaticamente.

### 7. Registrar resultado no sync manifest

Atualizar `prodops/artifacts/trails/github-sync-manifest.md`:
- Template: número, ID, campos presentes, is-template status
- Projeto gerenciado: número, ID, campos e views presentes
- Issues abertos referenciados por categoria
- Entrada no Histórico com data, executor e resultado

## Post-conditions

Concluído quando **todos** os itens abaixo são verdadeiros:

- Labels criadas e corrigidas via API
- Template `ProdOps — template` existe e tem campos canônicos provisionados
- Template marcado como template (ou nota registrada se falhou)
- Projeto gerenciado `ProdOps — <repo-name>` existe (criado via copy ou já existia)
- Fields automatizáveis provisionados no projeto gerenciado
- Views: tentativas de API executadas, Issues criados para gaps reais
- Milestones ausentes: Issues criados para Product Owner
- Sync manifest atualizado com template + projeto gerenciado

## Guardrails

- **Projetos gerenciados são PUBLIC por default** — aplicar `gh project edit --visibility PUBLIC` imediatamente após criar ou copiar. Alterar para PRIVATE somente com diretiva explícita do usuário.
- **Nunca criar campos ou views em projetos manuais** — verificar nome antes de qualquer operação de field/view.
- **Ordem obrigatória:** template antes do projeto gerenciado — a cópia depende do template existir.
- **Automation First (Princípio 8)** — tentar API → MCP → CLI → SDK → Browser Automation antes de declarar impossibilidade. Ver [automation-first.md](../../../../../framework/automation-first.md).
- **Nenhum gap sem Issue** — divergências não automatizáveis geram Issue com responsável e critério de resolução.
- **Nunca declarar "ação manual" como texto flutuante** — a instrução vai no corpo do Issue; o output do Reconcile lista Automation Opportunities e Known Platform Limitations.
- Nunca remover labels, views ou fields sem confirmação explícita.
- Nunca criar Milestones — criar Issue para o Product Owner.

## Out of scope

- `reconcile` **não** verifica Issues individuais — isso é Scan (Diligence Async).
- `reconcile` **não** atualiza labels em Issues existentes — isso é Repair (Diligence Async).
- `reconcile` **não** confirma o resultado final — isso é Verify.
