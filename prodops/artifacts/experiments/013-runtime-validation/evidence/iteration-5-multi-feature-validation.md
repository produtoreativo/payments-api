# EXP-013 — Iteração 5: Multi-Feature Runtime Validation
# Relatório de Conclusão

**Data de execução:** 2026-07-27
**runtime-version:** 0.3.0
**Features validadas:** FTR-001 (#76), FTR-002 (#77), FTR-003 (#78)
**Total de eventos:** 45 (15 por Feature)
**Resultado:** ✅ TODAS AS TRÊS FEATURES CHEGARAM A DONE

---

## 1. Definition of Done — Verificação

| Critério | Status | Evidência |
|---|---|---|
| Cada Timeline contém apenas eventos da sua Feature | ✅ | `subject` único por timeline: #76→76, #77→77, #78→78 |
| Cada Derived State evolui independentemente | ✅ | 3 arquivos `derived-state-{issue}.json` — correlation-ids distintos |
| Cada Issue possui `oem-state=DONE` no GitHub Project | ✅ | 3 syncs de DONE: #76, #77, #78 |
| `oem-last-event` correto para cada Issue | ✅ | `prodops.delivery.promote.completed` nas três Issues |
| Datadog filtrável por `issue` | ✅ | Tag `issue:<number>` presente em todos os pontos |
| Datadog filtrável por `runtime-correlation-id` | ✅ | Tag `correlation-id:<uuid>` por Feature |
| Mesma infraestrutura das iterações anteriores | ✅ | Sem novos componentes — apenas `bootstrap-multi-feature.sh` e update em `derive-state.sh` |

---

## 2. Arquivos Modificados

| Arquivo | Mudança |
|---|---|
| `prodops/runtime/consumer/derive-state.sh` | Escreve também em `derived-state-${ISSUE}.json` (além do `derived-state.json` existente) |

---

## 3. Arquivos Criados

| Arquivo | Descrição |
|---|---|
| `prodops/runtime/scripts/bootstrap-multi-feature.sh` | Script de execução intercalada para 3 Features |
| `prodops/artifacts/runtime/timelines/77.json` | Timeline de FTR-002 (15 CloudEvents) |
| `prodops/artifacts/runtime/timelines/78.json` | Timeline de FTR-003 (15 CloudEvents) |
| `prodops/artifacts/runtime/derived-state-76.json` | Derived State isolado para FTR-001 |
| `prodops/artifacts/runtime/derived-state-77.json` | Derived State isolado para FTR-002 |
| `prodops/artifacts/runtime/derived-state-78.json` | Derived State isolado para FTR-003 |

---

## 4. Resultados por Feature

### FTR-001 — Issue #76 — Invoice PIX — Happy Path Completo

| Campo | Valor |
|---|---|
| Estado Final | DONE |
| Eventos | 15 |
| Correlation ID | `b8b95031-8464-4c9f-aeed-9705670d8b76` |
| Timeline | `timelines/76.json` |
| Derived State | `derived-state-76.json` |
| GitHub | `oem-state=DONE` / `oem-last-event=prodops.delivery.promote.completed` |

### FTR-002 — Issue #77 — Invoice Cartão — Happy Path sem PAN

| Campo | Valor |
|---|---|
| Estado Final | DONE |
| Eventos | 15 |
| Correlation ID | `af34814e-a5d1-4260-8754-c35d0a3f64e4` |
| Timeline | `timelines/77.json` |
| Derived State | `derived-state-77.json` |
| GitHub | `oem-state=DONE` / `oem-last-event=prodops.delivery.promote.completed` |

### FTR-003 — Issue #78 — Confirmação de Pagamento — Webhook

| Campo | Valor |
|---|---|
| Estado Final | DONE |
| Eventos | 15 |
| Correlation ID | `177e5bb0-007a-4c09-aa81-df8afff652cd` |
| Timeline | `timelines/78.json` |
| Derived State | `derived-state-78.json` |
| GitHub | `oem-state=DONE` / `oem-last-event=prodops.delivery.promote.completed` |

---

## 5. Sequência Intercalada Executada

A execução seguiu o padrão intercalado: cada passo do Happy Path foi emitido para as 3 Features antes de avançar ao próximo passo.

| Step | Evento | #76 | #77 | #78 |
|---|---|---|---|---|
| 1 | Delivery.Bootstrap.Started | BOOTSTRAPPING | BOOTSTRAPPING | BOOTSTRAPPING |
| 2 | Delivery.Bootstrap.Completed | BOOTSTRAPPING | BOOTSTRAPPING | BOOTSTRAPPING |
| 3 | Delivery.Hack.Started | HACKING | HACKING | HACKING |
| 4 | Delivery.Hack.Completed | HACKING | HACKING | HACKING |
| 5 | Delivery.Sync.Started | SYNCING | SYNCING | SYNCING |
| 6 | Delivery.Sync.Completed | SYNCING | SYNCING | SYNCING |
| 7 | Delivery.Finish.Started | FINISHING | FINISHING | FINISHING |
| 8 | Delivery.Finish.Completed | FINISHING | FINISHING | FINISHING |
| 9 | Delivery.Ship.Started | SHIPPING | SHIPPING | SHIPPING |
| 10 | Delivery.Ship.Completed | SHIPPING | SHIPPING | SHIPPING |
| 11 | Delivery.Validate.Started | VALIDATING | VALIDATING | VALIDATING |
| 12 | Shared.Gate.Passed | VALIDATING | VALIDATING | VALIDATING |
| 13 | Delivery.Validate.Completed | VALIDATING | VALIDATING | VALIDATING |
| 14 | Delivery.Promote.Started | PROMOTING | PROMOTING | PROMOTING |
| 15 | Delivery.Promote.Completed | **DONE** | **DONE** | **DONE** |

---

## 6. Isolamento de Timeline — Verificação

Cada arquivo de timeline contém exclusivamente eventos do seu `subject` (issue number):

```
timelines/76.json → único subject: "76" (15 eventos)
timelines/77.json → único subject: "77" (15 eventos)
timelines/78.json → único subject: "78" (15 eventos)
```

Nenhum evento de uma Feature contaminou a timeline de outra.

---

## 7. Derived State — Verificação de Independência

Os três `runtime-correlation-id` são distintos, confirmando que cada Feature tem rastreabilidade própria:

```json
#76: "runtime-correlation-id": "b8b95031-8464-4c9f-aeed-9705670d8b76"
#77: "runtime-correlation-id": "af34814e-a5d1-4260-8754-c35d0a3f64e4"
#78: "runtime-correlation-id": "177e5bb0-007a-4c09-aa81-df8afff652cd"
```

Todos chegaram a `"state": "DONE"` de forma independente.

---

## 8. GitHub Project

**Project:** [ProdOps — payments-api #25](https://github.com/orgs/produtoreativo/projects/25)

As três Issues foram adicionadas ao projeto e tiveram seus campos atualizados nas 8 transições de estado (Bootstrap.Started, Hack.Started, Sync.Started, Finish.Started, Ship.Started, Validate.Started, Promote.Started, Promote.Completed).

| Issue | Título | oem-state | oem-last-event |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX | DONE | prodops.delivery.promote.completed |
| #77 | FTR-002: Invoice Cartão | DONE | prodops.delivery.promote.completed |
| #78 | FTR-003: Confirmação Pagamento | DONE | prodops.delivery.promote.completed |

*Screenshot visual: validação manual necessária via browser em github.com/orgs/produtoreativo/projects/25*

---

## 9. Datadog

**Métrica:** `runtime.event.received`
**Total de pontos enviados nesta execução:** 45

**Filtragem disponível:**
- Por Feature: tag `issue:76`, `issue:77`, `issue:78`
- Por execução: tag `correlation-id:<uuid>` por Feature

**Dashboard:** `prodops/artifacts/runtime/datadog-dashboard-definition.json`
Contém template variables `$correlation_id` e `$issue` — import manual necessário (DD_APP_KEY não disponível).

---

## 10. Experiment Findings

### Runtime Findings

| ID | Encontrado | Impacto |
|---|---|---|
| RF-1 | `derive-state.sh` escrevia em um único arquivo `derived-state.json` — incompatível com multi-feature | Médio — um único arquivo seria sobrescrito pela última Feature a rodar. Resolvido: escreve também em `derived-state-${ISSUE}.json` |
| RF-2 | `catalog_get()` com campo ausente lançava KeyError (Python) — bloqueia eventos sem `new-state` | Médio — corrigido na Iteração 4 com `.get(field, '')`. Evento com `alters-state: false` retorna `new-state: ""` no CE payload |
| RF-3 | Re-execução do script acumula eventos na timeline (sem deduplicação por CE `id`) | Baixo — re-execução dos scripts de iterações anteriores (3/4) gera eventos extras sobre a timeline existente |
| RF-4 | GitHub sync faz 8 chamadas GraphQL por Feature por estado (total: 24 syncs nesta iteração) | Baixo — custo esperado para validação; não é problema em experimento |

### Framework Findings

| ID | Encontrado | Implicação |
|---|---|---|
| FF-1 | **O modelo de Timeline por issue é naturalmente isolado** — nenhum evento "vazou" entre Features. O `subject` como discriminador de timeline é suficiente | A separação por `subject` é o design correto. Não é necessária uma chave composta ou namespace adicional |
| FF-2 | **O `runtime-correlation-id` per Feature é o mecanismo correto de rastreabilidade** — permite filtrar uma execução completa no Datadog sem ambiguidade | O correlation-id resolve o "de onde veio este evento" mesmo quando múltiplas Features rodam em paralelo |
| FF-3 | **O Derived State é stateless por design** — re-computado a partir da Timeline. Isso torna o sistema resiliente: um estado corrompido pode ser recuperado relendo a Timeline | A Timeline é a source of truth; o Derived State é uma projeção. Esse padrão é Event Sourcing básico |
| FF-4 | **A execução intercalada demonstra que o Runtime não possui estado global** — cada script opera sobre o `issue` recebido como argumento, sem variáveis globais compartilhadas | O Runtime é stateless. Isso permite execução paralela futura sem conflitos de estado |
| FF-5 | **Todos os 15 eventos do catálogo foram validados 3 vezes cada**, incluindo `Shared.Gate.Passed` (journey "Shared" — cross-cutting). O catálogo e o validator funcionam independentemente do journey | Eventos cross-cutting (Shared) podem ser adicionados ao catálogo sem alterações no validator ou producer |

### External Findings

| ID | Encontrado | Impacto |
|---|---|---|
| EF-1 | **Datadog Dashboard API requer DD_APP_KEY** (Application Key) — não disponível no ambiente | Médio — dashboard precisa ser importado manualmente. A definição JSON está disponível |
| EF-2 | **GitHub Projects v2 SingleSelect não é atualizado em tempo real no browser** — demora alguns segundos após o sync GraphQL | Baixo — comportamento esperado da UI GitHub; os dados estão corretos na API |
| EF-3 | **GitHub Projects v2 `addProjectV2ItemById` é idempotente** — adicionar a mesma issue duas vezes retorna o mesmo `item.id` | Positivo — o sync.sh pode ser chamado múltiplas vezes sem criar duplicatas no Project |
| EF-4 | **Taxa de chamadas GraphQL do GitHub** — 24 syncs de estado em ~4 minutos não atingiu rate limit. O padrão atual é seguro para o volume do experimento | Baixo — sem preocupações para as iterações dentro do experimento |

---

## 11. Limitações Encontradas

| Limitação | Severidade |
|---|---|
| Execução sequencial (feature por feature dentro de cada step) — não paralelismo real | Baixa — o experimento valida isolamento lógico, não performance |
| Dashboard Datadog criado manualmente (sem DD_APP_KEY para API) | Média — operacional, mas requer step manual |
| Screenshots do GitHub Project e Datadog não capturados programaticamente | Baixa — evidência visual requer acesso ao browser |
| Timeline acumula eventos em re-execuções | Média — os scripts resetam a timeline no início do multi-feature, mas risco em uso ad hoc |

---

## 12. Recomendações para a Iteração 6

| Recomendação | Prioridade | Motivação |
|---|---|---|
| **Configurar DD_APP_KEY** e automatizar criação do dashboard | Alta | EF-1 — dashboard é evidência visual necessária |
| **Adicionar `--dry-run` e `--reset-timeline` flags** nos scripts | Média — RF-3 | Controle explícito de re-execuções |
| **Explorar execução paralela** (bash `&` + `wait`) para simular features realmente concorrentes | Média — FF-4 | Valida que o Runtime é thread-safe na prática |
| **Adicionar `oem-correlation-id` como campo Text no GitHub Project** | Média — FF-2 | Fecha rastreabilidade GitHub → Datadog sem precisar dos logs |
| **Implementar `runtime-doctor.sh` check de timelines existentes** (quantas features ativas, estado atual) | Baixa — FF-3 | Visibilidade operacional sem executar o happy path |
| **Explorar cenários não-uniformes**: uma Feature em HACKING, outra em SHIPPING | Alta | Demonstra que o Runtime não confunde estados entre Features |
