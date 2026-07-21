# Upstream Experiment 009 — Serverless Maturity Assessment

Localização canônica:

```text
prodops/journeys/discovery/experiments/009-serverless-maturity-assessment/experiment.md
```

## Status

- [ ] Planned
- [x] In Progress
- [ ] Completed
- [ ] Cancelled

---

# Business Goal

Avaliar a maturidade atual da configuração Serverless (AWS SAM) do Payments API, identificar lacunas em relação às melhores práticas do setor, e produzir um plano de melhoria priorizado com evidências que fundamente decisões de arquitetura e capacidade operacional para produção.

O experimento responde à necessidade de aumentar a confiança na infraestrutura antes de escalar o tráfego de pagamentos reais.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Comportamento da Payments API
- [x] Lógica de domínio de Payments
- [x] Integração com provedor
- [x] Processamento de webhook
- [x] Persistência
- [x] Contrato de API/evento de propriedade do Payments
- [x] Testes locais ou evidência executável

## Dependências externas

- Pipeline CI/CD de produção (ausente — depende de decisão de operações)
- Limites de capacidade do DynamoDB (dependem de projeção de carga real de negócio)
- Ativação do Datadog (depende de contrato/billing com Datadog)

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório

---

# Question to Answer

1. Em que nível de maturidade Serverless o Payments API se encontra atualmente?
2. Quais lacunas críticas precisam ser resolvidas antes de escalar para produção com carga real?
3. Quais melhorias podem ser feitas de forma incremental sem risco de regressão?
4. Existe risco de throttling de DynamoDB sob carga real com a configuração atual?
5. Por que o Datadog está desabilitado em produção e qual é o impacto em observabilidade?
6. A ausência de VPC representa risco de segurança aceitável para o modelo de ameaça atual?

---

# Hypothesis

O Payments API possui uma base sólida de boas práticas Serverless (IAM least-privilege, partial batch failures, separação de stacks, OIDC keyless auth), mas apresenta lacunas operacionais críticas que aumentam o risco para produção:

- **Observabilidade**: Datadog configurado mas desabilitado — blind spot completo em produção.
- **Capacidade**: DynamoDB com 1 RCU/WCU por tabela sem Auto Scaling — throttling certo sob qualquer carga não trivial.
- **Cold start**: NestJS sem Provisioned Concurrency — latência de primeiro acesso elevada.
- **Produção manual**: Nenhum pipeline automatizado para deploy de produção — risco operacional.

A hipótese é que a maturidade atual é **nível 2 de 5** (fundação correta, mas não pronta para produção com carga) e que as lacunas podem ser fechadas com 3–4 sprints de trabalho Downstream.

---

# Scope

- Análise estática completa dos arquivos IaC (`api/infra/lambda.yaml`, `api/infra/dynamodb.yaml`, `api/samconfig.toml`)
- Análise dos handlers Lambda (`api/src/lambda.ts`, `api/src/webhook-worker.ts`)
- Análise da stack de observabilidade (`api/src/observability/`)
- Análise da configuração IAM, SQS, e CloudWatch
- Comparação com AWS Well-Architected Framework — Pilar Serverless
- Produção de tabela comparativa atual vs. recomendação
- Plano de experimentos Upstream derivados

---

# Out of Scope

- Implementação das melhorias (apenas análise e plano neste experimento)
- Migração de banco de dados ou schema changes
- Integração com outros sistemas fora deste repositório
- Análise de custos AWS detalhada (sem dados de carga real)
- Avaliação de outros provedores de pagamento além de Asaas

---

# Implementation

1. Leitura completa dos artefatos IaC e handlers
2. Mapeamento de práticas atuais contra referências (AWS Well-Architected, Serverless Land, Datadog Lambda Best Practices)
3. Atribuição de score de maturidade por dimensão
4. Elaboração da tabela comparativa
5. Identificação de experimentos derivados
6. Produção do Decision Package

---

# Code Produced

Nenhum código de produção produzido neste experimento — é uma investigação documental e de análise estática. Os artefatos de saída são documentação e plano de ação.

---

# Functional Validation

Análise estática dos arquivos IaC e código-fonte. Sem execução de testes ou deploy de sandbox nesta fase.

---

# Technical Findings

## Framework e IaC

| Aspecto | Situação Atual |
|---|---|
| Framework | **AWS SAM** (não Serverless Framework) — transform `AWS::Serverless-2016-10-31` |
| Runtime | `nodejs22.x` — versão LTS atual, correto |
| Stacks | 2 stacks separadas: `payments-api-dynamo-{env}` (stateful) + `payments-api-{env}` (efêmero) |
| Deploy | `sam deploy` via GitHub Actions OIDC para staging/experiment; **manual para produção** |
| Ambientes | `staging`, `experiment`, `production` em `samconfig.toml` |

## Lambda Functions

