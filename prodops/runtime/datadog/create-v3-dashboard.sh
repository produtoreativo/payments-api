#!/usr/bin/env bash
# create-v3-dashboard.sh — ProdOps Runtime Dashboard v3.0.0
#
# Layout:
#   Linha 1 (KPIs): Iteration Ativas | DONE | Bloqueios | Lead Time
#   Linha 2 (Jornadas): Funil | Delivery Journey phases (×8) | Diligence Status (×4)
#   Linha 3 (Exceptions): BLOQUEIO | DRIFT | REPAIR | CLOSED
#
# Métricas:
#   runtime.event.received        — delivery events (tag event = CE type)
#   runtime.diligence.event.received — diligence events
#   runtime.delivery.lead_time_days  — gauge (send.sh --lead-time-days)
#
# Versioning: prodops/runtime/datadog/dashboards/CHANGELOG.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
ENV_FILE="${REPO_ROOT}/api/.env"
DASHBOARDS_DIR="${SCRIPT_DIR}/dashboards"
EVIDENCE_DIR="${REPO_ROOT}/prodops/artifacts/experiments/014-diligence-tracks-delivery/evidence/executive-dashboard"
ARTIFACTS_DIR="${REPO_ROOT}/prodops/artifacts/runtime"
DD_SITE="${DD_SITE:-datadoghq.com}"
VERSION="3.4.0"

# ─── credentials ────────────────────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found" >&2; exit 1
fi
eval "$(grep -E "^(DD_API_KEY|DD_APP_KEY)=" "$ENV_FILE" | sed 's/^/export /')"
if [[ -z "${DD_API_KEY:-}" || -z "${DD_APP_KEY:-}" ]]; then
  echo "ERROR: DD_API_KEY / DD_APP_KEY not set in $ENV_FILE" >&2; exit 1
fi

mkdir -p "$DASHBOARDS_DIR" "$EVIDENCE_DIR" "$ARTIFACTS_DIR"

echo "=== ProdOps Runtime Dashboard v${VERSION} ==="
echo "site: ${DD_SITE}"
echo ""

