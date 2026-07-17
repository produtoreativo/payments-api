# Global Upstream Trail

## Propósito

O Global Upstream Trail registra marcos de alto nível das atividades de engenharia exploratória.

Cada experimento possui seu histórico de execução em
`prodops/journeys/discovery/experiments/NNN-short-slug/upstream-trail.md`.

Este arquivo global existe para ajudar futuros colaboradores a enxergar a evolução Upstream do repositório sem precisar ler cada trail de experimento.

---

# Template de entrada

## YYYY-MM-DD HH:MM

### Experiment

Reference:

`prodops/journeys/discovery/experiments/NNN-short-slug/experiment.md`

### Activity

Descrever o que aconteceu.

Exemplos:

- Iniciado experimento
- Protótipo atualizado
- Prova de conceito implementada
- Validation Workbench atualizado
- Documentação do provedor revisada
- Reliability Plan atualizado
- Experimento concluído
- Estrutura do experimento migrada
- Experimento promovido para Downstream

### Summary

Um ou dois parágrafos resumindo o trabalho realizado.

### Artifacts Updated

Listar apenas os artefatos atualizados durante esta atividade.

Exemplo:

- Validation Workbench
- Reliability Plan
- Repository Tracking List
- OBC
- BDD Feature

### Decision

Escolher uma opção:

- Continuar experimento
- Iniciar outro experimento
- Pronto para Assessment
- Descartar experimento
- Avançar para Downstream
- Mudança de processo global

### Notes

Observações adicionais, bloqueios ou ações de acompanhamento.

---

# History

> Acrescentar novas entradas abaixo.
> Nunca reescrever entradas anteriores.

## 2026-07-07 — EXP-007

### Experiment

Reference:

`prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`

### Activity

Execução completa da atividade Upstream (modo exploratório) para o Intent "Suporte a Múltiplos Pagamentos no Checkout".

### Summary

Todas as 10 perguntas em aberto do Business Intent foram respondidas. O modelo de domínio atual (1:1:1 — 1 pedido : 1 invoice : 1 método) foi analisado e comparado com alternativas de composição. Benchmark de Stripe, Adyen, MercadoPago e Asaas confirmou que a Payments API precisa absorver a orquestração da composição, pois o Asaas não tem suporte nativo a múltiplos métodos por pedido.

A Opção A (múltiplas invoices por pedido com nova entidade `PaymentComposition`) foi selecionada por ser aditiva ao modelo atual e não quebrar pagamentos simples. Event Storming do novo fluxo identificou 7 novos eventos de domínio. OBC candidato foi criado. A única decisão pendente de produto é a política de falha parcial (A: reverter tudo / B: manter confirmados / C: janela parcial) — Política B é a recomendada.

### Artifacts Updated

- `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
- `prodops/journeys/discovery/experiments/007-split-payment-model/upstream-trail.md`
- `prodops/artifacts/business/obcs/payment-composition-draft.md`
- `prodops/journeys/discovery/upstream-trail.md`

### Decision

Pronto para Assessment — aguarda decisão de produto sobre política de falha parcial.

### Notes

Próximos passos após decisão de produto: criar BDD Feature `prodops/artifacts/business/bdd/payment-composition.feature`, atualizar Iteration Plan, Bootstrap → Hack.

## 2026-07-03 18:04

### Experiment

Reference:

`prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`

### Activity

Migração dos experimentos existentes para o padrão de diretório por experimento.

### Summary

Arquivos planos dos experimentos EXP-001, EXP-002, EXP-003 e EXP-005 foram movidos para `experiment.md` dentro de seus próprios diretórios de experimento. Cada um agora possui um `upstream-trail.md` local e um diretório `evidence/`.

O EXP-004 foi recuperado como registro de referência porque o trail global, o Reliability Plan e a Repository Tracking List o referenciavam, mas o arquivo plano do experimento original não estava presente no workspace.

### Artifacts Updated

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments/001-credit-card-lifecycle/upstream-trail.md`
- `prodops/upstream/experiments/002-sandbox-funding/experiment.md`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/experiment.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/upstream-trail.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/upstream-trail.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/upstream-trail.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/upstream-trail.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/journeys/discovery/features/README.md` (removido: diretório consolidado em `prodops/artifacts/business/bdd/`)

### Decision

Pronto para Assessment.

### Notes

A referência histórica a `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removido: sem sucessor em `prodops/artifacts/business/bdd/`) permanece como gap: o arquivo é referenciado por entradas do trail mas não está presente no workspace.

## 2026-07-03 17:58

### Experiment

Reference:

`prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`

### Activity

Alteração do padrão de trail Upstream para um trail por experimento.

### Summary

