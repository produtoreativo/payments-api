# Upstream Experiment — DORA Estendido: Plano de Documentação Completa

Localização canônica:

```text
prodops/journeys/discovery/experiments/008-dora-extended-documentation/experiment.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Business Goal

O ProdOps usa métricas DORA estendidas como instrumento de avaliação de maturidade de delivery no Certificare. Porém, essas métricas não estão documentadas em nenhum nível do payments-api: não aparecem no glossário do framework, não são referenciadas na jornada Operation, não estão conectadas aos Observable Events dos OBCs nem ao Reliability Plan.

O objetivo deste experimento é produzir um plano de documentação completo e executável — mapeando o que precisa ser criado, em qual artefato, em qual ordem, e qual é a fronteira entre o que pertence ao framework canônico e o que pertence ao produto.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [ ] Comportamento da Payments API
- [ ] Lógica de domínio de Payments
- [ ] Integração com provedor
- [ ] Processamento de webhook
- [ ] Persistência
- [ ] Contrato de API/evento de propriedade do Payments
- [x] Testes locais ou evidência executável

**Natureza do experimento:** documentation-only. O repo hospeda os artefatos ProdOps do produto (glossário, Operation journey, Reliability Plan, OBCs) que precisam referenciar e contextualizar as métricas DORA estendidas definidas no Certificare.

## Dependências externas

- **Certificare** (`~/produtos/certificare`) — fonte canônica das definições, pesos por estágio e perfis de avaliação DORA estendido.
- **ProdOps Framework repo** (se existir separado) — casa canônica para definições de glossário de nível de framework.

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório
  - Justificativa: este repo é o ponto de adoção do framework pelo produto. Os artefatos de Operation, Reliability Plan e OBCs aqui são os que precisam conectar-se às métricas. A documentação pertence aqui porque é aqui que ela será usada.

---

# Question to Answer

1. Quais são as 7 métricas DORA estendidas e como elas se diferenciam das 4 originais?
2. Como os Observable Events dos OBCs existentes mapeiam para cada métrica DORA?
3. Onde cada camada de documentação deve viver (framework vs produto)?
4. Como o Reliability Plan deve referenciar DORA?
5. Como a jornada Operation deve incorporar DORA como instrumento de monitoramento contínuo?
6. Qual é a sequência de execução para produzir a documentação completa?

---

# Hypothesis

A documentação completa do DORA estendido no ProdOps deste produto requer **seis camadas interdependentes**, executadas de dentro para fora (framework → produto → operação), e pode ser produzida integralmente sem código — apenas com artefatos ProdOps.

---

# Scope

- Definição das 7 métricas no glossário do framework
- Novo arquivo `dora-metrics.md` no framework (PT + EN)
- Conexão entre Observable Events dos OBCs e cada métrica DORA
- Atualização da jornada Operation com DORA como instrumento de saúde
- Atualização do template de Reliability Plan para incluir DORA
- Atualização do Product Deck com indicadores de maturidade DORA
- Referência cruzada ao Certificare como plataforma de assessment

---

# Out of Scope

- Implementação de coleta de métricas em código (dashboards, pipelines de métricas)
- Alterações no Certificare
- Definição de targets absolutos por produto (isso pertence ao Reliability Plan por OBC)
- BDD Features ou OBCs de produto

---

# Plano de Documentação — As Seis Camadas

## Camada 1 — Definição no Glossário do Framework

**Arquivo:** `prodops/framework/glossary.md` + `glossary.en.md`

**O que adicionar:** Dois novos termos após a seção de Fases:

- **DORA Metrics (Extended):** definição das 7 métricas, distinção do DORA original de 4 métricas, referência a `dora-metrics.md`.
- **Maturity Level (Delivery):** escala 0–5 (Inexistente → Excelência), avaliação top-down, uso no Certificare.

**Critério de qualidade:** cada métrica deve ter nome canônico, o que mede, e como se relaciona com os Observable Events do produto.

---

## Camada 2 — Arquivo dedicado `dora-metrics.md`

**Arquivo:** `prodops/framework/dora-metrics.md` + `dora-metrics.en.md`

**Estrutura do arquivo:**

```
# DORA Metrics — Extended Model

