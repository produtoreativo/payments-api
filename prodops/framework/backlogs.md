# Hierarquia de Backlogs

O Framework ProdOps organiza o trabalho em dois fluxos hierárquicos: um de **plataforma** (Portfolio) e um de **produto** (Product Repository). Cada backlog responde a uma única pergunta e possui responsabilidades bem definidas.

O trabalho nunca pula níveis sem justificativa explícita registrada no OBC.

---

## Fluxo Global — Plataforma → Produto

```
Global Tracking List       ← O que merece atenção na plataforma?
          ↓
Business Intent Backlog    ← O que merece Discovery? (OBC Draft nasce aqui)
          ↓
Roadmap                    ← Qual a sequência estratégica de entrega?
          ↓
Platform Release           ← O que compõe esta versão da plataforma?
          ↓
Product Intent Backlog     ← O que foi oficialmente aceito pelo Product Owner?
          ↓
Icebox                     ← O que ainda está sendo preparado para Delivery?
          ↓
Iteration Backlog          ← O que está pronto para ser desenvolvido?
          ↓
Iteration Plan             ← O que está sendo executado nesta iteração?
          ↓
Delivery
```

---

## Fluxo Local — Produto

```
Repository Tracking List   ← O que merece atenção neste produto?
          ↓
Premortem + Análise de Risco Preliminar
          ↓
Owner Approval
          ↓
Product Intent Backlog     ← O que foi oficialmente aceito pelo Product Owner?
          ↓
[continua no fluxo comum acima]
```

> **Nota sobre Reliability Plan no fluxo local:** A etapa pré-PIB exige um **Premortem** e uma análise de risco preliminar — não o artefato formal Reliability Plan de `reliability-plans/`. O Reliability Plan formal é produzido pela jornada Assessment durante o Icebox, após o compromisso do Product Owner. O Premortem é suficiente para a decisão de entrada no PIB. O Reliability Plan formal é **recomendado** antes da Delivery, não obrigatório.

Após entrar no **Product Intent Backlog**, a origem do item deixa de importar. Todos os itens seguem exatamente a mesma jornada — independente de terem vindo do Portfolio ou do fluxo local.

---

## Backlogs da Plataforma

### Global Tracking List

**Pergunta:** O que merece atenção na plataforma?

**Propósito:** Registrar qualquer sinal de nível de plataforma ainda não compreendido o suficiente para ser tratado como uma Intent formal.

**Contém:** Ideias, oportunidades, problemas, demandas, compliance, melhorias, riscos, tecnologia — qualquer sinal que ainda não recebeu atenção suficiente.

**Não contém:** OBC. Compromisso. Identificador permanente.

**Compromisso:** Nenhum. O objetivo é investigar se o item representa uma Intent válida para a plataforma.

**Quando avançar:** Quando o item tiver sido compreendido o suficiente para ser reconhecido como uma Intent e entrar no Business Intent Backlog.

**Gerenciado por:** Portfolio.

---

### Business Intent Backlog

**Pergunta:** O que merece Discovery?

**Propósito:** Representar Intents aceitas para Discovery a nível de plataforma. É aqui que o OBC nasce como Draft para o fluxo global.

**O que acontece ao entrar neste backlog:**
- A Intent recebe um identificador permanente.
- Um OBC Draft é criado — captura a Intent e hipóteses iniciais.
- Inicia-se o ciclo de vida do trabalho.
- O Product Owner define o modo de execução: Upstream ou Downstream.

**Compromisso:** A Intent é aceita para Discovery. Ainda não existe compromisso de implementação.

**Quando avançar:** Quando a Intent tiver evidência suficiente para entrar no Roadmap.

**Gerenciado por:** Portfolio.

---

### Roadmap

**Pergunta:** Qual a sequência estratégica de entrega da plataforma?

**Propósito:** Organizar Platform Releases, Milestones, prioridades e dependências. O Roadmap coordena versões da plataforma — não contém tarefas técnicas.

**Contém:** Releases, Milestones, prioridades, dependências entre produtos.

**Não contém:** Tarefas técnicas, OBCs de produto, BDD Features.

**Compromisso:** Comprometimento estratégico — a plataforma pretende entregar isso em um horizonte definido.

**Gerenciado por:** Portfolio. Vive em ferramentas externas de gestão estratégica.

---

### Platform Release

**Pergunta:** O que compõe esta versão da plataforma?

