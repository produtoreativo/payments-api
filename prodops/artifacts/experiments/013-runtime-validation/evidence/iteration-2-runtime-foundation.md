# EXP-013 — Iteração 2: Runtime Foundation
# Relatório de Conclusão

**Data de execução:** 2026-07-27
**runtime-version:** 0.2.0
**Feature piloto:** Issue #76 — FTR-001: Invoice PIX — Happy Path Completo
**Resultado:** ✅ Todos os 5 passos funcionais + 7 objetivos estruturais implementados

---

## 1. Objetivos — Verificação

| Objetivo | Status | Entregável |
|---|---|---|
| 1. Event Catalog | ✅ | `prodops/runtime/catalog/events.yaml` |
| 2. Padronização de nomenclatura (kebab-case) | ✅ | Todos os JSON keys, campos GitHub e arquivos novos |
| 3. Separação Runtime / Evidence | ✅ | Runtime em `prodops/runtime/`; artefatos em `prodops/artifacts/runtime/` |
| 4. Eliminação de hardcodes | ✅ | `runtime.yaml` centraliza owner, repo, project-number, pilot-issue, service, environment |
| 5. Runtime Doctor | ✅ | `prodops/runtime/scripts/runtime-doctor.sh` — executa antes de qualquer operação |
| 6. Correlation ID | ✅ | Gerado em `bootstrap-runtime.sh`; presente em event JSON, timeline, derived-state, logs e tag Datadog |
| 7. Versionamento | ✅ | `runtime-version`, `framework-version`, `schema-version` em todos os artefatos |

---

## 2. Arquivos Modificados

| Arquivo | Tipo | Mudanças |
|---|---|---|
| `prodops/runtime/producer/emit.sh` | Rewrite | Lê catálogo via `catalog_get()`; aceita `--correlation-id`; JSON usa kebab-case; não conhece mais journey/cycle/phase/alters-state/new-state |
| `prodops/runtime/timeline/append.sh` | Refactor | Write atômico (tmp + mv elimina risco de arquivo corrompido) |
| `prodops/runtime/consumer/derive-state.sh` | Refactor | Usa `.["alters-state"]` e `.["new-state"]` (kebab-case); adiciona runtime-version/framework-version/schema-version/computed-at/runtime-correlation-id ao output |
| `prodops/runtime/github/sync.sh` | Refactor | `owner`, `repository`, `project-number` lidos de `runtime.yaml`; campos renomeados para `oem-state`/`oem-last-event` (kebab); aceita `--correlation-id` e loga |
| `prodops/runtime/datadog/send.sh` | Refactor | `service`, `environment` lidos de `runtime.yaml`; aceita `--correlation-id`; tag `correlation-id` adicionada ao metric |
| `prodops/runtime/scripts/bootstrap-runtime.sh` | Refactor | Executa Doctor; gera `CORRELATION_ID`; lê `PILOT_ISSUE`, `GH_OWNER`, etc. de `runtime.yaml`; passa correlation-id a todos os subprocessos; banner v0.2.0 |

---

## 3. Arquivos Criados

| Arquivo | Descrição |
|---|---|
| `prodops/runtime/runtime.yaml` | Config central — versões, github (owner/repo/project-number/pilot-issue), datadog (service/environment) |
| `prodops/runtime/catalog/events.yaml` | Event Catalog v1 — define `Delivery.Bootstrap.Started` com journey, cycle, phase, alters-state, new-state |
| `prodops/runtime/scripts/runtime-doctor.sh` | Health check — verifica tools (jq, curl, python3+PyYAML, gh), config (runtime.yaml, catalog), GitHub (auth, project, issue), Datadog (DD_API_KEY FAIL / DD_APP_KEY WARN) |
| `prodops/artifacts/experiments/013-runtime-validation/evidence/iteration-2-runtime-foundation.md` | Este relatório |

---

## 4. Refatorações Realizadas

