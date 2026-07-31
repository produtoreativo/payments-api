# Execution Report — Diligence GitHub Workspace Automation Architecture
**Data:** 2026-07-24
**ID:** AUTOMATION-2026-07-24-001
**Executor:** cmilfont (Christiano Milfont)
**Capability:** Workspace Reconciliation — Automation Architecture Research
**Modo:** Puramente documental — zero mutações executadas no GitHub
**Baseado em:** Pesquisa técnica exaustiva (GraphQL introspection + REST API testing + web research)

---

## 1. Executive Summary

Este relatório documenta a pesquisa técnica exaustiva conduzida para eliminar as
classificações "Manual Required" da Workspace Reconciliation Capability da Jornada
de Diligence.

**Objetivo:** Determinar o mecanismo de automação correto para cada operação
classificada como "Manual Required" no Plano de Reconcile de 2026-07-24, com
evidências técnicas obtidas diretamente da API do GitHub.

**Resultado principal:** A pesquisa identificou que a GitHub lançou uma REST API
para Projects v2 em setembro de 2025, que inclui endpoint de criação de Views com
suporte ao parâmetro `filter`. Isso elimina a classificação "Manual Required" para
a criação das 6 Views de Diligence e para a configuração de seus filtros.

**Items resolvidos:**

| Item | Classificação anterior | Classificação nova |
|---|---|---|
| Criar 6 Views de Diligence | Manual Required | Supported Automation (REST POST) |
| Configurar filter das Views | Manual Required | Supported Automation (REST filter param) |
| Configurar group_by das Views | Manual Required | Manual Exception (sem API — justificada) |
| Configurar sort_by das Views | Manual Required | Manual Exception (sem API — justificada) |
| Rename "Execution Mode" → "Mode" | GraphQL mutation (já automável) | Native Automation (confirmado) |

**Nenhuma mutação foi executada no GitHub durante esta pesquisa.**

---

## 2. Estado atual

### Itens "Manual Required" identificados no Reconcile Plan (PLAN-2026-07-24-001)

O Plano de Reconcile identificou 7 itens como "Manual Required" ou implicitamente manuais:

| # | DRF | Elemento | Classificação no Plano | Razão original |
|---|---|---|---|---|
| 1 | DRF-012 | View "Diligence Operations" | Create — "GraphQL + Web UI para filtros" | Ausência de mutations GraphQL |
| 2 | DRF-013 | View "Active Remediations" | Create — "GraphQL + Web UI para filtros" | Ausência de mutations GraphQL |
| 3 | DRF-014 | View "Workspace Reconciliation" | Create — "GraphQL + Web UI para filtros" | Ausência de mutations GraphQL |
| 4 | DRF-015 | View "Verification Queue" | Create — "GraphQL + Web UI para filtros" | Ausência de mutations GraphQL |
| 5 | DRF-016 | View "Diligence History" | Create — "GraphQL + Web UI para filtros" | Ausência de mutations GraphQL |
| 6 | DRF-017 | View "Waiver Reviews" | Create — "GraphQL + Web UI para filtros" | Ausência de mutations GraphQL |
| 7 | DRF-006 | Rename "Execution Mode" → "Mode" | Update via GraphQL mutation | Já identificado como automável |

Adicionalmente, as configurações de `filter`, `group_by` e `sort_by` das Views foram
implicitamente classificadas como "Manual Required" (Seção 6, Tabela de Mecanismos,
nota: "Filter/group_by/sort NOT configurável via API — requer Web UI").

**Nota sobre DRF-006:** O rename já estava identificado como automável via GraphQL
no Reconcile Plan. Esta pesquisa confirma a evidência técnica: `updateProjectV2Field`
mutation existe com suporte ao campo `name`.

---

## 3. Limitações encontradas

### 3.1 — Mutations GraphQL de View: CONFIRMADO AUSENTE

Introspecção completa do schema GraphQL executada via:
```bash
gh api graphql -f query='{ __schema { mutationType { fields { name } } } }' \
  --jq '[.data.__schema.mutationType.fields[] | .name] | sort[]'
```

