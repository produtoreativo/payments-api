# EXP-013 — Iteração 6: Operational Validation (Non-Uniform Execution)
# Relatório de Conclusão

**Data de execução:** 2026-07-27
**runtime-version:** 0.3.0
**Cenário:** Três Features em estados operacionais distintos e simultâneos
**Resultado:** ✅ NON-UNIFORM STATES CONFIRMED

---

## 1. Definition of Done — Verificação

| Critério | Status | Evidência |
|---|---|---|
| FTR-001 em DONE | ✅ | `derived-state-76.json` → state: DONE, 15 eventos |
| FTR-002 em VALIDATING | ✅ | `derived-state-77.json` → state: VALIDATING, 11 eventos |
| FTR-003 em HACKING | ✅ | `derived-state-78.json` → state: HACKING, 3 eventos |
| GitHub Project com oem-state correto por Issue | ✅ | #76=DONE, #77=VALIDATING, #78=HACKING |
| GitHub Project com oem-last-event correto por Issue | ✅ | Cada Issue com CE type do último evento recebido |
| Nenhum estado de uma Feature contaminou outra | ✅ | Timeline subjects isolados; correlation-ids distintos |
| Datadog filtrável por issue e correlation-id | ✅ | Tags presentes em todos os 29 pontos enviados |
| Nenhum novo componente criado | ✅ | Apenas `bootstrap-non-uniform.sh` adicionado |

---

## 2. Arquivos Criados

| Arquivo | Descrição |
|---|---|
| `prodops/runtime/scripts/bootstrap-non-uniform.sh` | Script de execução não-uniforme — 3 Features com sequências distintas |

Nenhum arquivo de infraestrutura modificado.

---

## 3. Snapshot Operacional Final

| Issue | Feature | Estado | Eventos | Correlation ID | Last Event Type |
|---|---|---|---|---|---|
| #76 | FTR-001: Invoice PIX | **DONE** | 15 | `0e56fc53-e32d-4040-8423-0f5bdf0541d0` | `prodops.delivery.promote.completed` |
| #77 | FTR-002: Invoice Cartão | **VALIDATING** | 11 | `48155e7f-b80b-4f98-9646-4a3b23f992fe` | `prodops.delivery.validate.started` |
| #78 | FTR-003: Confirmação Pagamento | **HACKING** | 3 | `f35032c9-168d-4367-a417-3b4c0cc79360` | `prodops.delivery.hack.started` |

---

## 4. Evidências por Feature

### FTR-001 — Issue #76 — DONE

```json
{
  "issue": "76",
  "state": "DONE",
  "last-event-type": "prodops.delivery.promote.completed",
  "runtime-correlation-id": "0e56fc53-e32d-4040-8423-0f5bdf0541d0",
  "computed-at": "2026-07-27T15:21:04Z"
}
```

Timeline: 15 eventos (15:19:43Z → 15:21:04Z) | GitHub: `oem-state=DONE`

### FTR-002 — Issue #77 — VALIDATING

```json
{
  "issue": "77",
  "state": "VALIDATING",
  "last-event-type": "prodops.delivery.validate.started",
  "runtime-correlation-id": "48155e7f-b80b-4f98-9646-4a3b23f992fe",
  "computed-at": "2026-07-27T15:22:05Z"
}
```

Timeline: 11 eventos (15:21:10Z → 15:22:05Z) | GitHub: `oem-state=VALIDATING`

### FTR-003 — Issue #78 — HACKING

```json
{
  "issue": "78",
  "state": "HACKING",
  "last-event-type": "prodops.delivery.hack.started",
  "runtime-correlation-id": "f35032c9-168d-4367-a417-3b4c0cc79360",
  "computed-at": "2026-07-27T15:22:23Z"
}
```

Timeline: 3 eventos (15:22:11Z → 15:22:23Z) | GitHub: `oem-state=HACKING`

---

## 5. GitHub Project — Estado Simultâneo

