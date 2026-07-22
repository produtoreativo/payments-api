# Observability Policy

Observabilidade é um entregável de primeira classe. Código que altera comportamento observável deve validar saída de logs, estrutura de erros e rastreabilidade antes de ser considerado completo.

## Regras de logging

- Usar log JSON estruturado (pino). Não usar `console.log`.
- Toda requisição deve carregar `correlationId` e `tenantId` no contexto de log.
- Logar no nível `info`: requisição recebida, chamada ao provedor iniciada, resultado persistido.
- Logar no nível `warn`: retentativas, resposta degradada do provedor, fallback ativado.
- Logar no nível `error`: exceções não tratadas, erros do provedor que afetam o cliente.
- Nunca logar secrets, tokens ou PII. `X-Api-Token` e `ADMIN_SECRET` devem estar nos redact paths do pino.

## Respostas de erro

- Erros HTTP 4xx devem retornar um campo `message` com descrição legível por humanos.
- Erros HTTP 5xx não devem expor stack traces internos ou detalhes do provedor.
- Todas as respostas de erro devem incluir o `correlationId` para rastreabilidade de suporte.

## Rastreabilidade

- O header `X-Correlation-Id` deve ser propagado da requisição para todas as chamadas downstream e entradas de log.
- `tenantId` deve estar presente em toda linha de log que registra uma ação de negócio.
- IDs de pagamento do provedor (`providerPaymentId`) devem ser logados quando conhecidos.

## Metrics

- Registrar métricas de negócio nos eventos críticos: criação de invoice, confirmação de pagamento, rejeição de autorização.
- Métricas devem ter dimensões de `tenantId` e `status` para permitir agregação por tenant e por resultado.
- Não bloquear o fluxo principal em caso de falha de métrica.

## Health checks

- Endpoints de health check (`/health`) devem verificar disponibilidade de DynamoDB e SQS.
- Health check não deve incluir dados do tenant — apenas disponibilidade de infraestrutura.

## Observability First (princípio)

Antes de implementar, definir:
- Quais logs serão emitidos e em qual nível.
- Qual `correlationId` propagará pela cadeia de chamadas.
- Quais métricas serão registradas.

Observabilidade não é um passo pós-implementação. É planejada junto com o contrato. Ver [ProdOps TDD — Observability First](../practices/prodops-tdd.md).

## Validação em testes

A validação de observabilidade faz parte do [Hack Flow](../phases/hack/README.md). Após o Green Bar, verificar que:
- As entradas de log esperadas são emitidas (usar o padrão Log String).
- Respostas de erro têm o `message` e a estrutura esperados.
- Nenhum dado sensível aparece nos logs.
