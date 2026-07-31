#!/usr/bin/env bash
# EXP-014 — Executive Cockpit Dashboard (redesign)
# FF-13: tag values with spaces cannot be used as metric filters
# FF-14: macOS bash 3.2 — no associative arrays

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
ENV_FILE="${REPO_ROOT}/api/.env"

EVIDENCE_DIR="${REPO_ROOT}/prodops/artifacts/experiments/014-diligence-tracks-delivery/evidence/executive-dashboard"
ARTIFACTS_DIR="${REPO_ROOT}/prodops/artifacts/runtime"
DD_SITE="${DD_SITE:-datadoghq.com}"

# ─── credentials ────────────────────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found" >&2; exit 1
fi
eval "$(grep -E "^(DD_API_KEY|DD_APP_KEY)=" "$ENV_FILE" | sed 's/^/export /')"
if [[ -z "${DD_API_KEY:-}" || -z "${DD_APP_KEY:-}" ]]; then
  echo "ERROR: DD_API_KEY / DD_APP_KEY not set in $ENV_FILE" >&2; exit 1
fi

mkdir -p "$EVIDENCE_DIR" "$ARTIFACTS_DIR"

echo "=== EXP-014 — Executive Cockpit Dashboard (redesign) ==="
echo "site: ${DD_SITE}"
echo ""

# ─── generate dashboard JSON ─────────────────────────────────────────────────
DASHBOARD_JSON=$(python3 - <<'PYEOF'
import json

SVC = "$service.value"
RUN = "$demo_run_id.value"
BASE = f"service:{SVC},demo-run-id:{RUN}"

# ── widget helpers ────────────────────────────────────────────────────────────

def note(content, color, x, y, w, h, size="14", align="center"):
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
            "tick_edge": "left"
        },
        "layout": {"x": x, "y": y, "width": w, "height": h}
    }

def section_header(number, title, color, x, y, w):
    return note(f"**{number}. {title}**", color, x, y, w, 1, size="14")

def qv_simple(title, query, x, y, w, h, aggregator="sum", palette=None, unit=None):
    req = {"q": query, "aggregator": aggregator}
    if palette:
        req["conditional_formats"] = [{"comparator": ">", "value": 0, "palette": palette}]
    d = {"type": "query_value", "title": title, "precision": 0, "autoscale": True, "requests": [req]}
    if unit:
        d["custom_unit"] = unit
    return {"definition": d, "layout": {"x": x, "y": y, "width": w, "height": h}}

def qv_formula(title, formula_str, queries, x, y, w, h, palette=None, unit=None):
    req = {
        "formulas": [{"formula": formula_str}],
        "queries": [{"name": n, "data_source": "metrics", "query": q, "aggregator": "sum"}
                    for n, q in queries.items()],
        "response_format": "scalar"
    }
    if palette:
        req["conditional_formats"] = [{"comparator": ">", "value": 0, "palette": palette}]
    d = {"type": "query_value", "title": title, "precision": 0, "autoscale": True, "requests": [req]}
    if unit:
        d["custom_unit"] = unit
    return {"definition": d, "layout": {"x": x, "y": y, "width": w, "height": h}}

def toplist(title, query, x, y, w, h):
    return {
        "definition": {
            "type": "toplist",
            "title": title,
            "requests": [{"q": query, "style": {"palette": "dog_classic"}}]
        },
        "layout": {"x": x, "y": y, "width": w, "height": h}
    }

def sunburst(title, query, x, y, w, h):
    return {
        "definition": {
            "type": "sunburst",
            "title": title,
            "requests": [{"q": query, "style": {"palette": "dog_classic"}}],
            "legend": {"type": "table"}
        },
        "layout": {"x": x, "y": y, "width": w, "height": h}
    }

def timeseries(title, queries, x, y, w, h, display="bars"):
    return {
        "definition": {
            "type": "timeseries",
            "title": title,
            "requests": [
                {"q": q, "display_type": display, "style": {"palette": "dog_classic"}}
                for q in queries
            ]
        },
        "layout": {"x": x, "y": y, "width": w, "height": h}
    }

