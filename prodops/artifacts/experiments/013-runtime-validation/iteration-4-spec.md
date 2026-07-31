# EXP-013 --- Iteration 4

## Delivery Happy Path

### Objetivo

A partir desta iteração **não evoluir a infraestrutura do Runtime**. Ela
é considerada suficiente para o experimento.

O objetivo é validar que **uma Feature consegue percorrer um Happy Path
completo**, refletindo em tempo real:

-   Operational Timeline (CloudEvents)
-   Derived State
-   GitHub Project (COR)
-   Datadog

Sem implementar Rework, Blocking, Replay ou Diligence.

------------------------------------------------------------------------

## Escopo

Expandir o catálogo adicionando apenas os eventos necessários para o
caminho feliz:

-   Delivery.Bootstrap.Completed
-   Delivery.Hack.Started
-   Delivery.Hack.Completed
-   Delivery.Sync.Started
-   Delivery.Sync.Completed
-   Delivery.Finish.Started
-   Delivery.Finish.Completed
-   Delivery.Ship.Started
-   Delivery.Ship.Completed
-   Delivery.Validate.Started
-   Shared.Gate.Passed
-   Delivery.Validate.Completed
-   Delivery.Promote.Started
-   Delivery.Promote.Completed

Todos devem seguir exatamente o mesmo contrato CloudEvents adotado na
Iteration 3.

------------------------------------------------------------------------

## Runtime

Não criar novos componentes.

Apenas expandir:

-   catalog/events.yaml
-   producer
-   validator

O Runtime continua reagindo apenas ao evento recebido.

------------------------------------------------------------------------

## Timeline

Executar uma única Feature piloto do início ao fim.

Ao final a Timeline deverá conter todos os CloudEvents do Happy Path em
ordem cronológica.

------------------------------------------------------------------------

## Derived State

Validar que o estado derivado evolui corretamente durante a execução.

Ao final:

DONE

------------------------------------------------------------------------

## GitHub Project

Após cada evento que altera estado:

Atualizar:

-   oem-state
-   oem-last-event

Validar visualmente que a Feature evolui nas Views já existentes.

Não criar novas Views.

------------------------------------------------------------------------

## Datadog

Após cada evento:

Enviar runtime.event.received.

Criar um dashboard mínimo contendo:

-   Último estado
-   Quantidade de eventos
-   Timeline temporal
-   Filtro por runtime-correlation-id
-   Filtro por issue

O objetivo é conseguir acompanhar uma execução completa.

Não criar métricas complexas.

------------------------------------------------------------------------

## Evidências

Gerar:

-   timeline completa
-   derived-state final
-   screenshot/export do GitHub Project
-   screenshot/export do Dashboard Datadog
-   logs da execução

------------------------------------------------------------------------

## Restrições

Não implementar:

-   Rework
-   Blocking
-   Lookback
-   Replay
-   Diligence
-   Pipeline
-   Webhooks
-   AWS EventBridge
-   Kafka
-   SQS
-   SNS

Não refatorar a arquitetura.

Adicionar apenas o necessário para concluir o Happy Path.

------------------------------------------------------------------------

## Definition of Done

Uma única execução deve demonstrar visualmente:

CloudEvents → Timeline → Derived State → GitHub Project → Datadog

Todos sincronizados durante o ciclo completo de uma Feature.

------------------------------------------------------------------------

## Relatório Final

Produzir um relatório contendo:

-   Arquivos modificados
-   Eventos adicionados
-   Evidências coletadas
-   Capturas do GitHub Project
-   Capturas do Datadog
-   Gaps encontrados
-   Ajustes recomendados antes da Iteration 5

Parar imediatamente após concluir esta iteração.
