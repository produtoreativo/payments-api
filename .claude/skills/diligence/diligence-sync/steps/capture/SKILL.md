---
name: diligence/capture
description: Create or update an OBC from the decision that triggered the Diligence Sync cycle. Use when an Assessment decision, Discovery experiment, or Operation signal requires canonical state to be recorded before Work Items are created.
---

# DILIGENCE SYNC → CAPTURE

Execute only the Capture step of the Diligence Sync flow.

**Responsabilidade:** registrar o estado canônico do OBC no arquivo Markdown. Capture não cria Work Items — apenas estabiliza o conhecimento antes que Attach possa rastreá-lo.

## Ação

### 1. Identificar o gatilho

Identificar a decisão ou evento que acionou o ciclo:
- Experimento Discovery concluído com decisão tomada
- Decisão de Assessment registrada em `prodops/framework/journeys/assessment/`
- Novo sinal de Operation que muda o estado de um OBC existente
- Mudança estratégica de Roadmap

### 2. Localizar ou criar o OBC

Se o OBC já existe em `prodops/artifacts/obcs/<obc-id>.md`:
- Ler o arquivo completo
- Atualizar o campo de status e adicionar entrada no histórico de decisões

Se o OBC não existe:
- Verificar que existe um gatilho canônico documentado: experimento concluído, decisão de Assessment registrada, sinal de Operation que justifica o OBC, ou operação autorizada
- Criar o arquivo seguindo o template disponível em `prodops/templates/` (se existir)
- Preencher: identificador, Business Intent de origem, estado inicial, decisão registrada
- **Não criar OBC sem gatilho canônico** — Capture registra decisões já tomadas, não inventa conteúdo ou comprometimentos de negócio

### 3. Registrar a decisão

No corpo do OBC, registrar:
- Data da decisão
- Decisão tomada e justificativa
- Jornada que produziu a decisão (Assessment, Discovery, Operation)
- Referência ao artefato fonte (experiment.md, risks.md, trail)

### 4. Commit do artefato

Para OBC:
```bash
git add prodops/artifacts/obcs/<obc-id>.md
git commit -m "docs(diligence): capture OBC state from <trigger>"
```

Para Business Signal (tracking list):
```bash
git add prodops/artifacts/product/backlogs/tracking-list.md
git commit -m "docs(diligence): capture business signal — <descrição curta>"
```

### 5. Avaliar necessidade de Attach para Business Signals

Quando o artefato capturado for um **Business Signal** (entrada na tracking list), avaliar se existe operação ativa em andamento sobre o Signal. Se houver operação ativa identificada (ex.: exploração, triagem, promoção para Business Intent) e não existir Work Item rastreável, sinalizar Attach como próximo step.

A ausência de Work Item não é automaticamente uma divergência. Work Items são criados quando há trabalho identificado sobre o Signal — não automaticamente ao registrar o Signal.

Registrar explicitamente antes de encerrar: "Business Signal capturado — [há/não há] operação ativa identificada — [Attach necessário / Attach não necessário neste momento]."

## Post-conditions

Concluído quando **todos** os itens abaixo são verdadeiros:

- Artefato committed com estado canônico atualizado
- Decisão registrada com data, justificativa e referência ao artefato fonte
- Se Business Signal: avaliada a necessidade de Attach com base na existência de operação ativa
- Nenhum Work Item criado neste step (responsabilidade de Attach)

## Guardrails

- Não criar Work Items neste step — isso é Attach.
- Não inventar decisões que não estão documentadas no artefato fonte.
- Não encerrar o ciclo diligence-sync após Capture quando o artefato for um Business Signal com operação ativa identificada — Attach é o próximo step nesse caso.
- Não alterar BDD Features ou Reliability Plan — responsabilidade de Delivery ou Assessment.
- Se o OBC exigir uma nova decisão de produto para ser atualizado, parar e surfacing como bloqueador.

## Out of scope

- `capture` **não** cria Work Items — isso é Attach.
- `capture` **não** move itens no backlog — isso é Promote.
- `capture` **não** fecha Work Items — isso é Close.
- `capture` **não** escaneia todos os OBCs — isso é Scan.
