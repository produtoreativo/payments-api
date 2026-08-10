# Service Deck

O Service Deck é um canvas de página única que representa um serviço como se fosse um produto — com o mesmo grau de detalhe e as mesmas seções do Product Deck, mas com o serviço como unidade central de análise.

Um serviço listado no **Product Services** de um Product Deck possui exatamente um Service Deck. O Service Deck é o artefato que detalha aquilo que o Product Deck apenas enumera.

---

## Tipos de Product Service

Um Product Service pode ser de dois tipos, e o Service Deck aplica-se a ambos:

| Tipo | Definição |
|---|---|
| **Service** | Unidade deployável única: microsserviço, API, worker, processador de fila. Tem fronteiras claras, responsabilidade única e SLO próprio. |
| **Value Stream** | Agrupamento lógico de um ou mais Services que juntos entregam um resultado de negócio específico. O resultado não é atingido por nenhum serviço isoladamente — emerge da colaboração entre eles. Um Value Stream tem um Service Deck consolidado; cada Service constituinte pode ter ou não o seu próprio Service Deck, dependendo da maturidade e da necessidade operacional. |

---

## Elo com o Local OBC: a dimensão Data

Cada Service Deck corresponde a exatamente um **Local OBC**. É no OBC que vivem os contratos de dados do serviço:

- APIs públicas (endpoints, contratos de request/response)
- Eventos publicados e consumidos (domínio de eventos)
- Schemas de persistência relevantes externamente
- SLIs (Service Level Indicators) observáveis

O Service Deck não duplica o OBC — ele o **superficia** na seção Service Endpoints, tornando a dimensão Data visível como parte da visão operacional do serviço. O OBC é a fonte de verdade; o Service Deck é o ponto de leitura consolidado.

```
Service Deck
  └── consome → Local OBC
        ├── Data: APIs, eventos, schemas
        ├── SLIs → número de confiabilidade (surfaced no Product Deck)
        └── Reliability Rules → Reliability Plan
```

---

## Seções canônicas

O Service Deck replica a estrutura do Product Deck, com os termos ajustados para o escopo do serviço:

### 1. Service Vision

**Pergunta:** Para quem este serviço existe e que valor ele entrega?

Mesmo formato do Product Vision (Geoffrey Moore / Lean Inception), mas o consumidor pode ser outro serviço, outro time ou o produto como um todo:

```
Para [consumidor do serviço — time, serviço, produto],
que [necessidade ou problema],
o [nome do serviço]
é um [categoria: API, worker, value stream…]
que [diferencial principal].
Diferente de [alternativa ou ausência],
este serviço [benefício decisivo].
```

---

### 2. Service Endpoints (Data)

**Pergunta:** Quais são os contratos de dados deste serviço?

Esta é a seção que materializa a **dimensão Data** da Product Topology a nível de serviço. Fonte: Local OBC.

| Categoria | Exemplos |
|---|---|
| **APIs públicas** | `POST /payments`, `GET /invoices/{id}` — contrato de request/response |
| **Eventos publicados** | `payment.confirmed`, `invoice.issued` — schema e canal |
| **Eventos consumidos** | `order.created`, `refund.requested` — contrato de consumo |
| **Schemas externos** | Modelos de dados expostos para integrações |

Um serviço sem Service Endpoints definidos não tem contrato observável — não pode ser listado como Product Service no Product Deck.

---

### 3. Service Team

**Pergunta:** Quem é responsável por construir e operar este serviço?

Mesma estrutura do Product Team do Product Deck, mas scoped ao serviço:
- **Owner:** responsável pelo OBC e pelo SLO
- **On-call:** quem acionar em incidentes, com canal e tempo de resposta
- **Consumers:** times ou serviços que dependem deste serviço

---

### 4. Service Architecture

**Pergunta:** Como os componentes internos do serviço se conectam e quais são suas dependências?

Mapeia:
- Componentes internos do serviço (API layer, workers, banco de dados, cache)
- Dependências diretas de outros serviços do produto
- Dependências externas (providers, APIs de terceiros)