| Aspecto | ApiFunction | WebhookWorkerFunction |
|---|---|---|
| Handler | `lambda.handler` (NestJS + serverless-express) | `webhook-worker.handler` (NestJS ApplicationContext) |
| Memória | 512 MB | 512 MB |
| Timeout | 15s | 30s |
| Trigger | Lambda Function URL (`AuthType: NONE`) | SQS (BatchSize: 5) |
| Cold start mitigation | Module-level cache (`cachedServer`) | Module-level cache (`cachedApp`) |
| Provisioned Concurrency | ❌ Ausente | ❌ Ausente |

## Segurança e IAM

| Aspecto | Situação | Avaliação |
|---|---|---|
| IAM roles | 2 roles dedicadas (por função) | ✅ Correto — não usa role SAM auto-gerada |
| `DeleteItem` | Ausente de todas as policies | ✅ Intencional — soft delete |
| `AuthType: NONE` na Function URL | Auth exclusivamente na camada de aplicação | ⚠️ Risco aceitável mas superfície de ataque maior |
| OIDC para CI/CD | Sem long-lived credentials no GitHub | ✅ Best practice |
| ExperimentDeployRole | Scoped a `experiment-*` | ✅ Correto |
| Segredos com `NoEcho` | Tokens Asaas, AdminSecret | ✅ Correto |
| VPC | Ausente | ⚠️ Sem isolamento de rede privada |

## Observabilidade

| Aspecto | Situação | Avaliação |
|---|---|---|
| Datadog APM | Configurado mas `DatadogEnabled=false` em **todos** os ambientes | ❌ Crítico — produção sem APM |
| Custom metrics | 9 métricas de negócio via DogStatsD | ✅ Excelente design |
| Business spans | `withBusinessSpan()` com tags OBC e reliability_scenario | ✅ Excelente |
| Log injection | Configurado com pino, JSON em produção | ✅ Correto |
| PII redaction | Campos cardNumber, cvv, tokens redactados em logs | ✅ Correto |
| X-Correlation-Id | Middleware de propagação | ✅ Correto |
| CloudWatch Logs | RetentionInDays: 30 | ✅ Correto |
| AWS X-Ray | Ausente | ⚠️ Sem distributed tracing nativo AWS |
| Datadog Extension Layer | ARN parametrizado, não ativado | ⚠️ Infraestrutura pronta, não ativada |

## Persistência (DynamoDB)

| Aspecto | Situação | Avaliação |
|---|---|---|
| Billing mode | `PROVISIONED` — 1 RCU / 1 WCU por tabela | ❌ Crítico — throttling sob qualquer carga |
| Auto Scaling | Ausente | ❌ Crítico |
| Separação de stacks | DynamoDB em stack própria | ✅ Dados sobrevivem a re-deploys |
| PAY_PER_REQUEST | Não configurado | ⚠️ Alternativa mais simples para escala variável |
| Backup/PITR | Não configurado em nenhuma tabela | ⚠️ Risco de perda de dados em produção |

## Mensageria (SQS)

| Aspecto | Situação | Avaliação |
|---|---|---|
| DLQ | Configurada com 14 dias de retenção | ✅ Correto |
| RedrivePolicy | `maxReceiveCount: 5` | ✅ Correto |
| VisibilityTimeout | 60s (≥ 2× timeout do worker 30s) | ✅ Correto |
| `ReportBatchItemFailures` | Template + handler implementados | ✅ Correto — partial batch failure |
| Monitoramento DLQ | Sem alarme CloudWatch na DLQ | ⚠️ DLQ pode acumular silenciosamente |
| Encryption at rest | Não configurado (SQS padrão SSE-SQS) | ⚠️ Verificar requisito regulatório |

## Cold Start e Performance

| Aspecto | Situação | Avaliação |
|---|---|---|
| Framework | NestJS (pesado) | ⚠️ Cold start estimado 400–900ms |
| Module caching | `cachedServer` / `cachedApp` | ✅ Warm invocations rápidas |
| Provisioned Concurrency | Ausente | ❌ Cold starts em produção |
| Worker bootstrap | `createApplicationContext` (sem HTTP) | ✅ Mais leve que API function |
| Bundle size | Build via `tsconfig.build.json` | ⚠️ Sem tree-shaking ou bundler (esbuild) configurado |

---

# DynamoDB Architecture Analysis

## Design Pattern Adotado

O sistema usa um **design híbrido** — multi-tabela por bounded context com single-table design aplicado dentro de contextos específicos:

| Abordagem | Onde é aplicada |
|---|---|
| **Multi-table por domínio** | 6 tabelas separadas: Payments, Transactions, Customers, Tenants, Providers, Webhooks |
| **Single-table dentro do domínio** | `PaymentsTable` hospeda 3 tipos de item; `TenantsTable` hospeda 2 tipos de item |

Este é um padrão defensável para DynamoDB — isola bounded contexts e evita hotspots entre domínios, enquanto aplica o single-table pattern dentro de cada contexto para suportar múltiplos access patterns.

---

## Mapeamento de Entidades por Tabela

### PaymentsTable

Três tipos de item compartilham a mesma tabela com prefixos distintos no PK/SK:

#### Tipo 1 — Invoice Record (item principal)

