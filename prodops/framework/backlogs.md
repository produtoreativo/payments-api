# Hierarquia de Backlogs

O Framework ProdOps organiza o trabalho em dois fluxos hierárquicos: um de **plataforma** (Portfolio) e um de **produto** (Product Repository). Cada backlog responde a uma única pergunta e possui responsabilidades bem definidas.

O trabalho nunca pula níveis sem justificativa explícita registrada no OBC.

---

## Modelo de entidades → backlogs

| Entidade | Onde vive | Representação no GitHub |
|---|---|---|
| **Business Signal** | Portfolio Tracking List (plataforma) ou Product Tracking List (produto) | Business Signal Issue |
| **Business Intent** | Business Intent Backlog e Product Backlog | Business Intent Issue |

> **Nota:** A Business Intent existe tanto no Business Intent Backlog quanto no Product Backlog (após OBC Partitioning). Cada Intent possui um Local OBC como documento de contrato. O OBC é um documento Markdown — não tem representação como Issue.

**Regra crítica:** Entidades nunca mudam de identidade. Um Business Signal **gera** Business Intents — não se torna uma. Uma Business Intent pode ser criada diretamente no BIB sem passar pela Tracking List. Quando originada de um Business Signal, mantém referência opcional ao Signal de origem.

---

## Fluxo Global — Plataforma → Produto

```
Portfolio Tracking List    ← Business Signals da plataforma (O que merece atenção?)
          ↓ (Business Signal gera Business Intent (1:N))
Business Intent Backlog    ← Business Intents (O que merece Discovery?)
    │         │              Global OBC Draft nasce aqui
    │         │
    │         ├─ Roadmap          [VIEW sobre BIB: em qual horizonte estratégico?]
    │         └─ Platform Release [VIEW sobre BIB: em qual versão da plataforma?]
    │
    │   (Discovery no BIB)
          ↓
OBC Partitioning           ← Business Intent → Local OBCs (um por produto)
          ↓
Product Backlog            ← OBCs do produto (fonte de verdade)
    │         │
    │         ├─ Icebox           [VIEW sobre Product Backlog: estado Refining]
    │         ├─ Iteration Backlog [VIEW sobre Product Backlog: estado Committed]
    │         └─ Release          [VIEW sobre Product Backlog: agrupado por versão]
    │
    │   (item com Local OBC Committed + BDD + critérios satisfeitos)
          ↓
Iteration Plan             ← execução da iteração atual
          ↓
Delivery
          ↓
Operation                  ← Refinamento Contínuo do OBC
```

> **Roadmap e Platform Release são VIEWs sobre o BIB** — não são backlogs separados.
> **Icebox, Iteration Backlog e Release são VIEWs sobre o Product Backlog** — não são filas separadas. Um item não sai do Product Backlog ao entrar em uma dessas views; ele permanece no Product Backlog e recebe um estado que determina qual view o representa.

---

## Fluxo Local — Produto

```
Product Tracking List      ← Business Signals do produto (O que merece atenção?)
          ↓ (Business Signal gera Business Intent (1:N) + Local OBC)
Premortem + Análise de Risco Preliminar
          ↓
Owner Approval
          ↓
Product Backlog            ← OBCs do produto (Local OBC nasce aqui no fluxo local)
[continua no fluxo comum — Icebox/Iteration Backlog/Release como VIEWs]
```

> **Nota sobre Reliability Plan no fluxo local:** A etapa pré-Product Backlog exige Premortem e análise de risco preliminar. O Reliability Plan formal é produzido pela Assessment durante o Icebox e torna-se gate de Delivery quando houver movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração de persistência ou segurança.

Após entrar no **Product Backlog**, a origem do item deixa de importar. Todos os itens seguem exatamente a mesma jornada — independente de terem vindo do Portfolio ou do fluxo local.

---

## Backlogs da Plataforma

### Portfolio Tracking List

**Pergunta:** Quais Business Signals merecem atenção na plataforma?

**Contém:** APENAS Business Signals. Nunca Business Intents. Nunca OBCs.

**Propósito:** Registrar qualquer Business Signal cujo escopo está indefinido ou ultrapassa um único produto. O sinal pertence à plataforma — ainda não se sabe qual produto ou time vai resolvê-lo.

