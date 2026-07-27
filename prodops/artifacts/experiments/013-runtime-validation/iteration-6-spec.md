# EXP-013 --- Iteration 6

## Operational Validation (Non-Uniform Execution)

### Objetivo

Validar que o Runtime representa corretamente o estado operacional
quando diferentes Features estão em momentos diferentes da jornada.

O foco **não é adicionar infraestrutura**, mas provar que GitHub
Project, Timeline e Datadog permanecem consistentes durante uma operação
real.

------------------------------------------------------------------------

## Cenário

Utilizar as mesmas três Features:

-   FTR-001 (#76)
-   FTR-002 (#77)
-   FTR-003 (#78)

Executar um fluxo não uniforme, por exemplo:

-   FTR-001 termina em **DONE**
-   FTR-002 para em **VALIDATING**
-   FTR-003 para em **HACKING**

Não implementar Rework nem Blocking.

------------------------------------------------------------------------

## Runtime

Não criar novos componentes.

Não alterar CloudEvents.

Não alterar Timeline.

Não alterar Derived State.

------------------------------------------------------------------------

## GitHub Project

Validar que cada Issue permanece com:

-   oem-state correto
-   oem-last-event correto

Mesmo estando em estados diferentes.

Registrar evidências.

------------------------------------------------------------------------

## Datadog

Utilizar o dashboard existente.

Validar filtros por:

-   issue
-   runtime-correlation-id
-   state

Demonstrar que as três Features podem ser acompanhadas simultaneamente.

------------------------------------------------------------------------

## Evidências

Gerar:

-   timelines das três Features
-   derived-state das três Features
-   export do dashboard
-   capturas do GitHub Project
-   logs da execução

------------------------------------------------------------------------

## Experiment Findings

Separar obrigatoriamente:

### Runtime Findings

### Framework Findings

### External Findings

Registrar apenas descobertas novas.

------------------------------------------------------------------------

## Restrições

Não implementar:

-   Rework
-   Blocking
-   Lookback
-   Replay
-   Diligence
-   Webhooks
-   GitHub Actions
-   AWS EventBridge
-   Kafka
-   Pipeline

------------------------------------------------------------------------

## Definition of Done

Ao final deve ser possível observar simultaneamente:

-   uma Feature concluída;
-   uma Feature em validação;
-   uma Feature em desenvolvimento;

com GitHub Project, Timeline, Derived State e Datadog refletindo
exatamente esses estados.

------------------------------------------------------------------------

## Relatório Final

Produzir:

-   arquivos modificados;
-   evidências;
-   findings;
-   limitações;
-   avaliação se o EXP-013 já atingiu seu objetivo principal ou quais
    lacunas ainda permanecem antes do encerramento do experimento.

Parar imediatamente após esta iteração.
