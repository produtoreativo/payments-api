---
name: finish/review
description: Inspect the pipeline and confirm the rules for a safe automatic PR are valid — without running the pipeline. Use before enabling auto-approval, to catch a missing branch-protection condition as a blocker instead of after merge.
---

# FINISH → REVIEW

Execute apenas o step de inspeção da pipeline do fluxo Finish.

**Responsabilidade:** garantir que as **regras para um PR automático estão
válidas** — que as condições para auto aprovação segura estão presentes no
repositório. É um passo de **inspeção**, não de execução: não roda a pipeline,
apenas confere se ela e a branch protection estão configuradas para que um PR
com todos os checks verdes possa mergear sozinho com segurança.

**Não é responsabilidade de `review`:** executar pipelines; commitar; escrever
ou ler código de produto; ter escrita em artefatos que não sejam de GitHub
Actions; fazer push; abrir o PR (isso é `request`).

## Inputs

- `.github/workflows/pr-gates.yml` — os checks que a pipeline expõe como gate
- `prodops/journeys/delivery/phases/finish/quality-gates.md` — condições de
  branch protection para auto aprovação segura
- `prodops/exec/manifest.yaml` — os gates canônicos que os checks devem espelhar
- A branch de destino do PR (a branch de origem da branch atual)

## Action

Confirme, sem executar a pipeline, que **todas** as condições abaixo estão
presentes. Inspecione via `gh` e leitura de config — não dispare workflows.

### 1. A pipeline expõe os gates obrigatórios como status checks

Os jobs do `pr-gates.yml` devem cobrir lint, teste (aceitação) e build — os
mesmos gates do `manifest.yaml`. Liste os checks que o GitHub conhece para a
branch:

```bash
gh api "repos/{owner}/{repo}/commits/$(git rev-parse HEAD)/check-runs" \
  --jq '.check_runs[].name'
```

- [ ] `lint`, `acceptance` e `build` aparecem como checks.

### 2. Branch protection na branch de destino exige os checks

A branch de destino (origem) deve **requerer** que esses checks passem antes do
merge — senão o auto-merge do `request` mergearia sem gate:

```bash
gh api "repos/{owner}/{repo}/branches/<branch-de-destino>/protection" \
  --jq '.required_status_checks.contexts'
```

- [ ] Branch protection exige todos os checks obrigatórios passando.

### 3. Nenhum reviewer obrigatório bloqueia o auto-merge

Um reviewer humano obrigatório impede o merge automático de um PR com checks
verdes. Confirme que não há review obrigatório, ou que um bot auto-aprova:

```bash
gh api "repos/{owner}/{repo}/branches/<branch-de-destino>/protection" \
  --jq '.required_pull_request_reviews'
```

- [ ] Nenhum reviewer obrigatório para PRs com todos os checks verdes (ou
      reviewer auto-aprovado por bot).

## Critério

Cada condição ausente é um **bloqueador**: registre-o no Finish antes de ativar
auto aprovação e **não avance para o push/request** com auto-merge até resolvê-lo.
Ativar auto-merge sem branch protection configurada mergearia código sem gate —
o oposto do que o Finish protege.

Se as condições de branch protection não puderem ser lidas (permissão
insuficiente) ou não estiverem configuradas, trate como bloqueador explícito, não
como "provavelmente ok".

## Guardrails

- Não executar pipelines — apenas inspecionar configuração.
- Não commitar, não escrever/ler código de produto, não fazer push, não abrir PR.
- Não ativar auto aprovação enquanto a branch protection não estiver configurada.
- Não presumir que um check ausente está "ok"; condição ausente é bloqueador.
