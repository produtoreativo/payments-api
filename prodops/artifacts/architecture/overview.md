# Architecture Overview — Payments API

> Atualizar sempre que houver mudança estrutural: novo módulo, rota, dependência
> externa, tabela de banco ou tópico de evento. Ver regra em [`AGENTS.md`](../../../AGENTS.md#arquitetura).
>
> Última atualização: 2026-07-17

## Fronteira de responsabilidade

Payments API é o System of Record do domínio de pagamentos deste produto. Checkout e outros consumidores usam o contrato interno da Payments API; Asaas atua como PSP externo por meio de um adaptador de integração.

```text
Checkout / consumidores
        |
        | contrato interno
        v
Payments API / Payments SOR
        |
        | contrato do provedor
        v
Asaas / outros PSPs
```

Payments é responsável por `invoiceId`, associação com `orderId`, tenant e cliente, seleção do provedor, idempotência, estado interno e histórico de transições. O PSP é responsável pela execução externa da cobrança e por seus identificadores e eventos. Status externos são normalizados pela Payments API; não devem ser expostos como a verdade operacional do produto.

Esta fronteira é uma decisão de produto e arquitetura. Os estados e eventos efetivamente suportados continuam definidos pelos OBCs, BDD Features, Event Storming e código vigentes; este documento não promove comportamento novo para Downstream.

## Diagrama de componentes

```mermaid
graph TB
    subgraph Externos["Sistemas Externos"]
        Checkout["Checkout\nWeb / App"]
        Admin["Operador\nAdministrativo"]
        Asaas["Asaas\nGateway de Pagamento"]
        Consumer["Consumidor\nWebhook Callback"]
    end

    subgraph Entry["Ponto de entrada — AWS"]
        FnUrl["Lambda Function URL\nAuthType: NONE\nCORS: AllowOrigins *\nHeaders: X-Api-Token · X-Correlation-Id\n        X-Tenant-Id · Idempotency-Key\n        asaas-access-token"]
    end

    subgraph ApiLambda["API Lambda — {env}-payments-api\nnodejs22.x · 512MB · timeout 15s"]
        DDLayer["Datadog Extension Layer\narn:…:Datadog-Extension:97\n(staging + production)"]

        subgraph Auth["Autenticação"]
            Guard["ApiTokenGuard\nheader: X-Api-Token"]
        end

        subgraph Controllers["Controllers"]
            InvCtrl["InvoiceController\nPOST   /invoices\nGET    /invoices/:invoiceId\nDELETE /invoices/:invoiceId\nPOST   /invoices/:invoiceId/refund"]
            WkCtrl["WebhookConfigController\nPOST   /webhooks\nGET    /webhooks\nDELETE /webhooks/:webhookId"]
            AsaasWkCtrl["AsaasWebhookController\nPOST /webhook/payments\nGET  /webhook/payments/queue"]
            SandboxCtrl["AsaasSandboxController\nPOST /sandbox/asaas/payments/:providerPaymentId/confirm"]
            AdminCtrl["AdminTokenController\nPOST   /admin/tokens\nGET    /admin/tokens/:tenantId\nDELETE /admin/tokens/:tenantId/:tokenId"]
            HealthCtrl["HealthController\nGET /health\n(sem guard)"]
        end

        subgraph Services["Services"]
            InvSvc["InvoiceService"]
            WkSvc["WebhookService"]
            WkDelivery["WebhookDeliveryService\n@OnEvent payment.confirmed\n@OnEvent payment.cancelled"]
            ObsListener["ObservabilityListener\n@OnEvent payments.observability"]
            EventBus(["EventEmitter2\n─────────────\npayment.confirmed\npayment.cancelled\npayments.observability"])
        end
    end

    subgraph WorkerLambda["Worker Lambda — {env}-payments-webhook-worker\nnodejs22.x · 512MB · timeout 30s"]
        WebhookWorker["WebhookWorker\nSQSHandler · BatchSize 5\nReportBatchItemFailures\n→ InvoiceService.processProviderWebhook"]
    end

    subgraph Storage["Armazenamento — DynamoDB (PAY_PER_REQUEST · PITR)"]
        DynPay[("PaymentsTable\n{env}-PaymentsTable\n· PK + SK\n· GSI1: ProviderPaymentIndex\n  GSI1PK: PROVIDER# / GSI1SK: PAYMENT#\n  Projection: ALL\n────────────────\nTransactionsTable · {env}-TransactionsTable\n· PK + SK\nCustomersTable · {env}-CustomersTable\n· PK + SK\nTenantsTable · {env}-TenantsTable\n· PK + SK")]
        DynWk[("WebhooksTable\n{env}-WebhooksTable\n· PK + SK\n· GSI1: TenantWebhooksIndex\n  GSI1PK / GSI1SK · Projection: ALL")]
        SQS[("SQS — {env}-payments-webhook-queue\nVisibilityTimeout: 60s · Retenção: 14d\nmaxReceiveCount: 5\n────────────────\nDLQ — {env}-payments-webhook-dlq\nRetenção: 14d")]
    end

    subgraph Logs["CloudWatch Logs (retenção 30 dias)"]
        CWApi["/aws/lambda/{env}-payments-api"]
        CWWorker["/aws/lambda/{env}-payments-webhook-worker"]
    end

    subgraph Obs["Observabilidade"]
        DD["Datadog\nAPM · Métricas · Logs\nDD_SERVICE: payments-api\nDD_SITE: datadoghq.com"]
    end

    %% Entry → API
    Checkout -->|"X-Api-Token"| FnUrl
    Admin -->|"X-Admin-Secret"| FnUrl
    Asaas -->|"asaas-access-token"| FnUrl
    FnUrl --> Guard
    FnUrl -->|"sem guard"| HealthCtrl

    %% Auth → Controllers
    Guard --> InvCtrl
    Guard --> WkCtrl
    Guard --> AsaasWkCtrl
    Guard --> SandboxCtrl
    Guard --> AdminCtrl

    %% Controllers → Services
    InvCtrl --> InvSvc
    WkCtrl --> WkSvc
    AsaasWkCtrl --> InvSvc
    SandboxCtrl -->|"confirma pagamento\nna Sandbox"| Asaas
    AdminCtrl -->|"tokens de API\nem TenantsTable"| DynPay

    %% Services → Storage
    InvSvc --> DynPay
    InvSvc -->|"POST /v3/payments\nPOST /v3/customers"| Asaas
    InvSvc -->|"async (WEBHOOK_PROCESSING_MODE=async)"| SQS
    WkSvc --> DynWk
    WkDelivery --> DynWk

    %% Internal event bus
    InvSvc -->|"emit"| EventBus
    EventBus -->|"@OnEvent"| WkDelivery
    EventBus -->|"@OnEvent"| ObsListener

    %% Outbound delivery
    WkDelivery -->|"HTTPS POST\nX-Payments-Signature\nX-Payments-Delivery-Id"| Consumer

    %% Worker Lambda
    SQS -->|"SQS trigger"| WebhookWorker
    WebhookWorker --> DynPay

    %% Logs
    ApiLambda -.->|"stdout → CloudWatch"| CWApi
    WorkerLambda -.->|"stdout → CloudWatch"| CWWorker

    %% Observability
    ObsListener --> DD
    DDLayer -.->|"APM traces · metrics"| DD
    WkDelivery -->|"emit payments.observability"| EventBus
```

## Mudanças estruturais que exigem atualização deste diagrama

| Tipo de mudança | Exemplos |
| --- | --- |
| Novo módulo NestJS | `WebhooksModule`, `NotificationsModule` |
| Nova rota ou grupo de rotas | `GET /invoices/:id`, `POST /refunds` |
| Nova dependência externa | Novo gateway, Notification Service, antifraude |
| Nova tabela ou índice DynamoDB | `NotificationsTable`, novo GSI em `PaymentsTable` |
| Novo tópico de evento ou fila | `payment.refunded`, nova fila SQS |
| Mudança de autenticação em rota | Adicionar/remover guard em controller |

**Não** exige atualização: novos campos em DTOs, bugfixes dentro de um serviço
existente, novos cenários BDD sem nova infra, refatorações internas sem mudança
de contrato.

## Histórico de mudanças estruturais

| Data | Mudança |
| --- | --- |
| 2026-07-03 | Criação inicial do diagrama. Módulos: `InvoicesModule`, `AuthModule`, `WebhooksModule`, `ObservabilityModule`. Tabelas: `PaymentsTable`, `CustomersTable`, `TenantsTable`, `ProvidersTable`, `WebhooksTable`. |
| 2026-07-11 | Adicionados `AdminTokenController` (`POST /admin/tokens`, `GET /admin/tokens/:tenantId`, `DELETE /admin/tokens/:tenantId/:tokenId`, autenticação via header `X-Admin-Secret`, tokens persistidos em `TenantsTable`) e a rota `GET /invoices/:invoiceId` no `InvoiceController`. |
| 2026-07-12 | Consolidada a fronteira Payments SOR ↔ PSP que antes estava duplicada em `docs/`; nenhum contrato de runtime foi alterado. |
| 2026-07-17 | Retroativo: adicionados `HealthController` (`GET /health`, sem guard), `WebhookWorker` (Lambda SQS trigger separado), `TransactionsTable`, GSI1 (ProviderPaymentIndex) em PaymentsTable. Corrigidos nomes de parâmetros de rota (`:webhookId`, `:providerPaymentId`). Adicionada aresta `WkDelivery → emit payments.observability`. |
| 2026-07-23 | Diagrama atualizado com dados reais da IaC: Lambda Function URL como ponto de entrada explícito (AuthType: NONE), Datadog Extension Layer (arn:…:Datadog-Extension:97), CloudWatch Log Groups com retenção 30d, parâmetros reais de SQS (VisibilityTimeout 60s, retenção 14d, maxReceiveCount 5), nomes reais de tabelas e GSIs com chaves de partição/range e ProjectionType. Removidos GSI2 (StatusOrderIndex) e ProvidersTable — não provisionados na IaC (`dynamodb.yaml`). |
| 2026-07-31 | DS-41 (credit-card-authorization-confirmation): adicionada rota `POST /invoices/:invoiceId/refund` no `InvoiceController`; adicionado `hostedPaymentUrl` em `InvoiceResponseDto`; adicionado status `REFUND_REQUESTED` em `InvoiceStatus`; emissão de `payment.card.hosted_invoice.created` e `payment.card.refund.requested`. |