## As 7 Métricas

### DORA Core (4 originais)
- Lead Time for Change
- Release Frequency
- Change Fail Rate
- Mean Time to Recovery

### Extensões ProdOps (3 adicionais)
- Reaction Time          ← tempo entre sinal e primeira resposta
- Rate of Return         ← defeitos escapados / retrabalho
- Availability           ← uptime operacional

## Pesos por Estágio de Produto

Tabela: Métrica × (PoC | MVP | IPR | MVR | MVT | MLP) com pesos 1–8.

## Perfis de Avaliação

balanced | velocity | quality | reliability | ai_readiness

## Escala de Maturidade (0–5)

Inexistente → Inicial → Repetível → Definido → Gerenciado → Excelência
Estratégia top-down: começa no 5, cai no primeiro critério obrigatório reprovado.

## Métricas Complementares (Quality Gate)

Test Coverage | Test Pass Rate | Rollback Health

## Referências
→ Certificare (plataforma de assessment)
→ Operation journey
→ Reliability Plan
```

---

## Camada 3 — Mapeamento OBC Observable Events → DORA

**Arquivo:** `prodops/journeys/discovery/experiments/008-dora-extended-documentation/evidence/obc-dora-mapping.md`

**O que produzir:** tabela cruzando cada Observable Event dos OBCs existentes com a métrica DORA que ele alimenta.

**Exemplo:**

| OBC | Observable Event | Métrica DORA alimentada |
|---|---|---|
| create-invoice | `invoice.created` | Release Frequency (deploy chegou a produzir eventos reais) |
| create-invoice | `invoice.creation_failed` | Change Fail Rate |
| payment-confirmation | `payment.confirmed` | Lead Time for Change |
| webhook-configuration | `webhook.delivered` | Availability |
| (qualquer OBC) | Ausência de evento em SLO window | Mean Time to Recovery |

**Critério:** todos os 7 OBCs existentes mapeados.

---

## Camada 4 — Atualização da Jornada Operation

**Arquivo:** `prodops/journeys/operation/README.md` + `README.en.md`

**O que adicionar:** seção "DORA como instrumento de saúde contínua" com:

- Qual métrica monitorar em qual estágio do produto
- Como o time de operação lê as métricas para gerar novas Intents
- Relação entre deterioração de DORA e abertura de incidentes ou postmortems
- Link para `dora-metrics.md` e para o Certificare

**Estrutura da seção:**

```markdown
## DORA como instrumento de saúde contínua

O Continuous Assessment usa as métricas DORA estendidas para identificar
quando o produto precisa de uma nova Intent de melhoria.

| Sinal de deterioração | Métrica DORA | Ação esperada |
|---|---|---|
| Deploy demora > X | Lead Time for Change | Intent Technology: revisar pipeline |
| Rollbacks frequentes | Change Fail Rate | Intent Technology: qualidade de testes |
| Recovery lento | Mean Time to Recovery | Intent Technology: runbook + alertas |
| Retrabalho crescente | Rate of Return | Intent Team: processo de validação |
| Disponibilidade caindo | Availability | Intent Technology: SLO + error budget |
| Resposta lenta a sinais | Reaction Time | Intent Team: on-call + monitoramento |
```

---

## Camada 5 — Atualização do Template de Reliability Plan

**Arquivo:** `prodops/journeys/assessment/reliability-plans/README.md` + `README.en.md`

**O que adicionar:** seção "DORA como referência de confiabilidade" indicando:

- Quais métricas DORA são relevantes para a decisão de readiness
- Como os Initial SLIs do OBC conectam-se às métricas DORA (ex: SLI de uptime = Availability DORA)
- Critério: para itens com alto risco operacional, o Reliability Plan deve declarar quais métricas DORA serão monitoradas em produção

---

## Camada 6 — Atualização do Product Deck

**Arquivo:** `prodops/artifacts/product/product-deck.md` + `product-deck.en.md`

**O que adicionar:** seção "Maturidade de Delivery (DORA)" com:

- Estágio atual do produto (PoC / MVP / IPR / MVR / MVT / MLP)
- Perfil de avaliação adotado (balanced / velocity / quality / reliability / ai_readiness)
- Link para o assessment no Certificare
- Métricas com maior peso neste estágio (pré-preenchido a partir da tabela de pesos)

---

# Sequência de Execução Recomendada

```
0. Camada 0 — Estágios de Produto + Spike Solution   ← PRÉ-REQUISITO de todas as demais
   (vocabulário que âncora os pesos DORA e distingue PoC de Spike Solution)
   └── framework/product-stages.md + .en.md           ✅ Concluído
   └── framework/glossary.md + .en.md                 ✅ Concluído (Product Stage, PoC, Spike Solution)
   └── journeys/discovery/spikes.md                   ✅ Concluído (elevado de stub para definição)

