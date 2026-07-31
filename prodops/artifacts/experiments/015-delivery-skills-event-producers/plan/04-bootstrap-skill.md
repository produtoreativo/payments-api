# Prompt para Claude — EXP-015 Iteration 4
## Bootstrap Skill Becomes Event Producer

## Objetivo

Modificar somente a Skill Bootstrap para definir:

```text
emit Bootstrap.Started
→ executar Bootstrap
→ validar evidências
→ emit Bootstrap.Completed
```

A Skill deve mandar o agente usar `prodops_emit_event`.

## Requisitos da Skill

- input context obrigatório;
- precondições;
- momento exato de Started;
- trabalho a executar;
- evidências;
- completion gate;
- momento exato de Completed;
- comportamento se Tool rejeitar;
- comportamento se trabalho falhar;
- nenhuma chamada direta a GitHub/Datadog.

## Neutralidade

Não colocar sintaxe específica de Claude, Codex ou Copilot na Skill canônica.

## Runner de teste

Pode fornecer contexto e coletar resultado, mas não pode emitir evento, montar CloudEvent, atualizar GitHub ou chamar Datadog.

## Testes

Executar Bootstrap separadamente com Claude, Codex e Copilot.

Timeline esperada por player:

```text
prodops.delivery.bootstrap.started
prodops.delivery.bootstrap.completed
```

## Gate

Provar que nenhum script externo emitiu os dois eventos e que os três players geraram projeções equivalentes.
