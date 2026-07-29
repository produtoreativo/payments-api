# Prompt para Claude — EXP-015 Iterations 8 e 9
## Failure Paths and Reactive Diligence

## Iteration 8 — Skill failure behavior

Validar uma falha real ou conclusão não atingida em Validate.

Regras:

- Started pode ser emitido;
- Completed não pode ser inventado;
- usar evento de falha/bloqueio apenas se já existir no catálogo aprovado;
- mesma semântica nos três players;
- Runtime e Diligence refletem execução parcial.

Não criar State Machine completa.

## Iteration 9 — Declarative Diligence subscriptions

Criar configuração declarativa:

```yaml
subscriptions:
  prodops.delivery.bootstrap.completed:
    - diligence.capture
  prodops.delivery.validate.completed:
    - diligence.attach
  prodops.delivery.promote.completed:
    - diligence.promote
```

Delivery não chama Diligence diretamente. Skills Delivery apenas emitem fatos. Runtime/dispatcher consulta subscriptions e aciona a Skill Diligence adequada.

Validar nos três players que:

- evento nasceu na Skill Delivery;
- Tool enviou;
- Runtime processou;
- Diligence reagiu;
- Delivery permaneceu independente;
- GitHub e Datadog mostram correlação.
