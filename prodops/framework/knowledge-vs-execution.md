# Knowledge Space vs Execution Space

Este documento estabelece o princípio arquitetural mais fundamental do Framework ProdOps:

> **Um artefato ProdOps nunca é uma GitHub Issue.**
> GitHub representa exclusivamente a execução do trabalho.
> ProdOps representa conhecimento.

Todo o restante da documentação deve ser lido e escrito à luz deste princípio.

→ [Modelo operacional](operating-model.md)
→ [Hierarquia de backlogs](backlogs.md)
→ [Fluxo do framework](flow.md)
→ [Glossário](glossary.md)

---

## Os dois universos do Framework

O ProdOps opera em dois universos completamente independentes.

```
┌─────────────────────────────────────────────────────────────────┐
│                       KNOWLEDGE SPACE                           │
│                                                                 │
│  Business Signal · Business Intent · OBC · BDD · Architecture  │
│  Plans · Evidence · Trails · Experiments                        │
│                                                                 │
│  Identidade permanente. Sobrevive a dezenas de Releases.        │
│  Fonte de verdade: arquivos Markdown no repositório git.        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    gera trabalho sobre ele
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                       EXECUTION SPACE                           │
│                                                                 │
│  GitHub Issues · Pull Requests · GitHub Projects · Releases     │
│  GitHub Actions · Pipelines · Milestones · Labels               │
│                                                                 │
│  Representa trabalho executado. Efêmero: Issues fecham,         │
│  PRs fazem merge, Releases são entregues. Nunca substitui       │
│  um artefato. Nunca é a fonte do conhecimento.                  │
└─────────────────────────────────────────────────────────────────┘
```

A seta tem uma única direção válida. O inverso não existe.

---

## Knowledge Space — Artefatos

### O que é um artefato

Um artefato ProdOps é um documento com identidade própria que:
- existe como arquivo Markdown no repositório git;
- acumula conhecimento ao longo do tempo;
- permanece existindo após Releases, iterações e mudanças de time;
- não desaparece quando o trabalho sobre ele é concluído.

### Artefatos canônicos

| Artefato | Localização | O que representa |
|---|---|---|
| **Business Signal** | Portfolio/Product Tracking List | Observação de mercado, operação ou técnica que merece atenção |
| **Business Intent** | Business Intent Backlog / Product Backlog | Decisão estratégica de investigar ou entregar algo |
| **Global OBC** | Repositório de portfólio | Contrato de negócio completo de uma intenção (4 dimensões) |
| **Local OBC** | `prodops/artifacts/business/obcs/<slug>.md` | Contrato de um único produto para uma intenção |
| **BDD Feature** | `prodops/artifacts/business/bdd/<slug>.feature` | Critério de aceite executável |
| **Architecture** | `prodops/artifacts/product/architecture/overview.md` | Diagrama canônico da infraestrutura e aplicações |
| **Plans** | `prodops/artifacts/governance/plans/` | Iteration Plan, Reliability Plan |
| **Trails** | `prodops/artifacts/governance/trails/` | Registros históricos de Release e decisões |
| **Risk Register** | `prodops/journeys/assessment/risks.md` | Registro de riscos identificados durante Assessment |
| **Evidence** | Dentro de OBCs e Trails | Postmortems, métricas, resultados de experimentos |

### Artefatos gerados vs. artefatos de conhecimento

Nem todo documento no repositório é um artefato do Knowledge Space.

| Documento | Classificação | Motivo |
|---|---|---|
| `prodops/exec/cards/<slug>/context.md` | **Execution-generated** | Gerado pelo Downstream readiness a partir de artefatos existentes. Efêmero — não é a fonte do conhecimento. |
| Evidence | **Componente** | Não existe de forma autônoma. Sempre pertence a um OBC, Trail ou Experiment. Nunca tem Work Item próprio — o Work Item referencia o artefato que contém a evidência. |

### Propriedades dos artefatos

