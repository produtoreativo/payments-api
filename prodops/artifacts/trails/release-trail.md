## 2026-06-30 22:24

### Summary

Implemented in-repo Reliability Plan P0 hardening for payment confirmation: Dynamo webhook correlation now finds invoices by provider payment id or external reference, and uncorrelated provider webhooks now emit an observable event.

### Related

- Reliability Plan: `prodops/journeys/assessment/reliability-plans/README.md`
- OBC: Confirmacao de pagamento confiavel para a jornada Checkout -> Payments
- BDD Feature: `prodops/artifacts/bdd/payment-confirmation.feature`

### Code

- `api/src/infra/dynamo.service.ts`
- `api/src/modules/invoices/services/invoice-repository.service.ts`
- `api/src/modules/invoices/services/invoice.service.ts`

### Tests

- Tests created or updated: `api/test/criar-invoice.e2e-spec.ts`
- Validation executed: `cd api && npm run test:acceptance -- --runInBand`
- Validation executed: `cd api && npm run build`

### Artifacts Updated

- Product Deck: not changed
- Service Deck: not changed
- Tracking List: not changed
- Reliability Plan: updated to reflect implemented Dynamo correlation and uncorrelated webhook observability
- OBC: not changed

### Notes

Remaining Reliability Plan items outside this change include Checkout Feature Flag readiness, retry policy for transient provider failures, required webhook token validation for release environments, Asaas timeout configuration and durable publication strategy for `payment.confirmed`.

## 2026-07-02 09:58

### Summary

Updated the repository home in `README.md` to present payments-api as the ProdOps University reference project, connecting the functional sandbox to product, reliability, observability, testing and operational artifacts.

### Related

- Reliability Plan: `prodops/journeys/assessment/reliability-plans/README.md`
- OBC: Product Deck and Service Deck OBC sections referenced in the README
- BDD Feature: not applicable — repository organization change, no product behavior changed

### Code

- `README.md`

### Tests

- Tests created or updated: none
- Validation executed: checked referenced README paths exist
- Validation executed: `git diff --check -- README.md prodops/artifacts/trails/release-trail.md`

### Artifacts Updated

- Product Deck: referenced, not changed
- Service Deck: referenced, not changed
- Tracking List: referenced, not changed
- Reliability Plan: referenced, not changed
- OBC: referenced, not changed

### Notes

README now calls out educational roadmap gaps explicitly: OpenAPI, OpenSLO, dedicated runbooks, Decision Trail, postmortems, dashboards and event contracts.

## 2026-07-02 11:17

### Summary

Removed the tracked frontend `node_modules` tree from Git and updated the repository ignore rules so dependency folders are ignored at any directory depth.

### Related

- Reliability Plan: not applicable
- OBC: not applicable
- BDD Feature: not applicable

### Code

- `.gitignore`
- `validation-workbench/node_modules`

### Tests

- Tests created or updated: none, mechanical repository hygiene change
- Validation executed: `git ls-files | rg '(^|/)node_modules(/|$)' || true`
- Validation executed: `git check-ignore -v validation-workbench/node_modules/.keep api/node_modules/.keep node_modules/.keep`

### Artifacts Updated

- Product Deck: not changed
- Service Deck: not changed
- Tracking List: not changed
- Reliability Plan: not changed
- OBC: not changed

### Notes

The local `validation-workbench/node_modules` directory can remain on disk for the developer environment, but it is no longer tracked by Git.

## 2026-07-02 11:38

### What changed?

Organized the repository for Claude, Codex, and Copilot agents with ProdOps as the single source of context. Added root agent guidance, Claude/Codex-specific instructions, Copilot prompts, generic execution skills, canonical ProdOps folders, and operation/diligence placeholders.

### Why?

To separate product context from execution workflows and tool-specific configuration, reducing duplicated business knowledge across agent surfaces.

### Related OBC

Not applicable; repository organization change.

### Related BDD

Not applicable; no product behavior changed.

### Evidence

- Created root `AGENTS.md` flow: Current State -> Assessment -> Reliability Plan -> BDD Feature -> Skill -> Code -> Release Trail.
- Added generic skills under `skills/`.
- Moved ProdOps artifacts to canonical paths under `prodops/artifacts/product/`, `prodops/assessment/`, `prodops/execution-model/`, and `prodops/operation/`.
- Updated old ProdOps path references.
- Validation executed: expected structure presence check.
- Validation executed: old path/name reference search.
- Validation executed: root skill frontmatter check.

### Next steps

