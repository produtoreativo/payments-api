# OBC - Criar Invoice via Gateway

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-38 |
| Iteração | v0.4.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-38 (#38) — v0.4.0, PR #89. Registro anterior: Downstream. Status `Entrou` em `prodops/artifacts/plans/iteration-plan.md` (seção "Iteration Plan recomendado") — jornada Pix como primeiro billing type habilitado.
**Pendência:** iteração concluída (PR #89); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-003](../business-intents/PI-003.md) |
| Product Tracking Item | issue #38 (DS-38), ver `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | PAY-ICE-001 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |
| Relacionado | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) |

## Business Outcome

Magazine Siará consegue criar cobranças via gateway de Payments sem acoplamento direto ao provedor Asaas. O Checkout envia um contrato único de invoice; o gateway resolve o provedor, cria ou reutiliza o cliente Asaas, garante idempotência por chave de pedido e retorna identificadores rastreáveis. A invoice nasce com status `OPEN` apenas quando o `providerPaymentId` está consolidado — nunca antes. Erros de validação são auditáveis sem expor segredos ou payload sensível.

### Em linguagem executiva

Uma cobrança só é considerada criada quando o Asaas confirma que a recebeu e registrou no sistema dele. Enquanto essa confirmação não chega, o sistema não exibe a cobrança como ativa para o cliente — ela não existe a meio caminho. É o equivalente a um comprovante bancário: o depósito só está feito quando o banco emite o comprovante.

Isso protege o Magazine Siará de dois problemas: (1) mostrar ao cliente uma cobrança que o Asaas nunca chegou a registrar, e (2) cobrar duas vezes o mesmo pedido em caso de retentativa — o sistema reconhece a chave do pedido e devolve a cobrança já existente sem criar uma nova.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/create-invoice.feature`; marcar após verificação.

- [ ] Criar invoice com sucesso no Asaas usando cliente ja vinculado
- [ ] Criar cliente Asaas antes da invoice quando nao houver vinculo
- [ ] Evitar duplicidade em retentativa do ecommerce
- [ ] Rejeitar provedor nao habilitado
- [ ] Falha transiente ao criar cobranca no provedor
- [ ] Falha de validacao retornada pelo provedor

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Service Deck: [compra-com-pix](../product/context/service-decks/compra-com-pix.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `invoice.created` | Planejado | Invoice criada com sucesso no provedor — status `OPEN`, `providerPaymentId` presente. — *equivalente provável no código (a confirmar): `payments.invoice.created`* | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `billingType`, `correlationId` |
| `invoice.creation_failed` | Planejado | Falha ao criar invoice no provedor — invoice em `FAILED` ou `PROVIDER_PENDING`. | `invoiceId`, `orderId`, `tenantId`, `reason`, `provider`, `correlationId` |
| `invoice.idempotency_hit` | Planejado | Retentativa com mesma chave de idempotência — invoice existente retornada sem nova cobrança. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `invoice.provider_rejected` | Planejado | Provedor rejeitou a criação por dados inválidos — invoice marcada como `FAILED`. | `invoiceId`, `orderId`, `tenantId`, `providerErrorCode`, `correlationId` |
| `invoice.customer_created` | Planejado | Cliente Asaas criado antes da invoice por ausência de vínculo. — *equivalente provável no código (a confirmar): `pagamento.cobranca.cadastrada.cliente.cadastrado`* | `tenantId`, `customerId`, `providerCustomerId`, `correlationId` |
| `invoice.access_rejected` | Planejado | Tentativa de criar invoice com provedor desabilitado para o tenant. | `tenantId`, `provider`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Invoices criadas com `providerPaymentId` presente na resposta ao Checkout. | 99.9% | [apurar] |
| Retentativas com mesma `Idempotency-Key` retornam invoice existente sem nova chamada ao provedor. | 100% | [apurar] |
| Invoice `OPEN` nunca retornada ao Checkout sem `providerPaymentId` consolidado. | 100% | [apurar] |
| Erros de validação do provedor retornados sem segredo ou payload sensível exposto. | 100% | [apurar] |
| Solicitações com provedor desabilitado para o tenant rejeitadas antes de chamar a API do provedor. | 100% | [apurar] |

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

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |
| Serviço externo | Asaas (PSP) | Crítica (Product Deck, seção 4) |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/create-invoice.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-001
- OBCs relacionados: `prodops/artifacts/obcs/payment-confirmation.md`, `prodops/artifacts/obcs/cancel-invoice.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
