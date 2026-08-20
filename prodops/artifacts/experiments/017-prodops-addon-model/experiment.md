# EXP-017 — ProdOps Add-on Model (Open/Closed Principle)

## Status

- [ ] Planned
- [x] In Progress
- [ ] Completed
- [ ] Cancelled

---

# Business Goal

O Framework ProdOps é hoje uma entidade **fechada para extensão sem modificação**. Para incorporar um novo método de produto (PBB, Lean Inception, Design Sprint, Story Mapping), o único caminho é modificar a ontologia core ou os skills existentes — violando o Open/Closed Principle.

O objetivo deste experimento é definir um modelo de Add-on que permita ao Framework ser **aberto para extensão** (novos métodos plugáveis) sem ser **modificado** (ontologia e skills core imutáveis), com o PBB — Product Backlog Building (Aguiar & Caroli, 2021) — como primeiro Add-on de referência.

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
- [x] Framework ProdOps — design e arquitetura (payments-api é repositório consumidor pioneiro; framework decisions aqui propagam para todos os consumidores via prodops-framework)

## Dependências externas

- Repositório `prodops-portfolio` — destino final dos artefatos do Add-on model
- Repositório `prodops-framework` — mecanismo de distribuição para consumidores
- Livro *Product Backlog Building* (Aguiar & Caroli, 2021) — fonte do método PBB

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório

**Justificativa:** payments-api é repositório consumidor do Framework e possui histórico estabelecido de experimentos de arquitetura de framework (EXP-006, EXP-008, EXP-014, EXP-015, EXP-016). O Add-on model impacta diretamente o processo de Discovery/Inception deste produto — e a decisão de arquitetura produzida aqui serve como input para o prodops-portfolio implementar. Implementação final dos artefatos do Add-on acontece em `prodops-portfolio`.

---

# Question to Answer

1. **Como o Framework pode ser estendido com novos métodos sem modificar sua ontologia core?**
2. **Quais são os Extension Points estáveis que o Framework deve declarar?**
3. **Qual é o contrato mínimo que um Add-on precisa satisfazer para ser plugável?**
4. **Como o PBB mapeia para os conceitos ProdOps existentes (OBC, BDD, Discovery, Inception)?**
5. **Onde os artefatos do Add-on PBB vivem no repositório e como são consumidos por agentes?**

---

# Hypothesis

> Se o Framework declarar **Extension Points estáveis** — slots com contrato de entrada/saída — então qualquer método externo (PBB, Lean Inception, Design Sprint) pode se encaixar nesses slots sem alterar Journey, Cycle, Phase, Capability, Skill ou Step existentes.
>
> O PBB é o método ideal como primeiro Add-on porque: (1) complementa o Scrum sem substituí-lo, (2) produz os artefatos exatos que o ProdOps precisa na Inception (Personas → OBC stakeholders, Funcionalidades → OBC capabilities, PBIs → BDD Features, COORG → Iteration Backlog), e (3) é simples, rápido e enxuto — baixo overhead de integração.

---

# Design: Modelo de Add-on (OCP) — v2 (pós-pesquisa de indústria)

## Princípio

| Dimensão | Definição |
|---|---|
| **Fechado para modificação** | Ontologia core: Journey → Cycle → Phase → Capability → Skill → Step. Nenhum Add-on pode alterar esses conceitos. |
| **Aberto para extensão** | O Framework declara Extension Points — interfaces estáveis onde Add-ons se conectam declarando o que consomem, o que produzem e quais gates satisfazem. |

---

## Os 6 Invariantes da Indústria (validados em 10 sistemas)

A pesquisa comparativa de VS Code, Eclipse, Backstage, Babel, ESLint, Terraform, GitHub Actions, Gradle, Jenkins e Webpack revelou seis invariantes presentes em todos os sistemas maduros. O modelo ProdOps Add-on os incorpora integralmente.

### Invariante 1 — Separação entre Contrato e Implementação

O core conhece apenas o contrato; nunca as implementações concretas.

| Forma do contrato | Exemplo na indústria | Equivalente ProdOps Add-on |
|---|---|---|
| JSON schema em manifesto | VS Code `package.json/contributes` | `addon.yaml` + `extension-points.md` |
| XML Schema (`.exsd`) | Eclipse `plugin.xml` | — (YAML é mais legível) |
| TypeScript interface + ID | Backstage `createExtensionPoint` | EP-ID como string namespaced |
| Protocolo gRPC + Schema Go | Terraform | `addon.yaml` + Skill schema |

