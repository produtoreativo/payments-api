# OBC - Criar Invoice via Gateway

## Status

Downstream. Status `Entrou` em `prodops/artifacts/governance/plans/iteration-plan.md` (seção "Iteration Plan recomendado") — jornada Pix como primeiro billing type habilitado.

## Business Outcome

Magazine Siará consegue criar cobranças via gateway de Payments sem acoplamento direto ao provedor Asaas. O Checkout envia um contrato único de invoice; o gateway resolve o provedor, cria ou reutiliza o cliente Asaas, garante idempotência por chave de pedido e retorna identificadores rastreáveis. A invoice nasce com status `OPEN` apenas quando o `providerPaymentId` está consolidado — nunca antes. Erros de validação são auditáveis sem expor segredos ou payload sensível.

### Em linguagem executiva

Uma cobrança só é considerada criada quando o Asaas confirma que a recebeu e registrou no sistema dele. Enquanto essa confirmação não chega, o sistema não exibe a cobrança como ativa para o cliente — ela não existe a meio caminho. É o equivalente a um comprovante bancário: o depósito só está feito quando o banco emite o comprovante.

Isso protege o Magazine Siará de dois problemas: (1) mostrar ao cliente uma cobrança que o Asaas nunca chegou a registrar, e (2) cobrar duas vezes o mesmo pedido em caso de retentativa — o sistema reconhece a chave do pedido e devolve a cobrança já existente sem criar uma nova.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `invoice.created` | Invoice criada com sucesso no provedor — status `OPEN`, `providerPaymentId` presente. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `billingType`, `correlationId` |
| `invoice.creation_failed` | Falha ao criar invoice no provedor — invoice em `FAILED` ou `PROVIDER_PENDING`. | `invoiceId`, `orderId`, `tenantId`, `reason`, `provider`, `correlationId` |
| `invoice.idempotency_hit` | Retentativa com mesma chave de idempotência — invoice existente retornada sem nova cobrança. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `invoice.provider_rejected` | Provedor rejeitou a criação por dados inválidos — invoice marcada como `FAILED`. | `invoiceId`, `orderId`, `tenantId`, `providerErrorCode`, `correlationId` |
| `invoice.customer_created` | Cliente Asaas criado antes da invoice por ausência de vínculo. | `tenantId`, `customerId`, `providerCustomerId`, `correlationId` |
| `invoice.access_rejected` | Tentativa de criar invoice com provedor desabilitado para o tenant. | `tenantId`, `provider`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Invoices criadas com `providerPaymentId` presente na resposta ao Checkout. | 99.9% |
| Retentativas com mesma `Idempotency-Key` retornam invoice existente sem nova chamada ao provedor. | 100% |
| Invoice `OPEN` nunca retornada ao Checkout sem `providerPaymentId` consolidado. | 100% |
| Erros de validação do provedor retornados sem segredo ou payload sensível exposto. | 100% |
| Solicitações com provedor desabilitado para o tenant rejeitadas antes de chamar a API do provedor. | 100% |

## Reliability Rules

- O gateway não retorna status `OPEN` ao Checkout sem `providerPaymentId` confirmado. Falha transiente (timeout, 5xx) gera estado `PROVIDER_PENDING` — o retry com mesma chave de idempotência é seguro.
- Idempotência por `Idempotency-Key`: segunda chamada com a mesma chave retorna a invoice existente sem nova chamada ao provedor. Comportamento obrigatório para retentativas do Checkout.
- Antes de criar uma invoice no Asaas, verificar se já existe cliente Asaas reutilizável por documento ou `externalReference`. Criar apenas se não existir. Persistir o identificador Asaas para reuso.
- O provedor deve estar habilitado para o tenant antes de qualquer chamada à API. Rejeitar com erro de negócio e registrar auditoria da tentativa.
- Erros do provedor são retornados ao Checkout sem exposição de segredos internos ou payload bruto da API Asaas.
- `externalReference` deve conter o identificador do pedido (`orderId`) — rastreabilidade bidirecional entre Payments e ecommerce.
- Falha de validação do Asaas (dados inválidos) marca a invoice como `FAILED`. Informação de auditoria interna preservada; erro externo limpo.

## Response Contract

O gateway deve retornar ao Checkout:

```json
{
  "invoiceId": "...",
  "orderId": "...",
  "provider": "ASAAS",
  "providerPaymentId": "...",
  "status": "OPEN",
  "amount": 159.90,
  "currency": "BRL",
  "billingType": "PIX",
  "externalReference": "MS-100045"
}
```

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/create-invoice.feature`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-001
- OBCs relacionados: `prodops/artifacts/business/obcs/payment-confirmation.md`, `prodops/artifacts/business/obcs/cancel-invoice.md`
