# Iteration Plan — v0.10.0

> Status: 🟡 Em andamento — aberta em 2026-08-01

## Objetivo

Fechar o ciclo do produto de pagamentos com o cancelamento de invoice, e eliminar o último alerta HIGH de segurança Dependabot no repositório (postcss em validation-workbench/).

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-51 | #47 | cancel-invoice: cancelar invoice pendente com idempotência | — | ✓ | ✓ | ✓ | Entrou | — |
| DS-52 | #117 | postcss-security: resolver vulnerabilidade HIGH do postcss em validation-workbench/ | — | ✓ | ✓ | ✓ | Entrou | — |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.10.0 |
|---|---|---|
| DS-51 | cancel-invoice | #47 |
| DS-52 | postcss-security | #117 |

## Critérios de saída

- [ ] PR merged em `master` para DS-51 (cancel-invoice)
- [ ] PR merged em `master` para DS-52 (postcss-security)
- [ ] `prodops.delivery.promote.completed` emitido para cada issue
- [ ] Alerta Dependabot #101 fechado após merge de DS-52
- [ ] Issues #47 e #117 fechadas no GitHub

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.10.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