Experimentos Upstream agora têm um layout canônico de diretório: `experiment.md`, `upstream-trail.md` e `evidence/` opcional. O trail local do experimento é o registro cronológico de execução primário.

O `prodops/upstream/upstream-trail.md` global permanece apenas como índice cronológico de alto nível para marcos entre experimentos, migrações, promoções e mudanças de processo Upstream em nível de repositório.

### Artifacts Updated

- `AGENTS.md`
- `skills/upstream/SKILL.md`
- `prodops/upstream/README.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/experiments/README.md`
- `prodops/templates/discovery/experiment.md`
- `prodops/templates/discovery/trail.md`
- `prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`
- `prodops/upstream/experiments/006-upstream-trail-per-experiment/upstream-trail.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Pronto para Assessment.

### Notes

Arquivos planos de experimentos existentes foram migrados. Novos experimentos devem usar `prodops/journeys/discovery/experiments/NNN-short-slug/`.

## 2026-07-03 17:50

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Conversão do tratamento de webhooks Asaas para um caminho serverless assíncrono com fila.

### Summary

O template AWS/SAM agora provisiona `payments-webhook-queue` e `payments-webhook-dlq`. A Lambda Function URL HTTP atua como receptor: valida o token Asaas, enfileira a mensagem do webhook e retorna HTTP 200 rapidamente. Uma Lambda dedicada `webhook-worker` consome mensagens SQS e executa a lógica de domínio de confirmação de pagamento existente.

A simulação local agora valida o shape end-to-end criando uma invoice pela API, extraindo `providerPaymentId` e `externalReference` da resposta e enviando `PAYMENT_CONFIRMED` com esses valores, fazendo polling no DynamoDB LocalStack até que a invoice seja confirmada. O modo de depuração local NestJS continua disponível com `WEBHOOK_PROCESSING_MODE=sync`; o deploy SAM/LocalStack usa o modo assíncrono.

### Artifacts Updated

- `api/infra/lambda.yaml`
- `api/src/webhook-worker.ts`
- `api/src/modules/invoices/controllers/asaas-webhook.controller.ts`
- `api/src/modules/invoices/services/asaas-webhook-queue.service.ts`
- `api/src/modules/invoices/services/invoice.service.ts`
- `api/src/modules/invoices/invoices.module.ts`
- `api/scripts/deploy.sh`
- `api/scripts/start-sandbox-api.sh`
- `api/scripts/start-localstack-api.sh`
- `api/scripts/simulate-asaas-webhook.sh`
- `api/.env.example`
- `README.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Continuar experimento.

### Notes

Evidência de validação: verificações de sintaxe de shell passaram para os scripts atualizados, e `sam validate --lint` passou para `api/infra/lambda.yaml` e `api/infra/dynamodb.yaml`. Node/npm não estavam disponíveis neste shell, portanto o build NestJS e a execução LocalStack não foram executados aqui.

## 2026-07-03 17:45

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Configuração da validação local para usar DynamoDB LocalStack em vez de armazenamento em memória.

### Summary

O caminho AWS local agora tem um script de runtime explícito, `api/scripts/start-localstack-api.sh`, que inicia a API NestJS com `INVOICE_REPOSITORY=dynamo`, `DYNAMO_MOCK=false` e `AWS_DYNAMODB_ENDPOINT=http://localhost.localstack.cloud:4566`.

A simulação de webhook Asaas agora cria primeiro uma invoice pela API, extrai `providerPaymentId` e `externalReference` da resposta e depois envia `PAYMENT_CONFIRMED` com esses valores. Isso valida a mesma estrutura de correlação DynamoDB usada pelo webhook handler em vez de depender de estado em memória ou IDs de provedor hardcoded.

### Artifacts Updated

- `api/infra/lambda.yaml`
- `api/src/modules/invoices/controllers/asaas-webhook.controller.ts`
- `api/scripts/build.sh`
- `api/scripts/deploy.sh`
- `api/scripts/start-localstack-api.sh`
- `api/scripts/simulate-asaas-webhook.sh`
- `api/.env.example`
- `README.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Continuar experimento.

### Notes

Evidência de validação: verificações de sintaxe de shell passaram para os scripts atualizados, e `sam validate --lint` passou para `api/infra/lambda.yaml` e `api/infra/dynamodb.yaml`. Node/npm não estavam disponíveis neste shell, portanto o build NestJS e a simulação end-to-end não foram executados aqui.

## 2026-07-03 17:35

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Ajuste da infraestrutura AWS para operação orientada ao Free Tier.

### Summary

O template Lambda agora usa Lambda Function URL em vez de API Gateway, remove o Secrets Manager do gerenciamento da chave Datadog, aceita a chave da API Datadog como parâmetro `NoEcho` no momento do deploy e usa uma role Lambda personalizada sem permissões de CloudWatch Logs para evitar cobranças de ingestão/armazenamento de logs.

O template DynamoDB agora usa capacidade provisionada com 1 RCU e 1 WCU para cada tabela e GSI. Com as cinco tabelas e três GSIs atuais, o total é 8 RCU e 8 WCU, permanecendo dentro do envelope clássico de capacidade provisionada do Free Tier.

### Artifacts Updated

- `api/infra/lambda.yaml`
- `api/infra/dynamodb.yaml`
- `api/.env.example`
- `README.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/learnings.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Continuar experimento.

