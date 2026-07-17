# Framework Flow

O fluxo oficial do Framework ProdOps descreve o caminho que toda mudança percorre desde a sua origem até a operação contínua.

```
Origin Stream → Intent → Global OBC Draft (BIB) → Discovery → OBC Partitioning → Local OBC Draft (PIB) → Exploration + Assessment → Assessment Review → Local OBC Committed + BDD committed → Iteration Plan → Delivery → Operation → Refinamento Contínuo do OBC
```

Este documento é a referência canônica para entender **o que acontece em cada etapa**, **o que é produzido** e **quando avançar**.

→ [Origin Streams: as quatro origens possíveis](origin-streams.md)
→ [Modelo operacional: hierarquia do Framework](operating-model.md)
→ [Glossário: definições canônicas](glossary.md)

---

## Diagrama completo

```mermaid
flowchart TD
    OS["Origin Stream\n(Business | Enterprise | Team | Technology)"]
    I["Intent"]
    GBIB["Global OBC Draft\n(Business Intent Backlog)"]
    EX1["Discovery no BIB\n(reduz incerteza estratégica)"]
    PART["OBC Partitioning\n(Global OBC → Local OBCs)"]
    LPIB["Local OBC Draft\n(Product Intent Backlog)"]
    EX2["Exploration no Icebox\n(Discovery; rigor conforme o modo)"]
    AS["Assessment\n(transversal)"]
    RP["Reliability Plan\n(recomendado)"]
    REV["Assessment Review\n(PM + Tech Lead)"]
    OBC["Local OBC Committed + BDD\ncommitted"]
    IP["Iteration Plan\n(status: Entrou)"]
    D["Delivery\n(Downstream)"]
    OP["Operation\n(Jornada: Operation)"]
    REF["Refinamento Contínuo do OBC"]

    OS --> I
    I --> GBIB
    GBIB --> EX1
    EX1 --> PART
    PART --> LPIB
    LPIB --> EX2
    EX2 --> REV
    LPIB -.-> AS
    EX2 -.-> AS
    AS -.-> RP
    RP -.-> REV
    REV --> OBC
    OBC --> IP
    IP --> D
    D --> OP
    OP --> REF
    REF -.->|"novas Intents"| OS

    EX2 -.->|"Descarte (aprendizado suficiente)"| X[Fechar sem avançar]
    EX2 -.->|"Requer mais exploração"| EX2

    style OS fill:#e2e3e5,stroke:#6c757d
    style GBIB fill:#fff3cd,stroke:#856404
    style PART fill:#e2d9f3,stroke:#6f42c1
    style OBC fill:#cce5ff,stroke:#004085
    style D fill:#d4edda,stroke:#155724
    style X fill:#f8d7da,stroke:#721c24
    style REF fill:#d1ecf1,stroke:#0c5460
```

---

## Etapas do fluxo

### 1. Origin Stream

**Objetivo:** Classificar a origem da mudança para estabelecer o contexto correto.

**O que acontece:** Um colaborador, stakeholder ou processo identifica uma necessidade. A necessidade é classificada em um dos quatro Origin Streams: Business, Enterprise, Team ou Technology.

**O que é produzido:** A necessidade bruta, ainda não formalizada como Intent.

**Quando avançar:** Assim que a origem estiver clara e o registro da Intent puder ser iniciado.

→ [Definição de cada Origin Stream](origin-streams.md)

---

### 2. Intent

**Objetivo:** Formalizar a necessidade como uma intenção explícita, sem compromisso de implementação.

**O que acontece:** A necessidade bruta é registrada como Intent. A Intent documenta: o valor que se pretende gerar, o contexto que motivou a necessidade, as hipóteses iniciais e as perguntas em aberto. Não há solução definida neste momento.

**O que é produzido:**
- Documento de Intent em `prodops/business-intents/<slug>.md`
- Origin Stream declarado
- Hipóteses e perguntas em aberto listadas
- Sugestão de modo de execução (Upstream ou Downstream)

**Quando avançar:** Assim que a Intent estiver registrada e houver decisão de continuar (não descartar).

→ [Template de Intent](../templates/business-intents/intent.md)

---

### 3. Global OBC Draft (BIB)

**Objetivo:** Criar o contrato de negócio estratégico que representa a intenção antes da decomposição por produto.

**O que acontece:** A Intent entra no Business Intent Backlog. Um **Global OBC Draft** nasce — captura o objetivo de negócio, o valor, os stakeholders, as regras e hipóteses iniciais. O Global OBC existe **antes** do Discovery, **antes** do particionamento, **antes** de qualquer compromisso de produto.

