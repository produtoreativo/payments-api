# Upstream Experiment 015 — Delivery Skills as Event Producers

Localização canônica:

```text
prodops/artifacts/experiments/015-delivery-skills-event-producers/experiment.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

**Data de conclusão:** 2026-07-28
**Branch:** `experiment/015-delivery-skills-event-producers`
**Conformance:** 22/22 × 3 players (claude, codex, copilot) — todos os chain scenarios PASS

---

# Business Goal

Validar que Delivery Skills podem atuar como produtoras de eventos operacionais via uma Tool canônica player-neutral (`prodops_emit_event`), com o Runtime processando CloudEvents 1.0 de forma desacoplada para sincronizar GitHub Project, Datadog e Diligence.

O objetivo é estabelecer o contrato de emissão de eventos que toda Skill deve seguir, independentemente do player (claude, codex, copilot) que executa a Skill.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Tool canônica `prodops_emit_event` (scripts/emit-event v1.0.0)
- [x] Catálogo de eventos (catalog/events.yaml) com 30+ eventos de Delivery e Diligence
- [x] Testes de conformance (22 cenários × 3 players)
- [x] Chain tests (full Delivery Journey + Diligence reativa)
- [x] Fix: guard string "null" work-item-id para plan-level events
- [x] Iteração v0.11.0 — DS-53/54/55/56 (framework distribution) entregue

---

# Hypothesis

**H1:** Uma Tool player-neutral pode encapsular toda a lógica de emissão de eventos, validação contra catálogo, idempotência e pipeline de 6 steps, sem que Skills precisem conhecer os detalhes.

**H2:** Skills de diferentes players (claude, codex, copilot) produzem eventos conformes ao mesmo schema CloudEvents 1.0 usando a mesma Tool.

**H3:** O pipeline de 6 steps é suficiente para sincronizar GitHub, Datadog e Diligence de forma desacoplada a partir de um único ponto de emissão.

---

# Outcome

Todas as hipóteses confirmadas. A Tool `prodops_emit_event` v1.0.0 é o contrato canônico de emissão de eventos para o ProdOps Framework. O padrão está documentado em `prodops/skills/prodops-emit-event/SKILL.md` e é referenciado por todas as Delivery Skills.

Bug identificado e corrigido durante o experimento: events plan-level com `work-item-id: null` geravam tag `issue:null` no Datadog — resolvido com guard no resolve-subject step do emit-event script.