### Notes

Evidência de validação: `sam validate --lint --template-file api/infra/lambda.yaml` e `sam validate --lint --template-file api/infra/dynamodb.yaml` passaram.

## 2026-07-03 17:17

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Investigação e remoção do acoplamento com o Serverless Framework do caminho Datadog e runtime local.

### Summary

O repositório tinha dois modelos de deploy/runtime para observabilidade: AWS SAM em `api/infra/lambda.yaml` e um `api/serverless.yml` recém-adicionado com `serverless-plugin-datadog` e `serverless-offline`. O experimento confirmou que o Datadog pode permanecer implementado via `dd-trace`, logs estruturados e a bridge `payments.observability` existente, enquanto a configuração de deploy AWS fica no SAM.

As dependências/scripts do Serverless Framework foram removidos da declaração do pacote da API, `api/serverless.yml` foi removido e o SAM agora aceita parâmetros Datadog para ambiente, ARN do secret da API key no Secrets Manager e ARN da Datadog Lambda Extension layer. A execução local continua sendo o script sandbox NestJS com Datadog desabilitado por padrão.

### Artifacts Updated

- `api/package.json`
- `api/package-lock.json`
- `api/infra/lambda.yaml`
- `api/scripts/start-sandbox-api.sh`
- `README.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/learnings.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Pronto para Assessment.

### Notes

A validação automatizada não foi executada porque `node` e `npm` não estavam disponíveis neste shell. A validação externa remanescente é um deploy SAM com o ARN/versão da Datadog Extension layer da conta alvo e o secret do Secrets Manager.

## 2026-07-02 16:08

### Experiment

Reference:

`prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`

### Activity

Início do experimento após revisão do Current State, Repository Tracking List, Reliability Plan, Premortem, Iteration Plan e experimentos Upstream existentes.

### Summary

A incerteza de maior prioridade é a prontidão da Feature Flag do Checkout para o novo gateway Payments. A release aprovada depende da habilitação dessa rota, mas o flag permanece documentado como bloqueado por um bug no Checkout e não possui evidência de rollback para pedidos já iniciados no Payments.

Os experimentos existentes cobrem a incerteza de cartão de crédito e não cobrem essa dependência bloqueante de release, portanto um novo experimento Upstream foi criado.

### Artifacts Updated

- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/product/tracking-list.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/upstream/learnings.md`

### Decision

Continuar experimento.

### Notes

Próximo passo: coletar evidências do Checkout — bug exato da Feature Flag, responsável, status da correção, regras de targeting, auditabilidade, critérios de rollout/pausa/rollback, telemetria por pedido e tratamento de pedidos em andamento após rollback.

## 2026-07-02 16:40

### Experiment

References:

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments/002-sandbox-funding/experiment.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/experiment.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`

### Activity

Atualização das BDD Features para refletir os experimentos Upstream existentes.

### Summary

O BDD de cartão de crédito agora inclui confirmação hospedada, recebimento financeiro, restrições de cartão tokenizado, eventos de análise de risco, evidências de sandbox/simulação e a decisão de manter a captura direta de dados brutos de cartão fora do primeiro slice Downstream.

Uma nova BDD de prontidão da Feature Flag do Checkout foi adicionada para representar o aprendizado do EXP-004 como critérios de aceite executáveis para rollout, pausa, rollback, auditabilidade, pedidos em andamento e bloqueio de promoção.

### Artifacts Updated

- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrado: hoje `prodops/artifacts/business/bdd/credit-card-payment.feature`)
- `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removido: sem sucessor em `prodops/artifacts/business/bdd/`)

### Decision

Continuar experimento.

### Notes

Essas features são insumos BDD para trabalho futuro de TDD/Downstream. Elas não promovem as capabilities por si mesmas.

## 2026-07-02 17:10

### Experiment