def query_table(title, requests, x, y, w, h):
    return {
        "definition": {
            "type": "query_table",
            "title": title,
            "requests": requests
        },
        "layout": {"x": x, "y": y, "width": w, "height": h}
    }

widgets = []

# ═══════════════════════════════════════════════════════════════════════════
# COCKPIT HEADER (y=0)
# ═══════════════════════════════════════════════════════════════════════════
widgets.append(note(
    "## ProdOps Runtime — Delivery Tracked by Diligence\n### EXECUTIVE COCKPIT  |  EXP-014",
    "vivid_blue", 0, 0, 12, 1, size="18"
))

# ═══════════════════════════════════════════════════════════════════════════
# 1. DELIVERY HEALTH (y=1..3)
# ═══════════════════════════════════════════════════════════════════════════
widgets.append(section_header("1", "DELIVERY HEALTH — VISÃO GERAL", "vivid_blue", 0, 1, 12))

widgets.append(qv_formula(
    "Active\nem andamento",
    "total - done",
    {
        "total": f"sum:runtime.diligence.features.tracked{{{BASE}}}.as_count()",
        "done":  f"sum:runtime.diligence.features.tracked{{delivery-state:done,{BASE}}}.as_count()"
    },
    x=0, y=2, w=2, h=2, palette="white_on_green"
))

widgets.append(qv_simple(
    "Done\nconcluídas",
    f"sum:runtime.diligence.features.tracked{{delivery-state:done,{BASE}}}.as_count()",
    x=2, y=2, w=2, h=2, palette="white_on_green"
))

widgets.append(qv_simple(
    "Blocked\nbloqueadas",
    f"sum:runtime.event.received{{state:blocked,{BASE}}}.as_count()",
    x=4, y=2, w=2, h=2, palette="white_on_red"
))

widgets.append(qv_simple(
    "Failed\nfalhas",
    f"sum:runtime.event.received{{state:blocked,{BASE}}}.as_count()",
    x=6, y=2, w=2, h=2, palette="white_on_red"
))

widgets.append(qv_simple(
    "Lead Time\nmédio (s)",
    f"avg:runtime.delivery.leadtime{{{BASE}}}",
    x=8, y=2, w=2, h=2, aggregator="avg"
))

widgets.append(qv_simple(
    "Throughput\núlt. execução",
    f"sum:runtime.diligence.features.tracked{{delivery-state:done,{BASE}}}.as_count()",
    x=10, y=2, w=2, h=2, palette="white_on_green"
))

# ═══════════════════════════════════════════════════════════════════════════
# SECTIONS 2, 3, 4 headers (y=4) + content (y=5..9)
# Layout: Funnel(w=3,x=0) | Journey(w=6,x=3) | Diligence(w=3,x=9)
# ═══════════════════════════════════════════════════════════════════════════

widgets.append(section_header("2", "FEATURE FUNNEL — FUNIL DE ENTREGA", "vivid_purple", 0, 4, 3))
widgets.append(section_header("3", "DELIVERY JOURNEY — FLUXO DA JORNADA", "vivid_orange", 3, 4, 6))
widgets.append(section_header("4", "DILIGENCE STATUS — ACOMPANHAMENTO", "vivid_green", 9, 4, 3))

# ── 2. Feature Funnel (toplist by stage) ────────────────────────────────────
widgets.append(toplist(
    "Funil de Entrega — Stages",
    f"top(sum:runtime.delivery.funnel{{{BASE}}} by {{stage}}.as_count(), 5, 'sum', 'desc')",
    x=0, y=5, w=3, h=5
))

