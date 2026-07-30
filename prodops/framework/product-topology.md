[English](product-topology.en.md)

# Product Topology

A **Product Topology** representa a organização estrutural permanente de um produto. Descreve as dimensões que coexistem em qualquer produto e sobre as quais os OBCs produzem mudanças.

**Product Topology não representa:** backlog, jornada, pipeline, fluxo, ciclo, processo.
**Product Topology representa:** a estrutura do produto — as dimensões que sempre existem, independente do estado do trabalho.

→ [OBC: Observable Business Contract](obc.md)
→ [Origin Streams: origens das Intents](origin-streams.md)
→ [Ontologia do Framework](ontology.md)
→ [Glossário](glossary.md)

---

## Separação ontológica: Origin Streams vs. Product Topology

Estes são dois conceitos completamente diferentes:

| Conceito | Pergunta que responde | Exemplos |
|---|---|---|
| **Origin Streams** | De onde surgiu esta necessidade? | Business, Enterprise, Team, Technology |
| **Product Topology** | Quais partes do produto serão impactadas? | Team, Flow, Data, Components |

**Origin Streams** (Business, Enterprise, Team, Technology) classificam a **origem** de um Business Signal — de onde veio a necessidade, quem a detém, qual o contexto de criação.

**Product Topology** (Team, Flow, Data, Components) descreve a **estrutura permanente do produto** — as dimensões que qualquer OBC pode modificar, independente de onde a intenção nasceu.

> **Exemplo de separação:** Um OBC com origem no Origin Stream "Business" (necessidade de mercado) pode impactar simultaneamente as dimensões Flow (registra o ciclo de vida da entrega pelas jornadas), Data (novo schema de invoice) e Components (novo serviço de emissão). A origem não determina o impacto.

---

## Posicionamento no Framework

```
Origin Streams (Business | Enterprise | Team | Technology)
       ↓  classificam a origem da necessidade
Business Signals
       ↓
Business Intent (+ Global OBC)
       ↓  OBC Partitioning ou Owner Approval
Local OBC committed
       ↓  implementação via Delivery
Product Topology     ← estrutura permanente do produto (não é fluxo)
    ├── Team         ← quem: organização, papéis, ownership
    ├── Data         ← o quê: contratos, entidades, schemas
    ├── Components   ← como: serviços, APIs, infraestrutura (comportamento funcional)
    └── Flow         ← quando/como evoluem: eixo temporal transversal às demais dimensões
```

**Leitura do diagrama:**

- O eixo vertical (Origin Streams → Local OBC) descreve o **fluxo de intenção** — como uma necessidade se transforma em contrato observável.
- A **Product Topology** está posicionada após o OBC porque é o OBC que materializa as mudanças sobre a estrutura do produto via Delivery.
- A Product Topology **não está no fluxo** — ela é permanente. O fluxo de trabalho termina; a estrutura do produto continua existindo e sendo modificada por cada OBC entregue.

---

## As quatro Product Dimensions

As quatro dimensões coexistem em qualquer produto. Não são hierárquicas. Não representam fases nem ciclos. Todo OBC pode impactar uma ou mais dimensões simultaneamente.

A dimensão **Flow** é transversal às demais: qualquer OBC, ao percorrer as jornadas do Framework, sempre impacta Flow — pois sempre deixa um rastro temporal na estrutura do produto.

### Team

**O que é:** A dimensão organizacional do produto.

**Descreve:** Ownership, responsabilidades, capacidades, papéis, colaboração, governança e modelo operacional do time que constrói e opera o produto.

**Exemplos de impacto de OBC:**
- Criação de nova responsabilidade operacional para um time (ex.: monitorar falhas de emissão de invoice)
- Redefinição de papéis entre times em um fluxo compartilhado
- Adoção de nova capability que altera o modelo de on-call ou plantão

**Distinção crítica:** Não confundir com o Origin Stream "Team" — que classifica a *origem* de uma necessidade (o time identificou o problema). A Product Dimension "Team" descreve o *impacto* sobre a organização do produto, independente de onde o OBC nasceu.

---

### Flow

**O que é:** O eixo temporal da Product Topology.

**Descreve:** Como as demais Product Dimensions — Team, Data e Components — evoluem ao longo das jornadas do Framework. Flow não executa nada: ele permite observar, por meio das jornadas (Discovery, Delivery, Operation, Diligence e futuras jornadas do Framework), como as mudanças produzidas por um OBC atravessam o tempo e se tornam parte permanente do produto.

Flow representa:
- **evolução** — a progressão de uma mudança desde a intenção até a consolidação no produto
- **transformação** — como as dimensões estruturais são alteradas por cada OBC ao longo do tempo
- **histórico** — o registro de quando e como cada mudança traversou as jornadas do Framework
- **lifecycle** — o ciclo de vida de uma entrega: nascimento (Discovery), implementação (Delivery), operação (Operation), validação (Diligence)