Keep future product context in `prodops/` and keep skills limited to execution procedure.

## 2026-07-02 13:42

### What changed?

Split the ProdOps workspace into Upstream and Downstream paths. Moved governed delivery evidence from `prodops/diligence/` to `prodops/execution-model/`, added the Upstream exploration workspace, added `skills/upstream/` and `skills/downstream/`, and added templates for both paths.

### Why?

To separate lightweight exploration from governed delivery while preserving the full ProdOps delivery flow for committed release work.

### Related OBC

Not applicable; repository organization change.

### Related BDD

Not applicable; no product behavior changed.

### Evidence

- Moved Release Trail, Quality Gates, and Done Criteria into `prodops/execution-model/`.
- Added `prodops/journeys/discovery/` for experiments, spikes, prototypes, learnings, and upstream trail.
- Added `prodops/downstream/delivery-flow.md` and a pointer backlog.
- Added `prodops/skills/upstream/SKILL.md` and `prodops/skills/downstream/SKILL.md`.
- Updated agent and Copilot prompts to route work through Upstream or Downstream.

### Next steps

Use Upstream for reversible exploration and Downstream for approved delivery governed by the full ProdOps flow.

## 2026-07-03 — Webhook Configuration per API Token

### What changed?

Implemented webhook configuration API, allowing API Token holders to register
HTTPS callback URLs that receive `invoice.confirmed` and `invoice.cancelled`
events. Each webhook has an auto-generated HMAC-SHA256 secret returned only at
creation. Delivery is fire-and-forget; failure never blocks the payment flow.

Canonical events `payment.confirmed` and `payment.cancelled` were enriched with
`tenantId`, `amount`, and `currency` to give downstream consumers full context
without a secondary lookup.

### Why?

Complete the integration contract: consumers using API Tokens need status
notifications without polling. Webhook configuration is the natural complement to
the API Token feature delivered earlier in this iteration.

### Related OBC

`prodops/artifacts/obcs/webhook-configuration.md`

### Related BDD

`prodops/artifacts/bdd/webhook-configuration.feature`

### Evidence

- `WebhooksModule` created at `api/src/modules/webhooks/` with:
  - `WebhookRepository` — DynamoDB-backed storage with `TenantWebhooksIndex` GSI.
  - `WebhookService` — registration, listing, deactivation; URL validation (HTTPS or localhost).
  - `WebhookDeliveryService` — listens to `payment.confirmed` / `payment.cancelled`; dispatches signed HTTP POST with 10s timeout; emits `webhook.delivery.sent` / `webhook.delivery.failed`.
  - `WebhookConfigController` — `POST /webhooks`, `GET /webhooks`, `DELETE /webhooks/:webhookId`, all behind `ApiTokenGuard`.
- `WebhooksTable` added to `api/infra/dynamodb.yaml` with `TenantWebhooksIndex` GSI.
- `payment.confirmed` and `payment.cancelled` events enriched with `tenantId`, `amount`, `currency` in `invoice.service.ts`.
- `WebhooksModule` registered in `AppModule`.
- Build: `cd api && npm run build` — passed with no errors.

### Next steps

- Add acceptance tests: webhook registration, listing, delivery on confirmed event.
- Add retry logic for failed deliveries (backoff + dead-letter queue).
- Add `WEBHOOKS_TABLE` env var to `.env.example`.
- Consider TTL for deactivated webhook records in DynamoDB.

## 2026-07-03 — API Token Validation

### What changed?

Implemented API Token authentication for the Payments API. All business routes
(`/invoices`) now require a valid `X-Api-Token` header. Webhook routes remain
excluded (they use their own `asaas-access-token` validation). A local dev token
is pre-registered via `API_TOKEN_LOCAL` env var, allowing localhost access without
external secrets infrastructure.

### Why?

Enable controlled access to the Payments API by tenant, eliminate anonymous
consumption by Checkout or integrations, and establish observable token validation
events from day one of production traffic.

### Related OBC

`prodops/artifacts/obcs/api-token-validation.md`

### Related BDD

`prodops/artifacts/bdd/api-token-validation.feature`

### Evidence

- `AuthModule` created at `api/src/modules/auth/` with `ApiTokenService` and `ApiTokenGuard`.
- `ApiTokenGuard` applied to `InvoiceController` via `@UseGuards`.
- `X-Api-Token` added to CORS allowed headers (`api/src/main.ts`).
- `X-Api-Token` added to pino log redaction paths (`api/src/app.module.ts`).
- `API_TOKEN_LOCAL` documented in `.env.example` and set in `.env` for local dev.
- Build executed: `cd api && npm run build` — passed with no errors.

