# Jornadas

O Framework ProdOps possui cinco jornadas organizadas em dois grupos.

---

## Separação fundamental

**Modos de execução não são jornadas.**

| Conceito | O que é | Exemplo |
|---|---|---|
| **Modo** | Determina o nível de compromisso e os quality gates aplicados | Upstream, Downstream |
| **Jornada** | Descreve o caminho de trabalho dentro de um modo | Discovery, Delivery, Operation |
| **Backlog** | Organiza o trabalho antes e durante a execução | Product Intent Backlog, Icebox, Iteration Backlog |
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
| [Diligence](diligence/) | Garantir aderência ao modelo operacional |

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
Product Intent Backlog
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

| Backlog | Jornada responsável |
|---|---|
| Repository Tracking List / Global Tracking List | Assessment (sinaliza) |
| Product Intent Backlog | Diligence (sincroniza) |
| Icebox | Discovery (Downstream) — preparação |
| Iteration Backlog | Diligence + Assessment |
| Iteration Plan | Delivery — execução |

A Discovery no Downstream opera dentro do Icebox.
A Delivery começa somente quando um item entra no Iteration Plan.

---

## Jornadas transversais

Assessment e Diligence acompanham continuamente as demais jornadas. Não representam apenas documentação — representam comportamento ativo do Framework.

Assessment pode ocorrer tanto no Upstream quanto no Downstream.

→ [Execution Model](../execution-model/README.md)
→ [Hierarquia de backlogs](../framework/backlogs.md)
