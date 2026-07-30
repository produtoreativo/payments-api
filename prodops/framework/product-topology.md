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

> **Exemplo de separação:** Um OBC com origem no Origin Stream "Business" (necessidade de mercado) pode impactar simultaneamente as dimensões Flow (novo comportamento de pagamento), Data (novo schema de invoice) e Components (novo serviço de emissão). A origem não determina o impacto.

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
    ├── Team
    ├── Flow
    ├── Data
    └── Components
```

**Leitura do diagrama:**

- O eixo vertical (Origin Streams → Local OBC) descreve o **fluxo de intenção** — como uma necessidade se transforma em contrato observável.
- A **Product Topology** está posicionada após o OBC porque é o OBC que materializa as mudanças sobre a estrutura do produto via Delivery.
- A Product Topology **não está no fluxo** — ela é permanente. O fluxo de trabalho termina; a estrutura do produto continua existindo e sendo modificada por cada OBC entregue.

---

## As quatro Product Dimensions

As quatro dimensões coexistem em qualquer produto. Não são hierárquicas. Não representam fases nem ciclos. Todo OBC pode impactar uma ou mais dimensões simultaneamente.

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

**O que é:** A dimensão comportamental do produto.

**Descreve:** Jornadas, processos, eventos, regras de negócio, estados, fluxos e automações que definem como o produto se comporta.

**Exemplos de impacto de OBC:**
- Novo fluxo de pagamento com etapas de validação adicionais
- Novo estado em uma máquina de estados de transações
- Automação de reconciliação que substitui processo manual
- Nova regra de negócio sobre expiração de invoice

**Distinção crítica:** Não confundir com as jornadas do Framework (Discovery, Delivery, Operation…) — que são o *processo de trabalho* do time. A Product Dimension "Flow" descreve o *comportamento do produto* que o cliente e os sistemas experimentam.

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

**O que é:** A dimensão física do produto.

**Descreve:** Aplicações, serviços, microsserviços, bancos de dados, filas, pipelines de dados, infraestrutura e repositórios que compõem a plataforma técnica do produto.

**Exemplos de impacto de OBC:**
- Novo provider de Pix como serviço independente dentro da plataforma
- Nova fila de mensagens para processamento assíncrono de confirmações
- Novo banco de dados para armazenar estados de reconciliação
- Novo pipeline de dados para auditoria de transações

---

## Relacionamento OBC → Product Topology

Um OBC **não pertence** a uma única Product Dimension. Um OBC pode modificar simultaneamente todas as quatro dimensões — o impacto depende do escopo da intenção, não da sua origem.

**Exemplo: OBC "Criar invoice Pix"**

| Product Dimension | Impacto concreto |
|---|---|
| **Team** | Nova responsabilidade operacional: o time passa a monitorar falhas de emissão de invoice |
| **Flow** | Novo fluxo de pagamento: Pix → Emissão de invoice → Confirmação → Reconciliação |
| **Data** | Novos contratos: schema de invoice, evento `invoice.created`, API de consulta de status |
| **Components** | Novo provider: serviço de emissão de invoice Pix integrado ao gateway de pagamentos |

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
