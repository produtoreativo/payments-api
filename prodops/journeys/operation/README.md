# Operation

## Responsabilidade

Operar e evoluir o produto em produção.

## Quando começa

A Operation inicia após a promoção da entrega pela fase Promote do CI Async.

## O que faz

- operação contínua do produto em produção
- observabilidade e monitoramento
- resposta a incidentes
- coleta de métricas operacionais
- postmortems e aprendizado operacional

Os aprendizados operacionais podem originar novos itens para o **Repository Tracking List**. Esse é o mecanismo pelo qual a Operation alimenta o ciclo de evolução do produto.

## Arquivos

| Arquivo | Propósito |
|---|---|
| [incidents.md](incidents.md) | Registro e resposta a incidentes |
| [postmortems.md](postmortems.md) | Postmortems e análise de causa raiz |
| [runbooks.md](runbooks.md) | Runbooks operacionais |
| [operational-trail.md](operational-trail.md) | Trilha append-only de eventos operacionais |

## Relação com outras jornadas

- **Delivery** alimenta a Operation com releases e evidências de deploy — Operation inicia após Promote.
- **Assessment** recebe sinais de operation para atualizar riscos e Reliability Plan.
- **Diligence** observa a operação e dispara verificações quando anomalias são detectadas.
- **Repository Tracking List** recebe novos itens originados de aprendizados operacionais.
