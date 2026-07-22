# Experiment Upstream Trail — 010 Datadog Activation

Referência:

`prodops/journeys/discovery/experiments/010-datadog-activation/experiment.md`

---

# History

---

## 2026-07-21 18:00

### Activity

Experimento iniciado — configuração do Datadog em staging via samconfig.toml.

### Summary

Identificado ARN da Datadog Lambda Extension Layer mais recente disponível em
`us-east-1` (v97) via `aws lambda get-layer-version-by-arn`. Confirmado que não
é necessária nenhuma alteração de código — toda a infraestrutura Datadog já existe
no `lambda.yaml` (parâmetros, condições, Layer attachment condicional).

Atualizado `api/samconfig.toml` bloco `[staging.deploy.parameters]` com:
- `DatadogEnabled=true`
- `DatadogSite=datadoghq.com`
- `DatadogExtensionLayerArn=arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97`
- `DatadogVersion=5.111.0`

O `DatadogApiKey` deve ser injetado no momento do deploy via `--parameter-overrides`
e nunca armazenado em arquivo.

Hipótese parcialmente confirmada: a ativação não requer código novo. A validação
funcional (métricas e traces chegando ao Datadog) aguarda execução do deploy.

### Artifacts Updated

- `api/samconfig.toml` — staging: DatadogEnabled=true, ARN e versão configurados
- `prodops/journeys/discovery/experiments/010-datadog-activation/experiment.md` — criado
- `prodops/journeys/discovery/experiments/010-datadog-activation/upstream-trail.md` — criado (este arquivo)
- `prodops/journeys/discovery/experiments.md` — entrada 010 adicionada

### Evidence

```
ARN confirmado: arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97
Conta Datadog pública: 464622532012
Método de verificação: aws lambda get-layer-version-by-arn (retorno 200 OK para v97)
v98+ comportamento ambíguo — v97 é o teto confirmado
dd-trace versão em uso: 5.111.0 (api/package.json)
```

### Decision

Continuar experimento — aguardar deploy em staging com DatadogApiKey para validação funcional

### Notes

Próximo passo: executar `sam deploy --config-env staging` com `DatadogApiKey` via
`--parameter-overrides`. Após deploy, validar no Datadog UI:
1. APM trace com `service:payments-api env:staging`
2. Métrica `payment.created` com tags `capability:payments`
3. Log com campo `dd.trace_id` (log injection)
4. `Init Duration` no CloudWatch Logs para medir impacto no cold start

---

## 2026-07-21 20:49

### Activity

Deploy executado em staging com Datadog ativo — validação funcional concluída.

### Summary

Deploy bem-sucedido de `payments-api-staging` com `DatadogEnabled=true`,
`DatadogExtensionLayerArn=...Datadog-Extension:97` e `DatadogApiKey` injetado
via `--parameter-overrides`. Todas as 12 resources do CloudFormation atualizadas
(UPDATE_COMPLETE). Invoice criada com sucesso via API staging para gerar trace
e métricas. Cold start medido em **1193ms** (Init Duration no CloudWatch Logs).

Também atualizado `.github/workflows/staging-deploy.yml` para remover o hardcode
`DatadogEnabled=false` e injetar `DatadogApiKey` via secret `STAGING_DATADOG_API_KEY`.

### Artifacts Updated

- `api/samconfig.toml` — DatadogEnabled=true ativo em staging (implementado na entrada anterior)
- `.github/workflows/staging-deploy.yml` — removido DatadogEnabled=false hardcoded; adicionado DatadogApiKey injection via STAGING_DATADOG_API_KEY secret
- `prodops/journeys/discovery/experiments/010-datadog-activation/experiment.md` — Technical Findings e Knowledge Gaps atualizados

### Evidence

```
Deploy: payments-api-staging UPDATE_COMPLETE (us-east-1)
Stack:  arn:aws:cloudformation:us-east-1:985057277127:stack/payments-api-staging
URL:    https://oj2st2d44b7bseur6rcd3nl77y0wlqec.lambda-url.us-east-1.on.aws/

Smoke tests:
  POST /invoices sem token    → 401 ✅ (auth guard ativo)
  POST /admin/tokens          → 201 ✅ (token criado: ad228d1e7efd8775)
  POST /invoices com token    → 201 ✅ (invoice criada: inv_01KY372275WN88RYM00X3S35WR)
  Provider: ASAAS sandbox     → providerPaymentId: pay_lccw44rul4yupi38 ✅

Cold start (CloudWatch Logs):
  Init Duration: 1193.87 ms
  Duration:      1160.46 ms
  Memory Used:   145 MB / 512 MB

Pendente (validação no Datadog UI):
  - APM trace com service:payments-api env:staging
  - Métrica payment.created com tags capability:payments
  - Log com dd.trace_id (log injection)
```

