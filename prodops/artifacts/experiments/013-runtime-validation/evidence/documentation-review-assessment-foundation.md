# Relatório — Assessment Journey Foundation
# ProdOps Framework — Fundação conceitual da Jornada Assessment

> **Data:** 2026-07-24
> **Tipo:** Fundação de Journey — validação de identidade e fronteiras
> **Status:** Concluído
> **Escopo:** `prodops/framework/journeys/assessment/README.md`

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| Journey definida | Assessment |
| Questão central | "Estamos melhorando continuamente o nosso modelo operacional?" |
| Ciclos propostos | 2 (Assessment Sync e Assessment Async) |
| Capabilities identificadas | 8 |
| Entradas mapeadas | 10 fontes distintas (primária: Operational Timelines) |
| Saídas mapeadas | 8 tipos de artefato (prospectivos e retrospectivos) |
| Critérios de sucesso definidos | 8 critérios verificáveis |
| Acoplamento OEM | Consumidor read-only — não emite eventos |
| Decisões arquiteturais anteriores alteradas | Nenhuma |
| Assessment é Journey distinta? | **Sim** — justificativa técnica na seção 7 |

---

## 2. Missão

**A Assessment responde uma pergunta que nenhuma outra Journey responde:**
"Estamos melhorando continuamente o nosso modelo operacional?"

Ela opera em duas dimensões complementares:

**Dimensão retrospectiva:** consome Timelines e Findings para avaliar se os ciclos passados
de Delivery e Diligence produziram evolução real — métricas, padrões, tendências.

**Dimensão prospectiva:** avalia riscos, hipóteses e prontidão de Work Items antes de
entrarem na Delivery — Reliability Plans, Decision Packages.

A missão completa não é apenas "olhar para trás" ou apenas "gate antes da execução". É
a integração das duas perspectivas que permite dizer: "sabemos como estamos, sabemos para
onde vamos, e sabemos o que precisa mudar."

---

## 3. Responsabilidades e fronteiras

### 3.1 O que pertence à Assessment

| Responsabilidade | Dimensão |
|---|---|
| Calcular métricas operacionais a partir de Timelines | Retrospectiva |
| Identificar padrões e tendências ao longo do tempo | Retrospectiva |
| Sintetizar Findings da Diligence em conclusões de modelo | Retrospectiva |
| Avaliar maturidade operacional | Retrospectiva |
| Propor evoluções de Journeys ou do Framework | Retrospectiva |
| Monitorar continuamente indicadores de saúde | Ambas |
| Avaliar riscos e oportunidades de Work Items | Prospectiva |
| Produzir Reliability Plans para gates formais | Prospectiva |
| Produzir Decision Packages para priorização | Prospectiva |
| Publicar resultados formalmente | Ambas |

### 3.2 O que NÃO pertence à Assessment

| Ação proibida | Razão |
|---|---|
| Executar qualquer Step da Delivery | Execução pertence à Delivery |
| Executar qualquer Step da Diligence | Execução pertence à Diligence |
| Emitir Operational Events | Assessment não escreve nas Timelines |
| Alterar Timelines existentes | Timelines são imutáveis |
| Gerenciar Work Items individualmente | Responsabilidade de Delivery e Diligence |
| Aprovar ou rejeitar promoções individuais | Decisões operacionais das Journeys de execução |
| Criar Event Types ou Shared Types | OEM governance — não Assessment |
| Priorizar o backlog diretamente | Informa, não decide |

---

## 4. Fronteiras com Delivery e Diligence

### 4.1 Assessment ≠ Delivery

| Dimensão | Delivery | Assessment |
|---|---|---|
| Questão | Como entrego este Work Item? | Estou melhorando o modelo? |
| Objeto de trabalho | Work Item individual | Modelo operacional agregado |
| Temporalidade | Transacional — por Work Item | Retrospectivo / contínuo |
| Escrita OEM | Sim — emite eventos nas Timelines | Não — consumidor read-only |
| Output | Software em produção | Insights, recomendações, planos |
| Trigger | Work Item no Iteration Plan | Cadência / limiar / sinal |

### 4.2 Assessment ≠ Diligence

| Dimensão | Diligence | Assessment |
|---|---|---|
| Questão | Este Work Item está conforme? | O modelo está melhorando? |
| Escopo | Conformance individual | Maturidade agregada |
| Temporalidade | Verificação periódica (scan) | Retrospectiva contínua |
| Output | Conformance (sim/não) | Tendências e recomendações |
| Ação | Sinaliza e repara divergências | Propõe evoluções |
| OEM | Produtor (Scan.Started, Flag.Completed etc.) | Consumidor read-only |

### 4.3 A sobreposição proibida

A Assessment **consome** Findings da Diligence mas **nunca** executa Diligence.
A Assessment **informa** a Delivery com Decision Packages mas **nunca** executa Delivery.