| Chave | Padrão | Exemplo |
|---|---|---|
| `PK` | `TENANT#<tenantId>` | `TENANT#t-abc123` |
| `SK` | `INVOICE#<invoiceId>` | `INVOICE#inv_01HX` |
| `GSI1PK` (ProviderPaymentIndex) | `PROVIDER#<provider>` | `PROVIDER#ASAAS` |
| `GSI1SK` (ProviderPaymentIndex) | `PAYMENT#<providerPaymentId>` | `PAYMENT#pay_123` |
| `GSI2PK` (PaymentStatusIndex) | `STATUS#<status>` | `STATUS#OPEN` |
| `GSI2SK` (PaymentStatusIndex) | `ORDER#<orderId>` | `ORDER#order-001` |

O item armazena o objeto completo `invoice` como blob JSON aninhado **E** escalares denormalizados no topo (`status`, `amount`, `provider`, etc.). Isso é um padrão aceitável para flexibilidade de leitura, mas gera redundância de escrita.

#### Tipo 2 — Idempotency Key

| Chave | Padrão |
|---|---|
| `PK` | `TENANT#<tenantId>` |
| `SK` | `IDEMPOTENCY#<idempotencyKey>` |

Sem atributos GSI — acessado exclusivamente por GetItem exato. Correto.

#### Tipo 3 — External Reference Pointer

| Chave | Padrão |
|---|---|
| `PK` | `EXTERNAL_REFERENCE#<externalReference>` |
| `SK` | `INVOICE` (literal) |

Item de ponteiro puro — dois hops de leitura: GetItem aqui → GetItem do invoice real. Design aceitável mas caro em volume alto.

---

### TransactionsTable

#### Tipo 1 — Provider Event Deduplication

| Chave | Padrão | Exemplo |
|---|---|---|
| `PK` | `PROVIDER_EVENT#<eventKey>` | `PROVIDER_EVENT#PAYMENT_RECEIVED:pay_123` |
| `SK` | `RAW` (literal) | `RAW` |

`eventKey = <EVENT_TYPE>:<providerPaymentId>`. Acessado por GetItem para deduplicação antes de processar webhooks.

> ⚠️ **Problema**: O `GSI1` definido no CloudFormation (`GSI1PK`/`GSI1SK`) **nunca é populado nem consultado** em nenhum repositório. É infraestrutura morta pagando 1 WCU em cada escrita e 1 RCU em cada leitura da tabela.

---

### CustomersTable

#### Tipo 1 — Customer-Provider Link

| Chave | Padrão | Exemplo |
|---|---|---|
| `PK` | `TENANT#<tenantId>` | `TENANT#t-abc123` |
| `SK` | `CUSTOMER#<customerId>#PROVIDER#<provider>` | `CUSTOMER#cus-01#PROVIDER#ASAAS` |

Sem GSI — acessado somente por GetItem exato (tenant + customer + provider). Sem access patterns de listagem. Correto para uso atual.

---

### TenantsTable

Single-table design para autenticação — dois tipos de item com access patterns complementares:

#### Tipo 1 — Token Hash Lookup

| Chave | Padrão |
|---|---|
| `PK` | `TOKEN_HASH#<sha256(rawToken)>` |
| `SK` | `METADATA` (literal) |

Lookup de autenticação: O-hop — GetItem direto pelo hash do token. Correto e eficiente.

#### Tipo 2 — Tenant Token List

| Chave | Padrão |
|---|---|
| `PK` | `TENANT_TOKENS#<tenantId>` |
| `SK` | `TOKEN#<tokenId>` |

Suporta `listByTenant` via Query com `begins_with(SK, "TOKEN#")`. Design correto para listagem + revogação.

> ℹ️ O campo `tokenHash` é armazenado neste item para possibilitar revogação sem re-derivação — trade-off intencional e correto.

---

### WebhooksTable

#### Tipo 1 — Webhook Registration

| Chave | Padrão | Exemplo |
|---|---|---|
| `PK` | `TOKEN#<tokenId>` | `TOKEN#tok-xyz` |
| `SK` | `WEBHOOK#<webhookId>` | `WEBHOOK#wh-001` |
| `GSI1PK` (TenantWebhooksIndex) | `TENANT#<tenantId>` | `TENANT#t-abc123` |
| `GSI1SK` (TenantWebhooksIndex) | `WEBHOOK#<webhookId>` | `WEBHOOK#wh-001` |

Suporta dois access patterns: por token (PK direto) e por tenant (via GSI). Correto.

---

### ProvidersTable

> ❌ **Tabela morta**: Definida no CloudFormation, exportada como output, referenciada como variável de ambiente no Lambda — mas **nenhum repositório em `api/src/` lê ou escreve nesta tabela**. Está consumindo 1 RCU e 1 WCU provisionados sem uso.

---

## Access Patterns — Análise por Repositório

### InvoiceRepository (PaymentsTable)

