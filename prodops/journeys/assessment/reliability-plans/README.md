# Reliability Plan - Payments Release

> Documento gerado a partir de `prodops/journeys/assessment/reliability-plans/setup/reliability-plan.prompt.md`.
> Entrada principal: `prodops/artifacts/governance/plans/iteration-plan.md`.

## Executive Summary

Este Reliability Plan considera exclusivamente as funcionalidades do Iteration Plan cuja decisão é exatamente `Entrou`. Pela regra do prompt, ficam fora deste plano os itens marcados como `Entrou como MVP`, `Dividida`, `Adiada` ou `Saiu`.

O escopo aprovado para a Release, portanto, é composto por seis funcionalidades com decisão `Entrou`: habilitar o novo gateway para o Checkout na jornada priorizada, criar invoice via Pix, confirmar pagamento, criar invoice via Boleto, validação de acesso por token de API e configuração de webhook por token de API. A API já possui implementação relevante para criação de invoice, integração Asaas, idempotência, confirmação por webhook, deduplicação de evento e eventos observáveis. A suite de aceitação em memória foi executada anteriormente com 19 testes passando.

> **Atenção:** As três funcionalidades adicionadas em 2026-07-06 (Boleto, token de API, webhook por token) têm OBC e BDD Feature criados, mas ainda não possuem análise de risco completa neste Reliability Plan. As seções de Estado atual, Principais riscos, Análise por funcionalidade e Reliability Roadmap cobrem apenas as três funcionalidades originais. As novas funcionalidades devem ter suas entradas de risco adicionadas antes do Bootstrap.

Os maiores riscos de confiabilidade para esse escopo aprovado estão na diferença entre caminho local e caminho de produção, na Feature Flag do Checkout documentada como bloqueada por bug e em divergências de documentação que podem fazer Checkout, Asaas ou operação configurarem contratos incorretos. A correlação de webhook em Dynamo por `providerPaymentId` e `externalReference` foi implementada em 2026-06-30 e passa a ter cobertura de aceitação com `DYNAMO_MOCK`.

## Funcionalidades consideradas

| Funcionalidade | Decisão no Iteration Plan | Evidência |
| --- | --- | --- |
| Habilitar novo gateway para o Checkout na jornada priorizada | Entrou | `prodops/artifacts/governance/plans/iteration-plan.md`, linha da tabela "Iteration Plan recomendado". |
| Criar invoice via Pix | Entrou | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/bdd/create-invoice.feature`; `InvoiceController.createInvoice`; `InvoiceService.createInvoice`. |
| Confirmação de pagamento | Entrou | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/bdd/payment-confirmation.feature`; `AsaasWebhookController`; `InvoiceService.processProviderWebhook`. |
| Criar invoice via Boleto | Entrou (revisado 2026-07-06) | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/create-invoice-boleto.md`; `prodops/artifacts/business/bdd/create-invoice-boleto.feature`. **Análise de risco pendente neste Reliability Plan.** |
| Validação de acesso por token de API | Entrou | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/api-token-validation.md`; `prodops/artifacts/business/bdd/api-token-validation.feature`. **Análise de risco pendente neste Reliability Plan.** |
| Configuração de webhook por token de API | Entrou | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/webhook-configuration.md`; `prodops/artifacts/business/bdd/webhook-configuration.feature`. **Análise de risco pendente neste Reliability Plan.** |
| Criar invoice via Cartão de Crédito (Hosted) | Entrou (aprovado 2026-07-07) | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/credit-card-authorization-confirmation.md`; `prodops/artifacts/business/bdd/credit-card-payment.feature`. **Análise de risco pendente neste Reliability Plan.** |

Itens explicitamente ignorados por não terem decisão exatamente `Entrou`: `Notificação de status de pagamento` (`Entrou como MVP`), `Cancelar invoice pendente` (`Adiada`), `Integração corporativa de incidentes/ITSM` (`Saiu`) e `Gateway fallback/Itaú` (`Saiu`).

## Estado atual

