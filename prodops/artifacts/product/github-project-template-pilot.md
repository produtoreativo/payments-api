# GitHub Project Template — Piloto Operacional Fase 2

> **Localização canônica:** `prodops/artifacts/product/github-project-template-pilot.md`
>
> Este documento define o **modelo conceitual** do GitHub Project para o Piloto Operacional Fase 2. Descreve Views, Campos e Regras de Representação.
>
> **Este documento NÃO implementa o Project via API.** Não contém chamadas GraphQL, scripts de criação ou automações. O GitHub Project é a **Representação Operacional Canônica (COR)** do ProdOps Framework — não é fonte de verdade para estado.

---

## 1. Princípio fundamental

> **O GitHub Project é a COR — Canonical Operational Representation.**
>
> O estado real de um Work Item reside na **Operational Timeline** (Event Instances imutáveis). O GitHub Project **projeta** o Derived State calculado pelo RT-02 — nunca o origina.
>
> Regra canônica (de `prodops/exec/manifest.yaml`):
> ```yaml
> github:
>   canonical_operational_representation:
>     view_semantics: projeção canônica de Issues por Journey/Phase/Operation
>     field_semantics: estado operacional necessário para projetar corretamente cada Work Item
>     label_semantics: classificação auxiliar — nunca fonte de verdade para estado
> ```

Consequências práticas:

- Se o Custom Field "State" no GitHub Project diz HACKING mas o RT-02 calcula BLOCKED, o **RT-02 está certo**. O GitHub Project está com drift.
- Atualizar o GitHub Project não altera a Timeline. A Timeline é imutável.
- Criar um Issue no GitHub Project não cria um Work Item no OEM. O Work Item existe quando `Bootstrap.Started` é emitido na Timeline.

---

## 2. Projeto

| Campo conceitual | Valor |
|---|---|
| **Nome** | ProdOps — payments-api |
| **Tipo** | GitHub ProjectsV2 |
| **Escopo** | Repositório `payments-api` |
| **Modo** | Privado (organização) |
| **Iteration** | IP-001 — Piloto Operacional Fase 2 |

---

## 3. Campos conceituais (Custom Fields)

Estes campos representam o estado operacional derivado da Timeline. São atualizados manualmente (neste piloto) ou por RT-03/RT-04 (pós-piloto).

| Campo | Tipo | Valores possíveis | Origem dos dados |
|---|---|---|---|
| **State** | Single select | `BOOTSTRAPPING · HACKING · SYNCING · FINISHING · SHIPPING · VALIDATING · PROMOTING · DONE · BLOCKED · REWORKING` | RT-02 → `DerivedState.state` |
| **Journey** | Single select | `Delivery · Diligence · Assessment` | RT-02 → `DerivedState.journey` |
| **Phase** | Single select | `Bootstrap · Hack · Sync · Finish · Ship · Validate · Promote · Rework` | RT-02 → `DerivedState.phase` |
| **Feature** | Text | `PI-PILOT-001` a `PI-PILOT-006` | Operador (estático por Issue) |
| **Work Item ID** | Text | Ex.: `wf-delivery-0001` | RT-02 → `DerivedState.work_item_id` |
| **Rework Count** | Number | `0, 1, 2, …` | RT-02 → `DerivedState.rework_count` |
| **Blocked Since** | Date | ISO-8601 ou vazio | RT-02 → `DerivedState.blocked_since` |
| **Last Event Type** | Text | Ex.: `Delivery.Hack.Completed` | RT-02 → `DerivedState.last_event_type` |
| **Computed At** | Date | ISO-8601 — timestamp do último evento | RT-02 → `DerivedState.computed_at` |
| **Has Corrections** | Checkbox | `true / false` | RT-02 → `DerivedState.has_corrections` |

### Regra de atualização

Durante o piloto, os campos são atualizados **manualmente** pelo operador após verificar o Derived State via RT-02. A sequência é:

1. Executar `replay()` ou `effectiveState()` no RT-02 para o Work Item
2. Copiar os valores do `DerivedState` resultante para os Custom Fields do Issue correspondente
3. Registrar o timestamp da atualização no campo **Computed At**

