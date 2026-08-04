# Delivery Journey — Operational Event Model
# ProdOps Framework

> **Domínio:** Journey — Delivery
> **Status:** Canônico
> **Versão:** 1.0.0 (MVP)
> **Depende de:** [OEM README](../../../events/README.md) · [Event Type Schema](../../../events/event-type-schema.md) · [Taxonomy](../../../events/taxonomy.md) · [Lifecycle](../../../events/lifecycle.md)

---

## Sobre este documento

Este documento explica como a Jornada Delivery utiliza o Operational Event Model (OEM).
Define o modelo de estados operacionais, os dois ciclos de entrega, e a estrutura do
catálogo de Event Types.

O catálogo concreto dos tipos está em [catalog.md](catalog.md).

---

## 1. A Jornada Delivery no ProdOps

A Jornada Delivery representa o fluxo operacional de um Work Item desde sua ativação até
a entrega em produção. É composta por dois ciclos independentes em sequência:

**CI Sync** — ciclo síncrono de desenvolvimento e integração:
```
Bootstrap → Hack → Sync → Finish
```

**CI Async** — ciclo assíncrono de entrega e validação:
```
Ship → Validate → Promote
```

O trabalho começa no CI Sync (Bootstrap) e termina no CI Async (Promote.Completed → DONE).

---

## 2. Modelo de Estados Operacionais

O Derived State de um Work Item na Jornada Delivery segue a progressão:

```
BOOTSTRAPPING → HACKING → SYNCING → FINISHING → SHIPPING → VALIDATING → PROMOTING → DONE
```

Estado transversal (qualquer Phase):
```
BLOCKED  — declarado por Impediment.Declared; resolvido por Impediment.Resolved
```

### 2.1 Significado de cada estado

| Estado | Fase | O que representa |
|---|---|---|
| **BOOTSTRAPPING** | CI Sync — Bootstrap | O Work Item está em preparação do ambiente de trabalho |
| **HACKING** | CI Sync — Hack | O Work Item está em desenvolvimento ativo |
| **SYNCING** | CI Sync — Sync | O Work Item está em revisão de código (PR aberto) |
| **FINISHING** | CI Sync — Finish | O Work Item passou pela revisão e está em checagens finais |
| **SHIPPING** | CI Async — Ship | O Work Item está sendo implantado em ambiente de homologação |
| **VALIDATING** | CI Async — Validate | O Work Item está em validação em homologação |
| **PROMOTING** | CI Async — Promote | O Work Item aguarda ou está em processo de promoção para produção |
| **DONE** | — | O Work Item foi entregue em produção com sucesso |
| **BLOCKED** | Qualquer Phase | O Work Item está bloqueado por impedimento externo |

### 2.2 Derivação de estado

O Derived State é sempre o `new_state` do último evento com `alters_state = true` na
Timeline do Work Item. Consumers não devem calcular estado por nenhum outro meio.

Eventos com `alters_state = false` — gates, aprovações, notas — são registrados na
Timeline e afetam métricas, mas não alteram o Derived State.

---

## 3. Os Dois Ciclos de Entrega

### 3.1 CI Sync

O CI Sync é o ciclo síncrono — requer presença ativa do developer.

```
Bootstrap.Started (BOOTSTRAPPING)
    ↓
Bootstrap.Completed (HACKING)
    ↓ [desenvolvimento ativo]
Hack.Completed (SYNCING) — PR aberto
    ↓ [revisão de código]
Gate events + Review events
    ↓
Sync.Completed (FINISHING) — PR mergeado
    ↓ [checagens finais]
Finish.Completed (SHIPPING)
```

**Saída do CI Sync:** o Work Item está em estado SHIPPING — pronto para o ciclo assíncrono.

### 3.2 CI Async

O CI Async é o ciclo assíncrono — pode rodar sem presença ativa do developer.