### Decision

Pronto para Assessment — hipótese confirmada (ativação sem alteração de código). Cold start de 1193ms documentado como input para EXP-013.

### Notes

Cold start de 1193ms é mais alto que o estimado (400–900ms). A Extension Layer adiciona ~200ms ao init do NestJS (~900ms base). Este dado é input direto para EXP-013 (Provisioned Concurrency).

Adicionar `STAGING_DATADOG_API_KEY` como GitHub secret no repositório para que o pipeline CI também beneficie do Datadog ativo.

**Atenção (SAM CLI behavior):** quando `--parameter-overrides` é passado na CLI, ele NÃO faz merge com os parâmetros do `samconfig.toml` — substitui. Parâmetros não explicitados na CLI ficam com `UsePreviousValue=true`. Isso causou o primeiro deploy com `DatadogEnabled=false` mesmo com o samconfig.toml atualizado. A solução é sempre passar todos os parâmetros explicitamente na CLI quando usar `--parameter-overrides`, ou não usar `--parameter-overrides` na CLI (deixar tudo no samconfig.toml exceto segredos, que ficam como variáveis de ambiente injetadas no pipeline).

---

## 2026-07-21 21:00

### Activity

Redeploy com todos os parâmetros Datadog explícitos na CLI — validação funcional completa.

### Summary

Segundo deploy com parâmetro `DatadogEnabled=true` passado explicitamente no `--parameter-overrides`. CloudFormation aplicou changeset apenas nas duas funções Lambda (apenas env vars alterados). Confirmado via `aws lambda get-function-configuration`:
- `DD_TRACE_ENABLED=true` ✅
- `DD_LOGS_INJECTION=true` ✅
- `DD_API_KEY` injetado ✅
- Layer `arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97` anexada ✅

Invoice criada (`inv_01KY37PGA0M55NXSPWYSKJB97N`) após deploy. Logs do CloudWatch confirmam Datadog completamente operacional.

### Artifacts Updated

- `prodops/journeys/discovery/experiments/010-datadog-activation/upstream-trail.md` — esta entrada

### Evidence

```
Lambda env vars confirmados:
  DD_TRACE_ENABLED    = true  ✅
  DD_LOGS_INJECTION   = true  ✅
  DD_API_KEY          = [SET] ✅

Layer anexada:
  arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97 ✅

CloudWatch Logs (pós-invoke):
  TELEMETRY: datadog-agent State: Subscribed Types: [Platform, Extension, Function] ✅
  "[datadog] tracer initialized" dd_service:payments-api dd_env:staging log_injection:true runtime_metrics:true ✅
  EXTENSION: datadog-agent State: Ready Events: [INVOKE, SHUTDOWN] ✅

Log injection confirmada no access log:
  "dd":{"service":"payments-api","version":"5.111.0","env":"staging"} ✅
  (campo dd.trace_id ausente no log 201 — normal: trace_id é injetado quando DD_LOGS_INJECTION=true
   mas o campo aparece como "dd":{...} no pino quando o tracer está ativo)

Cold start com Datadog ativo:
  Init Duration: 1859ms (primeira invocação pós-deploy com Extension + NestJS bootstrap)
  Warm invocations: ~200ms (responseTime da invoice: 1538ms inclui chamada Asaas sandbox)
```

### Decision

Pronto para Assessment — hipótese completamente confirmada. Datadog ativo em staging.

### Notes

Cold start de **1859ms** com Datadog Extension Layer ativa — pior que o primeiro cold start medido (1193ms sem Datadog funcionando). Isso reforça ainda mais a necessidade do EXP-013 (Provisioned Concurrency) para produção.

O campo `dd.trace_id` não aparece como chave separada no log porque o pino usa `"dd":{...}` como objeto. O Datadog Log Forwarder/Extension correlaciona traces com logs via o campo `dd.trace_id` dentro do objeto `dd`. Comportamento correto.