| Funcionalidade | Implementação existente | Dependências | Estado de confiabilidade |
| --- | --- | --- | --- |
| Habilitar novo gateway para o Checkout na jornada priorizada | Não há implementação de Feature Flag neste repositório; Premortem informa que o Checkout está preparado, mas a flag segue desabilitada por bug. | Checkout, Feature Flag, contrato Checkout -> Payments, Payments API. | Dependência externa crítica e ainda não evidenciada como pronta. |
| Criar invoice via Pix | `POST /invoices` recebe `CreateInvoiceDto`, exige `Idempotency-Key`, resolve provider, cria cliente/cobrança Asaas e atualiza invoice para `OPEN`. | Asaas `/customers`, Asaas `/payments`, Payments DB, customer binding. | Implementado e coberto por testes em memória; caminho Dynamo e timeout de provider ainda fragilizam a confiabilidade. |
| Confirmação de pagamento | `POST /webhook/payments` valida token quando configurado, persiste evento bruto, deduplica e processa `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED` e `PAYMENT_OVERDUE`. | Webhook Asaas, `ASAAS_WEBHOOK_TOKEN`, Payments DB, evento canônico `payment.confirmed`. | Regras cobertas em memória e em Dynamo mock para correlação por `providerPaymentId` e `externalReference`; webhook não correlacionado emite evento observável. |

**Inconsistências relevantes para o escopo aprovado**

| Funcionalidade | Inconsistência | Evidência | Risco |
| --- | --- | --- | --- |
| Habilitar novo gateway para o Checkout na jornada priorizada | Consumidores podem usar contrato divergente. | Documentação legada removida em 2026-07-12; contrato canônico usa `POST /invoices`. | Checkout integrar endpoint incorreto. |
| Criar invoice via Pix | ODD antigo referencia `/payments` e Asaas `/v3/paymentLinks`; código usa `/invoices` e `/v3/payments`. | `api/odd/create_invoice.yaml`; `AsaasService.createCharge`. | Observabilidade/contrato medir dependência errada. |
| Confirmação de pagamento | Consumidores podem configurar uma rota antiga de webhook. | Documentação legada removida em 2026-07-12; `AsaasWebhookController` usa `/webhook/payments`. | Webhook Asaas configurado em URL incorreta. |

## Principais riscos

| Funcionalidade | Risco | Impacto | Probabilidade | Criticidade |
| --- | --- | --- | --- | --- |
| Habilitar novo gateway para o Checkout na jornada priorizada | Feature Flag segue bloqueada por bug documentado no Premortem. | Release não ativa ou ativa sem previsibilidade. | Alta | Crítica |
| Habilitar novo gateway para o Checkout na jornada priorizada | Contrato Checkout -> Payments pode divergir do endpoint real. | Checkout falha ao criar invoice após ativação da flag. | Média | Alta |
| Habilitar novo gateway para o Checkout na jornada priorizada | Falta evidência neste repo de critério de rollback para pedidos iniciados com gateway novo. | Pedidos ficam presos entre fluxo antigo e novo. | Média | Alta |
| Criar invoice via Pix | Testes atuais usam `INVOICE_REPOSITORY=memory`; persistência Dynamo pode divergir. | Invoice criada localmente pode falhar no ambiente de Release. | Alta | Crítica |
| Criar invoice via Pix | Timeout transiente marca invoice como `FAILED` com chave de idempotência já salva. | Retry seguro pode retornar estado falho sem recriar cobrança. | Média | Alta |
| Criar invoice via Pix | `AsaasService` não define timeout explícito no client axios. | Chamada externa pode consumir janela da Lambda e degradar checkout. | Média | Alta |
| Criar invoice via Pix | Documentação/ODD divergente sobre endpoint e provider operation. | Time mede ou integra rota/dependência errada. | Média | Alta |
| Confirmação de pagamento | Consultas Dynamo por `providerPaymentId` e `externalReference` precisam ser validadas contra tabela/índices reais do ambiente. | Pagamento confirmado pode não atualizar invoice se o índice real divergir do modelo testado. | Média | Alta |
| Confirmação de pagamento | Webhook não correlacionado retorna sucesso técnico e depende de consumo operacional do evento observável. | Evento pago pode ficar invisível se não houver monitoramento sobre o sinal emitido. | Média | Alta |
| Confirmação de pagamento | Evento canônico é emitido por `EventEmitter2` local; não há evidência de publicação durável no repo. | Confirmação pode não chegar a consumidores fora do processo. | Média | Alta |
| Confirmação de pagamento | `ASAAS_WEBHOOK_TOKEN` só é exigido quando configurado. | Ambiente mal configurado pode aceitar webhook sem validação. | Média | Alta |

