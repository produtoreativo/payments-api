# Capability — Commit Workflow

→ [Capabilities](../README.md)

Padroniza o ciclo completo de commits, validações locais, geração de Pull Requests e encerramento de Tasks, usando apenas mecanismos nativos do Git.

## Estrutura deste diretório

```
commit-workflow/
├── README.md          ← este arquivo — referência operacional da capability
├── hooks/             ← Git hooks: delegam execução para scripts/
│   ├── pre-commit         pré-commit: format → lint → unit tests
│   ├── prepare-commit-msg aplica o template de mensagem (sem -m, merge ou squash)
│   ├── commit-msg         valida Conventional Commits
│   └── pre-push           pré-push: build → integration tests (contracts/quality gates somente com Makefile)
├── scripts/           ← lógica de validação: chamados pelos hooks e pela CI
│   ├── pre-commit.sh
│   ├── prepare-commit-msg.sh
│   ├── commit-msg.sh
│   ├── pre-push.sh
│   ├── test-commit-msg.sh  suíte de regressão do commit-msg (via `git commit` real)
│   └── check-commit-msg-suite.sh  roda a suíte só quando os scripts mudaram
└── templates/         ← templates reutilizáveis para PR, task-closing e mensagem de commit
    ├── commit-template.txt
    ├── pull_request.md
    └── task-closing.md
```

Os **hooks** contêm apenas uma linha de delegação — toda a lógica reside nos **scripts**. Isso permite testar scripts independentemente e reutilizá-los na CI sem depender dos hooks.

### Testando o `commit-msg`

```bash
./prodops/framework/journeys/delivery/capabilities/commit-workflow/scripts/test-commit-msg.sh
```

Roda o validador através de um `git commit` **real**, num repositório descartável
com o mesmo `core.hooksPath` deste repo — o caminho de integração, não só o
script isolado. Exit 0 = todos os casos passaram.

A propriedade que a suíte protege: **as regras do Conventional Commits valem para
o subject, não para a mensagem inteira**. Ler a mensagem toda (`cat "$1"`) em vez
do subject (`head -1 "$1"`) faz o hook rejeitar qualquer commit com body ou
trailer — e todo commit do fluxo ProdOps carrega um `Co-Authored-By:`. A suíte
foi verificada por mutação: injetando esse `cat`, os quatro casos de escopo de
subject falham e a suíte sai 1.

---

## Princípios

- **Git First** — sem Husky, sem commitlint, sem ferramentas externas.
- **Language Agnostic** — descobre automaticamente os comandos do projeto; nunca codifica tecnologia específica.
- **Zero dependência** — os hooks chamam scripts do próprio repositório; a única ferramenta externa usada é o `node` já exigido pelo projeto (para ler `package.json`).
- **Reutilização máxima** — nunca duplica scripts que já existem no projeto.
- **CI = Local** — a CI reutiliza exatamente os mesmos comandos usados localmente.

---

## Configuração

### Setup completo do ambiente

```bash
./scripts/setup-dev.sh
```

Verifica pré-requisitos, instala dependências npm, configura `core.hooksPath`, verifica permissões dos hooks. Idempotente.

### Configurar apenas os hooks

```bash
git config core.hooksPath prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
```

Para verificar:

```bash
git config core.hooksPath
# prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
```

Para remover:

```bash
git config --unset core.hooksPath
```

### Permissões

```bash
chmod +x prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks/*
chmod +x prodops/framework/journeys/delivery/capabilities/commit-workflow/scripts/*.sh
```

O repositório armazena permissões via `git update-index --chmod=+x`. Verifique com:

```bash
git ls-files --stage prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks/
```

---

## Pipeline de Validação

| Momento | Hook | O que executa |
|---|---|---|
| Antes do commit | `pre-commit` | Formatter → Lint → Unit tests |
| Na mensagem | `commit-msg` | Conventional Commit format |
| Antes do push | `pre-push` | Build → Integration tests → Contracts e Quality gates (somente quando houver `Makefile`) |

Qualquer etapa com exit code ≠ 0 bloqueia o commit ou push. Não existe modo "warn only" — passa ou bloqueia.

### Descoberta automática de comandos

Os scripts descobrem os comandos disponíveis nesta ordem:

1. `Makefile` — targets: `format`, `lint`, `test`, `build`, `test:acceptance`
2. `Taskfile.yml` / `Taskfile.yaml`
3. `justfile`
4. `api/package.json` — scripts: `lint`, `test`, `build`, `test:acceptance`, `format`
5. `package.json` (raiz)
6. `Gradle` (`./gradlew`)
7. `Maven` (`./mvnw`)
8. `Go` (`go test`, `go build`)
9. `Python` (`pytest`, `ruff`)
10. `.NET` (`dotnet build`, `dotnet test`)
11. Scripts em `scripts/` (ex: `scripts/test-acceptance.sh`)

### Comandos neste repositório (Node/NestJS)

| Etapa | Comando |
|---|---|
| Formatter | `cd api && npm run format` (prettier) |
| Lint | `cd api && npm run lint` (inclui `--fix`) |
| Unit tests | `cd api && npm run test` |
| Build | `cd api && npm run build` |
| Acceptance tests | `./scripts/test-acceptance.sh` |