| Método | Operação DynamoDB | Observação |
|---|---|---|
| `findInvoice` | GetItem | ✅ Acesso direto por PK+SK |
| `saveInvoice` | PutItem × 3 | ✅ Invoice + ExternalRef + Idempotency em sequência |
| `updateInvoice` | PutItem × 2 | ⚠️ Full overwrite sem condição de versão |
| `findByIdempotencyKey` | GetItem → GetItem (2 hops) | ⚠️ Dois RCUs por consulta de idempotência |
| `findByExternalReference` | GetItem → GetItem (2 hops) | ⚠️ Dois RCUs por evento de webhook |
| `findByProviderPaymentId` | Query GSI × N providers (loop sequencial) | ❌ N+1 multi-provider — veja abaixo |
| `saveRawProviderEvent` | GetItem → PutItem condicional | ✅ Deduplicação correta |
| `hasRawProviderEvent` | GetItem | ✅ Correto |
| `findCustomerLink` | GetItem | ✅ Correto |
| `saveCustomerLink` | PutItem | ✅ Correto |

### WebhookRepository (WebhooksTable)

| Método | Operação DynamoDB | Observação |
|---|---|---|
| `save` | PutItem | ✅ Correto |
| `findOne` | GetItem | ✅ Correto |
| `findByTokenId` | Query + filtro in-memory | ⚠️ Inativos acumulam sem TTL ou delete |
| `findActiveByTenantId` | QueryByIndex + filtro in-memory | ⚠️ Idem |
| `countByTokenId` | `findByTokenId().length` | ❌ Busca todos os dados apenas para contar |
| `deactivate` | UpdateItem (`active=false`) | ⚠️ Soft delete acumula itens inativos permanentemente |

### TokenRepository (TenantsTable)

| Método | Operação DynamoDB | Observação |
|---|---|---|
| `create` | PutItem × 2 (parallel) | ✅ Dual-write correto |
| `validate` | GetItem | ✅ O-hop por hash — eficiente |
| `listByTenant` | Query `begins_with(SK, "TOKEN#")` | ✅ Correto |
| `revoke` | Query → UpdateItem × 2 (parallel) | ⚠️ Query necessária para recuperar tokenHash |

---

## Problemas Identificados no Design DynamoDB

### P1 — Loop N+1 em `findByProviderPaymentId` ❌ Crítico

**Arquivo**: `api/src/modules/invoices/services/invoice-repository.service.ts`

O método itera sobre `['ASAAS', 'ITAU']` e emite um `QueryByIndex` separado no `ProviderPaymentIndex` para cada provider até encontrar resultado. Com 2 providers = 2 queries seriais por webhook. Com 5 providers = 5 queries seriais. ITAU ainda não está implementado mas já é consultado a cada evento.

Este método é chamado no caminho crítico de processamento de webhook — toda mensagem SQS que entra aciona este padrão.

**Solução recomendada**: Se o provider ID é conhecido no momento da chamada (o webhook já sabe de qual provider veio), passar o provider como parâmetro e fazer um único GetItem no índice. Se não for conhecido, repensar o modelo de dado do índice.

---

### P2 — GSI2 (`PaymentStatusIndex`) é infraestrutura morta ⚠️ Alto

**Arquivo**: `api/infra/dynamodb.yaml`

O índice `PaymentStatusIndex` (`GSI2PK=STATUS#<status>`, `GSI2SK=ORDER#<orderId>`) é provisionado e paga 1 WCU em cada escrita de invoice — mas **nenhum repositório faz Query neste índice**. O índice está escrito, mas nunca lido.

**Solução**: Remover o índice se não há access pattern definido. Quando um caso de uso surgir (e.g., listar pagamentos por status para um tenant), adicionar de volta com o design correto.

---

### P3 — GSI1 da TransactionsTable é infraestrutura morta ⚠️ Alto

Idêntico ao P2, mas na `TransactionsTable`. Os atributos `GSI1PK`/`GSI1SK` nunca são escritos e o índice nunca é consultado.

---

### P4 — `updateInvoice` sem controle de concorrência ⚠️ Alto

**Arquivo**: `api/src/modules/invoices/services/invoice-repository.service.ts`

Transições de status usam `PutItem` completo sem `ConditionExpression`. Se dois eventos chegarem simultaneamente (e.g., webhook de confirmação + timeout de cancelamento), o segundo `PutItem` sobrescreve silenciosamente o estado do primeiro. Não há versioning otimista nem `attribute_not_exists`.

**Solução recomendada**: Adicionar atributo `version` (número) e usar `ConditionExpression: version = :expected_version` + incremento atômico. Alternativa mais simples: `ConditionExpression: updatedAt = :expected_updated_at`.

---

### P5 — Filtro in-memory de webhooks ativos ⚠️ Médio

**Arquivo**: `api/src/modules/webhooks/services/webhook-repository.service.ts`

`findByTokenId` e `findActiveByTenantId` fazem Query e filtram `active === true` em memória. Webhooks desativados (`active=false`) nunca são deletados, acumulam no DynamoDB indefinidamente, e são buscados e descartados a cada Query.

**Solução**: Adicionar `FilterExpression: active = :true` na Query DynamoDB, ou usar TTL para expirar webhooks desativados, ou deletar fisicamente ao desativar.

---

### P6 — `countByTokenId` busca todos os dados para contar ⚠️ Médio