**O que é produzido:**
- Global OBC Draft no BIB (vive no repositório de portfólio quando committed)
- Identificador permanente da Intent

**Quando avançar:** Global OBC Draft criado e Discovery no BIB iniciado.

→ [Definição completa do OBC](obc.md)

---

### 4. Discovery (Jornada)

**Objetivo:** É uma atividade — não um backlog. Reduzir a incerteza da intenção de negócio antes do particionamento.

**O que acontece:** A jornada Discovery explora a Intent no nível de plataforma. Experimentos, benchmarks, spikes, pesquisas, entrevistas, protótipos e premortems podem ser conduzidos. Todos os aprendizados retornam ao Global OBC.

**O que é produzido:**
- Experimentos em `prodops/journeys/discovery/experiments/<NNN-slug>/`
- Decision Package (hipótese respondida, recomendação clara, aprendizados)
- Global OBC refinado (estado: Refining)
- Compreensão dos produtos envolvidos e dos bounded contexts

**Upstream vs Downstream:** Discovery pode ocorrer em modo Upstream (alta incerteza, código descartável) ou Downstream (clareza suficiente, gates obrigatórios). O modo nunca muda o estágio — um item em Discovery pode iniciar Upstream e transicionar para Downstream sem mudar de fase.

**Quando avançar:** Quando a hipótese central tiver sido respondida e a incerteza remanescente for aceitável para o particionamento.

→ [Jornada Discovery](../journeys/discovery/README.md)

---

### 5. OBC Partitioning

**Objetivo:** Transformar o Global OBC em Local OBCs — um por produto envolvido.

**O que acontece:** Portfolio PM e Tech Leads dos produtos identificam as responsabilidades de cada produto, os repositórios envolvidos e os bounded contexts. O Global OBC é decomposto em Local OBCs especializados. Cada Local OBC referencia o Global OBC e contém apenas o contrato de responsabilidade daquele produto.

**O que é produzido:**
- Local OBC Draft para cada produto (em `prodops/artifacts/obcs/<slug>.md`)
- Tabela de rastreabilidade atualizada no Global OBC
- Itens criados nos PIBs dos produtos envolvidos

**Quando avançar:** Cada produto recebeu seu Local OBC e iniciou o refinamento no Icebox.

