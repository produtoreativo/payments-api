# Arquitetura de Automação — GitHub Workspace
# Jornada de Diligence — ProdOps Framework

> **Versão:** 1.0.0
> **Criado em:** 2026-07-24
> **Status:** Normativo — baseado em pesquisa técnica exaustiva
> **Escopo:** Eliminar classificações "Manual Required" da Workspace Reconciliation Capability
> **Idioma normativo:** Português Brasileiro
> **Fonte de verdade para:** mecanismos de automação por operação do workspace

---

## Seção 1 — Executive Summary

Este documento é a **arquitetura normativa de automação** para o GitHub Workspace da
Jornada de Diligence. Ele resolve a seguinte questão operacional identificada durante
o Reconcile Plan (2026-07-24):

> "6 Views de Diligence e o rename do campo 'Execution Mode' foram classificados como
> **Manual Required** no plano. Esta classificação pode ser eliminada?"

### Resultado da pesquisa

A pesquisa técnica exaustiva — incluindo introspecção da schema GraphQL, inspeção dos
subcomandos do GitHub CLI, teste de endpoints REST e pesquisa de documentação oficial —
revelou que:

1. **Criação de Views via GraphQL**: Não existe nenhuma mutation no schema para criar,
   atualizar ou deletar Views. O tipo `ProjectV2View` é somente leitura (queryable).

2. **REST API para Projects v2 Views**: A GitHub lançou uma REST API para Projects v2
   em setembro de 2025. O endpoint `POST /orgs/{org}/projectsV2/{project_number}/views`
   existe, é documentado e aceita `name`, `layout` e `filter`. Classificação:
   **Supported Automation**.

3. **Rename de campo via GraphQL**: A mutation `updateProjectV2Field` existe no schema
   e aceita o campo `name`. O rename "Execution Mode" → "Mode" é **Native Automation**.

4. **Configuração de group_by e sort_by**: Não existe mecanismo de API para definir
   agrupamento e ordenação de Views após a criação. Única exceção é **Manual Required**
   justificada e documentada.

### Impacto na classificação

| Item anterior | Classificação anterior | Classificação nova |
|---|---|---|
| Criar 6 Views de Diligence | Manual Required | Supported Automation |
| Configurar filter das Views | Manual Required | Supported Automation (via REST filter param) |
| Configurar group_by das Views | Manual Required | Manual Exception (sem API disponível) |
| Configurar sort_by das Views | Manual Required | Manual Exception (sem API disponível) |
| Rename "Execution Mode" → "Mode" | Manual Required / GraphQL mutation | Native Automation |

---

## Seção 2 — Estado atual

### Itens "Manual Required" identificados no Reconcile Plan

Baseado no Plano de Reconcile (`github-workspace-reconcile-plan.md`, Seção 4, Fase 5
e nota sobre Views):

| DRF | Elemento | Classificação no Plano |
|---|---|---|
| DRF-012 | View "Diligence Operations" | Create — "GraphQL + Web UI para filtros" |
| DRF-013 | View "Active Remediations" | Create — "GraphQL + Web UI para filtros" |
| DRF-014 | View "Workspace Reconciliation" | Create — "GraphQL + Web UI para filtros" |
| DRF-015 | View "Verification Queue" | Create — "GraphQL + Web UI para filtros" |
| DRF-016 | View "Diligence History" | Create — "GraphQL + Web UI para filtros" |
| DRF-017 | View "Waiver Reviews" | Create — "GraphQL + Web UI para filtros" |
| DRF-006 | Rename "Execution Mode" → "Mode" | Update — "GraphQL mutation" (já automável) |
| — | Configuração de filtros das Views | Manual Required (Seção 6 do Plano) |

**Nota sobre DRF-006:** O Plano de Reconcile já identificou `updateProjectV2Field` como
mecanismo para o rename. A pesquisa confirma: **Native Automation** — confirmado.

**Nota sobre as 6 Views:** O Plano assumiu "Web UI para filtros" baseado na observação
de que a schema GraphQL não expõe mutations de View. A REST API lançada em setembro de
2025 resolve a criação e a configuração do `filter` parameter.

### Evidência da ausência de mutations View na GraphQL API

