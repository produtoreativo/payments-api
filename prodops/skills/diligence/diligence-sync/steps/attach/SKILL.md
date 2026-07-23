---
name: diligence/attach
description: Verify or create a Work Item in the external backlog referencing the OBC, operation, and journey. Use after Capture has stabilized the canonical OBC state.
---

# DILIGENCE SYNC → ATTACH

Execute only the Attach step of the Diligence Sync flow.

**Responsabilidade:** garantir que o trabalho sobre o OBC seja rastreável em backlogs externos. Attach não muda o estado do OBC — apenas cria ou verifica o Work Item que representa o trabalho sendo executado sobre ele.

## Ação

### 1. Verificar se Work Item ativo existe

Pesquisar no backlog externo (GitHub Issues, Jira, Linear) por Work Items que:
- Referenciam o `artifact_id` do OBC
- Estão abertos (status não fechado/done)

Se Work Item ativo existe: verificar se os campos obrigatórios estão corretos (`artifact_type`, `artifact_id`, `operation`, `journey`). Atualizar se necessário. **Não criar duplicata.**

### 2. Criar Work Item se ausente

Criar Work Item com os campos obrigatórios do schema canônico:

| Campo | Valor |
|---|---|
| `artifact_type` | `Local OBC` |
| `artifact_id` | identificador do OBC (ex: `observability-datadog`) |
| `operation` | operação em andamento (ex: `Refine`, `Promote`, `Review`) |
| `journey` | `Diligence` |

→ Schema completo em `prodops/framework/execution-mapping/work-item-schema.md`

Título canônico: `[Artifact ID]: descrição concisa`

Exemplo: `observability-datadog: avançar para Iteration Plan`

Labels obrigatórias:
```
operation:promote
artifact-type:local-obc
journey:diligence
```

### 3. Registrar link no OBC (opcional)

Se o OBC tiver seção de rastreabilidade, adicionar referência ao Work Item criado.

### 4. Adicionar o Issue ao projeto gerenciado

Obter o número do projeto `ProdOps — <repo-name>` do sync manifest:

```bash
grep "número\|number" prodops/artifacts/trails/github-sync-manifest.md
# fallback:
gh project list --owner <owner> --format json \
  | jq '.projects[] | select(.title == "ProdOps — <repo-name>") | .number'
```

Verificar se o Issue já é membro do projeto (idempotência):

```bash
gh project item-list <project-number> --owner <owner> --format json \
  | jq '.items[] | select(.content.number == <issue-number>) | .id'
```

Se o resultado for vazio, o Issue não é membro — adicionar:

**Prioridade 1 — CLI:**

```bash
gh project item-add <project-number> \
  --owner <owner> \
  --url https://github.com/<owner>/<repo>/issues/<issue-number>
```

**Prioridade 2 — GraphQL (fallback se CLI falhar):**

```bash
ISSUE_ID=$(gh api graphql -f query='
  { repository(owner: "<owner>", name: "<repo>") {
      issue(number: <issue-number>) { id }
  }}' --jq '.data.repository.issue.id')

PROJECT_ID=$(gh api graphql -f query='
  { organization(login: "<owner>") {
      projectV2(number: <project-number>) { id }
  }}' --jq '.data.organization.projectV2.id')

gh api graphql -f query='
  mutation {
    addProjectV2ItemById(input: {
      projectId: "'"$PROJECT_ID"'"
      contentId: "'"$ISSUE_ID"'"
    }) { item { id } }
  }'
```

Se o projeto gerenciado não existir ou não for acessível: registrar bloqueio —
`WORKSPACE NÃO CONFORMANTE — executar Workspace Reconciliation antes de Attach`.
Não encerrar silenciosamente.

## Post-conditions

Concluído quando:

- Work Item ativo existe referenciando o OBC com todos os campos obrigatórios preenchidos
- Nenhum Work Item duplicado foi criado
- Issue é membro do projeto `ProdOps — <repo-name>` — ou bloqueio registrado explicitamente se projeto inacessível

## Guardrails

- Não criar Work Item sem `artifact_type`, `artifact_id`, `operation` e `journey`.
- Verificar duplicatas antes de criar — Work Item duplicado é uma divergência, não uma correção.
- Verificar membership antes de adicionar ao projeto — idempotência explícita evita ruído nos logs.
- Se projeto inacessível: registrar bloqueio — não encerrar silenciosamente.
- Não mover o item no backlog — isso é Promote.
- Não alterar o OBC Markdown neste step — isso é Capture.

## Out of scope

- `attach` **não** cria o OBC — isso é Capture.
- `attach` **não** verifica readiness para Delivery — isso é Promote.
- `attach` **não** fecha Work Items — isso é Close.
- `attach` **não** configura Custom Fields do item no projeto (Artifact Type, Operation, Journey como campos do Project) — são campos de visualização, não de rastreabilidade canônica.