```
Ship.Completed (VALIDATING) — implantado em homologação
    ↓ [validação automatizada + manual]
Gate events
    ↓
Promote.Approved (PROMOTING) — decisão humana de promover para produção
    ↓
Promote.Completed (DONE) — produção atualizada
```

**Saída do CI Async:** o Work Item está em estado DONE — entregue.

### 3.3 Eventos transversais

Dois grupos de eventos podem ocorrer em qualquer Phase, interrompendo o fluxo normal:

**Blocking:** impedimentos externos que suspendem o trabalho.
- `Impediment.Declared` → BLOCKED
- `Impediment.Resolved` → retorna ao trabalho (HACKING no MVP)

**Rework:** retorno a uma fase anterior por qualidade insuficiente.
- `Rework.Declared` → HACKING (retorno ao desenvolvimento)
- `Rework.Completed` → SYNCING (novo PR aberto após rework)

---

## 4. Event Categories utilizadas

A Jornada Delivery utiliza 5 das 8 Event Categories definidas na Taxonomia do OEM:

| Category | Uso na Delivery |
|---|---|
| **Phase Lifecycle** | Início e conclusão de cada Phase; alterações de Derived State |
| **Gate** | Verificações automatizadas de qualidade (smoke tests, lint, CI gates) |
| **Human Decision** | Aprovações e revisões humanas (code review, decisão de promoção) |
| **Blocking** | Declaração e resolução de impedimentos externos |
| **Rework** | Ciclos de retorno ao desenvolvimento após revisão |

As categories **System**, **Diligence** e **Correction** não estão representadas neste
catálogo MVP — são candidatas a expansão futura.

---

## 5. Convenção de nomenclatura

Todos os Event Types seguem a convenção `Subject.Action` (sem Namespace dentro do catálogo
próprio). Em referências cross-Journey, o Namespace `Delivery` é adicionado:

```
Bootstrap.Started    →  referência interna
Delivery.Bootstrap.Started  →  referência cross-Journey
```

PascalCase em todos os componentes. Nomes livres de referências a tecnologia ou implementação.

---

## 6. Versão do catálogo e lifecycle

| Campo | Valor |
|---|---|
| Versão do catálogo | 1.0.0 (MVP) |
| Todos os tipos | Active |
| Shared Types utilizados | Nenhum neste MVP |
| Shared Types candidatos | Gate.Passed, Gate.Failed, Impediment.Declared, Impediment.Resolved, Rework.Declared, Rework.Completed |

---

## 7. Limitações conhecidas do MVP

Este catálogo é um **MVP de validação** — suficiente para cobrir o fluxo completo da
Jornada Delivery, mas não exaustivo.

Limitações documentadas intencionalmente:

| Limitação | Impacto | Endereçamento futuro |
|---|---|---|
| `Impediment.Resolved` retorna sempre a HACKING | Simplificação — em produção deveria restaurar o estado pré-bloqueio | Expandir no catálogo v2; pode requerer campo adicional no payload |
| Sem eventos System (Pipeline.Failed, Deploy.Failed) | Falhas de infraestrutura não são rastreadas | Catálogo v2 — category System |
| Sem eventos Hack.Started e Sync.Started | Início explícito das Phases não é registrado | Catálogo v2 — baixa prioridade |
| Sem Validate.Completed separado de Promote.Approved | Fim da validação e início da promoção são implícitos | Catálogo v2 |
| Sem Waiting.Declared/Resolved | Dependências externas são agregadas em Impediment | Catálogo v2 |

---

## Referências

- [OEM Fundação](../../../events/README.md)
- [Ontologia OEM](../../../events/ontology.md)
- [Taxonomia OEM](../../../events/taxonomy.md)
- [Lifecycle OEM](../../../events/lifecycle.md)
- [Event Type Schema](../../../events/event-type-schema.md)
- [Event Instance Schema](../../../events/event-instance-schema.md)
- [Catálogo Delivery MVP](catalog.md)
