# Iteration Plan — v0.4.0

> **Propósito:** Escopo de entrega aprovado para esta iteração. Contém os itens selecionados, a estratégia de execução, o detalhamento de cada fase e os critérios de saída.
>
> → [Iteration Backlog](../product/backlogs/iteration-backlog.md)

## Histórico

| Versão | Escopo | Status |
|---|---|---|
| v0.2.0 | DS-40: create-invoice-boleto | ✅ Concluído — PR #87 merged |
| v0.3.0 | Trilha A: Runtime Fix (send.sh + Lead Time + Status field) | ✅ Concluído |
| **v0.4.0** | **Trilha B: DS-38 create-invoice via Pix** | 🔄 Em execução |

---

## Escopo da iteração

| # | DS | Issue | Feature | Dependência | OBC | BDD | E2E | Status |
|---|---|-------|---------|-------------|-----|-----|-----|--------|
| 1 | DS-38 | [#38](https://github.com/produtoreativo/payments-api/issues/38) | create-invoice: criar invoice via Pix no gateway Payments | — | ✓ | ✓ | ✓ | ⬜ Pendente |

> DS-39 e DS-47 removidos desta iteração. DS-39 entra na próxima iteração após DS-38 promovido. DS-47 aguarda reconciliação do OBC (status "Adiado") e entrada no Reliability Plan.

---

## Fases do Downstream — o que cada uma realiza

A Jornada de Delivery opera em dois ciclos: **CI Sync** (conduzido pelo agente, local) e **CI Async** (conduzido pela plataforma, assíncrono). Cada fase emite eventos `Started` e `Completed` via `prodops_emit_event`, alimentando timeline, GitHub Project e Datadog.

---

### Bootstrap `CI Sync · fase 1 de 4`

**O que faz:** Prepara o ambiente de execução local antes de qualquer trabalho de código ou de git começar.

Ações concretas:
- Verifica runtimes e ferramentas de linha de comando disponíveis
- Instala dependências com o package manager declarado (`npm ci`)
- Sobe os serviços locais necessários (LocalStack para DynamoDB e SQS)
- Confirma que os nomes das variáveis de ambiente obrigatórias estão presentes (sem expor valores)
- Roda o gate de smoke definido em `prodops/exec/manifest.yaml`

**Quem não faz:** Não avalia artefatos ProdOps, não cria branches, não lê código de produto.

**Eventos:** `Bootstrap.Started` (imediatamente após ter o input context) → `Bootstrap.Completed` (após smoke gate passar).

**Correlation ID:** gerado nesta fase — propagado para todas as fases seguintes do mesmo flow.

---

### Hack `CI Sync · fase 2 de 4`

**O que faz:** Implementa a menor mudança coerente que satisfaz o OBC e a BDD Feature da issue, usando o ciclo TDD Red → Green → Yellow.

Ações concretas — executadas em três steps sequenciais:

**`start`**
- Limpa a working tree (stash ou descarte de mudanças não comprometidas)
- Sincroniza a base branch com `origin/master`
- Cria a feature branch no padrão `feat/<issue>-<slug>`

**`tdd`**
- Lê o OBC e a BDD Feature (fonte única de critérios de aceite — não inventa)
- **Red:** escreve ou ativa o teste que deve falhar (e confirma a falha)
- **Green:** implementa o mínimo de código para o teste passar
- **Yellow:** roda `lint`, `no_mocks`, atualiza artefatos ProdOps impactados (Event Storming, arquitetura, OBC), registra evidência no Release Trail

**`commit`**
- Revisa o diff completo antes de staged
- Commita seguindo Conventional Commits com escopo da issue

**Eventos:** `Hack.Started` (imediatamente após ter o input context, antes de ler OBC ou BDD) → `Hack.Completed` (após todos os gates do ciclo: Green + Lint + No Mocks + Release Trail).

---

### Sync `CI Sync · fase 3 de 4`

**O que faz:** Garante duas integridades independentes antes de fechar o trabalho local.

**`rebase` — integridade do repositório git**
- Busca atualizações do remote (`git fetch`)
- Avança a base branch (fast-forward ou merge)
- Integra a base no feature branch (`git rebase origin/master`)
- Resolve conflitos se houver, preservando os testes TDD
- Valida que os gates continuam passando após o rebase

**`align` — integridade dos artefatos ProdOps**
- Identifica artefatos desatualizados em relação ao diff do branch: BDD Features, Event Storming, arquitetura, OBC, Release Trail
- Atualiza apenas os arquivos impactados pela mudança
- Não reescreve decisões de produto upstream
- Registra o alinhamento no Release Trail

**Eventos:** `Sync.Started` → `Sync.Completed`.

---

### Finish `CI Sync · fase 4 de 4`

**O que faz:** Fecha o trabalho local com evidência de qualidade e abre o PR de forma autônoma.

Ações concretas:
- Revisa os arquivos alterados e confirma o escopo da entrega
- Roda os gates de qualidade completos: `acceptance` (36 cenários BDD via LocalStack), `lint`, `build`, `no_mocks`
- Confirma que os artefatos ProdOps foram atualizados apenas onde impactados
- Confirma que o Release Trail tem evidência do ciclo
- Faz push do feature branch para `origin`
- Cria o PR com título, descrição e referência à issue
- Aguarda a CI pipeline do PR (`pr-gates.yml`): lint, acceptance, build, no_mocks, prodops_consistency

**O que não faz:** Não faz deploy. Não aprova o PR. Não faz merge. Não decide sobre produção.

**Eventos:** `Finish.Started` → `Finish.Completed` (após PR criado e CI pipeline verde).

---

### Ship `CI Async · fase 1 de 3`

**O que faz:** Observa e orquestra o processo de merge + deploy de Staging. Não executa o deploy diretamente — quem executa é o GitHub Actions.

Ações concretas:
- Confirma que `Finish.Completed` foi emitido para este work item
- Faz o merge do PR via `gh pr merge --squash` (autorizado pela Skill)
- Confirma que o workflow de deploy de Staging iniciou e concluiu com sucesso (`staging-deploy.yml`)
- Registra o run ID e o resultado do workflow como evidência no Release Trail
- Confirma que o ambiente de Staging está responsivo após o deploy

**Eventos:** `Ship.Started` → `Ship.Completed` (após merge confirmado + deploy Staging bem-sucedido).

---

### Validate `CI Async · fase 2 de 3`

**O que faz:** Prova a prontidão para promoção com evidência de acceptance em Staging.

Ações concretas:
- Coleta evidência de que os cenários de aceite passam no ambiente de Staging
- Verifica que os quality gates declarados no Reliability Plan estão satisfeitos
- Verifica ausência de regressão nos cenários BDD não relacionados à mudança
- Registra evidência no Release Trail

**Eventos emitidos:** `Validate.Started` → `Shared.Gate.Passed` → `Validate.Completed`.

---

### Promote `CI Async · fase 3 de 3`

**O que faz:** Promove a Feature do ambiente de Staging para o Sandbox (Release Candidate) e emite o Lead Time automaticamente.

Ações concretas:
- Confirma que `Ship.Completed` e `Validate.Completed` foram emitidos para este work item
- Confirma que riscos não resolvidos estão aceitos, mitigados ou movidos para follow-up documentado
- Executa a promoção de Staging → Sandbox
- Registra aprovação, evidência e próximos passos no Release Trail
- Emite `Promote.Completed`, que aciona automaticamente:
  - Cálculo do Lead Time (diferença entre `Bootstrap.Started` e `Promote.Completed` em dias)
  - Emissão de `runtime.delivery.lead_time_days` gauge no Datadog

**Eventos:** `Promote.Started` → `Promote.Completed` (+ Lead Time automático via Step 4b do `emit-event`).

---

## Critérios de saída da iteração

- PR de DS-38 merged em `main`.
- Evento `prodops.delivery.promote.completed` emitido para issue #38.
- KPI Lead Time preenchido automaticamente no Promote (sem intervenção manual).
- Issue #38 fechada no GitHub.
- Diligence concluída para DS-38: evidence capturada, attached, promoted e closed.
