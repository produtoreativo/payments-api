# Estágios de Produto

O ProdOps organiza o ciclo de vida de um produto em seis estágios progressivos divididos em duas macro-fases. O estágio declara onde o produto está — e determina quais métricas de delivery têm maior peso naquele momento.

---

## As duas macro-fases

```
[ Validação de Hipóteses ]  →  TESE E COMPROMISSO  →  [ Aceleração ]
  PoC  →  MVP  →  IPR                                  MVR  →  MVT  →  MLP
```

**Validação de Hipóteses:** custo minimizado, aprendizado rápido, cliente como validador. O objetivo é provar que a ideia é viável antes de comprometer escala.

**Aceleração:** processo padronizado, adoção de mercado, produto que encanta. O objetivo é crescer com confiabilidade e repetibilidade.

---

## Os seis estágios

### PoC — Proof of Concept / Prova de Conceito

**Objetivo:** Validar se uma ideia ou abordagem é viável junto a um cliente real.

**Característica central:** O cliente sempre está envolvido. Sem cliente, não é PoC — é **Spike Solution** (ver abaixo).

**Resultado esperado:** Confirmar se a ideia vale ser desenvolvida, com base em feedback real de quem vai usar ou pagar pelo produto.

**Exemplo:** Um protótipo de split payment demonstrado para o Magazine Siará antes de qualquer decisão de desenvolvimento.

---

### MVP — Minimum Viable Product / Produto Mínimo Viável

**Objetivo:** Lançar a versão mais simples do produto para validar com usuários reais.

**Característica central:** Produto funcional, mínimo de recursos, testado no mercado.

**Resultado esperado:** Feedback real de usuários e validação de hipóteses de negócio.

**Exemplo:** Gateway de pagamentos com suporte apenas a Pix, sem outros métodos.

---

### IPR — Initial Product Release / Liberação Inicial do Produto

**Objetivo:** Primeira versão funcional liberada para uso — pode ter limitações, mas já entrega valor.

**Característica central:** Início do uso real por um grupo inicial de usuários.

**Resultado esperado:** Evidência de valor entregue, com coleta de aprendizado para evoluções.

**Exemplo:** Primeira versão pública do gateway com Pix e cartão de crédito hospedado.

---

### MVR — Minimum Viable Repeatability / Repetibilidade Mínima Viável

**Objetivo:** Validar se o produto pode ser repetido e escalado com processo padronizado.

**Característica central:** Processo de replicação definido; onboarding previsível e eficiente.

**Resultado esperado:** O produto pode ser reproduzido para novos clientes sem esforço manual relevante.

**Exemplo:** Gateway com onboarding automatizado de tenant, sem configuração manual por cliente.

---

### MVT — Minimum Viable Traction / Tração Mínima Viável

**Objetivo:** Validar se há adoção e demanda real no mercado.

**Característica central:** Mede engajamento, crescimento e retenção inicial.

**Resultado esperado:** Evidência de que há demanda real pelo produto — usuários ou clientes pagantes sem esforço de marketing intenso.

**Exemplo:** Gateway atingindo 10 tenants ativos com volume crescente de transações mês a mês.

---

### MLP — Minimum Lovable Product / Produto Mínimo Adorável

**Objetivo:** Produto que além de funcionar, encanta os usuários.

**Característica central:** Além de funcional, gera forte conexão — usuários não apenas usam, mas recomendam.

**Resultado esperado:** Net Promoter Score positivo; produto recomendado espontaneamente.

**Exemplo:** Gateway com experiência de integração tão simples e transparente que os desenvolvedores o recomendam sem ser solicitados.

---

## Spike Solution

**Spike Solution não é um estágio de produto.** É um instrumento de exploração técnica disponível em qualquer estágio e em qualquer fase de experimento — inclusive dentro de um PoC ou de qualquer jornada Upstream.

**Diferença crítica em relação ao PoC:**

| Dimensão | PoC | Spike Solution |
|---|---|---|
| Cliente envolvido | Sempre | Nunca |
| Objetivo | Validar viabilidade com feedback real | Responder pergunta técnica específica |
| Produz | Aprendizado validado com cliente | Aprendizado técnico interno |
| Código | Pode ser demonstrável ao cliente | Sempre descartável |
| Quando usar | Fase de Validação de Hipóteses | Qualquer estágio, qualquer fase |
| Registrado em | Experiment (`experiment.md`) | `prodops/journeys/discovery/spikes.md` |

Um Spike Solution pode ocorrer **dentro** de um PoC (para responder uma pergunta técnica antes de demonstrar ao cliente) ou **independentemente** (em qualquer estágio, quando surge uma incerteza técnica que bloqueia progresso).

---

## Estágios e métricas DORA

Cada estágio define o peso relativo das métricas DORA estendidas. Nos estágios iniciais, velocidade de aprendizado domina (Lead Time alto). Nos estágios finais, confiabilidade domina (MTTR, Availability, Change Fail Rate altos).

→ Ver [`dora-metrics.md`](dora-metrics.md) para a tabela completa de pesos por estágio.

---

## Referências

→ [Glossário](glossary.md)
→ [DORA Metrics — Extended Model](dora-metrics.md)
→ [Fluxo do Framework](flow.md)
→ [Jornada Discovery](../journeys/discovery/README.md)
→ [Spikes](../journeys/discovery/spikes.md)