Futuramente (pós-piloto), esta atualização será feita por RT-03 (GitHub Synchronizer).

---

## 4. Campos de rastreabilidade (Labels)

Labels são **classificação auxiliar** — nunca fonte de verdade para estado.

| Label | Categoria | Descrição |
|---|---|---|
| `journey:delivery` | Journey | Work Item na Delivery Journey |
| `journey:diligence` | Journey | Work Item na Diligence Journey |
| `operation:hack` | Operation | Work Item em fase de Hack |
| `operation:sync` | Operation | Work Item em fase de Sync |
| `operation:finish` | Operation | Work Item em fase de Finish |
| `operation:promote` | Operation | Work Item promovido |
| `exception:blocked` | Exception | Work Item com Impediment ativo |
| `exception:rework` | Exception | Work Item em ciclo de Rework |
| `pilot:fase-2` | Pilot | Identificador da Iteration IP-001 |
| `feature:happy-path` | Feature type | Features PI-001 a PI-003 |
| `feature:exception` | Feature type | Features PI-004 a PI-006 |

**Regra:** Labels refletem o estado, não o definem. Se o State muda (RT-02), as labels devem ser atualizadas para refletir — mas a label desatualizada não invalida o Derived State.

---

## 5. Views

### 5.1 Views de Backlog

#### View: Product Backlog

**Finalidade:** visão do backlog completo da Release REL-PILOT-v1 — todas as 6 Features.

| Configuração | Valor |
|---|---|
| Layout | Table |
| Agrupamento | Por Field: State |
| Ordenação | Por Feature (PI-PILOT-001 → 006) |
| Filtro | `pilot:fase-2` |
| Campos visíveis | Feature, State, Journey, Phase, Rework Count |

**Semântica:** mostra o backlog completo e o estado atual de cada Work Item. Serve para visão geral da Iteration.

---

#### View: Release Planning

**Finalidade:** visão da Release — sequência de Features, dependências, gate de bloco.

| Configuração | Valor |
|---|---|
| Layout | Roadmap (ou Table com Field: Feature) |
| Agrupamento | Bloco (Happy Path · Exceções) |
| Filtro | `pilot:fase-2` |
| Campos visíveis | Feature, State, Blocked Since, Has Corrections |

**Semântica:** mostra o andamento da Release por Feature. Permite identificar se o gate de bloco entre Bloco 1 e Bloco 2 foi satisfeito.

---

### 5.2 Views de Delivery (Board)

#### View: Delivery — Current (Kanban)

**Finalidade:** board do CI Sync — estado atual de cada Work Item em execução.

| Configuração | Valor |
|---|---|
| Layout | Board |
| Colunas | `HACKING · SYNCING · FINISHING · BLOCKED · REWORKING` |
| Filtro | `journey:delivery` AND `pilot:fase-2` AND NOT `State = DONE` |
| Campos no card | Feature, Phase, Last Event Type, Computed At |

**Semântica:** mostra onde cada Work Item está no CI Sync. Uma única Feature deve estar ativa por vez (restrição do Iteration Plan).

---

#### View: Delivery — Done

**Finalidade:** evidência de Features concluídas.

| Configuração | Valor |
|---|---|
| Layout | Table |
| Filtro | `journey:delivery` AND `State = DONE` AND `pilot:fase-2` |
| Campos visíveis | Feature, Work Item ID, Computed At, Rework Count, Has Corrections |
| Ordenação | Por Computed At (mais recente primeiro) |

**Semântica:** cada linha é uma Feature que chegou a DONE. `Rework Count > 0` indica que passou por pelo menos um ciclo de revisão. `Has Corrections` indica que houve Event.Corrected na Timeline.

---

#### View: Delivery — Blocked

**Finalidade:** rastreamento de impedimentos ativos.

| Configuração | Valor |
|---|---|
| Layout | Table |
| Filtro | `exception:blocked` AND `pilot:fase-2` |
| Campos visíveis | Feature, Blocked Since, Last Event Type, Work Item ID |
| Ordenação | Por Blocked Since (mais antigo primeiro — maior impacto) |

