# Product Deck

O Product Deck é um canvas de página única que agrega as informações essenciais de um produto digital — o que ele faz, o que ele não faz, quem o constrói, como é estruturado e quais métricas orientam decisões e avaliações contextuais.

Nasceu durante o Deploy First Development, inspirado pelo **Report A3 da Toyota** — método para resolução de problemas e coordenação de atividades que favorece pensamento estruturado e tomada de decisão baseada em evidências. Assim como o A3, o Product Deck força a síntese: tudo que importa cabe em uma página.

> **Princípio central:** qualquer membro do time, stakeholder ou colaborador externo deve conseguir entender o produto, seu estado e seus riscos com uma leitura do Product Deck — sem depender de documentação adicional para a visão de nível operacional.

---

## Relação com as jornadas ProdOps

O Product Deck não pertence a uma jornada específica — é um artefato **transversal**, consumido e atualizado em múltiplas jornadas:

| Jornada | Como o Product Deck é usado |
|---|---|
| **Assessment** | Fonte primária de contexto para avaliação de maturidade e premortems; a Arquitetura de Execução e a Matriz de Confiabilidade são insumos diretos |
| **Discovery** | Referência para validar se uma nova capability está alinhada ao escopo e à visão do produto |
| **Delivery** | Consultado durante Bootstrap para contexto de arquitetura e dependências; atualizado no Promote quando serviços ou equipe mudam |
| **Operation** | Product Analytics e Reliability Matrix são atualizados continuamente com dados operacionais |
| **Diligence** | Verifica consistência entre o estado declarado no Product Deck e o estado operacional real (backlogs, OBCs, Issues) |

---

## Seções canônicas

O Product Deck é composto por sete seções. Cada uma responde uma pergunta central:

### 1. Product Vision

**Pergunta:** Para quem este produto existe e que valor ele entrega?

Utiliza o formato de visão de produto de Geoffrey Moore (*Crossing the Chasm*), complementado pela abordagem de Lean Inception:

```
Para [persona/cliente-alvo],
que [necessidade ou problema],
o [nome do produto]
é um [categoria do produto]
que [diferencial principal].
Diferente de [alternativa atual],
nosso produto [benefício decisivo].
```

A Product Vision mantém o time focado no resultado esperado — não nas funcionalidades.

---

### 2. Product Services (Serviços do Produto)

**Pergunta:** Quais são os serviços que compõem este produto e qual é sua saúde operacional?

Cada entrada em Product Services representa um **Service Deck** — um artefato independente que toma o serviço como um produto e o descreve com o mesmo grau de detalhe do Product Deck. O Product Deck lista os serviços com seus indicadores de saúde; o Service Deck detalha cada um deles.

Um Product Service pode ser de dois tipos:

| Tipo | Definição | Quando usar |
|---|---|---|
| **Service** | Unidade deployável única: microsserviço, API, worker, processador de fila | O serviço tem fronteiras claras, responsabilidade única e SLO próprio |
| **Value Stream** | Agrupamento lógico de um ou mais Services que juntos entregam um resultado de negócio específico | O resultado só é atingido pela colaboração entre múltiplos Services que o time trata como uma unidade operacional |

No Product Deck, cada entrada é listada com dois indicadores obrigatórios:

| Campo | Descrição | Fonte |
|---|---|---|
| **Número de confiabilidade** | SLO atual em produção (ex.: 99,5%) | Local OBC → SLI |
| **Lead-time** | Tempo médio de entrega de mudanças no serviço | Release Trail → DORA |

**Elo com a dimensão Data:** cada Product Service possui exatamente um **Local OBC**. É no OBC que vivem os contratos de dados do serviço — APIs, eventos publicados e consumidos, schemas, SLIs. O Service Deck expõe esses contratos na seção Service Endpoints, tornando a dimensão Data visível a nível de serviço sem duplicar o OBC.

```
Product Service (listado no Product Deck)
    └── referencia → Service Deck
          ├── consome → Local OBC  [Data: APIs, eventos, schemas, SLIs]
          └── consome → Reliability Plan  [SLOs, análise de risco]
```

Um serviço sem Local OBC committed não deve aparecer como Product Service — deve ser sinalizado como pendente de contrato observável.

→ Definição completa do Service Deck: [`service-deck.md`](service-deck.md)

---

### 3. Product Team (Time do Produto)

**Pergunta:** Quem é responsável por construir e operar este produto?

Diferencia duas camadas:
- **Core Team:** membros que executam o produto — responsabilidade direta por OBCs, BDD Features e Reliability Plan.
- **Decision Participants:** stakeholders com poder de decisão sobre roadmap e operação — não são "clientes internos", são agentes de governança.

Inclui informações de acionamento (canal, horário, tempo de resposta esperado) — essenciais durante incidentes e premortems.

---

### 4. Product Execution Architecture (Arquitetura de Execução)

**Pergunta:** Como as partes do produto se conectam e quais são as dependências críticas?

Mapeia relações entre:
- Aplicações e microsserviços
- Componentes de infraestrutura (banco de dados, cache, filas)
- Serviços internos (outros produtos da plataforma)
- Serviços externos (integrações de terceiros)

Corresponde diretamente à **Product Dimension `Components`** da Product Topology.

É o insumo central dos premortems de Assessment: identificar riscos exige entender dependências. Um diagrama de arquitetura desatualizado invalida qualquer análise de risco.

---

### 5. Reliability Matrix (Matriz de Confiabilidade)

**Pergunta:** Quais aplicações são críticas e como elas se comportam sob falha?

Evolução da Matriz de Resiliência (inspirada no modelo do Shopify). Tabela que mapeia:
- Quais aplicações recebem mudanças de código
- Quais dependências (diretas e indiretas) cada aplicação possui
- Impacto de indisponibilidade de cada componente na experiência do cliente

