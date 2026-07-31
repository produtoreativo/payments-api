# Prompt para Claude — EXP-015 Iteration 2
## Generic Tool Implementation

Use o contrato aprovado na Iteration 1.

## Objetivo

Implementar a Tool canônica executável, ainda sem alterar Skills Delivery.

## Estrutura

```text
prodops/runtime/tools/emit-event/
├── README.md
├── contract/
│   ├── input.schema.json
│   └── output.schema.json
├── scripts/emit-event
├── tests/
└── examples/bootstrap-started.json
```

## Requisitos

- aceitar JSON por stdin ou arquivo;
- validar input;
- rejeitar metadados pertencentes ao catálogo;
- consultar `events.yaml`;
- gerar CloudEvent com producer existente;
- passar pelos dois gates;
- processar Runtime;
- JSON canônico no stdout e diagnóstico no stderr;
- dry-run;
- output de evidência isolado;
- preservar correlation ID;
- nunca expor segredo.

## Testes

- input válido;
- campos obrigatórios ausentes;
- evento desconhecido;
- caller tentando fornecer `new-state`;
- falha parcial do Runtime;
- repetição com mesmo execution-id.

Execute a mesma Tool a partir de Claude, Codex e Copilot.

## Restrições

Não criar MCP, não alterar Skills, não criar Tool por player.

## Gate

Os três players executam exatamente o mesmo script e obtêm a mesma projeção Runtime.
