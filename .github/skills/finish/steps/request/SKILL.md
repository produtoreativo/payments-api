---
name: finish/request
description: Open the PR in auto-approval mode — filled from the PR template with evidence, with auto-merge configured so it merges on its own once CI passes. Use as the last Finish step, after validate is clean, review has no blockers, and the commits are pushed.
---

# FINISH → REQUEST

Execute apenas o step de abertura de PR do fluxo Finish.

**Responsabilidade:** abrir **um** Pull Request em modo auto aprovação — se todos
os checks do GitHub Actions passarem, o PR mergeia automaticamente sem
intervenção manual. É a única responsabilidade deste passo.

**Não é responsabilidade de `request`:** qualquer ação que não seja abrir o PR —
não valida (isso é `validate`), não inspeciona a pipeline (isso é `review`), não
faz push (isso é o passo `push origin`), não commita, não escreve/lê código.

## Pré-condições

Não abra o PR antes de:

- `validate` limpo (lint + build + aceitação quando aplicável).
- `review` sem bloqueadores (branch protection e checks obrigatórios presentes).
- Commits já publicados na branch de trabalho (o passo `push origin`) — na
  branch atual, nunca na branch de destino do PR.

Se algum não foi cumprido, pare e sinalize — abrir o PR com auto-merge sem esses
pré-requisitos pode mergear código sem gate.

## Inputs

- `prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md`
  — o template de PR a preencher
- O diff da branch e as evidências de `validate` (output de lint/build/aceitação,
  a cobertura da suíte de aceitação e o scan de dependências)
- A branch de destino (origem) confirmada por `review`
- O trail da sessão ativa em `prodops/artifacts/trails/sessions/`

## Action

### 1. Preencher o body com o template

Preencha o [template de PR](../../../../framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md)
com evidências reais — objetivo, resumo, contratos alterados, testes executados
(com o output de `validate`), artefatos ProdOps atualizados e pendências. Não é
um log de commits; é o que a mudança entrega e como foi verificada.

### 2. Ler os vereditos dos gates de auto-merge

Os três gates de auto-merge — `gates.coverage`, `gates.dependencies` e
`gates.code-analysis` — **rodam no `validate`**, que é o step de análise
estática. Aqui apenas se **lê o veredito** que o `validate` produziu nesta
sessão. Todos precisam ter liberado para o auto-merge ser armado; se **qualquer
um** não liberou, o auto-merge fica desarmado (o PR abre mesmo assim; ver passo 4).

**Não execute os scripts de gate aqui.** A responsabilidade deste step é abrir o
PR — rodar `check-coverage-threshold.sh`, `check-dependencies.sh` ou
`check-code-analysis.sh` seria executar análise de qualidade, que pertence ao
`validate`. Rodar a aceitação para regerar o XML de cobertura seria pior ainda:
análise dinâmica dentro do step de abertura de PR.

| Gate | Veredito esperado do `validate` |
|---|---|
| `gates.coverage` | cobertura de branches >= limiar (hoje 100%) |
| `gates.dependencies` | sem vulnerabilidades >= high |
| `gates.code-analysis` | quality gate do SonarQube verde |

Para cada um, o `validate` reporta liberado, bloqueado, ou **não pôde rodar**
(sem `SNYK_TOKEN`, sem Docker, XML ausente). Os dois últimos contam igual aqui:
**não liberado** — mantenha o auto-merge desarmado e registre o motivo.

**Se não houver veredito do `validate` nesta sessão** — porque o `request` foi
invocado isoladamente, ou o `validate` rodou em outro HEAD — trate os três gates
como **não liberados**. Não tente recuperá-los: abra o PR sem armar o auto-merge
e registre que os gates não foram verificados neste fluxo. Reexecutar o
`validate` é o caminho para armá-lo.

### 3. Abrir o PR

Primeiro verifique se **já existe** um PR aberto para esta branch — o passo é
idempotente: rodá-lo de novo (porque um gate não liberou, ou por reexecução do
Finish) não deve criar um segundo PR.

