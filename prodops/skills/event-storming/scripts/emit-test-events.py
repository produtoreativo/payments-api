#!/usr/bin/env python3
"""Emite, via DogStatsD, as mesmas métricas que os widgets do spec consomem, para testar o dashboard.

Uso: emit-test-events.py <spec.json> [--count N] [--host H] [--port P] [--dry-run]

Para cada widget (disponível ou planejado) lê a métrica e os filtros da consulta e envia N
incrementos com as tags `env`, `service`, os filtros da consulta e `source:event-storming-test`
(dado sintético, fácil de filtrar ou excluir). Métricas de falha/ignorado recebem 1 incremento.
Destino padrão: DD_AGENT_HOST / DD_DOGSTATSD_PORT ou localhost:8125 (agente local do Docker).
"""
import argparse
import os
import re
import socket

from storming_common import die, load_spec, validate

TAG_ONLY = "$tags"


def parse(query):
    m = re.search(r"(?:sum|avg|max|min|count):([a-z][a-z0-9_.]+)\{([^}]*)\}", query)
    if not m:
        return None
    extras = [t.strip() for t in m.group(2).split(",") if t.strip() and t.strip() != TAG_ONLY]
    return m.group(1), extras


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("--count", type=int, default=5)
    ap.add_argument("--host", default=os.environ.get("DD_AGENT_HOST", "localhost"))
    ap.add_argument("--port", type=int, default=int(os.environ.get("DD_DOGSTATSD_PORT", "8125")))
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    spec = load_spec(a.spec)
    errors, _ = validate(spec)
    if errors:
        die("\n".join(f"ERRO: {e}" for e in errors))
    d = spec["dashboard"]
    base = [f"env:{d.get('env', 'development')}", f"service:{d.get('service', 'payments-api')}",
            "source:event-storming-test", f"storming:{spec['slug']}"]
    sent = {}
    for w in d["widgets"]:
        p = parse(w["query"])
        if not p:
            continue
        metric, extras = p
        n = 1 if re.search(r"failed|ignored|error", metric) else a.count
        sent[(metric, tuple(extras))] = n
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    for (metric, extras), n in sent.items():
        tags = ",".join(base + list(extras))
        for _ in range(n):
            if not a.dry_run:
                sock.sendto(f"{metric}:1|c|#{tags}".encode(), (a.host, a.port))
        print(f"{'(dry-run) ' if a.dry_run else ''}{metric} x{n}  tags: {tags}")
    print(f"OK: {sum(sent.values())} incrementos para {a.host}:{a.port}")


if __name__ == "__main__":
    main()
