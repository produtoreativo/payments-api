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

Título canônico: `[Operation] — [Artifact Type] [Artifact ID]: descrição concisa`

Exemplo: `Promote — Local OBC observability-datadog: avançar para Iteration Plan`

### 3. Registrar link no OBC (opcional)

Se o OBC tiver seção de rastreabilidade, adicionar referência ao Work Item criado.

## Post-conditions

Concluído quando:

- Work Item ativo existe referenciando o OBC com todos os campos obrigatórios preenchidos
- Nenhum Work Item duplicado foi criado

## Guardrails

- Não criar Work Item sem `artifact_type`, `artifact_id`, `operation` e `journey`.
- Verificar duplicatas antes de criar — Work Item duplicado é uma divergência, não uma correção.
- Não mover o item no backlog — isso é Promote.
- Não alterar o OBC Markdown neste step — isso é Capture.

## Out of scope

- `attach` **não** cria o OBC — isso é Capture.
- `attach` **não** verifica readiness para Delivery — isso é Promote.
- `attach` **não** fecha Work Items — isso é Close.
