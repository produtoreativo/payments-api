# Experiment Upstream Trail — 016 Operational Flow Validation

Referência:

`prodops/artifacts/experiments/016-operational-flow-validation/experiment.md`

---

# History

---

## 2026-07-29

### Activity

Experimento concluído — Delivery Journey end-to-end validada com 9 incrementos, Features #76 e #78 completas, Restart Protocol implementado.

### Summary

O EXP-016 validou o fluxo operacional completo:

- **Features #76 + #78** percorreram a Journey completa: BOOTSTRAPPING → HACKING → SYNCING → FINISHING → SHIPPING → VALIDATING → DONE
- **GitHub Project** sincronizado automaticamente por evento — oem-state e oem-last-event atualizados em tempo real
- **Datadog** com métricas de lead-time calculadas (Bootstrap.Started → Promote.Completed)
- **Diligence reativa** — Diligence Skills acionadas automaticamente via subscriptions a cada evento de Delivery
- **Feature Restart Protocol** — re-execução com novo correlation-id, audit trail das execuções anteriores preservado
- **Plan Bootstrap → Plan Validated → Plan Closed** — lifecycle do Iteration Plan registrado com eventos corretos

### Artifacts Updated

- `prodops/artifacts/experiments/016-operational-flow-validation/experiment.md` — criado
- `prodops/artifacts/experiments/016-operational-flow-validation/upstream-trail.md` — este arquivo

### Decision

Fluxo operacional validado end-to-end. O ProdOps Runtime está pronto para uso em produção. Padrões de Restart, Plan Bootstrap e correlação Delivery-Diligence promovidos para o Framework.

### Notes

Executado na branch `experiment/015-delivery-skills-event-producers`. Features #76 e #78 usadas como casos de teste reais. 9 incrementos de validação progressiva.
