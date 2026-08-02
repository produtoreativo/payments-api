# Iteration Plan — v0.10.0

> Status: ✅ Concluído — 2026-08-02

## Objetivo

Fechar o ciclo do produto de pagamentos com o cancelamento de invoice, e eliminar o último alerta HIGH de segurança Dependabot no repositório (postcss em validation-workbench/).

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-51 | #47 | cancel-invoice: cancelar invoice pendente com idempotência | — | ✓ | ✓ | ✓ | Concluído | #125 |
| DS-52 | #117 | postcss-security: resolver vulnerabilidade HIGH do postcss em validation-workbench/ | — | ✓ | ✓ | ✓ | Concluído | #126 |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.10.0 |
|---|---|---|
| DS-51 | cancel-invoice | #47 |
| DS-52 | postcss-security | #117 |

## Critérios de saída

- [x] PR merged em `master` para DS-51 (cancel-invoice) — PR #125
- [x] PR merged em `master` para DS-52 (postcss-security) — PR #126
- [x] `prodops.delivery.promote.completed` emitido para cada issue
- [x] Alerta Dependabot #101 fechado após merge de DS-52 — estado: fixed
- [x] Issues #47 e #117 fechadas no GitHub

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.10.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
