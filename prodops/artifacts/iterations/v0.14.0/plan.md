# Iteration Plan — v0.14.0

> Status: Entrou — 2026-08-05

## Objetivo

Revisão formal de entrega de Split Payment Pix + Boleto (PI-001). A iteração v0.13.0 (PR #162) executou o ciclo completo do framework e validou a capability. Esta iteração retoma o ciclo formal de produto sobre os mesmos artefatos.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-61 | #167 | split-payment-pix-boleto: Split Payment criação, confirmação Pix+Boleto, expiração Boleto, idempotência, eventos observáveis | — | ✓ | ✓ | ✓ | Entrou | — |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.14.0 |
|---|---|---|
| DS-61 | split-payment-pix-boleto | #167 |

## Sequência de entrega

DS-61 — entrega única (capability autossuficiente)

## Gates de entrada

| DS | OBC | BDD Feature | Owner Approval |
|---|---|---|---|
| DS-61 | [split-payment-pix-boleto.md](../../../obcs/split-payment-pix-boleto.md) | [split-payment-pix-boleto.feature](../../../bdd/split-payment-pix-boleto.feature) | ✅ Eugenio (PM) — 2026-08-04 |

## Critérios de saída

- [ ] PR merged para DS-61 — Split Payment criado, confirmações Pix+Boleto funcionando, expiração Boleto, idempotência e eventos observáveis implementados
- [ ] `prodops.delivery.promote.completed` emitido para a issue DS-61 — oem-state: DONE
- [ ] Issue DS-61 fechada no GitHub
- [ ] Eventos `split_payment.created`, `split_payment.pix.confirmed`, `split_payment.boleto.confirmed`, `split_payment.completed`, `split_payment.boleto.expired`, `split_payment.creation_failed` presentes nos logs de aceitação

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.14.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`

## Precedência

- Predecessor: [v0.13.0](../v0.13.0/plan.md) — mesma capability; histórico de execução e PR #162 preservados
- Issues em aberto herdadas:
  - #163 — EXPERIMENT secrets (`EXPERIMENT_ASAAS_TOKEN`, `EXPERIMENT_ASAAS_WEBHOOK_TOKEN`, `EXPERIMENT_ADMIN_SECRET`) ausentes no GitHub Environment
  - #164 — RISK-SP-005: Response Contract Split Payment não compartilhado com Checkout e Notification
