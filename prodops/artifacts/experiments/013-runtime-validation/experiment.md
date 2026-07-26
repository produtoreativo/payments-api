# EXP-013 — Validate the ProdOps Operational Runtime

## Status

- [x] Planned
- [x] In Progress
- [ ] Completed
- [ ] Cancelled

**Business Signal:** [`BS-RUNTIME-001`](../../business-signals/BS-RUNTIME-001.md)
**Product Intent:** [`PI-RUNTIME-001`](../../business-intents/PI-RUNTIME-001.md)

---

# Business Goal

Determinar se o modelo arquitetural atual do ProdOps Framework é suficiente para executar uma Iteration real com Runtime, Delivery, Diligence, GitHub COR e Datadog sincronizados — sem necessidade de alterações estruturais no Framework.

O payments-api é o produto de referência. O objetivo não é implementar o Runtime de forma definitiva — é validar a hipótese que sustenta PI-RUNTIME-001 antes de qualquer compromisso (OBC).

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Comportamento da Payments API (produto de referência da validação)
- [x] Lógica de domínio de Payments (Work Items reais para a Timeline)
- [x] Contrato de API/evento de propriedade do Payments
- [x] Testes locais ou evidência executável

## Dependências externas

- **GitHub Projects** — workspace do payments-api (já reconciliado) como Canonical Operational Representation (COR)
- **Datadog** — recepção de métricas derivadas da Timeline (configurado em EXP-005 e EXP-010)
- **ProdOps Framework** — OEM, Shared Types, Skills de Delivery e Diligence (não alterados por este experimento)

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório
- [ ] Registrar apenas como dependência externa ou risco de release
- [ ] Redirecionar para repositório ou time responsável

---

# Hipótese Principal

> **O Runtime consegue manter Runtime, Timeline, GitHub COR e Datadog sincronizados durante uma Iteration completa utilizando apenas os conceitos atualmente consolidados no Framework — sem necessidade de alterações estruturais no OEM, nos catálogos de Journey, nos Shared Types ou na COR?**

Esta hipótese é testável: o experimento executa uma Iteration real e observa o comportamento de cada componente. Se todos os componentes funcionarem conforme especificado, a hipótese é confirmada. Se qualquer componente exigir um conceito arquitetural novo (não um ajuste operacional), a hipótese é refutada.

---

# Perguntas do Experimento

| # | Pergunta | Categoria | Status |
|---|---|---|---|
| Q1 | O OEM é suficiente para registrar todos os eventos de uma Iteration real? | Framework | Pendente |
| Q2 | O Derived State é suficiente para representar o estado operacional de um Work Item a qualquer ponto no tempo? | OEM | Pendente |
| Q3 | A Timeline pode ser reconstruída (Replay) apenas pelos eventos registrados, sem estado externo? | OEM | Pendente |
| Q4 | O GitHub Projects permanece apenas como COR (leitura de estado derivado) sem precisar tornar-se fonte de verdade? | COR | Pendente |
| Q5 | A Diligence Journey consegue reconciliar todo o fluxo de conformidade de Work Items reais? | Journey | Pendente |
| Q6 | As métricas operacionais (Lead Time, Cycle Time, Block Time, Gate Failure Rate) podem ser derivadas exclusivamente dos eventos da Timeline? | Métricas | Pendente |
| Q7 | Os Shared Types (Gate.Passed, Gate.Failed, Impediment.Declared) são suficientes para os eventos transversais de uma Iteration? | Shared Types | Pendente |
| Q8 | O Runtime exige novos conceitos arquiteturais não previstos no Framework atual? | Arquitetura | Pendente |

---

# Objectives

## O que será validado