O acoplamento é estritamente via artefatos imutáveis (Timelines, Reports, Findings) —
nunca via chamada direta ou emissão de eventos.

---

## 5. Proposta de ciclos

### 5.1 Assessment Sync — Revisão Estruturada

```
Collect → Analyze → Synthesize → Report
```

Ciclo formal, acionado por trigger definido (cadência, limiar, sinal, solicitação).

| Step | Produto |
|---|---|
| Collect | Corpus de evidências indexado e qualificado |
| Analyze | Métricas calculadas + padrões identificados |
| Synthesize | Conclusões de alto nível + correlações |
| Report | Assessment Report + Recommendations publicados |

Analogia com outras Journeys:
- Delivery Sync: Bootstrap → Hack → Sync → Finish
- Diligence Sync: Capture → Attach → Promote → Close
- Assessment Sync: Collect → Analyze → Synthesize → Report

O padrão de 4 steps é consistente com as demais Journeys.

### 5.2 Assessment Async — Monitoramento Contínuo

```
Monitor → Alert → Evolve
```

Ciclo contínuo, sem trigger discreto — observa permanentemente os indicadores de saúde
operacional derivados das Timelines.

| Step | Produto |
|---|---|
| Monitor | Observação contínua de métricas e Findings |
| Alert | Sinal de limiar cruzado ou anomalia detectada |
| Evolve | Evolution proposal incremental |

Analogia com outras Journeys:
- Delivery Async: Ship → Validate → Promote
- Diligence Async: Scan → Flag → Repair
- Assessment Async: Monitor → Alert → Evolve

O Async da Assessment é menos transacional que os outros (o Monitor é contínuo, não
por Work Item) — mas o padrão de 3 steps é consistente.

### 5.3 Interação entre ciclos

```
Assessment Async (Monitor permanente)
    │
    │ limiar cruzado ou anomalia detectada
    ▼
Assessment Sync (Revisão estruturada acionada)
    │
    │ Report publicado
    ▼
Assessment Async (retoma monitoramento)
```

---

## 6. Proposta de Capabilities

| Capability | Função |
|---|---|
| **Evidence Collection** | Coleta, indexação e qualificação de evidências das Timelines e artefatos |
| **Metric Derivation** | Cálculo de métricas operacionais: Lead Time, Cycle Time, Block Time, DORA, Gate Failure Rate |
| **Pattern Recognition** | Identificação de padrões temporais e estruturais — tendências de melhoria ou degradação |
| **Maturity Evaluation** | Avaliação do nível de maturidade operacional com base nos padrões |
| **Risk and Opportunity Analysis** | Análise prospectiva de riscos e oportunidades antes da Delivery |
| **Recommendation Synthesis** | Formulação de Recommendations específicas, atribuídas, priorizadas e rastreáveis |
| **Evolution Proposal** | Proposta formal de evolução de Journeys, Skills ou Framework com evidência |
| **Continuous Monitoring** | Observação permanente de indicadores — detecta limiares e anomalias |

8 Capabilities identificadas, cobrindo ambas as dimensões (retrospectiva e prospectiva).

---

## 7. Entradas e saídas

### 7.1 Entradas (10 fontes)

| Entrada | Origem | Dimensão |
|---|---|---|
| Operational Timelines | Delivery, Diligence | Retrospectiva (primária) |
| Derived Metrics | Timelines (calculadas) | Retrospectiva |
| Findings | Diligence (Scan) | Retrospectiva |
| Divergence reports | Diligence (Scan) | Retrospectiva |
| OBCs | Artefatos | Ambas |
| Reliability Plans | Artefatos | Ambas |
| Release Trails | Artefatos | Retrospectiva |
| Evidence References | Event Instances (OEM) | Retrospectiva |
| Experimentos e hipóteses | Discovery | Prospectiva |
| Postmortems e incidentes | Operation | Retrospectiva |

### 7.2 Saídas (8 tipos)

| Saída | Dimensão | Destinatário |
|---|---|---|
| Assessment Report | Retrospectiva | Framework, Journeys, Stakeholders |
| Recommendations | Retrospectiva | Delivery, Diligence, Framework |
| Evolution Plan | Retrospectiva | Framework governance |
| Decision Package | Prospectiva | Delivery (gate de entrada) |
| Reliability Plan | Prospectiva | Delivery (gate de risco) |
| New Business Intents | Ambas | Discovery / backlog |
| Process improvement proposals | Ambas | Delivery, Diligence |
| Framework update suggestions | Ambas | Framework governance |

---

## 8. Integração com OEM

### 8.1 Papel: consumidor read-only

A Assessment não é produtora de eventos — ela é consumidora. Esta é a distinção mais
importante de sua relação com o OEM:

| Journey | Papel OEM |
|---|---|
| Delivery | Produtor — emite eventos nas Timelines |
| Diligence | Produtor — emite eventos nas Timelines |
| **Assessment** | **Consumidor read-only — nunca emite eventos** |

