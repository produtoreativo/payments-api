# Experiment Upstream Trail — 015 Delivery Skills as Event Producers

Referência:

`prodops/artifacts/experiments/015-delivery-skills-event-producers/experiment.md`

---

# History

---

## 2026-07-28

### Activity

Experimento concluído — Tool `prodops_emit_event` v1.0.0 validada com 22/22 conformance × 3 players.

### Summary

O EXP-015 produziu e validou:

- **Tool canônica `prodops_emit_event` v1.0.0** — interface única, player-neutral, 6-step pipeline
- **Catálogo de eventos** com 30+ eventos de Delivery e Diligence em `catalog/events.yaml`
- **Testes de conformance** — 22 cenários × claude, codex, copilot — todos PASS
- **Chain tests** — Happy Path completo (15 Delivery + 6 Diligence) com correlation-id único
- **Dispatcher integrado** como Step 6 — Diligence reativa sem acoplamento direto

### Artifacts Updated

- `prodops/runtime/tools/emit-event/scripts/emit-event` — v1.0.0 com 6 steps + dispatcher
- `prodops/runtime/catalog/events.yaml` — catálogo com 30+ eventos
- `prodops/runtime/subscriptions/delivery-diligence.yaml` — subscriptions declarativas
- `prodops/skills/prodops-emit-event/SKILL.md` — documentação da Tool para Skills
- `prodops/artifacts/experiments/015-delivery-skills-event-producers/experiment.md` — criado
- `prodops/artifacts/experiments/015-delivery-skills-event-producers/upstream-trail.md` — este arquivo

### Decision

Hipótese confirmada. A Tool `prodops_emit_event` é o contrato canônico. O padrão está disponível para todos os repositórios produto via o mecanismo de distribuição do Framework (DS-53/54/55/56 — v0.11.0).

### Notes

Bug corrigido durante EXP-015: `work-item-id: null` em plan-level events gerava `issue:null` no Datadog. Fix: guard `[[ "$WORK_ITEM_ID" == "null" ]]` → fallback para `plan-<iteration-id>`. Commit: `cd7e0c90`.
