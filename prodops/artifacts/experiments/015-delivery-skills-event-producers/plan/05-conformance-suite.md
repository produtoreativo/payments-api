# Prompt para Claude — EXP-015 Iteration 5
## Cross-Player Conformance Suite

## Objetivo

Automatizar, tanto quanto cada player permitir, a comparação Claude × Codex × Copilot.

## Matriz

- Skill descoberta;
- invocação explícita;
- invocação implícita;
- Started emitido uma vez;
- Completed emitido uma vez;
- mesmo correlation ID;
- input inválido rejeitado;
- contexto ausente rejeitado;
- Timeline correta;
- Derived State correto;
- GitHub correto;
- Datadog correto;
- Diligence observou;
- segredos sanitizados.

## Estrutura

```text
prodops/runtime/tools/emit-event/tests/conformance/
├── run-claude.sh
├── run-codex.sh
├── run-copilot.sh
├── compare-results.py
├── expected/
└── README.md
```

Onde houver interação manual obrigatória, crie passo manual preciso e resultado machine-readable. Não marque como automatizado.

Normalize somente timestamp, UUID, duração e metadata do player. Não normalize diferenças semânticas.

## Gate

Todas as verificações semânticas obrigatórias passam nos três players antes de adicionar Hack.
