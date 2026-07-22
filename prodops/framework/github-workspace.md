# GitHub Workspace — Especificação Canônica

Este arquivo é a fonte de verdade para a infraestrutura do GitHub Project do produto. O step `workspace` do ciclo `diligence-infra` lê este arquivo e compara com o estado real do repositório.

---

## Fluxo de provisioning

```mermaid
flowchart TD
    START([diligence-infra]) --> WORKSPACE

    subgraph WORKSPACE["① Workspace — leitura e diff"]
        W1[Labels\ngh label list] --> W2
        W2[Milestones\ngh api milestones] --> W3
        W3{"Template\nProdOps — template\nexiste na org?"}
        W3 -->|sim| W3B[Verificar campos\ndo template]
        W3 -->|não| W3C[TEMPLATE AUSENTE]
        W3B --> W4
        W3C --> W4
        W4{"Projeto gerenciado\nProdOps — repo\nexiste na org?"}
        W4 -->|sim| W4B[Verificar campos\ne views]
        W4 -->|não| W4C[PROJETO GERENCIADO\nAUSENTE]
        W4B --> W5
        W4C --> W5
        W5[Diff consolidado]
    end

    WORKSPACE --> PROVISION

    subgraph PROVISION["② Provision — execução"]
        P1[Labels\ngh label create / edit]
        P1 --> P2

        P2{"Template existe?"}
        P2 -->|não| P2A[gh project create\nProdOps — template]
        P2A --> P2B
        P2 -->|sim, desatualizado| P2B
        P2B[Provisionar campos\ncanônicos no template\ngh project field-create]
        P2B --> P2C[gh project mark-template]
        P2 -->|sim, conforme| P3
        P2C --> P3

        P3{"Projeto gerenciado\nexiste?"}
        P3 -->|não| P3A["gh project copy\nProdOps — template\n→ herda campos + views"]
        P3 -->|sim| P3B[Campos ausentes?\ngh project field-create]
        P3A --> P4
        P3B --> P4

        P4[Views ausentes?\nTentar API → Issue se falhar]
        P4 --> P5
        P5[Milestones ausentes?\nIssue para Product Owner]
    end

    PROVISION --> VERIFY

    subgraph VERIFY["③ Verify — confirmação"]
        V1[Re-verificar template +\nprojeto gerenciado +\nlabels + milestones]
        V1 --> V2[Atualizar sync manifest]
    end

    VERIFY --> DONE(["CONFORME\nPARCIAL\nNÃO CONFORME"])
```

---

## Labels

### Família: operation

| Label | Cor | Descrição |
|---|---|---|
| `operation:capture` | `#0075ca` | ProdOps operation: Capture |
| `operation:create` | `#0075ca` | ProdOps operation: Create |
| `operation:define` | `#0075ca` | ProdOps operation: Define |
| `operation:refine` | `#0075ca` | ProdOps operation: Refine |
| `operation:update` | `#0075ca` | ProdOps operation: Update |
| `operation:prototype` | `#0075ca` | ProdOps operation: Prototype |
| `operation:review` | `#0075ca` | ProdOps operation: Review |
| `operation:approve` | `#0075ca` | ProdOps operation: Approve |
| `operation:validate` | `#0075ca` | ProdOps operation: Validate |
| `operation:split` | `#0075ca` | ProdOps operation: Split |
| `operation:merge` | `#0075ca` | ProdOps operation: Merge |
| `operation:promote` | `#0075ca` | ProdOps operation: Promote |
| `operation:implement` | `#0075ca` | ProdOps operation: Implement |
| `operation:experiment` | `#0075ca` | ProdOps operation: Experiment |
| `operation:release` | `#0075ca` | ProdOps operation: Release |
| `operation:archive` | `#0075ca` | ProdOps operation: Archive |
| `operation:deprecate` | `#0075ca` | ProdOps operation: Deprecate |
| `operation:discard` | `#0075ca` | ProdOps operation: Discard |
| `operation:cancel` | `#0075ca` | ProdOps operation: Cancel |
| `operation:provision` | `#0075ca` | ProdOps operation: Provision |

### Família: artifact-type

| Label | Cor | Descrição |
|---|---|---|
| `artifact-type:business-signal` | `#e4e669` | ProdOps artifact type: Business Signal |
| `artifact-type:business-intent` | `#e4e669` | ProdOps artifact type: Business Intent |
| `artifact-type:global-obc` | `#e4e669` | ProdOps artifact type: Global OBC |
| `artifact-type:local-obc` | `#e4e669` | ProdOps artifact type: Local OBC |
| `artifact-type:bdd-feature` | `#e4e669` | ProdOps artifact type: BDD Feature |
| `artifact-type:architecture` | `#e4e669` | ProdOps artifact type: Architecture |
| `artifact-type:iteration-plan` | `#e4e669` | ProdOps artifact type: Iteration Plan |
| `artifact-type:reliability-plan` | `#e4e669` | ProdOps artifact type: Reliability Plan |
| `artifact-type:release-trail` | `#e4e669` | ProdOps artifact type: Release Trail |
| `artifact-type:experiment` | `#e4e669` | ProdOps artifact type: Experiment |
| `artifact-type:evidence` | `#e4e669` | ProdOps artifact type: Evidence |
| `artifact-type:risk-register` | `#e4e669` | ProdOps artifact type: Risk Register |
| `artifact-type:context-capsule` | `#e4e669` | ProdOps artifact type: Context Capsule |

### Família: journey

