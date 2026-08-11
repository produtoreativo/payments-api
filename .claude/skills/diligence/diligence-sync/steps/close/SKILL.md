---
name: diligence/close
description: Close the Work Item when the OBC reaches Operational state and update management artifacts. Use when the Release Trail confirms the delivery is complete.
---

# DILIGENCE SYNC → CLOSE

Execute only the Close step of the Diligence Sync flow.

**Responsabilidade:** fechar o Work Item quando o OBC atinge estado Operational, garantindo que os artefatos de gestão reflitam o estado final do trabalho entregue.

## Ação

### 1. Confirmar estado Operational no Release Trail

Verificar em `prodops/artifacts/trails/sessions/` se a entrega foi registrada no Release Trail com:
- Escopo confirmado
- Validação executada
- Data de conclusão

### 2. Atualizar o OBC

No arquivo `prodops/artifacts/obcs/<obc-id>.md`:
- Atualizar o campo de status para `Operational`
- Registrar data de conclusão e referência ao Release Trail

### 3. Fechar o Work Item

Fechar o Work Item no backlog externo com:
- Comentário referenciando o Release Trail entry
- Status final: Done/Closed/Operacional

### 4. Atualizar artefatos de gestão

Se o item estava representado em Roadmap ou Product Backlog, atualizar para refletir estado Operational.

### 5. Commit

```bash
git add prodops/artifacts/obcs/<obc-id>.md
git commit -m "docs(diligence): close OBC <obc-id> — Operational"
```

## Eventos — emissão obrigatória

Antes de qualquer trabalho de Close, emitir:

```json
{
  "event": "Diligence.Close.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "diligence-close-agent" },
  "payload": {}
}
```

Após OBC atualizado para Operational, Work Item fechado e commit realizado, emitir:

```json
{
  "event": "Diligence.Close.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "diligence-close-agent" },
  "payload": {}
}
```

Não emitir `Close.Completed` se o OBC não foi atualizado ou o Work Item não foi fechado.

## Post-conditions

Concluído quando:

- OBC com status `Operational` no arquivo Markdown
- Work Item fechado no backlog externo com referência ao Release Trail
- Artefatos de gestão atualizados

## Guardrails

- Não fechar sem evidência no Release Trail — o OBC não está Operational sem entrega registrada.
- Não fechar Work Items de outros OBCs no mesmo step.
- Não modificar BDD Features ou código — Close é um step de rastreabilidade, não de implementação.

## Out of scope

- `close` **não** valida a entrega — isso é Validate (Delivery CI Async).
- `close` **não** cria Release Trail entries — isso é Promote (Delivery CI Async).
- `close` **não** detecta Work Items órfãos em outros OBCs — isso é Scan.
