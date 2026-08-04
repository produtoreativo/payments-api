# Upstream Experiment 016 — Operational Flow Validation

Localização canônica:

```text
prodops/artifacts/experiments/016-operational-flow-validation/experiment.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

**Data de conclusão:** 2026-07-29
**Branch:** `experiment/015-delivery-skills-event-producers`
**Resultado:** 9 incrementos — Features #76 + #78 com Journey completa, Feature Restart implementado

---

# Business Goal

Validar que uma Feature percorre toda a Delivery Journey em tempo real — Skills emitem CloudEvents, GitHub Project é movimentado automaticamente, Datadog reflete o estado operacional, e Diligence reage de forma reativa.

O pagamentos-api é o produto de referência. O objetivo é demonstrar o fluxo operacional completo em condições reais, incluindo o protocolo de Restart para re-execução de phases sem perda de audit trail.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Delivery Journey end-to-end com Skills player-neutral
- [x] Feature Restart Protocol — re-emissão com novo correlation-id preservando audit trail
- [x] GitHub Project automaticamente sincronizado por evento (oem-state, oem-last-event)
- [x] Datadog refletindo BOOTSTRAPPING → DONE com lead-time calculado
- [x] Diligence reativa via subscriptions declarativas

---

# Hypothesis

**H1:** Uma Feature real percorre os 7 estados (BOOTSTRAPPING → HACKING → SYNCING → FINISHING → SHIPPING → VALIDATING → DONE) sem intervenção manual no GitHub Project ou Datadog.

**H2:** O protocolo de Restart permite re-execução de uma phase com novo correlation-id preservando o audit trail das execuções anteriores.

---

# Outcome

Ambas as hipóteses confirmadas. Features #76 e #78 percorreram a Journey completa. O Restart Protocol foi validado com nova correlation-id e trail preservado. O fluxo operacional está pronto para uso em Iterations reais.