**Quando usar:** O sinal envolve negócio, cadeia de valor, múltiplos produtos ou plataforma inteira. A propriedade do problema ainda não está clara. Exemplos: oportunidades de mercado sem produto definido, mudanças regulatórias que afetam vários sistemas, iniciativas de plataforma transversais.

**Não usar quando:** O sinal já tem destino certo — um produto ou time específico que claramente o resolve. Nesse caso, o sinal pertence à Product Tracking List do produto.

**Independência:** Business Signals da Portfolio Tracking List não são copiados para Product Tracking Lists de produtos candidatos. O item permanece na Portfolio Tracking List até ser triado e direcionado. Não existe duplicação entre os dois fluxos.

**Não contém:** OBC. Compromisso. Identificador permanente. Business Intents.

**Quando avançar:** Quando o Business Signal tiver sido compreendido o suficiente para ser reconhecido como estratégico — ao que o sinal **gera** uma nova Business Intent que entra no Business Intent Backlog.

**Gerenciado por:** Portfolio.

---

### Business Intent Backlog

**Pergunta:** O que merece Discovery?

**Propósito:** Representar Business Intents aceitas para Discovery a nível de plataforma. É aqui que o **Global OBC** nasce como Draft. O BIB contém apenas Business Intents (e seus Global OBCs associados) — nunca Local OBCs, nunca Business Signals.

**Contém:** APENAS Business Intents.

**O que acontece ao entrar neste backlog:**
- A Business Intent recebe um identificador permanente.
- Um **Global OBC Draft** é criado — captura a Business Intent e hipóteses iniciais de negócio.
- Inicia-se o ciclo de vida do trabalho.

**Compromisso:** A Business Intent é aceita para Discovery. Ainda não existe compromisso de implementação. Produtos, repositórios e número de Local OBCs ainda são desconhecidos neste momento.

**Dimensões sobre o BIB:** Itens do BIB podem receber dimensões estratégicas sem sair dele:
- **Roadmap** — posiciona o item em um horizonte de entrega (agora, próximo, futuro).
- **Platform Release** — agrupa o item na versão da plataforma à qual pertence.

Um item pode estar no BIB, associado a um Roadmap e a uma Platform Release, ao mesmo tempo. Essas dimensões são projeções — não filas pelas quais o item passa sequencialmente.

**Quando o item deixa o BIB:** Após o Discovery no BIB e o Particionamento do OBC, o Portfolio direciona os Local OBCs criados para os Product Backlogs dos produtos envolvidos.

**Gerenciado por:** Portfolio.

---

### OBC Partitioning

**O que é:** Capability responsável por transformar o Global OBC em Local OBCs — um por produto envolvido. Ocorre após o Discovery no BIB, antes da criação de itens nos Product Backlogs dos produtos.

**Responsabilidades:**
- Identificar os produtos envolvidos na implementação
- Identificar os repositórios correspondentes
- Identificar os Bounded Contexts
- Decompor o Global OBC em partições de responsabilidade
- Criar os Local OBCs com referência ao Global OBC
- Manter a tabela de rastreabilidade no Global OBC

**Resultado:** cada produto recebe um Local OBC em seu Product Backlog. O Global OBC registra a rastreabilidade de todos os Local OBCs.

**Quem executa:** Portfolio PM + Tech Leads dos produtos envolvidos.

---

### Roadmap

**Natureza:** View estratégica sobre o Business Intent Backlog — não é uma fila. Itens não "entram" no Roadmap; eles permanecem no BIB e recebem uma posição no horizonte estratégico.

**Pergunta:** Em qual horizonte de entrega este item se encaixa?

**Propósito:** Organizar a sequência estratégica dos itens do BIB por horizonte (agora / próximo / futuro), Milestones e dependências entre produtos. Permite ao Portfolio comunicar intenção sem comprometer entrega.

**O que representa:** Uma projeção temporal dos itens do BIB — quais serão endereçados em qual janela de tempo.

**Não é:** Uma lista de tarefas. Os itens no Roadmap ainda vivem no BIB e podem ser removidos, repriorizado ou redirecionados sem processo formal de remoção.

**Compromisso:** Intenção estratégica, não compromisso de entrega. A entrega só se torna compromisso quando o item entra no Product Backlog de um produto.

**Gerenciado por:** Portfolio. Vive em ferramentas externas de gestão estratégica.

---

### Platform Release

