# OBC — Observable Business Contract

O **Observable Business Contract** é o contrato vivo que representa uma intenção de negócio durante todo o seu ciclo de vida. É a fonte de verdade do trabalho — conecta negócio, produto, arquitetura, engenharia, operação, observabilidade e confiabilidade. Não deve existir outro documento exercendo esse papel.

O OBC existe em dois níveis distintos: **Global OBC** e **Local OBC**. Eles não são hierárquicos no sentido de herança — são especializações de escopo.

→ [Template de Global OBC](../templates/obcs/global-obc.md)
→ [Template de Local OBC](../templates/obcs/local-obc.md)
→ [OBCs do produto](../artifacts/business/obcs/)
→ [Fluxo do framework](flow.md)
→ [Hierarquia de backlogs](backlogs.md)

---

## Os dois níveis do OBC

### Global OBC

O **Global OBC** representa uma intenção de negócio completa — independente de produtos, times ou repositórios. É o contrato canônico da capability de negócio.

**Foco:** estratégico.

**Pertence a:** plataforma (BIB). Nunca a um produto.

**Nasce em:** Business Intent Backlog, quando uma Business Intent é aceita.

**Vive durante:** todo o ciclo de vida da intenção — não desaparece após a decomposição. Continua evoluindo durante Discovery, Delivery e Operation.

**Contém:**
- Objetivo de Negócio
- Valor de Negócio
- Stakeholders
- Regras de Negócio
- Eventos de Negócio
- KPIs / Resultados Esperados
- Value Stream
- Produtos envolvidos (quando conhecidos)
- Rastreabilidade dos Local OBCs

**Não contém:** detalhes de implementação, APIs específicas, repositórios, BDD, critérios de aceite técnicos.

**Localização:** Repositório de portfólio da plataforma (externo a este repositório de produto).

---

### Local OBC

O **Local OBC** representa a responsabilidade de **um único produto**. No fluxo global, especializa uma parte do Global OBC; no fluxo local, representa diretamente uma Business Intent aceita pelo produto. Pertence exatamente a um Product Backlog.

**Foco:** implementação e entrega de produto.

**Pertence a:** Product Backlog de um produto específico.

**Nasce em:** Product Backlog, por Particionamento do OBC no fluxo global ou por Owner Approval no fluxo local.

**Relação com a origem:** quando originado no Portfolio, não é uma cópia — é uma **especialização/partição** do Global OBC e deve referenciá-lo. Quando originado localmente, deve referenciar a Business Intent e o Product Tracking Item que justificaram o Owner Approval.

**Contém:**
- Referência de origem obrigatória: Global OBC (fluxo global) ou Business Intent + Product Tracking Item (fluxo local)
- Produto / Repositório / Bounded Context
- APIs e Eventos
- BDD / Critérios de Aceite
- Observabilidade (Observable Events)
- Regras de Confiabilidade
- Contrato de Resposta
- Dependências Técnicas
- Evidências

**Localização:** `prodops/artifacts/business/obcs/<slug>.md`

---

## Relação entre os níveis

```
Fluxo global: 1 Global OBC → N Local OBCs
Fluxo local:  1 Intent local → 1 Local OBC
```

Nunca o inverso. Use os termos: **decomposição**, **especialização**, **partição**. NUNCA use: pai, filho, herança.

---

## Particionamento do OBC

O **Particionamento do OBC** é a capability responsável por transformar um Global OBC em Local OBCs. Ocorre entre o Discovery no BIB e a criação de itens nos Product Backlogs dos produtos.

**Responsabilidades do Particionamento:**
- Identificar os produtos envolvidos
- Identificar os repositórios
- Identificar os Bounded Contexts
- Decompor o Global OBC
- Criar os Local OBCs
- Manter a rastreabilidade entre eles

**Resultado:** cada produto recebe um Local OBC em seu Product Backlog. O Global OBC recebe a tabela de rastreabilidade atualizada com os Local OBCs criados.

**Quem executa:** Portfolio PM + Tech Leads dos produtos envolvidos.

---

## As 4 dimensões do OBC

O OBC é o contrato que satisfaz simultaneamente as 4 dimensões de origem de uma intenção de negócio:

| Dimensão | Pergunta que responde | Seções do OBC |
|---|---|---|
| **Business** | O que o negócio precisa alcançar? | Objetivo, Valor de Negócio, KPIs, Regras de Negócio, Eventos |
| **Enterprise** | Quais restrições e padrões organizacionais se aplicam? | Stakeholders, Value Stream, Dependências, Compliance |
| **Team** | O que o time precisa para entregar com confiança? | BDD, Critérios de Aceite, Plano de Confiabilidade, Riscos |
| **Technology** | Como a arquitetura e os sistemas suportam a entrega? | APIs, Eventos, Observabilidade, Contrato de Resposta, Dependências Técnicas |

