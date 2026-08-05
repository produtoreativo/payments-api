# Tipos Canônicos de Artefatos

Este documento define os tipos canônicos de artefatos do Framework ProdOps: o que cada tipo representa, quando nasce, a qual jornada pertence e como se relaciona com os demais.

Para governança (owners, aprovações, ciclo de vida), ver [artifact-governance.md](artifact-governance.md).
Para labels e campos do GitHub, ver [github-workspace.md](github-workspace.md).

---

## Cadeia de artefatos de produto

Os artefatos de produto seguem uma cadeia de refinamento progressivo — cada um presupõe o anterior:

```
Business Signal
    ↓ gera
Business Intent
    ↓ contém / origina
OBC (Global ou Local)
    ↓ especifica comportamento em
BDD Feature
    ↓ identifica riscos documentados em
Risk Register
    ↓ informa
Reliability Plan
```

Artefatos de execução (`Iteration Plan`, `Context Capsule`, `Release Trail`) são produzidos durante o Delivery e consomem os artefatos de produto acima.

---

## Artefatos de produto

### `business-signal`

**O que é:** observação de mercado, cliente, operação ou técnica que indica que algo pode precisar mudar. Não carrega solução — apenas o sinal.

**Nasce quando:** qualquer membro do time identifica um padrão ou problema que merece atenção. Pode vir de métricas, feedback de cliente, incidente, análise competitiva ou decisão estratégica.

**Jornada:** Assessment (captura e triagem) → alimenta Discovery ou Operation.

**Caminho canônico:** `prodops/artifacts/business-signals/<id>.md`

**Relações:** gera um `business-intent` quando o Product Owner aprova a investigação.

---

### `business-intent`

**O que é:** intenção de negócio estruturada — conecta um `business-signal` a uma hipótese de solução, define o owner e o modo de execução (Upstream ou Downstream).

**Nasce quando:** o Product Owner aprova um Business Signal e define que ele será investigado ou construído.

**Jornada:** Discovery (em ambos os modos) → Delivery (Downstream).

**Caminho canônico:** `prodops/artifacts/business-intents/<id>.md`

**Relações:** origina um OBC (Global ou Local). Em Downstream, deve ter OBC Committed antes de entrar no Iteration Plan.

---

### `global-obc`

**O que é:** Observable Business Contract que abrange múltiplas capabilities ou o produto inteiro. Define o contrato observável no nível de plataforma ou produto.

**Nasce quando:** uma Business Intent de nível de plataforma (Portfolio) é aceita e o escopo é amplo o suficiente para cruzar múltiplos repositórios.

**Jornada:** Discovery (Portfolio), Assessment, Delivery (Workspace).

**Caminho canônico:** `prodops/artifacts/obcs/<slug>-global.md`

**Relações:** pode ser particionado em múltiplos `local-obc` para repositórios específicos.

---

### `local-obc`

**O que é:** Observable Business Contract de uma capability específica dentro de um Product Repository. Define Business Outcome, Observable Events, SLIs, Reliability Rules e Response Contract.

**Nasce quando:** uma Business Intent entra no Product Backlog — começa como Draft e evolui até Committed conforme o Discovery avança.

**Jornada:** Discovery → Delivery → Operation → Assessment (retroativo).

**Caminho canônico:** `prodops/artifacts/obcs/<slug>.md`

**Status possíveis:** `Draft` → `Refining` → `Committed` → `In Delivery` → `Operational` → `Archived`

**Relações:** presuposto por `bdd-feature`, `reliability-plan`, `context-capsule` e `release-trail`. Sem OBC Committed, não há entrada no Iteration Plan.

---

### `bdd-feature`

**O que é:** especificação comportamental em formato Gherkin (Given/When/Then) que descreve os cenários esperados da capability. É a definição executável do que será construído.

**Nasce quando:** o OBC atinge estado Committed e o Tech Lead escreve os cenários que guiarão o ciclo TDD.

**Jornada:** Delivery (fase Hack — ciclo Red → Green → Refactor).

**Caminho canônico:** `prodops/artifacts/bdd/<slug>.feature`

**Relações:** presupõe `local-obc`. É consumido pelo `hack-tdd-agent` e referenciado pelo `release-trail`.

---

### `risk-register`

**O que é:** registro dos riscos mapeados para uma capability ou iteração — cada risco com impacto, probabilidade, criticidade e status de resolução.

**Nasce quando:** o OBC é comprometido e os riscos são mapeados antes da entrada no Downstream.

**Jornada:** Assessment (identificação) → Delivery (monitoramento) → Operation (revisão pós-go-live).

**Caminho canônico:** `prodops/artifacts/risks/risks.md` (registro consolidado por produto)

**Relações:** informa o `reliability-plan`. Riscos não resolvidos bloqueam o Promote sem aceite explícito.

---

## Artefatos de execução

### `iteration-plan`

**O que é:** plano da iteração ativa — lista as capabilities com status `Entrou`, mapeia DS-IDs para GitHub Issues e registra o histórico de iterações concluídas.