→ [OBC Partitioning](obc.md#particionamento-do-obc)

---

### 6. Exploration (no Icebox)

**Objetivo:** Transformar o Local OBC Draft em um contrato verificável e pronto para entrega.

**O que acontece:** A jornada Discovery continua no nível de produto — agora no Icebox. O Local OBC é refinado com critérios de aceite, eventos observáveis, regras de confiabilidade e contrato de resposta. Em Upstream não há compromisso de entrega e a maturidade pode variar; em Downstream aplicam-se todos os gates vigentes.

**O que é produzido:**
- Local OBC refinado (estado: Refining → Committed)
- BDD Feature draft
- Atualização de riscos e oportunidades

**Quando avançar:** Quando o comportamento esperado estiver suficientemente compreendido e a incerteza remanescente for aceitável para entrar em Downstream. A decisão de avançar é explícita (PM + Tech Lead — Assessment Review).

→ [Jornada Discovery](../journeys/discovery/README.md)

---

### 7. Local OBC Committed + BDD

**Objetivo:** Transformar o conhecimento validado em um contrato observável e verificável — pronto para Delivery.

**O que acontece:** O Local OBC Draft é refinado pela Exploration (Discovery no Icebox) e pela Assessment. Na Assessment Review, PM e Tech Lead revisam o conjunto; quando aprovado, o Local OBC atinge o estado Committed e a BDD Feature é promovida para os diretórios committed. Sem esse conjunto, não há execução Downstream.

**O que é produzido:**
- Local OBC committed em `prodops/artifacts/obcs/<slug>.md`
- BDD Feature committed em `prodops/artifacts/bdd/<slug>.feature`

**Quando avançar:** Local OBC committed, BDD Feature committed, ambos revisados e aprovados.

→ [Definição completa do OBC](obc.md)
→ [Artefatos OBC](../artifacts/obcs/)

---

### 8. Reliability Plan

**Objetivo:** Definir, pela jornada transversal de Assessment, as condições de confiabilidade necessárias antes do compromisso no Iteration Plan.

**O que acontece:** Os riscos identificados são transformados em um plano de confiabilidade. SLOs, ações de mitigação, critérios de rollback e pontos de falha são documentados explicitamente. Assessment corre em paralelo às demais jornadas.

**O que é produzido:**
- Entrada no Reliability Plan em `prodops/journeys/assessment/reliability-plans/`
- Riscos atualizados em `prodops/journeys/assessment/risks.md`

**Quando avançar:** Reliability Plan atualizado e Assessment Review concluída para o item.

→ [Reliability Plans](../journeys/assessment/reliability-plans/)

---

### 9. Iteration Plan

**Objetivo:** Comprometer formalmente a capability na próxima iteração de entrega depois da Assessment Review.

**O que acontece:** O conjunto aprovado — Local OBC Committed, BDD Feature, riscos e Reliability Plan — entra no Iteration Plan com status `Entrou`. Isso representa compromisso formal de entrega; não é, isoladamente, prova de readiness.

**O que é produzido:**
- Entrada no Iteration Plan em `prodops/artifacts/plans/iteration-plan.md` com status `Entrou`
- Atualização da Repository Tracking List se o item estava lá

**Quando avançar:** Todos os gates de readiness Downstream estão satisfeitos.

→ [Iteration Plan](../artifacts/plans/iteration-plan.md)

---

### 10. Delivery

**Objetivo:** Implementar a capability com rastreabilidade, critérios de aceite verificáveis e evidência registrada em cada etapa.

**O que acontece:** O trabalho Downstream segue a sequência obrigatória `Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote`, dividida em CI Sync (trabalho local) e CI Async (plataforma e pipelines). O Local OBC muda para o estado Implemented.

**O que é produzido:**
- Software entregue e promovido
- Release Trail atualizado
- Evidências registradas
- Local OBC no estado Implemented

**Quando avançar:** Promote concluído, Release Trail atualizado, OBC validado em produção.

→ [Jornada Delivery](../journeys/delivery/README.md)
→ [Execution Mode Downstream](../execution-model/downstream.md)

---

### 11. Operation + Refinamento Contínuo

**Objetivo:** Operar e monitorar continuamente o software entregue, mantendo os critérios do OBC e refinando-o continuamente com evidências operacionais.

**O que acontece:** Runbooks, monitoramento de SLOs, alertas, resposta a incidentes, postmortems, atualizações de operational trail. A operação alimenta o Refinamento Contínuo do OBC — toda nova evidência operacional atualiza o contrato (Global e Local). A operação gera novas Intents.

**O que é produzido:**
- Local OBC no estado Operational (atualizado com evidências)
- Global OBC no estado Operational (atualizado com evidências consolidadas)
- Operational Trail atualizado
- Incidentes documentados
- Postmortems quando relevante
- Novas Intents (via Continuous Assessment)

**Quando avançar:** Operação é contínua — não tem ponto de encerramento definido. O ciclo recomeça com novas Intents geradas pelo aprendizado operacional.

→ [Jornada Operation](../journeys/operation/)

---

## Notas de nomenclatura

**Upstream e Downstream são modos, não fases**

Upstream e Downstream descrevem o **modo de execução** — o compromisso e o rigor aplicados. Não são fases do fluxo.

- **Upstream:** modo permissivo; código descartável; sem gates obrigatórios. Pode iniciar em qualquer estágio. Quando concluído, retorna ao estágio original.
- **Downstream:** modo com compromisso de entrega; aplica todos os quality gates vigentes.

Um item pode transicionar entre modos ao longo do mesmo estágio. O modo nunca determina o estágio.

**Exploration vs Discovery vs Upstream**

| Termo | Nível | Significado |
|---|---|---|
| **Exploration** | Etapa do fluxo | O que acontece entre Intent e OBC Committed: redução de incerteza |
| **Discovery** | Jornada | O nome da jornada do Framework que implementa Exploration |
| **Upstream** | Execution Mode | O modo de execução (baixo compromisso) usado durante Discovery |

Ao descrever o fluxo macro, use **Exploration**. Ao referenciar a jornada específica, use **Discovery**. Ao referenciar o modo de execução, use **Upstream**.

---

## Referências

→ [Origin Streams](origin-streams.md)
→ [Glossário](glossary.md)
→ [Fases da Intenção: Concepção e Inception](phases.md)
→ [Modelo operacional](operating-model.md)
→ [Execution Model](../execution-model/README.md)
→ [Jornadas](../journeys/README.md)
