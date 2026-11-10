#!/usr/bin/env python3
"""Gera o roteiro do Event Storming (Markdown) a partir do spec.

Uso: render-roteiro.py <spec.json> [--out <arquivo>] [--force]
Saída padrão: <dir do spec>/<slug>.md. Não sobrescreve um arquivo existente sem --force.
"""
import argparse
from pathlib import Path

from storming_common import die, load_spec, validate

STATUS = {"emitted": "Emitido", "planned": "Planejado", "external": "Externo"}
KIND = {"event": "🟧 Evento", "command": "🟦 Comando", "policy": "🟪 Política",
        "external": "⬜ Sistema externo", "hotspot": "🟥 Ponto crítico"}


def table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "|" + "---|" * len(headers)]
    out += ["| " + " | ".join(str(c).replace("|", "\\|") for c in r) + " |" for r in rows]
    return "\n".join(out)


def bullets(items):
    return "\n".join(f"- {i}" for i in items)


def mermaid(code):
    return f"```mermaid\n{code.strip()}\n```"


def render(s):
    L = []
    a = L.append
    refs = " · ".join(f"[{k}]({v})" for k, v in s.get("refs", {}).items())
    a(f"# Event Storming — {s['title']}\n")
    a(f"> **Status:** {s.get('status', 'proposta')}. Gerado pelo skill `event-storming` a partir de `{s['slug']}.spec.json` — altere o spec e gere de novo.")
    a(f"> **Dono e facilitador sugerido:** {s['owner']}")
    if refs:
        a(f"> {refs}")
    a("\n---\n")
    a("## 1. Objetivo e escopo\n")
    a(f"**Objetivo:** {s['objective']}\n")
    a(table(["Dentro", "Fora"], [(i, o) for i, o in zip(
        s["scope"]["in"] + [""] * max(0, len(s["scope"]["out"]) - len(s["scope"]["in"])),
        s["scope"]["out"] + [""] * max(0, len(s["scope"]["in"]) - len(s["scope"]["out"])))]))
    a("\n## 2. Participantes e formato\n")
    a(table(["Quem", "Por quê"], [(p["who"], p["why"]) for p in s.get("participants", [])]) if s.get("participants") else "[apurar] participantes")
    a("\n" + table(["Rodada", "Duração", "Saída"], [
        ("1. Big Picture", "45–60 min", "Linha do tempo de eventos de domínio e pontos críticos"),
        ("2. Processo", "45 min", "Comandos, políticas, caminhos infelizes"),
        ("3. Design", "45 min", "Agregados, contratos e rastreabilidade para OBC/BDD/teste")]))
    a("\n**Legenda:** 🟧 evento · 🟦 comando · 🟪 política · 🟨 agregado · 🟩 read model · 🟥 ponto crítico · ⬜ sistema externo.\n")
    a("## 3. Rodada 1 — Big Picture\n")
    a(table(["Ator", "Papel"], [(x["name"], x["role"]) for x in s["actors"]]))
    a("\n### Linha do tempo\n")
    a(table(["#", "Tipo", "Elemento", "Situação", "Observação"],
            [(t["id"], KIND[t["kind"]], t["name"], STATUS.get(t.get("status", ""), t.get("status", "")), t.get("note", ""))
             for t in s["timeline"]]))
    if s.get("diagrams", {}).get("timeline"):
        a("\n" + mermaid(s["diagrams"]["timeline"]))
    a("\n## 4. Rodada 2 — Processo\n")
    a(table(["Política", "Regra"], [(p["id"], p["rule"]) for p in s["policies"]]))
    for k, t in (("sequence", "Sequência"), ("states", "Estados")):
        if s.get("diagrams", {}).get(k):
            a(f"\n### {t}\n\n" + mermaid(s["diagrams"][k]))
    if s.get("unhappy"):
        a("\n### Caminhos infelizes\n")
        a(table(["Cenário", "Comportamento desejado", "BDD"], [(u["case"], u["expected"], u.get("bdd", "—")) for u in s["unhappy"]]))
    a("\n## 5. Rodada 3 — Design\n")
    a(table(["Camada", "Evento", "Payload", "Situação"],
            [(e["layer"], f"`{e['name']}`", ", ".join(f"`{p}`" for p in e.get("payload", [])), STATUS[e["status"]]) for e in s["events"]]))
    a("\n## 6. Pontos críticos\n")
    a(table(["#", "Ponto crítico", "Por quê", "Pergunta", "Quem decide", "Situação / decisão"],
            [(h["id"], h["title"], h.get("why", ""), h["question"], h.get("owner", "[apurar]"), h.get("decision", "Aberto")) for h in s["hotspots"]]))
    d = s["dashboard"]
    a("\n## 7. Observabilidade\n")
    a(f"Dashboard: **{d['title']}** (`{s['slug']}.datadog.json`, gerado por `build-dashboard.py`).\n")
    a(table(["Widget", "Situação", "Consulta"], [(w["title"], "Disponível" if w["status"] == "available" else "Planejado", f"`{w['query']}`") for w in d["widgets"]]))
    if d.get("slis"):
        a("\n" + table(["SLI", "Meta"], [(x["name"], x.get("target", "[apurar]")) for x in d["slis"]]))
    if s.get("traceability"):
        a("\n## 8. Rastreabilidade\n")
        a(table(["Elemento", "OBC", "BDD", "Teste", "Código"], [(t["element"], t.get("obc", "—"), t.get("bdd", "—"), t.get("test", "—"), t.get("code", "—")) for t in s["traceability"]]))
    if s.get("decisions"):
        a("\n## 9. Decisões\n")
        a(table(["#", "Decisão", "Confirmar com"], [(x["id"], x["decision"], x.get("confirm", "—")) for x in s["decisions"]]))
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("--out")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    spec = load_spec(a.spec)
    errors, warnings = validate(spec)
    for w in warnings:
        print(f"AVISO: {w}")
    if errors:
        die("\n".join(f"ERRO: {e}" for e in errors))
    out = Path(a.out) if a.out else Path(a.spec).with_name(f"{spec['slug']}.md")
    if out.exists() and not a.force:
        die(f"{out} já existe — use --out ou --force (sobrescreve)")
    out.write_text(render(spec), encoding="utf-8")
    print(f"OK: {out}")


if __name__ == "__main__":
    main()
