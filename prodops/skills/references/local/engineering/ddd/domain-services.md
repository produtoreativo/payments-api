# Domain Services

## Quando criar um domain service

Lógica que não pertence a nenhuma entidade específica e envolve múltiplos
aggregates ou regras de domínio puras.

**Criar quando:**
- A lógica é significativa para o domínio mas não tem "dono" claro no aggregate
- Envolve múltiplos aggregates ou fatores externos ao aggregate
- O nome como serviço reflete como especialistas do domínio descrevem o conceito

## Quando NÃO criar

- Lógica que pertence claramente ao `Invoice` → mover para `invoice.confirm()`,
  `invoice.cancel()` ou outros métodos do aggregate
- Preocupações de infraestrutura (HTTP, DynamoDB, SQS) → application service ou adapter
- Orquestração (chamar repo, chamar provider, emitir evento) → application service

Criar domain service para toda operação leva ao Anemic Domain Model.
Default: lógica no aggregate. Extrair para service só quando a ownership é ambígua.

## Exemplo aceitável: FeeCalculationService

Taxa de processamento depende do método de pagamento (no Invoice) e do plano do
tenant (contexto externo, não do Invoice).

```typescript
// domain/services/fee-calculation.service.ts
export class FeeCalculationService {
  calculate(amount: number, billingType: BillingType, tenantPlan: TenantPlan): number {
    const rate = this.resolveRate(billingType, tenantPlan);
    return amount * rate;
  }

  private resolveRate(method: BillingType, plan: TenantPlan): number {
    if (plan === 'PREMIUM' && method === 'PIX') return 0.005;
    if (method === 'PIX') return 0.01;
    if (method === 'BOLETO') return 0.015;
    return 0.025; // CREDIT_CARD default
  }
}
```

`Invoice` não conhece `TenantPlan` — cruzaria a fronteira do bounded context.
`FeeCalculationService` faz a ponte sem acoplar o aggregate ao contexto de tenant.

## Exemplo errado

```typescript
// ERRADO — isso é orquestração, não regra de domínio
export class InvoiceDomainService {
  async createAndCharge(dto: CreateInvoiceDto): Promise<void> {
    await this.repository.save(invoice);  // infraestrutura
    await this.asaas.createCharge(...);   // infraestrutura
    this.eventEmitter.emit(...);          // infraestrutura
  }
}
```

Esse padrão é um application service disfarçado de domain service.

## Domain service vs application service

| Domain service | Application service |
|----------------|---------------------|
| Contém regras de negócio | Orquestra — sem regras de negócio |
| Camada de domínio | Camada de aplicação |
| Sem dependências de infraestrutura | Injeta adapters e repositórios |
| Exemplo: `FeeCalculationService` | Exemplo: `InvoiceService` |