- **Runtime operacional end-to-end:** Skills de Delivery executadas por um time real, registrando Event Instances em Timelines reais
- **Delivery Journey completa:** pelo menos uma Iteration com Timeline desde Bootstrap.Started até Promote.Completed, incluindo cenários de Rework e Blocking
- **Diligence Journey completa:** ciclo Sync (Capture → Attach → Promote → Close) + ciclo Async (Scan → Flag → Repair) com Timeline registrada
- **GitHub COR sincronizado:** Custom Fields do GitHub Projects refletindo o último Derived State calculado a partir da Timeline
- **Derived State calculado:** Consumer calculando estado corretamente a partir da Timeline para Work Items históricos e ativos
- **Lookback em condição real:** pelo menos um cenário de Impediment.Resolved com Lookback executado corretamente
- **Datadog com métricas derivadas:** pelo menos uma métrica (ex.: Cycle Time de uma Iteration) visível no Datadog com trace rastreável até eventos da Timeline
- **Drift detectado pela Diligence:** pelo menos um cenário de divergência detectado pelo ciclo Async e reparado

## O que deliberadamente NÃO será validado nesta etapa

- Multiple repositórios ou múltiplos produtos
- Discovery Journey (EXP apenas — sem a Journey formal)
- Operation Journey (incidentes, SLOs em produção)
- Sincronização com Jira ou outras ferramentas externas
- Generalização do Runtime para outros produtos
- Assessment Journey com ciclo completo (Collect → Analyze → Synthesize → Report)
- Automação completa do Consumer de Derived State (pode ser manual/script neste EXP)
- Shared Types v1.1.0 (Impediment.Resolved como Shared Active) — usar tipo Journey por enquanto

---

# Scope do MVP

| Parâmetro | Valor |
|---|---|
| **Produto** | payments-api |
| **Iterations** | 1 (uma Iteration completa) |
| **Features reais** | 3 (três Features reais do backlog do payments-api) |
| **GitHub Project** | Workspace existente do payments-api (já reconciliado) |
| **Datadog** | Instância existente (configurada em EXP-005/EXP-010) |
| **Runtime** | Runtime mínimo — Skills executados manualmente ou com scripts leves |
| **Journeys** | Delivery + Diligence (Assessment opcional ao final) |
| **Horizonte temporal** | Definido no plano de execução do experimento |

---

# Critérios de Sucesso

O experimento é bem-sucedido se todos os critérios abaixo forem satisfeitos ao final da execução:

| # | Critério | Verificação |
|---|---|---|
| CS-01 | Três Features concluídas com Timelines registradas (Bootstrap.Started → Promote.Completed) | Timeline de cada Feature contém todos os eventos esperados |
| CS-02 | Timeline é reconstruível (Replay idempotente) sem estado externo | Replay produz o mesmo Derived State que o cálculo incremental |
| CS-03 | GitHub Project sincronizado com Derived State de todos os Work Items ativos | Custom Fields refletem o estado correto para cada Feature |
| CS-04 | Pelo menos um cenário de Rework real executado e registrado na Timeline | Rework.Declared + Rework.Completed presentes em pelo menos uma Timeline |
| CS-05 | Pelo menos um cenário de Blocking real executado com Lookback | Impediment.Declared + Impediment.Resolved (Lookback) em pelo menos uma Timeline |
| CS-06 | Pelo menos um Drift detectado pela Diligence Async e reparado | Divergence.Detected + Flag.Completed + Repair.Completed em pelo menos uma Timeline Diligence |
| CS-07 | Pelo menos uma métrica derivada da Timeline visível no Datadog | Dashboard com Lead Time ou Cycle Time com trace rastreável até eventos |
| CS-08 | Nenhuma mudança arquitetural obrigatória no Framework identificada | Nenhuma proposta de alteração no OEM, catálogos, ou Shared Types como pré-requisito para a execução |

---

# Critérios de Fracasso

A hipótese é considerada **refutada** se qualquer um dos critérios abaixo for verdadeiro durante a execução:

