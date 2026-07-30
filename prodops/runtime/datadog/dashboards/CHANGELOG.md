# Dashboard Changelog — ProdOps Runtime

## v3.2.0 — 2026-07-30

**Dashboard ID:** `3x5-6dn-9k4`

**Arquivo:** `v3.2.0.json`

**Correção:** todos os widgets reescalados para h=6 (≈90px). Anteriormente h=3 (~45px) não permitia que query_value renderizasse título + número sem compressão visual.

**Heights v3.2.0:**
- KPIs: h=6
- Delivery phases: h=6 por phase
- Funil: h=14 (label h=2 + row1 h=6 + row2 h=6)
- Diligence phases: h=6 (+ label h=2)
- Exception phases: h=6 (+ label h=2)
- Total altura: y=0..36 (≈540px)

---

## v3.1.0 — 2026-07-30

**Dashboard ID:** `g6i-3sn-wbx`

**Arquivo:** `v3.1.0.json` (gerado por `create-v3-dashboard.sh`)

**Layout:** free, 4 linhas, 24 widgets — sem widget de cabeçalho de texto

**Linha 1 — KPIs (y=0, h=3):** 4 × w=3
- Iteration Ativas | DONE — Concluídas | Falhas / Bloqueios | Lead Time (dias)

**Linha 2 — Funil + Delivery Journey (y=3, h=9):**
- Funil de Entrega timeseries bars (x=0, w=4) — alinhado com 2 linhas de phases
- Delivery Journey: 8 phases × **w=2** (2 rows de 4 em x=4..11) — fases com título legível completo

**Linha 3 — Diligence Status (y=12, h=4):** 4 × w=3 + label note
- Capture | Attach | Promote | Close ✓

**Linha 4 — Exception Paths (y=16, h=4):** 4 × w=3 + label note
- BLOQUEIO | DRIFT | REPAIR | CLOSED

**Mudanças em relação a v3.0.0:**
- Delivery phases: `w=1` → `w=2` (títulos completos e legíveis)
- Diligence Status: movido para linha própria (y=12), `w=3` por phase
- Section labels: note widgets de seção adicionados (Delivery Journey, Diligence Status, Exception Paths)
- Layout: abandonado ordered+groups (API rejeitou reflow_type=auto com grupos) → mantido free layout

---

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
