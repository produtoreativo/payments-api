# Iteration Plan — v0.5.0

> **Propósito:** Escopo de entrega aprovado para esta iteração. Contém os itens selecionados, a estratégia de execução, o detalhamento de cada fase e os critérios de saída.
>
> → [Iteration Backlog](../product/backlogs/iteration-backlog.md)

## Histórico

| Versão | Escopo | Status |
|---|---|---|
| v0.2.0 | DS-40: create-invoice-boleto | ✅ Concluído — PR #87 merged |
| v0.3.0 | Trilha A: Runtime Fix (send.sh + Lead Time + Status field) | ✅ Concluído |
| v0.4.0 | Trilha B: DS-38 create-invoice via Pix | ✅ Concluído — PR #89 merged |
| **v0.5.0** | **DS-39 · DS-42 · DS-43 · DS-41** | 🔄 Em execução |

---

## Escopo da iteração

| # | DS | Issue | Feature | Dependência | OBC | BDD | E2E | Status |
|---|---|-------|---------|-------------|-----|-----|-----|--------|
| 1 | DS-39 | [#39](https://github.com/produtoreativo/payments-api/issues/39) | payment-confirmation: confirmar pagamento aprovado via webhook do provedor | — | ✓ | ✓ | ✓ | ⬜ Pendente |
| 2 | DS-42 | [#42](https://github.com/produtoreativo/payments-api/issues/42) | api-token-validation: garantir acesso autenticado por token de API | — | ✓ | ✓ | ✓ | ⬜ Pendente |
| 3 | DS-43 | [#43](https://github.com/produtoreativo/payments-api/issues/43) | webhook-configuration: configurar webhook de notificação por token de API | DS-42 | ✓ | ✓ | ✓ | ⬜ Pendente |
| 4 | DS-41 | [#41](https://github.com/produtoreativo/payments-api/issues/41) | credit-card-authorization-confirmation: aceitar pagamento com cartão de crédito hospedado | — | ✓ | ⚠️ | ✓ | ⬜ Pendente |

> **⚠️ DS-41:** OBC committed. BDD presente como `credit-card-payment.feature` — slug divergente de `credit-card-authorization-confirmation`. Verificar no gate de readiness se o Downstream aceita o mapeamento ou se o arquivo precisa ser renomeado antes do Bootstrap.

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

**Eventos:** `Bootstrap.Started` → `Bootstrap.Completed` (após smoke gate passar).

---

### Hack `CI Sync · fase 2 de 4`

**O que faz:** Implementa a menor mudança coerente que satisfaz o OBC e a BDD Feature da issue, usando o ciclo TDD Red → Green → Yellow.

**`start`** — limpa working tree, sincroniza master, cria feature branch `feat/<issue>-<slug>`.

**`tdd`** — Red (teste falha) → Green (mínimo para passar) → Yellow (lint, no_mocks, artefatos ProdOps, Release Trail).

**`commit`** — revisa diff, commita seguindo Conventional Commits.

**Eventos:** `Hack.Started` → `Hack.Completed`.

---

### Sync `CI Sync · fase 3 de 4`

**O que faz:** Garante integridade do repositório git e dos artefatos ProdOps.

**`rebase`** — fetch, rebase em `origin/master`, resolve conflitos, valida gates.

**`align`** — identifica e atualiza artefatos ProdOps impactados pelo diff (BDD, Event Storming, OBC, Release Trail).

**Eventos:** `Sync.Started` → `Sync.Completed`.

---

### Finish `CI Sync · fase 4 de 4`

**O que faz:** Fecha o trabalho local com evidência de qualidade e abre o PR de forma autônoma.

- Gates completos: `acceptance`, `lint`, `build`, `no_mocks`
- Push do feature branch + criação do PR com referência à issue
- Habilita auto-merge (`--squash`) — merge ocorre quando CI pipeline (`pr-gates.yml`) ficar verde

**Eventos:** `Finish.Started` → `Finish.Completed` (após PR criado e CI verde).

---

### Ship `CI Async · fase 1 de 3`

**O que faz:** Observa merge + deploy de Staging via GitHub Actions (`staging-deploy.yml`).

**Eventos:** `Ship.Started` → `Ship.Completed` (após merge + deploy Staging confirmados).

---

### Validate `CI Async · fase 2 de 3`

**O que faz:** Prova prontidão para promoção com evidência de acceptance em Staging.

**Eventos:** `Validate.Started` → `Shared.Gate.Passed` → `Validate.Completed`.

---

### Promote `CI Async · fase 3 de 3`

**O que faz:** Promove de Staging → Sandbox (Release Candidate) e calcula Lead Time automaticamente.

**Eventos:** `Promote.Started` → `Promote.Completed` (+ `runtime.delivery.lead_time_days` gauge no Datadog).

---

## Critérios de saída da iteração

- PRs de DS-39, DS-42, DS-43 e DS-41 merged em `main`.
- Evento `prodops.delivery.promote.completed` emitido para cada issue.
- KPI Lead Time preenchido automaticamente no Promote de cada item.
- Issues #39, #42, #43, #41 fechadas no GitHub.
- Diligence concluída para cada item: evidence capturada, attached, promoted e closed.
