# Delivery Strategy — Piloto Operacional Fase 2

> **Localização canônica:** `prodops/artifacts/product/delivery-strategy-pilot.md`
>
> Este documento define o **modelo operacional do CI Sync** para o Piloto Operacional Fase 2. Descreve como cada Feature percorre as fases Bootstrap → Hack → Sync → Finish, as condições de transição entre fases, e as responsabilidades exclusivas do Delivery.
>
> O CI Async (Ship → Validate → Promote) e os padrões de exceção (Rework, Blocking) são cobertos separadamente nas seções de exceção.

---

## 1. Pipeline oficial

A fonte de verdade do pipeline é `prodops/exec/manifest.yaml`:

```yaml
pipeline:
  ci_sync:  [bootstrap, hack, sync, finish]
  ci_async: [ship, validate, promote]
```

O CI Sync é o escopo principal da Delivery Strategy. O CI Async é executado após o Finish.

---

## 2. Modelo operacional do CI Sync

### Visão geral

```
Bootstrap → Hack → Sync → Finish
               ↑         ↓
               └─────────┘
          (Changes Requested → retorno ao Hack)
```

Cada fase é executada pela skill correspondente. O `/delivery` invoca a skill da fase atual, aguarda a conclusão, emite o Event Instance de transição via RT-01, e avança para a próxima fase.

---

### Fase 1 — Bootstrap

**Objetivo:** preparar o ambiente de trabalho para a Feature.

**Entrada:**
- Feature está no topo da sequência do Iteration Plan IP-001
- Pré-condições da Feature satisfeitas (ver `iteration-plan-pilot.md`)
- `Delivery.Finish.Completed` da Feature anterior registrado (se não for a primeira)

**Atividades:**
1. Criar branch `feature/<slug-da-feature>` a partir de `master`
2. Verificar que o ambiente sandbox está acessível (Asaas sandbox + GitHub + RT-01/RT-02)
3. Confirmar que o OBC da Feature está legível (PI correspondente)
4. Registrar `Delivery.Bootstrap.Started` via RT-01

**Saída:**
- Branch criada e limpa
- `Delivery.Bootstrap.Completed` registrado via RT-01 (ou `Delivery.Hack.Started` diretamente, se Bootstrap for trivial)

**Responsabilidade exclusiva do Delivery:** verificar branch, ambiente e OBC antes de emitir `Bootstrap.Started`.

---

### Fase 2 — Hack

**Objetivo:** implementar o comportamento especificado pela Feature.

**Entrada:**
- `Bootstrap.Completed` (ou `Bootstrap.Started`, dependendo da Feature) registrado na Timeline
- Branch ativa e limpa

**Atividades:**
1. Implementar o comportamento da Feature (conforme BDD/OBC da PI correspondente)
2. Escrever ou atualizar testes de aceitação
3. Executar `npm run lint` e `npm run build` — Exit 0
4. Executar `./scripts/test-acceptance.sh` — Exit 0
5. Confirmar que nenhum `jest.fn(`, `.mockReturnValue(`, `.overrideProvider(` ou `jest.mock(` foi introduzido
6. Registrar `Delivery.Hack.Started` (no início) e `Delivery.Hack.Completed` (ao concluir) via RT-01

**Saída:**
- Código implementado, testes passando, lint limpo
- `Delivery.Hack.Completed` registrado via RT-01

**Invariante:** o Hack não faz push. Branch permanece local até o Sync.

---

### Fase 3 — Sync

**Objetivo:** sincronizar o trabalho com a base (`master`) e validar integridade da integração.

**Entrada:**
- `Hack.Completed` registrado na Timeline
- Branch local com código testado

**Atividades:**
1. Rebase da branch sobre `master` (ou merge, conforme convenção do repositório)
2. Resolver conflitos (se houver)
   - Conflito simples: resolver e continuar
   - Conflito não resolvível sem decisão de produto: registrar `Delivery.Gate.Failed` e pausar (PI-PILOT-004 — padrão de exceção)
3. Re-executar `npm run lint`, `npm run build`, `./scripts/test-acceptance.sh` pós-rebase — Exit 0
4. Push da branch para o remoto
5. Abrir Pull Request (sem assign de reviewers neste momento — Finish faz o assign)
6. Registrar `Delivery.Sync.Started` (no início) e `Delivery.Sync.Completed` via RT-01

**Saída:**
- Branch no remoto, PR aberto
- `Delivery.Sync.Completed` registrado via RT-01

**Conflito durante Sync (PI-PILOT-004):**
- Registrar `Delivery.Gate.Failed` com payload descritivo
- Pausar — não avançar para Finish
- Resolução: Gate.Passed após reconciliação → retomar Sync

---

### Fase 4 — Finish

**Objetivo:** encerrar a Feature após merge do PR.

**Entrada:**
- `Sync.Completed` registrado na Timeline
- PR aberto no GitHub

**Atividades:**
1. Registrar `Delivery.Finish.Started` via RT-01
2. Solicitar review do PR (assign de reviewers)
3. Aguardar decisão do reviewer:

   **Caminho A — PR Aprovado (Merged):**
   - PR é aprovado e merged em `master`
   - Registrar `Delivery.Finish.Completed` via RT-01
   - **Finish encerrado** — Feature pronta para CI Async

   **Caminho B — PR com Changes Requested:**
   - Reviewer solicita alterações (Changes Requested)
   - Se as mudanças exigirem retorno ao Hack: registrar `Delivery.Rework.Started` e retornar ao Hack (PI-PILOT-005 — padrão de exceção)
   - Se as mudanças são menores (não exigem Rework): resolver inline, push, aguardar re-review

