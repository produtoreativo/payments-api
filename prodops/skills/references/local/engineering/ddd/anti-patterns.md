# Anti-patterns — Payments Domain

## 1. Anemic Domain Model

**Sintoma:** `Invoice` é uma struct de dados sem comportamento. Toda lógica vive em
`InvoiceService`.

```typescript
// ERRADO — Invoice sem comportamento
class Invoice { status: string; tenantId: string; amount: number; }

// Em InvoiceService — regra de domínio inline no service
if (invoice.status === 'OPEN') {
  invoice.status = 'CONFIRMED';  // sem validação de invariante
}
```

**Correção:** mover lógica de transição para `invoice.confirm()` e `invoice.cancel()`.
O aggregate garante invariantes. `InvoiceService` apenas orquestra.

---

## 2. God Service

**Sintoma:** `InvoiceService` com 500+ linhas fazendo validação de input, queries
DynamoDB, chamadas HTTP ao Asaas, logging estruturado, emissão de eventos e todas
as regras de negócio em um único lugar.

**Correção:** separar responsabilidades:
- Regras de negócio → aggregate `Invoice` e domain services
- Persistência → `InvoiceRepository` adapter
- Provedor externo → `AsaasService` adapter
- `InvoiceService` vira um orquestrador fino chamando os acima

---

## 3. Feature Envy

**Sintoma:** método em `InvoiceService` acessa 5+ campos de `Invoice` para calcular
algo que pertence à própria fatura.

```typescript
// ERRADO — service fazendo trabalho do invoice
const canCancel =
  invoice.status !== 'CONFIRMED' &&
  invoice.status !== 'RECEIVED' &&
  invoice.providerPaymentId !== undefined;
```

**Correção:** mover o cálculo para `invoice.canCancel(): boolean`. Se um método tem
mais interesse nos dados de outro objeto do que nos seus próprios, a lógica pertence
ao outro objeto.

---

## 4. Primitive Obsession

**Sintoma:** `tenantId`, `orderId` e `invoiceId` são todos `string` no codebase.
Fácil de trocar acidentalmente — compila sem erro.

```typescript
// ERRADO
async findInvoice(tenantId: string, invoiceId: string): Promise<InvoiceRecord>

// Chamada com argumentos invertidos — compila, falha silenciosamente em runtime
await repo.findInvoice(invoiceId, tenantId);
```

**Correção:** usar `TenantId` value object. O compilador rejeita inversão de argumentos.
Validação (não-vazio, formato) roda no construtor uma vez, não espalhada nos services.

---

## 5. Transaction Script

**Sintoma:** `InvoiceService.confirmInvoice()` é uma sequência imperativa de passos:
carregar registro → verificar string de status → atualizar string → salvar → notificar.
Nenhum domain object, nenhum método de aggregate chamado.

**Correção:** identificar conceitos de domínio. `invoice.confirm()` captura a regra
de transição. O script vira orquestração: carregar aggregate → chamar método → salvar → emitir evento.

---

## 6. Leaky Abstraction

**Sintoma:** `InvoiceRepository` retorna tipos DynamoDB (`AttributeValue`, registros
brutos) que os chamadores precisam decodificar.

```typescript
// ERRADO — tipo de infraestrutura vazando para a camada de aplicação
findById(id: string): Promise<Record<string, AttributeValue> | null>
```

**Correção:** o método privado `toDomain()` do adapter mapeia de registros DynamoDB
para domain objects antes de retornar. Chamadores recebem um objeto de domínio limpo.
Detalhes de infraestrutura nunca cruzam a fronteira do port.
