# Finish → Request

Read `prodops/skills/finish/steps/request/SKILL.md` and execute the Request step.

**Objetivo do step:** abrir **um** Pull Request em modo auto aprovação — se todos os checks do GitHub Actions passarem, o PR mergeia automaticamente sem intervenção manual. É a única responsabilidade deste passo.

**Pré-condições (não abra o PR sem elas):** `validate` limpo, `review` sem bloqueadores, commits já publicados na branch de origem (o passo `push origin`). Abrir o PR com auto-merge sem esses pré-requisitos pode mergear código sem gate.

**Ação:** preencher o body com o [template de PR](../../prodops/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md) e evidências reais (output de `validate`, contratos alterados, artefatos ProdOps atualizados); abrir o PR contra a branch de destino confirmada por `review`; armar o auto-merge com `gh pr merge --auto --squash`; registrar o link do PR no Release Trail (trail da sessão ativa em `prodops/artifacts/trails/sessions/`).

**Critério de conclusão:** um único PR aberto contra a branch de destino correta, body segundo o template com evidências, auto-merge armado, Release Trail com o link do PR.

**Fora do escopo:** qualquer ação que não seja abrir o PR — não valida (`validate`), não inspeciona a pipeline (`review`), não faz push (`push origin`), não commita, não escreve/lê código. Não abrir PRs duplicados.

Execute apenas o step `request`. Importe o contexto de `AGENTS.md` e `prodops/journeys/delivery/phases/finish/README.md` quando houver dúvida sobre fronteira.
