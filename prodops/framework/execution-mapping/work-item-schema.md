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
| `artifact_id` | string | Identificador ou path do artefato | `payments-invoice-v2` |
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
| `repository` | string | Repositório que contém o artefato | `payments-api` |

### Campos de rastreabilidade

| Campo | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `depends_on` | list | Work Items que devem ser concluídos antes | `[#234, #198]` |
| `blocked_by` | list | Work Items que bloqueiam este | `[#301]` |
| `related_artifacts` | list | Artefatos secundários também afetados | `[bdd/payments-invoice.feature]` |

### Campos de evidência

| Campo | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `evidence_required` | boolean | Se a operação deve produzir evidência | `true` |
| `evidence_location` | string | Path onde a evidência será armazenada | `artifacts/business/obcs/payments-invoice-v2.md#evidências` |

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
    description: "Slug ou path relativo do artefato (ex: payments-invoice-v2)"

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
[Operation] — [Artifact Type] [Artifact ID]: [descrição concisa]
```

Exemplos:
```
Refine — Local OBC payments-invoice-v2: seção BDD incompleta
Review — Local OBC payments-invoice-v2: Assessment pré-Downstream
Implement — Local OBC payments-invoice-v2: split de pagamento PIX
Update — Architecture overview: novo módulo WebhookWorker
Split — Global OBC platform-billing-v3: decompor em 3 Local OBCs
Validate — BDD Feature payments-invoice.feature: CI gate pré-release
Promote — Business Signal SIG-089: gerar Business Intent
```

Este padrão:
- identifica o artefato sem ambiguidade
- nomeia a operação sem usar "Issue de X"
- permite busca e filtro por artefato ou operação no GitHub

---

## Validação

Um Work Item está corretamente estruturado quando:
- [ ] `artifact_type` está preenchido com um valor canônico
- [ ] `artifact_id` referencia um artefato existente no repositório
- [ ] `operation` está preenchida com uma operação permitida para aquele tipo de artefato (ver [Matriz](matrix.md))
- [ ] `journey` está preenchida
- [ ] O título segue o padrão `[Operation] — [Artifact Type] [Artifact ID]: ...`

---

## Referências

→ [Execution Mapping](README.md)
→ [Matriz de Mapeamento](matrix.md)
→ [Knowledge vs Execution](../knowledge-vs-execution.md)