| # | Critério de fracasso | Impacto |
|---|---|---|
| CF-01 | A Timeline é insuficiente para representar o estado de um Work Item — exige armazenamento de estado externo | OEM precisa revisão estrutural |
| CF-02 | O OEM não possui Event Types necessários para eventos reais da Iteration — gaps críticos sem workaround | Catálogos de Journey precisam revisão |
| CF-03 | O Derived State calculado diverge do estado real do Work Item — Consumer produz resultado incorreto | Mecanismo de Derived State precisa revisão |
| CF-04 | O GitHub Projects precisa tornar-se fonte de verdade (não apenas COR) para a operação funcionar | Definição de COR precisa revisão |
| CF-05 | O Runtime exige novos conceitos estruturais (nova Journey, nova Category, novo mecanismo do OEM) para ser operável | Framework precisa extensão estrutural antes da validação |
| CF-06 | A Diligence Journey é incapaz de reconciliar corretamente o fluxo de conformidade de Work Items Delivery | Journey Diligence precisa revisão |
| CF-07 | As métricas operacionais não podem ser derivadas apenas dos eventos da Timeline — exigem fonte externa | Modelo de métricas precisa revisão |

Se qualquer critério de fracasso for confirmado, o resultado do experimento é um **Evolution Plan** (não um OBC) — descrevendo as alterações estruturais necessárias antes de um novo experimento.

---

# Implementation Plan

Atividades planejadas para a execução do experimento:

## Fase 1 — Setup (pré-execução)

1. Selecionar as 3 Features reais do backlog do payments-api para a Iteration de validação
2. Confirmar que o GitHub Project do payments-api está pronto para receber Custom Fields de Derived State
3. Confirmar acesso ao Datadog e definir o destino das métricas derivadas
4. Definir o Consumer de Derived State mínimo (script ou manual — não automação completa)
5. Definir o formato de registro das Event Instances para a Timeline do experimento

## Fase 2 — Execução Delivery

6. Executar Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote para as 3 Features
7. Registrar todas as Event Instances nas Timelines correspondentes
8. Forçar pelo menos um cenário de Rework (Gate.Failed → Rework.Declared → Rework.Completed)
9. Forçar pelo menos um cenário de Blocking (Impediment.Declared → Impediment.Resolved com Lookback)
10. Calcular Derived State após cada evento state-altering
11. Sincronizar GitHub COR após cada transição de estado

## Fase 3 — Execução Diligence

12. Executar Diligence Sync (Capture → Attach → Promote → Close) para as Features concluídas
13. Executar Diligence Async (Scan → Flag → Repair) — pelo menos um ciclo com Drift detectado
14. Registrar Timelines de Diligence para cada Work Item

## Fase 4 — Métricas e Observabilidade

15. Calcular Lead Time, Cycle Time, Block Time e Gate Failure Rate a partir das Timelines
16. Enviar pelo menos uma métrica ao Datadog com trace rastreável até os eventos

## Fase 5 — Assessment (opcional)

17. Se tempo permitir: executar Assessment Sync (Collect → Analyze → Synthesize) sobre as Timelines produzidas

## Fase 6 — Evidências e Conclusão

18. Coletar todas as evidências em `evidence/`
19. Verificar cada critério de sucesso e de fracasso
20. Classificar as perguntas Q1–Q8
21. Produzir o Decision Package

---

# Evidências Esperadas

Ao final do experimento, as seguintes evidências devem existir em `evidence/`:

| Evidência | Descrição | Critério relacionado |
|---|---|---|
| `timelines/` | Timelines completas das 3 Features (formato JSON ou Markdown por evento) | CS-01, CS-02 |
| `derived-state-log.md` | Log de Derived State calculado após cada evento, com trace para o evento | CS-02, CS-03 |
| `github-cor-snapshot.md` | Screenshot ou export dos Custom Fields do GitHub Project em cada transição | CS-03 |
| `rework-timeline.md` | Timeline com cenário de Rework documentado | CS-04 |
| `blocking-lookback-trace.md` | Timeline com cenário de Blocking e trace do Lookback | CS-05 |
| `diligence-drift-repair.md` | Timeline Diligence com Divergence.Detected e Repair.Completed | CS-06 |
| `datadog-screenshot.md` | Screenshot do Datadog com métrica derivada e trace até evento da Timeline | CS-07 |
| `framework-gaps.md` | Lista de gaps encontrados durante a execução (vazia se CS-08 satisfeito) | CS-08 |

---

# Code Produced

*A ser preenchido durante a execução.*

