# Hierarquia de Backlogs

O Framework ProdOps organiza o trabalho em dois fluxos hierárquicos: um de **plataforma** (Portfolio) e um de **produto** (Product Repository). Cada backlog responde a uma única pergunta e possui responsabilidades bem definidas.

O trabalho nunca pula níveis sem justificativa explícita registrada no OBC.

---

## Fluxo Global — Plataforma → Produto

```
Global Tracking List       ← O que merece atenção na plataforma?
          ↓
Business Intent Backlog    ← O que merece Discovery? (Global OBC Draft nasce aqui)
    │         │
    │         ├─ Roadmap          [view: em qual horizonte estratégico?]
    │         └─ Platform Release [view: em qual versão da plataforma?]
    │
    │   (Discovery no BIB)
          ↓
OBC Partitioning           ← Global OBC → Local OBCs (um por produto)
          ↓
Product Intent Backlog     ← fonte de verdade do produto (Local OBC vive aqui)
    │         │
    │         ├─ Icebox           [view: em refinamento — estado Refining]
    │         ├─ Iteration Backlog [view: comprometido — estado Committed]
    │         └─ Release          [view: agrupado por versão de release]
    │
    │   (item com Local OBC Committed + BDD + critérios satisfeitos)
          ↓
Iteration Plan             ← execução da iteração atual
          ↓
Delivery
          ↓
Operation                  ← Refinamento Contínuo do OBC
```

> **Roadmap e Platform Release não são filas** — são projeções sobre itens do BIB.
> **Icebox, Iteration Backlog e Release também não são filas** — são projeções sobre itens do PIB. Um item não sai do PIB ao entrar em uma dessas views; ele permanece no PIB e recebe um estado que determina qual view o representa.

---

## Fluxo Local — Produto

```
Repository Tracking List   ← O que merece atenção neste produto?
          ↓
Premortem + Análise de Risco Preliminar
          ↓
Owner Approval
          ↓
Product Intent Backlog     ← fonte de verdade do produto (Local OBC nasce aqui)
[continua no fluxo comum — Icebox/Iteration Backlog/Release como views]
```

> **Nota sobre Reliability Plan no fluxo local:** A etapa pré-PIB exige um **Premortem** e uma análise de risco preliminar — não o artefato formal Reliability Plan de `reliability-plans/`. O Reliability Plan formal é produzido pela jornada Assessment durante o Icebox, após o compromisso do Product Owner. O Premortem é suficiente para a decisão de entrada no PIB. O Reliability Plan formal é **recomendado** antes da Delivery, não obrigatório.

Após entrar no **Product Intent Backlog**, a origem do item deixa de importar. Todos os itens seguem exatamente a mesma jornada — independente de terem vindo do Portfolio ou do fluxo local.

---

## Backlogs da Plataforma

### Global Tracking List

**Pergunta:** O que merece atenção na plataforma?

**Propósito:** Registrar qualquer sinal cujo escopo está indefinido ou ultrapassa um único produto. O sinal pertence à plataforma — ainda não se sabe qual produto ou time vai resolvê-lo.

**Quando usar:** O sinal envolve negócio, cadeia de valor, múltiplos produtos ou plataforma inteira. A propriedade do problema ainda não está clara. Exemplos: oportunidades de mercado sem produto definido, mudanças regulatórias que afetam vários sistemas, iniciativas de plataforma transversais.

**Não usar quando:** O sinal já tem destino certo — um produto ou time específico que claramente o resolve. Nesse caso, o sinal pertence à Repository Tracking List do produto.

**Independência:** Itens da Global Tracking List não são copiados para Repository Tracking Lists de produtos candidatos. O item permanece na Global até ser triado e direcionado. Não existe duplicação entre os dois fluxos.

**Contém:** Ideias, oportunidades, problemas, demandas, compliance, melhorias, riscos — qualquer sinal de escopo indeterminado.

**Não contém:** OBC. Compromisso. Identificador permanente.

**Quando avançar:** Quando o item tiver sido compreendido o suficiente para ser reconhecido como Intent e entrar no Business Intent Backlog.