```bash
gh pr list --head "$(git branch --show-current)" --state open
```

Se **já houver** um PR, opere sobre ele (passos 4 e 5 atualizam aquele PR) — não
crie outro. Só se **não houver** nenhum:

```bash
gh pr create --base <branch-de-destino> --fill-first --body-file <arquivo>
```

O PR é aberto **sempre** — independente do resultado do passo 2. Os gates de
auto-merge não são condição para abrir o PR nem para mergear; são condição
apenas para **automatizar** o merge.

### 4. Armar o auto-merge — somente se todos os gates do passo 2 liberaram

```bash
# apenas quando o `validate` reportou os três gates liberados
# (gates.coverage, gates.dependencies E gates.code-analysis)
gh pr merge --auto --squash
```

`--auto` arma o merge: o PR só mergeia quando todos os checks obrigatórios
ficam verdes. `--squash` mantém o histórico linear na branch de destino,
coerente com o fluxo do repositório.

**Se qualquer gate do passo 2 não liberou** (cobertura abaixo do limiar,
vulnerabilidade >= high, quality gate do SonarQube vermelho, ou um gate que não pôde
rodar por falta de `SNYK_TOKEN`/Docker), não execute `gh pr merge --auto`. Em vez
disso, registre no PR o motivo — específico ao gate que barrou:

```bash
gh pr comment <n> --body "Auto-merge não armado: <motivo>. O merge manual segue
disponível após review."
# <motivo>, ex.:
#   cobertura de branches abaixo do limiar de 100% (gates.coverage)
#   vulnerabilidades de severidade >= high nas dependências (gates.dependencies)
#   SNYK_TOKEN ausente — gate de dependências não pôde rodar (gates.dependencies)
#   quality gate do SonarQube vermelho em api/src (gates.code-analysis)
#   Docker indisponível — gate de análise de código não pôde rodar (gates.code-analysis)
```

O PR fica aberto, verde e **mergeável à mão** por um humano. Os gates governam
apenas a automação — nunca a capacidade de mergear. Por isso `gates.coverage`,
`gates.dependencies` e `gates.code-analysis` **não** são required status checks: como
required checks bloqueariam também o merge manual, que é justamente o que se
quer preservar.

### 5. Atualizar o Release Trail

Registre o link do PR no trail da sessão ativa
(`prodops/artifacts/trails/sessions/`), fechando o loop do Finish.

## Critério

Concluído quando: o PR está aberto contra a branch de destino correta, o body
segue o template preenchido com evidências, o auto-merge está armado
(`--auto --squash`) **quando todos os gates de auto-merge do passo 2 liberaram**
— ou deliberadamente não armado, com o motivo registrado no PR, quando algum não
liberou — e o Release Trail tem o link do PR. Exatamente **um** PR para a branch:
antes de criar, `gh pr list --head <branch>` confirma que não há outro aberto.

## Guardrails

- Não abrir o PR sem `validate` limpo e `review` sem bloqueadores.
- Não abrir PR com auto-merge quando a branch protection não está configurada
  (o `review` já teria sinalizado — respeite o bloqueador).
- Não armar o auto-merge quando um gate do passo 2 não liberou (cobertura abaixo
  do limiar, vulnerabilidade >= high, quality gate do SonarQube vermelho, ou um
  gate que não pôde rodar) — e não deixar de abrir o PR por causa disso: isso
  desarma a automação, não o PR.
- Não transformar `gates.coverage`, `gates.dependencies` ou `gates.code-analysis` em
  required status check: isso bloquearia o merge manual, contrariando o
  propósito do gate.
- Não fazer push, não commitar, não validar aqui — apenas abrir o PR.
- Não abrir PRs duplicados: rode `gh pr list --head <branch>` antes de criar; se
  já houver um PR aberto para a branch, opere sobre ele. Um Finish abre um PR.
