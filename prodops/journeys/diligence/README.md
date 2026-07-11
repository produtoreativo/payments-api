# Diligence

## O que é a Diligence

Diligence é a jornada do Framework ProdOps responsável por transformar decisões produzidas pelo Assessment em trabalho pronto para a Delivery — e por manter todos os artefatos de gestão sincronizados ao longo do ciclo de vida do produto.

Ela não implementa software. Ela prepara, organiza, prioriza, estrutura e governa o que será implementado.

---

## Propósito

A Diligence existe para garantir que o trabalho chegue à Delivery **sem ambiguidade**.

Sem a Diligence, decisões do Assessment ficam distribuídas em documentos, conversas e sistemas desconectados. A Delivery começa sem clareza sobre o que implementar, com que critérios, com qual prioridade e com que rastreabilidade.

A Diligence resolve esse problema: ela fecha a lacuna entre **decidir** e **implementar**.

---

## Problema que resolve

O Framework ProdOps separa rigorosamente quem decide do que implementar. Essa separação cria um gap operacional:

- O Assessment produz OBCs, Iteration Plans, Reliability Plans e riscos.
- A Delivery precisa de trabalho organizado, priorizado e rastreável para começar.

Esse gap não é preenchido automaticamente. Alguém (ou algum agente) precisa:

- Refinar os artefatos do Assessment até estarem acionáveis.
- Organizar e priorizar o backlog de trabalho.
- Estruturar Issues, Milestones e Roadmaps nas ferramentas de gestão.
- Sincronizar a rastreabilidade entre os artefatos e as ferramentas.
- Validar que o trabalho está pronto antes de entrar em Delivery.

Esse é o papel da Diligence.

---

## Posição no Framework

```
Origin Stream (Business | Enterprise | Team | Technology)
       ↓
    Intent
       ↓
  Exploration  (Jornada: Discovery, Modo: Upstream)
       ↓
     OBC
       ↓
  Assessment ──── produz ────► Diligence ────► trabalho pronto
                                   ↓
                               Delivery
                                   ↓
                               Operation
                                   ↓
                               Assessment  (ciclo contínuo)
```

A Diligence opera em paralelo ao Assessment e à Delivery — ela não é uma etapa sequencial única, mas uma jornada contínua que acompanha todo o ciclo.

---

## Princípios

### A Diligence nunca implementa software

A Diligence não altera código do produto. Não abre Pull Requests. Não modifica branches de desenvolvimento. Não implementa Features.

Toda implementação pertence exclusivamente à jornada de Delivery.

A fronteira é absoluta: se um artefato produzido pela Diligence precisar de implementação para entrar em vigor, ele deve cruzar explicitamente para a Delivery.

### A Diligence prepara o trabalho

Sua responsabilidade é transformar decisões do Assessment em trabalho acionável para a Delivery. O sinal de sucesso da Diligence não é o que ela produz — é a qualidade com que a Delivery começa.

Trabalho mal preparado gera scope creep, retrabalho e divergência de artefatos. Trabalho bem preparado permite que a Delivery flua sem interrupções.

### A Diligence governa a execução

Ela mantém sincronizados todos os artefatos de gestão do produto, independentemente da ferramenta. OBCs, Reliability Plans, Issues, Milestones, Roadmaps e documentação operacional devem refletir a mesma realidade.

A Diligence não escolhe uma ferramenta — ela garante consistência entre todas as ferramentas utilizadas.

### A Diligence preserva rastreabilidade

Toda decisão deve permanecer rastreável desde a Intent até a Operation:

```
Intent  →  Assessment  →  OBC  →  Issue  →  Delivery  →  Release  →  Operation
```

A rastreabilidade não é um artefato pontual — é uma invariante que a Diligence mantém continuamente. Quando qualquer elo dessa cadeia se rompe, cabe à Diligence restaurá-lo.

### A Diligence é contínua

A Diligence não tem início e fim por ciclo. Ela acompanha o produto enquanto ele existir.

É ativada por:
- novos riscos ou incidentes identificados na Operation;
- postmortems que geram novas Intents;
- mudanças estratégicas que afetam o Iteration Plan;
- novas oportunidades identificadas pelo Assessment;
- divergências detectadas entre artefatos e ferramentas de gestão.

---

## Responsabilidades

### O que a Diligence faz

- Refina OBCs e critérios de aceite até estarem acionáveis.
- Organiza e prioriza o backlog de Intents e OBCs.
- Estrutura Issues, Milestones e Roadmaps nas ferramentas de gestão.
- Sincroniza artefatos ProdOps com ferramentas externas (GitHub, Jira, Azure DevOps).
- Valida rastreabilidade antes de cada ciclo de Delivery.
- Mantém consistência entre todos os artefatos de gestão do produto.
- Define e comunica critérios de "trabalho pronto" para entrada em Delivery.
- Governa a evolução do backlog ao longo do tempo.

### O que a Diligence não faz

- Não implementa código.
- Não cria Pull Requests.
- Não modifica branches de desenvolvimento.
- Não toma decisões de produto que competem ao Assessment.
- Não reescreve OBCs ou critérios definidos pela Exploration.
- Não substitui a governança de produto — ela a operacionaliza.

---

## Relação com as demais jornadas

| Jornada | Relação com a Diligence |
|---|---|
| **Assessment** | Principal alimentador da Diligence. Produz OBCs, Iteration Plans, Reliability Plans e riscos que a Diligence refina e organiza para a Delivery. |
| **Delivery** | Principal consumidor da Diligence. Recebe trabalho organizado, priorizado e rastreável. A Diligence define quando o trabalho está pronto para entrar em Delivery. |
| **Operation** | Fonte de sinais contínuos. Incidentes, postmortems e anomalias operacionais ativam ciclos de Diligence, que pode gerar novas Intents ou revisões de OBC. |
| **Discovery** | A Diligence recebe as capabilities promovidas pela Discovery e as integra ao backlog gerenciado, garantindo que os artefatos produzidos estejam rastreados nas ferramentas de gestão. |

---

## Artefatos governados

A Diligence não é a autora desses artefatos — ela garante que estejam sincronizados, consistentes e rastreáveis entre si e nas ferramentas de gestão:

**Artefatos ProdOps**
- OBCs (`prodops/artifacts/obcs/`)
- BDD Features (`prodops/artifacts/bdd/`)
- Iteration Plans (`prodops/artifacts/plans/`)
- Reliability Plans (`prodops/journeys/assessment/reliability-plans/`)
- Tracking List (`prodops/artifacts/product/tracking-list.md`)
- Release Trail (`prodops/artifacts/trails/release-trail.md`)

**Ferramentas de gestão**
- GitHub Issues, Projects, Milestones, Labels, Roadmap
- Jira Boards e Backlogs
- Azure DevOps Boards

---

## Evolução desta documentação

Este README é a fundação conceitual da jornada. A documentação detalhada de cada responsabilidade será desenvolvida em subdiretórios:

- `capabilities/` — cada capability da jornada documentada individualmente
- `flows/` — fluxos operacionais internos da Diligence
- `governance/` — modelo de governança para cada ferramenta de gestão

→ [Issue #13: épico de documentação da Diligence](https://github.com/produtoreativo/payments-api/issues/13)