Essas dimensões correspondem aos 4 Origin Streams do Framework. O OBC não é uma perspectiva — é a síntese das 4.

---

## Estados

Os estados representam **maturidade do contrato**, não estado do software.

| Estado | Quando | Descrição |
|---|---|---|
| **Draft** | BIB / Product Backlog — entrada | Criado; pode estar incompleto; registra intenção inicial e hipóteses |
| **Refining** | Product Backlog — view Icebox | Em refinamento ativo; Discovery/Upstream podem estar ocorrendo |
| **Committed** | Product Backlog — view Iteration Backlog | Informações mínimas validadas; pronto para Delivery |
| **In Delivery** | Iteration Plan → Delivery | Em execução; implementação em andamento |
| **Operational** | Operation | Em produção; atualizado com evidências operacionais |
| **Archived** | — | Intenção encerrada; histórico preservado |

---

## Ciclo de vida

### Global OBC

| Onde o item está | Estado do Global OBC | O que acontece |
|---|---|---|
| Portfolio Tracking List | Não existe | Business Signal ainda não gerou uma Business Intent reconhecida |
| Business Intent Backlog | Draft | Global OBC criado; captura Business Intent e hipóteses iniciais |
| BIB — view Roadmap | Draft | Item posicionado em horizonte estratégico |
| BIB — view Platform Release | Draft | Item agrupado em versão de plataforma |
| Discovery (BIB) | Refining | Exploração refina o Global OBC; hipóteses testadas |
| Particionamento do OBC | Refining | Local OBCs criados; rastreabilidade estabelecida |
| Operation | Operational | Atualizado com evidências consolidadas de todos os produtos |
| — | Archived | Intenção encerrada |

### Local OBC

| Onde o item está | Estado do Local OBC | O que acontece |
|---|---|---|
| Particionamento do OBC | Draft | Local OBC criado com referência ao Global OBC |
| Product Backlog — view Icebox | Refining | Discovery refina o Local OBC; critérios emergem |
| Assessment Review | Candidato a Committed | OBC revisado por PM + Tech Lead; seções obrigatórias validadas |
| Product Backlog — view Iteration Backlog | Committed | Critérios mínimos validados; Downstream pode iniciar |
| Iteration Plan / Delivery | In Delivery | Guia a implementação; BDD Feature o operacionaliza |
| Operation | Operational | Em produção; complementado com métricas, SLOs, incidentes |
| — | Archived | Intenção encerrada |

O OBC registra o **histórico vivo do trabalho**: por quais estados passou, quando, decisões tomadas, como os critérios evoluíram, referências a experimentos e riscos.

---

## Rastreabilidade

A rastreabilidade deve funcionar em **ambas as direções**.

**Fluxo global** (quando a Business Intent vem do Portfolio):
```
Business Signal (1:N) → Business Intent → Repositório A
                                        → Repositório B  (via Local OBCs — documentos de contrato)
                                        → Repositório C
```

> O OBC não é uma entidade sequencial separada da Intent — é o documento de contrato da Intent, refinado progressivamente. O OBC Partitioning cria documentos Local OBC por produto envolvido.

**Fluxo local** (quando a Business Intent vem do produto):
```
Business Signal → Business Intent + Product Tracking Item → Local OBC → Repositório
```

**Navegação descendente:** do Global OBC, chegar a qualquer Local OBC e ao repositório que o implementa.

**Navegação ascendente:** de qualquer Local OBC, chegar à sua origem: Global OBC e Business Intent global (fluxo global), ou Business Intent e Product Tracking Item (fluxo local).

No fluxo global, o Global OBC mantém a tabela de rastreabilidade e cada Local OBC referencia o Global OBC de origem. No fluxo local, o Local OBC referencia diretamente a Business Intent e o Product Tracking Item que justificaram o Owner Approval.

---

## Refinamento Contínuo do OBC

O OBC nunca é considerado finalizado. Continua evoluindo durante:
- **Discovery:** novas hipóteses e experimentos atualizam o contrato
- **Delivery:** decisões de implementação refinam os critérios
- **Operation:** evidências operacionais, incidentes e postmortems enriquecem o contrato

Toda nova evidência atualiza o contrato. O OBC é um documento vivo — não um artefato gerado uma vez e arquivado.

---

