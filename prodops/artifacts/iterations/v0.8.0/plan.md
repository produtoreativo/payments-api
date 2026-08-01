# Iteration Plan — v0.8.0

> Status: ⏸ Suspenso — gates OBC/BDD/Risks ausentes para capabilities de infraestrutura ProdOps. Retomar quando artefatos forem criados ou gate for ajustado para itens infra.

## Objetivo

Corrigir inconsistências e lacunas na infraestrutura do ProdOps runtime: path de timelines, ciclo de vida de delivery e modelo de resultado de gate. Esta iteração não entrega produto — entrega confiabilidade e rastreabilidade do próprio framework de delivery.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-45 | #119 | timeline-iteration-scope: corrigir propagação de `--iteration-id` ao `append.sh` | — | — | — | — | Entrou | — |
| DS-46 | #88 | runtime-lifecycle-protocol: definir política para Promote.Completed prematuro e reconciliar oem-state | — | — | — | — | Entrou | — |
| DS-47 | #83 | gate-result-model: definir modelo canônico de resultado de gate (pass/fail/na + severity + evento NotApplicable) | — | — | — | — | Entrou | — |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.8.0 |
|---|---|---|
| DS-45 | timeline-iteration-scope | #119 |
| DS-46 | runtime-lifecycle-protocol | #88 |
| DS-47 | gate-result-model | #83 |

## Critérios de saída

- [ ] DS-45: timelines gravadas em `prodops/artifacts/iterations/<id>/runtime/timelines/<issue>.json` — path legado não recebe novas entradas
- [ ] DS-45: métrica `runtime.delivery.lead_time_days` enviada ao Datadog no Promote.Completed
- [ ] DS-46: política documentada para Promote.Completed prematuro; oem-state de v0.2.0 (PR #87) reconciliado
- [ ] DS-47: modelo de gate result definido com suporte a `na` + severity; evento `Delivery.Gate.NotApplicable` especificado
- [ ] Todos os PRs mergeados em `master`
- [ ] Issues #119, #88 e #83 fechadas no GitHub

## Backlog de refinamento de fases (não escopado nesta iteração)

Issues de refinamento de skill abertas — candidatos para v0.9.0 ou iteração dedicada:

| Issue | Título | Fase |
|---|---|---|
| #8 | refine(bootstrap): sandbox local como pré-condição de desenvolvimento | Bootstrap |
| #9 | refine(hack): decomposição em steps independentes com quality gates por ciclo | Hack |
| #10 | refine(sync): rebase como integridade do repo, align como integridade dos artefatos | Sync |
| #11 | refine(finish): validação local com rigor de pipeline, push, PR e auto-merge via CI | Finish |
| #31 | /hack start | Hack |
| #32 | /hack tdd | Hack |
| #33 | /hack commit | Hack |

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.8.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
