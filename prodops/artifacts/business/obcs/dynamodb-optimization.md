# OBC - Persistência DynamoDB Otimizada para Produção

## Status

Downstream. Status `Entrou` em `prodops/artifacts/governance/plans/iteration-plan.md` — capacidade operacional derivada do EXP-011.

## Business Outcome

As tabelas DynamoDB de produção da Payments API operam sem risco de throttling e com recuperação point-in-time habilitada. Nenhum pagamento falha por throttling de banco de dados e nenhum dado de pagamento é irrecuperável por ausência de backup contínuo. A cobrança por uso real (PAY_PER_REQUEST) elimina o desperdício de capacidade alocada que nunca é consumida.

### Em linguagem executiva

Antes, a Payments API usava um modelo de banco de dados com capacidade fixa contratada: se chegassem 3 ou mais escritas por segundo, o banco recusava as requisições — como uma linha telefônica que bloqueia ligações quando está ocupada. Agora, o banco escala automaticamente com a demanda, sem limite fixo e sem cobrança pelo que não é usado.

Além disso, qualquer dado de pagamento pode ser restaurado para qualquer ponto nos últimos 35 dias — equivalente a um "Ctrl+Z" de banco de dados para situações de erro operacional ou corrupção de dados.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `dynamodb.throttle` | Requisição throttled pelo DynamoDB — não deve ocorrer com PAY_PER_REQUEST. | `table`, `operation`, `env` |
| `dynamodb.pitr.enabled` | PITR habilitado na tabela — confirmado via `describe-continuous-backups`. | `table`, `env` |
| `dynamodb.billing_mode` | Billing mode confirmado como PAY_PER_REQUEST. | `table`, `env` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Eventos de throttling DynamoDB em produção em 30 dias. | 0 |
| Tabelas com PITR habilitado (todas as 5 tabelas críticas). | 100% |
| Tabelas com billing PAY_PER_REQUEST. | 100% |
| GSIs sem queries documentadas removidos. | 100% (GSI2 PaymentsTable, GSI1 TransactionsTable removidos) |

## Reliability Rules

- Nenhuma tabela deve operar com `BillingMode: PROVISIONED` sem Auto Scaling — throttling com ≥2 escritas/s é risco crítico para qualquer carga de pagamento real.
- PITR deve estar habilitado em todas as tabelas que persistem dados de pagamento: PaymentsTable, TransactionsTable, CustomersTable, TenantsTable, WebhooksTable.
- GSIs devem existir apenas quando há query documentada que os utiliza. GSIs sem uso geram custo de WCU em toda escrita.
- A ProvidersTable foi removida — nenhuma tabela sem repositório ativo deve existir no stack de produção.
- Mudanças de schema DynamoDB (adição/remoção de GSI, alteração de billing) devem ser feitas via `api/infra/dynamodb.yaml` e deployadas via CI/CD — nunca via console AWS.

## Response Contract

Não aplicável — mudança de infraestrutura de persistência sem alteração de contrato de API.

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/dynamodb-optimization.feature`
- Experiment: `prodops/artifacts/experiments/011-dynamodb-optimization/experiment.md`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- OBCs relacionados: `prodops/artifacts/business/obcs/production-cicd-pipeline.md`