**Aplicação ProdOps:** o Framework define `extension-points.md` com o schema de cada EP. O Add-on satisfaz esse schema via `addon.yaml`. O Framework Skill nunca importa nem executa código do Add-on diretamente — apenas lê o manifesto e invoca o Add-on Skill como sub-rotina.

---

### Invariante 2 — Registro Declarativo + Ativação Lazy (Two-Phase Initialization)

Sistemas maduros separam *o que o Add-on declara* (parse estático, sem execução) de *quando o Add-on age* (ativação on-demand).

```
Fase 1 — Descoberta (sem execução de lógica):
  Framework lê todos os addon.yaml → constrói registry em memória
  Valida hooks contra extension-points.md
  Valida gates de entrada

Fase 2 — Ativação (quando o hook point é atingido):
  Framework Skill atinge EP-002 (inception.pre-icebox)
  Consulta registry → encontra pbb@1.0.0 registrado neste EP
  Invoca Add-on Skill: prodops/addons/pbb/skills/pbb.md
  Add-on produz artefatos → Framework continua flow
```

**Aplicação ProdOps:** O Framework Skill (ex: `/upstream` ou skill de Discovery) lê `addons/*/addon.yaml` na inicialização da sessão, valida contratos e só invoca o Add-on Skill quando o lifecycle atinge o hook point declarado.

---

### Invariante 3 — Inversão de Controle (o Core sempre chama o Add-on)

O Framework orquestra; o Add-on nunca modifica o Framework.

| Padrão | Exemplo | Aplicação ProdOps |
|---|---|---|
| Visitor Pattern | Babel, ESLint | Add-on "visita" artefatos ProdOps (OBC, BDD) sem reescrever sua estrutura |
| Hook/Event Pattern | Webpack Tapable | Framework Skill emite "evento" de hook point; Add-on Skill responde |
| Registry Pattern | VS Code, Backstage | Add-on registra capacidades; Framework as consulta quando necessário |
| Process Boundary | Terraform | Futuro: Add-ons como processos separados para isolamento máximo |

**Regra ProdOps:** O Add-on Skill nunca modifica `ontology.md`, skills existentes nem artefatos de outros Add-ons. Ele lê os artefatos que declarou em `artifacts.consumes` e escreve apenas os que declarou em `artifacts.produces`.

---

### Invariante 4 — Identidade Única com Namespace Hierárquico

Todos os sistemas têm namespace para evitar colisões entre plugins de origens diferentes.

**Esquema de nomenclatura ProdOps:**

```
Extension Points: prodops.<journey>.<hook>
  prodops.discovery.methods
  prodops.inception.pre-icebox
  prodops.backlog.prioritization
  prodops.artifacts.obc.sections
  prodops.bdd.story-generation

Add-on IDs: <method-id>@<semver>
  pbb@1.0.0
  lean-inception@1.0.0
  design-sprint@1.0.0
```

---

### Invariante 5 — Isolamento por API Surface

Sem processo separado, o isolamento é garantido por **leitura exclusiva de superfícies declaradas**.

**Regras de isolamento do Add-on ProdOps:**

```
✅ Add-on PODE:
   Ler artefatos listados em artifacts.consumes
   Escrever artefatos listados em artifacts.produces
   Invocar Skills do Framework como leitura (sem modificação)
   Criar novos artefatos nos paths declarados

❌ Add-on NÃO PODE:
   Modificar ontology.md, glossary.md, operating-model.md
   Modificar Skills existentes do Framework
   Escrever em paths fora de prodops/addons/<id>/
   Modificar artefatos OBC ou BDD fora do escopo do seu hook point
```

---

### Invariante 6 — Versionamento como Contrato de Primeira Classe

O `addon.yaml` declara compatibilidade com range (não versão exata), seguindo o padrão `>=min, <max`:

```yaml
compatibility:
  framework-version: ">=1.14.0"    # range, nunca exato
  extension-points:
    - id: prodops.inception.pre-icebox
      since: "1.14.0"
```

O Framework valida essa compatibilidade ao ler o manifesto (Fase 1 — Descoberta).

**Anti-padrão (observado em sistemas imaturos):** depender de versão exata (`== 1.14.0`) em vez de range — cria fragilidade a cada evolução do core.

---

## Extension Points declarados pelo Framework (v2 — com namespace e schema)

