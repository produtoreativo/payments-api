# ProdOps Operating Model

## Modelo operacional

O ProdOps organiza o trabalho de produto e engenharia em camadas hierárquicas, com origem rastreável desde a fonte da necessidade até os artefatos produzidos:

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓
Intent → OBC draft no Icebox
  ↓
Exploration
  ↔ Continuous Assessment → Reliability Plan → Assessment Review
  ↓
OBC + BDD committed
  ↓
Backlog Management (Diligence)        ← Tracking List → Icebox → Roadmap → Release → Iteration
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

**Origin Stream** — a classificação da origem de uma Intent. Quatro possibilidades: Business (mercado, cliente, produto), Enterprise (compliance, regulação, governança), Team (processo, automações, produtividade), Technology (plataforma, segurança, infraestrutura). Toda Intent tem exatamente um Origin Stream. Ver [`origin-streams.md`](origin-streams.md).

**Intent** — ponto de entrada do Framework. Uma intenção de gerar valor ainda não comprometida. A Intent registra o "porquê" sem prescrever o "como". *Anteriormente chamada de Business Intent.*

**Exploration** — reduz incerteza e refina o OBC draft por meio da jornada Discovery. Discovery existe em ambos os modos; o rigor e o compromisso variam conforme Upstream ou Downstream. Ver [`flow.md`](flow.md).

**OBC (Observable Business Contract)** — nasce como draft quando a Intent entra no Icebox, é refinado por Exploration e Assessment e torna-se committed somente após Assessment Review. *Anteriormente definido incorretamente como Outcome-Based Criterion.*

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
Intent
  ↓ entra em
OBC draft no Icebox
  ↓
Exploration (Discovery) ↔ Assessment
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
