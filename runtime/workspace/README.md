# Workspace Management Capability

Materializa e reconcilia a Canonical Operational Representation (COR) do ProdOps Runtime no GitHub Projects.

> Faz parte do módulo `runtime/workspace` — primeiro componente do ProdOps Runtime MVP (EXP-013).

---

## Arquitetura

```
src/
├── capability.ts           WorkspaceManagementCapability — ponto de entrada único
├── provisioner.ts          Orquestrador de 7 passos (usa Capability)
├── doctor.ts               Detector de drifts (usa Capability; produz DriftItem enriquecido)
├── cli.ts                  CLI: workspace provision | doctor
├── types.ts                Tipos canônicos (WorkspaceConfig, DoctorReport, DriftItem, ProviderStrategy)
├── providers/
│   ├── strategy.ts         ProviderMeta — interface de metadados de estratégia
│   ├── project.provider.ts  ProjectProvider   (gh-cli + graphql)
│   ├── field.provider.ts    FieldProvider     (gh-cli)
│   ├── view.provider.ts     ViewProvider      (manual-intervention — limitação da API)
│   ├── label.provider.ts    LabelProvider     (gh-cli + rest)
│   ├── milestone.provider.ts MilestoneProvider (rest)
│   ├── iteration.provider.ts IterationProvider (manual-intervention — limitação da API)
│   └── membership.provider.ts MembershipProvider (gh-cli + graphql)
└── github/
    ├── client.ts           gh / ghJson / ghGraphql — adaptadores de baixo nível
    ├── project.ts          Operações de Project, Field, View (gh CLI + GraphQL)
    ├── labels.ts           Operações de Label
    ├── issues.ts           Operações de Issue
    └── milestone.ts        Operações de Milestone
```

### Hierarquia de responsabilidades

```
WorkspaceManagementCapability  ← ponto de entrada (capability.ts)
    └── Providers              ← seleção de estratégia (src/providers/)
            └── github/        ← adaptadores GitHub (src/github/)
```

**Regra de dependência:** Journeys (Delivery, Diligence) nunca importam de `runtime/workspace`. Esta Capability materializa o COR; não origina estado.

---

## Providers e estratégias

Cada Provider declara a estratégia que usa e se o drift pode ser corrigido automaticamente:

| Provider | Estratégia primária | Alternativa | Auto-correct |
|---|---|---|---|
| ProjectProvider | gh-cli | graphql | sim |
| FieldProvider | gh-cli | — | sim |
| ViewProvider | manual-intervention | graphql (list only) | **não** |
| LabelProvider | gh-cli | rest | sim |
| MilestoneProvider | rest | gh-cli | sim |
| IterationProvider | manual-intervention | — | **não** |
| MembershipProvider | gh-cli | graphql | sim |

**Hierarquia de estratégias (ordem de preferência):**
```
graphql → rest → gh-cli → browser-automation → manual-intervention
```

O consumidor (Doctor, Provisioner) não precisa conhecer qual estratégia foi usada — o Provider expõe essa informação através de `.meta`.

---

## Invariante: GitHub Project = COR

> **O GitHub Project é representação operacional canônica — nunca fonte de verdade.**

- O estado real reside na Operational Timeline (Event Instances imutáveis).
- O GitHub Project projeta o Derived State calculado pelo RT-02.
- Atualizar um Custom Field no GitHub não cria eventos na Timeline.
- Esta Capability materializa e reconcilia a COR; não tem autoridade sobre estado.

Se o campo `State` no GitHub diz HACKING mas RT-02 calcula BLOCKED: **RT-02 está correto**. O GitHub Project está com drift — use `workspace doctor`.

---

## Pré-requisitos

- Node.js >= 20
- `gh` CLI autenticado (`gh auth status`)
- Permissões: `project:write`, `repo:write` no repositório `payments-api`

---

## Instalação

```bash
cd runtime/workspace
npm install
```

---

## Configuração

Edite `workspace.yaml` e preencha `metadata.owner`:

```yaml
metadata:
  owner: "minha-org"        # GitHub org ou usuário
  repository: "payments-api"
  iteration: "IP-RUNTIME-001"
  release: "v0.1.0-runtime-pilot"
  obc: "EXP-013"
```

---

## Uso

### Provisionar o Workspace

```bash
npm run provision
```

Executa os 7 passos via `WorkspaceManagementCapability`:

1. **ProjectProvider** — cria ou verifica o GitHub Project
2. **MilestoneProvider** — cria ou verifica a Milestone
3. **FieldProvider** — cria os Custom Fields declarados
4. **LabelProvider** — cria as Labels no repositório
5. **ViewProvider** — verifica Views (criação manual para missing — ver Limitações)
6. **MembershipProvider** — cria Issues e adiciona ao Project
7. Sumário do estado final

**Idempotente:** executar duas vezes produz o mesmo estado. Recursos existentes são pulados.

### Verificar consistência (Doctor)

```bash
npm run doctor
```

Compara `workspace.yaml` com o estado real no GitHub. O relatório inclui, por drift:

- Severidade: `missing` ❌ · `divergent` ⚠️ · `extra` ℹ️
- Provider responsável (ex: `FieldProvider`)
- Estratégia de correção (ex: `gh-cli`)
- Estratégia alternativa (ex: `graphql`) ou `—`
- Auto-correct: `yes` (workspace provision corrige) ou `no` (requer ação manual)

Retorna exit code `0` se consistente, `1` se há drifts bloqueantes.

### Config alternativo

```bash
node dist/cli.js provision --config /path/to/outro-workspace.yaml
node dist/cli.js doctor    --config /path/to/outro-workspace.yaml
```

---

## Estrutura do workspace.yaml

```yaml
metadata:
  owner: string          # GitHub org ou usuário
  repository: string     # nome do repositório
  iteration: string      # identificador da Iteration (ex: IP-RUNTIME-001)
  release: string        # versão da Release (ex: v0.1.0-runtime-pilot)
  obc: string            # identificador do OBC ou Experimento

project:
  title: string          # nome do GitHub Project
  description: string    # descrição curta

milestone:
  title: string          # título da Milestone
  description: string    # descrição

fields:                  # lista de Custom Fields
  - name: string
    type: TEXT | NUMBER | DATE | SINGLE_SELECT
    options: [string]    # somente para SINGLE_SELECT
    required: boolean
    updatedBy: manual | runtime | both

labels:                  # lista de Labels do repositório
  - name: string
    color: string        # hex sem #
    description: string
    category: string     # agrupamento informacional

views:                   # lista de Views do Project
  - name: string
    layout: TABLE | BOARD
    description: string
    groupBy: string      # nome do campo (informacional — groupBy requer config manual no UI)

issues:                  # Work Items iniciais do backlog
  - title: string
    body: string
    labels: [string]
    type: Feature | Runtime Task | Finding
    feature: string      # valor de witem:feature
    initialFields:       # campos TEXT a serem preenchidos na criação
      fieldName: value
```

---

## Limitações conhecidas

### Views — sem API de criação

A mutação `createProjectV2View` **não existe** na API pública do GitHub Projects v2. Confirmado:
```
{"errors":[{"message":"Field 'createProjectV2View' doesn't exist on type 'Mutation'"}]}
```

O ViewProvider declara `strategyUsed: 'manual-intervention'`. O Doctor reporta views faltantes com `auto-correct: no` e instrução de criação manual via UI.

### SINGLE_SELECT field values

O GitHub Projects v2 usa option IDs internos para campos Single Select. O Provisioner cria os campos com as opções declaradas, mas não pode definir valores de SINGLE_SELECT em Issues automaticamente sem conhecer os option IDs gerados. Use `workspace doctor` para identificar divergências.

### Iterations — sem API de criação

O GitHub Projects v2 não expõe API para criação de Iteration cycles. O IterationProvider declara `strategyUsed: 'manual-intervention'`. Iterações devem ser criadas via UI no GitHub.

### Rate limiting

Para workspaces com muitas Issues, o provisioner pode atingir rate limits. Re-execute `workspace provision` — a idempotência garante que apenas itens faltantes serão criados.

---

## Reutilização em outros produtos

Para usar em outro produto além do payments-api:

1. Copie `workspace.yaml` para o diretório do novo produto
2. Atualize `metadata.owner`, `metadata.repository`, `metadata.iteration`, e `metadata.release`
3. Ajuste a lista de `issues` para os Work Items do novo backlog
4. Execute `workspace provision --config /path/to/novo-workspace.yaml`

---

## Desenvolvimento

```bash
# Verificar tipos
npm run typecheck

# Compilar para dist/
npm run build

# Executar com tsx (sem compilar)
npx tsx src/cli.ts provision
npx tsx src/cli.ts doctor
```