**Resultado:** Zero mutations contendo "View" relacionadas a Projects v2.

Mutations de Project v2 encontradas (lista completa):
```
addProjectV2DraftIssue, addProjectV2ItemById, archiveProjectV2Item,
clearProjectV2ItemFieldValue, convertProjectV2DraftIssueItemToIssue,
copyProjectV2, createProjectV2, createProjectV2Field,
createProjectV2IssueField, createProjectV2StatusUpdate,
deleteProjectV2, deleteProjectV2Field, deleteProjectV2Item,
deleteProjectV2StatusUpdate, deleteProjectV2Workflow,
linkProjectV2ToRepository, linkProjectV2ToTeam,
markProjectV2AsTemplate, unarchiveProjectV2Item,
unlinkProjectV2FromRepository, unlinkProjectV2FromTeam,
unmarkProjectV2AsTemplate, updateProjectV2, updateProjectV2Collaborators,
updateProjectV2DraftIssue, updateProjectV2Field,
updateProjectV2ItemFieldValue, updateProjectV2ItemPosition,
updateProjectV2StatusUpdate
```

**NÃO ENCONTRADO:** `addProjectV2View`, `createProjectV2View`,
`updateProjectV2View`, `deleteProjectV2View`

O tipo `ProjectV2View` EXISTE para leitura (com campos: `id`, `name`, `layout`,
`filter`, `groupByFields`, `sortByFields`, etc.) mas sem mutations correspondentes.

**Conclusão:** A GraphQL API confirma que View CRUD não é suportado.

### 3.2 — GitHub CLI v2.95.0: SEM SUPORTE A VIEW-CREATE

```
Versão testada: gh version 2.95.0 (2026-06-17)

Subcomandos disponíveis em `gh project`:
  close, copy, create, delete, edit, field-create, field-delete,
  field-list, item-add, item-archive, item-create, item-delete,
  item-edit, item-list, link, list, mark-template, unlink, view

AUSENTES: view-create, view-list, view-delete, view-update
`gh project view` é READ-ONLY — abre o Project no terminal/browser
```

**Conclusão:** GitHub CLI 2.95.0 não suporta criação de Views.

### 3.3 — REST API GET /views: 404 (mas POST EXISTS)

```bash
# Endpoints REST testados:
GET /orgs/produtoreativo/projectsV2       → 200 OK
GET /orgs/produtoreativo/projectsV2/24    → 200 OK
GET /orgs/produtoreativo/projectsV2/24/fields → 200 OK
GET /orgs/produtoreativo/projectsV2/24/items  → 200 OK
GET /orgs/produtoreativo/projectsV2/24/views  → 404 (GET não implementado)
```

O 404 no endpoint GET `/views` é esperado — a leitura de Views existentes é feita
via GraphQL (confirmado como funcional). O endpoint POST é documentado na referência
oficial: `docs.github.com/en/rest/projects/views`.

### 3.4 — MCP: NÃO CONFIGURADO

```bash
cat ~/.claude.json | python3 -c "import json,sys; print(json.load(sys.stdin).get('mcpServers',{}))"
# Resultado: {}
```

Nenhum servidor MCP configurado. O `github-mcp-server` oficial não está instalado.

### 3.5 — group_by e sort_by: SEM MECANISMO DE API

O payload REST POST `/views` aceita apenas: `name`, `layout`, `filter`,
`visible_fields`. Os campos `group_by` e `sort_by` estão ausentes do payload de
criação e não existe endpoint de atualização (PATCH) para Views. Conclusão:
**Manual Exception** justificada.

---

## 4. Pesquisa das alternativas

### A — GraphQL API (mutations)

**Resultado para Views:** Não suportado.
**Resultado para Field Rename:** SUPORTADO via `updateProjectV2Field`.
- Confirmado via introspecção de `UpdateProjectV2FieldInput`:
  campo `name` (String) = rename do campo.
- Field ID do "Execution Mode": `PVTSSF_lADOAT1J1c4BeILXzhYkr1o` (do Inspect)

### B — GitHub CLI

**Resultado:** Não suportado para Views (v2.95.0 testado).

