# ProdOps TDD

ProdOps TDD é a evolução do TDD clássico para o contexto de produtos digitais observáveis e confiáveis. Combina TDD, contratos, testes de integração, observabilidade, confiabilidade e evidência operacional em uma única prática de codificação.

**ProdOps TDD não é um fluxo separado.** É a prática utilizada dentro do [Hack Flow](../phases/hack/README.md).

---

## Definição central

> Escrever um contrato verificável. Escrever um teste de integração contra esse contrato. Fazê-lo falhar. Fazê-lo passar com a implementação mínima. Observar. Refatorar. Commitar. Registrar evidência.

O ProdOps TDD estende o TDD clássico (escola Detroit/Chicago):
1. Partindo de um contrato, não apenas de um teste.
2. Priorizando testes de integração e aceitação sobre unit tests.
3. Exigindo validação de observabilidade como parte do ciclo.
4. Consumindo o Commit Workflow após cada ciclo Red→Green→Refactor.
5. Produzindo evidências registradas antes da promoção.

---

## Principles

### Contract First
Toda implementação parte de um contrato verificável. Contratos aceitos: OpenAPI, AsyncAPI, JSON Schema, OBC, BDD Feature, eventos, especificações existentes. Se não existe contrato, criar antes de escrever o teste.

### Integration First
Priorizar testes que exercitam a aplicação por chamadas reais (HTTP, DynamoDB, eventos). Testar comportamento observável — não implementação interna. Unit tests cobrem casos que não alcançam a fronteira HTTP.

### Observability First
Antes de implementar, definir como o comportamento será observado: quais logs serão emitidos, quais métricas serão registradas, qual correlationId propagará. Observabilidade é parte do ciclo, não um extra pós-implementação.

### Progressive Substitution
Quando um Mock Server baseado em contrato for usado como passo inicial: iniciar com o Mock Server; substituir progressivamente pela API real; nunca reescrever os testes durante essa substituição. Os testes verificam o comportamento pelo contrato — o que está por trás é configuração.

### Non Intrusive Testing
Nunca alterar payload, headers, regras de negócio ou comportamento de produção para facilitar testes. Usar configuração por ambiente (env vars). `ASAAS_MOCK=true` é exemplo correto — ativa modo de comportamento do serviço real, não altera o contrato.

---

## Regras obrigatórias

1. **Priorizar testes de integração.** Os testes devem verificar comportamento na fronteira HTTP ou de evento, não detalhes de implementação interna.

2. **Sem mocks para regras de negócio.** Não substituir serviços próprios que carregam lógica de negócio por test doubles. Ver [No Mocks Rule](../../../../skills/hack/references/workflow.md) e [quality-gates.md](../phases/finish/quality-gates.md).

3. **Sem mocks para APIs de domínio quando existe contrato verificável.** Se existe spec OpenAPI, AsyncAPI ou BDD, testar contra ela. Mock Servers baseados nesse contrato são aceitáveis como infraestrutura temporária.

4. **Mock Servers são infraestrutura, não atalhos.** Um Mock Server simula uma dependência externa com base em um contrato publicado. Deve ser substituível pela integração real sem reescrever os testes (princípio Progressive Substitution).

5. **Não alterar payloads, headers ou lógica de produção para testes.** Os testes devem exercitar o caminho de código real. Variáveis de ambiente e switches de configuração são aceitáveis; branches que só ativam em teste não são.

6. **Preferir configuração por ambiente.** Usar env vars (ex.: `ASAAS_MOCK=true`) para alternar entre modos de teste. `ASAAS_MOCK=true` ativa um modo de comportamento projetado do serviço real — não é um mock object.

7. **Exercitar por chamadas reais sempre que possível.** Usar `supertest` contra a aplicação NestJS em execução, DynamoDB real via LocalStack e instâncias de serviço reais.

8. **Testar comportamento, não implementação.** Fazer asserções sobre respostas HTTP, estado do banco, saída de logs e eventos emitidos — não sobre quais métodos internos foram chamados.

9. **Validar respostas HTTP, mensagens de erro, logs e rastreabilidade.** Um teste que apenas verifica status code é incompleto.

10. **Usar contratos quando aplicável.** OpenAPI, AsyncAPI, Gherkin BDD Features e JSON schemas são contratos válidos. Referenciá-los nos planos de teste.

11. **Manter compatibilidade com Progressive Substitution.** Testes escritos contra um Mock Server devem passar sem modificação quando a integração real for substituída.

---

## TDD Cycle (ProdOps variant)

```
1. Ler contrato / critério de aceite
2. Escrever teste de integração → Red Bar (deve falhar por razão comportamental)
3. Implementar o mínimo → Green Bar
4. Refatorar → continua Green
5. Executar Commit Workflow (formatter → lint → unit tests → commit)
6. Validar observabilidade (logs, erros, traceability, métricas)
7. Registrar evidência
```

Não pular o passo 2. Um teste que nunca foi vermelho não é um teste verificado.

### Integração com Commit Workflow