| Refatoração | Localização | Resultado |
|---|---|---|
| Event metadata removida do producer | `emit.sh` | Producer recebe nome do evento e consulta o catálogo — não conhece mais journey/cycle/phase |
| Atomic write na timeline | `append.sh` | `jq ... > tmp && mv tmp destino` — elimina arquivo parcialmente escrito se jq falhar |
| `alters_state` → `alters-state` | todos | JSON keys padronizados em kebab-case conforme convenção oficial |
| `new_state` → `new-state` | todos | Idem |
| `occurred_at` → `occurred-at` | `emit.sh` | Idem |
| `computed_at` → `computed-at` | `derive-state.sh` | Idem |
| `id` → `runtime-event-id` | `emit.sh` | Nomenclatura inequívoca |
| Campos GitHub `oem state`/`oem last-event` → `oem-state`/`oem-last-event` | `sync.sh` + GitHub | Renomeados via `updateProjectV2Field` mutation |
| `PILOT_ISSUE` hardcode → `yaml_get "github.pilot-issue"` | `bootstrap-runtime.sh` | Config-driven |
| `OWNER`, `PROJECT_NUMBER`, `REPO` hardcodes → config | `sync.sh` | Config-driven |
| `DD_SERVICE`, `DD_ENV` hardcodes → config | `send.sh` | Config-driven |

---

## 5. Hardcodes Removidos

| Valor removido | De | Para |
|---|---|---|
| `"76"` (pilot issue) | `bootstrap-runtime.sh` | `runtime.yaml → github.pilot-issue` |
| `"produtoreativo"` (owner) | `github/sync.sh` | `runtime.yaml → github.owner` |
| `"payments-api"` (repo) | `github/sync.sh` | `runtime.yaml → github.repository` |
| `"25"` (project number) | `github/sync.sh` | `runtime.yaml → github.project-number` |
| `"payments-api"` (DD service) | `datadog/send.sh` | `runtime.yaml → datadog.service` |
| `"development"` (DD env) | `datadog/send.sh` | `runtime.yaml → datadog.environment` |
| `"Delivery"`, `"Bootstrap"`, `"Started"`, `true`, `"BOOTSTRAPPING"` | `producer/emit.sh` | `catalog/events.yaml` |

---

## 6. Decisões Arquiteturais

| Decisão | Motivo |
|---|---|
| **Python3 + PyYAML como parser YAML** | `yq` não estava instalado; PyYAML é uma dependência Python padrão disponível no ambiente. Doctor documenta isso como PASS (yq not required). |
| **`yaml_get()` inline em cada script** | A spec proíbe abstrações e interfaces. Copiar 10 linhas de Python em cada script é preferível a criar uma lib compartilhada. |
| **Correlation ID gerado no orquestrador** | O `bootstrap-runtime.sh` é o ponto de entrada de uma "run". Gerar o ID aqui garante que todos os steps de uma execução compartilhem o mesmo tracer. |
| **Catalog lookup com Python (não grep)** | O catálogo tem 3 níveis de profundidade e nomes de evento com pontos. Python lida corretamente com a estrutura YAML sem heurística de parsing. |
| **Renomear campos GitHub via `updateProjectV2Field`** | GitHub normaliza nomes de campos para unicidade (espaço ≈ hífen). Renomear os campos existentes é mais limpo que criar campos duplicados. |
| **Kebab-case em JSON keys** | Adota o padrão oficial do Runtime conforme especificado. Requer bracket notation em jq (`.["alters-state"]`). Documentado como Finding T6. |

---

## 7. Dívidas Técnicas Remanescentes

| Débito | Onde | Prioridade |
|---|---|---|
| `yaml_get()` duplicada em 4 scripts | `emit.sh`, `derive-state.sh`, `sync.sh`, `send.sh`, `bootstrap-runtime.sh` | Baixa — duplicação intencional (spec proíbe lib compartilhada) |
| `.env` path relativo hardcoded para fallback de credenciais | `send.sh:17`, `runtime-doctor.sh` | Baixa — path derivado de estrutura conhecida, não valor mágico |
| Timeline não é idempotente — re-execução duplica eventos | `timeline/append.sh` | Média — sem impacto funcional agora (consumer usa o último) |
| Sem tratamento de `SIGINT`/`SIGTERM` no orquestrador | `bootstrap-runtime.sh` | Baixa — script curto (~15s), risco de leave parcial aceitável |
| Doctor lê `runtime.yaml` com `yaml_get()` interno sem reutilizar a função do script | `runtime-doctor.sh` | Baixa — intencional para manter doctor independente |