### Next steps

- Add acceptance test scenarios for 401 rejection and token validation.
- Wire `API_TOKENS` env var with real Checkout token in staging before go-live.
- Evaluate token store migration to DynamoDB or SSM Parameter Store for zero-deploy revocation.

## 2026-07-08

### Summary

Implemented Boleto invoice creation on the Payments gateway: contract extended with `bankSlipUrl` and `identificationField` for `billingType=BOLETO`, `dueDate` validated as future (minimum D+1) before provider call, and provider charge contract now asserts `bankSlipUrl` presence for Boleto. The `toResponse` payload now exposes `billingType`, `dueDate`, `bankSlipUrl` and `identificationField` per the OBC response contract.

### Related OBC

`prodops/artifacts/obcs/create-invoice-boleto.md`

### Related BDD

`prodops/artifacts/bdd/create-invoice-boleto.feature` (8 scenarios)

### Iteration Plan

"Criar invoice via Boleto" — Entrou.

### Risks addressed

- B1 — `bankSlipUrl` ausente: `assertProviderChargeContract` agora rejeita cobrança Boleto sem `bankSlipUrl` (provider_contract_violation).
- B2 — `dueDate` passada/ausente: validação `400` antes de chamar a Asaas (mínimo D+1).
- B4 — `identificationField` ausente: adicionado a `ProviderChargeResponse`, `InvoiceRecord` e `InvoiceResponseDto`.

### Code

- `api/src/modules/invoices/types/invoice.types.ts` — `InvoiceRecord` e `ProviderChargeResponse` ganham `bankSlipUrl`/`identificationField`.
- `api/src/modules/invoices/dto/invoice-response.dto.ts` — DTO expõe `billingType`, `dueDate`, `bankSlipUrl`, `identificationField`.
- `api/src/infra/asaas.service.ts` — mock gera `bankSlipUrl`/`identificationField` para BOLETO; resposta real mapeia `identificationField`.
- `api/src/modules/invoices/services/invoice.service.ts`:
  - `validateCreateInvoice`: `dueDate` obrigatória e futura (≥ D+1) para BOLETO.
  - `assertProviderChargeContract`: exige `bankSlipUrl` em cobrança Boleto.
  - `createInvoice`: propaga `bankSlipUrl`/`identificationField` ao salvar OPEN.
  - `toResponse`: expõe os novos campos.

### Tests

- Test created: `api/test/criar-invoice-boleto.e2e-spec.ts` — 8 cenários BDD cobertos.
- Red Bar confirmado (4 falhas comportamentais: bankSlipUrl/identificationField ausentes na resposta, dueDate futura não validada).
- Green Bar: `npx jest --config ./test/jest-e2e.json test/criar-invoice-boleto.e2e-spec.ts` — 8 passed.
- Suite completa sem regressão: `criar-invoice`, `cancelar-invoice`, `confirmar-pagamento`, `api-token`, `criar-invoice-boleto` — 38 passed, 5 suites.
- Lint: `cd api && npm run lint` — exit 0 (0 errors).
- Build: `cd api && npm run build` — passed.

### Artifacts Updated

- Product Deck: não alterado.
- Service Deck: não alterado.
- Iteration Plan: não alterado (entrada já com status Entrou).
- OBC: não alterado.
- BDD Feature: não alterada.
- Riscos: não alterados (mitigações B1/B2/B4 cobertas pela implementação).

### Notes / Decision Trail

- `externalReference`: a BDD Feature (cenário "Criar boleto com sucesso") indica que o `externalReference` enviado à Asaas deve conter o identificador do pedido (`MS-200010`). O código atual usa `externalReference = invoiceId` (`inv_ulid`) e o `assertProviderChargeContract` valida consistência contra esse valor. Mudar essa semântica quebraria o contrato PIX/cartão já estabilizado e seus acceptance tests. Preservada a regra existente (`externalReference = invoiceId`); alinhamento com a BDD Boleto fica como divergência registrada para decisão posterior no Delivery Sync, conforme regra de Context Rules do AGENTS.md ("preservar a existente e registrar em Decision Trail").
- `payment.boleto.expired` (Risco B3) não implementado nesta entrega — depende de webhook `PAYMENT_OVERDUE` do provedor, atualmente mapeado como evento ignorado. A jornada de expiração assíncrona permanece fora deste slice.

## 2026-07-08 — Fix: test-acceptance.sh não executava a suíte Boleto

### Summary

