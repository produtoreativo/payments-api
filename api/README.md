# Payments API

API NestJS responsável pelo estado interno de invoices, integração com provedores de pagamento, processamento de webhooks e entrega de eventos aos consumidores.

O contexto de produto, os contratos e os riscos não são duplicados aqui:

- Product Deck: `prodops/artifacts/product/product-deck.md`
- OBCs committed: `prodops/artifacts/obcs/`
- BDD Features committed: `prodops/artifacts/bdd/`
- Arquitetura: `prodops/artifacts/architecture/overview.md`
- Reliability Plans: `prodops/artifacts/plans/reliability/`

## Instalação

```bash
npm install
```

## Execução local

```bash
npm run start:dev
```

Para executar com a sandbox real da Asaas, use:

```bash
./scripts/start-asaas-sandbox-real.sh
```

Consulte `.env.example` para os nomes das variáveis suportadas. Não registre chaves, tokens ou payloads sensíveis neste arquivo ou no repositório.

## Contratos HTTP principais

Os controllers atuais expõem:

| Operação | Rota |
| --- | --- |
| Criar invoice | `POST /invoices` |
| Cancelar invoice | `DELETE /invoices/:id` |
| Receber webhook Asaas | `POST /webhook/payments` |
| Consultar fila de webhook | `GET /webhook/payments/queue` |
| Registrar webhook de consumidor | `POST /webhooks` |
| Listar webhooks de consumidor | `GET /webhooks` |
| Remover webhook de consumidor | `DELETE /webhooks/:id` |

As rotas protegidas usam `X-Api-Token`. O webhook da Asaas usa `asaas-access-token`. Os payloads e comportamentos aceitos são definidos pelos DTOs, OBCs e BDD Features vigentes, não por exemplos históricos.

## Integração Asaas

A Asaas é tratada como PSP externo. A Payments API mantém o estado canônico da invoice e traduz as respostas e eventos do provedor.

Operações atualmente usadas pelo adaptador:

- `POST /v3/customers` para criação de cliente no provedor;
- `POST /v3/payments` para criação de cobrança;
- `DELETE /v3/payments/{id}` para remoção de cobrança aberta;
- webhooks como `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED` e `PAYMENT_DELETED`.

Regras operacionais:

- credenciais de sandbox e produção devem permanecer separadas;
- chamadas externas precisam usar timeout e tratamento de falhas compatíveis com o Reliability Plan;
- webhooks devem validar o token, preservar correlação e ser idempotentes;
- tokens, documentos completos e outros dados sensíveis não devem aparecer em logs;
- cancelamento de cobrança aberta não equivale a estorno de pagamento confirmado.

Detalhes observados na documentação externa da Asaas devem ser verificados novamente antes de alterar contratos ou comportamento de produção.

## Testes e qualidade

```bash
npm run lint
npm run build
npm test
```

Para comportamentos e contratos:

```bash
../scripts/test-acceptance.sh
```

As políticas canônicas de teste estão em `prodops/framework/journeys/delivery/practices/`.
