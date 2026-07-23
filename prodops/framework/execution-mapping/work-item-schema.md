# Schema de Work Item

Um **Work Item** é qualquer recurso do GitHub (Issue, PR, Discussion, Release) que representa uma operação sendo executada sobre um ou mais Artefatos do Knowledge Space.

Todo Work Item deve declarar explicitamente seus campos canônicos.

→ [Execution Mapping](README.md)
→ [Matriz de Mapeamento](matrix.md)

---

## Campos canônicos

### Campos obrigatórios

| Campo | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `artifact_type` | enum | Tipo do artefato principal afetado | `Local OBC` |
| `artifact_id` | string | Identificador ou path do artefato | `feature-name-v2` |
| `operation` | enum | Operação sendo executada | `Refine` |
| `journey` | enum | Jornada ProdOps em curso | `Discovery` |

### Campos contextuais

| Campo | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `execution_mode` | enum | Modo de execução | `Upstream` |
| `owner` | string | Responsável principal | `Product Manager` |
| `status` | enum | Estado do Work Item | `In Progress` |
| `priority` | enum | Prioridade | `High` |
| `release` | string | Release alvo (quando aplicável) | `v2.1.0` |
| `repository` | string | Repositório que contém o artefato | `product-repository` |

### Campos de rastreabilidade

| Campo | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `depends_on` | list | Work Items que devem ser concluídos antes | `[#234, #198]` |
| `blocked_by` | list | Work Items que bloqueiam este | `[#301]` |
| `related_artifacts` | list | Artefatos secundários também afetados | `[bdd/feature-name.feature]` |

### Campos de evidência

| Campo | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `evidence_required` | boolean | Se a operação deve produzir evidência | `true` |
| `evidence_location` | string | Path onde a evidência será armazenada | `artifacts/obcs/feature-name-v2.md#evidências` |

---

## Enums canônicos

### artifact_type
```
Business Signal
Business Intent
Global OBC
Local OBC
BDD Feature
Architecture
Iteration Plan
Reliability Plan
Release Trail
Experiment
Evidence
Risk Register
Context Capsule
```

### operation
```
# Família: Criação
Create
Capture
Define

# Família: Refinamento
Refine
Update
Prototype

# Família: Revisão e Aprovação
Review
Approve
Validate

# Família: Estrutura
Split
Merge
Promote

# Família: Execução
Implement
Experiment
Release

# Família: Encerramento
Archive
Deprecate
Discard
Cancel
```

### journey
```
Discovery
Assessment
Delivery
Operation
Diligence
```

### execution_mode
```
Upstream
Downstream
N/A
```

### status
```
Open
In Progress
Blocked
In Review
Done
Cancelled
```

### priority
```
Critical
High
Medium
Low
```

---

## GitHub Project — Configuração recomendada

Para o **Portfolio GitHub Project** e o **Product Repository GitHub Project**, os campos customizados recomendados são:

```yaml
custom_fields:
  - name: Artifact Type
    type: single_select
    options: [Business Signal, Business Intent, Global OBC, Local OBC, BDD Feature, Architecture, Iteration Plan, Reliability Plan, Release Trail, Experiment, Evidence, Risk Register]

  - name: Artifact ID
    type: text
    description: "Slug ou path relativo do artefato (ex: feature-name-v2)"

  - name: Operation
    type: single_select
    options: [Create, Capture, Define, Refine, Update, Prototype, Review, Approve, Validate, Split, Merge, Promote, Implement, Experiment, Release, Archive, Deprecate, Discard, Cancel]

  - name: Journey
    type: single_select
    options: [Discovery, Assessment, Delivery, Operation, Diligence]

  - name: Execution Mode
    type: single_select
    options: [Upstream, Downstream, "N/A"]

  - name: Owner
    type: text

  - name: Release
    type: text
    description: "Versão alvo (ex: v2.1.0)"

  - name: Evidence Required
    type: checkbox
```

Os campos nativos do GitHub Project (`Status`, `Priority`, `Assignees`, `Milestone`) complementam os campos customizados acima.

---

## Título canônico de Work Items

O título de um Work Item deve seguir o padrão:

```
[Artifact ID]: descrição concisa
```

O título é orientado ao objeto de trabalho — o que está sendo trabalhado. `Operation` e `Artifact Type` são detalhes de processo e vão para labels e campos do body, onde têm espaço para ser lidos com contexto.

Exemplos:
```
feature-name-v2: seção BDD incompleta
feature-name-v2: Assessment pré-Downstream
feature-name-v2: novo capability de composição
architecture-overview: novo módulo WorkerService
platform-billing-v3: decompor em 3 Local OBCs
feature-name.feature: CI gate pré-release
SIG-089: gerar Business Intent
```

---

## Labels canônicas de Work Items

`Operation` e `Artifact Type` são declarados como labels para permitir busca e filtro via `gh issue list` e GitHub search.

### Padrão de label

```
operation:<valor>       # ex: operation:refine, operation:promote, operation:capture
artifact-type:<valor>   # ex: artifact-type:local-obc, artifact-type:business-signal
```

Os valores seguem os enums canônicos em letras minúsculas com hífen.

### Exemplos

```bash
gh issue list --label "operation:promote"
gh issue list --label "artifact-type:local-obc"
gh issue list --label "operation:capture" --label "artifact-type:business-signal"
```

### Labels obrigatórias por Work Item

| Label | Obrigatória | Valores |
|---|---|---|
| `operation:<valor>` | Sim | enums da família `operation` |
| `artifact-type:<valor>` | Sim | enums de `artifact_type` |
| `journey:<valor>` | Recomendada | enums de `journey` |

---

## Validação

Um Work Item está corretamente estruturado quando:
- [ ] `artifact_type` está preenchido com um valor canônico
- [ ] `artifact_id` referencia um artefato existente no repositório
- [ ] `operation` está preenchida com uma operação permitida para aquele tipo de artefato (ver [Matriz](matrix.md))
- [ ] `journey` está preenchida
- [ ] O título segue o padrão `[Artifact ID]: descrição concisa`
- [ ] Labels `operation:<valor>` e `artifact-type:<valor>` estão presentes no Issue

---

## Referências

→ [Execution Mapping](README.md)
→ [Matriz de Mapeamento](matrix.md)
→ [Knowledge vs Execution](../knowledge-vs-execution.md)