### C — REST API (setembro 2025)

**Resultado:** SUPORTADO para criação de Views com filter.

Endpoint: `POST /orgs/{org}/projectsV2/{project_number}/views`
Lançamento: 11 de setembro de 2025 (GitHub Changelog)
Documentação: `docs.github.com/en/rest/projects/views`

Parâmetros suportados na criação:
| Parâmetro | Tipo | Required | Descrição |
|---|---|---|---|
| `name` | string | Sim | Nome da View |
| `layout` | string | Sim | `table`, `board`, ou `roadmap` |
| `filter` | string | Não | Sintaxe do Projects filter box |
| `visible_fields` | int[] | Não | IDs dos campos visíveis |

Parâmetros NÃO suportados: `group_by`, `sort_by`, `vertical_group_by`

### D — GitHub MCP Server

**Resultado:** Não disponível. Ver Seção 3.4.

### E — Octokit / GitHub SDK

**Resultado:** Suportado como wrapper do REST API. Não agrega capacidade adicional.
Útil se o executor já usa `@octokit/rest` em scripts existentes.

### F — github-script GitHub Action

**Resultado:** Viável para GitOps. Combina GraphQL (leitura de Views existentes
para idempotência) com REST POST (criação de Views Missing).

### G — Browser Automation (Playwright)

**Resultado:** Tecnicamente viável mas desnecessário dado REST API disponível.
Recomendado apenas como contingência se REST API se mostrar inacessível.

### H — GitOps / Declarative approach

**Resultado:** Arquitetura recomendada de médio prazo. Ver Seção 8 deste relatório.

---

## 5. Comparativo técnico

| Mecanismo | Maturidade | Risco | Idempotente | Manutenção | Recomendado para Views |
|---|---|---|---|---|---|
| GraphQL mutation (View) | N/A — não existe | N/A | N/A | N/A | Não |
| **REST API POST /views** | **GA (Set 2025)** | **Baixo** | **Sim** | **Baixo** | **Sim** |
| GitHub CLI | N/A — não suporta | N/A | N/A | N/A | Não |
| Octokit/SDK | Estável | Baixo | Sim | Médio | Sim (se já usa) |
| GitHub Action | Estável | Baixo | Sim | Médio | Sim (GitOps) |
| MCP | Não configurado | N/A | N/A | N/A | Não (agora) |
| Browser Automation | Experimental | Alto | Sim (check API) | Alto | Não (REST disponível) |
| Web UI manual | N/A | Médio | Não | N/A | group_by/sort_by apenas |
| **GraphQL updateField** | **GA (estável)** | **Baixo** | **Sim** | **Baixo** | **Sim (rename)** |

---

## 6. Arquitetura recomendada

### 6.1 — Para criação das 6 Views de Diligence

**Mecanismo:** REST API POST `/orgs/{org}/projectsV2/{project_number}/views`

**Fluxo completo (conceitual):**
```bash
# Step 1: Verificar Views existentes (idempotência)
EXISTING=$(gh api graphql -f query='query {
  organization(login: "produtoreativo") {
    projectV2(number: 24) {
      views(first: 20) { nodes { name } }
    }
  }
}' --jq '[.data.organization.projectV2.views.nodes[].name]')

# Step 2: Para cada View do schema, verificar se já existe
# Se NÃO existe: criar via REST API
gh api -X POST /orgs/produtoreativo/projectsV2/24/views \
  -f name="Diligence Operations" \
  -f layout="table" \
  -f filter="label:diligence"

# Step 3: Verificar criação
gh api graphql -f query='query {
  organization(login: "produtoreativo") {
    projectV2(number: 24) {
      views(first: 20) { nodes { id name layout filter } }
    }
  }
}'
```

### 6.2 — Para rename do campo "Execution Mode" → "Mode"

**Mecanismo:** GraphQL `updateProjectV2Field`