**Arquivo**: `api/src/modules/webhooks/services/webhook-repository.service.ts`

`countByTokenId` chama `findByTokenId()` e retorna `.length`. Isso busca todos os atributos de todos os webhooks do token para retornar apenas um inteiro.

**Solução**: Usar `Select: 'COUNT'` na Query DynamoDB — retorna apenas o count sem transferir dados.

---

### P7 — ProvidersTable não tem repositório ⚠️ Médio

Tabela definida, provisionada e com variável de ambiente injetada no Lambda — mas sem nenhum repositório ou código de acesso. Custo de operação sem valor.

**Solução**: Remover a tabela do CloudFormation e a variável de ambiente do SAM template, ou implementar o repositório se a tabela for necessária no roadmap.

---

### P8 — Dois hops de leitura para idempotência e externalReference ℹ️ Baixo

`findByIdempotencyKey` e `findByExternalReference` fazem dois GetItems sequenciais. Sob volume alto de webhooks, isso dobra o custo de leitura nesses caminhos. Design aceitável no estágio atual, mas deve ser monitorado quando Datadog estiver ativo.

---

## Comparativo DynamoDB — Atual vs. Recomendado

| Dimensão | Atual | Recomendado | Prioridade | Esforço |
|---|---|---|---|---|
| **Billing mode** | PROVISIONED 1 RCU/WCU | PAY_PER_REQUEST (on-demand) até dados reais de carga | 🔴 Crítico | Baixo |
| **PITR** | Ausente | `PointInTimeRecoveryEnabled: true` em produção | 🔴 Crítico | Baixo |
| **GSI2 (PaymentStatusIndex)** | Definido, nunca consultado | Remover até ter access pattern definido | 🟠 Alto | Baixo |
| **GSI1 TransactionsTable** | Definido, nunca populado | Remover do CloudFormation | 🟠 Alto | Baixo |
| **updateInvoice concorrência** | PutItem sem condição | Adicionar `version` + `ConditionExpression` | 🟠 Alto | Médio |
| **findByProviderPaymentId** | Loop N+1 multi-provider | Passar provider como parâmetro — Query única | 🟠 Alto | Médio |
| **countByTokenId** | Fetch completo + `.length` | `Select: 'COUNT'` na Query | 🟡 Médio | Baixo |
| **Filtro active in-memory** | Query + filtro JS | `FilterExpression` DynamoDB ou TTL | 🟡 Médio | Baixo |
| **ProvidersTable** | Provisionada, sem repositório | Remover tabela e variável de ambiente | 🟡 Médio | Baixo |
| **Auto Scaling** | Ausente | Application Auto Scaling se mantiver PROVISIONED | 🟠 Alto | Médio |

---

# Business Findings

1. **Risco de indisponibilidade em produção**: DynamoDB com 1 WCU por tabela em `PROVISIONED` mode fará throttling com qualquer volume de pagamentos. Um único pico de 2 escritas/segundo é suficiente para causar erros.

2. **Blind spot de observabilidade**: Datadog desabilitado em produção significa que não há como detectar degradação de performance, erros silenciosos, ou comportamentos anômalos sem inspecionar CloudWatch manualmente.

3. **Deploy de produção sem automação**: O deploy de produção é manual e depende de injeção de secrets via CLI. Isso aumenta risco operacional e dificulta rollback rápido.

4. **Confiabilidade do webhook**: A ausência de alarme na DLQ significa que falhas de processamento de webhook podem acumular sem alertas, impactando reconciliação financeira.

---

# Architecture Impact

## Decisões confirmadas como corretas

- Separação de stacks (DynamoDB stateful / Lambda efêmero) — padrão AWS recomendado
- IAM least-privilege com roles dedicadas por função
- Partial batch failure (`ReportBatchItemFailures`) implementado corretamente ponta-a-ponta
- OIDC keyless auth para CI/CD — eliminação de long-lived credentials
- SQS VisibilityTimeout > 2× worker timeout — prevenção de double-processing

## Decisões que requerem revisão

- `AuthType: NONE` na Function URL — reconsiderar `AWS_IAM` com CloudFront na frente, ou manter com camada de aplicação documentando o modelo de ameaça explicitamente
- DynamoDB `PROVISIONED` com 1 RCU/WCU — migrar para `PAY_PER_REQUEST` até ter dados de carga real, ou configurar Application Auto Scaling
- Ausência de VPC — aceitável para modelo de ameaça atual (sem dados PCI in-house), mas deve ser documentado como decisão explícita

## Questões em aberto

- O modelo de segurança sem VPC satisfaz os requisitos de compliance do produto?
- Qual é a projeção de volume de transações em 30/60/90 dias para dimensionar DynamoDB?
- Existe budget aprovado para ativação do Datadog em produção?

---

# Reliability Impact

