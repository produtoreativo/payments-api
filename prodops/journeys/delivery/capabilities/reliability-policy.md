# Reliability Policy

Confiabilidade é planejada antes da implementação e validada antes da promoção.

## Reliability Plan

O Reliability Plan é **obrigatório** quando qualquer um dos seguintes gatilhos canônicos estiver presente: movimentação financeira, integração externa, mudança de SLO, risco alto ou crítico, ou alteração de persistência ou segurança. Fora desses gatilhos, o Reliability Plan é opcional. Quando presente, o plano define:
- Riscos e mitigações
- OBCs (Observable Business Contracts) com thresholds de sucesso mensuráveis
- Sugestões de SLO para eventos no caminho crítico

O Reliability Plan fica em: `prodops/journeys/assessment/reliability-plans/`

## OBCs

Um OBC ancora a implementação a um resultado de negócio. Define o que "pronto" significa em termos observáveis e mensuráveis. OBCs devem existir antes de qualquer código ser escrito para um item Downstream.

Arquivos de OBC: `prodops/artifacts/business/obcs/`

## Definition of Done

Uma capability não está completa até que o [Definition of Done](../../../templates/engineering/definition-of-done.md) seja satisfeito, incluindo os critérios de confiabilidade.

## Modos de falha

Modos de falha conhecidos devem ser documentados no Reliability Plan (`risks.md`) antes de a capability entrar em produção. Para cada modo de falha:
- Definir a condição de acionamento.
- Definir o comportamento esperado do sistema (degradação controlada, resposta de erro, retry).
- Definir o sinal observável (entrada de log, métrica, alerta).

## Requisitos de confiabilidade por comportamento

Para cada comportamento implementado no Hack Flow, verificar os seguintes requisitos durante o Green Bar:

| Requisito | Descrição |
|---|---|
| **Timeout** | Chamadas ao provedor externo têm timeout configurado. Sem timeout indefinido. |
| **Retry** | Retentativas usam a mesma `Idempotency-Key`. Retry sem idempotência cria duplicatas. |
| **Idempotência** | A mesma operação executada duas vezes retorna o mesmo estado, sem efeitos colaterais adicionais. |
| **Tratamento de exceções** | Erros do provedor são capturados e transformados em resposta HTTP com `message` significativa. |
| **Mensagens consistentes** | Mensagens de erro são estáveis (não mudam por retry). Facilita diagnóstico em suporte. |
| **Códigos HTTP** | Status codes correspondem à semântica: 201 (criado), 400 (input inválido), 404 (não encontrado), 409 (conflito/estado inválido), 422 (regra de negócio). |
| **Degradação controlada** | Falha de dependência externa (provedor, SQS, DynamoDB) não derruba fluxos independentes. |

Esses requisitos são verificados no [Definition of Done](../../../templates/engineering/definition-of-done.md) — seção Reliability.

Para detalhes sobre como aplicar durante o TDD cycle: [ProdOps TDD — Confiabilidade no ciclo](../practices/prodops-tdd.md).

## Validação pós-deploy

Após o deploy, validar os critérios de confiabilidade definidos no OBC. Registrar evidências no trail da sessão ativa em `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md` e em `prodops/journeys/operation/operational-trail.md`.