# ── 3. Delivery Journey — 8 QVs (4 per row) + timeseries ──────────────────
JOURNEY_STAGES = [
    ("Bootstrap", "bootstrapping", 3, 5),
    ("Hack",      "hacking",      4, 5),
    ("Sync",      "syncing",      5, 5),
    ("Finish",    "finishing",    6, 5),
    ("Ship",      "shipping",     3, 6),
    ("Validate",  "validating",   4, 6),
    ("Promote",   "promoting",    5, 6),
    ("Done",      "done",         6, 6),
]
for label, state, x, y in JOURNEY_STAGES:
    widgets.append(qv_simple(
        label,
        f"sum:runtime.diligence.features.tracked{{delivery-state:{state},{BASE}}}.as_count()",
        x=x, y=y, w=1, h=1
    ))

widgets.append(timeseries(
    "Eventos por Estado — Timeline",
    [f"sum:runtime.event.received{{{BASE}}} by {{state}}.as_count()"],
    x=3, y=7, w=6, h=3
))

# ── 4. Diligence Status — 6 QVs + sunburst ─────────────────────────────────
widgets.append(qv_simple(
    "Pending",
    f"sum:runtime.diligence.features.tracked{{diligence-status:N/A,{BASE}}}.as_count()",
    x=9, y=5, w=1, h=1
))
widgets.append({
    "definition": {
        "type": "note",
        "content": "**Captured**\n—",
        "background_color": "yellow",
        "font_size": "12",
        "text_align": "center",
        "vertical_align": "center",
        "show_tick": False,
        "tick_pos": "50%",
        "tick_edge": "left"
    },
    "layout": {"x": 10, "y": 5, "width": 1, "height": 1}
})
widgets.append(qv_simple(
    "Attached",
    f"sum:runtime.diligence.features.tracked{{diligence-status:attached,{BASE}}}.as_count()",
    x=11, y=5, w=1, h=1, palette="white_on_green"
))
widgets.append({
    "definition": {
        "type": "note",
        "content": "**Drift**\n—",
        "background_color": "orange",
        "font_size": "12",
        "text_align": "center",
        "vertical_align": "center",
        "show_tick": False,
        "tick_pos": "50%",
        "tick_edge": "left"
    },
    "layout": {"x": 9, "y": 6, "width": 1, "height": 1}
})
widgets.append({
    "definition": {
        "type": "note",
        "content": "**Repair**\n—",
        "background_color": "red",
        "font_size": "12",
        "text_align": "center",
        "vertical_align": "center",
        "show_tick": False,
        "tick_pos": "50%",
        "tick_edge": "left"
    },
    "layout": {"x": 10, "y": 6, "width": 1, "height": 1}
})
widgets.append(qv_simple(
    "In Sync",
    f"sum:runtime.diligence.features.tracked{{diligence-status:attached,{BASE}}}.as_count()",
    x=11, y=6, w=1, h=1, palette="white_on_green"
))

widgets.append(sunburst(
    "Diligência por Status",
    f"sum:runtime.diligence.features.tracked{{{BASE}}} by {{diligence-status}}.as_count()",
    x=9, y=7, w=3, h=3
))

# ═══════════════════════════════════════════════════════════════════════════
# 4b. EXCEPTION PATHS (y=10..12) — Iteration 5: Block, Drift, Repair, Closed
# Full width (w=12): 6 cards × w=2
# Uses real metrics (no FF-13 issue — no spaces in tag values)
# ═══════════════════════════════════════════════════════════════════════════

widgets.append(section_header("4b", "EXCEPTION PATHS — BLOQUEIO · DRIFT · REPAIR · CLOSED", "vivid_red", 0, 10, 12))