## Análise por funcionalidade

### Habilitar novo gateway para o Checkout na jornada priorizada

**Riscos**

- Premortem informa que o Checkout está preparado, mas a ativação segue desabilitada por Feature Flag devido a bug localizado.
- A Feature Flag é dependência fora deste repositório; a API pode estar funcional e a Release ainda não estar pronta.
- Documentação divergente pode causar integração com endpoint errado.
- Falta evidência de política para pedidos criados durante ativação e depois rollback.

**Dependências**

- Checkout.
- Sistema de Feature Flag.
- Contrato real `POST /invoices`.
- Identificadores de correlação enviados pelo Checkout: `Idempotency-Key` e `X-Correlation-Id`.

**Pontos de atenção**

- A prontidão da Release depende da flag e do contrato do consumidor, não apenas da API.
- O Premortem classifica a ativação do gateway como risco central.
- Este plano não inclui Notification ou cancelamento porque não possuem decisão exatamente `Entrou`. Boleto, token de API e webhook por token estão listados nas Funcionalidades consideradas mas aguardam análise de risco completa neste documento.

**Recomendações**

- Definir readiness técnico da Feature Flag para esta jornada: estado inicial, critérios de ativação, critério de rollback e dono da decisão.
- Atualizar o contrato exposto ao Checkout para refletir o endpoint real e headers obrigatórios.
- Registrar evidência de ativação/desativação da flag em ambiente controlado antes da Release.

### Criar invoice via Pix

**Riscos**

- Implementação em memória está coberta, mas Dynamo ainda precisa ser validado para o mesmo fluxo.
- Retry de falha transiente pode ficar preso em invoice `FAILED` associada à mesma idempotency key.
- `AsaasService` usa axios sem timeout explícito.
- O contrato aceita outros `billingType`, mas a funcionalidade aprovada aqui é Pix; dados de Boleto não devem ser usados como evidência de prontidão de Pix.

**Dependências**

- Asaas `/customers`.
- Asaas `/payments`.
- Payments DB.
- Customer provider link.
- Checkout enviando payload Pix e idempotency key.

**Pontos de atenção**

- `InvoiceService.createInvoice` salva a invoice antes da chamada ao provider, o que ajuda auditoria.
- `assertProviderChargeContract` reduz risco de sucesso falso quando o provider responde sem dados essenciais.
- Eventos observáveis do fluxo Pix já possuem `correlationId`, `orderId`, `invoiceId`, provider e etapa.

**Recomendações**

- Validar o fluxo Pix com a mesma persistência prevista para a Release.
- Definir comportamento confiável para retry de falha transiente com idempotency key já persistida.
- Configurar timeout explícito e erro classificado para chamadas ao Asaas.
- Atualizar ODD/documentação de Pix para usar `/invoices` e `/v3/payments`.

### Confirmação de pagamento

**Riscos**

- `findByProviderPaymentId` e `findByExternalReference` funcionam em memória e possuem implementação/cobertura com Dynamo mock.
- `processProviderWebhook` pode responder sucesso técnico quando não encontrou invoice, mas agora emite evento observável específico de não correlação.
- `PAYMENT_RECEIVED` atualiza para `RECEIVED`; precisa preservar a regra de não republicar confirmação.
- `payment.confirmed` é emitido via EventEmitter local; não há durabilidade evidenciada para consumidores externos.
- Token de webhook depende de configuração de ambiente.

**Dependências**

- Asaas webhook.
- `ASAAS_WEBHOOK_TOKEN`.
- Payments DB.
- Índices de consulta por provider payment e referência externa.
- Evento canônico `payment.confirmed`.