| Dimensão | Situação Atual | Risco |
|---|---|---|
| Disponibilidade | Lambda auto-scaling, mas DynamoDB com capacidade 1 | Alto — throttling derruba disponibilidade |
| Observabilidade | Datadog desabilitado em produção | Alto — sem visibility para incidentes |
| MTTR | Sem APM, sem distributed tracing | Alto — debugging lento em incidentes |
| Durabilidade de dados | Sem PITR no DynamoDB | Médio — sem recuperação point-in-time |
| Webhook reliability | SQS + DLQ correta, sem alarme DLQ | Médio — falhas silenciosas |
| Cold start | NestJS sem Provisioned Concurrency | Baixo/Médio — degradação de UX no primeiro acesso |

---

# Maturity Assessment

## Modelo de Maturidade Serverless (5 níveis)

| Nível | Descrição | Critérios |
|---|---|---|
| 1 | Funcional | Lambda executa, não há erros graves |
| 2 | Estruturado | IaC, IAM básico, múltiplos ambientes |
| 3 | Operacional | Observabilidade ativa, alertas, pipeline automatizado |
| 4 | Resiliente | Provisioned Concurrency, Auto Scaling, PITR, runbooks |
| 5 | Otimizado | Cost optimization, chaos engineering, SLO-driven ops |

## Score Atual por Dimensão

| Dimensão | Score | Justificativa |
|---|---|---|
| IaC e Estrutura | 4/5 | SAM correto, stacks separadas, parâmetros, condições |
| Segurança IAM | 4/5 | Roles por função, least-privilege, OIDC, NoEcho |
| Observabilidade | 1/5 | Infraestrutura Datadog excelente mas **desabilitada** em produção |
| Persistência | 1/5 | PROVISIONED 1 RCU/WCU sem Auto Scaling — risco crítico |
| Mensageria | 4/5 | DLQ, partial batch, VisibilityTimeout corretos — sem alarme DLQ |
| Performance | 2/5 | Module cache presente; sem Provisioned Concurrency, sem esbuild |
| CI/CD | 2/5 | Staging automatizado; produção manual |
| Segurança de Rede | 2/5 | Sem VPC; Function URL pública; sem WAF |
| **Média Geral** | **2.5/5** | **Fundação sólida, não operacional em produção** |

---

# Comparison Table — Atual vs. Recomendado

| Dimensão | Prática Atual | Prática Recomendada | Prioridade | Esforço |
|---|---|---|---|---|
| **Observabilidade** | Datadog `DatadogEnabled=false` em todos os ambientes | Ativar Datadog em staging e produção; configurar dashboard e alertas | 🔴 Crítico | Baixo |
| **DynamoDB Capacity** | `PROVISIONED` 1 RCU/WCU por tabela | `PAY_PER_REQUEST` ou `PROVISIONED` com Application Auto Scaling | 🔴 Crítico | Baixo |
| **DynamoDB Backup** | Sem PITR, sem backup | `PointInTimeRecoveryEnabled: true` em tabelas de produção | 🔴 Crítico | Baixo |
| **CI/CD Produção** | Deploy manual com `sam deploy` | Pipeline GitHub Actions com aprovação manual para produção | 🔴 Crítico | Médio |
| **DLQ Alarm** | DLQ sem alarme CloudWatch | `AWS::CloudWatch::Alarm` em `ApproximateNumberOfMessagesVisible` da DLQ | 🟠 Alto | Baixo |
| **Provisioned Concurrency** | Ausente — cold starts NestJS | `ProvisionedConcurrencyConfig` para ApiFunction (pelo menos 1) | 🟠 Alto | Baixo |
| **Function URL Auth** | `AuthType: NONE` | Documentar modelo de ameaça explicitamente ou adicionar `AWS_IAM` + CloudFront | 🟠 Alto | Médio |
| **Bundle Optimization** | TypeScript compilado sem bundler | `esbuild` via `sam build --beta-features` (tree-shaking, minificação) | 🟡 Médio | Médio |
| **VPC** | Lambda sem VPC | Avaliar VPC para DynamoDB e SQS via VPC Endpoints (custo vs. segurança) | 🟡 Médio | Alto |
| **SQS Encryption** | SSE-SQS padrão | Avaliar SSE-KMS para dados sensíveis de pagamento | 🟡 Médio | Baixo |
| **X-Ray / Tracing** | Ausente | Habilitar `Tracing: Active` no SAM (complementar ao Datadog) | 🟡 Médio | Baixo |
| **Secrets Manager** | Secrets como parâmetros SAM `NoEcho` | Migrar para AWS Secrets Manager com `secretsmanager:GetSecretValue` | 🟡 Médio | Médio |
| **Worker Datadog** | Worker usa `console.error` sem structured logger | Usar `pino` logger no worker igual à API | 🟢 Baixo | Baixo |
| **Chaos Engineering** | Ausente | Injeção de falhas com AWS FIS para validar resiliência SQS/DLQ | 🟢 Baixo | Alto |

---

# Experiment Plan

Os seguintes experimentos Upstream derivados são recomendados para fechar as lacunas identificadas, em ordem de prioridade:

## EXP-010 — Ativação do Datadog em Produção

**Pergunta:** Qual é a configuração mínima necessária para ativar o Datadog em staging e produção sem impacto de cold start?

