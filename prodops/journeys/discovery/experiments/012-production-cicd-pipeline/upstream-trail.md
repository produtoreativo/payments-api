# Experiment Upstream Trail — 012 Production CI/CD Pipeline

Referência:

`prodops/journeys/discovery/experiments/012-production-cicd-pipeline/experiment.md`

---

# History

---

## 2026-07-21 21:45

### Activity

Experimento concluído — pipeline de produção criado e arquivos corrigidos.

### Summary

Implementados todos os artefatos do EXP-012:

1. **`.github/workflows/deploy-production.yml`** criado — `workflow_dispatch` apenas,
   `environment: production` com Required Reviewers gate, build → DynamoDB deploy →
   Lambda deploy → smoke test em sequência.

2. **`api/samconfig.toml` bloco `[production]`** atualizado:
   - `DatadogEnabled=true` (estava `false`)
   - `DatadogSite`, `DatadogExtensionLayerArn`, `DatadogVersion` adicionados
   - `confirm_changeset=false` (gate é o GitHub Environment, não o SAM CLI)
   - Comentário sobre SAM CLI merging behavior documentado

3. **`.github/workflows/staging-deploy.yml`** corrigido:
   - `sam deploy` passou a usar todos os parâmetros explícitos na CLI
   - Removida dependência de `--config-env staging` para `--parameter-overrides`
   - Fix do problema identificado em EXP-010: `--parameter-overrides` na CLI
     substitui (não mergeia) `parameter_overrides` do samconfig.toml

### Artifacts Updated

- `.github/workflows/deploy-production.yml` — criado
- `api/samconfig.toml` — bloco `[production]` atualizado
- `.github/workflows/staging-deploy.yml` — deploy step corrigido
- `prodops/journeys/discovery/experiments/012-production-cicd-pipeline/experiment.md` — criado
- `prodops/journeys/discovery/experiments/012-production-cicd-pipeline/upstream-trail.md` — criado (este arquivo)
- `prodops/journeys/discovery/experiments.md` — entrada 012 adicionada

### Evidence

**Artefatos criados:**

```
.github/workflows/deploy-production.yml
  - trigger: workflow_dispatch (manual only)
  - gate: environment: production (Required Reviewers)
  - concurrency: production-deploy, cancel-in-progress: false
  - steps: validate secrets → OIDC auth → SAM build → DynamoDB deploy → Lambda deploy → smoke test
  - smoke tests: POST /invoices → 401, DELETE /invoices/:id → 401
```

**samconfig.toml production block antes/depois:**

```diff
- "DatadogEnabled=false",
+ "DatadogEnabled=true",
+ "DatadogSite=datadoghq.com",
+ "DatadogExtensionLayerArn=arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:97",
+ "DatadogVersion=5.111.0",
```

**staging-deploy.yml antes/depois do deploy step:**

```diff
- --config-env staging
- --parameter-overrides \
-   AsaasToken="..." \
-   AsaasWebhookToken="..." \
-   AdminSecret="..." \
-   DatadogApiKey="..."
+ --parameter-overrides \
+   EnvironmentName=staging \
+   AsaasMock=false \
+   AsaasUrl=https://api-sandbox.asaas.com \
+   EnabledPaymentProviders=ASAAS \
+   DefaultPaymentProvider=ASAAS \
+   WebhookProcessingMode=async \
+   DatadogEnabled=true \
+   DatadogSite=datadoghq.com \
+   DatadogExtensionLayerArn=... \
+   DatadogVersion=5.111.0 \
+   AsaasToken="..." \
+   AsaasWebhookToken="..." \
+   AdminSecret="..." \
+   DatadogApiKey="..."
```

### Decision

Pronto para Downstream — configurar GitHub Environment `production` e adicionar secrets.

### Notes

Configurações necessárias pelo usuário no GitHub (fora do escopo do repositório):

1. **Settings → Environments → New environment: `production`**
   - Enable "Required reviewers" → adicionar os aprovadores desejados

2. **Settings → Environments → production → Secrets:**
   - `PRODUCTION_ASAAS_TOKEN` — token Asaas da conta de PRODUÇÃO (LIVE API)
   - `PRODUCTION_ASAAS_WEBHOOK_TOKEN` — token de validação do webhook Asaas de produção
   - `PRODUCTION_ADMIN_SECRET` — secret do header X-Admin-Secret em produção
   - `PRODUCTION_DATADOG_API_KEY` — mesma API Key do staging (ou específica de produção)

3. Executar primeiro deploy via Actions → "Deploy to Production" → Run workflow