**Nasce quando:** o time decide quais capabilities entrarão na próxima iteração de Delivery.

**Jornada:** Delivery (CI Sync e CI Async).

**Caminho canônico:** `prodops/artifacts/plans/iteration-plan.md`

**Relações:** presupõe `local-obc` Committed + `bdd-feature` + `risk-register`. Referenciado pelo `context-capsule` e `release-trail`.

---

### `reliability-plan`

**O que é:** plano de confiabilidade com análise de riscos, roadmap de iniciativas (P0/P1/P2), SLOs operacionais e critérios de DoD além do funcional.

**Nasce quando:** a capability atende a pelo menos um dos gatilhos: impacto financeiro, integração externa, SLO comprometido, ou risco alto no `risk-register`.

**Jornada:** Assessment (criação via Premortem) → Delivery (referência durante Validate) → Operation (monitoramento contínuo).

**Caminho canônico:** `prodops/artifacts/plans/reliability/README.md`

**Relações:** referencia `local-obc` (SLIs), `risk-register` e alimenta os critérios do `release-trail`.

---

### `context-capsule`

**O que é:** resumo técnico gerado no Bootstrap que concentra tudo que o time precisa para executar o Hack sem reler os artefatos de origem. Contém DS-ID, correlation-id, paths dos artefatos, cenários BDD e estado atual.

**Nasce quando:** o downstream-agent executa o Plan Bootstrap (Etapa 3 — `Plan.Bootstrap.Issue.Entered`).

**Jornada:** Delivery (exclusivamente — produzido e consumido no CI Sync).

**Caminho canônico:** `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`

**Relações:** presupõe `local-obc`, `bdd-feature` e `iteration-plan`. Consumido pelo `hack-tdd-agent`.

---

### `release-trail`

**O que é:** evidência formal de conclusão de uma entrega — produzida pelo Finish após todos os quality gates passarem. Registra o que foi entregue, os critérios de saída e as evidências de validação.

**Nasce quando:** a fase Finish conclui com todos os gates verdes (lint, build, acceptance, no_mocks).

**Jornada:** Delivery (fase Finish) → Operation (referência histórica) → Assessment (retroativa).

**Caminho canônico:** `prodops/artifacts/release-trail/<iteration-id>-<slug>.md`

**Relações:** referencia `local-obc`, `bdd-feature` e `iteration-plan`. Consumido por retrospectivas e Assessment retroativo.

---

## Artefatos de conhecimento

### `architecture`

**O que é:** decisão ou documentação de arquitetura — ADRs, diagramas de componentes, decisões técnicas com contexto e consequências.

**Nasce quando:** uma decisão técnica relevante é tomada durante Discovery, Delivery ou Operation.

**Jornada:** Discovery (exploração), Delivery (decisão), Operation (evolução).

**Caminho canônico:** `prodops/artifacts/architecture/`

**Relações:** pode referenciar `local-obc` quando a decisão impacta o contrato observável.

---

### `experiment`

**O que é:** resultado de um experimento Upstream — hipótese, metodologia, resultados e aprendizados. Não pressupõe entrega.

**Nasce quando:** uma Business Intent entra no modo Upstream e o time executa um spike, protótipo ou teste de hipótese.

**Jornada:** Discovery (Upstream exclusivamente).

**Caminho canônico:** `prodops/artifacts/experiments/<id>.md`

**Relações:** pode evoluir para `business-intent` Downstream se os aprendizados validarem a hipótese.

---

### `evidence`

**O que é:** evidência pontual de uma fase — screenshot, log, resultado de teste, output de ferramenta. Complementa o `release-trail` com detalhe específico.

**Nasce quando:** qualquer fase do CI Sync ou CI Async precisa registrar uma evidência que não cabe no trail narrativo.

**Jornada:** Delivery (qualquer fase).

**Caminho canônico:** `prodops/artifacts/evidence/`

**Relações:** referenciado pelo `release-trail`.

---

## Tipos internos do Diligence

Estes tipos não são artefatos de produto — são outputs da jornada de Diligence. Não possuem templates de negócio, apenas estrutura operacional.

| Tipo | O que é | Nasce quando |
|---|---|---|
| `Finding` | Inconsistência, gap ou divergência detectada pela Diligence | Diligence Scan ou Capture identifica desvio |
| `Remediation` | Ação corretiva para resolver um Finding | Finding é aceito e uma ação concreta é definida |
| `Waiver` | Aceite explícito de um Finding sem correção imediata | Time decide conviver com o desvio por prazo definido |
| `Check` | Verificação pontual executada durante Diligence Sync | Diligence reage a um evento de Delivery |

Findings alimentam o Assessment quando indicam padrão sistêmico — não são apenas ruído operacional.

---

## Referências

→ [Governança de artefatos](artifact-governance.md) — owners, aprovações, ciclo de vida
→ [Glossário](glossary.md) — definições canônicas de cada conceito
→ [GitHub Workspace](github-workspace.md) — labels e campos por tipo
→ [OBC: especificação completa](obc.md)
→ [Jornadas](journeys/README.md)