Este experimento pode gerar scripts auxiliares (Consumer de Derived State, sync de GitHub COR) que ficarão em `evidence/scripts/`. Nenhum código de produção (`api/`) será produzido nesta fase.

---

# Technical Findings

*A ser preenchido durante a execução.*

---

# Business Findings

*A ser preenchido durante a execução.*

---

# Architecture Impact

*A ser preenchido durante a execução.*

Se o experimento confirmar a hipótese: nenhum impacto arquitetural — o Framework está pronto para OBC-RUNTIME-001.

Se o experimento refutar a hipótese: Evolution Plan listando as mudanças estruturais necessárias.

---

# Reliability Impact

*A ser preenchido durante a execução.*

A validação do Runtime estabelece o baseline de confiabilidade operacional do Framework no payments-api. O primeiro Lead Time e Cycle Time reais serão registrados aqui.

---

# Artifacts Updated

*A ser preenchido durante a execução.*

---

# Knowledge Gaps Closed

| Pergunta | Status | Evidência |
|---|---|---|
| Q1 — O OEM é suficiente? | Pendente | — |
| Q2 — O Derived State é suficiente? | Pendente | — |
| Q3 — A Timeline pode ser reconstruída pelos eventos? | Pendente | — |
| Q4 — O GitHub permanece apenas COR? | Pendente | — |
| Q5 — A Diligence consegue reconciliar todo o fluxo? | Pendente | — |
| Q6 — Métricas deriváveis exclusivamente dos eventos? | Pendente | — |
| Q7 — Os Shared Types são suficientes? | Pendente | — |
| Q8 — O Runtime exige novos conceitos arquiteturais? | Pendente | — |

---

# New Backlog Items

*A ser preenchido durante a execução.*

---

# Recommendation

*A ser preenchido ao final da execução.*

- [ ] Mover para Downstream (criar OBC-RUNTIME-001)
- [ ] Executar outro experimento Upstream
- [ ] Aguardar decisão de produto
- [ ] Aguardar dependência externa
- [ ] Descartar capability

---

# Decision Package

*A ser preenchido ao final da execução.*

## Executive Summary

## Decisão Recomendada

## Riscos Atualizados

## Oportunidades Atualizadas

## Itens de Tracking Atualizados

## OBCs Atualizados

## Reliability Plan Atualizado

## Escopo Downstream Recomendado

---

# Output Artifacts

## Artefatos gerados

| Tipo | Artefato | Situação |
|---|---|---|
| Business Signal | BS-RUNTIME-001 | Criado |
| Product Intent | PI-RUNTIME-001 | Criado |
| OBC | OBC-RUNTIME-001 | Pendente — criado somente se experimento aprovado |

**Promovido para Downstream:** `- [ ] Sim` / `- [x] Não (ainda Planned)` / `- [ ] N/A`
**Data de promoção:** —
**Slice:** —

---

# Exit Criteria

- [ ] Hipótese original respondida (Q1–Q8 classificadas)
- [ ] Perguntas classificadas (✅ / ⚠ / ❌)
- [ ] Lacunas de conhecimento documentadas
- [ ] Impacto arquitetural documentado
- [ ] Impacto em confiabilidade documentado
- [ ] Evidências coletadas em `evidence/`
- [ ] Recomendação produzida
- [ ] Decision Package completo

---

# Next Step

## Se o experimento for aprovado (hipótese confirmada)

O próximo artefato será:

**`OBC-RUNTIME-001`** — criado em `prodops/artifacts/obcs/OBC-RUNTIME-001.md`

A iniciativa então segue para:

1. **Discovery consolidada** — Decision Package do EXP-013 como base
2. **Premortem** — análise de riscos antes do compromisso
3. **Reliability Plan** — baseline operacional estabelecido pelo experimento
4. **Release Plan** — sequência de entrega
5. **Iteration Plan** — ciclos de implementação

## Se o experimento for reprovado (hipótese refutada)

O próximo artefato será:

**Evolution Plan** — listando as mudanças estruturais necessárias no Framework antes de um novo experimento de validação. OBC-RUNTIME-001 não é criado.