Um artefato:
- **tem identidade permanente** — um `slug` ou ID que persiste durante todo o seu ciclo de vida;
- **tem estado próprio** — Draft, Refining, Committed, In Delivery, Operational, Archived;
- **nunca é substituído por ferramentas** — GitHub Issues, Jira cards e ADO work items são reflexos temporários de trabalho, não o artefato em si;
- **é a fonte de verdade** — qualquer divergência entre o arquivo Markdown e uma representação em ferramenta deve ser resolvida em favor do arquivo Markdown.

---

## Execution Space — Trabalho

### O que é um Work Item

Um Work Item (GitHub Issue, PR, Release) representa **trabalho realizado sobre artefatos**. Ele:
- referencia explicitamente o(s) artefato(s) que afeta;
- descreve a operação que está sendo executada;
- fecha ou faz merge quando o trabalho termina;
- não substitui o artefato — o artefato continua existindo.

### Cardinalidade — não existe relação 1:1

Esta é a distinção mais importante do modelo:

```
Um artefato pode receber dezenas de Work Items ao longo de sua vida:

Local OBC (payments-invoice-v2)
  ├─ Issue: "Refinar critérios de aceite — Sprint 12"          → fechada
  ├─ Issue: "Atualizar OBC com resultado do postmortem"        → fechada
  ├─ PR: feat(invoice): implement payment split logic          → mergeado
  ├─ PR: fix(invoice): correct tax calculation edge case       → mergeado
  ├─ PR: docs(obc): add operational evidence month-3           → mergeado
  └─ Release: v2.1.0                                           → entregue

O OBC continua existindo com toda essa história acumulada.
```

```
Um Work Item pode afetar mais de um artefato simultaneamente:

Issue: "Adequar pagamentos e faturas ao novo regulamento XYZ"
  ├─ modifica: Local OBC payments-invoice-v2
  ├─ modifica: Local OBC payments-settlement-v1
  ├─ modifica: BDD feature payments-invoice.feature
  └─ modifica: Architecture overview.md

A Issue fecha. Os três artefatos continuam existindo, atualizados.
```

**Consequência:** não se deve criar um Work Item por artefato, nem tentar sincronizar o estado de um artefato com o estado de um Work Item. São universos independentes.

### Schema canônico de um Work Item

Todo Work Item deve referenciar explicitamente os artefatos que afeta:

| Campo | Descrição | Exemplo |
|---|---|---|
| **Artifact Type** | Tipo do artefato afetado | `Local OBC` |
| **Artifact ID** | Identificador ou caminho do artefato | `payments-invoice-v2` |
| **Operation** | O que está sendo feito sobre o artefato | `Refine`, `Create`, `Review`, `Update evidence` |
| **Journey** | Jornada ProdOps em execução | `Discovery`, `Delivery`, `Operation`, `Assessment` |
| **Execution Mode** | Modo de execução | `Upstream`, `Downstream` |
| **Owner** | Responsável | Product Manager |
| **Status** | Estado do Work Item | `Open`, `In Progress`, `Done` |
| **Release** | Release alvo (se aplicável) | `v2.1.0` |

### O que os GitHub Projects representam

Um GitHub Project representa **um domínio de gestão do trabalho** — não um backlog de artefatos.

| GitHub Project | Trabalho que representa |
|---|---|
| **Portfolio GitHub Project** | Work Items sobre Business Signals e Business Intents na plataforma |
| **Product Repository GitHub Project** | Work Items sobre Business Intents, OBCs, BDD, Plans no produto |

Views dentro de um GitHub Project são filtros sobre Work Items — nunca sobre artefatos.

---

## A relação correta

```
Artefato
  ↓
  └─ gera Work Items quando há trabalho a fazer sobre ele
        ↓
        Work Item (Issue / PR) no GitHub
              ↓
              referencia o artefato explicitamente
              ↓
              trabalho é executado
              ↓
              Work Item fecha / PR faz merge / Release é entregue
                    ↓
                    Artefato continua existindo, potencialmente atualizado
```

O ciclo completo de um artefato é: ele existe antes do primeiro Work Item, sobrevive a todos os Work Items, e continua existindo após o último Work Item.