`scripts/test-acceptance.sh` não incluía `test/criar-invoice-boleto.e2e-spec.ts` em nenhum filtro — nem na suíte padrão (sem argumento), nem como opção nomeada (`criar`, `cancelar`, `confirmar`, `token`). Os 8 cenários BDD de Boleto, implementados e commitados na entrada anterior deste trail, nunca eram executados pelo wrapper de testes de aceitação. Adicionado filtro `boleto` e inclusão na suíte padrão.

Corrigido também um bug de detecção de container: `docker inspect` em um container inexistente emite uma linha vazia em stdout (comportamento observado no Docker CLI 29.6.1) além do erro em stderr; combinado com `set -o pipefail`, isso encerrava o script silenciosamente antes de alcançar o fallback `missing`, impedindo a criação automática do container LocalStack quando ausente.

### Related OBC

`prodops/artifacts/obcs/create-invoice-boleto.md`

### Related BDD

`prodops/artifacts/bdd/create-invoice-boleto.feature` (8 cenários — já cobertos por `api/test/criar-invoice-boleto.e2e-spec.ts`, agora efetivamente executados)

### Evidence

- `scripts/test-acceptance.sh`:
  - Linha de detecção de estado do container: normaliza saída de `docker inspect` (`tr -d '[:space:]'`) e neutraliza o exit code da pipeline (`|| true`) antes de aplicar o fallback `missing`, corrigindo a interação com `set -euo pipefail`.
  - Filtro `boleto` adicionado, mapeando para `test/criar-invoice-boleto.e2e-spec.ts`.
  - Suíte padrão (`FILTER=""`) passa a incluir `test/criar-invoice-boleto.e2e-spec.ts`.
  - Comentário de uso e mensagem de erro de filtro inválido atualizados.
- Validação executada: container `localstack` removido manualmente (`docker rm -f localstack`) e `./scripts/test-acceptance.sh` reexecutado do zero — script detectou corretamente o estado `missing`, recriou o container, aguardou saúde, e rodou a suíte completa.
- Suite completa sem regressão: `criar-invoice`, `criar-invoice-boleto`, `cancelar-invoice`, `confirmar-pagamento`, `api-token` — 38 passed, 5 suites.

### Artifacts Updated

- Product Deck: não alterado.
- Service Deck: não alterado.
- Iteration Plan: não alterado.
- OBC: não alterado.
- BDD Feature: não alterada — o gap era de execução (script wrapper), não de cobertura de cenário.

### Notes

Esse gap não teria sido pego por CI, já que `.github/workflows/staging-deploy.yml` invoca os specs diretamente via `npx jest` (não via `test-acceptance.sh`) — o wrapper é usado apenas em fluxo local. Vale considerar, em um Sync futuro, se o CI e o script local devem compartilhar a mesma lista de specs para evitar essa classe de divergência se repetir.

## 2026-07-12 — Consolidação e remoção de `docs/`

### Summary

Removida a árvore documental legada `docs/` após triagem. Contexto válido foi consolidado nas fontes canônicas sem alterar código ou promover novos comportamentos.

### Artifacts Updated

- Product Deck: incorporada a visão de Payments como System of Record e Asaas como PSP externo.
- Architecture Overview: registrada a fronteira de responsabilidade Payments ↔ PSP.
- Decision Trail: registrada a consolidação e as alternativas descartadas.
- BDD index: adicionada a feature de cartão e corrigido o caminho de features exploratórias.
- OBC index: reforçado que todo OBC committed possui arquivo próprio.
- API README: substituído o conteúdo genérico do NestJS por instruções específicas da Payments API e da integração Asaas.
- Reliability Plan: referências a contratos legados substituídas pelos caminhos vigentes.

### Validation

- Nenhuma BDD committed foi substituída pela especificação alternativa existente em `docs/`.
- O Event Storming canônico em `prodops/journeys/assessment/event-storming/plan.json` foi preservado.
- A mudança é exclusivamente documental; testes de aplicação não são requeridos.

## 2026-07-13 — refine(sync): rebase como integridade do repo, align como integridade dos artefatos ProdOps

### Summary

Refinamento conceitual da fase Sync em `prodops/journeys/delivery/phases/sync/`. Os dois steps ganharam responsabilidades articuladas com precisão: `rebase` é a **integridade do repositório git** (tornar o repo pronto para merge, sem enfraquecer testes), e `align` é a **integridade dos artefatos ProdOps** (BDD, Event Storming, arquitetura, OBC e Release Trail refletem o diff do branch). Foram tornadas explícitas as fronteiras do Sync com Hack (quality gates/Yellow Bar), Finish (abertura de PR) e Ship (pipeline assíncrona), além do critério de conclusão de cada step e da tabela canônica mudança → artefato.

