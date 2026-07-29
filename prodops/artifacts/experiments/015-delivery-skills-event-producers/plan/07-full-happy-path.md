# Prompt para Claude — EXP-015 Iteration 7
## Full Happy Path Through Skills

## Objetivo

Migrar todos os Skills:

```text
Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote
```

Cada Skill emite seus próprios eventos via Tool.

## Ordem incremental

Migre e valide um por vez:

1. Sync
2. Finish
3. Ship
4. Validate
5. Promote

Após cada Skill:

- Claude;
- Codex;
- Copilot;
- conformance suite;
- Timeline;
- GitHub;
- Datadog;
- Diligence;
- findings.

## Runner

Pode apenas:

- carregar Iteration Plan;
- criar contexto;
- invocar Skills;
- parar em falha;
- resumir.

Não pode conhecer tipos CloudEvent, estados, GitHub, Datadog, Diligence ou Timeline.

## Verificação final

Pesquisar no repositório e provar que montagem de Delivery CloudEvents só existe na Tool/Runtime.

Resultado esperado: 15 eventos do Happy Path.

## Gate

O código de emissão dos scripts demo pode ser removido/desabilitado e o fluxo continua funcionando nos três players.
