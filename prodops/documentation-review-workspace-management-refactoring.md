# Documentation Review — Workspace Management Capability Refactoring

**Data:** 2026-07-26
**Revisor:** Claude (automatizado)
**Escopo:** Refactoring arquitetural de `runtime/workspace` — consolidação em Workspace Management Capability
**Antecedente:** [documentation-review-pilot-project-materialization.md](./documentation-review-pilot-project-materialization.md)

---

## Sumário

`runtime/workspace` foi refatorado para consolidar toda a responsabilidade de gerenciamento do GitHub Workspace em uma única Capability. Foram introduzidos 7 Providers com hierarquia de estratégia explícita. O `DriftItem` foi enriquecido com metadados de Provider/Strategy. O Doctor agora reporta qual Provider foi usado, qual estratégia foi aplicada e se auto-correção é possível.

Nenhum código foi duplicado. Nenhum Runtime paralelo foi criado. Os adaptadores `github/` permanecem inalterados. Compatibilidade preservada — typecheck Exit 0.

---

## 1. Componentes introduzidos

### 1.1 WorkspaceManagementCapability (`src/capability.ts`)

Ponto de entrada único para toda a responsabilidade de gerenciamento do GitHub Workspace. Agrega os 7 Providers em um objeto `const` tipado.

```typescript
WorkspaceManagementCapability.project      // ProjectProvider
WorkspaceManagementCapability.field        // FieldProvider
WorkspaceManagementCapability.view         // ViewProvider
WorkspaceManagementCapability.label        // LabelProvider
WorkspaceManagementCapability.milestone    // MilestoneProvider
WorkspaceManagementCapability.iteration    // IterationProvider
WorkspaceManagementCapability.membership   // MembershipProvider
WorkspaceManagementCapability.allProviders // lista ordenada para Doctor summary
```

**Regra canônica (documentada em capability.ts):**
- Journeys (Delivery, Diligence) não importam de `runtime/workspace`
- Esta Capability materializa a COR; não origina estado

### 1.2 Providers (`src/providers/`)

7 Providers introduzidos, cada um com:
- `name` — identificador do Provider (usado em DriftItem)
- `meta: ProviderMeta` — estratégia primária, alternativa, autoCorrectPossible
- Funções delegadas dos adaptadores `github/` (sem duplicação)

| Provider | Estratégia primária | Alternativa | Auto-correct |
|---|---|---|---|
| ProjectProvider | gh-cli | graphql | sim |
| FieldProvider | gh-cli | — | sim |
| ViewProvider | manual-intervention | graphql (list) | **não** |
| LabelProvider | gh-cli | rest | sim |
| MilestoneProvider | rest | gh-cli | sim |
| IterationProvider | manual-intervention | — | **não** |
| MembershipProvider | gh-cli | graphql | sim |

**Hierarquia declarada (src/types.ts):**
```typescript
type ProviderStrategy = 'graphql' | 'rest' | 'gh-cli' | 'browser-automation' | 'manual-intervention';
```

### 1.3 ProviderMeta (`src/providers/strategy.ts`)

Interface que todos os Providers satisfazem:
```typescript
interface ProviderMeta {
  providerName: string;
  strategyUsed: ProviderStrategy;
  alternativeStrategy: ProviderStrategy | null;
  autoCorrectPossible: boolean;
}
```

---

## 2. Componentes reorganizados

### 2.1 DriftItem (src/types.ts)

Antes:
```typescript
interface DriftItem {
  resource: string;
  name: string;
  severity: DriftSeverity;
  expected?: unknown;
  actual?: unknown;
  recommendation: string;
}
```

Depois (4 campos adicionados):
```typescript
interface DriftItem {
  resource: string;
  name: string;
  severity: DriftSeverity;
  expected?: unknown;
  actual?: unknown;
  recommendation: string;
  providerUsed: string;           // qual Provider detectou e corrigiria este drift
  strategyUsed: ProviderStrategy; // estratégia que o Provider usaria
  alternativeStrategy: ProviderStrategy | null;
  autoCorrectPossible: boolean;   // true = 'workspace provision' corrige; false = manual
}
```

### 2.2 DoctorReport (src/types.ts)

Campo `providers` adicionado:
```typescript
interface DoctorReport {
  // ... campos existentes ...
  providers: Record<string, ProviderSummary>; // novo
}

interface ProviderSummary {
  strategyUsed: ProviderStrategy;
  alternativeStrategy: ProviderStrategy | null;
  resourcesChecked: number;
  driftsFound: number;
  autoCorrectPossible: boolean;
}
```

### 2.3 doctor.ts

Antes: construía DriftItems com chamadas diretas a `github/` + campos de drift sem metadados de Provider.

Depois:
- Usa `WorkspaceManagementCapability` em todos os blocos de detecção
- Helper `makeDrift()` centraliza a construção de DriftItem com provider metadata
- Helper `providerSummary()` centraliza a construção de ProviderSummary
- `printReport()` expandido: exibe `provider`, `strategy`, `alt`, `auto-correct` por drift + seção "Providers" com resumo por Provider

Saída do Doctor (exemplo para view faltante):
```
❌ [view] Delivery — Current
   fix      : Manual: https://github.com/orgs/... — create "Delivery — Current" with BOARD layout (...)
   provider : ViewProvider  strategy: manual-intervention  auto-correct: no
```

### 2.4 provisioner.ts

Antes: importava funções individuais de `github/project.ts`, `github/labels.ts`, etc.