O ProdOps TDD não implementa formatter, lint, nem gestão de commits. Essa responsabilidade pertence ao **Commit Workflow**.

Após cada ciclo Red→Green→Refactor (step 5 acima), o Hack consome o Commit Workflow:

```
Red → Green → Refactor → [Commit Workflow] → próximo ciclo
```

O Commit Workflow executa:
- Formatter (`npm run lint` com `--fix`)
- Lint (bloqueia se não passar)
- Unit tests rápidos
- Validação de Conventional Commit

Ver: [capabilities/commit-workflow/README.md](../capabilities/commit-workflow/README.md)

### Confiabilidade no ciclo

Durante a implementação, considerar os requisitos de confiabilidade para o comportamento sendo testado:

| Aspecto | O que verificar |
|---|---|
| **Timeout** | O sistema tem timeout configurado para chamadas ao provedor? |
| **Retry** | Retentativas com mesma `Idempotency-Key` produzem o mesmo resultado? |
| **Idempotência** | Mesma operação executada duas vezes retorna o mesmo estado? |
| **Exceções** | Erros do provedor produzem resposta HTTP significativa (4xx/5xx com `message`)? |
| **Degradação controlada** | Falha de dependência externa não derruba o sistema inteiro? |
| **Códigos HTTP** | Os status codes correspondem ao comportamento semântico (201, 400, 404, 409)? |

Esses aspectos não precisam de testes separados quando já cobertos pelo teste de integração principal. Mas devem ser verificados no Green Bar antes de avançar.

---

## Patterns

### Red Bar Patterns

| Pattern | Quando usar |
|---|---|
| **Starter Test** | Primeiro teste para uma nova capability; verifica o resultado observável mais simples possível. |
| **One Step Test** | Um incremento de comportamento por teste; evita dar saltos à frente. |
| **Explanation Test** | Esclarece comportamento esperado para uma spec ambígua ou pouco documentada. |
| **Learning Test** | Explora o comportamento de uma dependência de terceiros antes de integrá-la. |
| **Another Test** | Captura uma nova ideia que surgiu durante a escrita do teste atual; adicioná-la à lista para não perdê-la. |
| **Triangulation Test** | Adiciona um segundo cenário para forçar a generalização quando Fake It foi usado primeiro. |
| **Regression Test** | Escrito antes de corrigir um defeito confirmado; garante que o defeito não possa recorrer. |
| **Break Test** | Verifica condições de fronteira: entrada vazia, valores máximos, estados inválidos. |
| **Do Over** | Exclui uma suite de testes que testava implementação em vez de comportamento e a reescreve a partir do contrato. |

### Green Bar Patterns

| Pattern | Quando usar |
|---|---|
| **Fake It** | Retorna um valor hardcoded para chegar ao verde rapidamente; seguido de Triangulate para generalizar. |
| **Triangulate** | Adiciona um segundo cenário que força o Fake It a se tornar uma implementação real. |
| **Obvious Implementation** | Usado quando a implementação correta é óbvia e curta; pula o Fake It. |
| **One-to-Many** | Conduz uma implementação consciente de coleção a partir de um teste de item único, depois adiciona o teste multi-item. |

### Yellow Bar Patterns

Yellow Bar patterns gerenciam a complexidade dos testes. **Não são licença para mockar lógica de negócio.**

| Pattern | Uso aceitável | Não aceitável |
|---|---|---|
| **Mock Object** | Dependências técnicas: logger, clock, gerador de UUID, adaptador de telemetria, adaptador de e-mail, cliente HTTP externo quando não existe contrato e a integração é cara/imprevisível. | Serviços próprios, repositórios, regras de domínio ou qualquer componente que carrega comportamento de negócio. |
| **Self Shunt** | Classe de teste implementa interface de listener para observar eventos internos. | — |
| **Log String** | Captura saída de log para verificar que o comportamento de observabilidade está correto. | — |
| **Child Test** | Divide um teste com falha em um teste menor quando o teste pai é complexo demais para depurar. | — |
| **Crash Test Dummy** | Simula uma falha catastrófica (OOM, erro fatal) que não pode ser acionada em ambiente real. | Simular erros de negócio previsíveis que o sistema real consegue produzir. |
| **Broken Test** | Deixa um teste falhando intencionalmente com comentário claro quando o trabalho está em progresso e um commit é necessário. | — |
| **Clear Check-in** | Garante que todos os testes passam antes de commitar, mesmo que isso signifique reverter uma mudança quebrada. | — |

**Regra:** um Mock Object é aceitável apenas quando não oculta comportamento de negócio. Se o mock substitui lógica que o código real executaria de forma diferente, está ocultando um defeito.

---

## O que ProdOps TDD não é

- Não é motivo para pular testes de aceitação.
- Não é motivo para usar mocks como abordagem padrão.
- Não é um fluxo separado do Hack Flow.
- Não é permissão para adicionar branches exclusivos de teste no código de produção.
- Não é substituto para validação de observabilidade.
