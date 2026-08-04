# Upstream Experiment 014 — Diligence Tracks Delivery

Localização canônica:

```text
prodops/artifacts/experiments/014-diligence-tracks-delivery/experiment.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

**Data de conclusão:** 2026-07-27
**demo-run-id:** `exp-014-demo-2026-07-27-1959`
**Todas as execuções:** 53/53 PASS

---

# Business Goal

Demonstrar que o ProdOps Runtime rastreia automaticamente o estado de Delivery de cada Feature (via CloudEvents) e que a Diligence captura e anexa as evidências operacionais ao mesmo Work Item, mantendo GitHub Project e Datadog sincronizados em tempo real.

O payments-api é o produto de referência. O objetivo é validar que Diligence reage a eventos de Delivery sem acoplamento direto — via subscriptions declarativas no `delivery-diligence.yaml`.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Runtime pipeline (emit-event → timeline → derive-state → Datadog → GitHub → dispatcher)
- [x] Diligence Skills como assinantes de eventos de Delivery
- [x] Subscriptions declarativas em `delivery-diligence.yaml`
- [x] GitHub Project sincronizado com oem-state e diligence-status
- [x] Datadog com métricas de Delivery e Diligence correlacionadas

---

# Hypothesis

**H1:** A Diligence Journey pode rastrear o ciclo de Delivery de cada Feature de forma reativa e desacoplada, usando apenas o dispatcher de eventos como mecanismo de integração.

**H2:** O GitHub Project reflete o estado de Delivery e Diligence em tempo real, sem escritas diretas da Diligence nos campos de Delivery.

---

# Outcome

Hipótese confirmada. O pipeline de 6 steps (emit → timeline → derive-state → datadog → github → dispatcher) integra Delivery e Diligence de forma desacoplada. O dispatcher lê `delivery-diligence.yaml` e dispara Diligence Skills sem que Delivery Skills conheçam Diligence.

Flow completo validado: 21 eventos (15 Delivery + 6 Diligence) com correlation-id único por flow.