Corresponde à **Product Dimension `Components`** no escopo do serviço. Para um Value Stream, o diagrama mostra como os Services constituintes colaboram para produzir o resultado de negócio.

---

### 5. Service Reliability

**Pergunta:** Qual é o compromisso de confiabilidade deste serviço e como ele está sendo cumprido?

| Campo | Fonte | Descrição |
|---|---|---|
| **SLO** | Local OBC | Compromisso formal de disponibilidade/latência |
| **SLIs** | Local OBC | Métricas observáveis que provam o SLO |
| **Error Budget** | SLO − SLI atual | Margem disponível antes de violação |
| **MTTR** | Release Trail + Incidents | Tempo médio de recuperação |

Para um Value Stream, o SLO consolidado é derivado dos SLOs dos Services constituintes — geralmente o mais restritivo ou a combinação que reflita o caminho crítico.

---

### 6. Service Analytics

**Pergunta:** O serviço está entregando o resultado esperado para seus consumidores?

Métricas de negócio e operacionais específicas do serviço:
- Throughput (volume de operações processadas)
- Latência (p50, p95, p99)
- Taxa de erro (por tipo de falha)
- KPIs de negócio do serviço (ex.: taxa de aprovação de pagamentos, invoice success rate)

---

### 7. Service Consumers

**Pergunta:** Quem depende deste serviço e qual é o impacto de uma falha sobre eles?

Lista os consumidores diretos do serviço — outros serviços, produtos, times — com o impacto esperado de degradação ou indisponibilidade. Alimenta a Reliability Matrix do Product Deck.

O termo "cliente interno" é rejeitado. Consumidores são **parceiros de contrato** — cada um tem responsabilidade explícita sobre o contrato exposto pelo OBC.

---

## Localização canônica

```
prodops/artifacts/services/<service-slug>/service-deck.md
```

Um serviço tem exatamente um Service Deck. Para Value Streams:

```
prodops/artifacts/services/<value-stream-slug>/service-deck.md
prodops/artifacts/services/<value-stream-slug>/services/<service-slug>/service-deck.md  ← opcional por constituinte
```

---

## Ciclo de vida

O Service Deck é um artefato **vivo**, atualizado sempre que o estado do serviço ou do seu OBC muda:

| Momento | Atualização esperada |
|---|---|
| **Local OBC committed** | Criar ou atualizar Service Endpoints com contratos do OBC |
| **Nova capability em Operational** | Atualizar Service Endpoints, Service Reliability e Service Analytics |
| **Mudança de SLO** | Atualizar Service Reliability e refletir no número de confiabilidade do Product Deck |
| **Mudança de arquitetura do serviço** | Atualizar Service Architecture |
| **Novo consumidor** | Atualizar Service Consumers e Reliability Matrix do Product Deck |
| **Incidente** | Atualizar Service Reliability (MTTR, Error Budget) após postmortem |

---

## Relação com outros artefatos ProdOps

```
Service Deck
  ├── é referenciado por → Product Deck [Product Services]
  ├── consome → Local OBC  [Service Endpoints: APIs, eventos, schemas, SLIs]
  ├── consome → Reliability Plan  [Service Reliability: SLOs, análise de risco]
  ├── consome → Release Trail  [Service Analytics: métricas pós-entrega]
  ├── referencia → Product Topology: Components  [Service Architecture]
  ├── referencia → Product Topology: Data  [Service Endpoints — via Local OBC]
  └── alimenta → Reliability Matrix do Product Deck  [Service Consumers + SLO]
```

---

## Referências

→ [Product Deck](product-deck.md) — o artefato de nível de produto que referencia o Service Deck
→ [OBC: Observable Business Contract](obc.md) — fonte de verdade dos contratos de dados e SLIs
→ [Reliability Plan](artifact-types.md#reliability-plan) — análise de risco e SLOs detalhados
→ [Product Topology](product-topology.md) — as dimensões estruturais (Components, Data, Team, Flow)
→ [Matriz de Confiabilidade — Produto Reativo](https://produtoreativo.com.br/matriz-de-confiabilidade/)