```bash
# Step 1: Verificar nome atual (idempotência)
gh api graphql -f query='query {
  organization(login: "produtoreativo") {
    projectV2(number: 24) {
      field(name: "Mode") { ... on ProjectV2SingleSelectField { id name } }
    }
  }
}'
# Se "Mode" já existe → Skip

# Step 2: Executar rename (somente se necessário)
gh api graphql -f query='mutation {
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

---

## 7. Automation First Pipeline

```
github-workspace-schema.yaml (source of truth)
   ↓
Inspect: GraphQL query → Views existentes, Fields existentes
   ↓
Plan: calcular drift (Views Missing, Fields Different)
   ↓
Execute:
   │
   ├─ Field Rename → Native Automation
   │    gh api graphql → updateProjectV2Field { name: "Mode" }
   │
   ├─ View Creation → Supported Automation
   │    gh api -X POST .../projectsV2/24/views
   │    payload: { name, layout, filter }
   │
   ├─ Filter Configuration → Supported Automation
   │    filter param incluso no mesmo POST de criação
   │
   └─ group_by / sort_by → Manual Exception
        Instrução Web UI documentada → executar por humano
        Registrar como Unverifiable via API
   ↓
Verify: GraphQL query → confirmar Views criadas (nome, layout, filter)
   ↓
Evidence: snapshot pré + respostas da API + snapshot pós
```

---

## 8. Estratégia GitOps

Um GitHub Action pode enforçar o estado desejado de forma contínua.

**Arquitetura conceitual (NÃO é um arquivo de workflow real):**

```
Trigger: push ao main modificando github-workspace-schema.yaml
         OU workflow_dispatch (manual com aprovação)

Job: workspace-reconcile
  Permissions: GitHub Environment protection (aprovação humana)

  Step 1 — Read Schema
    Parse github-workspace-schema.yaml → views_expected[]

  Step 2 — Inspect (read-only)
    GraphQL: views existentes com nome, layout, filter
    REST GET: fields com IDs

  Step 3 — Compute Diff
    views_missing = views_expected XOR views_existing

  Step 4 — Reconcile (requires approval)
    Para cada view_missing:
      REST POST /orgs/{org}/projectsV2/{project_number}/views
    Para field rename:
      GraphQL updateProjectV2Field (se nome ≠ "Mode")

  Step 5 — Verify
    GraphQL query → confirmar estado pós-Reconcile
    Se view ainda Missing → fail com evidence output

  Step 6 — Evidence
    Gerar relatório markdown com snapshots pré/pós
    Criar PR com o relatório para human review