**Pontos de atenção**

- Testes cobrem webhook autenticado, inválido, duplicado, `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED`, `PAYMENT_OVERDUE` e correlação por `externalReference`.
- A cobertura atual é forte para regra de domínio, mas insuficiente para o modo Dynamo.
- Confirmação é funcionalidade aprovada como `Entrou`; qualquer iniciativa aqui precisa parar na confiabilidade da confirmação, sem planejar notificação.

**Recomendações**

- Validar consultas Dynamo para encontrar invoice por `providerPaymentId` e `externalReference` contra tabela/índices reais do ambiente.
- Conectar o evento de webhook não correlacionado a dashboard/alerta operacional e definir reprocessamento.
- Definir mecanismo durável ou limite explícito do evento canônico `payment.confirmed`.
- Exigir token de webhook em ambientes de Release e falhar configuração insegura.

## Reliability Roadmap

| Funcionalidade | Iniciativa | Objetivo | Prioridade | Risco mitigado | Esforço | Dependências |
| --- | --- | --- | --- | --- | --- | --- |
| Habilitar novo gateway para o Checkout na jornada priorizada | Readiness técnico da Feature Flag | Confirmar que a flag permite ativação, rollback e rastreabilidade da jornada aprovada. | P0 | Flag bloqueada por bug ou rollback inconsistente. | Médio | Checkout, sistema de Feature Flag, Payments. |
| Habilitar novo gateway para o Checkout na jornada priorizada | Sincronizar contrato Checkout -> Payments | Garantir que Checkout use `POST /invoices`, `Idempotency-Key` e `X-Correlation-Id`. | P0 | Integração com endpoint/header incorreto. | Baixo | Checkout, docs técnicos, API Payments. |
| Habilitar novo gateway para o Checkout na jornada priorizada | Evidenciar política para pedidos durante rollback | Definir o que acontece com pedidos já iniciados no gateway novo quando a flag desligar. | P0 | Pedido preso entre fluxo antigo e novo. | Médio | Checkout, Payments, operação de release. |
| Criar invoice via Pix | Validar fluxo Pix no modo Dynamo | Garantir que criação, idempotência e leitura de invoice funcionem na persistência da Release. | P0 | Testes em memória mascararem falha de persistência. | Médio | DynamoService, PaymentsTable, ambiente local/homologação. |
| Criar invoice via Pix | Definir política de retry para falha transiente | Evitar que timeout de provider transforme retry seguro em retorno permanente de `FAILED`. | P0 | Cliente/Checkout sem recuperação após erro transiente. | Médio | InvoiceService, idempotência, regra de estados. |
| Criar invoice via Pix | Configurar timeout explícito para Asaas | Evitar que chamadas externas consumam a janela da Lambda e degradem Checkout. | P1 | Latência alta e falha em cascata. | Baixo | AsaasService, configuração de ambiente. |
| Criar invoice via Pix | Corrigir documentação/ODD do fluxo Pix | Alinhar endpoint real `/invoices` e provider operation `/v3/payments`. | P1 | Observabilidade ou integração medindo dependência errada. | Baixo | Docs, ODD, Payments. |
| Criar invoice via Pix | Dashboard mínimo de criação Pix | Expor sucesso, erro e latência das etapas de criação aprovadas. | P1 | Baixa visibilidade sobre falha de criação Pix. | Médio | Eventos `payments.observability`, DataDog/APM. |
| Confirmação de pagamento | Implementar consulta Dynamo por `providerPaymentId` | Permitir que webhook encontre invoice no ambiente persistente. | P0 | Pagamento confirmado sem atualização interna. | Médio | `ProviderPaymentIndex`, InvoiceRepository. |
| Confirmação de pagamento | Implementar consulta Dynamo por `externalReference` | Suportar webhook que chega antes da consolidação do provider payment id. | P0 | Evento antecipado não correlacionado. | Médio | Modelo Dynamo, índice por pedido/referência. |
| Confirmação de pagamento | Cobrir webhook com repositório Dynamo/local mock | Validar confirmação, deduplicação e correlação no caminho de persistência da Release. | P0 | Falsa segurança dos testes em memória. | Médio | DynamoService, LocalStack ou `DYNAMO_MOCK`. |
| Confirmação de pagamento | Evento observável para webhook não correlacionado | Dar sinal claro quando o provider envia pagamento sem invoice encontrada. | P0 | Evento pago invisível operacionalmente. | Baixo | InvoiceService, eventos observáveis. |
| Confirmação de pagamento | Validar configuração obrigatória do token de webhook | Impedir ambiente de Release aceitando webhook sem `ASAAS_WEBHOOK_TOKEN`. | P0 | Falha de segurança por configuração ausente. | Baixo | ConfigModule, ambiente de deploy. |
| Confirmação de pagamento | Definir durabilidade do evento `payment.confirmed` | Garantir que a confirmação aprovada não dependa apenas de listener local sem persistência. | P1 | Perda de evento canônico em restart/falha de processo. | Médio/alto | EventEmitter atual, broker futuro ou decisão arquitetural. |
| Confirmação de pagamento | Dashboard mínimo de confirmação | Expor webhooks recebidos, confirmados, duplicados, inválidos e não correlacionados. | P1 | MTTR alto em falha de confirmação. | Médio | Eventos de webhook, DataDog/APM. |

