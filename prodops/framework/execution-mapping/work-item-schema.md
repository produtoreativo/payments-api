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
# Diligence — entidades canônicas (adicionadas em 2026-07-24)
Finding
Remediation
Waiver
Check
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
Reconcile    # alinhar estado real ao estado canônico declarado (adicionado em 2026-07-24)
             # uso primário: Workspace Reconciliation (Capability da Diligence)
             # semântica: nenhuma operação existente cobre "detectar e corrigir
             #            divergência entre estado declarado e estado observado"

# Família: Encerramento
Archive
Deprecate
Discard
Cancel
```

#### Rationale — Adição de `Reconcile`

A operação `Reconcile` foi adicionada em 2026-07-24 como resultado da análise de
convergência de operações para a Jornada de Diligence (ver
`prodops/framework/journeys/diligence/github-workspace-schema.yaml`).

Nenhuma das operações existentes cobre a semântica de "alinhar estado real ao
estado canônico declarado":
- `Update` — atualiza conteúdo com nova informação; não implica detecção de drift
- `Implement` — desenvolve código; não implica comparação com especificação
- `Validate` — verifica contra critérios; é o step Verify do processo, não o Reconcile
- `Repair` — nome de fase do Diligence Async; não é uma operação de Work Item

`Reconcile` tem uso primário em Workspace Reconciliation (Capability da Diligence)
e pode ser usado em outros contextos onde há necessidade de alinhar estado real a
estado esperado de forma rastreável.

**Operações NÃO adicionadas e seus rationales:**
- `Approve Waiver` — redundante com `Approve + Artifact Type = Waiver`; operações
  compostas criam inconsistência de vocabulário no enum
- `Collect Evidence` — redundante com `Capture + Artifact Type = Evidence`;
  Capture já existe e cobre a semântica de registrar/capturar
- `Repair` — nome de fase do Diligence Async; `Implement` cobre a semântica
  de implementar uma correção como Work Item
- `Investigate` — sinônimo de `Review` no contexto operacional; minimizar vocabulário

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
    options:
      # Knowledge Space — artefatos de produto e portfólio
      - Business Signal
      - Business Intent
      - Global OBC
      - Local OBC
      - BDD Feature
      - Architecture
      - Iteration Plan
      - Reliability Plan
      - Release Trail
      - Experiment
      - Evidence
      - Risk Register
      # Diligence — entidades canônicas (adicionadas em 2026-07-24)
      - Finding       # FND-YYYY-NNNN
      - Remediation   # RMD-YYYY-NNNN
      - Waiver        # WVR-YYYY-NNNN
      - Check         # DIL-CATEGORY-NNN

  - name: Artifact ID
    type: text
    description: >
      Slug ou path relativo do artefato (ex: feature-name-v2).
      Para entidades Diligence: FND-YYYY-NNNN, RMD-YYYY-NNNN,
      WVR-YYYY-NNNN, EVD-YYYY-NNNN, DIL-CAT-NNN.
      IDs são imutáveis após criação e independentes de número de Issue.

  - name: Operation
    type: single_select
    options:
      # Família: Criação
      - Create
      - Capture
      - Define
      # Família: Refinamento
      - Refine
      - Update
      - Prototype
      # Família: Revisão e Aprovação
      - Review
      - Approve
      - Validate
      # Família: Estrutura
      - Split
      - Merge
      - Promote
      # Família: Execução
      - Implement
      - Experiment
      - Release
      - Reconcile   # adicionado em 2026-07-24 — ver rationale na seção Enums
      # Família: Encerramento
      - Archive
      - Deprecate
      - Discard
      - Cancel

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

#### Campos adicionais para a Jornada Diligence

Work Items da Jornada Diligence usam campos adicionais de rastreabilidade
declarados no schema `prodops/framework/journeys/diligence/github-workspace-schema.yaml`:

```yaml
diligence_fields:
  - name: Cycle
    type: single_select
    options: [diligence-sync, diligence-async, workspace-reconciliation]

  - name: Phase
    type: single_select
    options: [Capture, Attach, Promote, Close, Scan, Flag, Repair, Inspect, Reconcile, Verify]

  - name: Mode
    type: single_select
    options: [Sync, Async, Manual]
```

#### Exemplos — Jornada Diligence

```yaml
# Exemplo 1: Work Item de investigação de Finding
artifact_type: Finding
artifact_id: FND-2026-0007
operation: Review
journey: Diligence
cycle: diligence-async
phase: Scan
mode: Async
owner: Diligence Owner

# Exemplo 2: Work Item de implementação de Remediation
artifact_type: Remediation
artifact_id: RMD-2026-0003
operation: Implement
journey: Diligence
cycle: diligence-async
phase: Repair
mode: Async
owner: Software Engineer

# Exemplo 3: Work Item de verificação pós-Remediation
artifact_type: Remediation
artifact_id: RMD-2026-0003
operation: Validate
journey: Diligence
cycle: diligence-async
phase: Verify
mode: Async
owner: PRE  # verificador independente do implementador

# Exemplo 4: Work Item de aprovação de Waiver
artifact_type: Waiver
artifact_id: WVR-2026-0001
operation: Approve
journey: Diligence
cycle: diligence-async
phase: Repair
mode: Async
owner: Product Owner  # aprovador com autoridade

# Exemplo 5: Work Item de Workspace Reconciliation
artifact_type: Check
artifact_id: DIL-WSP-001
operation: Reconcile
journey: Diligence
cycle: workspace-reconciliation
phase: Reconcile
mode: Manual
owner: Platform Engineer
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

---

## Ciclo de vida do Work Item em transições do OBC

O estado do OBC e o estado do Work Item são **independentes**. Uma transição de estado do OBC não fecha nem reabre automaticamente um Work Item. Um Work Item rastreia uma operação específica — quando a operação termina, o Work Item fecha. O OBC pode continuar evoluindo após o fechamento do Work Item.

### Matriz de transições

| Transição do OBC | Operação Esperada | Ação no Work Item |
|---|---|---|
| Draft → Refining | Explore ou Refine | Criar Work Item se existe operação ativa; não criar se o OBC avança passivamente |
| Refining → Committed | Commit ou Promote | Fechar Work Item de refinamento quando a operação termina; registrar promoção se necessário |
| Committed → In Delivery | Implement | Criar Work Item de implementação quando a Delivery é iniciada |
| In Delivery → Operational | Validate e Promote | Fechar Work Items de implementação concluídos; registrar evidências |
| Operational → Archived | Archive | Criar Work Item somente para operação formal de arquivamento se necessário |

### Princípios

- **OBC state ≠ Work Item state.** Um OBC pode estar Operational e ainda ter Work Items abertos de atualizações pós-operação.
- **Uma transição de OBC NÃO fecha ou reabre automaticamente um Work Item.** O Work Item fecha quando a operação que ele rastreia termina.
- **Um Work Item rastreia uma operação específica.** Quando a operação termina, o Work Item fecha — independente do estado do OBC.
- **Uma nova operação pode requerer um novo Work Item.** Work Items anteriores permanecem como histórico e NÃO são reabertos quando o OBC evolui.
- **O OBC pode continuar evoluindo após Work Items fechados.** O histórico de Work Items acumula no OBC sem que novos Work Items precisem ser abertos para cada mudança menor.

---

## Referências

→ [Execution Mapping](README.md)
→ [Matriz de Mapeamento](matrix.md)
→ [Knowledge vs Execution](../knowledge-vs-execution.md)