# ─── generate dashboard JSON ─────────────────────────────────────────────────
# Layout: ordered + reflow_type=fixed com GRUPOS
# Formato confirmado via inspeção de dashboard existente (5zm-a3w-gjf):
#   - Grupo top-level: layout {x, y, width, height} no grid 12-col do dashboard
#   - Sub-widget: layout {x, y, width, height} no grid 12-col INTERNO do grupo
#   - Tamanhos são relativos à tela (12 colunas = 100% da largura disponível)
#
# Grupo A — KPIs         : y=0,  h=3  | 4 × qv  (x=0,3,6,9  w=3 h=2)
# Grupo B — Funil        : y=3,  h=7  | 1 × ts  (x=0 w=12 h=6)
# Grupo C — Delivery     : y=10, h=5  | 8 × qv  (4 por linha, w=3 h=2)
# Grupo D — Diligence    : y=15, h=3  | 4 × qv  (x=0,3,6,9  w=3 h=2)
# Grupo E — Exceptions   : y=18, h=3  | 4 × qv  (x=0,3,6,9  w=3 h=2)
DASHBOARD_JSON=$(python3 - <<'PYEOF'
import json

SVC = "$service.value"
ENV = "$env.value"
BASE = f"service:{SVC},env:{ENV}"

def qv(title, query, x, y, w, h, aggregator="sum", palette=None, unit=None, precision=0):
    """Sub-widget dentro de grupo: coordenadas relativas ao grid interno do grupo."""
    req = {"q": query, "aggregator": aggregator}
    if palette:
        req["conditional_formats"] = [{"comparator": ">=", "value": 0, "palette": palette}]
    d = {"type": "query_value", "title": title, "title_size": "16", "title_align": "left",
         "precision": precision, "autoscale": True, "requests": [req]}
    if unit:
        d["custom_unit"] = unit
    return {"definition": d, "layout": {"x": x, "y": y, "width": w, "height": h}}

def ts(title, series_list, x, y, w, h, display="bars"):
    """Sub-widget timeseries dentro de grupo."""
    reqs = [{"q": q, "display_type": display,
             "style": {"palette": "dog_classic", "line_type": "solid", "line_width": "normal"}}
            for q, _ in series_list]
    return {"definition": {"type": "timeseries", "title": title, "title_size": "16",
                            "show_legend": True, "legend_layout": "auto",
                            "legend_columns": ["sum"], "requests": reqs},
            "layout": {"x": x, "y": y, "width": w, "height": h}}

def group(title, bg_color, gx, gy, gw, gh, sub_widgets):
    """Grupo top-level com posição absoluta no dashboard e sub-widgets relativos."""
    d = {"type": "group", "title": title, "layout_type": "ordered", "widgets": sub_widgets}
    if bg_color:
        d["background_color"] = bg_color
    return {"definition": d, "layout": {"x": gx, "y": gy, "width": gw, "height": gh}}

funil_series = [
    (f"sum:runtime.event.received{{event:prodops.delivery.bootstrap.started,{BASE}}}.as_count()", "Bootstrap"),
    (f"sum:runtime.event.received{{event:prodops.delivery.hack.started,{BASE}}}.as_count()", "Hack"),
    (f"sum:runtime.event.received{{event:prodops.delivery.sync.started,{BASE}}}.as_count()", "Sync"),
    (f"sum:runtime.event.received{{event:prodops.delivery.finish.started,{BASE}}}.as_count()", "Finish"),
    (f"sum:runtime.event.received{{event:prodops.delivery.ship.started,{BASE}}}.as_count()", "Ship"),
    (f"sum:runtime.event.received{{event:prodops.delivery.validate.started,{BASE}}}.as_count()", "Validate"),
    (f"sum:runtime.event.received{{event:prodops.delivery.promote.started,{BASE}}}.as_count()", "Promote"),
    (f"sum:runtime.event.received{{event:prodops.delivery.promote.completed,{BASE}}}.as_count()", "DONE"),
]

DELIVERY_PHASES = [
    ("Bootstrap", "prodops.delivery.bootstrap.started"),
    ("Hack",      "prodops.delivery.hack.started"),
    ("Sync",      "prodops.delivery.sync.started"),
    ("Finish",    "prodops.delivery.finish.started"),
    ("Ship",      "prodops.delivery.ship.started"),
    ("Validate",  "prodops.delivery.validate.started"),
    ("Promote",   "prodops.delivery.promote.started"),
    ("DONE ✓",    "prodops.delivery.promote.completed"),
]

DILIGENCE_PHASES = [
    ("Capture",  "prodops.diligence.capture.completed"),
    ("Attach",   "prodops.diligence.attach.completed"),
    ("Promote",  "prodops.diligence.promote.completed"),
    ("Close ✓",  "prodops.diligence.close.completed"),
]

EXCEPTION = [
    ("⛔ BLOQUEIO", "prodops.diligence.block.declared",       "white_on_red"),
    ("⚡ DRIFT",    "prodops.diligence.divergence.detected",  "white_on_orange"),
    ("🔧 REPAIR",  "prodops.diligence.repair.completed",     "white_on_yellow"),
    ("✅ CLOSED",  "prodops.diligence.close.completed",      "white_on_green"),
]

# 4 sub-widgets na mesma linha, cada um w=3
def four_across(items_fn):
    return [items_fn(i) for i in range(4)]

widgets = [
    # ── A — KPIs (y=0, h=3): 4 contadores lado a lado ──────────────────────
    group("A — KPIs", None, gx=0, gy=0, gw=12, gh=3, sub_widgets=[
        qv("Iteration Ativas",
           f"sum:runtime.event.received{{event:prodops.delivery.bootstrap.started,{BASE}}}.as_count()",
           x=0, y=0, w=3, h=2, palette="white_on_green"),
        qv("DONE — Concluídas",
           f"sum:runtime.event.received{{event:prodops.delivery.promote.completed,{BASE}}}.as_count()",
           x=3, y=0, w=3, h=2, palette="white_on_green"),
        qv("Falhas — Bloqueios",
           f"sum:runtime.diligence.event.received{{event:prodops.diligence.block.declared,{BASE}}}.as_count()",
           x=6, y=0, w=3, h=2, palette="white_on_red"),
        qv("Lead Time (dias)",
           f"avg:runtime.delivery.lead_time_days{{{BASE}}}",
           x=9, y=0, w=3, h=2, aggregator="avg", precision=1, unit="d"),
    ]),

    # ── B — Funil de Entrega (y=3, h=7): timeseries bars ───────────────────
    group("B — Funil de Entrega", "vivid_purple", gx=0, gy=3, gw=12, gh=7, sub_widgets=[
        ts("Eventos por Stage (Delivery)", funil_series, x=0, y=0, w=12, h=6),
    ]),

    # ── C — Delivery Journey (y=10, h=5): 8 fases, 4 por linha ─────────────
    group("C — Delivery Journey", "vivid_orange", gx=0, gy=10, gw=12, gh=5, sub_widgets=[
        *[qv(label,
             f"sum:runtime.event.received{{event:{event},{BASE}}}.as_count()",
             x=(i % 4) * 3, y=(i // 4) * 2, w=3, h=2,
             palette="white_on_green" if "DONE" in label else "white_on_yellow")
          for i, (label, event) in enumerate(DELIVERY_PHASES)]
    ]),

    # ── D — Diligence Status (y=15, h=3): 4 fases em linha ─────────────────
    group("D — Diligence Status", "vivid_green", gx=0, gy=15, gw=12, gh=3, sub_widgets=[
        *[qv(label,
             f"sum:runtime.diligence.event.received{{event:{event},{BASE}}}.as_count()",
             x=i * 3, y=0, w=3, h=2,
             palette="white_on_green" if "✓" in label else "white_on_yellow")
          for i, (label, event) in enumerate(DILIGENCE_PHASES)]
    ]),

    # ── E — Exception Paths (y=18, h=3): 4 em linha ────────────────────────
    group("E — Exception Paths — BLOQUEIO · DRIFT · REPAIR · CLOSED",
          "vivid_red", gx=0, gy=18, gw=12, gh=3, sub_widgets=[
        *[qv(label,
             f"sum:runtime.diligence.event.received{{event:{event},{BASE}}}.as_count()",
             x=i * 3, y=0, w=3, h=2, palette=palette)
          for i, (label, event, palette) in enumerate(EXCEPTION)]
    ]),
]

dashboard = {
    "title": "ProdOps Runtime — Delivery & Diligence v3",
    "description": (
        "v3.4.0 | Ordered+fixed com grupos — layout 12-col responsivo. "
        "A: KPIs | B: Funil | C: Delivery Journey ×8 | D: Diligence ×4 | E: Exception Paths ×4"
    ),
    "layout_type": "ordered",
    "reflow_type": "fixed",
    "tags": ["team:prodops"],
    "widgets": widgets,
    "template_variables": [
        {"name": "service", "prefix": "service", "default": "payments-api"},
        {"name": "env",     "prefix": "env",     "default": "development"},
        {"name": "issue",   "prefix": "issue",   "default": "*"}
    ]
}
print(json.dumps(dashboard, indent=2))
PYEOF
)

WIDGET_COUNT=$(echo "$DASHBOARD_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d["widgets"]))')
echo "Dashboard JSON generated: ${WIDGET_COUNT} widgets"

# ─── save versioned definition ────────────────────────────────────────────────
DEFINITION_FILE="${DASHBOARDS_DIR}/v${VERSION}.json"
echo "$DASHBOARD_JSON" > "$DEFINITION_FILE"
echo "Definition saved: $DEFINITION_FILE"

# ─── post to Datadog API ──────────────────────────────────────────────────────
echo ""
echo "=== Posting to Datadog API ==="
RESPONSE=$(curl -s -X POST "https://api.${DD_SITE}/api/v1/dashboard" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -d "$DASHBOARD_JSON")

DASH_ID=$(echo  "$RESPONSE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("id",""))' 2>/dev/null || true)
DASH_URL=$(echo "$RESPONSE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("url",""))' 2>/dev/null || true)
WIDGET_COUNT_API=$(echo "$RESPONSE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d.get("widgets",[])))' 2>/dev/null || true)

if [[ -z "$DASH_ID" ]]; then
  echo "ERROR: Dashboard creation failed" >&2
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE" >&2
  exit 1
fi

echo "Dashboard ID:  $DASH_ID"
echo "Dashboard URL: https://app.${DD_SITE}${DASH_URL}"
echo "Widgets:       ${WIDGET_COUNT_API}"
echo ""

# ─── save artifacts ──────────────────────────────────────────────────────────
RESPONSE_FILE="${ARTIFACTS_DIR}/datadog-v3-dashboard-response.json"
echo "$RESPONSE" > "$RESPONSE_FILE"

NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
METADATA=$(python3 - <<PYMETA
import json
meta = {
    "version": "${VERSION}",
    "dashboard-id": "${DASH_ID}",
    "dashboard-url": "https://app.${DD_SITE}${DASH_URL}",
    "title": "ProdOps Runtime — Delivery & Diligence v3.1",
    "previous-dashboard-id": "84w-hbn-6pn",
    "widget-count": ${WIDGET_COUNT_API:-0},
    "sections": 3,
    "created-at": "${NOW_ISO}",
    "layout": {
        "row1": "KPIs: Iteration Ativas, DONE, Falhas/Bloqueios, Lead Time (dias)",
        "row2": "Funil de Entrega (timeseries bars) | Delivery Journey x8 | Diligence Status x4",
        "row3": "Exception Paths: BLOQUEIO, DRIFT, REPAIR, CLOSED"
    },
    "template-variables": ["service", "env", "issue"],
    "metrics": [
        "runtime.event.received",
        "runtime.diligence.event.received",
        "runtime.delivery.lead_time_days"
    ],
    "notes": [
        "Removido widget de cabeçalho de texto (ProdOps Runtime header)",
        "Removida dependência de demo-run-id",
        "Sem live_span fixo — widgets herdam seletor global da dashboard",
        "Lead time via runtime.delivery.lead_time_days (gauge, emitido com send.sh --lead-time-days)",
        "Funil usa timeseries bars agrupado por event tag (CE type)"
    ],
    "changelog": "prodops/runtime/datadog/dashboards/CHANGELOG.md"
}
print(json.dumps(meta, indent=2))
PYMETA
)

METADATA_FILE="${EVIDENCE_DIR}/executive-dashboard-metadata.json"
echo "$METADATA" > "$METADATA_FILE"

cp "$DEFINITION_FILE" "${EVIDENCE_DIR}/executive-dashboard-v${VERSION}.json"

echo "=== Artifacts saved ==="
echo "  Versioned definition: $DEFINITION_FILE"
echo "  Evidence copy:        ${EVIDENCE_DIR}/executive-dashboard-v${VERSION}.json"
echo "  Response:             $RESPONSE_FILE"
echo "  Metadata:             $METADATA_FILE"
echo ""
echo "=== Dashboard v${VERSION} READY ==="
echo "  URL: https://app.${DD_SITE}${DASH_URL}"
echo "  ID:  ${DASH_ID}"
echo ""
echo "  Next: inject test events to verify all queries:"
echo "  bash prodops/runtime/datadog/send-test-events.sh"