### 8.2 Mecanismos OEM utilizados

| Mecanismo | Como Assessment usa |
|---|---|
| **Derived State** | Entende o estado atual de conjuntos de Work Items sem armazenar |
| **Lookback** | Consultas retroativas: estado em data específica, tempo em cada estado |
| **Replay** (conceitual) | Reconstrução de distribuições históricas de estado por período |

### 8.3 O que a Assessment não faz com OEM

- Não cria Event Types
- Não emite Event Instances
- Não altera Timelines
- Não cria Shared Types (promoção é via `lifecycle.md`)
- Não possui Timeline própria no MVP

### 8.4 Potencial futuro: Timeline da Assessment

Em versões futuras, o ciclo Assessment Sync poderia ter sua própria Timeline para
registrar formalmente: `Assessment.Started`, `Evidence.Collected`, `Assessment.Published`.
Isso tornaria cada ciclo de Assessment rastreável via OEM. Não está no escopo atual.

---

## 9. Confirmação de invariantes arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| OEM (README, Ontology, Taxonomy, Lifecycle) | Não alterado |
| Event Type Schema | Não alterado |
| Event Instance Schema | Não alterado |
| Timeline OEM | Não alterado |
| Delivery Event Catalog | Não alterado |
| Diligence Event Catalog | Não alterado |
| Cross-Journey Event Analysis | Não alterado |
| Nenhum Event Type criado | Confirmado |
| Nenhum Shared Type criado ou promovido | Confirmado |
| Nenhuma Timeline própria criada | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 10. A Assessment é uma Journey realmente distinta?

### Resposta objetiva

**Sim. A Assessment é uma Journey realmente distinta e não pode ser absorvida pela
Delivery ou pela Diligence.** Justificativa técnica em três eixos:

---

### Eixo 1 — Abstração

Delivery e Diligence operam no nível de **Work Item individual**. Cada ciclo trata
de um único Work Item: "este OBC foi entregue?", "este Work Item está conforme?".

A Assessment opera no nível do **modelo operacional agregado**. Ela não pergunta
sobre um Work Item — ela pergunta sobre o conjunto: "a média de Lead Time está
melhorando?", "o Gate Failure Rate aumentou este trimestre?".

Absorver a Assessment pela Delivery significaria que a Delivery — enquanto executa
Work Items individuais — precisaria simultaneamente analisar tendências de todos os
Work Items anteriores. Isso é uma contradição de escopo.

---

### Eixo 2 — Temporalidade

Delivery e Diligence são **transacionais**: cada ciclo tem início, meio e fim claros
por Work Item. O tempo de referência é o tempo de execução do Work Item.

A Assessment é **retrospectiva e contínua**: ela analisa períodos, não transações.
O tempo de referência é a janela de análise (trimestre, mês, período pós-release).

Absorver a Assessment pela Diligence significaria que a Diligence — que verifica
conformance de Work Items individuais — precisaria também avaliar tendências
retrospectivas de todo o modelo. Isso é uma contradição de temporalidade.

---

### Eixo 3 — Relação com o OEM

Delivery e Diligence são **produtores** — elas criam eventos que registram o que
aconteceu. Sua existência é justificada pelos eventos que emitem.

A Assessment é um **consumidor read-only** — ela não emite eventos. Sua existência
é justificada pelos insights que produz a partir dos eventos existentes.

Se a Assessment fosse absorvida por uma Journey produtora, o OEM ficaria com um
Consumer permanente dentro de um Produtor — um paradoxo arquitetural. Consumers e
Producers têm responsabilidades, ciclos e acoplamentos incompatíveis.

---

### Conclusão

A Assessment não é uma "fase extra" da Delivery nem uma "verificação adicional" da
Diligence. Ela opera em uma abstração diferente, em uma temporalidade diferente, e
tem um papel oposto no OEM. Estas três diferenças são suficientes para justificar
uma Journey distinta — e insuficientes para justificar qualquer absorção.

Tentativas de absorção criariam:
- Na Delivery: um produtor que precisa analisar tendências do passado
- Na Diligence: um verificador de conformance que precisa avaliar maturidade agregada

Ambas as absorções produziriam Journeys com responsabilidades contraditórias.

---

## 11. Documentos criados e alterados

### Criados

| Arquivo | Conteúdo |
|---|---|
| `prodops/framework/journeys/assessment/README.md` | Fundação completa da Jornada Assessment — missão, ciclos, Capabilities, OEM integration, critérios de sucesso |
| `prodops/documentation-review-assessment-foundation.md` | Este documento |

### Alterados

| Arquivo | O que mudou |
|---|---|
| `prodops/framework/journeys/assessment/README.md` | Expandido de 43 linhas (placeholder) para fundação completa — conteúdo anterior incorporado |

Nenhum outro arquivo foi alterado.
