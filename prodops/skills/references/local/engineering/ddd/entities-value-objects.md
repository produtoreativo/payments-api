# Entities e Value Objects

## Entidade — tem identidade única

Definida pela identidade, não pelos atributos. Dois `Invoice` com o mesmo `invoiceId`
são o mesmo invoice, mesmo que outros campos difiram.

**Invoice** é a única entidade (e aggregate root) deste contexto.
- Identidade: `invoiceId` (formato `inv_<ULID>`)
- Identidade persiste através de mudanças de estado: confirmar ou cancelar não cria
  um novo invoice — é o mesmo invoice em novo estado.

## Value Object — definido pelos atributos, sem identidade

Imutável. Dois VOs com os mesmos valores são iguais. Para "mudar" um VO, substitua-o.

### TenantId

Garante que o identificador do lojista não seja vazio ou nulo.

```typescript
export class TenantId {
  constructor(readonly value: string) {
    if (!value?.trim()) throw new Error('TenantId cannot be empty');
  }

  equals(other: TenantId): boolean {
    return this.value === other.value;
  }
}
```

### Status como Value Object

```typescript
export type InvoiceStatus =
  | 'CREATED' | 'PROVIDER_PENDING' | 'OPEN'
  | 'CONFIRMED' | 'RECEIVED' | 'FAILED'
  | 'CANCELLED' | 'CANCEL_REQUESTED' | 'CANCEL_RECONCILIATION_REQUIRED';
```

Nunca usar strings literais espalhadas no código — sempre o tipo `InvoiceStatus`.

### Money

```typescript
export class Money {
  constructor(readonly amount: number, readonly currency: 'BRL' = 'BRL') {
    if (amount <= 0) throw new Error('Amount must be positive');
  }
}
```

O projeto valida `currency === 'BRL'` no application service. Encapsular em `Money`
move essa regra para o domínio.

## Por que Value Objects importam

| Sem VOs | Com VOs |
|---------|---------|
| `tenantId: string` — qualquer string compila | `TenantId` — string inválida é erro de compilação |
| Validação espalhada nos services | Validação no construtor, garantida em todo lugar |
| Fácil trocar `orderId` por `tenantId` (ambos `string`) | Tipos distintos — o compilador rejeita a troca |

**Regra prática:** se um primitivo tem restrição ou significado específico no domínio,
envolva-o em um Value Object.

## Primitive Obsession no projeto atual

O `InvoiceRecord` usa `tenantId: string` e `orderId: string`.
Ao refatorar para modelo rico, substituir por `TenantId` e manter `orderId: string`
(referência opaca sem validação de negócio).

Ver [anti-patterns.md](./anti-patterns.md) para o padrão Primitive Obsession completo.
