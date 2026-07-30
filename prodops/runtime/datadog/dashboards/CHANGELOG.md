# Dashboard Changelog — ProdOps Runtime

## v3.0.0 — 2026-07-30

**Arquivo:** `v3.0.0.json` (gerado por `create-v3-dashboard.sh`)

**Layout:** 3 linhas, sem widget de texto de cabeçalho

**Linha 1 — KPIs:**
- Iteration Ativas (Bootstrap.Started count)
- DONE Concluídas (Promote.Completed count)
- Falhas / Bloqueios (Block.Declared count)
- Lead Time dias (`runtime.delivery.lead_time_days` gauge — emitido via `send.sh --lead-time-days`)

**Linha 2 — Jornadas:**
- Funil de Entrega por Stage (timeseries bars por `event` tag)
- Delivery Journey: 8 contadores por phase (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Done)
- Diligence Status: 4 contadores por phase (Capture, Attach, Promote, Close)

**Linha 3 — Exception Paths:**
- BLOQUEIO (Block.Declared), DRIFT (Divergence.Detected), REPAIR (Repair.Completed), CLOSED (Close.Completed)

**Métricas usadas:**
- `runtime.event.received` — eventos de Delivery (tag `event` = CE type)
- `runtime.diligence.event.received` — eventos de Diligence
- `runtime.delivery.lead_time_days` — gauge de lead time (emitido manualmente via `--lead-time-days`)

**Template variables:** `$service` (payments-api), `$env` (development)

---

## v2.0.0 — 2026-07-29

**Dashboard ID:** `d73-8be-pds`

Redesign que removeu dependência de `demo-run-id` e `live_span` fixo.
Tags corrigidas: `delivery-state`, `delivery-correlation-id`.

---

## v1.0.0 — 2026-07-28

**Dashboard ID:** `kij-n25-sui`

Dashboard inicial EXP-014 com `demo-run-id` como filtro obrigatório.
