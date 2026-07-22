# OBC - Pipeline de CI/CD para Produção com Gate de Aprovação

## Status

Downstream. Status `Entrou` em `prodops/artifacts/governance/plans/iteration-plan.md` — capacidade operacional derivada do EXP-012.

## Business Outcome

Todo deploy em produção da Payments API requer aprovação humana explícita de um revisor designado e deixa rastro auditável no GitHub Actions com nome do aprovador, timestamp, commit e motivo do deploy. Não existe caminho de deploy em produção que contorne esse gate. O tempo entre um commit aprovado e o ambiente de produção atualizado é mensurável e controlado.

### Em linguagem executiva

Antes, produção era atualizada manualmente via terminal: qualquer pessoa com credenciais AWS podia fazer um deploy sem aprovação, sem registro e sem rollback automático. Agora, deploy em produção é como assinar um cheque de alto valor — exige uma segunda assinatura, fica registrado, e o sistema recusa qualquer tentativa de bypass.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `cicd.deploy.requested` | Workflow de produção disparado — aguardando aprovação do Required Reviewer. | `actor`, `commit_sha`, `branch`, `reason` |
| `cicd.deploy.approved` | Deploy aprovado pelo Required Reviewer e iniciado. | `approver`, `actor`, `commit_sha`, `timestamp` |
| `cicd.deploy.completed` | Deploy de produção concluído com sucesso — smoke tests passaram. | `commit_sha`, `api_url`, `stack_name`, `duration_seconds` |
| `cicd.deploy.smoke_passed` | Smoke tests pós-deploy validaram que a API está respondendo e o auth guard está ativo. | `api_url`, `http_status` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Deploys em produção que passaram pelo gate de Required Reviewer. | 100% |
| Deploys em produção com rastro auditável (aprovador + commit + motivo). | 100% |
| Smoke tests pós-deploy passando antes de marcar deploy como concluído. | 100% |
| Secrets de produção armazenados no GitHub Environment — nunca em samconfig.toml ou código. | 100% |
| Deploys acidentais por push em branch (sem workflow_dispatch). | 0 |

## Reliability Rules

- O workflow `deploy-production.yml` só pode ser disparado via `workflow_dispatch` — nunca por push automático em qualquer branch.
- O job de deploy fica bloqueado até aprovação explícita do Required Reviewer configurado no GitHub Environment `production`.
- `cancel-in-progress: false` — deploys em andamento nunca são cancelados por um novo trigger.
- Todos os parâmetros não-secret (EnvironmentName, DatadogEnabled, etc.) devem ser passados explicitamente na CLI do `sam deploy` — não confiar no merge automático do `samconfig.toml` (SAM CLI substitui, não mergeia, `--parameter-overrides`).
- Secrets (`AsaasToken`, `AdminSecret`, `DatadogApiKey`) são injetados apenas via GitHub Environment secrets — nunca armazenados em `samconfig.toml`.
- O smoke test valida que o auth guard retorna 401 antes de marcar o deploy como concluído.
- A role OIDC `payments-api-github-deploy` é definida em `api/infra/iam-deploy-role.yaml` — qualquer mudança de permissão passa por PR e deploy CloudFormation.

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/production-cicd-pipeline.feature`
- Experiment: `prodops/journeys/discovery/experiments/012-production-cicd-pipeline/experiment.md`
- IaC: `api/infra/iam-deploy-role.yaml`, `.github/workflows/deploy-production.yml`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- OBCs relacionados: `prodops/artifacts/business/obcs/observability-datadog.md`, `prodops/artifacts/business/obcs/dynamodb-optimization.md`