**Saída:**
- PR merged em `master`
- `Delivery.Finish.Completed` registrado via RT-01
- Branch de feature deletada (opcional, após merge)

**Invariante crítica:** `Finish.Completed` só é emitido **após** o PR ser merged. Nunca antes. O Finish não encerra com PR aberto.

---

## 3. Retorno de Finish para Hack (Changes Requested → Rework)

Quando o reviewer solicita alterações que exigem trabalho significativo de implementação:

```
Finish.Started
    ↓
[Changes Requested]
    ↓
Rework.Started       → Estado OSE: REWORKING, rework_count++
    ↓
Hack.Started         (novo ciclo)
    ↓
Hack.Completed
    ↓
Sync.Started
    ↓
Sync.Completed
    ↓
Finish.Started       (novo ciclo de Finish)
    ↓
[PR Aprovado]
    ↓
Rework.Completed     → OSE restaura estado pré-rework (SHIPPING)
    ↓
Gate.Passed
    ↓
Finish.Completed
```

**Regra de decisão:** o operador decide se uma solicitação de revisão dispara Rework ou é resolvida inline. O `/delivery` não toma esta decisão — o operador informa ao `/delivery` que o Rework foi iniciado.

**Critério de Rework vs. mudança inline:**
- **Rework:** o reviewer pede reescrita significativa de lógica de negócio, mudança de arquitetura, ou adição de comportamento não previsto no Hack original
- **Mudança inline:** o reviewer pede ajuste de nomenclatura, comentário, formatação ou pequena correção que não exige novo ciclo de implementação

---

## 4. Responsabilidades exclusivas do Delivery

O Delivery (CI Sync + CI Async) é responsável exclusivamente por:

| Responsabilidade | Fase |
|---|---|
| Criar e gerenciar branches de feature | Bootstrap |
| Verificar que o ambiente sandbox está acessível | Bootstrap |
| Implementar comportamento da Feature conforme PI/OBC | Hack |
| Garantir que todos os quality gates passam (lint, build, acceptance) | Hack, Sync |
| Garantir que nenhum mock foi introduzido | Hack |
| Sincronizar branch com `master` e resolver conflitos | Sync |
| Abrir PR e solicitar review | Sync, Finish |
| Aguardar merge do PR antes de emitir `Finish.Completed` | Finish |
| Emitir Event Instances na Timeline via RT-01 | Todas as fases |
| Verificar Derived State via RT-02 após cada fase | Todas as fases |

**O Delivery NÃO é responsável por:**

| Não responsabilidade | Responsável |
|---|---|
| Decidir quais Features entram na Iteration | Product Owner (Iteration Plan pré-definido) |
| Decidir a ordem das Features | Iteration Plan (fixo) |
| Resolver conflitos de produto durante Sync | Operador / Product Owner |
| Resolver impedimentos externos (Blocking) | Operador + blocker_owner |
| Atualizar dashboards Datadog | RT-04 (fora do escopo deste piloto) |
| Sincronizar GitHub COR automaticamente | Operador (manual neste piloto) |

---

## 5. Events por fase (referência rápida)

| Fase | Evento(s) emitidos via RT-01 |
|---|---|
| Bootstrap | `Delivery.Bootstrap.Started` · `Delivery.Bootstrap.Completed` (opcional) |
| Hack | `Delivery.Hack.Started` · `Delivery.Hack.Completed` |
| Sync (normal) | `Delivery.Sync.Started` · `Delivery.Sync.Completed` |
| Sync (conflito) | `Delivery.Sync.Started` · `Delivery.Gate.Failed` · `Delivery.Gate.Passed` · `Delivery.Sync.Completed` |
| Finish (aprovado) | `Delivery.Finish.Started` · `Delivery.Finish.Completed` |
| Finish (Changes Requested → Rework) | `Delivery.Finish.Started` · `Delivery.Rework.Started` · (retorna ao Hack) · `Delivery.Rework.Completed` · `Delivery.Gate.Passed` · `Delivery.Finish.Completed` |
| Ship | `Delivery.Ship.Started` · `Delivery.Ship.Completed` |
| Validate | `Delivery.Validate.Started` · `Delivery.Gate.Passed` · `Delivery.Validate.Completed` |
| Promote | `Delivery.Promote.Started` · `Delivery.Promote.Completed` |
| Blocking | `Delivery.Impediment.Raised` · `Delivery.Impediment.Resolved` |

---

## 6. Quality Gates (do manifest.yaml)

Todos os gates a seguir devem passar antes de `Sync.Completed`:

```yaml
gates:
  lint:      cd api && npm run lint     # Exit 0
  build:     cd api && npm run build    # Exit 0
  acceptance: ./scripts/test-acceptance.sh  # Exit 0 (quando behavior/contract mudou)
  no_mocks:
    grep: [jest.fn(, .mockReturnValue(, .overrideProvider(, jest.mock(]
    in: [api/src, api/test]
    expect: zero_hits
```

**Regressão de Runtime:** além dos gates de produto, o piloto exige `npm test` em:
- `runtime/producer/` — 37 testes
- `runtime/state-engine/` — 98 testes

Ambos devem permanecer em Exit 0 durante toda a Iteration.

---

## 7. Rastreabilidade

| Artefato | Localização |
|---|---|
| manifest.yaml (pipeline fonte) | `prodops/exec/manifest.yaml` |
| Release Plan | [release-plan-pilot.md](./release-plan-pilot.md) |
| Iteration Plan | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) |
| Skill Bootstrap | `prodops/skills/bootstrap/SKILL.md` |
| Skill Hack | `prodops/skills/hack/SKILL.md` |
| Skill Sync | `prodops/skills/sync/SKILL.md` |
| Skill Finish | `prodops/skills/finish/SKILL.md` |
