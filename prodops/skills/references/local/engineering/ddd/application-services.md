# Application Services

## O que é um application service

Orquestra domain objects, repositories e external services para completar um use case.
Não contém regras de negócio — chama domain objects que as contêm.

## InvoiceService como exemplo

`InvoiceService` é o application service principal. Seus use cases:

- `createInvoice()` — cria fatura, registra no provedor, emite eventos
- `getInvoice()` — consulta fatura por tenant + invoiceId
- `cancelInvoice()` — cancela fatura no provedor, atualiza status
- `processProviderWebhook()` — processa webhook do Asaas e aplica transição de status

## Regras

1. **Não contém lógica de domínio** — lógica de transição de status fica no aggregate
2. **Não retorna domain objects** — retorna `InvoiceResponseDto` ou tipos simples
3. **Tem dependências de infraestrutura** — injeta `InvoiceRepository`, `AsaasService`, `EventEmitter2`
4. **Coordena a sequência** — buscar → validar → persistir → chamar provedor → emitir evento

## createInvoice() — passo a passo

```typescript
async createInvoice(
  dto: CreateInvoiceDto,
  idempotencyKey: string,
  correlationId?: string,
): Promise<InvoiceResponseDto> {
  // 1. Validar input (campos obrigatórios, currency BRL, billingType válido)
  this.validateCreateInvoice(dto, idempotencyKey);

  // 2. Verificar idempotência — retornar fatura existente se chave já foi usada
  const existing = await this.repository.findByIdempotencyKey(dto.tenantId, idempotencyKey);
  if (existing) return this.toResponse(existing);

  // 3. Resolver provider (ASAAS ou ITAU)
  const provider = this.providerRouter.resolve(dto.provider);

  // 4. Criar InvoiceRecord com status CREATED e salvar (+ idempotency key)
  const invoiceId = `inv_${ulid()}`;
  const invoice: InvoiceRecord = { invoiceId, ...dto, status: 'CREATED', externalReference: invoiceId };
  await this.repository.saveInvoice(invoice, idempotencyKey);
  this.eventEmitter.emit('payments.invoice.created', { invoiceId, orderId: dto.orderId, ... });

  // 5. Atualizar para PROVIDER_PENDING antes de chamar o provedor
  const pendingInvoice = await this.repository.updateInvoice(invoice, 'PROVIDER_PENDING');

  // 6. Garantir customer no Asaas (CustomerProviderLink)
  const customerLink = await this.ensureProviderCustomer(pendingInvoice, provider, correlationId);

  // 7. Criar cobrança no Asaas (AsaasService = anti-corruption layer)
  const charge = await this.asaas.createCharge({ customer: customerLink.providerCustomerId, ... });

  // 8. Atualizar para OPEN com providerPaymentId e paymentUrl
  const openInvoice = await this.repository.updateInvoice(pendingInvoice, 'OPEN', {
    providerPaymentId: charge.id,
    paymentUrl: charge.invoiceUrl ?? charge.bankSlipUrl,
  });
  this.eventEmitter.emit('payments.invoice.opened', { invoiceId: openInvoice.invoiceId, ... });

  // 9. Retornar DTO — nunca o domain object diretamente
  return this.toResponse(openInvoice);
}
```

## O que o application service não faz

- Não contém `if (status === 'OPEN')` inline — isso fica no aggregate
- Não chama DynamoDB diretamente — sempre via `InvoiceRepository`
- Não conhece HTTP (`Request`, `Response`, objetos Express/Fastify)
- Não importa módulos de Checkout ou Order Management

## Diferença de domain service

| Application service | Domain service |
|--------------------|----------------|
| Tem dependências de infraestrutura | Sem infraestrutura |
| Orquestra — sem regras de negócio | Contém regras de negócio |
| `InvoiceService` | `FeeCalculationService` |

Ver [domain-services.md](./domain-services.md) para detalhes.