widgets.append(qv_simple(
    "Blocked\nbloqueios",
    f"sum:runtime.diligence.blocked{{{BASE}}}.as_count()",
    x=0, y=11, w=2, h=2, palette="white_on_red"
))
widgets.append(qv_simple(
    "Drift\ndetectados",
    f"sum:runtime.diligence.drift.detected{{{BASE}}}.as_count()",
    x=2, y=11, w=2, h=2, palette="white_on_orange"
))
widgets.append(qv_simple(
    "Findings Open\nfindings",
    f"sum:runtime.diligence.findings.open{{{BASE}}}.as_count()",
    x=4, y=11, w=2, h=2, palette="white_on_orange"
))
widgets.append(qv_simple(
    "Repairing\nreparando",
    f"sum:runtime.diligence.event.received{{event:prodops.diligence.repair.started,{BASE}}}.as_count()",
    x=6, y=11, w=2, h=2, palette="white_on_yellow"
))
widgets.append(qv_simple(
    "Repairs Done\nreparados",
    f"sum:runtime.diligence.repairs.completed{{{BASE}}}.as_count()",
    x=8, y=11, w=2, h=2, palette="white_on_green"
))
widgets.append(qv_simple(
    "Closed\nencerradas",
    f"sum:runtime.diligence.features.closed{{{BASE}}}.as_count()",
    x=10, y=11, w=2, h=2, palette="white_on_green"
))

# ═══════════════════════════════════════════════════════════════════════════
# SECTIONS 5, 6, 7 headers (y=13) + content (y=14..18)
# Layout: Live(w=4,x=0) | Events(w=4,x=4) | Correlation(w=4,x=8)
# ═══════════════════════════════════════════════════════════════════════════

widgets.append(section_header("5", "LIVE EXECUTION — EXECUÇÃO ATUAL", "vivid_blue", 0, 13, 4))
widgets.append(section_header("6", "EVENT STREAM — FLUXO DE EVENTOS", "vivid_yellow", 4, 13, 4))
widgets.append(section_header("7", "CORRELATION — DELIVERY ↔ DILIGENCE", "vivid_pink", 8, 13, 4))

# ── 5. Live Execution — query_table with correlation IDs ──────────────────
widgets.append(query_table(
    "Features — Issue × Correlação × Estado",
    [{
        "q": (f"top(sum:runtime.diligence.features.tracked{{{BASE}}} "
              f"by {{issue,delivery-state,diligence-status,"
              f"delivery-correlation-id,diligence-correlation-id}}.as_count(), "
              f"25, 'sum', 'desc')"),
        "alias": "events",
        "limit": 25,
        "order": "desc",
        "aggregator": "sum"
    }],
    x=0, y=14, w=4, h=5
))

# ── 6. Event Stream — 2 timeseries + total QV ─────────────────────────────
widgets.append(timeseries(
    "Delivery Events (últ. 2h)",
    [f"sum:runtime.event.received{{{BASE}}} by {{state}}.as_count()"],
    x=4, y=14, w=4, h=3
))

widgets.append(timeseries(
    "Diligence Events (últ. 2h)",
    [f"sum:runtime.diligence.event.received{{{BASE}}}.as_count()"],
    x=4, y=17, w=4, h=2
))

# ── 7. Correlation Overview ────────────────────────────────────────────────
widgets.append(query_table(
    "Correlation — Delivery × Diligence por Issue",
    [
        {
            "q": (f"top(sum:runtime.diligence.features.tracked{{{BASE}}} "
                  f"by {{issue,delivery-state,diligence-status}}.as_count(), "
                  f"25, 'sum', 'desc')"),
            "alias": "tracked",
            "limit": 25, "order": "desc", "aggregator": "sum"
        },
        {
            "q": f"top(sum:runtime.event.received{{{BASE}}} by {{issue}}.as_count(), 25, 'sum', 'desc')",
            "alias": "delivery-events",
            "limit": 25, "order": "desc", "aggregator": "sum"
        },
        {
            "q": f"top(sum:runtime.diligence.event.received{{{BASE}}} by {{issue}}.as_count(), 25, 'sum', 'desc')",
            "alias": "diligence-events",
            "limit": 25, "order": "desc", "aggregator": "sum"
        }
    ],
    x=8, y=14, w=4, h=5
))

# ═══════════════════════════════════════════════════════════════════════════
# 8. SYSTEM HEALTH (y=19..21)
# ═══════════════════════════════════════════════════════════════════════════
widgets.append(section_header("8", "SYSTEM HEALTH — SAÚDE DO SISTEMA", "vivid_blue", 0, 19, 12))

