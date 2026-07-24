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
- Commits já publicados na branch de origem (o passo `push origin`).

Se algum não foi cumprido, pare e sinalize — abrir o PR com auto-merge sem esses
pré-requisitos pode mergear código sem gate.

## Inputs

- `prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md`
  — o template de PR a preencher
- O diff da branch e as evidências de `validate` (output de lint/build/aceitação
  e a cobertura da suíte de aceitação)
- A branch de destino (origem) confirmada por `review`
- O trail da sessão ativa em `prodops/artifacts/trails/sessions/`

## Action

### 1. Preencher o body com o template

Preencha o [template de PR](../../../../framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md)
com evidências reais — objetivo, resumo, contratos alterados, testes executados
(com o output de `validate`), artefatos ProdOps atualizados e pendências. Não é
um log de commits; é o que a mudança entrega e como foi verificada.

### 2. Verificar o limiar de cobertura (gate de auto-merge)

Antes de armar o auto-merge, verifique a cobertura contra o limiar canônico
(`gates.coverage` no manifest — hoje **100% de branches**):

```bash
./scripts/check-coverage-threshold.sh
```

O script consome o XML gerado pelo gate `acceptance`, então rode-o depois de
`validate`. Exit 0 libera o auto-merge; exit 1 o **bloqueia**.

### 3. Abrir o PR

```bash
gh pr create --base <branch-de-destino> --fill-first --body-file <arquivo>
```

O PR é aberto **sempre** — independente do resultado do passo 2. A cobertura
não é condição para abrir o PR nem para mergear; é condição apenas para
**automatizar** o merge.

### 4. Armar o auto-merge — somente se a cobertura passou

```bash
# apenas quando ./scripts/check-coverage-threshold.sh saiu 0
gh pr merge --auto --squash
```

`--auto` arma o merge: o PR só mergeia quando todos os checks obrigatórios
ficam verdes. `--squash` mantém o histórico linear na branch de destino,
coerente com o fluxo do repositório.

**Se a cobertura ficou abaixo do limiar**, não execute `gh pr merge --auto`.
Em vez disso, registre no PR por que o auto-merge não foi armado:

```bash
gh pr comment <n> --body "Auto-merge não armado: cobertura de branches abaixo
do limiar de 100% (gates.coverage). O merge manual segue disponível após review."
```

O PR fica aberto, verde e **mergeável à mão** por um humano. O limiar governa
apenas a automação — nunca a capacidade de mergear. Por isso `gates.coverage`
**não** é um required status check: como required check ele bloquearia também o
merge manual, que é justamente o que se quer preservar.

### 5. Atualizar o Release Trail

Registre o link do PR no trail da sessão ativa
(`prodops/artifacts/trails/sessions/`), fechando o loop do Finish.

## Critério

Concluído quando: o PR está aberto contra a branch de destino correta, o body
segue o template preenchido com evidências, o auto-merge está armado
(`--auto --squash`) **quando o gate de cobertura passou** — ou deliberadamente
não armado, com o motivo registrado no PR, quando não passou — e o Release Trail
tem o link do PR. Um único PR — não abrir duplicados.

## Guardrails

- Não abrir o PR sem `validate` limpo e `review` sem bloqueadores.
- Não abrir PR com auto-merge quando a branch protection não está configurada
  (o `review` já teria sinalizado — respeite o bloqueador).
- Não armar o auto-merge com a cobertura abaixo do limiar — e não deixar de
  abrir o PR por causa disso: cobertura baixa desarma a automação, não o PR.
- Não transformar `gates.coverage` em required status check: isso bloquearia o
  merge manual, contrariando o propósito do gate.
- Não fazer push, não commitar, não validar aqui — apenas abrir o PR.
- Não abrir PRs duplicados; um Finish abre um PR.
