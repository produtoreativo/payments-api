# ProdOps Operating Model

## Arquitetura do ProdOps

O ProdOps é organizado em quatro níveis hierárquicos:

```
ProdOps Framework
       ↓
ProdOps Portfolio
       ↓
ProdOps Workspace
       ↓
Product Repository     ←  este repositório (payments-api)
```

| Nível | Responsabilidade | Não contém |
|---|---|---|
| **Framework** | Princípios, jornadas, capabilities, skills, templates, glossário | Roadmap, Backlogs, Business Intents, Releases, Features |
| **Portfolio** | Portfolio Tracking List (Business Signals), Business Intent Backlog (Business Intents), Roadmaps (VIEW), Platform Releases (VIEW), Milestones | Implementação de software |
| **Workspace** | Integração e execução conjunta de Product Repositories | Roadmap, Business Intents |
| **Product Repository** | Implementar e operar um produto específico | — |

Este repositório (`payments-api`) é um **Product Repository**. Serve como implementação de referência do Framework ProdOps. Os níveis Portfolio e Workspace existem na arquitetura e são referenciados nesta documentação; ainda não possuem repositórios físicos criados.

→ Ver [glossary.md](glossary.md) para definições canônicas de cada nível.

---

## GitHub no Execution Space

O GitHub é a ferramenta canônica para rastrear a **execução do trabalho** sobre os artefatos ProdOps. Artefatos (OBCs, BDD, Intents, etc.) vivem como arquivos Markdown no repositório — nunca como GitHub Issues.

### GitHub Projects como domínios de gestão

| Domínio | GitHub Project | Rastreia trabalho sobre |
|---|---|---|
| **Portfolio** | Portfolio GitHub Project | Work Items sobre Business Signals e Business Intents |
| **Product Repository** | Product Repository GitHub Project | Work Items sobre Business Intents, OBCs, BDD e Plans |

### GitHub Project Views como projeções

As Views de um GitHub Project são projeções sobre os dados — não backlogs separados:

**Portfolio GitHub Project Views:**
- Business Signals — todos os Business Signals
- Discovery — Business Signals em investigação
- Business Intent Backlog — Business Intents aceitas
- Roadmap — Business Intents por horizonte (now/next/later)
- Platform Releases — Business Intents por versão de plataforma
- Completed — Business Intents entregues

**Product Repository GitHub Project Views:**
- Product Backlog — todos os Business Intents
- Release Planning — Business Intents por versão de release
- Current Iteration — Business Intents da iteração atual
- Doing — Business Intents em execução
- Review — Business Intents em revisão
- Done — Business Intents entregues
- Reliability — Business Intents com Reliability Plan ativo
- Bugs — Business Intents de bug

### Work Items — tipos de operação

| Tipo de Work Item | Artefatos tipicamente afetados | Exemplos de operação |
|---|---|---|
| **Business Signal Work Item** | Business Signal | Investigar, Priorizar, Gerar Intent |
| **Business Intent Work Item** | Business Intent, OBC, BDD | Explorar, Refinar OBC, Revisar, Entregar |

Um Work Item deve sempre declarar: Artifact Type, Artifact ID, Operation, Journey. → [Knowledge vs Execution](knowledge-vs-execution.md)

### Ferramentas externas são sync opcionais

Jira, Azure DevOps e Linear podem receber sincronização de dados do GitHub, mas **não são a fonte de verdade** do estado do trabalho. O arquivo OBC `.md` é a fonte de verdade do conteúdo e do estado. GitHub Issues rastreiam o trabalho executado sobre o OBC — não são representações do OBC. Jira, Azure DevOps e Linear são ferramentas de sync opcionais sobre o GitHub, nunca fontes canônicas.

→ [Execution Mapping — operações por artefato](execution-mapping/README.md)
→ [Matriz de Mapeamento](execution-mapping/matrix.md)
→ [Schema de Work Item](execution-mapping/work-item-schema.md)

---

## Modelo operacional

O ProdOps organiza o trabalho de produto e engenharia em camadas hierárquicas, com origem rastreável desde a fonte da necessidade até os artefatos produzidos:

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓
Business Signal → Business Intent (com OBC draft como contrato) no BIB ou Product Backlog
  ↓
Exploration (Icebox)
  ↔ Continuous Assessment → Reliability Plan → Assessment Review
  ↓
OBC + BDD committed
  ↓
Backlog Management (Diligence)        ← Product Tracking List → Product Backlog → Icebox → Iteration Backlog → Iteration Plan
  ↓
Execution Mode
├── Upstream
└── Downstream
  ↓
Journey
├── Discovery
├── Delivery
├── Operation
├── Assessment
└── Diligence
  ↓
Phase
├── Bootstrap
├── Hack
├── Sync
├── Finish
├── Ship
├── Validate
└── Promote
  ↓
Practice
└── ProdOps TDD
  ↓
Delivery Capability
├── Commit Workflow
├── Contract Management
├── Evidence Management
├── Observability
└── Reliability
  ↓