---

## Exemplos

### Correto ✓

```
OBC payments-invoice-v2
  └─ Issue: "Refinar OBC — seção BDD incompleta"
       → referencia: payments-invoice-v2
       → operation: Refine
       → journey: Discovery
       → fecha quando BDD está completo
       → OBC continua existindo, agora em estado Committed
```

```
Business Intent BI-042 (Suporte a split de pagamento)
  └─ Issue: "Discovery — entender complexidade técnica do split"
       → referencia: BI-042
       → operation: Explore
       → journey: Discovery / Upstream
       → fecha quando decision é registrada na Intent
       → Business Intent continua existindo
```

### Incorreto ✗

```
❌ OBC = GitHub Issue #234
   (Issue representa o artefato, não o trabalho sobre ele)

❌ "Criar Issue para o Business Signal"
   (o Signal é um artefato — a Issue representa trabalho SOBRE ele)

❌ "Business Signal Issue" como tipo canônico de Issue
   (o tipo nomeia o artefato, não a operação)

❌ "GitHub Project contém Business Signals"
   (o Project contém Work Items sobre Signals, não os Signals)

❌ "GitHub Issue é a representação operacional do OBC"
   (não existe representação do OBC no GitHub — o OBC é o próprio artefato)
```

---

## Implicações para agentes e scripts

### Ao criar um Work Item

Sempre incluir no Work Item:
1. Referência ao(s) artefato(s) afetado(s) por tipo e ID
2. A operação sendo executada
3. A jornada ProdOps em curso

Nunca:
- criar um Work Item sem referência de artefato;
- assumir que um Work Item IS o artefato;
- sincronizar estado do artefato via estado de Issue.

### Ao ler o estado do trabalho

A fonte de verdade do **conhecimento** é sempre o arquivo Markdown do artefato.
A fonte de verdade da **execução em curso** é o GitHub Issue/PR/Project.

Se houver conflito — o arquivo Markdown prevalece.

### Ao fazer Diligence

Diligence sincroniza o estado dos artefatos com as ferramentas de execução. O objetivo de Diligence é verificar que:
- os artefatos (Markdown) refletem a realidade do trabalho executado;
- os Work Items referenciam os artefatos corretos;
- não existem Work Items "soltos" sem referência de artefato.

Diligence não cria Issues "para" artefatos. Ela cria Issues quando há **trabalho identificado** que precisa ser realizado sobre um artefato.

---

## Erros comuns

| Erro | Por que é errado | Como corrigir |
|---|---|---|
| "O OBC está na Issue #234" | O OBC é um arquivo Markdown. A Issue é trabalho sobre o OBC. | "A Issue #234 registra trabalho de refinamento sobre o OBC `payments-invoice-v2`" |
| "Fechar a Issue quando o OBC estiver Committed" | O estado do OBC é independente do estado da Issue | "Fechar a Issue quando o trabalho de refinamento estiver concluído. O OBC atingirá Committed quando seus critérios mínimos forem satisfeitos." |
| "Criar uma Issue para cada Business Intent" | Uma Business Intent pode ter dezenas de Issues ao longo de sua vida | "Criar Issues para operações específicas sobre a Intent: Discovery, Review, Atualizar OBC, etc." |
| "GitHub Project contém Business Signals" | O Project contém Work Items. Os Signals são artefatos nos arquivos. | "GitHub Project contém Work Items sobre Business Signals" |
| "A Business Intent Issue #42" | Nomeia a Issue pelo artefato, estabelecendo 1:1 | "Issue: 'Discovery — BI-042 Suporte a split de pagamento'" |

---

## Referências

→ [Modelo operacional](operating-model.md)
→ [Hierarquia de backlogs](backlogs.md)
→ [OBC — Observable Business Contract](obc.md)
→ [Governança de artefatos](artifact-governance.md)
→ [Glossário](glossary.md)
→ [Fluxo do framework](flow.md)
→ [Execution Mapping — operações por artefato](execution-mapping/README.md)
