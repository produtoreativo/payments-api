#!/usr/bin/env python3
"""Gera o JSON de dashboard do Datadog a partir do spec do Event Storming.

Uso: build-dashboard.py <spec.json> [--out <arquivo>] [--check]
  --check   só valida o spec (eventos/métricas contra o código) e sai com 1 se houver erro.
Saída padrão: <dir do spec>/<slug>.datadog.json
"""
import argparse
import json
from pathlib import Path

from storming_common import die, load_spec, validate

TAG_EXPR = "env:$env.value,service:$service.value"


def widget(w):
    q = w["query"].replace("$tags", TAG_EXPR)
    title = w["title"] + (" (planejado)" if w["status"] == "planned" else "")
    kind = w.get("kind", "query_value")
    if kind == "timeseries":
        d = {"type": "timeseries", "title": title, "show_legend": False,
             "requests": [{"q": q, "display_type": w.get("display", "bars")}]}
    else:
        d = {"type": "query_value", "title": title, "autoscale": True, "precision": 0,
             "requests": [{"q": q, "aggregator": "sum"}]}
    return {"definition": d}


def note(text):
    return {"definition": {"type": "note", "content": text, "background_color": "white",
                           "font_size": "14", "text_align": "left", "show_tick": False}}


def group(title, widgets):
    return {"definition": {"type": "group", "title": title, "layout_type": "ordered", "widgets": widgets}}


def build(spec):
    dash = spec["dashboard"]
    avail = [w for w in dash["widgets"] if w["status"] == "available"]
    planned = [w for w in dash["widgets"] if w["status"] == "planned"]
    links = " · ".join(f"[{k}]({v})" for k, v in dash.get("links", {}).items())
    header = f"**{spec['title']}**\n\nDono: {spec['owner']}. {spec['objective']}\n\n{links}"
    widgets = [note(header)]
    if avail:
        widgets.append(group("Sinais disponíveis", [widget(w) for w in avail]))
    if planned:
        widgets.append(group("Planejado — a métrica ainda não é emitida", [widget(w) for w in planned]))
    slis = dash.get("slis", [])
    if slis:
        rows = "\n".join(f"| {s['name']} | {s.get('target', '[apurar]')} |" for s in slis)
        widgets.append(note("**SLIs propostos**\n\n| SLI | Meta |\n|---|---|\n" + rows))
    return {
        "title": dash["title"],
        "description": f"Gerado do Event Storming '{spec['slug']}' pelo skill event-storming. Não edite à mão: altere o spec e gere de novo.",
        "layout_type": "ordered",
        "reflow_type": "auto",
        "tags": ["team:payments"],  # o Datadog só aceita as chaves team e ai em dashboards
        "template_variables": [
            {"name": "env", "prefix": "env", "default": dash.get("env", "development")},
            {"name": "service", "prefix": "service", "default": dash.get("service", "payments-api")},
        ],
        "widgets": widgets,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("--out")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    spec = load_spec(a.spec)
    errors, warnings = validate(spec)
    for w in warnings:
        print(f"AVISO: {w}")
    for e in errors:
        print(f"ERRO: {e}")
    if errors:
        die(f"{len(errors)} erro(s) — nada gerado")
    if a.check:
        print(f"OK: spec válido ({len(warnings)} aviso(s))")
        return
    out = Path(a.out) if a.out else Path(a.spec).with_name(f"{spec['slug']}.datadog.json")
    d = build(spec)
    out.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    n = sum(len(g["definition"].get("widgets", [])) for g in d["widgets"] if g["definition"]["type"] == "group")
    print(f"OK: {out} ({n} widgets em {len(d['widgets'])} blocos)")


if __name__ == "__main__":
    main()