**Natureza:** View de agrupamento sobre o Business Intent Backlog — não é uma fila. Itens não "passam" pela Platform Release; eles permanecem no BIB e são associados a uma versão da plataforma.

**Pergunta:** Quais itens do BIB compõem esta versão da plataforma?

**Propósito:** Agrupar itens do BIB que formam uma entrega coerente da plataforma como um todo — uma combinação de versões de Product Repositories que serão lançadas juntas.

**Exemplo:**
- Platform Release 3.0 = payments-api v3 + webshop-api v8 + order-api v2

**O que representa:** Um agrupamento estratégico de itens do BIB por versão de plataforma. É a decisão do Portfolio de quais produtos e versões serão coordenados numa mesma entrega.

**Responsabilidade:** Os Product Repositories não controlam a Platform Release. A responsabilidade é exclusivamente do Portfolio.

**Relação com o Product Backlog:** A associação de um item a uma Platform Release pode preceder ou acompanhar o direcionamento para o Product Backlog de um produto — mas não o substitui. O item só entra no fluxo de produto quando o Portfolio o direciona explicitamente para o Product Backlog.

**Gerenciado por:** Portfolio.

---

## Backlogs do Produto

### Product Tracking List

**Pergunta:** Quais Business Signals merecem atenção neste produto?

**Contém:** APENAS Business Signals. Nunca Business Intents. Nunca OBCs.

**Propósito:** Capturar Business Signals já direcionados a este produto ou time específico. A propriedade já está definida — sabe-se que o problema pertence aqui.

**Quando usar:** O Business Signal tem destino certo: este produto, este time. Não precisa de triagem de plataforma. Exemplos: bug identificado neste serviço, dívida técnica interna, oportunidade de melhoria de performance deste domínio, sinal vindo de postmortem ou operação deste produto.

**Não usar quando:** O sinal é amplo demais, envolve múltiplos produtos ou a propriedade ainda não está clara. Nesse caso, o sinal pertence à Portfolio Tracking List.

**Independência:** A Product Tracking List é autônoma — não depende da Portfolio Tracking List e não recebe cópias dela. Um Business Signal que chega aqui já tem destino definido e segue diretamente para o fluxo local (Premortem + Owner Approval → Product Backlog), sem passar pelo Portfolio.

**Não contém:** OBC. Compromisso. Identificador permanente. Business Intents.

**Quando avançar:** Via Premortem + Análise de Risco Preliminar + Owner Approval → Product Backlog.

**Artefato canônico:** `prodops/artifacts/product/backlogs/tracking-list.md`

---

### Product Backlog

**Natureza:** Backlog — fonte de verdade de todo trabalho aceito pelo produto. Os itens vivem aqui do aceite até a entrega. Icebox, Iteration Backlog e Release são VIEWs sobre estes itens, não destinos separados.

**Pergunta:** O que foi oficialmente aceito pelo Product Owner?

**Contém exclusivamente:** Business Intents. Cada Intent possui um Local OBC como documento de contrato. O Product Backlog nunca contém Business Signals isolados ou Global OBCs.

**Dois caminhos de entrada:**

| Origem | Caminho de entrada |
|---|---|
| Plataforma | Local OBC criado pelo OBC Partitioning (de uma Business Intent), direcionado pelo Portfolio após Discovery no BIB |
| Local | Product Tracking Item (Business Signal) promovido via Premortem + Análise de Risco Preliminar com Owner Approval — gera Business Intent + Local OBC Draft |

**O que acontece ao entrar:**
- O Product Owner formaliza a aceitação.
- Se ainda não existia (caminho local), uma **Business Intent** + **Local OBC Draft** são criados.
- O item inicia seu ciclo de vida rastreável no produto.
- O item recebe o estado inicial **Draft**. Quando o Discovery ativo começa, transiciona para **Refining** e passa a ser representado na VIEW Icebox.

**Após a entrada, a origem deixa de importar.** O item evolui de estado no Product Backlog: Draft → Refining (VIEW Icebox) → Committed (VIEW Iteration Backlog) → In Delivery (Iteration Plan) → Operational.

> **Promoção de Upstream:** Um item promovido de Upstream que satisfaz os critérios do estado Committed pula o refinamento no Icebox e aparece na VIEW Iteration Backlog. O Product Owner ainda precisa selecioná-lo explicitamente para o Iteration Plan.

**Compromisso:** O Product Owner comprometeu-se a investigar e entregar este item.

---