**Hipótese:** O Datadog Extension Layer já está parametrizado no template SAM. Basta fornecer `DatadogEnabled=true`, `DatadogApiKey`, e `DatadogExtensionLayerArn` no `samconfig.toml` de staging para validar métricas, APM e log forwarding sem alteração de código.

**Escopo:** Modificar `samconfig.toml` staging, fazer deploy, validar no Datadog dashboard que métricas customizadas e traces chegam. Medir impacto no cold start.

**Critério de saída:** Traces visíveis no Datadog APM, pelo menos 3 métricas customizadas chegando ao dashboard, cold start delta < 200ms.

**Recomendação esperada:** Avançar para Downstream (mudança de configuração com low risk).

---

## EXP-011 — DynamoDB Capacity Mode Migration

**Pergunta:** Qual billing mode e configuração de capacidade é mais adequada para o volume atual e projetado de pagamentos?

**Hipótese:** Migrar para `PAY_PER_REQUEST` é mais seguro para a fase atual (volume imprevisível), e pode ser feito in-place via CloudFormation sem downtime. Tabelas no modo `PAY_PER_REQUEST` não throttleiam.

**Escopo:** Atualizar `dynamodb.yaml` para `BillingMode: PAY_PER_REQUEST` (remover `ProvisionedThroughput`), adicionar `PointInTimeRecoverySpecification: PointInTimeRecoveryEnabled: true`. Testar em staging com load test básico.

**Critério de saída:** Deploy em staging sem downtime, zero throttle errors em load test de 50 transações/minuto, PITR habilitado.

**Recomendação esperada:** Avançar para Downstream.

---

## EXP-012 — Pipeline CI/CD de Produção

**Pergunta:** Como estruturar o pipeline de produção com aprovação manual, injeção segura de secrets, e rollback automatizado?

**Hipótese:** GitHub Actions com environment `production` (required reviewers), secrets no GitHub Environment Secrets ou AWS Secrets Manager, e workflow `on: workflow_dispatch` com `confirm_changeset: true` satisfaz os requisitos de segurança sem overhead operacional.

**Escopo:** Criar `.github/workflows/deploy-production.yml`, configurar GitHub Environment `production` com reviewers obrigatórios, validar que o deploy de produção não é possível sem aprovação.

**Critério de saída:** Deploy de produção disparado via workflow, aprovação manual obrigatória funcionando, secrets nunca expostos em logs.

**Recomendação esperada:** Avançar para Downstream.

---

## EXP-013 — Provisioned Concurrency e Bundle Optimization

**Pergunta:** Qual é o cold start real do ApiFunction em produção e quais são as opções de mitigação com menor custo?

**Hipótese:** O cold start com NestJS + @codegenie/serverless-express é de 500–900ms. `esbuild` via SAM pode reduzir o tamanho do bundle em 40–60%, reduzindo cold start. Provisioned Concurrency de 1 instância elimina cold starts para o percentil P99.

**Escopo:** Medir cold start atual com CloudWatch Logs Insights. Configurar `sam build --beta-features` com `esbuild`. Comparar antes/depois. Avaliar custo de Provisioned Concurrency = 1 para ApiFunction.

**Critério de saída:** Delta de cold start documentado, tamanho de bundle antes/depois, custo mensal estimado de Provisioned Concurrency.

**Recomendação esperada:** Avançar para Downstream (esbuild + Provisioned Concurrency para produção).

---

# Artifacts Updated

- `prodops/journeys/discovery/experiments/009-serverless-maturity-assessment/experiment.md` (este arquivo)
- `prodops/journeys/discovery/experiments/009-serverless-maturity-assessment/upstream-trail.md`
- `prodops/journeys/discovery/experiments.md` (entrada 009 adicionada)

---

# Knowledge Gaps Closed

| Pergunta | Status | Evidência |
|---|---|---|
| Nível de maturidade Serverless atual | ✅ Respondida | Score 2.5/5 — análise estática completa do IaC e handlers |
| Lacunas críticas antes de escalar para produção | ✅ Respondida | Datadog desabilitado, DynamoDB 1 RCU/WCU, produção manual |
| Melhorias incrementais sem risco | ✅ Respondida | Tabela comparativa com prioridade e esforço |
| Risco de throttling DynamoDB | ✅ Respondida | PROVISIONED 1 WCU — throttling com ≥2 escritas/segundo |
| Por que Datadog está desabilitado | ✅ Respondida | Parâmetro `DatadogEnabled=false` em todos os entries do samconfig |
| Risco de VPC ausente | ⚠️ Parcialmente respondida | Sem VPC é aceitável para modelo atual; decisão de compliance pendente |

---

# New Backlog Items

| Item | Classificação |
|---|---|
| Ativar Datadog em staging (EXP-010) | Candidato ao Iteration Backlog |
| Migrar DynamoDB para PAY_PER_REQUEST + PITR (EXP-011) | Candidato ao Iteration Backlog |
| Pipeline CI/CD de produção (EXP-012) | Candidato ao Iteration Backlog |
| Provisioned Concurrency + esbuild (EXP-013) | Repository Tracking List |
| Alarme CloudWatch na DLQ de webhook | Candidato ao Iteration Backlog |
| Documentar modelo de ameaça Function URL AuthType: NONE | Repository Tracking List |
| Avaliar AWS Secrets Manager para tokens de produção | Repository Tracking List |
| Logger estruturado (pino) no webhook worker | Repository Tracking List |

