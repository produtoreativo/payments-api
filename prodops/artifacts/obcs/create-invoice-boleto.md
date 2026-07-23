# OBC - Criar Invoice via Boleto

## Status

Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` (section "Iteration Plan recomendado").

## Business Outcome

Magazine Siará pode emitir cobranças via Boleto Bancário para pedidos onde o cliente opta por pagamento offline com prazo definido de vencimento. O Checkout passa a oferecer Boleto como meio de pagamento via o gateway Payments, sem acoplamento direto ao provedor. O cliente recebe o link do PDF do boleto e a linha digitável para pagamento bancário. O gateway garante idempotência e não emite cobranças duplicadas em retentativas do Checkout.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `payment.boleto.created` | Invoice Boleto criada com sucesso no provedor — bankSlipUrl disponível. | `invoiceId`, `orderId`, `tenantId`, `providerPaymentId`, `billingType`, `dueDate`, `correlationId` |
| `payment.boleto.creation_failed` | Falha ao criar boleto no provedor — invoice permanece em PROVIDER_PENDING ou FAILED. | `invoiceId`, `orderId`, `tenantId`, `reason`, `correlationId` |
| `payment.boleto.idempotency_hit` | Retentativa com mesma chave de idempotência — invoice existente retornada sem nova cobrança. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Invoices Boleto criadas com `bankSlipUrl` presente na resposta. | 99.9% |
| `dueDate` no passado rejeitada antes de chamar o provedor. | 100% |
| Retentativas com mesma `Idempotency-Key` retornam invoice existente sem nova cobrança. | 100% |
| `bankSlipUrl` e `identificationField` não aparecem em logs, traces ou respostas de erro. | 100% |
| Invoice com status `OPEN` retornada ao Checkout após criação bem-sucedida. | 100% |

## Reliability Rules

- `dueDate` é obrigatória e deve ser uma data futura (mínimo D+1 em relação ao momento da requisição). Requisições com `dueDate` no passado ou ausente são rejeitadas com `400` antes de chamar o provedor.
- A resposta ao Checkout deve incluir `bankSlipUrl` (link PDF do boleto) e `identificationField` (linha digitável). Se o provedor não retornar `bankSlipUrl`, a invoice é marcada como `FAILED` e o erro é observável.
- `bankSlipUrl` e `identificationField` não devem ser logados — contêm dados de cobrança rastreáveis. Logar apenas `invoiceId` e `providerPaymentId`.
- O status da invoice permanece `OPEN` após criação bem-sucedida. Confirmação de pagamento é assíncrona (webhook do provedor) e pode ocorrer dias após a emissão.
- Boleto expirado (vencimento passado sem pagamento) não deve ser tratado como erro operacional — é estado natural do ciclo. O evento `payment.boleto.expired` deve ser observável quando o webhook do provedor comunicar a expiração.
- Idempotência: a mesma `Idempotency-Key` deve retornar a invoice existente sem nova chamada ao provedor. Comportamento idêntico ao Pix.
- Falha transiente do provedor (timeout, 5xx) não altera o comportamento de idempotência — o retry com a mesma chave pode ser reenviado pelo Checkout com segurança.
- `billingType=BOLETO` no payload de criação é obrigatório. O gateway não deve inferir o tipo de cobrança.

## Response Contract

O gateway deve retornar ao Checkout:

```json
{
  "invoiceId": "...",
  "orderId": "...",
  "provider": "ASAAS",
  "providerPaymentId": "...",
  "status": "OPEN",
  "amount": 250.00,
  "currency": "BRL",
  "billingType": "BOLETO",
  "dueDate": "2026-07-10",
  "bankSlipUrl": "https://sandbox.asaas.com/b/pdf/...",
  "identificationField": "34191.75402...",
  "externalReference": "MS-200010"
}
```

`bankSlipUrl` e `identificationField` são campos adicionais ao contrato genérico de invoice — precisam ser adicionados a `InvoiceResponseDto` e `InvoiceRecord`.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/create-invoice-boleto.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- OBC relacionado: `prodops/artifacts/obcs/api-token-validation.md`
- Risks: `prodops/artifacts/risks/risks.md` — seção Riscos Boleto