### Related

- Fase: `prodops/journeys/delivery/phases/sync/README.md` (e `.en.md`)
- Skills: `prodops/skills/sync/steps/rebase/SKILL.md`, `prodops/skills/sync/steps/align/SKILL.md` (e versões `.en.md`)
- Prompts Copilot: `.github/prompts/sync-rebase.prompt.md`, `.github/prompts/sync-align.prompt.md`

### Artifacts Updated

- Product Deck: não alterado.
- Service Deck: não alterado.
- Iteration Plan: não alterado.
- OBC: não alterado.
- BDD Feature: não alterada.
- Riscos: não alterados.

### Validation

- Mudança exclusivamente documental; sem código de aplicação e sem testes afetados.
- Links internos dos 10 arquivos alterados verificados — todos resolvem (`python3` check, saída 0).
- Sem renomeação de paths, sem quebra de contratos.

### Notes / Decision Trail

- O `align` não reescreve decisões de produto upstream: se o diff divergir de BDD/OBC em intenção (não só em detalhe), a divergência é registrada no Release Trail e sinalizada ao Finish, em conformidade com a regra de Context Rules do `AGENTS.md`.
- O `rebase` executa testes/lint apenas como smoke pós-integração (não quality gate); cobertura nova e correção de code smell herdado continuam sendo do Hack (Yellow Bar).

## 2026-07-13 — Refinamento da fase Hack: steps sequenciais + quality gates por ciclo (issue #9)

### Summary

Refinamento de processo/documentação da fase Hack (issue #9, `type:refinement`). Sem mudança em código de aplicação. Reestruturação em torno de três distinções:

- **Steps sequenciais vs. validações transversais.** `start → tdd → commit` permanecem sequenciais e independentemente invocáveis. Segurança, Qualidade e Documentação passam a ser explicitamente **transversais**, executadas no Yellow Bar de cada ciclo — não como steps extras.
- **Quality gates como critério de saída do ciclo.** Novo arquivo canônico `prodops/journeys/delivery/phases/hack/quality-gates.md` (+ `.en.md`) com o checklist mínimo para commitar (Green, lint 0, sem mock proibido, sem secrets/PII, Release Trail, artefatos ProdOps).
- **Referências de engenharia por step** (DDD, ProdOps TDD, Clean Code) linkadas em Red/Green/Yellow/commit.

### Artifacts Updated

- `prodops/journeys/delivery/phases/hack/README.md` (+ `.en.md`): seção "steps sequenciais vs. validações transversais"; terminologia padronizada em Red→Green→Yellow (antes "Refactor"); sequência reescrita em Red/Green/Yellow com validações transversais; referências por fase.
- `prodops/journeys/delivery/phases/hack/quality-gates.md` (+ `.en.md`): **novo arquivo**, checklist canônico do ciclo.
- `prodops/skills/hack/SKILL.md` (+ `.en.md`): tabela de quality gates obrigatórios (critério de saída do ciclo).
- `prodops/skills/hack/steps/tdd/SKILL.md` (+ `.en.md`): gates de Segurança e Qualidade explícitos no Yellow Bar; referências por fase; post-conditions atualizadas.
- `prodops/skills/references/engineering/tdd-prodops/quality-gates.md` (+ `.en.md`): Definition of Done deixa de duplicar e passa a apontar para o arquivo canônico de `phases/hack/`.
- `.github/prompts/hack-tdd.prompt.md`: prompt reforça a execução dos quality gates no Yellow Bar.

### Validation

- **TDD não aplicável:** a mudança é exclusivamente documental (Markdown), sem superfície de runtime — registrado aqui conforme a guardrail do hack skill ("If TDD is not applicable, record why in the Release Trail").
- Validações estilo Yellow Bar que se aplicam a docs, todas executadas:
  - Sem secrets/PII no diff (varredura no `git diff` — apenas ocorrências da palavra "secrets" na prosa dos próprios gates).
  - Todos os links relativos resolvem (checagem programática dos 11 arquivos alterados).
  - Terminologia consistente: ciclo padronizado em Yellow, não Refactor, nos arquivos da fase Hack.
  - Gêmeos pt/en em paridade (contagem de headings e links idêntica por par).
- Event Storming e arquitetura preservados — nenhum evento de domínio ou estrutura alterados.
