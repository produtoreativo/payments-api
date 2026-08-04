# Experiment Upstream Trail — 014 Diligence Tracks Delivery

Referência:

`prodops/artifacts/experiments/014-diligence-tracks-delivery/experiment.md`

---

# History

---

## 2026-07-27

### Activity

Experimento concluído — Diligence reativa a eventos de Delivery validada com 53/53 PASS em todas as iterações.

### Summary

O EXP-014 validou o modelo de integração Delivery-Diligence via dispatcher reativo:

- **Dispatcher como Step 6** do pipeline `emit-event` — lê `delivery-diligence.yaml` e dispara Diligence Skills sem acoplamento direto
- **21 eventos por flow** — 15 Delivery + 6 Diligence com correlation-id único
- **Diligence Capture** disparada automaticamente ao `Plan.Bootstrap.Issue.Entered`
- **Diligence Trail** atualizado em cada fase (Bootstrap, Hack, Finish, Ship, Validate, Promote)
- **GitHub Project** com `diligence-status` e `diligence-evidence` sincronizados por evento
- **Subscriptions declarativas** em `delivery-diligence.yaml` — sem hardcode em Delivery Skills

### Artifacts Updated

- `prodops/runtime/dispatcher/dispatch.sh` — implementado
- `prodops/runtime/subscriptions/delivery-diligence.yaml` — criado
- `prodops/runtime/tools/emit-event/scripts/emit-event` — Step 6 (dispatcher) integrado
- `prodops/artifacts/experiments/014-diligence-tracks-delivery/experiment.md` — criado
- `prodops/artifacts/experiments/014-diligence-tracks-delivery/upstream-trail.md` — este arquivo

### Decision

Hipótese confirmada. O modelo de subscriptions declarativas é o mecanismo canônico de integração Delivery-Diligence. Padrão promovido para o Framework.

### Notes

Execuções: 6 iterações (1, 2, 3, 4, 4b, 5) com demo-run-id `exp-014-demo-2026-07-27-1959`. Todos os 53 cenários PASS.