---

## 8. Limitações Conhecidas

| Limitação | Impacto |
|---|---|
| Apenas 1 evento no catálogo (`Delivery.Bootstrap.Started`) | Não é possível avançar o ciclo sem editar `events.yaml` |
| Timeline append-only sem deduplicação | Rodar o script N vezes cria N eventos com correlation-ids distintos |
| GitHub sync sem verificação de drift (sempre escreve) | Pequeno overhead; não detecta se o valor já está correto |
| Campos GitHub existentes com nomes legados (`oem state`, `oem last-event`) coexistem com os novos (`oem-state`, `oem-last-event`) | Os campos legados estão inativos — não são mais escritos ou lidos |
| Sem AWS Credentials check no Doctor | O Doctor menciona AWS no check list do spec, mas não há uso de AWS nesta iteração — check omitido |

---

## 9. Evidências da Execução

### Timeline (`artifacts/runtime/timelines/76.json`)
```json
[
  {
    "runtime-event-id": "0c416755-bcf8-4207-b48d-e54c393e6194",
    "runtime-correlation-id": "6341dfa1-f651-4ab8-ac76-944079e5d1ea",
    "runtime-version": "0.2.0",
    "framework-version": "1.0.0",
    "schema-version": "1",
    "occurred-at": "2026-07-27T14:09:45Z",
    "issue": "76",
    "event": "Delivery.Bootstrap.Started",
    "journey": "Delivery",
    "cycle": "Bootstrap",
    "phase": "Started",
    "alters-state": true,
    "new-state": "BOOTSTRAPPING"
  }
]
```

### Derived State (`artifacts/runtime/derived-state.json`)
```json
{
  "issue": "76",
  "state": "BOOTSTRAPPING",
  "last-event": "Delivery.Bootstrap.Started",
  "runtime-correlation-id": "6341dfa1-f651-4ab8-ac76-944079e5d1ea",
  "runtime-version": "0.2.0",
  "framework-version": "1.0.0",
  "schema-version": "1",
  "computed-at": "2026-07-27T14:09:46Z"
}
```

### Doctor Result
```
Result: PASS with WARNINGS  (12 passed, 1 warnings)
WARN: DD_APP_KEY is not set — not required for publishing metrics, but needed for Datadog API reads
```

### GitHub Project #25
- Campo `oem-state` atualizado: `BOOTSTRAPPING`
- Campo `oem-last-event` atualizado: `Delivery.Bootstrap.Started`
- Correlation ID logado: `6341dfa1-f651-4ab8-ac76-944079e5d1ea`

### Datadog
- HTTP 202 — `runtime.event.received`
- Tags: `issue:76`, `event:Delivery.Bootstrap.Started`, `state:BOOTSTRAPPING`, `correlation-id:6341dfa1-f651-4ab8-ac76-944079e5d1ea`

---

## 10. Sugestões para a Iteração 3

| Sugestão | Valor de aprendizado |
|---|---|
| **Adicionar múltiplos eventos ao catálogo** (`Delivery.Hack.Started`, `Delivery.Promote.Completed`) | Alto — permite observar uma Feature cruzando múltiplos estados na Timeline e valida Q2 |
| **Adicionar `runtime-session-id` ao `runtime.yaml`** para distinguir sessões de execução do `CORRELATION_ID` por evento | Médio — esclarece o modelo mental de rastreabilidade |
| **Adicionar deduplicação por `runtime-event-id` na Timeline** | Médio — elimina duplicação em re-execuções |
| **Adicionar campo `runtime-correlation-id` no GitHub Project** (`oem-correlation-id`) para rastreabilidade GitHub → Datadog | Médio — fecha o loop de observabilidade sem nova infraestrutura |
| **Executar o fluxo completo para FTR-002 e FTR-003** | Alto — começa a validar CS-01 (três Features com Timelines) |
| **Implementar drift detection no sync** (ler campo antes de escrever) | Baixo — qualidade operacional, sem impacto no experimento |
