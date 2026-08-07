# Iteration Plan — v0.15.0

> Status: Em execução — aberta em 2026-08-07

## Objetivo

Refinar a fase Finish do Delivery Journey: decompor o passo monolítico em sub-steps auditáveis (`validate`, `review`, `request`) e instalar os gates de qualidade que faltavam — cobertura, dependências e análise estática de código. Esta iteração não entrega produto — entrega rigor e auditabilidade ao próprio fluxo de encerramento técnico, no mesmo molde de v0.8.0 e v0.11.0.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-62 | #11 | finish-substeps: decompor Finish em `validate`, `review`, `request` com fronteira explícita por step | — | n/a | n/a | n/a | Em execução | — |
| DS-63 | #11 | finish-quality-gates: gates `coverage`, `dependencies` e `code-analysis` como `blocks: auto_merge_only` | DS-62 | n/a | n/a | n/a | Em execução | — |
| DS-64 | #11 | commit-workflow-rules: subject completo em 72 caracteres, scope-case e ponto final | — | n/a | n/a | n/a | Em execução | — |

> **OBC/BDD/Risco marcados `n/a`.** Trabalho de infraestrutura ProdOps não tem
> OBC de produto nem cenário BDD executável. Mesma lacuna que suspendeu a
> v0.8.0 ("gates OBC/BDD/Risks ausentes para infraestrutura ProdOps") —
> registrada em `prodops/framework/framework-gaps.md`, não resolvida aqui.

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.15.0 |
|---|---|---|
| DS-62 | finish-substeps | #11 |
| DS-63 | finish-quality-gates | #11 |
| DS-64 | commit-workflow-rules | #11 |

> Os três DS compartilham a issue #11: o refino foi especificado como uma única
> issue guarda-chuva antes de existir a decomposição em DS. Diferente de
> v0.11.0, onde cada DS tinha issue própria.

## Sequência de entrega

DS-62 → DS-63 (os gates dependem da fronteira dos steps) · DS-64 independente.

## Critérios de saída

- [x] Finish decomposto em `validate`, `review`, `request` — cada um com seção "não faz"
- [x] Artefatos da fase criados: `README`, `done-criteria`, `quality-gates`
- [x] Gate `coverage` — `scripts/check-coverage-threshold.sh`, branches ≥ 100%
- [x] Gate `dependencies` — `scripts/check-dependencies.sh`, Snyk severidade ≥ high
- [x] Gate `code-analysis` — `scripts/check-code-analysis.sh`, SonarQube local
- [x] `commit-msg.sh` medindo o subject inteiro, com scope-case e ponto final
- [x] Os três gates executados de ponta a ponta ao menos uma vez
- [ ] PR aberto para a issue #11
- [ ] Issue #11 fechada no GitHub
- [ ] `prodops.delivery.promote.completed` emitido para a issue #11

### Bloqueadores conhecidos

Ambos exigem `admin` no repositório — herdados do trail `4a9e4c58`:

1. **Sem `required_status_checks` na `master`.** O step `review` trata branch
   protection ausente como bloqueador, o que impede `request` de abrir o PR.
2. **`SNYK_TOKEN` não cadastrado.** O gate `dependencies` sai com exit 2 em
   qualquer ambiente enquanto o secret não existir.

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.15.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `prodops/artifacts/trails/sessions/` — trail `4a9e4c58`
  (modelo vigente é por sessão, não por iteração; ver `trails/release-trail.md`)
