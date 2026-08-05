# Iteration Plan — v0.13.0

> Status: Concluído — 2026-08-04

## Objetivo

Entregar Split Payment Pix + Boleto como nova capacidade da payments-api, viabilizando o lançamento com fornecedor parceiro da Magazine Siará dentro do prazo de 15 dias (prazo: 2026-08-19).

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-61 | #160 | split-payment-pix-boleto: Split Payment criação, confirmação Pix+Boleto, expiração Boleto, idempotência, eventos observáveis | — | ✓ | ✓ | ✓ | Concluído | #162 |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.13.0 |
|---|---|---|
| DS-61 | split-payment-pix-boleto | #160 |

## Sequência de entrega

DS-61 — entrega única (capability autossuficiente)

## Gates de entrada

| DS | OBC | BDD Feature | Owner Approval |
|---|---|---|---|
| DS-61 | [split-payment-pix-boleto.md](../../../obcs/split-payment-pix-boleto.md) | [split-payment-pix-boleto.feature](../../../bdd/split-payment-pix-boleto.feature) | ✅ Eugenio (PM) — 2026-08-04 |

## Critérios de saída

- [x] PR merged para DS-61 — Split Payment criado, confirmações Pix+Boleto funcionando, expiração Boleto, idempotência e eventos observáveis implementados (#160) → PR #162 merged
- [x] `prodops.delivery.promote.completed` emitido para issue #160 — evento ed86c1f6, oem-state: DONE
- [x] Issue #160 fechada no GitHub — CLOSED
- [x] Eventos `split_payment.created`, `split_payment.pix.confirmed`, `split_payment.boleto.confirmed`, `split_payment.completed`, `split_payment.boleto.expired`, `split_payment.creation_failed` presentes nos logs de aceitação — cobertos por 9 cenários de aceitação

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.13.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`

## Notas de encerramento

- Experiment Sandbox Deploy falhou por secrets ausentes (`EXPERIMENT_ASAAS_TOKEN`, `EXPERIMENT_ASAAS_WEBHOOK_TOKEN`, `EXPERIMENT_ADMIN_SECRET`) — não aplicável a DS delivery; Staging deploy (run #30964992611) confirmado como RC. Follow-up criado.
- RISK-SP-005 (times adjacentes sem contrato da API) — follow-up criado para garantir acesso ao Response Contract.
- Build blocker (TS1272 — CreateSplitPaymentDto como interface) detectado pelo finish-agent e corrigido na mesma sessão (commit ca4198f1).
