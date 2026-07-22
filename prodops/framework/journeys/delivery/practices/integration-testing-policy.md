# Integration Testing Policy

Testes de integração e aceitação neste repositório exercitam o stack completo da aplicação:
- Aplicação NestJS real (todos os módulos conectados)
- DynamoDB real via LocalStack
- Instâncias de serviço reais (sem substituições)
- HTTP real via supertest

## Localização dos testes de aceitação

`api/test/` — um arquivo por comportamento de domínio (`criar-invoice`, `cancelar-invoice`, `confirmar-pagamento`, `api-token`).

## Estrutura dos testes

```typescript
// Uma app por arquivo — criada no beforeAll, encerrada no afterAll
beforeAll(async () => {
  fixture = await buildTestFixture();
  app = fixture.app;
});

afterAll(async () => {
  await teardownFixture(fixture);
});

// Tabelas truncadas entre testes
beforeEach(async () => {
  await truncateAllTables();
});
```

## LocalStack

Serviços obrigatórios: `dynamodb`, `sqs`.

Inicializar e verificar via `./scripts/test-acceptance.sh`. O script detecta se o LocalStack está rodando e o inicia se necessário.

## Cliente DynamoDB em testes

`api/test/dynamo-test-utils.ts` fornece um cliente DynamoDB singleton com gerenciamento de conexão. Usar `truncateAllTables()` e `resetTestClient()` deste módulo — não criar clientes ad-hoc em arquivos de teste.

## Progressive Substitution

Testes que atualmente dependem de `ASAAS_MOCK=true` devem passar sem modificação quando `ASAAS_MOCK` for removido e a integração com sandbox for substituída. O teste verifica comportamento HTTP observável; o modo interno do provedor é configuração.

## Alinhamento com contratos

Testes de aceitação devem estar alinhados com o arquivo BDD Feature para o mesmo comportamento. Se o arquivo Feature e o teste divergirem, atualizar o arquivo Feature primeiro e tratar a divergência como gap.
