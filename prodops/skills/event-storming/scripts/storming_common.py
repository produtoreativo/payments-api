"""Funções compartilhadas pelos scripts do skill event-storming."""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]
EVENTS_TS = REPO / "api/src/events/payments-events.ts"
METRIC_SOURCES = [REPO / "api/src/observability/metrics.ts", REPO / "prodops/runtime/datadog/send.sh"]

REQUIRED = ["slug", "title", "owner", "objective", "scope", "actors", "timeline", "policies",
            "hotspots", "events", "dashboard"]
EVENT_STATUS = {"emitted", "planned", "external"}
WIDGET_STATUS = {"available", "planned"}
LAYERS = {"domain", "webhook", "observability"}
KINDS = {"event", "command", "policy", "external", "hotspot"}


def load_spec(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def code_events():
    """Nomes de evento de domínio presentes na fonte única do código."""
    if not EVENTS_TS.exists():
        return set()
    return set(re.findall(r"'(payments\.[a-z_]+\.[a-z_]+)'", EVENTS_TS.read_text(encoding="utf-8")))


def known_metrics():
    out = set()
    for f in METRIC_SOURCES:
        if f.exists():
            out |= set(re.findall(r"['\"]([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)['\"]", f.read_text(encoding="utf-8")))
    return out


def query_metrics(query):
    return set(re.findall(r"(?:sum|avg|max|min|count):([a-z][a-z0-9_.]+)\{", query))


def validate(spec):
    """Retorna (erros, avisos). Erros bloqueiam; avisos pedem atenção."""
    errors, warnings = [], []
    for k in REQUIRED:
        if k not in spec or spec[k] in (None, "", [], {}):
            errors.append(f"campo obrigatório ausente: {k}")
    if errors:
        return errors, warnings
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", spec["slug"]):
        errors.append("slug deve ser kebab-case")
    ids = [t.get("id") for t in spec["timeline"]]
    if len(ids) != len(set(ids)):
        errors.append("ids duplicados na timeline")
    for t in spec["timeline"]:
        if t.get("kind") not in KINDS:
            errors.append(f"timeline {t.get('id')}: kind inválido {t.get('kind')!r}")
    domain = code_events()
    for e in spec["events"]:
        n, st, ly = e.get("name"), e.get("status"), e.get("layer")
        if st not in EVENT_STATUS:
            errors.append(f"evento {n}: status inválido {st!r}")
        if ly not in LAYERS:
            errors.append(f"evento {n}: layer inválida {ly!r}")
        if ly == "domain" and domain:
            if not str(n).startswith("payments."):
                errors.append(f"evento de domínio {n} deve seguir payments.<agregado>.<fato>")
            elif st == "emitted" and n not in domain:
                errors.append(f"evento {n} marcado emitted, mas não existe em payments-events.ts")
            elif st == "planned" and n in domain:
                warnings.append(f"evento {n} marcado planned, mas já existe no código — atualizar para emitted")
    hot = {h.get("id") for h in spec["hotspots"]}
    for h in spec["hotspots"]:
        for f in ("id", "title", "question"):
            if not h.get(f):
                errors.append(f"hotspot sem {f}: {h}")
    metrics = known_metrics()
    for w in spec["dashboard"].get("widgets", []):
        st, q = w.get("status"), w.get("query", "")
        if st not in WIDGET_STATUS:
            errors.append(f"widget {w.get('title')!r}: status inválido {st!r}")
            continue
        found = query_metrics(q)
        missing = {m for m in found if m not in metrics}
        if st == "available" and missing:
            errors.append(f"widget {w['title']!r} marcado available, mas a métrica não existe no código: {sorted(missing)}")
        if st == "planned" and found and not missing:
            warnings.append(f"widget {w['title']!r} marcado planned, mas a métrica já existe — marcar available")
    return errors, warnings


def die(msg, code=1):
    print(msg, file=sys.stderr)
    sys.exit(code)
