# EXP-013 --- Iteration 5

## Multi-Feature Runtime Validation

### Objetivo

Validar que o Runtime implementado é capaz de acompanhar **múltiplas
Features simultaneamente**, mantendo sincronizados:

-   CloudEvents
-   Timeline
-   Derived State
-   GitHub Project
-   Datadog

Sem adicionar nova infraestrutura.

------------------------------------------------------------------------

## Escopo

Utilizar três Features existentes:

-   FTR-001
-   FTR-002
-   FTR-003

Executar exatamente o mesmo Happy Path já implementado.

Não criar novos eventos.

Não alterar o contrato CloudEvents.

------------------------------------------------------------------------

## Execução

Criar um script:

`bootstrap-multi-feature.sh`

Executar as três Features de forma **intercalada**, por exemplo:

1.  FTR-001 Bootstrap.Started
2.  FTR-002 Bootstrap.Started
3.  FTR-003 Bootstrap.Started
4.  FTR-001 Bootstrap.Completed
5.  FTR-002 Bootstrap.Completed ...

Cada Feature deve possuir seu próprio `runtime-correlation-id`.

------------------------------------------------------------------------

## Validações

Confirmar que:

-   cada Timeline contém apenas os eventos da sua Feature;
-   cada Derived State evolui independentemente;
-   cada Issue possui `oem-state` e `oem-last-event` corretos;
-   o Datadog permite filtrar por `issue` e `runtime-correlation-id`.

------------------------------------------------------------------------

## GitHub

Não criar novos campos.

Validar apenas que o Project acompanha corretamente as três Features.

Registrar evidências visuais.

------------------------------------------------------------------------

## Datadog

Aprimorar apenas o dashboard existente.

Adicionar filtros por:

-   issue
-   runtime-correlation-id

Não criar novas métricas.

------------------------------------------------------------------------

## Evidências

Gerar:

-   timeline das três Features
-   derived-state das três Features
-   logs
-   export do dashboard
-   capturas do GitHub Project

------------------------------------------------------------------------

## Experiment Findings

Separar obrigatoriamente:

### Runtime Findings

Problemas da implementação.

### Framework Findings

Descobertas que indicam evolução do ProdOps.

### External Findings

Limitações do GitHub, Datadog ou ferramentas.

------------------------------------------------------------------------

## Restrições

Não implementar:

-   Rework
-   Blocking
-   Lookback
-   Replay
-   Diligence
-   State Machine
-   Webhooks
-   GitHub Actions
-   EventBridge
-   Kafka
-   SNS
-   SQS

------------------------------------------------------------------------

## Definition of Done

O experimento será considerado concluído quando três Features puderem
ser acompanhadas simultaneamente, cada uma mantendo sua própria
Timeline, Derived State, sincronização no GitHub Project e
observabilidade no Datadog, utilizando exatamente a mesma infraestrutura
construída nas iterações anteriores.

------------------------------------------------------------------------

## Relatório Final

Produzir:

-   arquivos modificados;
-   evidências coletadas;
-   resultados por Feature;
-   Experiment Findings;
-   limitações encontradas;
-   recomendações para a Iteration 6.

Parar ao final da validação, sem iniciar novos cenários.
