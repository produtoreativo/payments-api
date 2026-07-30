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
VERSION="3.0.0"

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
DASHBOARD_JSON=$(python3 - <<'PYEOF'
import json

SVC = "$service.value"
ENV = "$env.value"
BASE = f"service:{SVC},env:{ENV}"

# ── helpers ────────────────────────────────────────────────────────────────

def qv(title, query, x, y, w, h, aggregator="sum", palette=None, unit=None, precision=0):
    req = {"q": query, "aggregator": aggregator}
    if palette:
        req["conditional_formats"] = [{"comparator": ">=", "value": 0, "palette": palette}]
    d = {
        "type": "query_value",
        "title": title,
        "precision": precision,
        "autoscale": True,
        "requests": [req]
    }
    if unit:
        d["custom_unit"] = unit
    return {"definition": d, "layout": {"x": x, "y": y, "width": w, "height": h}}

def note(content, color, x, y, w, h, size="12", align="center"):
    return {
        "definition": {
            "type": "note",
            "content": content,
            "background_color": color,
            "font_size": size,
            "text_align": align,
            "vertical_align": "center",
            "show_tick": False,
            "tick_pos": "50%",
            "tick_edge": "bottom"
        },
        "layout": {"x": x, "y": y, "width": w, "height": h}
    }

def timeseries_multi(title, series_list, x, y, w, h, display="bars"):
    """series_list: [(query_str, display_name_or_None), ...]"""
    requests = []
    for q, name in series_list:
        r = {"q": q, "display_type": display, "style": {"palette": "dog_classic", "line_type": "solid", "line_width": "normal"}}
        requests.append(r)
    return {
        "definition": {
            "type": "timeseries",
            "title": title,
            "requests": requests,
            "show_legend": True,
            "legend_layout": "vertical",
            "legend_columns": ["avg", "sum"]
        },
        "layout": {"x": x, "y": y, "width": w, "height": h}
    }

widgets = []

# ═══════════════════════════════════════════════════════════════════════════
# LINHA 1 — KPIs (y=0, h=3)
# ═══════════════════════════════════════════════════════════════════════════

widgets.append(qv(
    "Iteration Ativas",
    f"sum:runtime.event.received{{event:prodops.delivery.bootstrap.started,{BASE}}}.as_count()",
    x=0, y=0, w=3, h=3,
    aggregator="sum",
    palette="white_on_green"
))

widgets.append(qv(
    "DONE — Concluídas",
    f"sum:runtime.event.received{{event:prodops.delivery.promote.completed,{BASE}}}.as_count()",
    x=3, y=0, w=3, h=3,
    aggregator="sum",
    palette="white_on_green"
))

widgets.append(qv(
    "Falhas — Bloqueios",
    f"sum:runtime.diligence.event.received{{event:prodops.diligence.block.declared,{BASE}}}.as_count()",
    x=6, y=0, w=3, h=3,
    aggregator="sum",
    palette="white_on_red"
))

widgets.append(qv(
    "Lead Time (dias)",
    f"avg:runtime.delivery.lead_time_days{{{BASE}}}",
    x=9, y=0, w=3, h=3,
    aggregator="avg",
    precision=1,
    unit="d"
))

# ═══════════════════════════════════════════════════════════════════════════
# LINHA 2 — FUNIL + DELIVERY JOURNEY + DILIGENCE STATUS (y=3)
# x=0..3: Funil (w=4, h=8)
# x=4..7: Delivery Journey label + 8 phase counters
# x=8..11: Diligence Status label + 4 phase counters
# ═══════════════════════════════════════════════════════════════════════════

# ── Funil de Entrega (timeseries bars por event, todos os delivery events) ──
widgets.append(timeseries_multi(
    "Funil de Entrega — Eventos por Stage",
    [
        (f"sum:runtime.event.received{{event:prodops.delivery.bootstrap.started,{BASE}}}.as_count()", "Bootstrap"),
        (f"sum:runtime.event.received{{event:prodops.delivery.hack.started,{BASE}}}.as_count()", "Hack"),
        (f"sum:runtime.event.received{{event:prodops.delivery.sync.started,{BASE}}}.as_count()", "Sync"),
        (f"sum:runtime.event.received{{event:prodops.delivery.finish.started,{BASE}}}.as_count()", "Finish"),
        (f"sum:runtime.event.received{{event:prodops.delivery.ship.started,{BASE}}}.as_count()", "Ship"),
        (f"sum:runtime.event.received{{event:prodops.delivery.validate.started,{BASE}}}.as_count()", "Validate"),
        (f"sum:runtime.event.received{{event:prodops.delivery.promote.started,{BASE}}}.as_count()", "Promote"),
        (f"sum:runtime.event.received{{event:prodops.delivery.promote.completed,{BASE}}}.as_count()", "DONE"),
    ],
    x=0, y=3, w=4, h=8,
    display="bars"
))

# ── Delivery Journey label ──────────────────────────────────────────────────
widgets.append(note(
    "**DELIVERY JOURNEY**",
    "vivid_orange", x=4, y=3, w=4, h=1, size="14"
))

# ── Delivery phase counters (8 phases, 4 per row) ──────────────────────────
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

for idx, (label, event) in enumerate(DELIVERY_PHASES):
    row = idx // 4
    col = idx % 4
    palette = "white_on_green" if label == "DONE ✓" else "white_on_yellow"
    widgets.append(qv(
        label,
        f"sum:runtime.event.received{{event:{event},{BASE}}}.as_count()",
        x=4 + col, y=4 + row * 3, w=1, h=3,
        aggregator="sum",
        palette=palette
    ))

# ── Diligence Status label ──────────────────────────────────────────────────
widgets.append(note(
    "**DILIGENCE STATUS**",
    "vivid_green", x=8, y=3, w=4, h=1, size="14"
))

# ── Diligence phase counters (4 happy-path phases, 2 per row) ──────────────
DILIGENCE_PHASES = [
    ("Capture",  "prodops.diligence.capture.completed"),
    ("Attach",   "prodops.diligence.attach.completed"),
    ("Promote",  "prodops.diligence.promote.completed"),
    ("Close ✓",  "prodops.diligence.close.completed"),
]

for idx, (label, event) in enumerate(DILIGENCE_PHASES):
    row = idx // 2
    col = idx % 2
    palette = "white_on_green" if "✓" in label else "white_on_yellow"
    widgets.append(qv(
        label,
        f"sum:runtime.diligence.event.received{{event:{event},{BASE}}}.as_count()",
        x=8 + col * 2, y=4 + row * 3, w=2, h=3,
        aggregator="sum",
        palette=palette
    ))

# ═══════════════════════════════════════════════════════════════════════════
# LINHA 3 — EXCEPTION PATHS (y=11, h=3)
# BLOQUEIO | DRIFT | REPAIR | CLOSED
# ═══════════════════════════════════════════════════════════════════════════

widgets.append(qv(
    "⛔ BLOQUEIO — Block Declarado",
    f"sum:runtime.diligence.event.received{{event:prodops.diligence.block.declared,{BASE}}}.as_count()",
    x=0, y=11, w=3, h=3,
    aggregator="sum",
    palette="white_on_red"
))

widgets.append(qv(
    "⚡ DRIFT — Divergência Detectada",
    f"sum:runtime.diligence.event.received{{event:prodops.diligence.divergence.detected,{BASE}}}.as_count()",
    x=3, y=11, w=3, h=3,
    aggregator="sum",
    palette="white_on_orange"
))

widgets.append(qv(
    "🔧 REPAIR — Reparo Concluído",
    f"sum:runtime.diligence.event.received{{event:prodops.diligence.repair.completed,{BASE}}}.as_count()",
    x=6, y=11, w=3, h=3,
    aggregator="sum",
    palette="white_on_yellow"
))

widgets.append(qv(
    "✅ CLOSED — Encerrado",
    f"sum:runtime.diligence.event.received{{event:prodops.diligence.close.completed,{BASE}}}.as_count()",
    x=9, y=11, w=3, h=3,
    aggregator="sum",
    palette="white_on_green"
))

# ═══════════════════════════════════════════════════════════════════════════
# Dashboard payload
# ═══════════════════════════════════════════════════════════════════════════
dashboard = {
    "title": "ProdOps Runtime — Delivery & Diligence v3",
    "description": (
        "v3.0.0 | Linha 1: KPIs | Linha 2: Funil + Delivery Journey phases + Diligence Status | "
        "Linha 3: Exception Paths. Filtre por $service e $env."
    ),
    "layout_type": "free",
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
    "title": "ProdOps Runtime — Delivery & Diligence v3",
    "previous-dashboard-id": "d73-8be-pds",
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