| ID namespaced | Hook Point | Quando é invocado | Artefatos consumidos | Artefatos produzidos |
|---|---|---|---|---|
| `prodops.discovery.methods` | Journey: Discovery | Técnica estruturada durante Discovery | Business Signal, OBC Draft | Experiment, Findings |
| `prodops.inception.pre-icebox` | Lifecycle: Inception, antes do Icebox | Enriquece OBC Draft com contexto | OBC Draft, Origin Stream | OBC enriquecido, BDD Features |
| `prodops.backlog.prioritization` | Product Backlog → Iteration Backlog | Priorização alternativa/adicional | PBIs, COORG criteria | Ordered Iteration Backlog |
| `prodops.artifacts.obc.sections` | OBC template | Seções adicionais no OBC | OBC Draft | OBC com seções extras |
| `prodops.bdd.story-generation` | BDD Feature pipeline | Geração customizada de User Stories | Funcionalidades, Personas | BDD Feature files |

Extension Points são **interfaces estáveis com versionamento** — declarados em `extension-points.md` com `since: <framework-version>`.

---

## Contrato do Add-on (addon.yaml v2 — incorporando invariantes)

```yaml
# prodops/addons/<id>/addon.yaml

# Invariante 4: identidade única com namespace
id: pbb
name: Product Backlog Building
version: 1.0.0
source: "Fábio Aguiar & Paulo Caroli — Editora Caroli, 2021"

# Invariante 6: range de compatibilidade, nunca versão exata
compatibility:
  framework-version: ">=1.14.0"
  extension-points:
    - id: prodops.inception.pre-icebox
      since: "1.14.0"
    - id: prodops.bdd.story-generation
      since: "1.14.0"
    - id: prodops.backlog.prioritization
      since: "1.14.0"

# Invariante 2: declaração estática dos hooks (lido na Fase 1, sem execução)
hooks:
  - extension-point: prodops.inception.pre-icebox
    priority: default          # se múltiplos Add-ons no mesmo EP, define ordem
  - extension-point: prodops.bdd.story-generation
  - extension-point: prodops.backlog.prioritization

# Invariante 1 + 5: contrato explícito de consumo e produção
artifacts:
  consumes:
    - type: obc
      state: draft
    - type: origin-stream
    - type: business-intent
  produces:
    - type: obc-sections
      schema: prodops/addons/pbb/artifacts/obc-sections.schema.yaml
    - type: bdd-feature
      schema: prodops/addons/pbb/artifacts/pbi.schema.yaml
    - type: pbb-canvas
      template: prodops/addons/pbb/artifacts/pbb-canvas.md

# Invariante 3: gates definem pré e pós-condições verificáveis pelo Framework
gates:
  entry:
    - obc.state == "draft"
    - business-intent.identified == true
  exit:
    - personas.count >= 1
    - funcionalidades.count >= 1
    - pbis.count >= 3
    - user-stories.written == true
    - coorg.applied == true

# Invariante 2: ativação lazy — o Skill só é carregado quando o hook point é atingido
skills:
  - path: prodops/addons/pbb/skills/pbb.md
    activated-by:
      - prodops.inception.pre-icebox
      - prodops.bdd.story-generation
      - prodops.backlog.prioritization
```

---

## Mapeamento PBB → ProdOps

| Conceito PBB | Equivalente ProdOps | Artefato produzido |
|---|---|---|
| Nome do Produto | Business Intent — nome do OBC | OBC header |
| Problemas | Business Signal — dores e lacunas | OBC section: Problems |
| Expectativas | OBC — estado desejado / hipóteses | OBC section: Expectations |
| Personas (O que faz / O que espera) | OBC — stakeholders e atividades | OBC section: Personas |
| Funcionalidades (Ação, Problema, Benefício) | OBC — Product Capabilities | OBC section: Features |
| Steps Map (ARO: Ação → Resultado → Objeto) | BDD Feature steps (Given/When/Then) | BDD Feature |
| PBIs como User Stories (3Ws: Quem/O quê/Por quê) | BDD Feature cards | User Story cards |
| Critérios de Aceite | BDD Acceptance Criteria | BDD Scenarios |
| Habilitador exploratório (Spike) | Upstream experiment | Experiment entry |
| Habilitador técnico | Non-functional PBI / Tech debt | OBC technical note |
| COORG (Classificar + Ordenar + ORGanizar) | Priorização do Iteration Backlog | Ordered backlog |
| Definição de Preparado (DoR) | Definition of Ready canônico ProdOps | DoR checklist |
| Definição de Pronto (DoD) | Definition of Done canônico ProdOps | DoD checklist |
| TAPAS (Dívida técnica) | Technical debt / Reliability Plan items | Reliability Plan |

---

## Fluxo: onde o PBB se encaixa no lifecycle ProdOps