---

## Conventional Commits

Formato:

```
<type>(<scope>): <summary>

[body opcional]

[footer opcional]
```

- **type** — obrigatório, define a natureza da mudança.
- **scope** — opcional, minúsculas, delimita o módulo ou domínio afetado.
- **summary** — obrigatório, imperativo, minúsculas, sem ponto final, máximo 72 caracteres.
- **body** — opcional, explica o "porquê", não o "o quê".
- **footer** — opcional, referências a issues, breaking changes (`BREAKING CHANGE:`).

### Tipos

| Type | Quando usar |
|---|---|
| `feat` | Nova funcionalidade visível ao usuário ou consumidor da API. Incrementa MINOR no SemVer. |
| `fix` | Correção de comportamento incorreto. Incrementa PATCH. |
| `docs` | Mudanças exclusivas em documentação (`.md`, comentários, specs). |
| `test` | Adição ou correção de testes sem alterar código de produção. |
| `refactor` | Mudança interna sem alterar comportamento externo e sem corrigir bug. |
| `perf` | Melhoria de performance sem mudança de comportamento externo. |
| `build` | Mudanças no sistema de build, dependências, scripts de infra. |
| `ci` | Mudanças em workflows de CI/CD (GitHub Actions, configurações de pipeline). |
| `style` | Formatação, espaçamento, vírgulas — sem impacto em lógica. |
| `chore` | Tarefas de manutenção que não se encaixam em nenhum tipo acima. |
| `revert` | Reverte um commit anterior. O summary deve referenciar o commit revertido. |

### Breaking changes

```
feat(invoices)!: remove billingType PIX from create endpoint
```

Ou via footer:

```
BREAKING CHANGE: PIX billing type removed from POST /invoices
```

### Scopes sugeridos neste repositório

| Scope | Módulo |
|---|---|
| `invoices` | Criação, cancelamento, confirmação de invoices |
| `auth` | API token validation, admin token management |
| `webhook` | Webhook processing, Asaas events |
| `asaas` | AsaasService, provider integration |
| `dynamo` | DynamoDB, repositories |
| `prodops` | Documentação ProdOps |
| `scripts` | Scripts utilitários |
| `ci` | GitHub Actions workflows |

### Exemplos

```
feat(invoices): add hosted credit card payment flow
fix(webhook): prevent duplicate PAYMENT_CONFIRMED processing
docs(prodops): unify commit-workflow as capability
test(invoices): add boleto acceptance scenarios
refactor(auth): extract token validation to TokenRepository
chore: update STAGING_ADMIN_SECRET in GitHub Actions
ci: replace --runInBand with --maxWorkers=1 in acceptance tests
```

---

## Fluxo integrado

```
Hack  → commit pequeno → pre-commit (format + lint + unit tests)
                       → commit-msg (Conventional Commit validado)
Sync  → pre-push (build + integration tests; contracts somente com Makefile)
Finish → PR gerado com template
```

---

## Checklist do Finish

Execute na ordem abaixo antes de publicar o Pull Request.

### 1. Histórico de commits

```bash
git log --oneline origin/HEAD..HEAD
```

- [ ] Todos os commits seguem Conventional Commits.
- [ ] Não há commits "WIP", "temp", "fixup" não resolvidos.
- [ ] O histórico conta a história da mudança de forma coerente.

### 2. Formatter + Lint

```bash
cd api && npm run format && npm run lint
```

- [ ] Lint passa sem erros (exit 0).

### 3. Build

```bash
cd api && npm run build
```

- [ ] Build compila sem erros TypeScript.

### 4. Testes

```bash
cd api && npm run test
./scripts/test-acceptance.sh
```

- [ ] Todos os testes unitários passam.
- [ ] Todos os testes de aceitação passam.
- [ ] Nenhum teste novo usa mocks de regra de negócio.

### 5. Contratos

- [ ] BDD Feature atualizado se o comportamento mudou.
- [ ] OpenAPI spec atualizado se rota foi adicionada/alterada.
- [ ] AsyncAPI atualizado se evento foi adicionado/alterado.

### 6. Artefatos ProdOps

- [ ] Architecture diagram atualizado (se mudança estrutural).
- [ ] Event Storming atualizado (se eventos novos).
- [ ] Release Trail com evidência desta implementação.

### 7. Definition of Done

- [ ] Todos os itens de [definition-of-done.md](../../../../../templates/engineering/definition-of-done.md) satisfeitos.

### Geração do Pull Request

```bash
# 1. Revise o template
cat prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md

# 2. Crie o PR usando gh CLI
gh pr create \
  --title "<type>(<scope>): <summary>" \
  --body-file prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md \
  --base main
```

---

## Bypass (emergência)

```bash
git commit --no-verify -m "chore: emergency fix"
git push --no-verify
```

Use apenas em emergências reais. Documente a justificativa no commit body ou no Decision Trail.

---

## Fases consumidoras

| Fase | Momento |
|---|---|
| Hack | Após cada ciclo Red→Green→Refactor |
| Sync | Após rebase/atualização de branch |
| Finish | Validação final antes do PR |
