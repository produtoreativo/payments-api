# EXP-013 — Iteração 4: Delivery Happy Path
# Relatório de Conclusão

**Data de execução:** 2026-07-27
**runtime-version:** 0.3.0
**Feature piloto:** Issue #76 — FTR-001: Invoice PIX — Happy Path Completo
**Correlation ID:** `bea8ad98-9a23-4f26-9469-84bcb8346fc1`
**Resultado:** ✅ Delivery Happy Path executado com sucesso — estado final: DONE

---

## 1. Definition of Done — Verificação

| Critério | Status | Evidência |
|---|---|---|
| 15 CloudEvents emitidos e validados | ✅ | Validator: PASS em cada evento |
| Timeline com 15 CloudEvents em ordem cronológica | ✅ | `timelines/76.json` — 15 eventos, 14:52Z → 14:54Z |
| Derived State evoluiu corretamente até DONE | ✅ | `derived-state.json` → state: DONE |
| GitHub Project: oem-state=DONE após Promote.Completed | ✅ | 8 syncs: BOOTSTRAPPING → HACKING → SYNCING → FINISHING → SHIPPING → VALIDATING → PROMOTING → DONE |
| GitHub Project: oem-last-event atualizado a cada estado | ✅ | Último valor: `prodops.delivery.promote.completed` |
| Datadog: 15 métricas `runtime.event.received` enviadas | ✅ | HTTP 202 para cada evento |
| Dashboard Datadog definido | ✅ | `datadog-dashboard-definition.json` (import manual — sem DD_APP_KEY) |
| Nenhuma nova infraestrutura criada | ✅ | Apenas catalog expandido + happy-path script adicionado |

---

## 2. Arquivos Modificados

| Arquivo | Mudança |
|---|---|
| `prodops/runtime/catalog/events.yaml` | 14 novos eventos adicionados (total: 15) |
| `prodops/runtime/producer/emit.sh` | `catalog_get()` usa `.get(field, '')` — suporta eventos sem `new-state` |

---

## 3. Arquivos Criados

| Arquivo | Descrição |
|---|---|
| `prodops/runtime/scripts/bootstrap-happy-path.sh` | Script de execução do Happy Path completo (15 eventos em sequência) |
| `prodops/runtime/datadog/create-dashboard.sh` | Script de criação do dashboard Datadog via API v1 |
| `prodops/artifacts/runtime/datadog-dashboard-definition.json` | Definição JSON do dashboard para import manual |
| `prodops/artifacts/experiments/013-runtime-validation/iteration-4-spec.md` | Spec original da Iteração 4 |

---

## 4. Eventos Adicionados ao Catálogo

| Evento Lógico | CE Type | Alters State | New State |
|---|---|---|---|
| `Delivery.Bootstrap.Started` | `prodops.delivery.bootstrap.started` | ✓ | BOOTSTRAPPING |
| `Delivery.Bootstrap.Completed` | `prodops.delivery.bootstrap.completed` | — | — |
| `Delivery.Hack.Started` | `prodops.delivery.hack.started` | ✓ | HACKING |
| `Delivery.Hack.Completed` | `prodops.delivery.hack.completed` | — | — |
| `Delivery.Sync.Started` | `prodops.delivery.sync.started` | ✓ | SYNCING |
| `Delivery.Sync.Completed` | `prodops.delivery.sync.completed` | — | — |
| `Delivery.Finish.Started` | `prodops.delivery.finish.started` | ✓ | FINISHING |
| `Delivery.Finish.Completed` | `prodops.delivery.finish.completed` | — | — |
| `Delivery.Ship.Started` | `prodops.delivery.ship.started` | ✓ | SHIPPING |
| `Delivery.Ship.Completed` | `prodops.delivery.ship.completed` | — | — |
| `Delivery.Validate.Started` | `prodops.delivery.validate.started` | ✓ | VALIDATING |
| `Shared.Gate.Passed` | `prodops.shared.gate.passed` | — | — |
| `Delivery.Validate.Completed` | `prodops.delivery.validate.completed` | — | — |
| `Delivery.Promote.Started` | `prodops.delivery.promote.started` | ✓ | PROMOTING |
| `Delivery.Promote.Completed` | `prodops.delivery.promote.completed` | ✓ | DONE |

**Estado anterior:** 1 evento | **Estado atual:** 15 eventos

---

## 5. Timeline Completa — `timelines/76.json`

Execução registrada em `2026-07-27` com `correlation-id: bea8ad98-9a23-4f26-9469-84bcb8346fc1`:

| # | CE Type | Timestamp | Alters State | State |
|---|---|---|---|---|
| 1 | `prodops.delivery.bootstrap.started` | 14:52:32Z | ✓ | BOOTSTRAPPING |
| 2 | `prodops.delivery.bootstrap.completed` | 14:52:42Z | — | BOOTSTRAPPING |
| 3 | `prodops.delivery.hack.started` | 14:52:45Z | ✓ | HACKING |
| 4 | `prodops.delivery.hack.completed` | 14:52:54Z | — | HACKING |
| 5 | `prodops.delivery.sync.started` | 14:52:57Z | ✓ | SYNCING |
| 6 | `prodops.delivery.sync.completed` | 14:53:06Z | — | SYNCING |
| 7 | `prodops.delivery.finish.started` | 14:53:10Z | ✓ | FINISHING |
| 8 | `prodops.delivery.finish.completed` | 14:53:18Z | — | FINISHING |
| 9 | `prodops.delivery.ship.started` | 14:53:22Z | ✓ | SHIPPING |
| 10 | `prodops.delivery.ship.completed` | 14:53:29Z | — | SHIPPING |
| 11 | `prodops.delivery.validate.started` | 14:53:32Z | ✓ | VALIDATING |
| 12 | `prodops.shared.gate.passed` | 14:53:40Z | — | VALIDATING |
| 13 | `prodops.delivery.validate.completed` | 14:53:43Z | — | VALIDATING |
| 14 | `prodops.delivery.promote.started` | 14:53:46Z | ✓ | PROMOTING |
| 15 | `prodops.delivery.promote.completed` | 14:53:53Z | ✓ | DONE |