References:

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/experiment.md`

### Activity

Atualização do código da Payments API de acordo com o escopo executável dos experimentos de cartão de crédito.

### Summary

A API agora torna explícito o primeiro slice de cartão de crédito: `CREDIT_CARD` é tratado como checkout hospedado e rejeita campos de dados de cartão tokenizado ou direto em `POST /invoices`. Isso impede que os experimentos de cartão tokenizado/direto se tornem silenciosamente comportamento de produção não suportado.

O tratamento de webhooks agora registra eventos Asaas específicos de cartão — como autorização, análise de risco e recusa de captura — como eventos observáveis de cartão. Eventos de autorização e análise de risco não publicam `payment.confirmed`; recusa de captura e reprovação por risco marcam a invoice como falha quando o pagamento ainda não foi confirmado ou recebido.

### Artifacts Updated

- `api/src/modules/invoices/dto/create-invoice.dto.ts`
- `api/src/modules/invoices/services/invoice.service.ts`
- `api/test/create-invoice.acceptance.e2e-spec.ts` (renomeado: hoje `api/test/criar-invoice.e2e-spec.ts`)

### Decision

Pronto para Assessment.

### Notes

Evidência de validação: `npm run test:acceptance` em `api/` passou com 26 testes.

## 2026-07-02 17:48

### Experiment

Reference:

`prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`

### Activity

Expansão do experimento de lifecycle de cartão de crédito Asaas para cobrir contratos Cart/Checkout para Payments, listagem de cartões salvos, cadastro de novo cartão, fronteira de tokenização e exploração no Validation Workbench.

### Summary

O experimento agora separa checkout hospedado, pagamento com cartão salvo e submissão de novo cartão. O checkout hospedado continua sendo o candidato Downstream mais seguro. Os fluxos de cartão salvo e novo cartão permanecem em Upstream até que Produto, Segurança e Arquitetura decidam sobre armazenamento de token, propriedade, consentimento, fronteira PCI, tratamento de `remoteIp` e política de reembolso.

O Validation Workbench agora permite que agentes e humanos explorem os shapes de payload para cartão hospedado, cartão salvo e novo cartão, incluindo cadastro local descartável de cartão e simulação de webhook para autorização, análise de risco, confirmação, recusa, cancelamento e reembolso.

### Artifacts Updated

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/learnings.md`
- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrado: hoje `prodops/artifacts/business/bdd/credit-card-payment.feature`)
- `prodops/product/tracking-list.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/upstream/obcs/credit-card-authorization-confirmation.md`
- `validation-workbench/src/App.tsx`
- `validation-workbench/src/styles.css`

### Decision

Continuar experimento.

### Notes

Recomendação: avançar apenas o checkout hospedado para Assessment. Manter reutilização de cartão salvo e cadastro de novo cartão em Upstream até que as decisões de armazenamento de token, fronteira PCI, consentimento e reembolso estejam registradas.

## 2026-07-07

### Experiments

- EXP-003: `prodops/journeys/discovery/experiments/003-hosted-vs-tokenized/experiment.md`
- EXP-001: `prodops/journeys/discovery/experiments/001-credit-card-lifecycle/experiment.md`

### Activity

Move-to-delivery: hosted card slice promoted to Downstream.

### Decision

PM approved. OBC and BDD Feature moved to committed locations. Iteration Plan updated. Hosted card slice enters Downstream delivery flow.

## 2026-07-08

### Activity

Normalized ProdOps framework operational paths and executable skills.

### Summary

The framework now has an explicit canonical path map and the primary executable
skills point to the current `prodops/artifacts/` and `prodops/journeys/`
structure instead of migrated legacy paths. Discovery instructions now create
new experiments under `prodops/journeys/discovery/experiments/`, root
Upstream templates are marked as legacy, and Bootstrap is available as a
first-class Delivery skill.

A lightweight `prodops/scripts/doctor.sh` check was added to verify required
ProdOps paths, experiment layout, and accidental legacy path references in
operational documents.

### Artifacts Updated

- `AGENTS.md`
- `prodops/README.md`
- `prodops/framework/canonical-paths.md`
- `prodops/framework/glossary.md`
- `prodops/framework/principles.md`
- `prodops/journeys/discovery/README.md`
- `prodops/journeys/discovery/experiments.md`
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/journeys/delivery/capabilities/`
- `prodops/journeys/operation/runbooks.md`
- `prodops/skills/`
- `prodops/scripts/doctor.sh`
- `templates/upstream-*.md`

### Evidence

- `prodops/scripts/doctor.sh` passed.
- `rg` check found no legacy ProdOps path references in operational docs outside
  explicitly excluded historical trails and the canonical legacy mapping.

### Decision

Continue using the `prodops/journeys/` and `prodops/artifacts/` structure as the
operational source of truth.

### Notes

Historical trails may still mention legacy paths as migration evidence. New
operational instructions should use `prodops/framework/canonical-paths.md`.
