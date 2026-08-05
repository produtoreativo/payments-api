# Jornadas

O Framework ProdOps possui cinco jornadas organizadas em dois grupos.

---

## Separação fundamental

**Modos de execução não são jornadas.**

| Conceito | O que é | Exemplo |
|---|---|---|
| **Modo** | Determina o nível de compromisso e os quality gates aplicados | Upstream, Downstream |
| **Jornada de produto** | Descreve o caminho de trabalho orientado ao produto | Discovery, Delivery, Operation |
| **Jornada ProdOps** | Acompanha transversalmente as jornadas de produto | Assessment, Diligence |
| **Backlog** | Organiza o trabalho antes e durante a execução | Product Backlog, Icebox, Iteration Backlog |
| **Plano** | Registra a execução de uma iteração | Iteration Plan |

Upstream e Downstream são modos, não jornadas. A Discovery é a jornada — ela existe em ambos os modos com responsabilidades diferentes.

---

## Responsabilidade de cada jornada

| Jornada | Responsabilidade única |
|---|---|
| [Discovery](discovery/) | Reduzir incertezas e preparar o trabalho |
| [Delivery](delivery/) | Construir, validar e promover a solução |
| [Operation](operation/) | Operar e evoluir o produto em produção |
| [Assessment](assessment/) | Produzir análises para apoiar decisões |
| [Diligence](diligence/) | Garantir a consistência do sistema de trabalho do ProdOps |

---

## Relacionamento entre jornadas

```mermaid
flowchart TD
    subgraph MODES["Modos de execução — determinam compromisso e gates"]
        UP["Upstream\nexploração sem compromisso"]
        DOWN["Downstream\ncompromisso com entrega"]
    end

    subgraph PRODUCT["Jornadas de produto"]
        DIS["Discovery\nReduz incertezas e\nprepara o trabalho"]
        DEL["Delivery\nCI Sync → CI Async\nBootstrap → Promote"]
        OP["Operation\nObservabilidade, incidentes,\npostmortems, DORA"]
    end

    subgraph TRANSVERSAL["Jornadas transversais"]
        ASS["Assessment\nAnalisa e informa"]
        DIL["Diligence\nVerifica e corrige"]
    end

    %% Modos determinam como Discovery opera — não são jornadas
    UP -."Discovery opera\nsem compromisso".-> DIS
    DOWN -."Discovery prepara\nOBC Committed".-> DIS

    %% Fluxo principal das jornadas de produto
    DIS -->|"OBC Committed\n→ Iteration Plan"| DEL
    DEL -->|"Promote.Completed"| OP
    OP -."sinais operacionais\nalimentam novos intents".-> DIS

    %% Assessment — transversal às 3 jornadas de produto
    ASS -."análises e recomendações".-> DIS
    ASS -."análises e recomendações".-> DEL
    ASS -."análises e recomendações".-> OP
    DIS -."hipóteses e riscos\npré-compromisso".-> ASS
    DEL -."timelines + métricas".-> ASS
    OP -."postmortems + DORA".-> ASS

    %% Diligence — transversal às 3 jornadas de produto
    DIL -."verifica consistência".-> DIS
    DIL -."verifica consistência".-> DEL
    DIL -."verifica consistência".-> OP
    DEL -->|"eventos disparam\nDiligence Sync"| DIL
    DIL -."Findings alimentam".-> ASS

    %% Paleta — subgraphs
    style MODES      fill:#dbeafe,stroke:#2563eb,color:#1e3a5f
    style PRODUCT    fill:#dcfce7,stroke:#16a34a,color:#14532d
    style TRANSVERSAL fill:#f5f3ff,stroke:#7c3aed,color:#4c1d95

    %% Paleta — nós individuais
    style UP   fill:#bfdbfe,stroke:#1d4ed8,color:#1e3a5f
    style DOWN fill:#bfdbfe,stroke:#1d4ed8,color:#1e3a5f
    style DIS  fill:#bbf7d0,stroke:#15803d,color:#14532d
    style DEL  fill:#bbf7d0,stroke:#15803d,color:#14532d
    style OP   fill:#bbf7d0,stroke:#15803d,color:#14532d
    style ASS  fill:#fef3c7,stroke:#d97706,color:#78350f
    style DIL  fill:#ede9fe,stroke:#7c3aed,color:#3b0764

    %% Setas — modo → discovery (azul, médias)
    linkStyle 0,1 stroke:#2563eb,stroke-width:2px,stroke-dasharray:6

    %% Setas — fluxo principal produto (verde, grossas)
    linkStyle 2,3 stroke:#15803d,stroke-width:3px

    %% Seta — ciclo operacional de volta (verde, média tracejada)
    linkStyle 4 stroke:#15803d,stroke-width:2px,stroke-dasharray:6

    %% Setas — Assessment ↔ jornadas (âmbar)
    linkStyle 5,6,7,8,9,10 stroke:#d97706,stroke-width:2px,stroke-dasharray:4

    %% Setas — Diligence ↔ jornadas (violeta)
    linkStyle 11,12,13 stroke:#7c3aed,stroke-width:2px,stroke-dasharray:4
    linkStyle 14 stroke:#7c3aed,stroke-width:3px
    linkStyle 15 stroke:#7c3aed,stroke-width:2px,stroke-dasharray:4
```

