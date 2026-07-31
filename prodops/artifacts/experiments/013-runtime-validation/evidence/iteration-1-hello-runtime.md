# EXP-013 — Iteração 1: Hello Runtime
# Relatório de Conclusão

**Data de execução:** 2026-07-27
**Feature piloto:** Issue #76 — FTR-001: Invoice PIX — Happy Path Completo
**Evento executado:** `Delivery.Bootstrap.Started`
**Resultado:** ✅ Todos os 5 passos completados com sucesso

---

## 1. Arquitetura Criada

O fluxo implementado é estritamente linear — sem bus, sem replay, sem plugins:

```
runtime emit
    │
    ▼
producer/emit.sh
    │  (JSON do evento)
    ▼
timeline/append.sh
    │  (76.json atualizado)
    ▼
consumer/derive-state.sh
    │  (derived-state.json)
    ▼
github/sync.sh
    │  (GitHub Project #25 atualizado)
    ▼
datadog/send.sh
    │  (HTTP 202 da Datadog API)
    ▼
bootstrap-runtime.sh (resumo)
```

Todos os componentes são scripts bash independentes. O orquestrador (`bootstrap-runtime.sh`) é o único ponto de composição.

---

## 2. Arquivos Adicionados

### Runtime (implementação)

| Caminho | Função |
|---|---|
| `prodops/runtime/producer/emit.sh` | Event Producer — gera JSON com id, occurred_at, event, journey, cycle, phase, alters_state, new_state |
| `prodops/runtime/timeline/append.sh` | Timeline — append-only em `artifacts/runtime/timelines/<issue>.json` |
| `prodops/runtime/consumer/derive-state.sh` | Derived State — último `alters_state=true` determina o estado |
| `prodops/runtime/github/sync.sh` | GitHub Sync — adiciona issue ao projeto, cria campos se ausentes, atualiza `oem state` e `oem last-event` |
| `prodops/runtime/datadog/send.sh` | Datadog — publica `runtime.event.received` via Datadog HTTP API v2 `/api/v2/series` |
| `prodops/runtime/scripts/bootstrap-runtime.sh` | Orquestrador — executa os 5 passos e imprime resumo |

### Evidências (geradas pelo script)

| Caminho | Conteúdo |
|---|---|
| `prodops/artifacts/runtime/timelines/76.json` | Timeline do issue #76 (array JSON append-only) |
| `prodops/artifacts/runtime/derived-state.json` | Último estado derivado do issue #76 |
| `prodops/artifacts/runtime/runtime.log` | Log completo de execução |
| `prodops/artifacts/runtime/github-sync.log` | Log detalhado da sincronização GitHub |
| `prodops/artifacts/runtime/datadog.log` | Log da publicação Datadog |

### Documentação

| Caminho | Conteúdo |
|---|---|
| `prodops/artifacts/experiments/013-runtime-validation/evidence/iteration-1-hello-runtime.md` | Este relatório |

---

## 3. Decisões Tomadas

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Implementar em bash puro | Node.js / TypeScript | Sem dependências, sem build, alinha com restrição "faça apenas funcionar" |
| Usar Datadog HTTP API v2 `/series` | DogStatsD UDP (porta 8125) | DogStatsD requer agente local rodando — HTTP API funciona diretamente com a API key |
| Usar GitHub Project #25 ("ProdOps — payments-api") | Criar novo projeto | Projeto já existia; reutilização imediata sem provisionamento |
| Nomear campos do GitHub com espaço (`oem state`) | Usar colons (`oem:state`) | GitHub Projects rejeita colons em nomes de campos (GraphQL error `createProjectV2Field`) |
| Criar os campos no script se ausentes | Exigir pré-provisionamento | Reduz fricção operacional; o sync é idempotente |
| Feature piloto: Issue #76 | Qualquer outro issue | Primeiro issue da lista com estado limpo; FTR-001 é o happy path canônico |

---

## 4. Limitações Conhecidas

| Limitação | Escopo | Impacto |
|---|---|---|
| Apenas 1 evento suportado (`Delivery.Bootstrap.Started`) | producer/emit.sh | Não é possível avançar para outros ciclos sem adicionar cases |
| Timeline não é idempotente — re-execução duplica eventos | timeline/append.sh | Rodar o script duas vezes cria 2 registros para o mesmo momento |
| GitHub sync sem verificação de drift — sempre escreve | github/sync.sh | Não detecta se o campo já tem o valor correto antes de atualizar |
| Datadog usa API Key do `.env` — não há fallback | datadog/send.sh | Se o arquivo não existir no caminho relativo esperado, falha com erro claro |
| Sem testes — funciona apenas pelo happy path | todo o runtime | Qualquer alteração pode quebrar silenciosamente |
| Campos criados com nomes alternativos (espaço em vez de colon) | github/sync.sh | Os campos criados no GitHub (ex.: `oem state`) diferem do nome canônico da COR (`oem:state`) |