Artifacts
├── OBCs
├── BDD Features
├── Plans
├── Trails
└── Evidence
```

→ [Fluxo completo: como cada etapa funciona](flow.md)
→ [Origin Streams: os quatro tipos de origem](origin-streams.md)
→ [Hierarquia de backlogs: definições e modelo oficial](backlogs.md)

---

**Origin Stream** — a classificação da origem de um Business Signal. Quatro possibilidades: Business (mercado, cliente, produto), Enterprise (compliance, regulação, governança), Team (processo, automações, produtividade), Technology (plataforma, segurança, infraestrutura). Todo Business Signal tem exatamente um Origin Stream. Ver [`origin-streams.md`](origin-streams.md).

**Business Signal** — qualquer oportunidade, hipótese, problema, benchmark ou ideia que merece atenção. Vive na Portfolio Tracking List ou Product Tracking List. Gera Business Intents quando investigado e reconhecido como estratégico.

**Business Intent** — decisão estratégica de perseguir valor. Pode ser criada a partir de um Business Signal ou diretamente no BIB. Vive no Business Intent Backlog e, após OBC Partitioning, também no Product Backlog. Possui um OBC como documento de contrato (Global OBC co-nasce no BIB; Local OBCs são criados por OBC Partitioning).

**Exploration** — reduz incerteza e refina o OBC draft por meio da jornada Discovery. Discovery existe em ambos os modos; o rigor e o compromisso variam conforme Upstream ou Downstream. Ver [`flow.md`](flow.md).

**OBC (Observable Business Contract)** — nasce como Draft quando a Business Intent entra no Business Intent Backlog (fluxo global) ou no Product Backlog (fluxo local). É refinado pela Discovery no Icebox até atingir o estado **Committed** (gate de entrada no Iteration Backlog). Fica **In Delivery** durante a Delivery e **Operational** na Operation.

**Continuous Assessment** — avalia continuamente riscos, oportunidades e decide o próximo passo.

**Execution Mode** — o nível de compromisso e critérios de qualidade aplicados:
- **Upstream** — permissivo, experimental, sem compromisso de entrega e com maturidade variável
- **Downstream** — compromisso de entrega; aplica todos os quality gates vigentes em todas as jornadas

**Journey** — o caminho de trabalho dentro de um modo de execução:
- Discovery, Delivery, Operation — jornadas clássicas
- Assessment, Diligence — jornadas transversais

**Phase** — a sequência de estágios dentro da jornada Delivery:
- CI Sync: Bootstrap → Hack → Sync → Finish
- CI Async: Ship → Validate → Promote

**Practice** — o método utilizado durante uma fase:
- ProdOps TDD (usado pelo Hack)

**Delivery Capability** — competências técnicas reutilizáveis consumidas pelas fases:
- Commit Workflow
- Contract Management
- Evidence Management
- Observability
- Reliability

**Artifacts** — artefatos produzidos e consumidos pelo Framework:
- OBCs, BDD Features, Plans, Trails, Evidence

---

## Journeys

### Discovery

Explora problemas, hipóteses e possibilidades. Discovery existe em Upstream e Downstream; não é sinônimo de nenhum dos modos.

→ [prodops/journeys/discovery/README.md](../journeys/discovery/README.md)

### Delivery

Implementação governada. Usa o conhecimento validado pela Exploration para entregar com confiança. Exige OBC committed antes de iniciar.

→ [prodops/journeys/delivery/README.md](../journeys/delivery/README.md)

### Operation

Operação contínua. Runbooks, incidentes, postmortems, trilha operacional.

→ [prodops/journeys/operation/](../journeys/operation/)

### Assessment

Jornada transversal. Avalia riscos, oportunidades, OBCs e Iteration Plans.

→ [prodops/journeys/assessment/README.md](../journeys/assessment/README.md)

### Diligence

Jornada transversal. Guardiã da consistência do sistema de trabalho do ProdOps. Garante que o estado de cada OBC permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão, sem modificar o código do produto.

→ [prodops/journeys/diligence/README.md](../journeys/diligence/README.md)
→ [Hierarquia de backlogs gerenciados](backlogs.md)

---

## Execution Modes

→ [prodops/execution-model/README.md](../execution-model/README.md)

---

## Ciclo de vida de uma Product Capability

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓ gera
Business Signal → Business Intent
  ↓ entra em
Business Intent Backlog (fluxo global) ou Product Backlog (fluxo local) → OBC draft
  ↓
Exploration (Discovery no Icebox) ↔ Assessment
  Experimento → aprendizado → Decision Package
  Assessment → riscos + Reliability Plan
  ↓ Assessment Review (PM + Tech Lead)
OBC committed + BDD Feature committed
  ↓ se aprovado
Iteration Plan (status: Entrou)
  ↓ Downstream (Delivery)
Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote
  ↓
Operation
```

---

## Princípios

→ [principles.md](principles.md)

## Glossário

→ [glossary.md](glossary.md)

## Fluxo completo

→ [flow.md](flow.md)

## Origin Streams

→ [origin-streams.md](origin-streams.md)