Duração total: ~89 segundos (14:52:32Z → 14:54:01Z)

---

## 6. Derived State Final

```json
{
  "issue": "76",
  "state": "DONE",
  "last-event-type": "prodops.delivery.promote.completed",
  "runtime-correlation-id": "bea8ad98-9a23-4f26-9469-84bcb8346fc1",
  "runtime-version": "0.3.0",
  "framework-version": "1.0.0",
  "schema-version": "1",
  "computed-at": "2026-07-27T14:54:01Z"
}
```

---

## 7. GitHub Project — Estado Final

**Project:** [ProdOps — payments-api #25](https://github.com/orgs/produtoreativo/projects/25)

**Issue #76:** FTR-001: Invoice PIX — Happy Path Completo

| Campo | Valor Final |
|---|---|
| `oem-state` | `DONE` |
| `oem-last-event` | `prodops.delivery.promote.completed` |

**Sequência de sincs:** 8 atualizações de estado
```
BOOTSTRAPPING → HACKING → SYNCING → FINISHING → SHIPPING → VALIDATING → PROMOTING → DONE
```

*Nota: Screenshot/export do GitHub Project não capturado automaticamente — validação visual requer acesso ao browser.*

---

## 8. Datadog

**Métrica:** `runtime.event.received`
**Total de pontos enviados:** 15
**Tags presentes em todos os pontos:**
- `issue:76`
- `correlation-id:bea8ad98-9a23-4f26-9469-84bcb8346fc1`
- `service:payments-api`
- `env:development`
- `runtime:prodops`
- `event:<ce-type>` (distinto por evento)
- `state:<STATE>` (estado derivado no momento do envio)

**Dashboard:** definição salva em `datadog-dashboard-definition.json`. Import manual necessário (DD_APP_KEY não configurado):
```
Datadog → Dashboards → New Dashboard → (cog) → Import dashboard JSON
```

**Widgets definidos:**
- Nota com filtros de template variable ($correlation_id, $issue)
- Query Value: Total de eventos no período
- Toplist: Último estado por issue
- Toplist: Eventos por tipo
- Timeseries: Timeline de eventos (por CE type)
- Timeseries: Timeline de transições de estado

---

## 9. Gaps Encontrados

| Gap | Descrição | Severidade |
|---|---|---|
| G-1 | Dashboard Datadog não pode ser criado via API (DD_APP_KEY ausente) | Média — funcionalidade existe, credencial em falta |
| G-2 | `new-state: ""` aparece no CloudEvent payload para eventos com `alters-state: false` | Baixa — consumer ignora o campo quando `alters-state: false`; semanticamente correto |
| G-3 | GitHub sync não atualiza `oem-last-event` para eventos sem state change | Baixa — comportamento definido na spec; mas oem-last-event fica defasado entre estados |
| G-4 | Timeline não é deduplicada — re-execuções acumulam eventos | Média — re-execução do script gera 15 novos eventos sobre os 15 existentes |
| G-5 | Runtime Doctor não verifica saúde do catálogo (contagem de eventos) | Baixa — melhoria de observabilidade |
| G-6 | Screenshots do GitHub Project e Datadog não capturados automaticamente | Baixa — limitação de ambiente (sem browser headless) |

---

## 10. Ajustes Recomendados Antes da Iteração 5

| Ajuste | Prioridade | Justificativa |
|---|---|---|
| **Configurar DD_APP_KEY** para permitir criação de dashboard programática | Alta | Sem ela, o dashboard só pode ser criado manualmente |
| **Adicionar modo `--dry-run`** ao `bootstrap-happy-path.sh` para validar o catálogo sem executar | Média | Permite testar novos eventos sem side effects |
| **Implementar `--reset-timeline` flag** para controlar limpeza da timeline explicitamente | Média — G-4 | Evita acumulação acidental de eventos em re-execuções |
| **Sync GitHub para todos os eventos** (não só state-altering) para manter `oem-last-event` sempre atual | Baixa — G-3 | Tradeoff: mais chamadas GraphQL vs visibilidade maior |
| **Adicionar `oem-event-count`** como campo Text no GitHub Project | Baixa | Visibilidade do progresso sem abrir a timeline |
| **Expandir Runtime Doctor** para verificar catálogo mínimo (ex: ≥ 1 evento por Journey) | Baixa — G-5 | Previne execução com catálogo incompleto |
| **Executar o Happy Path para FTR-002 e FTR-003** com issues distintas | Alta — CS-01 | Valida que o Runtime opera múltiplas Features em paralelo |