## Quick Wins

| Funcionalidade | Melhoria | Benefício | Esforço |
| --- | --- | --- | --- |
| Habilitar novo gateway para o Checkout na jornada priorizada | Criar checklist curto de readiness da Feature Flag. | Alinha critério de ativação e rollback entre Checkout e Payments. | Baixo |
| Habilitar novo gateway para o Checkout na jornada priorizada | Atualizar documentação do consumidor com `POST /invoices`. | Reduz risco de integração incorreta. | Baixo |
| Criar invoice via Pix | Registrar no release trail o resultado de `npm run test:acceptance`. | Cria evidência objetiva da base funcional atual. | Baixo |
| Criar invoice via Pix | Adicionar timeout configurável no axios do Asaas. | Reduz risco de chamada externa longa. | Baixo |
| Criar invoice via Pix | Remover referências do ODD a `/v3/paymentLinks`. | Evita dashboard/dependência errada para Pix. | Baixo |
| Confirmação de pagamento | Emitir evento observável quando webhook não encontra invoice. | Torna falha crítica visível rapidamente. | Baixo |
| Confirmação de pagamento | Falhar startup/deploy quando token de webhook estiver ausente em ambiente não local. | Evita configuração insegura. | Baixo |
| Confirmação de pagamento | Documentar chaves de correlação do webhook: `providerPaymentId` e `externalReference`. | Facilita diagnóstico e alinhamento com Asaas. | Baixo |

## Backlog futuro

Estas melhorias estão relacionadas a funcionalidades que não fazem parte do escopo de análise coberto pelas seções de risco deste documento.

- `Notificação de status de pagamento` (`Entrou como MVP`): planejar contrato Payments -> Notification, deduplicação ponta a ponta, status de entrega e alertas de confirmação sem comunicação ao cliente quando houver nova decisão `Entrou`.
- `Criar invoice via Boleto`, `Validação de acesso por token de API`, `Configuração de webhook por token de API` (`Entrou` — promovidos após geração deste documento): OBC e BDD Feature existem. Adicionar análise de risco completa para cada uma antes do Bootstrap respectivo.
- `Cancelar invoice pendente` (`Adiada`): retomar hardening de cancelamento, webhook `PAYMENT_DELETED`, reconciliação 404 e concorrência com confirmação quando entrar em Release.
- `Integração corporativa de incidentes/ITSM` (`Saiu`): planejar integração DataDog/APM com ITSM em iniciativa própria.
- `Gateway fallback/Itaú` (`Saiu`): planejar roteamento/fallback multi-provedor apenas quando houver decisão de negócio e contrato técnico aprovado.

## DORA como referência de confiabilidade

As métricas DORA estendidas complementam o Reliability Plan com uma visão de maturidade de delivery. Para cada funcionalidade com risco operacional relevante, declarar quais métricas DORA serão monitoradas após o deploy.

