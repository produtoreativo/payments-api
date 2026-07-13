# Modo Downstream

Downstream é o modo de entrega governada do Framework ProdOps.

## Propósito

Entregar software com rastreabilidade, critérios de aceite verificáveis e evidência registrada em cada etapa.

## Características do modo

- Compromisso formal com critérios de aceite (OBC + BDD Feature)
- Governança e rastreabilidade completas
- Artefatos obrigatórios antes do início
- Evidências registradas em cada etapa
- Sequência completa obrigatória

## Quando usar o modo Downstream

- Item aprovado no Iteration Plan
- Implementar OBC + BDD Feature existente
- Entregar feature com compromisso formal
- Executar item do Reliability Plan

## Pré-condições obrigatórias

O modo Downstream pode ser iniciado para guiar um item comprometido até readiness. Antes de executar qualquer fase de Delivery, todos os requisitos abaixo devem estar satisfeitos:

1. OBC em `prodops/artifacts/obcs/`
2. BDD Feature em `prodops/artifacts/bdd/`
3. Riscos documentados em `prodops/journeys/assessment/risks.md`
4. Entrada no Reliability Plan, produzido pela Assessment, em `prodops/journeys/assessment/reliability-plans/`
5. Entrada no Iteration Plan com status `Entrou` em `prodops/artifacts/plans/iteration-plan.md`

Quando faltar um requisito, o Downstream para antes da Delivery, indica o responsável e orienta a próxima ação. Reliability precede a decisão de readiness do Iteration Plan.

## Sequência obrigatória

```
Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote
```

O trabalho é dividido em dois ciclos:

```
CI Sync: Bootstrap → Hack → Sync → Finish     (trabalho local, síncrono)
CI Async: Ship → Validate → Promote            (plataforma, pipelines, ambientes)
```

## Fases

| Fase | Descrição | Link |
|---|---|---|
| Bootstrap | Dependências + infraestrutura local + configuração + smoke gate | [../journeys/delivery/phases/bootstrap/README.md](../journeys/delivery/phases/bootstrap/README.md) |
| Hack | Implementação via ProdOps TDD | [../journeys/delivery/phases/hack/README.md](../journeys/delivery/phases/hack/README.md) |
| Sync | Branch sync (rebase) + alinhamento de artefatos (align) | [../journeys/delivery/phases/sync/README.md](../journeys/delivery/phases/sync/README.md) |
| Finish | Quality Gates + PR | [../journeys/delivery/phases/finish/README.md](../journeys/delivery/phases/finish/README.md) |
| Ship | Preparation + Deployment | [../journeys/delivery/phases/ship/README.md](../journeys/delivery/phases/ship/README.md) |
| Validate | Runtime + observabilidade + SLO | [../journeys/delivery/phases/validate/README.md](../journeys/delivery/phases/validate/README.md) |
| Promote | Aprovação formal + Release Trail | [../journeys/delivery/phases/promote/README.md](../journeys/delivery/phases/promote/README.md) |

## Evidências

Registrar evidências significativas de entrega em `prodops/artifacts/trails/release-trail.md`.

## O Downstream deve preservar

Rastreabilidade desde o estado atual e o assessment até a implementação, validação e promoção.