Depois: importa `WorkspaceManagementCapability` e delega para Providers. Lógica idêntica — apenas ponto de importação consolidado. Nenhuma funcionalidade alterada.

---

## 3. Componentes inalterados

| Componente | Status |
|---|---|
| `src/github/client.ts` | inalterado |
| `src/github/project.ts` | inalterado |
| `src/github/labels.ts` | inalterado |
| `src/github/issues.ts` | inalterado |
| `src/github/milestone.ts` | inalterado |
| `src/cli.ts` | inalterado |
| `workspace.yaml` | inalterado |
| `tsconfig.json` | inalterado |
| `package.json` | inalterado |

Os adaptadores `github/` continuam sendo a camada de implementação. Os Providers são wrappers de metadados — não reescrevem lógica.

---

## 4. Código removido

Nenhum código foi removido. A refatoração é aditiva:
- `github/` permanece como implementação
- Providers adicionam metadados sem duplicar lógica
- `doctor.ts` e `provisioner.ts` trocam imports diretos de `github/` por `WorkspaceManagementCapability` — mesmo número de chamadas

---

## 5. Compatibilidade

| Verificação | Resultado |
|---|---|
| `npm run typecheck` | ✅ Exit 0 |
| CLI `workspace provision` | ✅ Compatível — mesma lógica, sem breaking changes |
| CLI `workspace doctor` | ✅ Compatível — output expandido, não quebra |
| `DoctorReport` shape | ✅ Adição de `providers` é backward-compatible (novo campo) |
| `DriftItem` shape | ⚠️ Campos obrigatórios adicionados — consumidores externos que constroem DriftItem diretamente precisam adicionar os 4 campos. Neste módulo, apenas `doctor.ts` constrói DriftItems (via `makeDrift()`). |

---

## 6. Melhorias arquiteturais

### Transparência de estratégia

Antes, um consumer do Doctor precisaria inspecionar o `recommendation` (texto livre) para entender qual estratégia aplicar. Agora, `DriftItem.strategyUsed` e `DriftItem.autoCorrectPossible` são campos tipados — consumíveis programaticamente.

### Clareza sobre limitações da API

O ViewProvider e IterationProvider declaram explicitamente `strategyUsed: 'manual-intervention'` e `autoCorrectPossible: false`. Isso formaliza o que antes era apenas um comentário em `ensureView()`:
```
// GitHub Projects API does not expose createProjectV2View
```

Agora essa limitação é um dado estrutural do sistema, não apenas documentação.

### Ponto único de extensão

Para adicionar suporte a Views quando a API do GitHub eventualmente disponibilizar `createProjectV2View`:
1. Atualizar `ViewProvider.meta.strategyUsed` para `'graphql'`
2. Atualizar `ViewProvider.meta.autoCorrectPossible` para `true`
3. Implementar a chamada GraphQL em `github/project.ts`
4. Nenhum outro arquivo precisa ser alterado

---

## 7. Conformidade com restrições

| Restrição | Status |
|---|---|
| NÃO implementar Delivery, Diligence, Timeline Processor, Datadog, Runtime Events | ✅ Nenhum desses componentes alterado |
| NÃO alterar OEM, SDK, Event Catalogs, Discovery, Release, Iteration Plan | ✅ Confirmado |
| NÃO criar Runtime paralelo | ✅ `github/` inalterado; Providers são wrappers sem lógica duplicada |
| NÃO duplicar código | ✅ Providers delegam para `github/` — sem cópia de lógica |
| Typecheck Exit 0 | ✅ `npm run typecheck` passa |

---

## 8. Próximos passos para retomar o Piloto

O Piloto Operacional (IP-001) pode continuar após esta refatoração. Nenhum artefato de Discovery, Release, Iteration Plan ou GitHub Project foi alterado.

### Entry Gate da Release (checklist)

Antes de iniciar F-01 (Invoice PIX), verificar:

- [ ] `npm run typecheck` em `runtime/workspace` — ✅ Exit 0 (verificado neste refactoring)
- [ ] `npm test` em `runtime/producer/` — 37 testes
- [ ] `npm test` em `runtime/state-engine/` — 98 testes
- [ ] `workspace doctor` — confirmar que o GitHub Project #24 está consistente
- [ ] GitHub Project #24 — verificar que os 6 Issues (#76–#81) aparecem na Iteration Backlog
- [ ] Views pendentes — criar as 13 Views manualmente via UI (conforme `documentation-review-pilot-project-materialization.md`)

### Sequência do Piloto

1. Entry Gate satisfeito → iniciar F-01 (PI-PILOT-001 — Invoice PIX)
2. Emitir `Delivery.Bootstrap.Started` via RT-01
3. Seguir `iteration-plan-pilot.md`: F-01 → F-02 → ... → F-06

---

## 9. Rastreabilidade

| Artefato | Localização |
|---|---|
| WorkspaceManagementCapability | `runtime/workspace/src/capability.ts` |
| Providers | `runtime/workspace/src/providers/` |
| DriftItem evoluído | `runtime/workspace/src/types.ts` |
| Doctor atualizado | `runtime/workspace/src/doctor.ts` |
| Provisioner atualizado | `runtime/workspace/src/provisioner.ts` |
| README atualizado | `runtime/workspace/README.md` |
| Iteration Plan | `prodops/artifacts/plans/iteration-plan-pilot.md` |
| GitHub Project #24 | https://github.com/orgs/produtoreativo/projects/24 |
| doc-review anterior (Project Materialization) | `prodops/documentation-review-pilot-project-materialization.md` |