## OBC no Upstream

Durante o Upstream, o OBC permanece em Draft ou Refining. Pode ser alterado livremente, pode estar incompleto, não bloqueia experimentos. Registra aprendizados, hipóteses e decisões produzidas pelos experimentos. Nenhuma Skill deve exigir OBC completo durante o Upstream.

OBCs produzidos dentro de experimentos Upstream permanecem no diretório do experimento (`prodops/journeys/discovery/experiments/<NNN-slug>/obcs/`) até a promoção formal.

**Nota sobre modos:** Upstream e Downstream são **modos de execução**, não fases ou estágios. Um item pode iniciar Upstream em qualquer estágio do ciclo de vida — quando concluído, retorna ao estágio original. O modo nunca muda o estágio.

---

## OBC no Downstream

Ao entrar no Downstream, o Local OBC deixa de ser apenas um registro — passa a ser o contrato operacional da entrega. É refinado no Icebox até atingir o estado Committed, então controla toda a evolução das jornadas seguintes.

O compromisso pode ser declarado antes da prontidão. O conjunto mínimo exigido para atingir **Downstream Ready** e iniciar uma fase de Delivery é:
- Local OBC committed em `prodops/artifacts/business/obcs/<slug>.md` com estado Committed
- BDD Feature committed em `prodops/artifacts/business/bdd/<slug>.feature`
- Riscos documentados e item `Entrou` no Iteration Plan
- Reliability Plan atualizado quando houver movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração de persistência ou segurança

---

## OBC e as Skills

Todas as Skills do Downstream utilizam o Local OBC como principal fonte de contexto. As Skills nunca geram informações paralelas que substituam o OBC. Novos artefatos produzidos por Skills complementam ou referenciam o OBC. O OBC permanece como a única fonte de verdade da intenção.

---

## Governança

### Global OBC

| Campo | Valor |
|---|---|
| **Owner** | Portfolio PM |
| **Onde nasce** | Business Intent Backlog |
| **Artefato canônico** | Repositório de portfólio da plataforma (externo a repositórios de produto) |
| **Quem modifica** | Portfolio PM, Tech Leads (com registro de mudanças) |
| **Quem aprova** | Portfolio PM |
| **Consumidores** | Local OBCs, Particionamento do OBC, Roadmap, Platform Release |
| **Ciclo de vida** | Draft → Refining → Operational → Archived |
| **Jornadas** | Discovery (BIB), Operation |

### Local OBC

| Campo | Valor |
|---|---|
| **Owner** | Product Manager + Tech Lead do produto |
| **Onde nasce** | Product Backlog (após Particionamento do OBC) |
| **Artefato canônico** | `prodops/artifacts/business/obcs/<slug>.md` (quando committed) |
| **Quem modifica** | Product Manager, Tech Lead, engenheiros (com registro de mudanças) |
| **Quem aprova** | Product Manager + Tech Lead (Assessment Review) |
| **Consumidores** | Delivery, Reliability Plan, BDD Feature, Release Trail, Iteration Plan |
| **Ciclo de vida** | Draft → Refining → Committed → In Delivery → Operational → Archived |
| **Jornadas** | Discovery, Delivery, Operation, Assessment, Diligence |

---

## Localização dos artefatos

| Situação | Localização |
|---|---|
| OBC exploratório (em experimento Upstream) | `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md` |
| Global OBC committed | Repositório de portfólio da plataforma (externo a este repositório) |
| Local OBC committed | `prodops/artifacts/business/obcs/<slug>.md` |

---

## Quando não usar

Não usar OBC como substituto de tarefa técnica isolada ou ticket de bug sem Business Intent correspondente. GitHub Issues são **representações operacionais** de uma entidade já definida no Framework (Business Signal ou Business Intent) — não são o ponto de entrada do trabalho. O OBC é um documento Markdown — não tem representação como Issue. Jira, Azure DevOps e Linear são ferramentas de sync opcionais sobre o GitHub, nunca o ponto de entrada canônico.

---

## Referências

→ [Template de Global OBC](../templates/obcs/global-obc.md)
→ [Template de Local OBC](../templates/obcs/local-obc.md)
→ [OBCs do produto](../artifacts/business/obcs/)
→ [Fluxo do framework](flow.md)
→ [Hierarquia de backlogs](backlogs.md)
→ [Governança de artefatos](artifact-governance.md)
→ [Fases: Concepção e Inception](phases.md)
→ [Jornada Discovery](../journeys/discovery/README.md)
→ [Reliability Plans](../journeys/assessment/reliability-plans/README.md)
