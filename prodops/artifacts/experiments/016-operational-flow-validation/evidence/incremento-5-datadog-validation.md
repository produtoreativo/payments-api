# EXP-016 — Incremento 5: Validação do Datadog

**Data:** 2026-07-29

---

## Dashboards Disponíveis

| Dashboard | URL | Origem |
|-----------|-----|--------|
| Operational | https://app.datadoghq.com/dashboard/jhq-ztv-3pv | EXP-014 |
| Executive Cockpit | https://app.datadoghq.com/dashboard/4rs-983-e35 | EXP-014 (Iteration 4b) |

---

## Métrica Enviada

**Métrica:** `runtime.event.received`  
**Tags por evento:**

```
service:payments-api
env:development
issue:<work-item-id>
event:<event-type>
state:<derived-state>
correlation-id:<uuid>
```

---

## Evidência de Sincronização

Todos os 21 eventos do flow EXP-016 retornaram `"datadog-sync": "success"`:

| Evento | State enviado |
|--------|--------------|
| Bootstrap.Started | BOOTSTRAPPING |
| Bootstrap.Completed | BOOTSTRAPPING |
| Diligence.Capture.Started | BOOTSTRAPPING |
| Diligence.Capture.Completed | BOOTSTRAPPING |
| Hack.Started | HACKING |
| Hack.Completed | HACKING |
| Sync.Started | SYNCING |
| Sync.Completed | SYNCING |
| Finish.Started | FINISHING |
| Finish.Completed | FINISHING |
| Ship.Started | SHIPPING |
| Ship.Completed | SHIPPING |
| Validate.Started | VALIDATING |
| Shared.Gate.Passed | VALIDATING |
| Validate.Completed | VALIDATING |
| Diligence.Attach.Started | VALIDATING |
| Diligence.Attach.Completed | VALIDATING |
| Promote.Started | PROMOTING |
| Promote.Completed | **DONE** |
| Diligence.Promote.Started | DONE |
| Diligence.Promote.Completed | DONE |

---

## Visualização no Datadog

Para observar os eventos na Metrics Explorer:

```
metric: runtime.event.received
filter: issue:76
group by: state
time: last 1 hour
```

Para o funil da Journey (série temporal):

```
metric: runtime.event.received
filter: event:prodops.delivery.*.completed
group by: event
```

---

## Dashboard Adequada para Demonstração

O Executive Cockpit (EXP-014 Iteration 4b) já contém:

- Features por estado (widget de distribuição)
- Funil da Delivery Journey (série temporal de eventos)
- Throughput (count de `promote.completed` por período)
- Diligence Status
- Timeline de eventos

**Não foram necessárias alterações** — o dashboard existente reflete diretamente os eventos emitidos pelo EXP-016.

---

**Resultado Incremento 5:** ✓ Datadog recebeu todos os 21 eventos com `datadog-sync: success`. Dashboard executiva adequada para demonstração.