**Mapeamento SLIs dos OBCs → métricas DORA para esta Release:**

| OBC / Funcionalidade | SLI existente | Métrica DORA alimentada |
|---|---|---|
| Criar invoice via Pix | `invoice.created` com `providerPaymentId` — 99.9% | Availability |
| Criar invoice via Pix | `invoice.creation_failed` correlacionado com deploy | Change Fail Rate |
| Criar invoice via Pix | Latência de criação | Reaction Time |
| Confirmação de pagamento | `payment.confirmed` publicado 1x — 100% | Availability |
| Confirmação de pagamento | `webhook.received` → `payment.confirmed` gap | Reaction Time |
| Confirmação de pagamento | `webhook.delivery.failed` → `webhook.delivery.sent` gap | MTTR |
| Criar invoice via Boleto | `payment.boleto.created` — 99.9% | Availability |
| Cartão de Crédito | Card outcome em até 5min — 99% | Reaction Time |
| Cartão de Crédito | `payment.card.refund.requested` taxa | Rate of Return |
| Webhook Configuration | `webhook.delivery.sent` em até 5s — 95% | Reaction Time + Availability |
| API Token Validation | `api.token.validated` sem latência adicional >5ms — 99.9% | Availability + Reaction Time |

**Lacunas de cobertura DORA identificadas para esta Release:**

| Métrica DORA | Status | Gap |
|---|---|---|
| Lead Time for Change | ✗ Não coberta | Requer integração CI/CD com observabilidade |
| Release Frequency | ✗ Não coberta | Requer integração CI/CD |
| Change Fail Rate | ⚠ Parcial | Eventos mapeados; falta correlação temporal com deploys |
| MTTR | ⚠ Parcial | Pares de eventos mapeados; falta incident management |
| Reaction Time | ✅ Coberta | SLIs existentes nos OBCs já alimentam diretamente |
| Rate of Return | ✅ Coberta | Eventos de idempotência e estorno mapeados |
| Availability | ✅ Coberta | SLIs 99.9%/100% dos OBCs são métricas de Availability |

→ Ver mapeamento completo em [`../../discovery/experiments/008-dora-extended-documentation/evidence/obc-dora-mapping.md`](../../discovery/experiments/008-dora-extended-documentation/evidence/obc-dora-mapping.md)
→ Ver definições e pesos em [`../../../framework/dora-metrics.md`](../../../framework/dora-metrics.md)

---

## Premissas

- A palavra `Entrou` foi interpretada de forma estrita conforme o prompt. `Entrou como MVP` não foi considerado no escopo deste Reliability Plan.
- O escopo técnico desta Release ficou restrito a três funcionalidades: habilitar gateway no Checkout, criar invoice via Pix e confirmar pagamento.
- A persistência pretendida para Release é Dynamo, pois o repositório possui `INVOICE_REPOSITORY=dynamo` e infraestrutura `PaymentsTable`.
- Checkout e Feature Flag ficam fora deste repositório, mas são dependências diretas da funcionalidade aprovada de habilitação do gateway.
- A suite de aceitação atual usa repositório em memória e Asaas stub; ela valida regras de domínio, mas não prova confiabilidade em Dynamo.
- As iniciativas deste documento não alteram o Iteration Plan e não adicionam novas funcionalidades de negócio.

## Fontes consultadas

- `prodops/artifacts/governance/plans/iteration-plan.md`
- `prodops/journeys/assessment/reliability-plans/premortem.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
- `prodops/artifacts/business/bdd/create-invoice.feature`
- `prodops/artifacts/business/bdd/payment-confirmation.feature`
- `api/src/modules/invoices/controllers/invoice.controller.ts`
- `api/src/modules/invoices/controllers/asaas-webhook.controller.ts`
- `api/src/modules/invoices/services/invoice.service.ts`
- `api/src/modules/invoices/services/invoice-repository.service.ts`
- `api/src/infra/asaas.service.ts`
- `api/infra/dynamodb.yaml`
- `api/test/criar-invoice.e2e-spec.ts`
