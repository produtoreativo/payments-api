---
name: event-storming
description: Gera o roteiro de um Event Storming a partir de um Business Signal/Intent/OBC, documenta o resultado, produz o dashboard do Datadog e o publica. Use quando houver um sinal ou capability que precisa de um Event Storming (linha do tempo de eventos, políticas, pontos críticos, observabilidade) ou quando o spec de um Event Storming existente mudou e o dashboard precisa ser regerado. Fonte única é o spec JSON; roteiro e dashboard são derivados.
---

# Event Storming — roteiro, documentação, dashboard e publicação

Esta skill transforma um sinal de negócio em um **Event Storming documentado** e em um **dashboard do Datadog**. O fluxo gira em torno de um único arquivo, o **spec**:

```
prodops/artifacts/event-storming/<slug>.spec.json      ← fonte única (editado por humano/agente)
        ├─ render-roteiro.py   → <slug>.md              roteiro e documentação
        ├─ build-dashboard.py  → <slug>.datadog.json    dashboard (JSON da API do Datadog)
        └─ publish-dashboard.sh→ Datadog + <slug>.datadog.state.json (id do dashboard)
```

Roteiro e dashboard nunca são editados à mão: altere o spec e gere de novo. Os scripts ficam em `prodops/skills/event-storming/scripts/` (rode com `python3`, sem `-I`).

## Quando usar

| Situação | Modo |
|---|---|
| Há um Business Signal/Intent/OBC e nenhum Event Storming | `criar` |
| O spec mudou (evento passou a ser emitido, decisão tomada) | `atualizar` |
| Só quer saber se o spec bate com o código | `check` |
| Publicar ou atualizar o dashboard no Datadog | `publicar` |

Não use para: alterar código, testes, BDD ou OBC (esses seguem pelas suas skills — `obc`, `hack`); nem para decidir pelo dono — pontos críticos sem decisão ficam `Aberto`.

## Pré-leitura

1. Business Signal, Business Intent e OBC da capability; BDD (`prodops/artifacts/bdd/<slug>.feature`).
2. Catálogo de eventos: `prodops/artifacts/architecture/domain-events.md` e a fonte única `api/src/events/payments-events.ts`.
3. Métricas existentes: `api/src/observability/metrics.ts` e `prodops/runtime/datadog/send.sh`.
4. O schema do spec (seção abaixo) e `prodops/artifacts/event-storming/` — onde ficam os specs, roteiros e dashboards já existentes.

## Fluxo — `criar`

1. **Levantar os fatos no código**, não por suposição: o que é emitido (`grep -rn "\.emit\|emitAsync" api/src`), quais guardas existem, quais listeners escutam. Onde a dúvida se resolve com um teste, escreva o teste de investigação, rode, e registre o resultado (marque `Comprovado` ou `Confirmado no código`); apague o teste depois de virar teste definitivo.
2. **Escrever o spec** (`<slug>.spec.json`) com o schema abaixo. Eventos prometidos e não emitidos são `planned`; nunca invente um nome — se o código não o emite, `planned`.
3. **Validar**: `python3 prodops/skills/event-storming/scripts/build-dashboard.py <spec> --check`. Falha se um evento `emitted` não existe em `payments-events.ts` ou se um widget `available` usa métrica que o código não emite; avisa se um `planned` já existe.
4. **Gerar o roteiro**: `python3 prodops/skills/event-storming/scripts/render-roteiro.py <spec>` (não sobrescreve sem `--force`).
5. **Gerar o dashboard**: `python3 prodops/skills/event-storming/scripts/build-dashboard.py <spec>`.
6. **Publicar** (próxima seção), só com autorização.
7. Linkar o roteiro no OBC (`Related Artifacts`) e no Business Signal.

## Schema do spec

