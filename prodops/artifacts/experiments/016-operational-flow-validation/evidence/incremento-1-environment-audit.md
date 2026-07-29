# EXP-016 — Incremento 1: Auditoria de Ambiente

**Data:** 2026-07-29

---

## prepare-demo.sh

```
Total checks — PASS: 24 | WARN: 1 | FAIL: 0
Result: READY WITH WARNINGS
```

**WARN:** View "02 — Iteration Plan" not found by name (view existe com nome ligeiramente diferente no projeto).

---

## GitHub Project — Views existentes (project #25)

| # | Nome | Layout | Serve para EXP-016 |
|---|------|--------|-------------------|
| 2 | 01 — Delivery Timeline | BOARD | ✓ Delivery Board / Delivery Timeline |
| 4 | 03 — Diligence Tracking | BOARD | ✓ Diligence Board |
| 5 | 04 — Runtime Reconciliation | TABLE | ✓ referência runtime |
| 7 | 02 - Iteration Plan | BOARD | ✓ contexto do plano |

**Views necessárias para EXP-016 não existentes:**

| View | Status |
|------|--------|
| Delivery Board | ✓ coberta por "01 — Delivery Timeline" |
| Delivery Timeline | ✓ coberta por "01 — Delivery Timeline" |
| Diligence Board | ✓ coberta por "03 — Diligence Tracking" |
| Active Features | ✗ ausente — criar |
| Executive Overview | ✗ ausente — criar |

---

## GitHub Project — Feature Issues

| Issue | Feature | oem-state atual | Candidata para EXP-016 |
|-------|---------|----------------|------------------------|
| #76 | FTR-001: Invoice PIX — Happy Path | BOOTSTRAPPING | ✓ selecionada |
| #77 | FTR-002: Invoice Cartão | VALIDATING | Parcialmente executada |
| #78 | FTR-003: Confirmação de Pagamento | HACKING | Parcialmente executada |
| #79 | FTR-004: Split Payment — Conflito | — | Disponível |
| #80 | FTR-005: Split Payment Reversal | — | Disponível |
| #81 | FTR-006: Split Payment Settlement | — | Disponível |

**Seleção:** Issue #76 (FTR-001) — nova execução com novo `correlation-id`, percorrendo Bootstrap → Promote completo.

---

## Datadog — Dashboards

| Dashboard | URL | Status |
|-----------|-----|--------|
| Operational | https://app.datadoghq.com/dashboard/jhq-ztv-3pv | Existente (EXP-014) |
| Executive Cockpit | https://app.datadoghq.com/dashboard/4rs-983-e35 | Existente (EXP-014) |

---

## Gap Summary

| Gap | Ação |
|-----|------|
| Views "Active Features" e "Executive Overview" ausentes | Criar via REST — Incremento 2 |
| Feature com journey completa | Executar #76 via run-chain.sh — Incremento 3 |
| Validate-demo.sh aponta para EXP-014 | Usar como referência; criar validação EXP-016 — Incremento 6 |

**Resultado Incremento 1:** ✓ Ambiente pronto. 2 views a criar.