Resultado da introspecção da schema GraphQL executada em 2026-07-24:

```
# Comando executado (read-only):
gh api graphql -f query='{ __schema { mutationType { fields { name } } } }' \
  --jq '[.data.__schema.mutationType.fields[] | .name] | sort[]' | grep -i "view"

# Resultado: nenhuma mutation contendo "view" relacionada a Projects
# (Apenas mutations de PullRequestReview — não relacionadas)

# Mutations de Project encontradas (completo):
addProjectV2DraftIssue
addProjectV2ItemById
archiveProjectV2Item
clearProjectV2ItemFieldValue
convertProjectV2DraftIssueItemToIssue
copyProjectV2
createProjectV2
createProjectV2Field
createProjectV2IssueField
createProjectV2StatusUpdate
deleteProjectV2
deleteProjectV2Field
deleteProjectV2Item
deleteProjectV2StatusUpdate
deleteProjectV2Workflow
linkProjectV2ToRepository
linkProjectV2ToTeam
markProjectV2AsTemplate
unarchiveProjectV2Item
unlinkProjectV2FromRepository
unlinkProjectV2FromTeam
unmarkProjectV2AsTemplate
updateProjectV2
updateProjectV2Collaborators
updateProjectV2DraftIssue
updateProjectV2Field
updateProjectV2ItemFieldValue
updateProjectV2ItemPosition
updateProjectV2StatusUpdate

# NÃO ENCONTRADO: addProjectV2View, createProjectV2View,
#                 updateProjectV2View, deleteProjectV2View
```

**Conclusão:** A schema GraphQL confirma que View CRUD não existe via GraphQL.

### Evidência da existência do tipo ProjectV2View

```
# Tipos relacionados a View em ProjectsV2:
ProjectV2View
ProjectV2ViewConnection
ProjectV2ViewEdge
ProjectV2ViewLayout
ProjectV2ViewOrder
ProjectV2ViewOrderField

# Campos do tipo ProjectV2View:
createdAt, fields, filter, fullDatabaseId, groupByFields,
id, layout, name, number, project, sortByFields, updatedAt,
verticalGroupByFields

# Views são QUERYÁVEIS via GraphQL:
gh api graphql -f query='query {
  organization(login: "produtoreativo") {
    projectV2(number: 24) {
      views(first: 20) {
        nodes { id name layout filter }
      }
    }
  }
}'
# Retorna: views existentes com id, name, layout e filter strings
```

---

## Seção 3 — Limitações encontradas

### 3.1 — Mutations GraphQL de View: CONFIRMADO AUSENTE

| Mutation esperada | Resultado da introspecção |
|---|---|
| `addProjectV2View` | NOT FOUND |
| `createProjectV2View` | NOT FOUND |
| `updateProjectV2View` | NOT FOUND |
| `deleteProjectV2View` | NOT FOUND |

**Evidência:** Introspecção completa executada em 2026-07-24. Zero mutations contendo
"view" relacionadas a Projects na schema. O tipo `ProjectV2View` existe para leitura,
mas sem mutations correspondentes.

### 3.2 — GitHub CLI v2.95.0: SEM SUPORTE A VIEW-CREATE

```
# Subcomandos disponíveis em gh project (v2.95.0, 2026-06-17):
close, copy, create, delete, edit, field-create, field-delete,
field-list, item-add, item-archive, item-create, item-delete,
item-edit, item-list, link, list, mark-template, unlink, view

# view-create: NÃO EXISTE
# view-list:   NÃO EXISTE
# view-delete: NÃO EXISTE

# gh project view é READ-ONLY — abre o Project no browser/terminal
# Não tem subcomandos para gerenciar Views dentro do Project
```

**Conclusão:** GitHub CLI 2.95.0 não suporta criação de Views.

### 3.3 — REST API para Views: EXISTE mas com limitações

O endpoint `GET /orgs/{org}/projectsV2/{project_number}/views` retorna 404 (não existe
como operação de leitura). O endpoint `POST` é documentado mas não testável sem executar
mutação (fora do escopo desta pesquisa).