**Como Flow age na prática:** Um OBC que adiciona emissão de boleto cria responsabilidade em Team, contratos em Data, e serviços em Components. Flow registra como esse conjunto de mudanças percorre Discovery → Delivery → Operation → Diligence até se tornar parte permanente do produto. Flow não criou nada — ele representa o caminho temporal que as outras dimensões percorreram.

**Distinção crítica:** Flow não é comportamento funcional do produto. Não descreve processos de negócio, regras de negócio, máquinas de estado, automações ou funcionalidades. Esses conceitos pertencem à dimensão **Components** — que implementa o comportamento do produto. Flow responde exclusivamente *quando* e *como* as dimensões evoluem, nunca *o que* o produto faz.

---

### Data

**O que é:** A dimensão informacional do produto.

**Descreve:** Entidades de negócio, contratos de dados, schemas, persistência, integrações, eventos de domínio e APIs que compõem o modelo informacional do produto.

**Exemplos de impacto de OBC:**
- Novo schema de invoice com campos de rastreabilidade fiscal
- Novo evento de domínio emitido ao confirmar pagamento (ex.: `invoice.confirmed`)
- Novo contrato de API exposto para integrações externas
- Nova entidade de reconciliação com modelo de persistência próprio

---

### Components

**O que é:** A dimensão física e comportamental do produto.

**Descreve:** Aplicações, serviços, microsserviços, bancos de dados, filas, pipelines de dados, infraestrutura e repositórios que compõem a plataforma técnica do produto. **Os Components implementam o comportamento funcional do produto** — são eles que executam regras de negócio, funcionalidades, integrações, APIs e processos automatizados. O comportamento do produto emerge da colaboração entre seus Components.

**Exemplos de impacto de OBC:**
- Novo serviço de emissão de boleto (Invoice Service) integrado ao provider Asaas
- Nova API exposta para consulta de status de invoice
- Novo worker para processamento assíncrono de confirmações de pagamento
- Nova fila de mensagens para desacoplamento entre emissão e confirmação

---

## Relacionamento OBC → Product Topology

Um OBC **não pertence** a uma única Product Dimension. Um OBC pode modificar simultaneamente todas as quatro dimensões — o impacto depende do escopo da intenção, não da sua origem.

**Exemplo: OBC "Adicionar emissão de boleto"**

| Product Dimension | Impacto concreto |
|---|---|
| **Team** | Novo responsável operacional: o time passa a monitorar falhas de emissão no provider Asaas |
| **Data** | Novo contrato de invoice (campos de boleto), novo evento de domínio `boleto.issued` |
| **Components** | Invoice Service, Asaas Provider, API de consulta de status, Worker de confirmação |
| **Flow** | Registra como essas mudanças percorreram Discovery → Delivery → Operation → Diligence até se tornarem parte permanente do produto |

**Regra:** Ao escrever ou refinar um OBC, identificar quais Product Dimensions serão impactadas. Isso informa arquitetura, responsabilidades, riscos e a necessidade de um Reliability Plan — mas não altera a origem do OBC nem o fluxo de Delivery.

---

## O que Product Topology não é

| Conceito | Por que não é Product Topology |
|---|---|
| **Backlog** | O backlog representa *trabalho em gestão*. A Product Topology representa *a estrutura que o trabalho modifica*. |
| **Jornada do Framework** | As jornadas (Discovery, Delivery, Operation…) são o *processo de trabalho*. A Product Topology é *o que existe no produto*, independente do processo. |
| **Pipeline** | Um pipeline é uma sequência de passos de execução. A Product Topology é uma estrutura permanente — não tem início nem fim. |
| **Origin Stream** | Origin Streams classificam a *origem* da necessidade. A Product Topology classifica o *impacto estrutural* sobre o produto. |
| **Cycle** | Um Cycle (CI Sync, CI Async, diligence-sync…) é uma sequência de Phases de trabalho. A Product Topology não é executável — é descritiva. |

---

## Terminologia canônica

| Usar | Evitar |
|---|---|
| **Product Topology** | Layers, Domains, Architecture Domains, Streams (como substituto) |
| **Product Dimensions** | Views, Perspectives, Pillars, Concerns |
| **Team, Flow, Data, Components** | Outros nomes para as quatro dimensões |

---

## Referências

→ [OBC: Observable Business Contract](obc.md)
→ [Origin Streams: origens das Intents](origin-streams.md)
→ [Ontologia do Framework](ontology.md)
→ [Glossário](glossary.md)
→ [Fluxo do Framework](flow.md)
