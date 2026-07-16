# Runbooks

Procedimentos operacionais para suporte à release de Payments API.

Os cenários cobertos aqui foram identificados no pré-mortem da release:
[`prodops/journeys/assessment/reliability-plans/premortem.md`](../assessment/reliability-plans/premortem.md)

Para cada runbook: diagnóstico → contenção imediata → resolução → verificação.

---

## RB-001 — Rollback da Feature Flag do novo gateway

**Cenário de origem:** PMT-PRE-005 — Feature Flag não permite rollback limpo.

**Quando usar:** após desativar a Feature Flag do novo gateway no Checkout, pedidos já iniciados no Payments continuam chegando eventos ou ficam órfãos.

### Sinais de alerta

- Pedidos com `invoiceId` criados no Payments continuam recebendo webhooks depois da flag desligada.
- Checkout cria novos pedidos no fluxo antigo, mas continua enviando eventos ao Payments.
- `payment.confirmed` emitido sem invoice correspondente no Payments.

### Diagnóstico

```bash
# Verificar eventos chegando ao Payments sem invoice correspondente
# CloudWatch Logs — filtrar por:
#   message: "invoice not found" OR "uncorrelated webhook"
#   correlationId: presente nos logs de webhook

# Verificar volume de webhooks no SQS DLQ
aws sqs get-queue-attributes \
  --queue-url "$STAGING_WEBHOOK_DLQ_URL" \
  --attribute-names ApproximateNumberOfMessages
```

### Contenção imediata

1. Não desativar a flag de forma abrupta se há pedidos com status `OPEN` ou `CANCEL_REQUESTED` — essas invoices precisam ser reconciliadas.
2. Registrar o horário exato de desativação da flag para delimitar o escopo de pedidos afetados.
3. Manter o Payments processando webhooks mesmo com a flag desligada para o Checkout — os eventos de confirmação de pedidos já iniciados devem ser concluídos.

### Política de reconciliação

| Estado da invoice | Ação após rollback |
|---|---|
| `OPEN` | Aguardar webhook de confirmação ou cancelamento do provedor. Não cancelar manualmente sem confirmação. |
| `CANCEL_REQUESTED` | Aguardar webhook `PAYMENT_DELETED`. Se não chegar em 24h, verificar no painel da Asaas. |
| `CONFIRMED` | Nenhuma ação necessária. Evento já foi emitido. |
| `CANCELLED` | Nenhuma ação necessária. |

### Verificação pós-resolução

- [ ] Nenhuma invoice em status `OPEN` criada após rollback sem resolução.
- [ ] Volume de mensagens no DLQ retornou ao baseline.
- [ ] Logs sem `uncorrelated webhook` acima do baseline.

**Registrar:** data/hora, escopo de pedidos afetados, decisão tomada → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-002 — Falha na criação de invoice / timeout do provedor

**Cenário de origem:** PMT-PRE-001 — Checkout habilita o novo gateway e parte dos pedidos não cria invoice. PMT-PRE-007 — Criação de invoice gera cobrança duplicada.

**Quando usar:** `POST /invoices` retorna 4xx/5xx em volume anormal, ou o mesmo `orderId` aparece com mais de uma invoice no provedor.

### Sinais de alerta

- Taxa de erro em `POST /invoices` acima do baseline (>1% em janela de 5 min).
- Mesmo `orderId` com mais de uma invoice com status `OPEN` no DynamoDB.
- Logs com `provider returned error` ou timeout do AsaasService.

### Diagnóstico

```bash
# CloudWatch Logs — filtrar erros de criação
# message: "provider returned error" OR level: "error" AND service: "invoices"
# Verificar: é erro 4xx (contrato) ou 5xx (instabilidade do provedor)?
```

### Contenção — provider 4xx (erro de contrato)

1. Identificar o payload rejeitado (verificar `message` no body da resposta).
2. Se for erro de validação do Payments, criar fix com novo ciclo Hack.
3. Não retentar automaticamente — retentativas de 4xx criam duplicidade.

### Contenção — provider 5xx (instabilidade do provedor)

1. Verificar status público da Asaas.
2. Retentativas com `Idempotency-Key` são seguras — o Payments rejeita duplicidade por `orderId + tenantId`.
3. Se a instabilidade persistir >15 min, comunicar ao Checkout para pausar novas criações.

### Contenção — invoice duplicada

1. Identificar as duas invoices pelo `orderId`.
2. Cancelar a invoice duplicada via `DELETE /invoices/{invoiceId}` com `Idempotency-Key` único.
3. Confirmar que apenas uma invoice permanece com status `OPEN` para o `orderId`.

### Verificação pós-resolução

- [ ] Taxa de erro em `POST /invoices` retornou ao baseline.
- [ ] Nenhum `orderId` com duas invoices `OPEN` no DynamoDB.
- [ ] Idempotência verificada: mesmo `orderId` + mesma `Idempotency-Key` retorna 201 com a invoice original.

**Registrar:** → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-003 — Pagamento confirmado sem notificação ao cliente

**Cenário de origem:** PMT-PRE-002 — Cliente paga, mas não recebe confirmação.

**Quando usar:** `payment.confirmed` foi emitido pelo Payments mas o cliente não recebeu comunicação, ou o Notification Service reportou falha.

### Sinais de alerta