### Icebox

**Natureza:** VIEW sobre o Product Backlog — não é uma fila separada. Representa os itens do Product Backlog que ainda estão em refinamento: Local OBC incompleto, decisões em aberto, Discovery em andamento.

**Pergunta:** Quais itens do Product Backlog ainda estão sendo refinados para Delivery?

**O que representa:** Um item está na VIEW Icebox enquanto o Local OBC ainda não atingiu o estado Committed. O Discovery necessário ocorre neste estado. O estado do Local OBC é **Refining**.

**O Discovery no estado Icebox pode ser:**
- **Funcional** — entender o que deve ser construído
- **Técnico** — entender como construir com confiança
- **Operacional** — entender como operar e monitorar

**Transição de estado:** O item sai da VIEW Icebox quando o Local OBC atinge o estado Committed — passa a ser representado na VIEW Iteration Backlog.

**Artefato canônico:** `prodops/artifacts/product/backlogs/icebox-backlog.md`

---

### Iteration Backlog

**Natureza:** VIEW sobre o Product Backlog — não é uma fila separada. Representa os itens do Product Backlog que estão comprometidos e prontos para iniciar Delivery: Local OBC Committed, Discovery concluído, decisão de entrega assumida.

**Pergunta:** Quais itens do Product Backlog estão prontos para ser desenvolvidos?

**O que representa:** Um item está na VIEW Iteration Backlog quando satisfaz todos os critérios de prontidão. O estado do Local OBC é **Committed**. A única decisão restante é a prioridade do Product Owner para a próxima iteração.

**Não é refinamento.** Refinamento acontece no estado Icebox. Um item que chega aqui está pronto — não precisa de mais Discovery.

**Critérios para estar nesta view:**
- Local OBC no estado Committed
- Discovery funcional, técnico e operacional suficiente
- Riscos identificados em `prodops/journeys/assessment/risks.md`

**Critérios para entrar no Iteration Plan (iniciar execução):**
- Local OBC committed em `prodops/artifacts/business/obcs/`
- BDD Feature committed em `prodops/artifacts/business/bdd/`
- Entrada no Reliability Plan quando aplicável: movimentação financeira, integração externa, mudança de SLO, risco alto/crítico, alteração de persistência ou segurança

**Artefato canônico:** `prodops/artifacts/product/backlogs/iteration-backlog.md`

---

### Release

**Natureza:** VIEW sobre o Product Backlog — não é uma fila separada. Representa os itens do Product Backlog agrupados por versão de release do produto.

**Pergunta:** Quais itens do Product Backlog fazem parte desta versão de release?

**O que representa:** Uma visão organizada dos Local OBCs agrupados pela versão de release à qual contribuem. Facilita o planejamento, a comunicação e o acompanhamento de versões.

**Não confundir com:** Platform Release (que é uma VIEW sobre o BIB, de responsabilidade do Portfolio). A VIEW Release do Product Backlog é de responsabilidade do Product Owner.

**Gerenciado por:** Product Owner.

---

### Iteration Plan

**Pergunta:** O que está sendo executado nesta iteração?

**Propósito:** Representar exclusivamente uma execução de Delivery em andamento. Não é um backlog de planejamento ou priorização — é o registro da iteração atual.

**Contém:**
- Itens escolhidos do Iteration Backlog
- Estratégia de execução
- Jornadas CI Sync (Bootstrap → Hack → Sync → Finish)
- Jornadas CI Async (Ship → Validate → Promote)
- Acompanhamento da implementação
- Evidências produzidas
- Critérios de saída da iteração

**Não contém:** Priorização. Refinamento. Itens do Icebox. Itens sem Local OBC Committed.

**Artefato canônico:** `prodops/artifacts/governance/plans/iteration-plan.md`

---

## OBC como identificador permanente

O Local OBC acompanha o trabalho por toda a sua vida no produto — do momento em que é criado pelo Particionamento (ou pelo Owner Approval no fluxo local) até a operação em produção. Cada transição de backlog acima representa também uma transição de estado do Local OBC.

O Global OBC acompanha a intenção de negócio de ponta a ponta — sobrevive à decomposição e continua sendo refinado durante Operation.

→ **Ciclo de vida completo, composição e governança do OBC:** [`obc.md`](obc.md)

---

## GitHub no Execution Space

