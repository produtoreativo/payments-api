# Prompt para Claude — EXP-015 Iteration 6
## Bootstrap → Hack Chain

## Objetivo

Conectar duas Skills reais, ambas emitindo Started/Completed pela Tool.

```text
Bootstrap → Hack
```

## Regras

- um correlation ID por fluxo Delivery;
- execution-id distinto por Skill;
- runner só carrega Iteration Plan e invoca Skills;
- nenhum evento montado no runner;
- GitHub e Datadog atualizados pelo Runtime;
- Diligence observa eventos reais;
- rodar nos três players.

## Sequência esperada

```text
Delivery.Bootstrap.Started
Delivery.Bootstrap.Completed
Delivery.Hack.Started
Delivery.Hack.Completed
```

## Probe de execução incompleta

Para cada player, execute um caso em que o critério de conclusão de Hack não é satisfeito.

Esperado:

- Hack.Started pode existir;
- Hack.Completed não pode existir;
- agente reporta incompleto;
- runner não fabrica conclusão;
- Diligence observa Timeline parcial.

## Gate

Os três players preservam a semântica tanto no sucesso quanto no cenário incompleto.
