# Relatório de Execução — Experimento de Validação de Automação
# GitHub Projects V2 — View Creation via REST API
# 2026-07-24

---

## 1. Executive Summary

Um experimento controlado de automação foi executado em 2026-07-24 para validar
empiricamente se o endpoint REST `POST /orgs/{org}/projectsV2/{project_number}/views`
cria Views no GitHub Projects V2.

**Resultado:** Partial Success.

- A hipótese principal foi **CONFIRMADA**: REST POST retornou HTTP 201 e criou a View
  "Workspace Reconciliation" (view #7, node_id PVTV_lADOAT1J1c4BeILXzgLFNOI).
- **Descoberta crítica**: A API **não é auto-idempotente**. O teste de idempotência
  criou uma View duplicada (#8) que não pode ser removida via API.
- **Classificação mantida**: Supported Automation (não promovida a Native Automation
  devido à ausência de idempotência nativa e ausência de DELETE).
- **Ação manual necessária**: Remover View duplicada #8 via Web UI.

**Evidence:** EVD-2026-0003

---

## 2. Hipótese

**H:** O endpoint REST `POST /orgs/{org}/projectsV2/{project_number}/views` suporta
criação de Views no GitHub Projects V2, permitindo automação sem interface web.

**Subhipóteses:**
- H1: O endpoint aceita `name` e `layout` como parâmetros e retorna 201 Created.
- H2: A operação é idempotente — um segundo POST com o mesmo nome não cria duplicata.
- H3: Existe mecanismo de DELETE para Views via API.

**Resultados:**
- H1: CONFIRMADA (HTTP 201, View criada com sucesso)
- H2: REFUTADA (segundo POST criou View duplicada — não há deduplicação por nome)
- H3: REFUTADA (REST DELETE retorna 404; GraphQL deleteProjectV2View não existe no schema)

---

## 3. Ambiente

| Parâmetro | Valor |
|---|---|
| GitHub CLI | v2.95.0 (2026-06-17) |
| Project | ProdOps — payments-api |
| Project Number | 24 |
| Project ID (node) | PVT_kwDOAT1J1c4BeILX |
| Owner | produtoreativo |
| Repository | produtoreativo/payments-api |
| Executor | cmilfont (Christiano Milfont) |
| Autorização | Section 13 — github-workspace-reconcile-plan.md, 2026-07-24 |
| Data de execução | 2026-07-24T17:30:22Z |

---

## 4. Execução

### 4.1 — Pre-flight (Step 1)

GraphQL query confirmou 6 views existentes antes do experimento:

| # | Nome | Layout | Criada em |
|---|---|---|---|
| 1 | View 1 | TABLE_LAYOUT | 2026-07-22 |
| 2 | All Work Items | TABLE_LAYOUT | 2026-07-22 |
| 3 | By Operation | TABLE_LAYOUT | 2026-07-22 |
| 4 | Business Signals | TABLE_LAYOUT | 2026-07-22 |
| 5 | Delivery | TABLE_LAYOUT | 2026-07-22 |
| 6 | Diligence | TABLE_LAYOUT | 2026-07-22 |

"Workspace Reconciliation" **ausente** — condição de pré-execução confirmada.

### 4.2 — POST principal (Step 2)

```
POST /orgs/produtoreativo/projectsV2/24/views
{
  "name": "Workspace Reconciliation",
  "layout": "table"
}
```

**Resultado:** HTTP 201 Created

View criada:
- `id`: 46478562
- `number`: 7
- `node_id`: PVTV_lADOAT1J1c4BeILXzgLFNOI
- `html_url`: https://github.com/orgs/produtoreativo/projects/24/views/7
- `created_at`: 2026-07-24T17:30:22Z
- `filter`: null
- `group_by`: [] (parâmetro não suportado na criação)

### 4.3 — Post-verification (Step 3)

GraphQL query confirmou view #7 "Workspace Reconciliation" presente com TABLE_LAYOUT.

### 4.4 — Idempotency test (Step 4)

Segundo POST idêntico executado. Resultado: **HTTP 201 Created** — View duplicada criada:
- `number`: 8
- `node_id`: PVTV_lADOAT1J1c4BeILXzgLFNOs
- `created_at`: 2026-07-24T17:30:35Z

Tentativas de deleção da View #8:
- `DELETE /orgs/produtoreativo/projectsV2/24/views/8`: **404 Not Found**
- GraphQL `deleteProjectV2View(input: {viewId: "..."})`: **Field doesn't exist on Mutation**

**Conclusão:** View duplicada persiste. Remoção requer Web UI manual.

---

## 5. Evidências

| ID | Tipo | Status | Descrição |
|---|---|---|---|
| EVD-2026-0003 | Automation Validation Experiment | Collected | Este experimento — View Creation via REST API |
| EVD-2026-0001 | Inspection Snapshot | Collected | Estado pré-Reconcile (referência) |
| EVD-2026-0002 | Post-Reconcile Snapshot | Collected | Estado pós-Fases 1-4 (referência) |

**Request/Response documentados em:** `prodops/artifacts/diligence/evidence/EVD-2026-0003.md`

---

## 6. Resultado

**Classificação:** Partial Success

| Aspecto | Resultado | Detalhe |
|---|---|---|
| View criada | SIM | HTTP 201, view #7, node_id PVTV_lADOAT1J1c4BeILXzgLFNOI |
| Hipótese H1 | CONFIRMADA | REST POST funciona como documentado |
| Hipótese H2 | REFUTADA | API não é auto-idempotente — cria duplicatas |
| Hipótese H3 | REFUTADA | DELETE não disponível via REST nem GraphQL |
| Estado pós-experimento | Não-limpo | View #8 duplicada persiste, requer cleanup manual |

**Justificativa técnica:** A hipótese principal foi confirmada — o endpoint existe, aceita
os parâmetros documentados, e retorna 201. Porém o experimento revelou dois comportamentos
não documentados que impactam a arquitetura de automação: ausência de idempotência nativa
e ausência de mecanismo de reversão via API.

---

## 7. Idempotência

**Resultado: FALHA — API NÃO É AUTO-IDEMPOTENTE**

| Chamada | HTTP Status | Resultado |
|---|---|---|
| POST #1 (view #7) | 201 Created | View "Workspace Reconciliation" criada |
| POST #2 (view #8) | 201 Created | View DUPLICADA criada — mesmo nome, novo ID |

**Implicação:** O padrão documentado na `idempotency_strategy` da matriz é MANDATÓRIO:

```
1. GraphQL query: projectV2.views(first:20) → listar names existentes
2. Calcular diff: expectedViews XOR existingViews
3. REST POST somente para Views Missing (diff result)
4. GraphQL verify após criação
```

Qualquer implementação que execute POST sem o pre-check GraphQL produzirá duplicatas
irremovíveis via API. O campo `idempotent: true` na matriz foi corrigido para `false`.

---

## 8. Impacto arquitetural

O experimento confirma que o mecanismo REST POST funciona para as 5 Views restantes:

| View | DRF | Status pré-experimento | Impacto |
|---|---|---|---|
| Diligence Operations | DRF-012 | Não criada | REST POST aplicável |
| Active Remediations | DRF-013 | Não criada | REST POST aplicável |
| Verification Queue | DRF-015 | Não criada | REST POST aplicável |
| Diligence History | DRF-016 | Não criada | REST POST aplicável |
| Waiver Reviews | DRF-017 | Não criada | REST POST aplicável |

**Workspace Reconciliation** (DRF-014): Criada por este experimento (view #7). View #8
(duplicata do idempotency test) requer cleanup manual via Web UI.

**Constraint arquitetural crítico:** O script de automação DEVE implementar o pre-check
GraphQL como step obrigatório. Sem isso, múltiplas execuções (re-runs, retries) criarão
duplicatas irremovíveis.

**DELETE não disponível:** A ausência de DELETE via API significa que erros de criação
(nome incorreto, layout errado) requerem intervenção manual no browser para cleanup.
O script deve validar parâmetros antes de POST.

---

## 9. Atualização da classificação

**Classificação mantida: Supported Automation** (não promovida)

| Critério | Situação |
|---|---|
| API documentada e estável | SIM — GA desde setembro 2025 |
| Cria Views com sucesso | SIM — HTTP 201 confirmado |
| Idempotência nativa | NÃO — requer guard externo |
| Reversão via API | NÃO — DELETE retorna 404 |
| GraphQL mutation nativa | NÃO — não existe no schema |

A promoção para "Native Automation" foi considerada mas não aplicada pois:
1. "Native Automation" requer GraphQL mutation (conforme definição canônica na matriz)
2. A ausência de idempotência nativa e DELETE impede classificação como totalmente
   confiável para automação não-supervisionada

**Documentos atualizados:**
- `github-workspace-automation-matrix.yaml`: `idempotent` corrigido para `false`,
  `idempotency_guard` marcado como `mandatory`, `empirical_validation` adicionado
- `github-workspace-automation.md`: Tabela Seção 5 e Seção 13 atualizadas com
  nota de idempotência e referência a EVD-2026-0003

---

## 10. Recomendações para Verify

### Views restantes a criar (5 de 6)

As 5 Views restantes (DRF-012, 013, 015, 016, 017) devem ser criadas com o seguinte
padrão obrigatório:

```bash
# Step 1 — Verificar views existentes (OBRIGATÓRIO antes de qualquer POST)
EXISTING_VIEWS=$(gh api graphql -f query='
  query {
    node(id: "PVT_kwDOAT1J1c4BeILX") {
      ... on ProjectV2 {
        views(first: 20) {
          nodes { name }
        }
      }
    }
  }' --jq '[.data.node.views.nodes[].name]')

# Step 2 — POST somente se view não existe
# (implementar diff: expectedViews XOR existingViews)

# Step 3 — Verificar criação
# (repetir GraphQL query do Step 1)
```

### Cleanup necessário antes de prosseguir

**Ação manual obrigatória:** Remover View duplicada #8 "Workspace Reconciliation":
1. Acessar https://github.com/orgs/produtoreativo/projects/24
2. Identificar a view duplicada "Workspace Reconciliation" (number=8)
3. Renomear ou deletar via interface web
4. Verificar via GraphQL que apenas view #7 persiste

### Configurações pós-criação (Manual Exception mantido)

Após criar as 5 Views restantes via REST:
- `group_by`: Configurar via Web UI para cada view (sem API disponível)
- `sort_by`: Configurar via Web UI para cada view (sem API disponível)
- `filter`: Definido no POST de criação via parâmetro `filter` (Supported Automation)

### Classificação da operação pós-Verify

Se as 5 Views restantes forem criadas com sucesso via REST POST com pre-check GraphQL:
- O padrão como um todo é **Supported Automation com guard obrigatório**
- A classify pode ser revisitada se o GitHub adicionar idempotência nativa ou DELETE

---

*Gerado em: 2026-07-24*
*Executor: cmilfont*
*Evidence: EVD-2026-0003*
*Authorization: Section 13 — github-workspace-reconcile-plan.md*