---

# Recommendation

- [x] Executar outro experimento Upstream

**Justificativa:** O experimento respondeu todas as perguntas principais e produziu um plano de ação claro. A recomendação é executar sequencialmente os experimentos EXP-010 (Datadog), EXP-011 (DynamoDB), e EXP-012 (CI/CD Produção) — nessa ordem de prioridade — antes de considerar o produto pronto para tráfego de produção com escala.

Os itens EXP-010, EXP-011, e EXP-012 são candidatos a promoção direta para Downstream após validação em staging, dado que são mudanças de configuração de baixo risco.

EXP-013 requer uma sprint dedicada e pode aguardar dados de carga real de produção.

---

# Decision Package

## Executive Summary

O Payments API usa AWS SAM com uma fundação estrutural sólida — separação de stacks, IAM least-privilege por função, partial batch failures em SQS, e infraestrutura Datadog pronta. No entanto, a maturidade operacional é **2.5/5**: três lacunas críticas impedem operação segura em produção com carga real — Datadog desabilitado (blind spot total), DynamoDB com capacidade 1 RCU/WCU (throttling garantido), e ausência de pipeline automatizado de produção.

## Decisão Recomendada

Executar EXP-010, EXP-011, e EXP-012 em sequência (Upstream → Downstream imediato), antes de qualquer escalonamento de volume em produção.

## Riscos Atualizados

| Risco | Severidade | Mitigação |
|---|---|---|
| Throttling DynamoDB em produção | Crítico | EXP-011 — PAY_PER_REQUEST |
| Sem observabilidade em produção | Crítico | EXP-010 — Datadog ativado |
| Deploy de produção manual propenso a erros | Alto | EXP-012 — Pipeline automatizado |
| Cold start NestJS degradando UX | Médio | EXP-013 — Provisioned Concurrency |
| DLQ acumulando silenciosamente | Médio | Alarme CloudWatch DLQ |
| Perda de dados sem PITR | Médio | Coberto pelo EXP-011 |

## Oportunidades Atualizadas

- A infraestrutura Datadog existente (business spans, métricas OBC-tagged) é excelente — uma vez ativada, oferece observabilidade de negócio rica de imediato.
- A separação de stacks DynamoDB/Lambda é uma decisão arquitetural madura que facilita migrations sem downtime.
- O modelo de roles IAM por função é extensível para novos workers sem refatoração.

## Itens de Tracking Atualizados

EXP-010, EXP-011, EXP-012, EXP-013 adicionados como candidatos ao backlog. Alarme DLQ e Logger do worker adicionados à Repository Tracking List.

## OBCs Atualizados

Nenhum OBC existente é impactado diretamente. Os experimentos derivados produzirão OBCs próprios ao serem promovidos.

## Reliability Plan Atualizado

Os riscos de throttling DynamoDB e blind spot de observabilidade devem ser adicionados ao Reliability Plan como itens de alta severidade com mitigation actions vinculados aos experimentos derivados.

## Escopo Downstream Recomendado

Após conclusão de EXP-010 a EXP-012 e aprovação de Product Manager + Tech Lead:
- Ativar Datadog em produção (mudança de configuração)
- Migrar DynamoDB para PAY_PER_REQUEST + PITR (mudança de configuração IaC)
- Criar pipeline de produção (novo workflow GitHub Actions)

---

# Output Artifacts

## Artefatos gerados

| Tipo | Artefato | Situação |
|---|---|---|
| Análise | `009-serverless-maturity-assessment/experiment.md` | Draft — Upstream |
| Trail | `009-serverless-maturity-assessment/upstream-trail.md` | Draft — Upstream |
| Índice | `experiments.md` (entrada 009) | Atualizado |

**Promovido para Downstream:** `- [ ] Não` (análise e plano — experimentos derivados serão promovidos individualmente)
**Data de promoção:** —
**Slice:** —

---

# Exit Criteria

- [x] Hipótese original respondida — maturidade 2.5/5 com lacunas críticas identificadas
- [x] Perguntas classificadas — todas respondidas ou parcialmente respondidas
- [x] Lacunas de conhecimento documentadas — tabela Knowledge Gaps Closed
- [x] Impacto arquitetural documentado — decisões confirmadas e pendentes
- [x] Impacto em confiabilidade documentado — tabela Reliability Impact
- [x] Artefatos atualizados — experiments.md, upstream-trail.md
- [x] Recomendação produzida — executar EXP-010, EXP-011, EXP-012
- [x] Decision Package completo

---

# Next Step

Executar **EXP-010 — Ativação do Datadog em Produção** como próximo experimento Upstream, seguido de EXP-011 e EXP-012.

Apresentar o Decision Package deste experimento ao Product Manager e Tech Lead para aprovação do roadmap de melhorias.
