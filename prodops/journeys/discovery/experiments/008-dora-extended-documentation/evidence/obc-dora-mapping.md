# Mapeamento: Observable Events dos OBCs → Métricas DORA

Este documento mapeia os 41 Observable Events dos 7 OBCs committed do payments-api para as 7 métricas DORA estendidas.

---

## Como ler este mapeamento

Cada evento pode **alimentar diretamente** uma métrica (o evento sozinho é o sinal) ou **contribuir indiretamente** (o evento é parte de um cálculo que requer correlação com outro evento ou com dados de pipeline).

Lacunas identificadas indicam onde a instrumentação atual é insuficiente e o que precisa ser adicionado para cobrir a métrica completamente.

---

## 1. Lead Time for Change

**O que mede:** tempo entre o commit de código e ele estar em execução em produção.

**Natureza:** métrica de pipeline — não mapeada diretamente para eventos de OBC.

**Sinal disponível nos OBCs:** nenhum evento de domínio sinaliza "código acabou de ser deployado". O primeiro evento de qualquer OBC após um deploy indica que a mudança chegou à produção, mas o timestamp do commit precisa vir do CI/CD.

**Gap:** ausência de evento de deployment nos OBCs. Lead Time requer integração com pipeline (ex: GitHub Actions → DataDog timestamp de deploy).

| OBC | Evento | Contribuição |
|---|---|---|
| Todos | Primeiro evento após deploy | ⚠ Indireto — marca o "chegou a produção", mas não o commit inicial |

---

## 2. Release Frequency

**O que mede:** frequência de deploys bem-sucedidos para produção.

**Natureza:** métrica de pipeline — não mapeada para eventos de OBC.

**Gap:** nenhum evento de OBC registra deploy. Requer CI/CD instrumentation.

| OBC | Evento | Contribuição |
|---|---|---|
| — | — | ✗ Não mapeável via eventos de OBC |

---

## 3. Change Fail Rate

**O que mede:** percentual de mudanças que causam falha ou degradação observável em produção.

**Natureza:** híbrida — parte pipeline (correlação deploy × incidente), parte OBC (taxa de falha pós-deploy).

**Sinal disponível nos OBCs:** eventos de falha de capability que podem ser correlacionados com deploys recentes.

| OBC | Evento | Contribuição |
|---|---|---|
| create-invoice | `invoice.creation_failed` | ✅ Direto — falha na capability; pico após deploy = change failure |
| create-invoice | `invoice.provider_rejected` | ✅ Direto — rejeição por dados inválidos; novo após deploy = regressão |
| create-invoice | `invoice.access_rejected` | ✅ Direto — tenant sem acesso ao provedor; comportamento novo após deploy |
| create-invoice-boleto | `payment.boleto.creation_failed` | ✅ Direto — falha de criação de boleto |
| cancel-invoice | `invoice.cancel_provider_not_found` | ✅ Direto — 404 do provider; pode indicar mudança que quebrou correlação |
| payment-confirmation | `webhook.rejected` | ✅ Direto — webhook rejeitado; taxa alta após deploy indica regressão de auth |
| credit-card | `payment.card.refused` | ⚠ Indireto — recusa pode ser negócio ou regressão; correlacionar com deploy |
| webhook-configuration | `webhook.delivery.failed` | ✅ Direto — falha de entrega; pico após deploy = change failure |
| api-token-validation | `api.token.rejected` | ⚠ Indireto — pode ser tentativa inválida ou regressão; monitorar taxa |

**Nota:** Change Fail Rate em nível de deploy requer correlação do timestamp do deploy com aumento de taxa desses eventos. Monitorar nos 30 minutos após cada deploy.

---

## 4. Mean Time to Recovery (MTTR)

**O que mede:** tempo médio desde a detecção da falha até a recovery completa.

**Natureza:** operacional — requer tooling de incident management (PagerDuty, DataDog incidents) correlacionado com eventos de recovery.

**Sinal disponível nos OBCs:** pares de eventos falha → sucesso que delimitam a janela de recovery por tentativa.

| OBC | Par de eventos | Contribuição |
|---|---|---|
| create-invoice | `invoice.creation_failed` → `invoice.created` (retry) | ✅ Direto — gap de tempo = recovery de criação individual |
| cancel-invoice | `invoice.cancel_provider_not_found` → `payment.cancelled` | ✅ Direto — gap = tempo até conciliação/recovery |
| webhook-configuration | `webhook.delivery.failed` → `webhook.delivery.sent` | ✅ Direto — gap = tempo de recovery de entrega |
| payment-confirmation | `webhook.received` sem `payment.confirmed` → posterior `payment.confirmed` | ⚠ Indireto — requer correlação por `correlationId` |

**Gap:** ausência de evento "incidente declarado" e "incidente resolvido" nos OBCs. MTTR de incidentes de nível de serviço requer integração com incident management.

---

## 5. Reaction Time

**O que mede:** tempo entre a chegada de um sinal externo e a primeira ação processada pelo sistema.

**Natureza:** diretamente mapeável via timestamps de eventos de OBC.