O GitHub é a ferramenta canônica para rastrear a **execução do trabalho** sobre os artefatos ProdOps. Artefatos (OBCs, BDD, Intents, etc.) vivem como arquivos Markdown no repositório — nunca como GitHub Issues.

**Dois tipos de Work Item no Framework:**
- **Business Signal Work Item** — representa trabalho sobre um Business Signal na Portfolio Tracking List ou Product Tracking List
- **Business Intent Work Item** — representa trabalho sobre uma Business Intent no BIB e no Product Backlog

**GitHub Projects como domínios de gestão:** O Portfolio GitHub Project **rastreia o trabalho** sobre Business Signals e Business Intents. O Product Repository GitHub Project **rastreia o trabalho** sobre Business Intents, OBCs, BDD e Plans do produto. O OBC é um documento Markdown — não tem representação como Issue.

**Jira, ADO, Linear são sync opcionais.** Ferramentas externas podem receber sincronização dos dados do GitHub, mas não são a fonte de verdade do estado do trabalho. O OBC no arquivo `.md` é a fonte de verdade do conteúdo e do estado. GitHub Issues rastreiam o trabalho executado sobre o OBC — não são representações do OBC. Ferramentas externas são espelhos de conveniência.

→ [Schema de Work Item](execution-mapping/work-item-schema.md)
→ [Execution Mapping](execution-mapping/README.md)

---

## Diligence como guardiã da hierarquia

A Diligence é a jornada responsável por manter os backlogs sincronizados em todos os níveis — plataforma e produto.

> **Princípio:** A Diligence garante que o estado de cada OBC permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão, sem modificar o código do produto.

**O que a Diligence mantém sincronizado:**
- Estado do Local OBC em cada backlog (Product Backlog, Icebox, Iteration Backlog, Iteration Plan)
- Estado do Global OBC no BIB e sua rastreabilidade
- Representações operacionais nas ferramentas (GitHub Issues, Jira, Azure DevOps)
- Rastreabilidade:
  - Knowledge: Business Signal → Business Intent → Global OBC → Local OBC
  - Execution: Work Item (referencia artefato) → PR → Release → Operation

  Os dois espaços são independentes. Um artefato não "gera" Issues sequencialmente — Issues representam trabalho iniciado sobre ele quando necessário.
- Consistência entre artefatos ProdOps e ferramentas externas

→ [Jornada Diligence](../journeys/diligence/README.md)

---

## Responsabilidade por backlog

| Backlog / View | Entidade | Pergunta | Gerenciado por |
|---|---|---|---|
| Portfolio Tracking List | Business Signals | Quais Business Signals merecem atenção na plataforma? | Portfolio |
| Business Intent Backlog | Business Intents | O que merece Discovery? | Portfolio |
| Roadmap (VIEW sobre BIB) | Business Intents | Qual a sequência estratégica de entrega? | Portfolio |
| Platform Release (VIEW sobre BIB) | Business Intents | O que compõe esta versão da plataforma? | Portfolio |
| OBC Partitioning | — | Como decompor o Global OBC em Local OBCs? | Portfolio PM + Tech Leads |
| Product Tracking List | Business Signals | Quais Business Signals merecem atenção neste produto? | Product Repository |
| Product Backlog | Business Intents | O que foi oficialmente aceito pelo Product Owner? | Product Owner |
| Icebox (VIEW sobre Product Backlog) | Business Intents | O que ainda está sendo preparado para Delivery? (Refining) | Product Owner + Tech Lead |
| Iteration Backlog (VIEW sobre Product Backlog) | Business Intents | O que está pronto para ser desenvolvido? (Committed) | Product Owner |
| Release (VIEW sobre Product Backlog) | Business Intents | O que compõe esta versão do produto? | Product Owner |
| Iteration Plan | Business Intents | O que está sendo executado nesta iteração? | Time de Delivery |

---

## Referências

- `prodops/artifacts/product/backlogs/tracking-list.md` — Product Tracking List
- `prodops/artifacts/product/backlogs/icebox-backlog.md` — Icebox
- `prodops/artifacts/business/obcs/` — OBCs committed
- `prodops/artifacts/product/backlogs/iteration-backlog.md` — Iteration Backlog
- `prodops/artifacts/governance/plans/iteration-plan.md` — Iteration Plan
- `prodops/framework/glossary.md` — definições canônicas
- `prodops/journeys/diligence/README.md` — Jornada Diligence