1. Camada 3 — Mapeamento OBC → DORA
   (base empírica que ancora as definições — produzir primeiro)
   └── evidence/obc-dora-mapping.md

2. Camada 2 — dora-metrics.md
   (definições completas; usa o mapeamento como evidência)
   └── framework/dora-metrics.md + .en.md

3. Camada 1 — Glossário
   (termos curtos que referenciam dora-metrics.md)
   └── framework/glossary.md + .en.md

4. Camada 4 — Operation journey
   (conecta monitoramento contínuo às métricas)
   └── journeys/operation/README.md + .en.md

5. Camada 5 — Reliability Plan template
   (conecta avaliação de risco às métricas)
   └── journeys/assessment/reliability-plans/README.md + .en.md

6. Camada 6 — Product Deck
   (posiciona o produto na escala de maturidade)
   └── artifacts/product/product-deck.md + .en.md
```

---

# Technical Findings

- O Certificare define 7 métricas com pesos por estágio (escala 1–8) e perfis de avaliação.
- Os Observable Events dos OBCs existentes já têm semântica compatível com DORA — falta apenas o mapeamento explícito.
- A jornada Operation existe mas não referencia métricas de saúde de delivery.
- O Reliability Plan referencia SLIs/SLOs por OBC mas não conecta ao modelo DORA.
- O Product Deck não tem seção de maturidade de delivery.

---

# Architecture Impact

Nenhum impacto arquitetural. Documentação-only.

---

# Reliability Impact

Nenhum impacto direto. O plano prepara o terreno para que futuros Reliability Plans referenciem métricas DORA — mas não altera nenhum artefato operacional existente.

---

# Artifacts Updated

- Este experimento (criado): `prodops/journeys/discovery/experiments/008-dora-extended-documentation/`

Artefatos a serem produzidos nas Camadas 1–6 (não modificados ainda):
- `prodops/framework/dora-metrics.md` + `.en.md`
- `prodops/framework/glossary.md` + `.en.md`
- `prodops/journeys/operation/README.md` + `.en.md`
- `prodops/journeys/assessment/reliability-plans/README.md` + `.en.md`
- `prodops/artifacts/product/product-deck.md` + `.en.md`
- `evidence/obc-dora-mapping.md`

---

# Knowledge Gaps Closed

| Pergunta | Status | Evidência |
|---|---|---|
| Quais são as 7 métricas DORA estendidas? | ✅ Respondida | Certificare `assessments.service.ts` |
| Como os Observable Events mapeiam para DORA? | ⚠ Parcialmente respondida | Mapeamento inicial na Camada 3; requer validação com os 7 OBCs |
| Onde cada camada de documentação deve viver? | ✅ Respondida | Plano de 6 camadas acima |
| Como o Reliability Plan deve referenciar DORA? | ✅ Respondida | Camada 5 |
| Como a jornada Operation deve incorporar DORA? | ✅ Respondida | Camada 4 |
| Qual é a sequência de execução? | ✅ Respondida | Sequência definida acima |

---

# New Backlog Items

| Item | Classificação |
|---|---|
| Executar Camada 3: mapeamento OBC → DORA | Candidato ao Iteration Backlog (documentation downstream) |
| Executar Camadas 1–2: glossário + dora-metrics.md | Candidato ao Iteration Backlog |
| Executar Camadas 4–6: Operation, Reliability Plan, Product Deck | Candidato ao Iteration Backlog |

---

# Recommendation

- [x] Mover para Downstream

O plano está suficientemente definido. As 6 camadas têm escopo, ordem e critério de qualidade declarados. A incerteza remanescente (mapeamento completo dos 7 OBCs) é baixa e resolvível durante a Camada 3.

---

# Decision Package

## Executive Summary

O DORA estendido do ProdOps define 7 métricas com pesos por estágio de produto e perfis de avaliação. Nenhuma delas está documentada no payments-api. A documentação completa requer 6 camadas executáveis em sequência, todas documentation-only, sem impacto em código ou contratos de produto.

## Decisão Recomendada

Promover para Downstream. Executar as 6 camadas em ordem, começando pelo mapeamento OBC → DORA como base empírica.

## Riscos Atualizados

- Risco baixo: mapeamento OBC → DORA pode revelar eventos ausentes nos OBCs existentes (ex: nenhum evento sinaliza Lead Time for Change explicitamente). Mitigação: documentar a lacuna e abrir item no Tracking List.

## Oportunidades Atualizadas

- A conexão Observable Events → DORA pode qualificar os OBCs como instrumentos de health check automático no Certificare.

## Itens de Tracking Atualizados

Nenhum item novo na Repository Tracking List neste momento.

## OBCs Atualizados

Nenhum OBC modificado.

## Reliability Plan Atualizado

Nenhum Reliability Plan modificado. O template será atualizado na Camada 5.

## Escopo Downstream Recomendado

Executar as 6 camadas como um único item de documentação no próximo ciclo de Delivery, com as Camadas 1–3 como pré-requisito para as Camadas 4–6.

---

# Output Artifacts

Lista os artefatos de produto gerados ou promovidos por este experimento.

## Artefatos gerados

| Tipo | Artefato | Situação |
|---|---|---|
| OBC | N/A | Documentation-only |
| BDD Feature | N/A | Documentation-only |

**Promovido para Downstream:** N/A — experimento documentation-only.
**Artefatos de framework gerados (10):**
- `prodops/framework/dora-metrics.md` + `.en.md` — criados
- `prodops/framework/glossary.md` + `.en.md` — atualizados (DORA Metrics + Maturity Level)
- `prodops/journeys/operation/README.md` + `.en.md` — atualizados (seção DORA)
- `prodops/journeys/assessment/reliability-plans/README.md` — atualizado (DORA como referência)
- `prodops/artifacts/product/context/product-deck.md` — atualizado (seção Maturidade de Delivery)
- `prodops/journeys/discovery/experiments/008-dora-extended-documentation/evidence/obc-dora-mapping.md` — criado

---

# Exit Criteria

- [x] Hipótese original respondida — 7 camadas (0–6) implementadas
- [x] Perguntas classificadas — todas respondidas
- [x] Lacunas de conhecimento documentadas — 3 gaps de instrumentação em obc-dora-mapping.md
- [x] Impacto arquitetural documentado — nenhum
- [x] Impacto em confiabilidade documentado — seção DORA adicionada ao Reliability Plan
- [x] Artefatos atualizados — todos os 10 artefatos produzidos
- [x] Recomendação produzida — Promover para Downstream
- [x] Decision Package completo

---

# Next Step

Iniciar Downstream com a Camada 3 (mapeamento OBC → DORA) como primeiro entregável, seguido das Camadas 1–2 (glossário + dora-metrics.md).