| Campo | Conteúdo |
|---|---|
| `slug`, `title`, `owner`, `status`, `objective` | identificação (`slug` kebab-case, igual ao do OBC) |
| `refs` | links relativos (BS, PI, OBC, BDD, catálogo) |
| `scope.in` / `scope.out` | o que entra e o que não entra |
| `participants`, `actors` | quem participa; atores do fluxo |
| `timeline[]` | `{id, kind: event\|command\|policy\|external\|hotspot, name, status, note}` |
| `policies[]` | `{id, rule}` — "sempre que … então …" |
| `diagrams` | opcional: `sequence`, `states`, `timeline` (texto Mermaid) |
| `unhappy[]` | `{case, expected, bdd}` |
| `events[]` | `{name, layer: domain\|webhook\|observability, status: emitted\|planned\|external, payload[]}` |
| `hotspots[]` | `{id, title, why, question, owner, decision}` — sem `decision` = aberto |
| `traceability[]`, `decisions[]` | evento → OBC/BDD/teste/código; decisões a confirmar |
| `dashboard` | `{title, env, service, widgets[], slis[]}`; widget `{title, kind: query_value\|timeseries, status: available\|planned, query}` |

Consultas usam `$tags` (vira `env:$env.value,service:$service.value`) — ex.: `sum:webhook.failed{$tags}.as_count()`. Widget `available` precisa de métrica **que o código já emite**; o resto é `planned` e aparece num grupo próprio, com "(planejado)" no título, para não esconder lacunas.

## Publicação no Datadog

```bash
prodops/skills/event-storming/scripts/publish-dashboard.sh <slug>.datadog.json            # dry-run: valida chave e JSON, não envia
prodops/skills/event-storming/scripts/publish-dashboard.sh <slug>.datadog.json --apply    # cria (POST) ou atualiza (PUT)
```

- Publicar é um **efeito externo**: rode o dry-run, mostre ao dono o que será criado/atualizado e **peça confirmação** antes de `--apply`.
- Credenciais `DD_API_KEY`, `DD_APP_KEY`, `DD_SITE` do ambiente ou de `api/.env`. **Nunca imprimir as chaves**.
- O id fica em `<slug>.datadog.state.json`; a próxima publicação atualiza o mesmo dashboard (não duplica). Se o arquivo de estado não existir mas o dashboard já existe, **pare e pergunte** — não crie um segundo.
- Reporte o link devolvido pela API; não o invente.

## Testar o dashboard com métricas sintéticas

```bash
python3 prodops/skills/event-storming/scripts/emit-test-events.py <spec> --dry-run   # mostra o que enviaria
python3 prodops/skills/event-storming/scripts/emit-test-events.py <spec> [--count N] # envia ao agente (DogStatsD)
```

Envia, para cada métrica usada pelos widgets (disponíveis e planejados), os mesmos incrementos que o código emitirá, com as tags `env`, `service`, os filtros da consulta e `source:event-storming-test` + `storming:<slug>` (dado sintético, fácil de filtrar). Métricas de falha/ignorado recebem 1 incremento. Requer o agente do Datadog no ar (`localhost:8125`, ou `DD_AGENT_HOST`/`DD_DOGSTATSD_PORT`). É dado real no Datadog: confirme com o dono antes de rodar, e retire o filtro `source:event-storming-test` das análises de verdade. Quando o código passar a emitir a métrica de fato, marque o widget `available` no spec e regere o dashboard.

## Verificação (saída esperada)

```
Spec: <slug>   modo: <criar|atualizar|check|publicar>
Validação: <N erros, M avisos>
Gerado: <roteiro.md, datadog.json>
Dashboard: <N widgets disponíveis, M planejados>  Publicado: <url | não (dry-run)>
Pontos críticos abertos: <lista>
Métricas faltando para os widgets planejados: <lista>
```

## Guardrails

- **Não inventar** decisões, metas de SLI, nomes de stakeholders ou métricas: sem fonte → `[apurar]` / `planned`.
- **Não alterar** código, testes, BDD nem OBC por esta skill; métricas faltantes viram pendência de Delivery.
- **Não commitar** sem autorização de quem chamou (mensagem: `docs(event-storming): <slug>`); respeitar restrições de branch do usuário.
- **Não apagar** dashboards no Datadog; esta skill só cria e atualiza o que ela mesma publicou.
- Não materializar segredos em nenhum artefato (spec, roteiro, JSON, estado).