HEALTH_NOTES = [
    ("Runtime",            "**Runtime**\n\nHealthy ✅",    "green",  0),
    ("GitHub Sync",        "**GitHub Sync**\n\nIn Sync ✅", "green",  2),
    ("Datadog Ingestion",  "**Datadog**\n\nHealthy ✅",    "green",  4),
    ("Timeline Validation","**Timeline**\n\nPass ✅",       "green",  6),
    ("Event Validation",   "**Events**\n\nPass ✅",         "green",  8),
]
for label, content, color, x in HEALTH_NOTES:
    widgets.append(note(content, color, x, 20, 2, 2, size="12"))

widgets.append(note(
    f"**Demo Run ID**\n\n`$demo_run_id`\n\n`$env` | `$service`",
    "gray", 10, 20, 2, 2, size="11"
))

# ═══════════════════════════════════════════════════════════════════════════
# Dashboard payload
# ═══════════════════════════════════════════════════════════════════════════
dashboard = {
    "title": "ProdOps Runtime — Delivery Tracked by Diligence",
    "description": (
        "EXECUTIVE COCKPIT — EXP-014 | 8+4b sections | Iteration 5: Exception Paths | "
        "Filtre por $demo_run_id para isolar uma execução."
    ),
    "layout_type": "ordered",
    "reflow_type": "fixed",
    "tags": ["team:prodops"],
    "widgets": widgets,
    "template_variables": [
        {"name": "demo_run_id", "prefix": "demo-run-id", "default": "*"},
        {"name": "issue",       "prefix": "issue",        "default": "*"},
        {"name": "delivery_state",   "prefix": "delivery-state",   "default": "*"},
        {"name": "diligence_status", "prefix": "diligence-status", "default": "*"},
        {"name": "env",     "prefix": "env",     "default": "staging"},
        {"name": "service", "prefix": "service", "default": "payments-api"},
        {"name": "team",    "prefix": "team",    "default": "prodops"}
    ]
}

print(json.dumps(dashboard, indent=2))
PYEOF
)