| Label | Cor | Descrição |
|---|---|---|
| `journey:discovery` | `#d93f0b` | ProdOps journey: Discovery |
| `journey:assessment` | `#d93f0b` | ProdOps journey: Assessment |
| `journey:delivery` | `#d93f0b` | ProdOps journey: Delivery |
| `journey:operation` | `#d93f0b` | ProdOps journey: Operation |
| `journey:diligence` | `#d93f0b` | ProdOps journey: Diligence |

---

## Milestones

Milestones representam releases do produto. Criados pelo Product Owner antes de cada iteração.

| Milestone | Descrição |
|---|---|
| `v{major}.{minor}` | Release do produto — agrupa Issues da iteração correspondente |

Milestones são gerenciados pelo Product Owner — não são provisionados automaticamente pelo Diligence.

---

## GitHub Projects — Dois projetos gerenciados

O framework mantém **dois** GitHub Projects na org, ambos identificados por nome (nunca por número):

| Papel | Nome | Escopo |
|---|---|---|
| Template canônico | `ProdOps — template` | Org — source para `gh project copy` |
| Projeto gerenciado | `ProdOps — <repo-name>` | Por repositório — ex: `ProdOps — payments-api` |

**Projetos manuais são intocáveis.** Qualquer projeto cujo nome não corresponda a um desses dois padrões é ignorado pelo Diligence — inclusive projetos criados antes do framework (ex: "Turma Junho 2026").

### ProdOps — template (org-level)

Projeto marcado como template via `gh project mark-template`. Contém todos os campos canônicos e as views canônicas. Serve como source de `gh project copy` ao criar projetos gerenciados para novos repositórios.

**Quando criar:** na primeira execução de `diligence-infra provision` se ainda não existir.
**Criação:**
```bash
gh project create --owner <org> --title "ProdOps — template"
gh project edit <number> --owner <org> --visibility PUBLIC   # público por default
```
**Após criar:** provisionar campos canônicos via API, criar views via REST, então `gh project mark-template`.
**Visibilidade:** PUBLIC por default. Alterar para PRIVATE somente com diretiva explícita.

### ProdOps — \<repo-name\> (por repositório)

Projeto criado via `gh project copy "ProdOps — template"`, herdando campos e views automaticamente.

**Quando criar:** quando o projeto gerenciado do repositório não existir.
**Criação:**
```bash
gh project copy <template-number> \
  --source-owner <org> --target-owner <org> \
  --title "ProdOps — <repo-name>"
gh project edit <number> --owner <org> --visibility PUBLIC   # público por default
```
**Pré-requisito:** o template deve existir e estar configurado antes da cópia.
**Visibilidade:** PUBLIC por default. `gh project copy` herda a visibilidade do source — verificar e corrigir após cópia se necessário.

### Custom Fields canônicos (obrigatórios em ambos os projetos)

| Campo | Tipo | Opções / Formato |
|---|---|---|
| `Artifact Type` | single_select | enums de `artifact_type` do work-item-schema |
| `Artifact ID` | text | slug ou path relativo do artefato |
| `Operation` | single_select | enums de `operation` do work-item-schema |
| `Journey` | single_select | Discovery, Assessment, Delivery, Operation, Diligence |
| `Execution Mode` | single_select | Upstream, Downstream, N/A |
| `Owner` | text | responsável principal |
| `Release` | text | versão alvo (ex: v2.1.0) |
| `Evidence Required` | single_select | `Required` (campo vazio = false) — implementado como SINGLE_SELECT enquanto API não suporta CHECKBOX em `ProjectV2CustomFieldType` |

### Views canônicas (obrigatórias em ambos os projetos)

> **Automação via REST API (verificado 2026-07-22):**
> ```bash
> curl -X POST "https://api.github.com/orgs/{org}/projectsV2/{projectNumber}/views" \
>   -H "Authorization: Bearer $TOKEN" \
>   -H "Accept: application/vnd.github+json" \
>   -d '{"name": "View Name", "layout": "table", "filter": "label:journey:delivery"}'
> ```
> Endpoint: `/orgs/{org}/projectsV2/{N}/views` (atenção: `projectsV2`, não `projects`).
> Suporta: `name`, `layout` (table/board/roadmap), `filter`.
> **`group_by`:** não configurável via API (GraphQL sem mutation, REST PATCH retorna 404). Configurar manualmente na UI se necessário — não bloqueia funcionalidade.

| View | Filtro | Agrupamento | Propósito |
|---|---|---|---|
| `All Work Items` | nenhum | Journey | Visão completa do trabalho em andamento |
| `By Operation` | nenhum | Operation | Triagem por tipo de operação |
| `Business Signals` | `label:artifact-type:business-signal` | Status | Tracking list operacional |
| `Delivery` | `label:journey:delivery` | Status | Acompanhamento de Delivery em andamento |
| `Diligence` | `label:journey:diligence` | Operation | Trabalho ativo da jornada Diligence |

**Criar as views no template (uma vez):**
1. Abrir `ProdOps — template` no GitHub
2. Para cada view: clicar em `+ New view`, nomear e configurar filtro e agrupamento
3. Executar `/diligence diligence-infra verify` para confirmar via GraphQL
4. A partir daí, todos os novos projetos herdam as views via `gh project copy`

---

## Referências

→ [Work Item Schema](execution-mapping/work-item-schema.md) — campos, enums e título canônico
→ [Diligence Infra cycle](../journeys/diligence/diligence-infra.md)
→ [GitHub Sync Manifest](../artifacts/governance/github-sync-manifest.md)