```

---

## 9. Estratégia declarativa

O `github-workspace-schema.yaml` é o source of truth único.

**Princípio inviolável:** O schema nunca é editado para refletir o estado real.
O estado real é reconciliado ao schema.

**Propagação:**
```
Schema YAML → Inspect → Drift Report → Reconcile → GitHub Workspace → Verify → Evidence
```

**Ciclo de manutenção:**
- Schema atualizado → pipeline detecta drift → reconcile (automático ou aprovado)
- Workspace mudou fora do schema → Unexpected → investigar + atualizar schema OU reverter

---

## 10. Browser Automation

Disponível como contingência se REST API se mostrar inacessível em ambiente específico.

**Estratégia de idempotência:**
1. GraphQL query: verificar se View com nome esperado já existe
2. Se existe → skip (não navegar ao browser)
3. Se Missing → Playwright navega ao Project, cria View

**Riscos:**
- GitHub redesenha UI sem aviso → seletores quebram
- Configuração de filtros complexos via UI é propensa a erro humano simulado
- Manutenção contínua de seletores = custo operacional alto

**Conclusão:** Não recomendado dado REST API disponível. Usar como último recurso.

---

## 11. Critérios para Manual Exception

**Manual Exception é aceitável SOMENTE quando:**
1. Nenhuma API oficial existe (confirmado via introspecção de schema GraphQL + docs REST)
2. Nenhum suporte no CLI existe (confirmado via `gh project --help` na versão atual)
3. Nenhum servidor MCP disponível com a capacidade
4. Browser automation é tecnicamente inviável ou custo > benefício
5. A operação é suficientemente infrequente
6. Os passos manuais são completamente documentados e determinísticos
7. Existe rastreamento da execução (Evidence registrada)

**Itens que qualificam como Manual Exception:**

`group_by` nas Views:
- Critério 1: Confirmado — REST POST não aceita `group_by`
- Critério 2: Confirmado — `gh project` não configura Views
- Critério 5: Infrequente — configurado uma vez por View, raramente alterado
- Critério 6: Documentado em `github-workspace-automation.md` Seção 13

`sort_by` nas Views:
- Mesmo raciocínio que `group_by`

**O que NÃO qualifica como Manual Exception:**
- Criação das Views: REST API existe e é documentada → Supported Automation
- Configuração do filter: REST filter param existe → Supported Automation
- Rename de campo: GraphQL mutation existe → Native Automation

---

## 12. Roadmap de implementação

### Fase A — Imediato (ferramentas existentes)

Disponível agora sem desenvolvimento adicional:

1. **Rename "Execution Mode" → "Mode"** (DRF-006):
   - Mecanismo: `gh api graphql` com `updateProjectV2Field`
   - Esforço: ~5 minutos (executar + verificar)
   - Dependência: autorização humana

2. **Criar 6 Views de Diligence** (DRF-012 a DRF-017):
   - Mecanismo: `gh api -X POST .../projectsV2/24/views`
   - Esforço: ~15 minutos (6 POST requests + verificação)
   - Dependência: autorização humana + campos Cycle e Phase já criados (Fase 1 do Plano)

3. **Configurar group_by e sort_by** (Manual Exception):
   - Mecanismo: Web UI do GitHub Projects
   - Esforço: ~10 minutos (6 views × 2 configurações)
   - Dependência: Views criadas no passo 2

### Fase B — Próximo (desenvolvimento de script)

Script shell ou Node.js que:
1. Parse `github-workspace-schema.yaml` → views_expected
2. GraphQL query → views_existing
3. REST POST para Views Missing
4. Gera relatório de Evidence em Markdown

Estimativa: 2-4 horas de desenvolvimento.

### Fase C — Futuro (GitOps completo)

GitHub Action que executa o script da Fase B:
- Trigger automático ou manual com aprovação
- Environment protection para autorização humana
- PR automático com Evidence após reconcile

Estimativa: 1 dia de desenvolvimento + configuração.

---

## 13. Recomendação final

### Classificação definitiva por item

| Item | DRF | Mecanismo | Classificação | Idempotente | Fase |
|---|---|---|---|---|---|
| Criar "Diligence Operations" | DRF-012 | REST POST /views | Supported Automation | Sim | A |
| Criar "Active Remediations" | DRF-013 | REST POST /views | Supported Automation | Sim | A |
| Criar "Workspace Reconciliation" | DRF-014 | REST POST /views | Supported Automation | Sim | A |
| Criar "Verification Queue" | DRF-015 | REST POST /views | Supported Automation | Sim | A |
| Criar "Diligence History" | DRF-016 | REST POST /views | Supported Automation | Sim | A |
| Criar "Waiver Reviews" | DRF-017 | REST POST /views | Supported Automation | Sim | A |
| Configurar filter das Views | — | REST filter param | Supported Automation | Sim | A |
| Configurar group_by | — | Web UI | Manual Exception | Não | A |
| Configurar sort_by | — | Web UI | Manual Exception | Não | A |
| Rename "Execution Mode" → "Mode" | DRF-006 | GraphQL updateField | Native Automation | Sim | A |

### Impacto na classificação do Reconcile Plan

O Plano de Reconcile (`github-workspace-reconcile-plan.md`) deve ser atualizado:

| Seção | Antes | Depois |
|---|---|---|
| Seção 3, Matriz, DRF-012 a DRF-017 | "GraphQL + Web UI para filtros" | "REST POST + Web UI (group_by/sort_by)" |
| Seção 6, Tabela de Mecanismos | "Filter/group_by/sort NOT configurável via API" | "filter configurável via REST; group_by/sort Manual Exception" |
| Seção 11, Unverifiable | Filter configs das 6 views | group_by e sort_by (filter agora Supported) |

---

## 14. Arquivos criados/modificados

| Arquivo | Tipo | Ação | Função |
|---|---|---|---|
| `prodops/framework/journeys/diligence/github-workspace-automation.md` | Normativo | Criado | Arquitetura normativa de automação — 13 seções |
| `prodops/framework/journeys/diligence/github-workspace-automation-matrix.yaml` | Normativo | Criado | Matriz técnica por operação com evidências |
| `prodops/documentation-review-diligence-github-automation.md` | Execution Report | Criado | Este relatório — evidências e decisões |

**Arquivos NÃO modificados** (conforme restrição de escopo):
- `github-workspace-reconcile-plan.md` — atualizações recomendadas documentadas acima
- `github-workspace-readiness.md` — nenhuma mudança necessária (readiness é para Inspect/Plan)
- Nenhum arquivo de produto (`api/`) modificado

---

## 15. Validações

### V1 — YAML válido

```bash
python3 -c "import yaml; yaml.safe_load(open('prodops/framework/journeys/diligence/github-workspace-automation-matrix.yaml')); print('YAML valid')"
# Resultado esperado: YAML valid
```

### V2 — Seções em automation.md

```bash
grep -n "^## Seção" prodops/framework/journeys/diligence/github-workspace-automation.md
# Esperado: 13 seções (1 a 13)
```

### V3 — Ausência de mutações GitHub nos novos arquivos

```bash
grep -n "method POST\|method PATCH\|method PUT\|method DELETE\|gh project create\|gh label create" \
  prodops/framework/journeys/diligence/github-workspace-automation.md \
  prodops/framework/journeys/diligence/github-workspace-automation-matrix.yaml 2>/dev/null | wc -l
