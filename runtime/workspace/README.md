# Workspace Provisioner

Materializa automaticamente a Canonical Operational Representation (COR) do ProdOps Runtime no GitHub Projects.

> Faz parte do módulo `runtime/workspace` — primeiro componente do ProdOps Runtime MVP (EXP-013).

---

## Responsabilidade

O Workspace Provisioner lê `workspace.yaml` e garante que o GitHub Project `ProdOps — payments-api` esteja completamente provisionado:

- Project criado
- Milestone criada
- 18 Custom Fields criados
- 25 Labels criadas no repositório
- 7 Views configuradas
- Issues do Product Backlog criadas e adicionadas ao Project
- Campos de identidade preenchidos em cada Issue

O Workspace Doctor compara o estado declarado em `workspace.yaml` com o estado real no GitHub e produz um relatório de drifts com comandos de reparo.

**O GitHub Project é superfície de visualização — não fonte de verdade.** A Operational Timeline em `evidence/timelines/` é a fonte de verdade.

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

Todos os demais valores (fields, labels, views, issues) estão pré-configurados com a COR do piloto.

---

## Uso

### Provisionar o Workspace

```bash
npm run provision
```

Executa os 7 passos:

1. Cria (ou verifica) o GitHub Project
2. Cria (ou verifica) a Milestone
3. Cria os 18 Custom Fields
4. Cria as 25 Labels no repositório
5. Cria as 7 Views
6. Cria as Issues do backlog e adiciona ao Project
7. Preenche campos de identidade (TEXT) nas Issues

**Idempotente:** executar duas vezes produz o mesmo estado. Recursos existentes são pulados.

### Verificar consistência (Doctor)

```bash
npm run doctor
```

Compara `workspace.yaml` com o estado real no GitHub e produz:

- Recursos ausentes (❌ missing)
- Divergências em campos ou labels (⚠️ divergent)
- Recursos extras não declarados no config (ℹ️ extra)
- Recomendação de reparo para cada drift

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

### SINGLE_SELECT field values

O GitHub Projects v2 usa option IDs (strings como `f75ad8...`) para campos Single Select — não os valores textuais. O `gh project item-edit --single-select-option-id` requer o ID da opção, que só é determinável após criar o campo via `gh project field-list --format json`.

**Workaround:** após `workspace provision`, configure os valores iniciais de `oem:state`, `diligence:evidence`, `runtime:sync` e `runtime:timeline-state` manualmente no GitHub UI, ou use `workspace doctor` para identificar divergências e os comandos de reparo correspondentes.

### View filters e groupBy

O GitHub Projects v2 API (GraphQL) suporta criação de Views com `layout` (TABLE ou BOARD), mas configuração de filtros, groupBy, e colunas de visualização requer interação via interface do GitHub ou mutations GraphQL específicas por campo. O provisioner cria as Views com o layout correto; os filtros e agrupamentos devem ser configurados manualmente no GitHub UI seguindo a especificação em `runtime-validation-cor.md`.

### Rate limiting

Para workspaces com muitas Issues, o provisioner pode atingir rate limits da API do GitHub. Se isso ocorrer, re-execute `workspace provision` — a idempotência garante que apenas os itens faltantes serão criados.

---

## Reutilização em outros produtos

Para usar o Workspace Provisioner em outro produto além do payments-api:

1. Copie `workspace.yaml` para o diretório do novo produto
2. Atualize `metadata.owner`, `metadata.repository`, `metadata.iteration`, e `metadata.release`
3. Ajuste a lista de `issues` para os Work Items do novo backlog
4. Execute `workspace provision --config /path/to/novo-workspace.yaml`

Os campos, labels, e views são definidos genericamente — funcionam para qualquer produto que siga a COR do ProdOps Framework.

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