**Propósito:** Representar uma combinação de versões de Product Repositories que formam uma entrega coerente da plataforma como um todo.

**Exemplo:**
- payments-api v3 + webshop-api v8 + order-api v2

**Responsabilidade:** Os Product Repositories não controlam a Platform Release. A responsabilidade é exclusivamente do Portfolio.

**Gerenciado por:** Portfolio.

---

## Backlogs do Produto

### Repository Tracking List

**Pergunta:** O que merece atenção neste produto?

**Propósito:** Capturar qualquer sinal local de produto ainda não compreendido o suficiente para ser tratado como um compromisso formal.

**Contém:** Bugs, dívida técnica, arquitetura, observabilidade, performance, segurança, custos, melhorias internas.

**Não contém:** OBC. Compromisso. Identificador permanente.

**Compromisso:** Nenhum. Nem todo item precisa virar uma Intent global — alguns podem ser resolvidos localmente via fluxo de Premortem + Reliability Plan.

**Quando avançar:** Via Premortem + Reliability Plan + Owner Approval → Product Intent Backlog.

**Artefato canônico:** `prodops/artifacts/product/tracking-list.md`

---

### Product Intent Backlog

**Pergunta:** O que foi oficialmente aceito pelo Product Owner?

**Propósito:** Representar todo trabalho formalmente aceito pelo Product Owner do produto. Ponto de entrada único do produto para o ciclo de Delivery — independente de onde o item veio.

**Dois caminhos de entrada:**

| Origem | Caminho de entrada |
|---|---|
| Plataforma | Business Intent do Portfolio, após Platform Release coordenar a entrega |
| Local | Repository Tracking Item promovido via Premortem + Reliability Plan com Owner Approval |

**O que acontece ao entrar neste backlog:**
- O Product Owner formaliza a aceitação.
- Se ainda não existia (caminho local), um OBC Draft é criado para o item.
- O item inicia seu ciclo de vida rastreável no produto.

**Após a entrada, a origem deixa de importar.** Todos os itens seguem a mesma jornada: Icebox → Iteration Backlog → Iteration Plan → Delivery.

> **Exceção — promoção de Upstream:** Um item promovido de Upstream para Downstream já possui OBC, BDD Feature e riscos documentados. Ele entra **diretamente no Iteration Plan** (status `Entrou`), pulando o Iteration Backlog. O Iteration Backlog é a fila de espera para itens que ainda não estão prontos para iniciar Delivery — itens promovidos de Upstream já satisfazem esse critério.

**Compromisso:** O Product Owner comprometeu-se a investigar e eventualmente entregar este item.

**Quando avançar:** Quando a Intent tiver evidência suficiente para entrar no Icebox (preparação para Delivery).

---

### Icebox

**Pergunta:** O que ainda está sendo preparado para Delivery?

**Propósito:** Representar itens comprometidos que ainda estão sendo preparados para iniciar a Delivery. Durante esta fase ocorre o Discovery necessário para o produto.

**O Discovery no Icebox pode ser:**
- **Funcional** — entender o que deve ser construído
- **Técnico** — entender como construir com confiança
- **Operacional** — entender como operar e monitorar

**Objetivo:** Produzir um OBC mínimo aceitável. Enquanto isso não acontece, o item permanece no Icebox.

**Compromisso:** O item será entregue — mas ainda não está pronto para começar.

**Quando avançar:** Quando o item tiver um OBC mínimo validado e estiver pronto para entrar no Iteration Backlog.

**Artefato canônico:** `prodops/artifacts/product/icebox-backlog.md`

---

### Iteration Backlog

**Pergunta:** O que está pronto para ser desenvolvido?

**Propósito:** Representar todos os itens com OBC mínimo validado e prontos para Delivery imediata. A única decisão restante é a prioridade definida pelo Product Owner.

**Este backlog não é de refinamento.** Refinamento acontece no Icebox. O Iteration Backlog representa exclusivamente trabalho pronto para ser implementado.

**Pré-requisito para entrar:** OBC mínimo validado.

**Pré-requisitos para sair (entrar em Delivery via Iteration Plan):**
- OBC committed em `prodops/artifacts/obcs/`
- BDD Feature committed em `prodops/artifacts/bdd/`
- Entrada no Iteration Plan com status `In`
- Riscos documentados em `prodops/journeys/assessment/risks.md`
- *(Recomendado)* Entrada no Reliability Plan em `prodops/journeys/assessment/reliability-plans/` — não é gate obrigatório, mas fortemente recomendado para itens com risco operacional relevante