**Project:** [ProdOps — payments-api #25](https://github.com/orgs/produtoreativo/projects/25)

As três Issues aparecem simultaneamente no Project com estados distintos:

| Issue | oem-state | oem-last-event |
|---|---|---|
| #76 | DONE | prodops.delivery.promote.completed |
| #77 | VALIDATING | prodops.delivery.validate.started |
| #78 | HACKING | prodops.delivery.hack.started |

*Validação visual: github.com/orgs/produtoreativo/projects/25 — as três Issues coexistem nas Views existentes com estados operacionais distintos.*

---

## 6. Datadog

**Pontos enviados nesta execução:** 29 (15 para #76 + 11 para #77 + 3 para #78)
**Métrica:** `runtime.event.received`

Para filtrar cada Feature no dashboard:
- FTR-001: `issue:76` + `correlation-id:0e56fc53-e32d-4040-8423-0f5bdf0541d0`
- FTR-002: `issue:77` + `correlation-id:48155e7f-b80b-4f98-9646-4a3b23f992fe`
- FTR-003: `issue:78` + `correlation-id:f35032c9-168d-4367-a417-3b4c0cc79360`

Para ver o snapshot operacional (todas as Features): `state:DONE`, `state:VALIDATING`, `state:HACKING` nos filtros da toplist "Último Estado por Issue".

---

## 7. Experiment Findings (apenas novos)

### Runtime Findings

Nenhum novo finding. Os findings RF-1 a RF-4 documentados na Iteração 5 permanecem válidos e sem regressões nesta iteração.

### Framework Findings

| ID | Encontrado | Implicação |
|---|---|---|
| FF-6 | **O estado operacional de uma Feature é completamente independente do número de eventos** — FTR-003 com 3 eventos em HACKING é tão válido quanto FTR-001 com 15 eventos em DONE | A Timeline é append-only e a regra "último evento com alters-state=true" funciona corretamente para qualquer comprimento de Timeline |
| FF-7 | **Parar uma Feature em qualquer ponto do Happy Path não deixa estado corrompido** — o Derived State reflete o ponto exato de parada, sem necessidade de evento "cancelamento" ou "pausa" | O modelo de Event Sourcing com Derived State é resiliente por design: qualquer corte temporal produz um estado consistente |
| FF-8 | **O GitHub Project é uma View do estado derivado, não uma fonte de verdade** — se o oem-state no Project for manualmente alterado, a Timeline permanece correta e o Derived State pode ser recomputado | A separação entre Timeline (imutável) e Project (View) é arquiteturalmente sólida |
| FF-9 | **Nenhum mecanismo de coordenação foi necessário para Features em estados distintos** — o isolamento por `issue` como chave primária é suficiente | Não há necessidade de locks, semáforos, ou coordenação entre Features. O modelo escala horizontalmente por design |

### External Findings

Nenhum novo finding externo. Os findings EF-1 a EF-4 documentados na Iteração 5 permanecem válidos.

---

## 8. Limitações

| Limitação | Severidade | Contexto |
|---|---|---|
| Screenshot automático do GitHub Project não disponível (sem browser headless) | Baixa — evidência visual manual necessária | Limitação de ambiente, não do Runtime |
| Dashboard Datadog requer import manual (DD_APP_KEY ausente) | Média | Pendente desde Iteração 4 |
| `derive-state.sh` escala O(n) com o tamanho da timeline — sem indexação | Baixa — irrelevante no escopo do experimento | Limite prático: centenas de eventos por Feature |
| Execução sequencial entre Features — não concorrência real por thread | Baixa — validado logicamente; o código é reentrante | Para concorrência real: bash `&` + `wait` |

---

## 9. Avaliação do EXP-013 — Objetivo Principal Atingido?

### Objetivo declarado do experimento

> *Validar que o ProdOps Runtime implementado é capaz de acompanhar Features ao longo de sua jornada operacional, mantendo sincronizados CloudEvents, Timeline, Derived State, GitHub Project e Datadog.*

### Avaliação por critério

| Critério | Status | Evidência |
|---|---|---|
| CloudEvents 1.0 como contrato de evento | ✅ ATINGIDO | Todas as iterações (3 a 6) — 9 campos obrigatórios, validator PASS em 100% dos eventos |
| Timeline append-only por Feature | ✅ ATINGIDO | 3 timelines isoladas, nunca contaminadas entre Features |
| Derived State computado corretamente | ✅ ATINGIDO | "último alters-state=true wins" — funciona para sequências completas e parciais |
| GitHub Project sincronizado em tempo real | ✅ ATINGIDO | oem-state e oem-last-event corretos para 3 Features em estados distintos |
| Datadog com observabilidade filtrável | ✅ ATINGIDO | 109 pontos totais enviados (Iter 3+4+5+6); filtros por issue, correlation-id, state |
| Múltiplas Features simultâneas e independentes | ✅ ATINGIDO | Iterações 5 e 6 demonstram isolamento completo |
| Happy Path completo (Bootstrap → DONE) | ✅ ATINGIDO | 3 execuções completas do Happy Path de 15 eventos |
| Execução não-uniforme (Features em estados distintos) | ✅ ATINGIDO | DONE / VALIDATING / HACKING simultaneamente — Iteração 6 |

### Lacunas remanescentes antes do encerramento

| Lacuna | Impacto no experimento | Criticidade |
|---|---|---|
| Dashboard Datadog não criado via API (DD_APP_KEY) | Screenshots manuais não capturados; evidência visual parcial | **Média** — Dashboard foi definido (JSON disponível); métricas chegam ao Datadog corretamente |
| Screenshots do GitHub Project não automatizados | Validação visual requer acesso ao browser | **Baixa** — o Project contém os dados corretos; validação é visual |
| Execução paralela real (bash `&`) não testada | A concorrência lógica foi validada; a real não | **Baixa** — irrelevante para o objetivo do experimento |
| Cenários de falha parcial (evento emitido mas GitHub offline) não testados | Resiliência a falhas externas | **Baixa** — fora do escopo definido nas restrições |

### Conclusão

**O objetivo principal do EXP-013 foi atingido.**

A partir desta iteração é possível afirmar:

1. O **ProdOps Runtime** implementado em shell script puro (bash + jq + python3 + gh CLI) é capaz de gerenciar o ciclo de vida operacional de múltiplas Features independentes.

2. O **CloudEvents 1.0** como contrato de evento provou-se suficiente para transportar o payload OEM sem necessidade de extensões proprietárias.

3. A **Timeline por issue** é o mecanismo correto de isolamento — nenhuma Feature contaminou outra em nenhuma das 6 iterações.

4. O **Derived State** por projeção (Event Sourcing básico) é resiliente e recomputável a partir da Timeline a qualquer momento.

5. O **GitHub Project** como View do estado operacional funciona como canal de visibilidade para Product Managers e Stakeholders sem acesso aos logs.

6. O **Datadog** como plano de observabilidade com filtros por `issue` e `correlation-id` permite rastreabilidade de ponta a ponta de cada execução.

---

## 10. Recomendações Pós-EXP-013

Se o Runtime for utilizado em produção ou em um experimento posterior:

| Recomendação | Motivação |
|---|---|
| Configurar `DD_APP_KEY` para automatizar criação do dashboard | Completa a evidência visual do Datadog |
| Adicionar `oem-correlation-id` como campo no GitHub Project | Fecha rastreabilidade GitHub → Datadog sem logs |
| Implementar `--reset-timeline` e `--dry-run` nos scripts | Previne acumulação de eventos em re-execuções |
| Explorar execução real paralela com `bash &` + `wait` | Valida escalabilidade horizontal — próxima evolução natural |
| Considerar um JSON Schema Registry real para `dataschema` URI | Torna o contrato verificável por ferramentas externas |
| Avaliar migração para um Event Bus real (quando o volume justificar) | O experimento demonstra que o modelo funciona; a infraestrutura bash tem limitações de escala |