```
INCEPTION
│
├─ Product Backlog (OBC = Draft)
│      │
│      ▼   ← EP-002: inception.pre-icebox
│   ┌─────────────────────────────────────────────┐
│   │  PBB Session (Add-on)                       │
│   │                                              │
│   │  PASSO 1 — Contextualizar produto            │
│   │    Nome do Produto → OBC Business Intent     │
│   │    Problemas → OBC section: Problems         │
│   │    Expectativas → OBC section: Expectations  │
│   │                                              │
│   │  PASSO 2 — Descrever Personas               │
│   │    Persona + O que faz + O que espera        │
│   │    → OBC section: Personas                  │
│   │                                              │
│   │  PASSO 3 — Entender Funcionalidades         │
│   │    Ação/Interação + Problema + Benefício     │
│   │    → OBC section: Features (capabilities)   │
│   │                                              │
│   │  PASSO 4 — Identificar PBIs (Steps Map)     │  ← EP-005
│   │    ARO: Ação → Resultado → Objeto            │
│   │    → BDD Features (User Stories + AC)        │
│   │                                              │
│   │  PASSO 5 — COORG                            │  ← EP-003
│   │    Classificar + Ordenar + ORGanizar         │
│   │    → Iteration Backlog priorizado            │
│   └─────────────────────────────────────────────┘
│      │
│      ▼
│   Icebox (OBC = Refining)
│   Assessment Review (PM + Tech Lead)
│      │
│      ▼
│   OBC = Committed → Iteration Backlog
│      │
│      ▼
│   DELIVERY (Bootstrap → Hack → ... → Promote)
```

---

## Estrutura de arquivos do Add-on (em prodops-portfolio)

```
prodops/
  addons/
    README.md                      ← modelo de Add-on (OCP contract)
    extension-points.md            ← EP-001 a EP-005 com contratos estáveis
    pbb/
      addon.yaml                   ← manifesto PBB
      README.md                    ← documentação humana do Add-on
      skills/
        pbb.md                     ← Skill executável para agentes
      artifacts/
        pbb-canvas.md              ← template do PBB Canvas
        persona.md                 ← template de Persona
        funcionalidade.md          ← template de Funcionalidade
        pbi.md                     ← template de PBI (modelo ARO)
      references/
        coorg.md                   ← técnica COORG detalhada
        steps-map.md               ← técnica Steps Map
        user-story.md              ← guia de User Stories (3Ws + INVEST + 3Cs)
```

## Alterações mínimas no Framework core

O `ontology.md` recebe uma seção nova sob "Camada de implementação":

**Add-on** — Uma extensão autocontida que se encaixa em um Extension Point declarado pelo Framework, sem modificar a ontologia core. Um Add-on declara o que consome, o que produz, em qual Extension Point atua e quais gates de entrada e saída deve satisfazer. Add-on é um conceito de implementação (como Skill e Step) — não é um conceito estrutural do Framework.

O `extension-points.md` novo arquivo documenta os EP-001 a EP-005 como interfaces estáveis.

---

# Perguntas — Status Após Experimento

| # | Pergunta | Status | Resposta |
|---|---|---|---|
| 1 | Como estender o Framework sem modificar ontologia? | ✅ Respondida | Extension Points estáveis com contrato addon.yaml |
| 2 | Quais Extension Points declarar? | ✅ Respondida | EP-001 a EP-005 (discovery.methods, inception.pre-icebox, backlog.prioritization, artifacts.obc.sections, bdd.story-generation) |
| 3 | Qual contrato mínimo de um Add-on? | ✅ Respondida | addon.yaml com id, hooks, artifacts.consumes, artifacts.produces, gates, skills |
| 4 | Como o PBB mapeia para conceitos ProdOps? | ✅ Respondida | Tabela de mapeamento completa — Personas→OBC, Funcionalidades→OBC, PBIs→BDD, COORG→Iteration Backlog |
| 5 | Onde vivem os artefatos do Add-on? | ✅ Respondida | prodops-portfolio/prodops/addons/pbb/ — fora do Framework core |

---

# Recommendation

- [x] Mover para Downstream
- [ ] Executar outro experimento Upstream
- [ ] Aguardar decisão de negócio
- [ ] Aguardar dependência externa
- [ ] Descartar capability

**Justificativa:** O design do Add-on model está completo e validado conceitualmente. O mapeamento PBB → ProdOps é consistente e sem conflito com a ontologia existente. A implementação dos artefatos (addons/README.md, extension-points.md, pbb/addon.yaml, pbb/skills/pbb.md) é trabalho Downstream claro, com escopo definido e reversível. Nenhuma questão aberta bloqueia a implementação.

---

# Decision Package

## Executive Summary

