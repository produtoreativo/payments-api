# EXP-016 — Operational Flow Validation

**Produto:** payments-api  
**Iteration:** IP-001 — Piloto Operacional Fase 2  
**Status:** ✅ COMPLETED — 9 incrementos, Features #76 + #78 com Journey completa, Feature Restart implementado  
**Data de conclusão:** 2026-07-29  
**Branch:** `experiment/015-delivery-skills-event-producers`

---

## Hipótese

> Uma Feature percorre toda a Journey Delivery em tempo real, sendo executada por Skills, emitindo CloudEvents, movimentando automaticamente os cards do GitHub Project, atualizando dashboards executivos no Datadog e acionando a Journey Diligence de forma reativa.

---

## Escopo

- **Não alterar** o contrato CloudEvents.
- **Não alterar** o Runtime.
- **Não alterar** o modelo das Skills.
- **Não introduzir** novos componentes arquiteturais.
- Foco: validação operacional ponta a ponta.

---

## Fundação

| Experimento | O que entrega para EXP-016 |
|-------------|---------------------------|
| EXP-013 | Runtime validado: Timeline, Derived State, GitHub sync, Datadog |
| EXP-014 | Diligence reativa: GitHub Project views, Datadog dashboards, demo scripts |
| EXP-015 | Skills como produtoras: Tool canônica, Conformance suite, Dispatcher no Step 6 |

---

## Incrementos

| # | Objetivo | Status |
|---|----------|--------|
| 1 | Auditoria de ambiente (views, dashboard, Feature issue) | ✅ |
| 2 | GitHub Project — views para demonstração operacional | ✅ |
| 3 | Delivery real — Feature #76 percorre toda a Journey (21 eventos) | ✅ |
| 4 | Validação do GitHub Project (cards, views) | ✅ |
| 5 | Validação do Datadog (dashboard executiva) | ✅ |
| 6 | Preparação para demonstração | ✅ |
| 7 | Feature #79 BLOQUEADA — baseline documentado (F-03 incompleta + DQ-02) | ✅ |
| 8 | Feature Restart — Tool implementada, catálogo atualizado, RST aplicado a #78 | ✅ |
| 9 | F-03 Journey canônica — Issue #78 completada: Bootstrap→Promote (DONE) | ✅ |

---

## Modelo de Execução (decisão aprovada — EXP-015)

### Sync
- execução local; reativa; stateless; idempotente

### Async
- GitHub Actions; GitHub Agents

---

## Definition of Done

- [x] Uma Feature percorreu toda a Delivery Journey (Issue #76 — 21 eventos, Bootstrap→Promote)
- [x] GitHub Project moveu os cards automaticamente (BOOTSTRAPPING→DONE confirmado via API)
- [x] Datadog refletiu o fluxo em tempo real (21 métricas com datadog-sync=success)
- [x] Diligence acompanhou toda a execução (Capture+Attach+Promote via dispatcher Step 6)
- [x] Ambiente pronto para gravação de demonstração operacional (24/25 PASS)
- [x] Feature Restart implementado como Tool canônica não-destrutiva
- [x] Issue #78 completada via Restart + Journey canônica (21 eventos, DONE)
- [x] Gate de Bloco do Iteration Plan IP-001 satisfeito (F-01 + F-02 + F-03 all DONE)
- [ ] DQ-02 (`Delivery.Gate.Failed`) — **explicitamente em aberto**

## Evidências

| Incremento | Documento |
|-----------|-----------|
| 1 — Auditoria | `evidence/incremento-1-environment-audit.md` |
| 2 — Views | `evidence/incremento-2-github-views.md` |
| 3 — Delivery run | `evidence/incremento-3-delivery-run.md` |
| 4 — GitHub | `evidence/incremento-4-github-project-validation.md` |
| 5 — Datadog | `evidence/incremento-5-datadog-validation.md` |
| 6 — Demo prep | `evidence/incremento-6-demo-preparation.md` |
| Run artifacts | `evidence/delivery-run/` (15 arquivos JSON, 1 por evento Delivery) |
| 7 — Real Delivery (bloqueada) | `evidence/real-delivery-run/baseline.md` |
| 8 — Feature Restart | `evidence/feature-restart/restart-execution.md` |
| 8 — Catálogo | `evidence/feature-restart/catalog-update.md` |
| 8 — Idempotência | `evidence/feature-restart/idempotency-analysis.md` |
| 9 — F-03 Journey | `evidence/feature-restart/f03-journey.md` |
| 9 — F-03 Timeline | `evidence/feature-restart/f03-timeline.md` |
| 9 — Relatório Final | `evidence/feature-restart/final-report.md` |
| Restart artifacts | `prodops/artifacts/runtime/restarts/78/` (8 arquivos JSON) |

---

## Links

| Sistema | URL |
|---------|-----|
| GitHub Project | https://github.com/orgs/produtoreativo/projects/25 |
| Datadog Operational | https://app.datadoghq.com/dashboard/jhq-ztv-3pv |
| Datadog Executive | https://app.datadoghq.com/dashboard/4rs-983-e35 |