| OBC | Par de eventos | O que mede |
|---|---|---|
| payment-confirmation | `webhook.received` → `payment.confirmed` | Tempo entre chegada do webhook e confirmação processada |
| payment-confirmation | `webhook.received` → `webhook.rejected` | Rejeição imediata — reaction time de segurança |
| payment-confirmation | `webhook.received` → `webhook.deduplicated` | Deduplicação imediata — reaction time de idempotência |
| payment-confirmation | `webhook.received` → `webhook.correlated_by_reference` | Tempo de correlação por referência |
| api-token-validation | `api.token.validated` | Latência de validação — reaction time de autenticação |
| webhook-configuration | `webhook.delivery.sent` | Latência de entrega após evento — reaction time de notificação |
| credit-card | `payment.card.authorization.requested` → `payment.card.authorized` | Tempo de autorização do cartão |
| credit-card | `payment.card.authorization.requested` → `payment.card.refused` | Tempo de recusa — reaction time mesmo em falha |

**SLI existente que alimenta diretamente Reaction Time:**
- `webhook.delivery.sent` em até 5s após evento — 95% (webhook-configuration OBC)
- Card attempts com outcome terminal em até 5 min — 99% (credit-card OBC)
- Card confirmations em até 30s — 99% (credit-card OBC)

---

## 6. Rate of Return

**O que mede:** taxa de defeitos escapados para produção e rework gerado.

**Natureza:** diretamente mapeável — retentativas e pedidos de estorno são sinais de rework.

| OBC | Evento | O que mede |
|---|---|---|
| create-invoice | `invoice.idempotency_hit` | Cliente retentou — pode indicar resposta anterior ambígua ou falha |
| create-invoice-boleto | `payment.boleto.idempotency_hit` | Cliente retentou criação de boleto |
| cancel-invoice | `invoice.cancel_idempotency_hit` | Cliente retentou cancelamento |
| credit-card | `payment.card.refund.requested` | Estorno solicitado após confirmação — defeito escapado pós-entrega |
| credit-card | `payment.card.refund.required` | Necessidade de estorno por impossibilidade de cancelamento — rework operacional |

**Nota:** `idempotency_hit` sozinho não confirma rework (pode ser retry legítimo de rede). Correlacionar com ausência de resposta anterior bem-sucedida para diferenciar retry de rede de retry por falha.

---

## 7. Availability

**O que mede:** percentual de tempo em que o serviço está disponível e respondendo corretamente.

**Natureza:** diretamente mapeável via razão sucesso/falha por janela de tempo.

| OBC | Numerador | Denominador | SLI |
|---|---|---|---|
| create-invoice | `invoice.created` | `invoice.created` + `invoice.creation_failed` + `invoice.provider_rejected` | 99.9% target |
| create-invoice-boleto | `payment.boleto.created` | `payment.boleto.created` + `payment.boleto.creation_failed` | 99.9% target |
| payment-confirmation | `payment.confirmed` (publicado 1x) | Webhooks `PAYMENT_CONFIRMED` recebidos | 100% target |
| webhook-configuration | `webhook.delivery.sent` | `webhook.delivery.sent` + `webhook.delivery.failed` | 95% em 5s |
| api-token-validation | `api.token.validated` | `api.token.validated` + `api.token.rejected` (token inválido genuíno excluído) | 99.9% target |
| cancel-invoice | `payment.cancelled` | `payment.cancelled` + estados não resolvidos | 99.9% target |
| credit-card | `payment.confirmed` | Tentativas iniciadas com `payment.card.authorization.requested` | 99% em 5min |

**Nota:** `api.token.rejected` por token ausente ou inválido não é falha de Availability — é comportamento correto. Disponibilidade de autenticação = % de tokens válidos autorizados sem latência excessiva.

---

## Resumo: cobertura por métrica

| Métrica DORA | Cobertura via OBC Events | Gap |
|---|---|---|
| Lead Time for Change | ⚠ Parcial — primeiro evento pós-deploy | Requer integração com CI/CD para timestamp de commit |
| Release Frequency | ✗ Não coberta | Requer CI/CD instrumentation |
| Change Fail Rate | ✅ Coberta — 9 eventos de falha mapeados | Requer correlação temporal com deploys |
| MTTR | ✅ Coberta — 4 pares falha→recovery mapeados | Requer incident management para MTTR de serviço |
| Reaction Time | ✅ Coberta — 8 pares de eventos mapeados | Já existem SLIs alinhados |
| Rate of Return | ✅ Coberta — 5 eventos de rework mapeados | Distinguir retry legítimo de retry por falha |
| Availability | ✅ Coberta — 7 razões sucesso/falha mapeadas | Já existem SLIs alinhados |

---

## Lacunas de instrumentação identificadas

Para cobertura completa das 7 métricas DORA, os seguintes eventos estão ausentes nos OBCs:

| Lacuna | Métricas afetadas | Ação recomendada |
|---|---|---|
| Evento de deployment (deploy iniciado / deploy concluído) | Lead Time for Change, Release Frequency, Change Fail Rate | Integrar pipeline CI/CD com DataDog ou equivalente |
| Evento de incidente (declarado / resolvido) | MTTR | Integrar PagerDuty ou incident management |
| Evento de rollback | Change Fail Rate, MTTR | Adicionar ao pipeline e ao OBC de gateway configuration |