**Gerenciado por:** Portfolio.

---

### Business Intent Backlog

**Pergunta:** O que merece Discovery?

**Propósito:** Representar Intents aceitas para Discovery a nível de plataforma. É aqui que o **Global OBC** nasce como Draft. O BIB contém apenas Global OBCs — nunca Local OBCs.

**O que acontece ao entrar neste backlog:**
- A Intent recebe um identificador permanente.
- Um **Global OBC Draft** é criado — captura a Intent e hipóteses iniciais de negócio.
- Inicia-se o ciclo de vida do trabalho.

**Compromisso:** A Intent é aceita para Discovery. Ainda não existe compromisso de implementação. Produtos, repositórios e número de Local OBCs ainda são desconhecidos neste momento.

**Dimensões sobre o BIB:** Itens do BIB podem receber dimensões estratégicas sem sair dele:
- **Roadmap** — posiciona o item em um horizonte de entrega (agora, próximo, futuro).
- **Platform Release** — agrupa o item na versão da plataforma à qual pertence.

Um item pode estar no BIB, associado a um Roadmap e a uma Platform Release, ao mesmo tempo. Essas dimensões são projeções — não filas pelas quais o item passa sequencialmente.

**Quando o item deixa o BIB:** Após o Discovery no BIB e o Particionamento do OBC, o Portfolio direciona os Local OBCs criados para os Product Intent Backlogs dos produtos envolvidos.

**Gerenciado por:** Portfolio.

---

### OBC Partitioning

**O que é:** Capability responsável por transformar o Global OBC em Local OBCs — um por produto envolvido. Ocorre após o Discovery no BIB, antes da criação de itens nos PIBs dos produtos.

**Responsabilidades:**
- Identificar os produtos envolvidos na implementação
- Identificar os repositórios correspondentes
- Identificar os Bounded Contexts
- Decompor o Global OBC em partições de responsabilidade
- Criar os Local OBCs com referência ao Global OBC
- Manter a tabela de rastreabilidade no Global OBC

**Resultado:** cada produto recebe um Local OBC em seu PIB. O Global OBC registra a rastreabilidade de todos os Local OBCs.

**Quem executa:** Portfolio PM + Tech Leads dos produtos envolvidos.

---

### Roadmap

**Natureza:** View estratégica sobre o Business Intent Backlog — não é uma fila. Itens não "entram" no Roadmap; eles permanecem no BIB e recebem uma posição no horizonte estratégico.

**Pergunta:** Em qual horizonte de entrega este item se encaixa?

**Propósito:** Organizar a sequência estratégica dos itens do BIB por horizonte (agora / próximo / futuro), Milestones e dependências entre produtos. Permite ao Portfolio comunicar intenção sem comprometer entrega.

**O que representa:** Uma projeção temporal dos itens do BIB — quais serão endereçados em qual janela de tempo.

**Não é:** Uma lista de tarefas. Os itens no Roadmap ainda vivem no BIB e podem ser removidos, repriorizado ou redirecionados sem processo formal de remoção.

**Compromisso:** Intenção estratégica, não compromisso de entrega. A entrega só se torna compromisso quando o item entra no Product Intent Backlog de um produto.

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

**Relação com o PIB:** A associação de um item a uma Platform Release pode preceder ou acompanhar o direcionamento para o PIB de um produto — mas não o substitui. O item só entra no fluxo de produto quando o Portfolio o direciona explicitamente para o PIB.

**Gerenciado por:** Portfolio.

---

## Backlogs do Produto

### Repository Tracking List

**Pergunta:** O que merece atenção neste produto?

**Propósito:** Capturar sinais já direcionados a este produto ou time específico. A propriedade já está definida — sabe-se que o problema pertence aqui.

**Quando usar:** O sinal tem destino certo: este produto, este time. Não precisa de triagem de plataforma. Exemplos: bug identificado neste serviço, dívida técnica interna, oportunidade de melhoria de performance deste domínio, sinal vindo de postmortem ou operação deste produto.

**Não usar quando:** O sinal é amplo demais, envolve múltiplos produtos ou a propriedade ainda não está clara. Nesse caso, o sinal pertence à Global Tracking List.

