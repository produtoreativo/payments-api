# Prompt para Claude — EXP-015 Iteration 1
## Contract and Capability Spike

Leia o Runtime atual, catálogo, CloudEvents, Skills Delivery e evidências dos EXP-013/014.

## Objetivo

Definir o contrato player-neutral `prodops_emit_event` e provar que Claude, Codex e Copilot conseguem invocar o mesmo executável local com resultados semanticamente equivalentes.

## Ações

1. Inventarie todos os pontos atuais que montam eventos Delivery.
2. Defina `input.schema.json`, `output.schema.json`, exit codes e modelo de erro.
3. Defina idempotência mínima e logging sanitizado.
4. Crie um spike executável que delegue ao Runtime atual.
5. Não use MCP ainda.
6. Não altere Skills Delivery.
7. Prepare instruções de teste específicas para Claude, Codex e Copilot.
8. Execute `Delivery.Bootstrap.Started` uma vez por player, com correlation IDs distintos.
9. Compare CloudEvent, Timeline, Derived State, GitHub e Datadog.

## Evidências

```text
prodops/artifacts/experiments/015-delivery-skills-event-producers/evidence/iteration-1/
  contract.md
  input.schema.json
  output.schema.json
  current-emission-inventory.md
  claude-run.json
  codex-run.json
  copilot-run.json
  conformance-report.md
  findings.md
```

## Gate

Não concluir com teste apenas teórico. Os três players precisam invocar o spike. Diferenças só podem existir em actor/session metadata.
