# EXP-015 — Delivery Skills as Event Producers

## Hipótese

Uma Skill de Delivery define **quando e por que** um evento deve ser emitido; o agente executa a Skill; uma Tool genérica realiza **como** o evento é construído e enviado; o Runtime processa o CloudEvent. O mesmo contrato deve funcionar em Claude Code, Codex e GitHub Copilot.

## Arquitetura

```text
Canonical Delivery Skill
        ↓ semantic instruction
Agent (Claude | Codex | Copilot)
        ↓ player-specific tool invocation
prodops_emit_event
        ↓ CloudEvent 1.0
Runtime
  ├─ Timeline
  ├─ Derived State
  ├─ GitHub Project
  ├─ Datadog
  └─ Diligence
```

## Responsabilidades

### Skill
- define evento lógico e momento da emissão;
- define precondições e critérios de conclusão;
- define evidências;
- não conhece GitHub, Datadog, curl, GraphQL ou envelope CloudEvents.

### Agent
- lê a Skill;
- mantém contexto da execução;
- chama a Tool;
- executa o trabalho;
- não inventa estados ou metadados do catálogo.

### Tool
- valida input;
- consulta `events.yaml`;
- constrói CloudEvent;
- chama Runtime;
- devolve resultado canônico.

### Runtime
- valida;
- persiste Timeline;
- deriva estado;
- sincroniza GitHub;
- envia Datadog;
- disponibiliza sinais para Diligence.

## Fonte canônica e adapters

```text
prodops/skills/                         # fonte canônica
prodops/runtime/tools/emit-event/       # Tool canônica
prodops/execution/player-adapters/
  ├─ claude/
  ├─ codex/
  └─ copilot/
```

Materializações:

```text
.claude/skills/     # Claude
.agents/skills/     # Codex
.github/skills/     # Copilot
```

Não manter três versões manuais da mesma Skill. Criar geração/symlink determinístico.

## Contrato lógico da Tool

Nome:

```text
prodops_emit_event
```

Input:

```json
{
  "event": "Delivery.Bootstrap.Started",
  "work-item-id": "76",
  "iteration-id": "IP-RUNTIME-001",
  "correlation-id": "uuid",
  "execution-id": "uuid",
  "actor": {
    "player": "claude|codex|copilot",
    "agent": "delivery-agent"
  },
  "payload": {}
}
```

O agente não fornece:

```text
specversion, source, type, dataschema,
journey, cycle, phase, alters-state, new-state
```

Esses dados pertencem ao catálogo/runtime.

Output:

```json
{
  "status": "accepted",
  "event-id": "uuid",
  "event-type": "prodops.delivery.bootstrap.started",
  "correlation-id": "uuid",
  "derived-state": "BOOTSTRAPPING",
  "github-sync": "success",
  "datadog-sync": "success",
  "errors": []
}
```

## Regra de conformidade

Para o mesmo cenário, Claude, Codex e Copilot devem produzir o mesmo:

- evento lógico;
- tipo CloudEvent;
- semântica de payload;
- Timeline;
- Derived State;
- projeção GitHub;
- tags Datadog;
- comportamento de erro.

Diferenças permitidas: player, session-id, logs e duração.

## Iterações

1. Contrato e spike.
2. Tool genérica.
3. Adapters dos três players.
4. Bootstrap Skill como produtora.
5. Conformance suite.
6. Cadeia Bootstrap → Hack.
7. Happy Path completo.
8. Falha/execução incompleta.
9. Diligence reativa por subscriptions.

Cada iteração deve gerar evidências separadas para Claude, Codex e Copilot e uma comparação final.