**Independência:** A Repository Tracking List é autônoma — não depende da Global Tracking List e não recebe cópias dela. Um sinal que chega aqui já tem destino definido e segue diretamente para o fluxo local (Premortem + Owner Approval → PIB), sem passar pelo Portfolio.

**Contém:** Bugs, dívida técnica, arquitetura, observabilidade, performance, segurança, custos, melhorias internas, sinais de operação e postmortems.

**Não contém:** OBC. Compromisso. Identificador permanente.

**Quando avançar:** Via Premortem + Análise de Risco Preliminar + Owner Approval → Product Intent Backlog.

**Artefato canônico:** `prodops/artifacts/product/backlogs/tracking-list.md`

---

### Product Intent Backlog

**Natureza:** Backlog — fonte de verdade de todo trabalho aceito pelo produto. Os itens vivem aqui do aceite até a entrega. Icebox, Iteration Backlog e Release são projeções sobre estes itens, não destinos separados.

**Pergunta:** O que foi oficialmente aceito pelo Product Owner?

**Contém exclusivamente:** Local OBCs. O PIB nunca contém Global OBCs.

**Dois caminhos de entrada:**

| Origem | Caminho de entrada |
|---|---|
| Plataforma | Local OBC criado pelo OBC Partitioning, direcionado pelo Portfolio após Discovery no BIB |
| Local | Repository Tracking Item promovido via Premortem + Análise de Risco Preliminar com Owner Approval |

**O que acontece ao entrar:**
- O Product Owner formaliza a aceitação.
- Se ainda não existia (caminho local), um **Local OBC Draft** é criado.
- O item inicia seu ciclo de vida rastreável no produto.
- O item recebe o estado inicial **Draft** — representado na view Icebox como Refining.

**Após a entrada, a origem deixa de importar.** O item evolui de estado no PIB: Refining (Icebox) → Committed (Iteration Backlog) → Implemented (Iteration Plan) → Operational.

> **Promoção de Upstream:** Um item promovido de Upstream já possui Local OBC, BDD Feature e riscos documentados — já satisfaz os critérios do estado Committed. Entra diretamente no Iteration Plan sem passar pela view Icebox.

**Compromisso:** O Product Owner comprometeu-se a investigar e entregar este item.

---

### Icebox

**Natureza:** View sobre o PIB — não é uma fila separada. Representa os itens do PIB que ainda estão em refinamento: Local OBC incompleto, decisões em aberto, Discovery em andamento.

**Pergunta:** Quais itens do PIB ainda estão sendo refinados para Delivery?

**O que representa:** Um item está na view Icebox enquanto o Local OBC ainda não atingiu o estado Committed. O Discovery necessário ocorre neste estado. O estado do Local OBC é **Refining**.

**O Discovery no estado Icebox pode ser:**
- **Funcional** — entender o que deve ser construído
- **Técnico** — entender como construir com confiança
- **Operacional** — entender como operar e monitorar

**Transição de estado:** O item sai da view Icebox quando o Local OBC atinge o estado Committed — passa a ser representado na view Iteration Backlog.

**Artefato canônico:** `prodops/artifacts/product/backlogs/icebox-backlog.md`

---

### Iteration Backlog

**Natureza:** View sobre o PIB — não é uma fila separada. Representa os itens do PIB que estão comprometidos e prontos para iniciar Delivery: Local OBC Committed, Discovery concluído, decisão de entrega assumida.

**Pergunta:** Quais itens do PIB estão prontos para ser desenvolvidos?

**O que representa:** Um item está na view Iteration Backlog quando satisfaz todos os critérios de prontidão. O estado do Local OBC é **Committed**. A única decisão restante é a prioridade do Product Owner para a próxima iteração.

**Não é refinamento.** Refinamento acontece no estado Icebox. Um item que chega aqui está pronto — não precisa de mais Discovery.

**Critérios para estar nesta view:**
- Local OBC no estado Committed
- Discovery funcional, técnico e operacional suficiente
- Riscos identificados em `prodops/journeys/assessment/risks.md`