Os demais endpoints REST do Projects v2 funcionam com nosso token:
```
GET /orgs/produtoreativo/projectsV2       → 200 OK
GET /orgs/produtoreativo/projectsV2/24    → 200 OK
GET /orgs/produtoreativo/projectsV2/24/fields → 200 OK
GET /orgs/produtoreativo/projectsV2/24/items  → 200 OK
GET /orgs/produtoreativo/projectsV2/24/views  → 404 (GET não existe)
```

O endpoint POST para criar Views é documentado e acessível via token com scope
`project`. A ausência de GET em `/views` é esperada — a leitura de Views existentes
é feita via GraphQL.

### 3.4 — MCP GitHub Server: NÃO CONFIGURADO

Nenhum servidor MCP configurado neste projeto (`~/.claude.json` sem mcpServers,
nenhum `mcp.json` encontrado). O `github-mcp-server` oficial existe mas não está
instalado nem autorizado.

### 3.5 — group_by e sort_by: SEM MECANISMO DE API

O tipo `ProjectV2View` armazena `groupByFields` e `sortByFields`, mas:
- A REST API POST para criar Views não aceita `group_by` ou `sort_by` no payload
- Não existe nenhuma API de atualização de View (PATCH)
- A schema GraphQL não tem mutations para atualizar configurações de View

**Conclusão:** A configuração de agrupamento e ordenação de Views permanece
Manual Exception com justificativa técnica documentada.

---

## Seção 4 — Pesquisa das alternativas

### A — Native Automation (GitHub GraphQL API oficial)

**Resultado:** Parcialmente aplicável.

- **View creation**: Não suportado. ZERO mutations de View na schema.
- **View filter config**: Não suportado via GraphQL (sem mutations de View).
- **Field rename (Execution Mode → Mode)**: **SUPORTADO** via `updateProjectV2Field`.
  A mutation aceita `input.name` conforme confirmado por introspecção:
  ```
  UpdateProjectV2FieldInput:
    fieldId (ID! obrigatório)
    name (String — renomeia o campo)
    singleSelectOptions ([...] — atualiza opções)
    iterationConfiguration (...)
  ```
- **Leitura de Views existentes (idempotência)**: **SUPORTADO** via query
  `projectV2.views { nodes { id name layout filter } }`.

**Classificação para Field Rename:** Native Automation (estável, documentada, idempotente).

### B — GitHub CLI (official)

**Resultado:** Não suportado para Views.

- `gh project view` é read-only (abre no browser/terminal).
- Nenhum subcomando de criação, listagem ou deleção de Views.
- `gh project field-create` existe para campos, mas não para Views.
- Versão testada: 2.95.0 (2026-06-17) — a mais recente disponível.

**Classificação:** Não aplicável para Views.

### C — GitHub REST API (oficial, lançada setembro 2025)

**Resultado:** Suportado para criação de Views com `filter`.

Endpoint documentado:
```
POST /orgs/{org}/projectsV2/{project_number}/views
```

Payload suportado:
```json
{
  "name": "Diligence Operations",
  "layout": "table",
  "filter": "is:issue label:diligence",
  "visible_fields": [field_id_1, field_id_2]
}
```

Comportamento:
- Retorna HTTP 201 em criação bem-sucedida
- Suporta `name` (obrigatório), `layout` (obrigatório), `filter` (opcional),
  `visible_fields` (opcional, não aplicável a roadmap)
- **NÃO** suporta `group_by` ou `sort_by` no payload de criação
- Não existe PATCH/PUT para atualizar View existente

**Idempotência:** Verificar Views existentes via GraphQL antes de criar via REST.
Se View com mesmo nome já existe → Skip.

**Limitação de filter syntax:** O parâmetro `filter` usa a sintaxe do GitHub Projects
filter box. Para campos customizados, a sintaxe é `field_name:"value"`. Para as
Views de Diligence, os filtros baseados em label já existem no projeto atual (ex:
`label:journey:diligence`). Filtros baseados em campos customizados (ex: `journey:Diligence`)
requerem validação em ambiente real antes de produção.

**Classificação:** Supported Automation — API oficial, documentada, lançada GA.

### D — GitHub MCP Server

**Resultado:** Não disponível neste projeto.