---

## Fluxo Upstream

```
Intent
  ↓
Upstream
  ↓
Discovery (exploratório)
  ↓
Aprendizados / Protótipos / Experimentos
  ↓
(Eventualmente) → Downstream
```

Não existe compromisso de entrega. O objetivo é reduzir incerteza. Uma Intent pode permanecer indefinidamente no Upstream, ser descartada, retornar ao Portfolio ou seguir para Downstream.

---

## Fluxo Downstream

```
Intent
  ↓
Product Backlog
  ↓
Icebox (Discovery preparatória)
  ↓
Iteration Backlog
  ↓
Iteration Plan
  ↓
Delivery (CI Sync → CI Async)
  ↓
Operation
```

Existe compromisso de entrega, validação, governança e confiabilidade.

---

## Relação entre jornadas e backlogs

| Backlog | Responsável |
|---|---|
| Portfolio Tracking List | Portfolio (Assessment sinaliza) |
| Product Tracking List | Product Owner (Assessment sinaliza) |
| Product Backlog | Product Owner gerencia; Diligence sincroniza consistência |
| Icebox | Discovery (Downstream) — preparação |
| Iteration Backlog | Product Owner + Diligence |
| Iteration Plan | Delivery — execução |

O **Product Backlog** é gerenciado pelo Product Owner. A Diligence sincroniza o estado dos artefatos e das ferramentas — não gerencia o backlog. A Diligence garante consistência; a priorização é responsabilidade do Product Owner.

A Discovery no Downstream opera dentro do Icebox.
A Delivery começa somente quando um item entra no Iteration Plan.

---

## Jornadas transversais

Assessment e Diligence não são etapas de um fluxo linear — são jornadas que acompanham as três jornadas de produto simultaneamente. A diferença entre elas não é de posição, mas de **foco**: Assessment analisa e informa; Diligence verifica e corrige.

```
               DISCOVERY     DELIVERY     OPERATION
                   │             │             │
                   │             │             │
ASSESSMENT ────────┼─────────────┼─────────────┤
                   │             │             │
DILIGENCE  ────────┼─────────────┼─────────────┤
                   │             │             │
                   ▼             ▼             ▼
```

O peso e o esforço de cada jornada transversal variam conforme a jornada de produto em que operam:

| | Discovery | Delivery | Operation |
|---|---|---|---|
| **Assessment** | Médio — avalia hipóteses, riscos e prontidão pré-compromisso | Alto — gate formal de entrada + análise retroativa de timelines | Alto — postmortems, DORA, sinais operacionais alimentam novos intents |
| **Diligence** | Leve — consistência dos artefatos exploratórios | Alto — sincroniza OBC, eventos, timelines e estado do Project em tempo real | Médio — detecta drift acumulado de artefatos e conformidade operacional |

---

### Assessment

Produz análises e recomendações que apoiam decisões. Não bloqueia o fluxo por si só — gera insumos que outros atores usam para decidir.

**Questão central:** O que sabemos, o que não sabemos e o que devemos decidir antes de avançar?

→ [Assessment — especificação completa](assessment/README.md)

---

### Diligence

Verifica se o sistema de trabalho do ProdOps permanece coerente e rastreável. Opera de forma reativa (síncrona) a eventos de entrega e de forma proativa (assíncrona) para detectar drift acumulado.

**Questão central:** O conhecimento, as decisões, a execução e as evidências continuam coerentes e rastreáveis?

A Diligence opera em exatamente dois ciclos:
- **diligence-sync** — síncrono, reativo, contextual, ligado a uma operação em andamento
- **diligence-async** — assíncrono, proativo, para detecção de drift acumulado

Capabilities como Workspace Reconciliation são sub-rotinas consumidas pelos ciclos — não são ciclos independentes.

→ [Diligence — especificação completa](diligence/README.md)

---

→ [Execution Model](../execution-model/README.md)
→ [Hierarquia de backlogs](../backlogs.md)