**Critérios para entrar no Iteration Plan (iniciar execução):**
- Local OBC committed em `prodops/artifacts/business/obcs/`
- BDD Feature committed em `prodops/artifacts/business/bdd/`
- *(Recomendado)* Entrada no Reliability Plan em `prodops/journeys/assessment/reliability-plans/` — não é gate obrigatório, mas fortemente recomendado para itens com risco operacional relevante

**Artefato canônico:** `prodops/artifacts/product/backlogs/iteration-backlog.md`

---

### Release

**Natureza:** View sobre o PIB — não é uma fila separada. Representa os itens do PIB agrupados por versão de release do produto.

**Pergunta:** Quais itens do PIB fazem parte desta versão de release?

**O que representa:** Uma visão organizada dos Local OBCs agrupados pela versão de release à qual contribuem. Facilita o planejamento, a comunicação e o acompanhamento de versões.

**Não confundir com:** Platform Release (que é uma view no BIB, de responsabilidade do Portfolio). A view Release do PIB é de responsabilidade do Product Owner.

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

## GitHub Issue como representação operacional

Uma GitHub Issue não é a origem do trabalho no Framework ProdOps. Ela é uma **representação operacional** de um compromisso já assumido.

**Quando nasce uma Issue:** Normalmente quando um Local OBC entra no Iteration Backlog ou no Iteration Plan — o trabalho está pronto para execução.

**O Framework é independente de ferramenta.** GitHub Issues, Jira Cards, Azure DevOps Work Items são representações operacionais do mesmo OBC em ferramentas diferentes. O OBC é a fonte de verdade; a Issue é a instância de execução.

---

## Diligence como guardiã da hierarquia

A Diligence é a jornada responsável por manter os backlogs sincronizados em todos os níveis — plataforma e produto.

> **Princípio:** A Diligence garante que o estado de cada OBC permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão, sem modificar o código do produto.

**O que a Diligence mantém sincronizado:**
- Estado do Local OBC em cada backlog (Product Intent, Icebox, Iteration Backlog, Iteration Plan)
- Estado do Global OBC no BIB e sua rastreabilidade
- Representações operacionais nas ferramentas (GitHub Issues, Jira, Azure DevOps)
- Rastreabilidade Intent → Global OBC → Local OBC → Issue → PR → Release → Operation
- Consistência entre artefatos ProdOps e ferramentas externas

→ [Jornada Diligence](../journeys/diligence/README.md)

---

## Responsabilidade por backlog

| Backlog / View | Pergunta | Gerenciado por |
|---|---|---|
| Global Tracking List | O que merece atenção na plataforma? | Portfolio |
| Business Intent Backlog | O que merece Discovery? (Global OBCs) | Portfolio |
| OBC Partitioning | Como decompor o Global OBC em Local OBCs? | Portfolio PM + Tech Leads |
| Roadmap | Qual a sequência estratégica de entrega? | Portfolio |
| Platform Release | O que compõe esta versão da plataforma? | Portfolio |
| Repository Tracking List | O que merece atenção neste produto? | Product Repository |
| Product Intent Backlog | O que foi oficialmente aceito pelo Product Owner? (Local OBCs) | Product Owner |
| Icebox | O que ainda está sendo preparado para Delivery? (Refining) | Product Owner + Tech Lead |
| Iteration Backlog | O que está pronto para ser desenvolvido? (Committed) | Product Owner |
| Release | O que compõe esta versão do produto? | Product Owner |
| Iteration Plan | O que está sendo executado nesta iteração? | Time de Delivery |

---

## Referências

- `prodops/artifacts/product/backlogs/tracking-list.md` — Repository Tracking List
- `prodops/artifacts/product/backlogs/icebox-backlog.md` — Icebox
- `prodops/artifacts/business/obcs/` — OBCs committed
- `prodops/artifacts/product/backlogs/iteration-backlog.md` — Iteration Backlog
- `prodops/artifacts/governance/plans/iteration-plan.md` — Iteration Plan
- `prodops/framework/glossary.md` — definições canônicas
- `prodops/journeys/diligence/README.md` — Jornada Diligence