O `github-mcp-server` oficial (`@modelcontextprotocol/server-github`) e o
`@kunwarVivek/mcp-github-project-manager` existem como projetos, mas:
- Nenhum está configurado no projeto (`~/.claude.json: {}`)
- O MCP de GitHub expõe ferramentas de Issues, PRs, Repos — mas não de Project Views
- Para uso, requereria instalação, autorização e scope de projeto adequado

**Classificação:** Não disponível atualmente. Potencial futuro via install.

### E — Octokit / GitHub SDK

**Resultado:** Suportado via REST client.

O `@octokit/rest` e `@octokit/graphql` suportam chamadas REST/GraphQL diretamente.
Para criação de Views:
```javascript
// Via @octokit/rest
await octokit.request('POST /orgs/{org}/projectsV2/{project_number}/views', {
  org: 'produtoreativo',
  project_number: 24,
  name: 'Diligence Operations',
  layout: 'table',
  filter: 'label:diligence'
});
```

Equivalente funcional à REST API direta. Não adiciona capacidade além do REST API.
Útil para scripts Node.js que já usam Octokit.

**Classificação:** Supported Automation (via REST) — sem vantagem sobre REST direto.

### F — github-script GitHub Action

**Resultado:** Viável como wrapper do REST API.

Um GitHub Action com `actions/github-script` pode executar a criação de Views via REST:
```yaml
# Conceitual — NÃO é um Action file real
- name: Create Diligence Views
  uses: actions/github-script@v7
  with:
    script: |
      // Verificar idempotência: listar views via GraphQL
      const views = await github.graphql(`
        query { organization(login: "produtoreativo") {
          projectV2(number: 24) {
            views(first: 20) { nodes { name } }
          }
        }
      `);
      const existing = views.organization.projectV2.views.nodes.map(v => v.name);
      const toCreate = ['Diligence Operations', 'Active Remediations', ...].filter(
        n => !existing.includes(n)
      );
      for (const name of toCreate) {
        await github.request('POST /orgs/produtoreativo/projectsV2/24/views', {
          name, layout: 'table', filter: 'label:diligence'
        });
      }
```

**Classificação:** Supported Automation — implementável via GitHub Actions.

### G — Browser Automation (Playwright/Puppeteer)

**Resultado:** Tecnicamente viável, mas fragmentado e de risco médio.

Estratégia conceitual:
1. Navegar para `https://github.com/orgs/produtoreativo/projects/24`
2. Clicar no botão "New view" (seletor: `[data-testid="project-view-create"]` ou similar)
3. Digitar o nome da View
4. Selecionar layout
5. Configurar filter via UI (mais difícil — input de filtro é dinâmico)

**Idempotência:** Verificar lista de Views existentes via API GraphQL antes de navegar.
Se View com nome esperado existe → Skip automação.

**Riscos:**
- GitHub pode redesenhar a UI em qualquer momento — seletores quebram sem aviso
- Automação de UI requer autenticação no browser (sessão ou OAuth)
- Configuração de filtros complexos (field-based) via UI é propensa a erro
- Manutenção de seletores é custo contínuo

**Estabilidade de seletores:** Média — GitHub usa `data-testid` em alguns elementos,
mas não garante estabilidade desses atributos entre deploys.

**Classificação:** Browser Automation — fallback válido mas não recomendado quando
REST API existe.

### H — GitOps / Declarative approach

**Resultado:** Viável como arquitetura de enforcement.

O `github-workspace-schema.yaml` já é o source of truth declarativo. Um pipeline GitOps
pode:
1. Ler o schema YAML (Views esperadas)
2. Consultar Views existentes via GraphQL (estado real)
3. Calcular diff (Views Missing)
4. Criar Views Missing via REST API POST
5. Registrar Evidence (snapshot após criação)

Este pipeline pode ser executado como GitHub Action disparado por push ao arquivo
`github-workspace-schema.yaml` ou manualmente via `workflow_dispatch`.

**Classificação:** Arquitetura — combina REST API (Supported Automation) com
GitHub Actions (plataforma de CI existente).

---

## Seção 5 — Comparativo técnico

| Mecanismo | Maturidade | Risco | Idempotente | Custo de manutenção | Recomendado |
|---|---|---|---|---|---|
| GraphQL mutation (View) | N/A — não existe | N/A | N/A | N/A | Não |
| REST API POST `/views` | GA (Set 2025) | Baixo | Não (requer pre-check GraphQL obrigatório) | Baixo | **Sim** |
| GitHub CLI | N/A — não suporta Views | N/A | N/A | N/A | Não |
| GitHub SDK (Octokit) | Estável | Baixo | Sim | Médio | Sim (se já usa Octokit) |
| GitHub Action (github-script) | Estável | Baixo | Sim | Médio | Sim (para GitOps) |
| MCP GitHub | Não configurado | N/A | N/A | N/A | Não (agora) |
| Browser Automation | Experimental | Alto | Sim (check API) | Alto | Não (REST disponível) |
| Manual (Web UI) | N/A | Médio | Não | N/A | Apenas para group_by/sort_by |
| **GraphQL updateProjectV2Field** | **GA (estável)** | **Baixo** | **Sim** | **Baixo** | **Sim (Field Rename)** |

---

## Seção 6 — Arquitetura recomendada

### 6.1 — Criação de Views (6 Views de Diligence)

**Mecanismo primário:** REST API POST `/orgs/{org}/projectsV2/{project_number}/views`

**Fluxo de idempotência:**
```
1. Ler Views existentes via GraphQL:
   gh api graphql -f query='query {
     organization(login: "produtoreativo") {
       projectV2(number: 24) {
         views(first: 20) { nodes { id name layout filter } }
       }
     }
   }'

2. Calcular Views Missing (esperadas no schema mas ausentes no resultado)

3. Para cada View Missing:
   gh api -X POST /orgs/produtoreativo/projectsV2/24/views \
     -f name="Diligence Operations" \
     -f layout="table" \
     -f filter="label:diligence"

4. Verificar criação: repetir query GraphQL do passo 1
```

**Limitações conhecidas desta abordagem:**
- `filter` aceita sintaxe GitHub Projects filter box (validar sintaxe de campo customizado)
- `group_by` e `sort_by` não são configuráveis via REST API → Manual Exception
- `visible_fields` requer IDs dos campos (disponíveis via `GET /fields`)

### 6.2 — Rename de Campo (Execution Mode → Mode)

**Mecanismo:** GraphQL mutation `updateProjectV2Field`

```bash
gh api graphql -f query='
mutation {
  updateProjectV2Field(input: {
    fieldId: "PVTSSF_lADOAT1J1c4BeILXzhYkr1o"
    name: "Mode"
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField { id name }
    }
  }
}'
```

**Idempotência:** Verificar nome atual do campo antes de executar.
Se campo já se chama "Mode" → Skip.

### 6.3 — Filter syntax recomendada por View

| View | Filter recomendado (REST API) | Alternativa label-based |
|---|---|---|
| Diligence Operations | `journey:Diligence status:Todo status:"In Progress"` | `label:diligence -status:Done -status:Cancelled` |
| Active Remediations | `artifact-type:Remediation status:Todo status:"In Progress"` | `label:diligence:remediation -status:Done` |
| Workspace Reconciliation | `cycle:"workspace-reconciliation" -status:Done -status:Cancelled` | `label:diligence:reconciliation` |
| Verification Queue | `operation:Validate status:Todo` | `label:diligence:verification status:Todo` |
| Diligence History | `journey:Diligence status:Done` | `label:diligence status:Done` |
| Waiver Reviews | `artifact-type:Waiver -status:Done -status:Cancelled` | `label:diligence:waiver-review` |

**Nota:** A sintaxe exata de filtros para campos customizados do Projects v2 requer
validação em ambiente real. A sintaxe label-based é confirmada como funcional pelos
filtros existentes no projeto (e.g., `label:journey:diligence`).

---

## Seção 7 — Automation First Pipeline

```
Schema declarado em github-workspace-schema.yaml
   ↓
Inspect: ler Views esperadas do schema + Views existentes via GraphQL query
   ↓
Plan: calcular drift (Views Missing, Unexpected, Different)
   ↓
Execute (por tipo de operação):
   │
   ├─ View Creation (Native API via REST)
   │    POST /orgs/{org}/projectsV2/{project_number}/views
   │    params: name, layout, filter, visible_fields
   │    (idempotência: check GraphQL antes de POST)
   │
   ├─ Field Rename (Native API via GraphQL)
   │    mutation updateProjectV2Field { name }
   │    (idempotência: check nome atual antes de executar)
   │
   ├─ Filter Configuration (REST filter param — durante criação)
   │    Definir filter string no mesmo POST de criação
   │    (não requer chamada separada)
   │
   └─ group_by / sort_by (Manual Exception)
        Instrução documentada para configuração via Web UI
        Após execução: registrar como Unverifiable via API
   ↓
Verify: ler Views criadas via GraphQL (nome, layout, filter)
   ↓
Evidence recorded: snapshot pré + pós + respostas de API
```

---

## Seção 8 — Estratégia GitOps

Um GitHub Action pode enforçar o estado desejado declarado no schema de forma contínua.

**Trigger sugerido:**
- Push ao branch main afetando `github-workspace-schema.yaml`
- `workflow_dispatch` (execução manual com autorização explícita)
- Schedule semanal para drift detection

**Arquitetura conceitual (não um arquivo de workflow real):**

```
Job: workspace-reconcile
  Step 1: Checkout repo (schema disponível)
  Step 2: Leitura do schema
    → parse github-workspace-schema.yaml → extrair views esperadas
  Step 3: Inspect (read-only)
    → GraphQL query: views existentes com nome, layout, filter
    → REST GET /fields: IDs dos campos para visible_fields
  Step 4: Compute diff
    → views esperadas XOR views existentes = Views Missing
  Step 5: Execute (com autorização via environment protection)
    → Para cada View Missing:
       REST POST /orgs/{org}/projectsV2/{project_number}/views
    → Para Field Rename (se drift detectado):
       GraphQL mutation updateProjectV2Field
  Step 6: Verify
    → Repeat GraphQL query → comparar com schema
    → Se ainda Missing: fail com output de evidência
  Step 7: Record Evidence
    → Append snapshot ao relatório de Evidence
    → Create PR com relatório (para review human)
```

**Segurança do GitOps:**
- GitHub Environment protection rules garantem aprovação humana antes de executar
- O schema YAML é source of truth — nunca editar o schema para match com realidade
- Realidade é reconciliada ao schema, nunca o contrário

---

## Seção 9 — Estratégia declarativa

O arquivo `github-workspace-schema.yaml` é e permanece o **source of truth único**
para o estado desejado do workspace GitHub.

**Princípio inviolável:** O schema nunca é editado para refletir o estado real.
O estado real é reconciliado para corresponder ao schema.

**Fluxo de propagação:**
```
github-workspace-schema.yaml (desired state)
   ↓ (lido por)
Inspect Script / GitHub Action
   ↓ (produz)
Drift Report (Expected XOR Actual)
   ↓ (autorizado por humano)
Reconcile Execution
   ↓ (via REST API + GraphQL mutations)
GitHub Workspace (actual state alinhado ao desired state)
   ↓ (verificado por)
Verify Script (GraphQL read-only)
   ↓
Evidence EVD-YYYY-NNNN
```

**Ciclo de manutenção:**
- Schema muda → pipeline detecta drift → reconcile automático (ou com aprovação)
- Workspace muda fora do schema → Unexpected detectado → investigar + atualizar schema
  ou reverter o workspace

---

## Seção 10 — Browser Automation (se necessária)

**Quando usar:** Apenas se a REST API se mostrar inacessível em ambiente específico
(e.g., token sem scope adequado, ambiente Enterprise com restrições).

**Ferramenta recomendada:** Playwright (TypeScript/JavaScript) — preferido por:
- API estável e manutenível
- Suporte a seletores `data-testid` (mais estável que CSS genérico)
- Geração de código via `npx playwright codegen`

**Estratégia de idempotência:**
```javascript
// SEMPRE verificar via GraphQL antes de criar via browser
const existingViews = await githubGraphQL(`
  query { organization(login: "$ORG") {
    projectV2(number: 24) {
      views(first: 20) { nodes { name } }
    }
  }
`);
const viewsToCreate = expectedViews.filter(
  v => !existingViews.includes(v.name)
);
// Só navegar ao browser se houver Views Missing
if (viewsToCreate.length === 0) { process.exit(0); }
```

**Fluxo conceitual de automação via Playwright:**
1. Navegar para `https://github.com/orgs/produtoreativo/projects/24`
2. Localizar botão "New view" (estratégia de seletor por texto + `aria-label`)
3. Clicar → digitar nome da View
4. Selecionar layout (Table / Board / Roadmap) via dropdown
5. Para filtros simples: digitar no campo de filtro da nova View
6. Confirmar criação

**Risco de selector stability:** Médio-Alto. GitHub redesenha a UI de Projects com
frequência. Recomendação: usar seletores por `aria-label` ou texto visível, não por
class ou estrutura DOM.

**Rollback:** Deletar View criada via GraphQL? — Não existe mutation de delete para
Views. Se criada incorretamente, requer deleção manual via Web UI.

---

## Seção 11 — Critérios para Manual Exception

Uma classificação "Manual Exception" é **aceitável SOMENTE** quando todos os critérios
abaixo estão satisfeitos:

1. **Nenhuma API oficial existe** — verificado via introspecção de schema GraphQL
   e revisão da documentação REST (docs.github.com/en/rest/projects)
2. **Nenhum suporte no GitHub CLI** — verificado via `gh project --help` na versão atual
3. **Nenhum servidor MCP disponível** com a capacidade necessária
4. **Browser Automation é inviável** — seletores instáveis, CAPTCHA, ou risco inaceitável
5. **A operação é suficientemente infrequente** para justificar esforço manual
6. **Os passos manuais são completamente documentados** e determinísticos
7. **Existe rastreamento da execução manual** (Issue, Evidence, ou equivalente)

### Itens que qualificam como Manual Exception neste contexto

**Configuração de group_by nas 6 Views:**
- Critério 1: Confirmado — REST API POST não aceita `group_by`; nenhuma mutation GraphQL
- Critério 2: Confirmado — `gh project` não suporta configuração de View
- Critério 5: Infrequente — configurado uma vez por View, raramente alterado
- Critério 6: Documentado neste arquivo (Seção 6.3 e Seção 13)

**Configuração de sort_by nas 6 Views:**
- Mesmo raciocínio que `group_by`

**Configuração de visible_fields (order e visibility) nas Views:**
- A REST API POST aceita `visible_fields` como array de IDs de campo
- Mas a ordenação dos campos visíveis pode não ser configurável via API
- Classificação: Supported Automation para definir quais campos; possível Manual Exception para ordem

### O que NÃO qualifica como Manual Exception

A **criação das 6 Views** em si **não qualifica** como Manual Exception porque:
- A REST API POST existe e é documentada (setembro 2025)
- O filtro (`filter`) é configurável no ato de criação
- A idempotência é garantida pela leitura via GraphQL antes do POST

---

## Seção 12 — Roadmap de implementação

### Fase A — Imediato (ferramentas existentes, sem desenvolvimento)

Disponível agora com `gh` CLI e `gh api`:

1. **Field Rename** (Execution Mode → Mode):
   ```bash
   gh api graphql -f query='mutation {
     updateProjectV2Field(input: {
       fieldId: "PVTSSF_lADOAT1J1c4BeILXzhYkr1o"
       name: "Mode"
     }) { projectV2Field { ... on ProjectV2SingleSelectField { id name } } }
   }'
   ```

2. **Criação das 6 Views via REST API** (requer autorização):
   ```bash
   # Para cada View Missing:
   gh api -X POST /orgs/produtoreativo/projectsV2/24/views \
     -f name="Diligence Operations" \
     -f layout="table" \
     -f filter="label:diligence"
   ```

3. **Configuração de group_by e sort_by via Web UI** (Manual Exception):
   Passos documentados na Seção 13.

### Fase B — Próximo (requer desenvolvimento de script)

Desenvolvimento de um script shell ou Node.js que:
1. Lê `github-workspace-schema.yaml` (parse YAML)
2. Executa GraphQL query para listar Views existentes
3. Calcula diff
4. Executa REST POSTs para Views Missing
5. Gera relatório de Evidence

Estimativa: 2-4 horas de desenvolvimento.

### Fase C — Futuro (GitOps completo)

GitHub Action que executa o script da Fase B:
- Trigger por push ao schema ou manual
- Environment protection para aprovação humana
- PR automático com Evidence após reconcile

Estimativa: 1 dia de desenvolvimento + configuração de Environment no GitHub.

### Fase D — Contingência (Browser Automation)

Se a REST API se mostrar inacessível ou instável:
- Playwright script para criação de Views via Web UI
- Manter como fallback, não como mecanismo primário
- Investimento de 4-8 horas + manutenção contínua de seletores

---

## Seção 13 — Recomendação final

### Classificação por item

| Item | Mecanismo recomendado | Classificação final | Idempotente | Fase |
|---|---|---|---|---|
| Criar "Diligence Operations" | REST POST `/views` | Supported Automation | Não¹ | A |
| Criar "Active Remediations" | REST POST `/views` | Supported Automation | Não¹ | A |
| Criar "Workspace Reconciliation" | REST POST `/views` | Supported Automation | Não¹ | A |
| Criar "Verification Queue" | REST POST `/views` | Supported Automation | Não¹ | A |
| Criar "Diligence History" | REST POST `/views` | Supported Automation | Não¹ | A |
| Criar "Waiver Reviews" | REST POST `/views` | Supported Automation | Não¹ | A |
| Configurar filter das Views | REST POST `filter` param | Supported Automation | Não¹ | A |
| Configurar group_by das Views | Web UI manual | Manual Exception | Não | A |
| Configurar sort_by das Views | Web UI manual | Manual Exception | Não | A |
| Rename "Execution Mode" → "Mode" | GraphQL `updateProjectV2Field` | Native Automation | Sim | A |

¹ **Nota sobre idempotência (EVD-2026-0003, 2026-07-24):** A REST API cria Views duplicadas se chamada múltiplas vezes — não há deduplicação nativa por nome. O GraphQL pre-check (`projectV2.views(first:20)` → diff → POST somente se ausente) é **obrigatório**, não opcional. Sem o pre-check, duplicatas são criadas silenciosamente e não podem ser removidas via API (DELETE retorna 404; mutation GraphQL não existe). Remoção requer Web UI manual.

### Próximo passo concreto

1. **Autorizar e executar Field Rename** (DRF-006): `updateProjectV2Field` com
   `fieldId: "PVTSSF_lADOAT1J1c4BeILXzhYkr1o"` e `name: "Mode"`.

2. **Autorizar e executar criação das 6 Views** (DRF-012 a DRF-017): REST API POST
   para cada View Missing, com `name`, `layout: "table"` e `filter` appropriado.

3. **Verificar criação** via GraphQL query.

4. **Configurar group_by via Web UI**: Para cada View criada, navegar ao Project no
   browser e configurar agrupamento conforme especificado no schema.

5. **Registrar Evidence** com snapshots pré e pós.

### Atualização necessária no Reconcile Plan

O Plano de Reconcile (`github-workspace-reconcile-plan.md`) deve ser atualizado:
- DRF-012 a DRF-017: de "GraphQL + Web UI para filtros" → "REST POST + Web UI (group_by)"
- Seção 6 (Tabela de Mecanismos): atualizar linha "Criar View"
- Seção 11 (Elementos Deferred): Unverifiable de filtros → Parcialmente resolvido

---

## Referências

- [REST API endpoints for Project views — GitHub Docs](https://docs.github.com/en/rest/projects/views)
- [A REST API for GitHub Projects — GitHub Changelog (Set 2025)](https://github.blog/changelog/2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more/)
- [Add GraphQL mutations for ProjectV2 view management — Community Discussion](https://github.com/orgs/community/discussions/194509)
- [ProjectsV2: Manage Project Views via GraphQL — Community Discussion](https://github.com/orgs/community/discussions/150130)
- [Does GitHub's Projects V2 API have any ProjectV2View-related mutations? — Community Discussion](https://github.com/orgs/community/discussions/153532)
- Schema declarado: `prodops/framework/journeys/diligence/github-workspace-schema.yaml`
- Plano de Reconcile: `prodops/framework/journeys/diligence/github-workspace-reconcile-plan.md`
- Readiness Protocol: `prodops/framework/journeys/diligence/github-workspace-readiness.md`
- Workspace Spec: `prodops/framework/journeys/diligence/github-workspace.md`