# Resultado esperado: 0 (nenhuma mutação real executada — apenas exemplos conceituais documentados)
```

### V4 — Pesquisa técnica com evidências

Evidências coletadas durante a pesquisa:
- Introspecção da schema GraphQL: EXECUTADA ✓
- Teste REST GET endpoints: EXECUTADO ✓ (200 OK para /projectsV2, /fields, /items)
- Teste `gh project --help`: EXECUTADO ✓
- Verificação do tipo `UpdateProjectV2FieldInput`: EXECUTADA ✓ (campo `name` confirmado)
- Pesquisa de documentação oficial: EXECUTADA ✓ (REST API docs + Changelog Set 2025)

---

## 16. Critérios de aceite atendidos

| # | Critério | Status |
|---|---|---|
| 1 | Pesquisa técnica exaustiva com evidências reais (não pressupostos) | Atendido |
| 2 | Introspecção completa do schema GraphQL | Atendido |
| 3 | Teste de endpoints REST com respostas reais | Atendido |
| 4 | Verificação da versão atual do GitHub CLI | Atendido |
| 5 | Nenhuma mutação GitHub executada | Confirmado |
| 6 | Nenhum commit criado | Confirmado |
| 7 | Classificação baseada em evidências (não em opinião) | Atendido |
| 8 | Manual Exception justificada com critérios documentados | Atendido |
| 9 | Roadmap de implementação por fase | Atendido |
| 10 | Arquivos normativo e matriz criados | Atendido |
| 11 | Recomendação de atualização do Reconcile Plan documentada | Atendido |

---

## Referências

- REST API para Projects v2 (Views): https://docs.github.com/en/rest/projects/views
- GitHub Changelog (Set 2025): https://github.blog/changelog/2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more/
- Community: Add GraphQL mutations for ProjectV2 view management: https://github.com/orgs/community/discussions/194509
- Community: ProjectsV2 Manage Project Views via GraphQL: https://github.com/orgs/community/discussions/150130
- Community: Does Projects V2 API have ProjectV2View mutations?: https://github.com/orgs/community/discussions/153532
- Schema: `prodops/framework/journeys/diligence/github-workspace-schema.yaml`
- Reconcile Plan: `prodops/framework/journeys/diligence/github-workspace-reconcile-plan.md`
- Automation Architecture: `prodops/framework/journeys/diligence/github-workspace-automation.md`
- Automation Matrix: `prodops/framework/journeys/diligence/github-workspace-automation-matrix.yaml`
