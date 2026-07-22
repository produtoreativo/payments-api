# Upstream Trail — EXP-008 DORA Extended Documentation

## 2026-07-16

**Iniciado por:** Christiano Milfont

**Contexto:** Usuário solicitou plano de documentação completa do DORA estendido no ProdOps. As métricas estão definidas no Certificare (`~/produtos/certificare`) mas não têm nenhuma presença no payments-api.

**Ações:**
- Leitura do Certificare: `assessments.service.ts`, `delivery-assessment-definition.service.ts`, pocket assessment YAMLs.
- Identificadas 7 métricas DORA estendidas + escala de maturidade 0–5 + 5 perfis de avaliação.
- Aplicado Repository Scope Gate: documentation-only, dentro do escopo do produto.
- Criado `experiment.md` com plano de 6 camadas, sequência de execução e Decision Package.

**Resultado:** Plano completo produzido. Recomendação: Promover para Downstream.

**Próximos passos:** Assessment Review com PM + Tech Lead para aprovação do plano e início da Camada 3.

---

## 2026-07-16 — Camada 0 executada

**Contexto:** Identificado que PoC no ProdOps sempre tem cliente envolvido. Sem cliente = Spike Solution. Spike Solution pode ocorrer em qualquer estágio e fase. Os estágios (PoC, MVP, IPR, MVR, MVT, MLP) não estavam documentados no framework.

**Ações:**
- Criado `prodops/framework/product-stages.md` + `.en.md` — 6 estágios com definições, macro-fases, tabela PoC vs Spike Solution, referência a DORA.
- Atualizado `prodops/framework/glossary.md` + `.en.md` — adicionados termos: Estágio de Produto, PoC, Spike Solution.
- Elevado `prodops/journeys/discovery/spikes.md` de stub para definição completa com estrutura de registro e distinção de PoC.
- EXP-008 atualizado com Camada 0 marcada como concluída.

**Resultado:** Vocabulário de estágios e Spike Solution disponível para as Camadas 1–6.

---

## 2026-07-16 — Camadas 1–6 implementadas (experimento concluído)

**Ações:**

- **Camada 3** — Criado `evidence/obc-dora-mapping.md`: 41 eventos de 7 OBCs mapeados para as 7 métricas DORA. Cobertura: Reaction Time ✅, Rate of Return ✅, Availability ✅, Change Fail Rate ✅ parcial, MTTR ✅ parcial, Lead Time ✗, Release Frequency ✗. 3 gaps de instrumentação documentados.
- **Camada 2** — Criados `framework/dora-metrics.md` + `.en.md`: 7 métricas com definições, tabela de pesos por estágio (PoC→MLP), 5 perfis de avaliação, escala de maturidade 0–5, métricas complementares.
- **Camada 1** — Atualizados `framework/glossary.md` + `.en.md`: adicionados termos **DORA Metrics (Extended)** e **Maturity Level (Delivery)**.
- **Camada 4** — Atualizados `journeys/operation/README.md` + `.en.md`: seção "DORA como instrumento de saúde contínua" com tabela de sinais → ações por métrica e fluxo de geração de Intents via deterioração DORA.
- **Camada 5** — Atualizado `journeys/assessment/reliability-plans/README.md`: seção "DORA como referência de confiabilidade" com mapeamento SLIs dos OBCs → métricas DORA e gaps de cobertura desta Release.
- **Camada 6** — Atualizado `artifacts/product/product-deck.md`: seção 15 "Maturidade de Delivery (DORA)" com estágio atual (MVP→IPR), perfil balanced, pesos por métrica e gaps de instrumentação.

**Artefatos produzidos (10):**
1. `evidence/obc-dora-mapping.md` (novo)
2. `framework/dora-metrics.md` (novo)
3. `framework/dora-metrics.en.md` (novo)
4. `framework/glossary.md` (atualizado — DORA Metrics + Maturity Level)
5. `framework/glossary.en.md` (atualizado)
6. `journeys/operation/README.md` (atualizado)
7. `journeys/operation/README.en.md` (atualizado)
8. `journeys/assessment/reliability-plans/README.md` (atualizado)
9. `artifacts/product/product-deck.md` (atualizado)
10. `experiment.md` (concluído)

**Resultado:** experimento concluído. Hipótese confirmada — documentação completa em 7 camadas, documentation-only, sem impacto em código.