No Product Deck, a Reliability Matrix funciona como **dashboard** — não apenas como documento estático. Alimenta sistemas de alerta inteligente e reduz MTTR ao tornar dependências visíveis durante incidentes.

→ Definição completa: [`matriz-de-confiabilidade`](https://produtoreativo.com.br/matriz-de-confiabilidade/)

---

### 6. Product Analytics

**Pergunta:** O produto está entregando o valor prometido?

Apresenta as métricas de negócio associadas aos serviços do produto — conversão, receita, retenção, adoção — e as métricas de confiabilidade operacional (SLIs, error budget, MTTR).

Conecta negócio e engenharia em uma visão unificada. Um serviço com SLO verde mas KPIs de negócio em queda sinaliza problema de valor — não de confiabilidade.

---

### 7. Stakeholders

**Pergunta:** Quem governa e evolui este produto além do time direto?

Lista responsáveis por gestão e evolução que impactam roadmap e operação — liderança de produto, representantes de negócio, parceiros regulatórios, squads consumidores.

O termo "cliente interno" é rejeitado. No ProdOps, toda relação entre times é de **parceria de produto** — cada parte tem responsabilidade explícita sobre o resultado compartilhado.

---

## Flow: do Origin Stream ao Release Trail

A dimensão **Flow** da Product Topology, aplicada ao escopo do Product Deck, representa a trilha completa de rastreabilidade de uma capability — desde a origem da necessidade até a evidência de entrega em produção.

O Product Deck consolida o estado atual do produto. Flow registra como esse estado foi construído e como cada mudança o atravessou:

```
Origin Stream (Business | Enterprise | Team | Technology)
    ↓  classifica a origem da necessidade
Business Signal  ·····  [Product Tracking List]
    ↓  Owner Approval
Business Intent + Local OBC Draft  ·····  [Icebox — Refining]
    ↓  Discovery: Upstream ou Downstream
Local OBC Committed + BDD Feature  ·····  [Iteration Backlog]
    ↓  entra no Iteration Plan
Delivery
  ├── CI Sync:   Bootstrap → Hack → Sync → Finish
  └── CI Async:  Ship → Validate → Promote
    ↓
Release Trail  ·····  [evidência formal de conclusão]
    ↓  alimenta
Product Analytics + Reliability Matrix  ·····  [Product Deck atualizado]
```

**O que o Flow registra para cada Product Service:**

| Ponto do Flow | Artefato | O que registra |
|---|---|---|
| Origem | Business Signal | Qual necessidade originou a capability |
| Compromisso | Business Intent + Local OBC | O que foi contratado e por quem |
| Contratos | Local OBC Committed | APIs, eventos, schemas, SLIs — dimensão Data |
| Especificação | BDD Feature | Comportamento esperado em Gherkin |
| Entrega | Release Trail | Evidência de conclusão com quality gates |
| Resultado | Product Analytics | KPIs de negócio e SLIs pós-entrega |

Esse rastreamento completo é o que permite ao Assessment reconstruir a história de maturidade do produto — não apenas seu estado atual. A Diligence usa essa trilha para verificar se o estado declarado no Product Deck corresponde ao portfólio de OBCs e ao histórico de Release Trails.

---

## Localização canônica

```
prodops/artifacts/product/product-deck.md
```

Um produto tem exatamente um Product Deck. Não existe Product Deck por feature, por release ou por iteração. O Product Deck representa o produto como um todo em seu estado atual.

---

## Ciclo de vida

O Product Deck é um artefato **vivo** — não tem estado de "concluído":

| Momento | Atualização esperada |
|---|---|
| **Nova capability em Operational** | Atualizar Product Services, Reliability Matrix e Product Analytics |
| **Mudança de arquitetura** | Atualizar Execution Architecture e Reliability Matrix |
| **Mudança de time** | Atualizar Product Team e Stakeholders |
| **Novo SLO comprometido** | Atualizar número de confiabilidade no Product Services |
| **Assessment de maturidade** | Revisar Product Analytics e Reliability Matrix como linha de base |
| **Premortem** | Consumption: Execution Architecture e Reliability Matrix são lidos como insumo |

A Diligence verifica periodicamente se o Product Deck está sincronizado com o estado operacional real dos OBCs e dos serviços.

---

## Relação com outros artefatos ProdOps

```
Product Deck
  ├── referencia → Service Deck  (um por Product Service)
  │     ├── consome → Local OBC  [Data: APIs, eventos, schemas, SLIs]
  │     └── consome → Reliability Plan  [SLOs, análise de risco]
  ├── consome → Release Trail  [Product Analytics: métricas pós-entrega + Flow]
  ├── referencia → Product Topology: Components  [Execution Architecture]
  ├── referencia → Product Topology: Team  [Product Team + Stakeholders]
  ├── referencia → Product Topology: Flow  [Origin Stream → Release Trail por capability]
  └── é consumido por → Premortem, Assessment, Bootstrap  [contexto de arquitetura e risco]
```

---

## Referências

- [Product Deck — Produto Reativo](https://produtoreativo.com.br/product-deck/)
- [Matriz de Confiabilidade — Produto Reativo](https://produtoreativo.com.br/matriz-de-confiabilidade/)
- [Visão e Missão do ProdOps — Produto Reativo](https://produtoreativo.com.br/visao-e-missao-do-prodops/)
- [Observabilidade em Primeiro Lugar — Produto Reativo](https://produtoreativo.com.br/observabilidade-em-primeiro-lugar/)
- Geoffrey Moore — *Crossing the Chasm* (formato de Product Vision)
- Toyota A3 Problem Solving (inspiração do formato canvas)
- Shopify Resilience Matrix (inspiração da Reliability Matrix)
