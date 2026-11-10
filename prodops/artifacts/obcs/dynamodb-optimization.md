# OBC - Persistência DynamoDB Otimizada para Produção

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-49 |
| Iteração | v0.9.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-49 (#45) — v0.9.0, PR #121. Registro anterior: Downstream. Status `Entrou` em `prodops/artifacts/plans/iteration-plan.md` — capacidade operacional derivada do EXP-011.
**Pendência:** iteração concluída (PR #121); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-004](../business-signals/BS-004.md) |
| Business Intent | [PI-011](../business-intents/PI-011.md) |
| Product Tracking Item | issue #45 (DS-49), ver `prodops/artifacts/plans/iteration-plan.md` |
| Experimento | [EXP-011](../experiments/011-dynamodb-optimization/experiment.md) |

## Business Outcome

As tabelas DynamoDB de produção da Payments API operam sem risco de throttling e com recuperação point-in-time habilitada. Nenhum pagamento falha por throttling de banco de dados e nenhum dado de pagamento é irrecuperável por ausência de backup contínuo. A cobrança por uso real (PAY_PER_REQUEST) elimina o desperdício de capacidade alocada que nunca é consumida.

### Em linguagem executiva

Antes, a Payments API usava um modelo de banco de dados com capacidade fixa contratada: se chegassem 3 ou mais escritas por segundo, o banco recusava as requisições — como uma linha telefônica que bloqueia ligações quando está ocupada. Agora, o banco escala automaticamente com a demanda, sem limite fixo e sem cobrança pelo que não é usado.

Além disso, qualquer dado de pagamento pode ser restaurado para qualquer ponto nos últimos 35 dias — equivalente a um "Ctrl+Z" de banco de dados para situações de erro operacional ou corrupção de dados.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/dynamodb-optimization.feature`; marcar após verificação.

- [ ] Tabelas operam com billing PAY_PER_REQUEST
- [ ] PITR esta habilitado em todas as tabelas criticas
- [ ] GSIs sem uso foram removidos
- [ ] TransactionsTable nao possui GSIs desnecessarios
- [ ] ProvidersTable nao existe no stack de producao
- [ ] Escrita em alta carga nao gera throttling

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | n/a — capacidade de plataforma/framework, não é Product Service |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `dynamodb.throttle` | [apurar] | Requisição throttled pelo DynamoDB — não deve ocorrer com PAY_PER_REQUEST. | `table`, `operation`, `env` |
| `dynamodb.pitr.enabled` | [apurar] | PITR habilitado na tabela — confirmado via `describe-continuous-backups`. | `table`, `env` |
| `dynamodb.billing_mode` | [apurar] | Billing mode confirmado como PAY_PER_REQUEST. | `table`, `env` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Eventos de throttling DynamoDB em produção em 30 dias. | 0 | [apurar] |
| Tabelas com PITR habilitado (todas as 5 tabelas críticas). | 100% | [apurar] |
| Tabelas com billing PAY_PER_REQUEST. | 100% | [apurar] |
| GSIs sem queries documentadas removidos. | 100% (GSI2 PaymentsTable, GSI1 TransactionsTable removidos) | [apurar] |

## Reliability Rules

- Nenhuma tabela deve operar com `BillingMode: PROVISIONED` sem Auto Scaling — throttling com ≥2 escritas/s é risco crítico para qualquer carga de pagamento real.
- PITR deve estar habilitado em todas as tabelas que persistem dados de pagamento: PaymentsTable, TransactionsTable, CustomersTable, TenantsTable, WebhooksTable.
- GSIs devem existir apenas quando há query documentada que os utiliza. GSIs sem uso geram custo de WCU em toda escrita.
- A ProvidersTable foi removida — nenhuma tabela sem repositório ativo deve existir no stack de produção.
- Mudanças de schema DynamoDB (adição/remoção de GSI, alteração de billing) devem ser feitas via `api/infra/dynamodb.yaml` e deployadas via CI/CD — nunca via console AWS.

## Response Contract

Não aplicável — mudança de infraestrutura de persistência sem alteração de contrato de API.

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| — | [apurar] | [apurar] |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/dynamodb-optimization.feature`
- Experiment: `prodops/artifacts/experiments/011-dynamodb-optimization/experiment.md`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- OBCs relacionados: `prodops/artifacts/obcs/production-cicd-pipeline.md`
