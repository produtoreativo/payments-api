# Quality Gates

Use este arquivo para registrar Quality Gates de release que se aplicam à implementação, validação, ship e promoção.

## Delivery Gates

- O contexto ProdOps relevante foi lido antes da implementação.
- Mudanças de comportamento são cobertas por testes respaldados por BDD quando aplicável.
- Riscos do Reliability Plan impactados pela mudança foram revisados.
- Evidências de build, teste ou validação estão registradas no Release Trail.
- Acompanhamentos operacionais estão registrados em vez de deixados implícitos.

## Gates de análise estática (`validate`)

Executados localmente pelo [`/finish validate`](../../../../../skills/finish/steps/validate/SKILL.md),
replicando o que a pipeline remota (`.github/workflows/pr-gates.yml`) roda. Os
comandos canônicos vivem em [`prodops/exec/manifest.yaml`](../../../../../exec/manifest.yaml)
(`gates:`) — este arquivo referencia, não os reescreve.

- **lint** (`gates.lint`) — ESLint sobre as fontes da api, sem erros (warnings
  não bloqueiam; o gate exige exit 0).
- **build** (`gates.build`) — build de produção NestJS compila.
- **acceptance** (`gates.acceptance`, quando comportamento/contratos mudaram) —
  suíte e2e contra LocalStack. É a **única exceção dinâmica** do `validate`.
- **no_mocks** (`gates.no_mocks`) — ver Test Quality Gates abaixo.

**Cobertura** (`gates.coverage`). Subproduto da suíte de aceitação: rodar a
aceitação emite o relatório em **Cobertura XML**
(`api/coverage/cobertura-coverage.xml`), formato que o GitHub Code Quality
consome. O limiar canônico está no manifest (`gates.coverage.threshold_pct`) e é
verificado por `./scripts/check-coverage-threshold.sh`, sobre a métrica de
**branches**.

**O que este gate bloqueia — e o que não bloqueia.** Ele bloqueia **apenas o
auto-merge**: abaixo do limiar, o [`request`](../../../../../skills/finish/steps/request/SKILL.md)
não arma o `gh pr merge --auto` e registra o motivo no PR. O PR continua aberto,
verde e **mergeável manualmente** por um humano após review. Cobertura baixa
desarma a automação, nunca a capacidade de mergear.

Por isso `gates.coverage` **não** é um required status check e não aparece como
job bloqueante em `pr-gates.yml`: um required check bloquearia também o merge
manual — exatamente o que este desenho preserva.

**Falha em qualquer gate estático não avança o Finish:** a correção é mudança de
produto e retorna ao [`hack tdd`](../../../../../skills/hack/steps/tdd/SKILL.md), não
ao `validate` (que não escreve código).

## Branch protection para auto aprovação (`review`)

Condições que o [`/finish review`](../../../../../skills/finish/steps/review/SKILL.md)
inspeciona **sem executar a pipeline**, antes de armar o auto-merge. Cada
condição ausente é um **bloqueador** a registrar no Finish antes de qualquer auto
aprovação:

- [ ] A pipeline expõe `lint`, `acceptance` e `build` como status checks.
- [ ] Branch protection na branch de destino **exige** esses checks passando
      antes do merge.
- [ ] Nenhum reviewer obrigatório bloqueia o merge de um PR com todos os checks
      verdes (ou um bot auto-aprova).

Ativar `gh pr merge --auto --squash` sem essas condições mergearia código sem
gate — por isso `review` é pré-condição do push e do `request`.

## Test Quality Gates

> **Gate de enforcement do No Mocks Rule.** Este arquivo define o que bloqueia merge. Para a definição técnica e como aplicar no ciclo TDD, ver [`prodops/skills/hack/references/workflow.md § No Mocks Rule`](../../../../../skills/hack/references/workflow.md). Para os Yellow Bar patterns aceitáveis (injeção de erro, unit tests), ver [`mocking-policy.md`](../../../../../skills/references/engineering/tdd-prodops/mocking-policy.md).

**Proibição de test doubles em testes de aceitação.** `api/test/` não deve conter substituições de serviço via `jest.fn()`, implementações de `jest.spyOn(...).mockXxx()` ou chamadas a `.overrideProvider()`. Violações bloqueiam o merge.

**`ASAAS_MOCK=true` é permitido.** É um modo de comportamento projetado do `AsaasService` real, não um test double. O serviço real é instanciado; o flag mock controla qual branch executa.

**DynamoDB real via LocalStack.** Todos os testes de aceitação acessam uma API compatível com DynamoDB real. Modos de repositório em memória ou mockados (`INVOICE_REPOSITORY=memory`, `DYNAMO_MOCK=true`) são proibidos em `api/test/`.

**App compartilhado por arquivo.** Cada spec file cria a aplicação NestJS uma única vez no `beforeAll` e a encerra no `afterAll`. Tabelas são truncadas no `beforeEach`. Não recriar a app por teste.

**Testes de injeção de erro pertencem a unit tests.** Cenários que exigem forçar falha em um serviço externo (timeout, resposta malformada, erro de rede) não são cenários de teste de aceitação. São unit tests direcionados à camada de serviço em isolamento e ficam fora dos acceptance specs em `api/test/`.