**Artefato canônico:** `prodops/artifacts/plans/iteration-backlog.md`

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

**Não contém:** Priorização. Refinamento. Itens do Icebox. Itens sem OBC committed.

**Artefato canônico:** `prodops/artifacts/plans/iteration-plan.md`

---

## OBC como identificador permanente

O OBC acompanha o trabalho por toda a sua vida — do momento em que a Intent é aceita até a operação em produção.

### Ciclo de vida do OBC

| Fase | Estado do OBC | O que acontece |
|---|---|---|
| Global Tracking List / Repository Tracking List | Não existe | O item ainda não é uma Intent reconhecida |
| Business Intent Backlog (fluxo global) | **Draft** | OBC criado; captura a Intent e hipóteses iniciais |
| Product Intent Backlog (fluxo local) | **Draft** | OBC criado ao ser aceito pelo Product Owner |
| Icebox | Draft em refinamento | OBC refinado pelo Discovery; critérios emergem |
| Assessment Review | Candidato a committed | OBC revisado por PM + Tech Lead |
| Iteration Backlog | Minimum OBC | OBC mínimo validado; Downstream pode iniciar |
| Delivery | Active | OBC guia a implementação; BDD Feature o operacionaliza |
| Operation | Operational | OBC validado em produção; pode ser estendido por novas Intents |

### O que o OBC registra

O OBC é o **histórico vivo do trabalho**:
- Intent original e Origin Stream
- Por quais backlogs passou e quando
- Decisões tomadas e descartadas
- Critérios de aceite e como evoluíram
- Referências a experimentos, riscos e Reliability Plan
- Evidências de validação em produção

---

## GitHub Issue como representação operacional

Uma GitHub Issue não é a origem do trabalho no Framework ProdOps. Ela é uma **representação operacional** de um compromisso já assumido.

**Quando nasce uma Issue:** Normalmente quando um OBC entra no Iteration Backlog ou no Iteration Plan — o trabalho está pronto para execução.

**O Framework é independente de ferramenta.** GitHub Issues, Jira Cards, Azure DevOps Work Items são representações operacionais do mesmo OBC em ferramentas diferentes. O OBC é a fonte de verdade; a Issue é a instância de execução.

---

## Diligence como guardiã da hierarquia

A Diligence é a jornada responsável por manter os backlogs sincronizados em todos os níveis — plataforma e produto.

> **Princípio:** A Diligence garante que o estado de cada OBC permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão, sem modificar o código do produto.

**O que a Diligence mantém sincronizado:**
- Estado do OBC em cada backlog (Product Intent, Icebox, Iteration Backlog, Iteration Plan)
- Representações operacionais nas ferramentas (GitHub Issues, Jira, Azure DevOps)
- Rastreabilidade Intent → OBC → Issue → PR → Release → Operation
- Consistência entre artefatos ProdOps e ferramentas externas

→ [Jornada Diligence](../journeys/diligence/README.md)

---

## Responsabilidade por backlog

| Backlog | Pergunta | Gerenciado por |
|---|---|---|
| Global Tracking List | O que merece atenção na plataforma? | Portfolio |
| Business Intent Backlog | O que merece Discovery? | Portfolio |
| Roadmap | Qual a sequência estratégica de entrega? | Portfolio |
| Platform Release | O que compõe esta versão da plataforma? | Portfolio |
| Repository Tracking List | O que merece atenção neste produto? | Product Repository |
| Product Intent Backlog | O que foi oficialmente aceito pelo Product Owner? | Product Owner |
| Icebox | O que ainda está sendo preparado para Delivery? | Product Owner + Tech Lead |
| Iteration Backlog | O que está pronto para ser desenvolvido? | Product Owner |
| Iteration Plan | O que está sendo executado nesta iteração? | Time de Delivery |

---

## Referências

- `prodops/artifacts/product/tracking-list.md` — Repository Tracking List
- `prodops/artifacts/product/icebox-backlog.md` — Icebox
- `prodops/artifacts/obcs/` — OBCs committed
- `prodops/artifacts/plans/iteration-backlog.md` — Iteration Backlog
- `prodops/artifacts/plans/iteration-plan.md` — Iteration Plan
- `prodops/framework/glossary.md` — definições canônicas
- `prodops/journeys/diligence/README.md` — Jornada Diligence