**Semântica:** um Work Item aqui indica Impediment ativo. `Blocked Since` quantifica o Block Time acumulado. Visão vazia = nenhum bloqueio ativo.

---

### 5.3 Views de Diligence (Board)

#### View: Diligence — Sync (Active)

**Finalidade:** board do Diligence Sync — Work Items que precisam de Attach ou Promote no ciclo de conformidade.

| Configuração | Valor |
|---|---|
| Layout | Board |
| Colunas | `BOOTSTRAPPING · HACKING · SYNCING · FINISHING` |
| Filtro | `journey:diligence` AND NOT `State = DONE` |
| Campos no card | Work Item ID, Phase, Last Event Type |

**Semântica:** cada coluna representa uma fase do Diligence Sync. Durante o piloto, o Diligence Journey corre em paralelo com o Delivery Journey — cada Feature pode ter um Work Item de Diligence correspondente.

---

#### View: Diligence — Async (Findings)

**Finalidade:** rastreamento de Findings ativos e Remediations em andamento.

| Configuração | Valor |
|---|---|
| Layout | Table |
| Filtro | `journey:diligence` AND (`exception:blocked` OR `operation:sync`) |
| Campos visíveis | Work Item ID, State, Last Event Type, Blocked Since |

**Semântica:** Findings abertos aparecem aqui até serem reparados. Um Finding reparado (`State = DONE`) sai da view.

---

## 6. Regras de representação

### Regra 1 — Um Issue por Work Item

Cada Work Item (Feature no contexto do piloto) corresponde a **exatamente um GitHub Issue**. O Issue é criado quando o Work Item entra na Iteration (não quando é concluído).

### Regra 2 — Estado deriva da Timeline

O Custom Field **State** do Issue é sempre o valor de `DerivedState.state` calculado pelo RT-02. Nunca é editado manualmente baseado em opinião — sempre baseado no cálculo do RT-02.

### Regra 3 — COR é leitura, não escrita

Atualizar o GitHub Project **não** cria eventos na Timeline. Se o operador quiser registrar um estado, deve emitir o Event Instance via RT-01 — não editar o Custom Field diretamente.

Exceção documentada: durante o piloto, quando RT-03 (GitHub Sync automatizado) ainda não está implementado, o operador atualiza os Custom Fields manualmente — mas apenas **após** verificar o Derived State via RT-02. O RT-02 é a fonte; o GitHub Project é o espelho.

### Regra 4 — Labels são auxiliares

Labels como `operation:hack` ou `exception:blocked` refletem o estado atual para facilitar filtragem, mas não são fonte de verdade. Se a label está desatualizada em relação ao Custom Field **State**, o Custom Field prevalece.

### Regra 5 — Campos Computed At e Last Event Type

Esses campos identificam quando o estado foi calculado e qual evento o causou. São obrigatórios para diagnosticar drift: se `Computed At` está há horas no passado enquanto eventos novos foram emitidos, o GitHub Project está com drift e deve ser ressincronizado.

### Regra 6 — Drift é esperado neste piloto

Como RT-03 não está implementado, haverá latência entre o Event Instance emitido via RT-01 e a atualização do Custom Field no GitHub Project. Esta latência é **conhecida e aceitável** no piloto. O operador ressincroniza após cada fase (ou após `Finish.Completed`, no mínimo).

---

## 7. O que este template NÃO define

| Item | Razão |
|---|---|
| Script de criação via API GraphQL | Não implementar via API neste documento |
| GitHub Actions para atualização automática | Não criar GitHub Actions (restrição do prompt) |
| Automações de label | Idem |
| Webhooks do GitHub para RT-01 | Fora do escopo deste piloto |
| Views de Portfolio | Portfolio não é escopo do piloto |

---

## 8. Rastreabilidade

| Artefato | Localização |
|---|---|
| manifest.yaml (COR canônica) | `prodops/exec/manifest.yaml` |
| COR specification | `prodops/framework/journeys/diligence/github-workspace.md` |
| Workspace COR (evidências) | `experiments/013-runtime-validation/evidence/` |
| Release Plan | [release-plan-pilot.md](./release-plan-pilot.md) |
| Iteration Plan | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) |