O ProdOps Framework precisa de um mecanismo para incorporar métodos externos (PBB, Lean Inception, Design Sprint) sem modificar sua ontologia core. Este experimento projetou um modelo de Add-on baseado no Open/Closed Principle, validado contra 10 sistemas de extensão maduros da indústria (VS Code, Eclipse, Backstage, Babel, ESLint, Terraform, GitHub Actions, Gradle, Jenkins, Webpack). O design incorpora os 6 invariantes que aparecem em todos os sistemas bem-sucedidos: separação contrato/implementação, registro declarativo + ativação lazy, inversão de controle, identidade namespaced, isolamento por API surface e versionamento com range constraints. O PBB foi mapeado integralmente para os conceitos ProdOps sem nenhum conflito ontológico.

## Decisão Recomendada

Implementar o Add-on model em `prodops-portfolio/prodops/addons/`, começando pelo Add-on PBB como referência. O design v2 (pós-pesquisa) incorpora os 6 invariantes da indústria e define dois mecanismos que não estavam no design v1: **Two-Phase Initialization** (discovery declarativa separada da ativação) e **namespace hierárquico** para Extension Points (`prodops.<journey>.<hook>`). A implementação inclui: (1) `extension-points.md` com 5 EPs namespaced e versionados, (2) `addon.yaml` v2 do PBB com compatibility ranges, (3) Skill `pbb.md` com ativação lazy, (4) templates de artefatos PBB, (5) seção Add-on mínima no `ontology.md`.

## Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Extension Points podem ficar desatualizados com evolução da ontologia | Médio | EP são documentados com contrato explícito; qualquer mudança no Framework exige revisão de EP |
| Add-ons podem criar dependência circular com Framework | Baixo | Add-on só consome EP declarados; nunca modifica Framework core |
| Proliferação descontrolada de Add-ons | Baixo | Cada Add-on exige addon.yaml com contrato formal; curadoria no addons/README.md |

## Oportunidades

- Onboarding de novos métodos (Lean Inception, Design Sprint, Story Mapping) como Add-ons futuros
- Skill `/pbb` executável por agentes para conduzir sessões de backlog building assistidas
- Reutilização do padrão Extension Points em outras camadas (ex: gates customizados, templates de OBC por domínio)

## Itens de Tracking

Nenhum item novo no tracking-list — este experimento produz Downstream direto.

## OBCs

Nenhum OBC novo gerado — implementação é infraestrutura de framework.

## Reliability Plan

Não aplicável para artefatos de processo.

## Escopo Downstream Recomendado

**Repositório alvo:** `prodops-portfolio`

**Entregáveis:**
1. `prodops/addons/README.md` — modelo de Add-on e OCP rationale
2. `prodops/addons/extension-points.md` — EP-001 a EP-005 com contratos
3. `prodops/addons/pbb/addon.yaml` — manifesto PBB
4. `prodops/addons/pbb/README.md` — documentação humana
5. `prodops/addons/pbb/skills/pbb.md` — Skill executável
6. `prodops/addons/pbb/artifacts/` — templates (canvas, persona, funcionalidade, pbi)
7. `prodops/addons/pbb/references/` — guias (coorg, steps-map, user-story)
8. `prodops/framework/ontology.md` — seção Add-on adicionada (mínima, não-disruptiva)

**Gate de saída:** todos os 8 artefatos presentes, addon.yaml válido, Skill pbb.md executável por agente.

---

# Output Artifacts

| Tipo | Artefato | Situação |
|---|---|---|
| Design Document | `experiment.md` | Draft — neste experimento |
| Skill | `prodops/addons/pbb/skills/pbb.md` | Pendente — Downstream em prodops-portfolio |
| Template | `prodops/addons/pbb/artifacts/` | Pendente — Downstream em prodops-portfolio |
| Framework Extension | `prodops/addons/extension-points.md` | Pendente — Downstream em prodops-portfolio |
| Ontology Update | `prodops/framework/ontology.md` | Pendente — seção Add-on |

**Promovido para Downstream:** - [ ] Sim — aguarda abertura de Work Item em prodops-portfolio

---

# Exit Criteria

- [x] Hipótese original respondida
- [x] Perguntas classificadas
- [x] Lacunas de conhecimento documentadas (nenhuma aberta)
- [x] Impacto arquitetural documentado
- [x] Impacto em confiabilidade documentado (não aplicável)
- [x] Artefatos atualizados (tracking-list + learnings)
- [x] Recomendação produzida
- [x] Decision Package completo

---

# Next Step

Abrir Work Item em `prodops-portfolio` para implementar o Add-on model como Downstream. Escopo: 8 artefatos listados acima, sem modificação disruptiva ao Framework core.