---

## 5. Dívida Técnica Criada

| Débito | Onde | Custo estimado de remover |
|---|---|---|
| Caminho relativo hardcoded para `api/.env` no `send.sh` | `datadog/send.sh:15` | Pequeno — parametrizar ou usar variável de ambiente |
| PROJECT_NUMBER hardcoded como `25` | `github/sync.sh:12` | Pequeno — extrair para configuração |
| Nenhum lock no append da Timeline | `timeline/append.sh` | Médio — concorrência não é problema agora, mas será em Iteração 2+ |
| Sem log estruturado (só texto plano) | todos os scripts | Médio — logs em JSON seriam consultáveis; desnecessário nesta iteração |
| Campos GitHub criados com nome alternativo sem registro canônico | `github/sync.sh` | Pequeno — documentar mapeamento `oem:state` → `oem state` na COR |

---

## 6. Sugestões para a Iteração 2

As sugestões abaixo são ordenadas por valor de aprendizado — não por esforço.

### 2.1 Adicionar mais eventos ao producer

Expandir `emit.sh` para suportar pelo menos:
- `Delivery.Hack.Started` → `HACKING`
- `Delivery.Hack.Completed` → `FINISHING`
- `Delivery.Promote.Completed` → `DONE`

Isso permitirá observar uma Feature percorrendo múltiplos estados na Timeline e validando Q2 (Derived State suficiente para representar o estado em qualquer ponto).

### 2.2 Tornar a Timeline idempotente por execução

Adicionar um `run_id` ao evento (ex.: hash do `id` + `issue`) e checar duplicatas antes de append. Simples, mas remove o ruído de re-execuções.

### 2.3 Adicionar detecção de drift ao sync GitHub

Antes de chamar a mutation de atualização, ler o valor atual do campo e comparar. Só escrever se diferente. Isso valida Q4 (GitHub como COR passiva) de forma mais rigorosa.

### 2.4 Rodar o fluxo completo para as 3 Features

Usar FTR-001 (#76), FTR-002 (#77), FTR-003 (#78) com eventos distribuídos. Isso começa a validar CS-01 (três Features com Timelines registradas).

### 2.5 Adicionar métrica de Cycle Time ao Datadog

Calcular `cycle_time_seconds` entre o primeiro `alters_state=true` e o último, e publicar como métrica. Isso valida CS-07 (métrica derivada da Timeline visível no Datadog).

---

## 7. Definition of Done — Verificação

| Critério | Status | Evidência |
|---|---|---|
| ✅ Um evento criado | **Passou** | `timelines/76.json` contém 1 evento `Delivery.Bootstrap.Started` |
| ✅ Timeline persistida | **Passou** | `timelines/76.json` (append-only, formato JSON) |
| ✅ Derived State calculado | **Passou** | `derived-state.json`: `state: BOOTSTRAPPING` |
| ✅ GitHub Project atualizado | **Passou** | Campos `oem state=BOOTSTRAPPING`, `oem last-event=Delivery.Bootstrap.Started` no Project #25 |
| ✅ Evento visível no Datadog | **Passou** | HTTP 202 da Datadog API v2 — métrica `runtime.event.received` com tags `issue:76`, `event:Delivery.Bootstrap.Started`, `state:BOOTSTRAPPING` |

---

## 8. Como Visualizar no Datadog

1. Acesse [app.datadoghq.com/metric/explorer](https://app.datadoghq.com/metric/explorer)
2. Busque a métrica: `runtime.event.received`
3. Filtre por tag: `issue:76`
4. O ponto de dados aparece no timestamp de execução (~13:44 UTC em 2026-07-27)

Tags disponíveis para filtrar:
- `issue:76`
- `event:Delivery.Bootstrap.Started`
- `state:BOOTSTRAPPING`
- `service:payments-api`
- `env:development`
- `runtime:prodops`

---

## 9. Próximo Passo

Encerrar Iteração 1. Iniciar Iteração 2 apenas com alinhamento explícito do objetivo — sugestão: expandir para múltiplos eventos e múltiplas Features (ver seção 6).