- Invoice com status `CONFIRMED` no DynamoDB mas sem entrada de notificação nos logs do Notification Service.
- Aumento de chamados: "paguei mas não recebi confirmação".
- Evento `payment.confirmed` nos logs do Payments sem evento correspondente no Notification Service.

### Diagnóstico

```bash
# 1. Verificar se o evento foi emitido pelo Payments
# CloudWatch Logs — Payments
# Buscar por: invoiceId + "payment.confirmed" (log estruturado)
# Confirmar: tenantId, orderId, invoiceId, correlationId presentes

# 2. Verificar se o evento chegou ao Notification Service
# Buscar pelo mesmo correlationId ou invoiceId nos logs do Notification Service
# Se ausente: problema de entrega de evento
# Se presente mas sem envio: falha no processamento do Notification Service

# 3. Verificar DLQ
aws sqs get-queue-attributes \
  --queue-url "$STAGING_WEBHOOK_DLQ_URL" \
  --attribute-names ApproximateNumberOfMessages
```

### Contenção

| Causa | Ação |
|---|---|
| Evento não chegou ao Notification Service | Verificar fila SQS/EventBridge; reprocessar da DLQ após resolver a causa raiz |
| Evento chegou mas não foi processado | Acionar time do Notification Service com `correlationId` e `invoiceId` |
| Notificação duplicada | Verificar idempotência por `invoiceId` no Notification Service |

### Ação manual de último recurso

Se não houver resolução imediata, o atendimento pode confirmar o status do pagamento consultando `GET /invoices/{invoiceId}` com o token do tenant afetado.

### Verificação pós-resolução

- [ ] `payment.confirmed` com o `invoiceId` afetado aparece nos logs do Notification Service.
- [ ] Cliente recebeu comunicação (confirmado pelo log de envio ou pelo atendimento).
- [ ] Volume de eventos na DLQ retornou ao baseline.

**Registrar:** → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-004 — Webhook do provedor não processado

**Quando usar:** evento do Asaas (`PAYMENT_CONFIRMED`, `PAYMENT_DELETED`) chegou ao endpoint `/webhook/payments` mas a invoice não foi atualizada.

### Sinais de alerta

- Invoice permanece em `OPEN` ou `CANCEL_REQUESTED` por mais de 10 min após evento esperado.
- Logs com `webhook received` mas sem `invoice updated`.
- Mensagens acumulando na DLQ do webhook.

### Diagnóstico

```bash
# 1. Verificar se o webhook chegou
# CloudWatch Logs — filtrar por path "/webhook/payments" AND method "POST"
# Buscar pelo providerPaymentId do pedido afetado

# 2. Verificar assinatura (401 nos logs = token incorreto)
# Comparar ASAAS_WEBHOOK_TOKEN configurado na Lambda com o valor no painel da Asaas

# 3. Verificar DLQ
aws sqs receive-message \
  --queue-url "$STAGING_WEBHOOK_DLQ_URL" \
  --max-number-of-messages 10
```

### Contenção

| Causa | Ação |
|---|---|
| Token de webhook incorreto | Corrigir `ASAAS_WEBHOOK_TOKEN` na Lambda e re-registrar o webhook na Asaas |
| Invoice não encontrada por `providerPaymentId` | Verificar se `providerPaymentId` foi salvo corretamente na criação da invoice |
| Evento na DLQ | Reprocessar manualmente após resolver a causa raiz |
| Asaas não está retentando | Re-registrar manualmente a transição de status via `PUT /invoices/{invoiceId}` (uso interno) |

### Verificação pós-resolução

- [ ] Invoice com status correto no DynamoDB.
- [ ] Evento registrado na tabela `RawProviderEvents` com `eventKey` correspondente.
- [ ] DLQ com volume de baseline.

**Registrar:** → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-005 — Guia de diagnóstico por identificadores

**Cenário de origem:** PMT-PRE-006 — Times não conseguem diagnosticar falhas rapidamente.

Use este guia para localizar qualquer evento na cadeia Checkout → Payments → Asaas → Notification Service.

### Identificadores disponíveis

| Identificador | Origem | Onde buscar |
|---|---|---|
| `orderId` | Checkout | InvoicesTable (índice OrderIdIndex), logs do Payments |
| `invoiceId` | Payments (prefixo `inv_`) | InvoicesTable (chave primária), todos os logs do Payments |
| `providerPaymentId` | Asaas (prefixo `pay_`) | InvoicesTable, logs do Payments, painel da Asaas |
| `correlationId` | Header `X-Correlation-Id` | Todos os logs da requisição e dos eventos emitidos |
| `tenantId` | Header / payload | InvoicesTable, todos os logs do Payments |
| `tokenId` | ApiTokensTable | Logs de autenticação (nunca o token bruto) |

### Sequência de busca recomendada

```
1. Partir do identificador disponível (orderId, invoiceId ou providerPaymentId)
2. Localizar a invoice no DynamoDB
3. Obter correlationId e providerPaymentId da invoice
4. Buscar no CloudWatch Logs por correlationId para rastrear toda a cadeia
5. Verificar no painel da Asaas pelo providerPaymentId se necessário
```

### Campos obrigatórios em todos os logs

Todo log do Payments deve ter: `correlationId`, `tenantId`, `invoiceId` (quando aplicável), `level`, `msg`.

Se um log não tiver esses campos, o problema está na instrumentação — abrir item na Repository Tracking List de observabilidade (`TL-003`).
