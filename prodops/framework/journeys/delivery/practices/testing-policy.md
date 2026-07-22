# Testing Policy

## Pirâmide de testes

Este repositório prioriza testes na seguinte ordem:

1. **Testes de aceitação / E2E** — fronteira HTTP, DynamoDB real (LocalStack), instâncias de serviço reais. Ficam em `api/test/`.
2. **Testes de integração** — interações entre módulos e entre serviços.
3. **Unit tests** — comportamento isolado de função única. Usados para casos de borda e caminhos de erro que não alcançam a fronteira HTTP.

Unit tests não substituem testes de aceitação para comportamento funcional.

## Ferramentas

- Test runner: Jest (configurado em `api/test/jest-e2e.json`)
- Asserções HTTP: supertest
- Infraestrutura local: LocalStack (DynamoDB, SQS)
- Runner de testes de aceitação: `./scripts/test-acceptance.sh`

## No Mocks Rule

A proibição de test doubles em testes de aceitação é aplicada como Quality Gate que bloqueia merge.

- Definição técnica completa: [`prodops/skills/hack/references/workflow.md § No Mocks Rule`](../../../../skills/hack/references/workflow.md)
- Enforcement gate (o que bloqueia merge): [`prodops/framework/journeys/delivery/phases/finish/quality-gates.md § Test Quality Gates`](../phases/finish/quality-gates.md)

## Testes de caminhos de erro

Caminhos de erro que exigem falha de sistema externo pertencem a unit tests ou testes de camada de serviço, não a testes de aceitação. Ver [ProdOps TDD — Yellow Bar Patterns](prodops-tdd.md).

## App compartilhado por arquivo

Cada arquivo de teste de aceitação cria a aplicação NestJS uma vez no `beforeAll` e a encerra no `afterAll`. Tabelas são truncadas no `beforeEach`. Recriar a app por teste é proibido.

## Cobertura

Thresholds de cobertura (quando configurados em `jest.config.*`) não devem ser reduzidos sem uma justificativa registrada em um [Decision Trail](../../../../templates/assessment/decision-trail.md).
