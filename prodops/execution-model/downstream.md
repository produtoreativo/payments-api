# Modo Downstream

Downstream é o **modo de compromisso** do Framework ProdOps.

## Definição canônica

Downstream representa um modo de compromisso. A partir do momento em que uma Business Intent entra em Downstream, existe compromisso de entrega, qualidade e confiabilidade. Todo trabalho passa a seguir obrigatoriamente o modelo operacional do ProdOps.

## Propósito

Entregar software com rastreabilidade, critérios de aceite verificáveis e evidência registrada em cada etapa.

## Características do modo

No Downstream:

- existe compromisso de implementação
- existe compromisso de confiabilidade
- existe governança
- existe validação obrigatória
- existe rastreabilidade
- existe geração de evidências
- existe conformidade com o modelo operacional

As Skills deixam de ser opcionais. Passam a fazer parte do processo de execução — participam da validação das jornadas, produzem evidências e garantem consistência.

## OBC no Downstream

Ao entrar no Downstream, o OBC deixa de ser apenas um registro. Ele passa a ser o contrato operacional do trabalho.

Durante o Discovery (no Icebox), será refinado até atingir o estado Committed. Esse OBC controla a evolução das jornadas seguintes: Iteration Backlog → Iteration Plan → Delivery.

## Quando usar o modo Downstream

- Item aprovado no Iteration Plan
- Implementar OBC + BDD Feature existente
- Entregar feature com compromisso formal
- Executar item do Reliability Plan

## Pré-condições obrigatórias

O Downstream possui três momentos explícitos:

1. **Downstream Declared** — o compromisso foi assumido; o modo guia o item até readiness.
2. **Downstream Ready** — todos os gates aplicáveis foram satisfeitos.
3. **Delivery Started** — Bootstrap foi iniciado para um item Ready.

Antes de executar qualquer fase de Delivery, todos os requisitos abaixo devem estar satisfeitos:

1. OBC em `prodops/artifacts/business/obcs/`
2. BDD Feature em `prodops/artifacts/business/bdd/`
3. Riscos documentados em `prodops/journeys/assessment/risks.md`
4. Entrada no Iteration Plan com status `Entrou` em `prodops/artifacts/governance/plans/iteration-plan.md`

5. Reliability Plan quando houver movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração de persistência ou segurança

Quando faltar um requisito obrigatório, o Downstream para antes da Delivery, indica o responsável e orienta a próxima ação.

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

Registrar evidências significativas de entrega no trail da sessão ativa em `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`.

## O Downstream deve preservar

Rastreabilidade desde o estado atual e o assessment até a implementação, validação e promoção.
