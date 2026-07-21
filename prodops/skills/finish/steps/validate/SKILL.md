---
name: finish/validate
description: Static quality analysis before push. Use to replicate locally what the remote pipeline will run, so failures surface before a push instead of on a red PR.
---

# FINISH → VALIDATE

Execute apenas o step de análise estática de qualidade do fluxo Finish.

**Responsabilidade:** inspecionar a qualidade executando **todos os passos de
análise estática de código**. Como os testes de aceitação são de integração,
eles são a **única exceção de análise dinâmica** admitida neste passo.

**Não é responsabilidade de `validate`:** commitar; escrever ou ler código; ter
escrita em artefatos; fazer push. É um passo de **inspeção**, não de mutação.

## Inputs

- `prodops/exec/manifest.yaml` — comandos e critérios canônicos dos gates
  (`gates.lint`, `gates.acceptance`, `gates.build`, `gates.no_mocks`)
- `prodops/journeys/delivery/phases/finish/quality-gates.md` — o que bloqueia merge
- Current diff — para decidir se a exceção dinâmica (aceitação) se aplica

## Action

### 1. Suíte de análise estática (scripts do repositório)

Fonte de verdade dos comandos: `prodops/exec/manifest.yaml`. Os scripts existem
em `api/package.json` e o jest está instalado — mas nem todos servem como gate
sem ajuste (ver notas):

```bash
cd api

# format — Prettier (gate limpo)
npm run format     # prettier --write "src/**/*.ts" "test/**/*.ts"

# lint — ESLint (ver nota: --fix)
npm run lint       # eslint "{src,apps,libs,test}/**/*.ts" --fix

# build — verificação de compilação (gate limpo)
npm run build      # nest build
```

> A **cobertura** não entra aqui: no repo ela é subproduto da suíte de
> aceitação, que é dinâmica. Ver a seção 3.

**Nota `lint`:** o script usa `--fix`, que **reescreve** arquivos em vez de
falhar — inútil como gate de CI. Para inspecionar sem mutar (o que `validate`
exige), rode o eslint sem `--fix`, como o `pr-gates.yml` faz:
`npx eslint "{src,apps,libs,test}/**/*.ts"` (erros falham; warnings não — o repo
carrega warnings pré-existentes e o gate exige apenas exit 0).

### 2. Ferramentas ainda não presentes como script

A configurar antes de tornar o gate obrigatório (gap deste refinamento):

```bash
# commit lint — mensagens em Conventional Commits
npx --no-install commitlint --edit $1

# SAST — SonarQube (scanner local)
docker run -d --name sonarqube -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p 9000:9000 sonarqube:latest
sonar-scanner \
  -Dsonar.projectKey=payments \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<SONAR_TOKEN>

# dependências — Snyk
snyk test --dev
```

### 3. Exceção dinâmica (aceitação/integração) — e cobertura

Quando comportamento ou contratos mudaram (`gates.acceptance.when:
behavior_or_contract_changed`):

```bash
./scripts/test-acceptance.sh   # também emite api/coverage/cobertura-coverage.xml
```

Requer LocalStack (a app fixture provisiona tabelas DynamoDB mesmo com o
repositório em memória).

**Origem da cobertura.** Não há suítes unitárias sobre `api/src`
(`jest --coverage` via `test:cov` usa `rootDir: src` + `testRegex: .*\.spec\.ts$`
e encontra 0 testes). A cobertura efetiva vem desta suíte de aceitação
(`test/*.e2e-spec.ts`, config `test/jest-e2e.json`). O `jest-e2e.json` foi
configurado para **instrumentar `src` durante a execução da aceitação**
(`collectCoverage` + `collectCoverageFrom: src/**/*.ts`) e emitir o relatório em
**formato Cobertura XML** (`coverageReporters: [text-summary, cobertura]`), que é
o formato que o GitHub Code Quality consome. Por isso rodar a aceitação já gera
`api/coverage/cobertura-coverage.xml` — não há passo de coverage separado.

No CI, o job `acceptance` do `pr-gates.yml` roda em `pull_request` **e** `push`;
o upload do XML via `actions/upload-code-coverage@v1` acontece em **dois casos**:
push na `master` publica o **baseline** da default branch, e o evento
`pull_request` (não-fork) anexa a cobertura do PR, comparada contra esse
baseline. Push em feature branch sem PR **não** faz upload — o servidor só aceita
upload sem PR na default branch. Informativo — não bloqueia merge.

## Critério

Se algum desses falha localmente, o passo falha e **não se avança**. A
justificativa é simples: falhar na pipeline remota depois de um push tem custo
maior (retrabalho, notificações, PR com status vermelho) do que falhar
localmente antes.

**Em caso de falha, retorne ao `hack tdd` — não corrija aqui.** `validate` é um
passo de inspeção, sem escrita em código (ver Guardrails); a correção de uma
falha (lint, build ou aceitação vermelha) é mudança de produto e pertence ao
ciclo TDD do Hack. Encaminhe a falha ao [`hack tdd`](../../../hack/steps/tdd/SKILL.md)
(Red → Green → Refactor) e só reexecute `validate` depois que o Hack fechar em
verde. Um `validate` verde é pré-condição para `review` e o push.

## Guardrails

- Não commitar, não escrever/ler código, não escrever em artefatos, não fazer push.
- Não pular um passo de análise sem registrar o motivo.