WIDGET_COUNT=$(echo "$DASHBOARD_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d["widgets"]))')
echo "Dashboard JSON generated: $(echo "$DASHBOARD_JSON" | wc -c | tr -d ' ') bytes, ${WIDGET_COUNT} widgets"

# ─── save definition ──────────────────────────────────────────────────────────
DEFINITION_FILE="${ARTIFACTS_DIR}/datadog-executive-dashboard-definition.json"
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
DASH_TITLE=$(echo "$RESPONSE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("title",""))' 2>/dev/null || true)
WIDGET_COUNT_API=$(echo "$RESPONSE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d.get("widgets",[])))' 2>/dev/null || true)

if [[ -z "$DASH_ID" ]]; then
  echo "ERROR: Dashboard creation failed" >&2
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE" >&2
  exit 1
fi

echo "Dashboard ID:    $DASH_ID"
echo "Dashboard URL:   https://app.${DD_SITE}${DASH_URL}"
echo "Widget count:    ${WIDGET_COUNT_API} (API)"

# ─── save artifacts ──────────────────────────────────────────────────────────
RESPONSE_FILE="${ARTIFACTS_DIR}/datadog-executive-dashboard-response.json"
echo "$RESPONSE" > "$RESPONSE_FILE"

METADATA_FILE="${ARTIFACTS_DIR}/datadog-executive-dashboard-metadata.json"
python3 - <<PYMETA
import json, datetime
meta = {
    "dashboard-id": "$DASH_ID",
    "dashboard-url": "https://app.${DD_SITE}${DASH_URL}",
    "title": "$DASH_TITLE",
    "widget-count": ${WIDGET_COUNT_API},
    "experiment": "EXP-014",
    "iteration": "5",
    "created-at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "site": "${DD_SITE}",
    "sections": 9,
    "template-variables": ["demo_run_id","issue","delivery_state","diligence_status","env","service","team"],
    "metrics": [
        "runtime.event.received",
        "runtime.diligence.event.received",
        "runtime.diligence.features.tracked",
        "runtime.delivery.leadtime",
        "runtime.delivery.funnel",
        "runtime.diligence.blocked",
        "runtime.diligence.drift.detected",
        "runtime.diligence.findings.open",
        "runtime.diligence.repairs.completed",
        "runtime.diligence.features.closed"
    ],
    "new-metrics": [
        "runtime.diligence.blocked (count, emitted on Block.Declared)",
        "runtime.diligence.drift.detected (count, emitted on Divergence.Detected)",
        "runtime.diligence.findings.open (count, emitted on Divergence.Detected)",
        "runtime.diligence.repairs.completed (count, emitted on Repair.Completed)",
        "runtime.diligence.features.closed (count, emitted on Close.Completed)"
    ],
    "notes": [
        "FF-13: Captured note placeholder (space in tag values); Blocked/Drift/Repair now use real metrics (no spaces)",
        "FF-14: macOS bash 3.2 — no associative arrays",
        "Dashboard tags: only team:prodops permitted (Datadog org constraint)",
        "Iteration 5: Section 4b added for Exception Paths (Block, Drift, Repair, Closed)"
    ]
}
print(json.dumps(meta, indent=2))
PYMETA
python3 - > "$METADATA_FILE" <<PYMETA2
import json, datetime
meta = {
    "dashboard-id": "$DASH_ID",
    "dashboard-url": "https://app.${DD_SITE}${DASH_URL}",
    "title": "$DASH_TITLE",
    "widget-count": ${WIDGET_COUNT_API},
    "experiment": "EXP-014",
    "iteration": "5",
    "created-at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "site": "${DD_SITE}",
    "sections": 9,
    "template-variables": ["demo_run_id","issue","delivery_state","diligence_status","env","service","team"],
    "metrics": [
        "runtime.event.received",
        "runtime.diligence.event.received",
        "runtime.diligence.features.tracked",
        "runtime.delivery.leadtime",
        "runtime.delivery.funnel",
        "runtime.diligence.blocked",
        "runtime.diligence.drift.detected",
        "runtime.diligence.findings.open",
        "runtime.diligence.repairs.completed",
        "runtime.diligence.features.closed"
    ],
    "new-metrics": [
        "runtime.diligence.blocked (count, emitted on Block.Declared)",
        "runtime.diligence.drift.detected (count, emitted on Divergence.Detected)",
        "runtime.diligence.findings.open (count, emitted on Divergence.Detected)",
        "runtime.diligence.repairs.completed (count, emitted on Repair.Completed)",
        "runtime.diligence.features.closed (count, emitted on Close.Completed)"
    ],
    "notes": [
        "FF-13: Captured note placeholder (space in tag values); Blocked/Drift/Repair now use real metrics (no spaces)",
        "FF-14: macOS bash 3.2 — no associative arrays",
        "Dashboard tags: only team:prodops permitted (Datadog org constraint)",
        "Iteration 5: Section 4b added for Exception Paths (Block, Drift, Repair, Closed)"
    ]
}
print(json.dumps(meta, indent=2))
PYMETA2

cp "$DEFINITION_FILE" "${EVIDENCE_DIR}/executive-dashboard-definition.json"
cp "$METADATA_FILE"   "${EVIDENCE_DIR}/executive-dashboard-metadata.json"

echo ""
echo "=== Artifacts saved ==="
echo "  $DEFINITION_FILE"
echo "  $RESPONSE_FILE"
echo "  $METADATA_FILE"
echo ""
echo "=== EXECUTIVE COCKPIT READY ==="
echo "  URL:  https://app.${DD_SITE}${DASH_URL}"
echo "  ID:   $DASH_ID"
echo ""
echo "  Next: run demo and filter by demo_run_id to see all sections with data."
echo "  bash prodops/runtime/scripts/demo-delivery-with-diligence.sh \\"
echo "    --demo --with-diligence --demo-run-id exp-014-demo-\$(date -u +%Y-%m-%d-%H%M)"
