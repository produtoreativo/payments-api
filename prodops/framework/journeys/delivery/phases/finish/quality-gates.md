# Quality Gates

Use este arquivo para registrar Quality Gates de release que se aplicam à implementação, validação, ship e promoção.

## Delivery Gates

- O contexto ProdOps relevante foi lido antes da implementação.
- Mudanças de comportamento são cobertas por testes respaldados por BDD quando aplicável.
- Riscos do Reliability Plan impactados pela mudança foram revisados.
- Evidências de build, teste ou validação estão registradas no Release Trail.
- Acompanhamentos operacionais estão registrados em vez de deixados implícitos.

## Test Quality Gates

> **Gate de enforcement do No Mocks Rule.** Este arquivo define o que bloqueia merge. Para a definição técnica e como aplicar no ciclo TDD, ver [`prodops/skills/hack/references/workflow.md § No Mocks Rule`](../../../../../skills/hack/references/workflow.md). Para os Yellow Bar patterns aceitáveis (injeção de erro, unit tests), ver [`mocking-policy.md`](../../../../../skills/references/engineering/tdd-prodops/mocking-policy.md).

**Proibição de test doubles em testes de aceitação.** `api/test/` não deve conter substituições de serviço via `jest.fn()`, implementações de `jest.spyOn(...).mockXxx()` ou chamadas a `.overrideProvider()`. Violações bloqueiam o merge.

**`ASAAS_MOCK=true` é permitido.** É um modo de comportamento projetado do `AsaasService` real, não um test double. O serviço real é instanciado; o flag mock controla qual branch executa.

**DynamoDB real via LocalStack.** Todos os testes de aceitação acessam uma API compatível com DynamoDB real. Modos de repositório em memória ou mockados (`INVOICE_REPOSITORY=memory`, `DYNAMO_MOCK=true`) são proibidos em `api/test/`.

**App compartilhado por arquivo.** Cada spec file cria a aplicação NestJS uma única vez no `beforeAll` e a encerra no `afterAll`. Tabelas são truncadas no `beforeEach`. Não recriar a app por teste.

**Testes de injeção de erro pertencem a unit tests.** Cenários que exigem forçar falha em um serviço externo (timeout, resposta malformada, erro de rede) não são cenários de teste de aceitação. São unit tests direcionados à camada de serviço em isolamento e ficam fora dos acceptance specs em `api/test/`.
