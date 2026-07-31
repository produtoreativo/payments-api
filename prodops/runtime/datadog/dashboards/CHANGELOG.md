# Dashboard Changelog — ProdOps Runtime

## v3.5.0 — 2026-07-31

**Dashboard ID:** `iut-r7k-ehn` (atualizado via PUT — mesmo ID da v3.4.0)

**Arquivo:** `v3.5.0.json`

**Mudanças:** restyling semântico de paleta — estrutura e queries inalteradas.

| Seção | Antes | Depois |
|---|---|---|
| A — KPIs: Iterações Ativas | `white_on_green` | `white_on_blue` — neutro, não implica aprovação |
| B — Funil: background | `vivid_purple` | `blue` — informacional, não saturado |
| C — Delivery Journey: background | `vivid_orange` | `purple` — anchora no brand Datadog |
| C — fases Bootstrap→Promote | `white_on_yellow` | `white_on_blue` — in-progress, não warning |
| D — Diligence: background | `vivid_green` | `gray` — suporte, não protagonista |
| D — fases Capture/Attach/Promote | `white_on_yellow` | `white_on_blue` |
| E — Exception Paths: background | `vivid_red` | `orange` — seção inclui estados resolvidos |
| E — REPAIR | `white_on_yellow` | `white_on_blue` — ação em progresso |

**Mantidos sem alteração:** DONE `white_on_green`, BLOQUEIO `white_on_red`, DRIFT `white_on_orange`, Close ✓ `white_on_green`.

---

## v3.4.0 — 2026-07-30

**Dashboard ID:** `iut-r7k-ehn`

**Arquivo:** `v3.4.0.json`

**Layout:** `ordered` + `reflow_type: "fixed"` com **grupos** — formato confirmado via inspeção do dashboard `5zm-a3w-gjf` existente na org.

**Estrutura:** 5 grupos top-level, cada um com `layout {x,y,width,height}` no grid de 12 colunas do dashboard. Sub-widgets dentro de cada grupo usam coordenadas internas relativas ao grupo (grid 12-col responsivo).

| Grupo | y | h | Conteúdo |
|---|---|---|---|
| A — KPIs | 0 | 3 | 4 × qv (w=3, h=2) em linha |
| B — Funil de Entrega | 3 | 7 | 1 × timeseries (w=12, h=6) |
| C — Delivery Journey | 10 | 5 | 8 × qv (w=3, h=2), 4 por linha |
| D — Diligence Status | 15 | 3 | 4 × qv (w=3, h=2) em linha |
| E — Exception Paths | 18 | 3 | 4 × qv (w=3, h=2) em linha |

---

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
