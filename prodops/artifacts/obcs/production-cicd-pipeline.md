# OBC - Pipeline de CI/CD para Produção com Gate de Aprovação

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-48 |
| Iteração | v0.9.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-48 (#46) — v0.9.0, PR #120. Registro anterior: Downstream. Status `Entrou` em `prodops/artifacts/plans/iteration-plan.md` — capacidade operacional derivada do EXP-012.
**Pendência:** iteração concluída (PR #120); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-004](../business-signals/BS-004.md) |
| Business Intent | [PI-012](../business-intents/PI-012.md) |
| Product Tracking Item | issue #46 (DS-48), ver `prodops/artifacts/plans/iteration-plan.md` |
| Experimento | [EXP-012](../experiments/012-production-cicd-pipeline/experiment.md) |

## Business Outcome

Todo deploy em produção da Payments API requer aprovação humana explícita de um revisor designado e deixa rastro auditável no GitHub Actions com nome do aprovador, timestamp, commit e motivo do deploy. Não existe caminho de deploy em produção que contorne esse gate. O tempo entre um commit aprovado e o ambiente de produção atualizado é mensurável e controlado.

### Em linguagem executiva

Antes, produção era atualizada manualmente via terminal: qualquer pessoa com credenciais AWS podia fazer um deploy sem aprovação, sem registro e sem rollback automático. Agora, deploy em produção é como assinar um cheque de alto valor — exige uma segunda assinatura, fica registrado, e o sistema recusa qualquer tentativa de bypass.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/production-cicd-pipeline.feature`; marcar após verificação.

- [ ] Deploy em producao requer aprovacao do Required Reviewer
- [ ] Deploy nao e acionado por push automatico
- [ ] Deploy aprovado conclui com smoke tests passando
- [ ] Secrets de producao nunca aparecem no samconfig.toml
- [ ] Dois deploys simultaneos nao sao permitidos
- [ ] Mudanca na role IAM exige PR e deploy CloudFormation

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | n/a — capacidade de plataforma/framework, não é Product Service |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `cicd.deploy.requested` | [apurar] | Workflow de produção disparado — aguardando aprovação do Required Reviewer. | `actor`, `commit_sha`, `branch`, `reason` |
| `cicd.deploy.approved` | [apurar] | Deploy aprovado pelo Required Reviewer e iniciado. | `approver`, `actor`, `commit_sha`, `timestamp` |
| `cicd.deploy.completed` | [apurar] | Deploy de produção concluído com sucesso — smoke tests passaram. | `commit_sha`, `api_url`, `stack_name`, `duration_seconds` |
| `cicd.deploy.smoke_passed` | [apurar] | Smoke tests pós-deploy validaram que a API está respondendo e o auth guard está ativo. | `api_url`, `http_status` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Deploys em produção que passaram pelo gate de Required Reviewer. | 100% | [apurar] |
| Deploys em produção com rastro auditável (aprovador + commit + motivo). | 100% | [apurar] |
| Smoke tests pós-deploy passando antes de marcar deploy como concluído. | 100% | [apurar] |
| Secrets de produção armazenados no GitHub Environment — nunca em samconfig.toml ou código. | 100% | [apurar] |
| Deploys acidentais por push em branch (sem workflow_dispatch). | 0 | [apurar] |

## Reliability Rules

- O workflow `deploy-production.yml` só pode ser disparado via `workflow_dispatch` — nunca por push automático em qualquer branch.
- O job de deploy fica bloqueado até aprovação explícita do Required Reviewer configurado no GitHub Environment `production`.
- `cancel-in-progress: false` — deploys em andamento nunca são cancelados por um novo trigger.
- Todos os parâmetros não-secret (EnvironmentName, DatadogEnabled, etc.) devem ser passados explicitamente na CLI do `sam deploy` — não confiar no merge automático do `samconfig.toml` (SAM CLI substitui, não mergeia, `--parameter-overrides`).
- Secrets (`AsaasToken`, `AdminSecret`, `DatadogApiKey`) são injetados apenas via GitHub Environment secrets — nunca armazenados em `samconfig.toml`.
- O smoke test valida que o auth guard retorna 401 antes de marcar o deploy como concluído.
- A role OIDC `payments-api-github-deploy` é definida em `api/infra/iam-deploy-role.yaml` — qualquer mudança de permissão passa por PR e deploy CloudFormation.

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| — | [apurar] | [apurar] |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/production-cicd-pipeline.feature`
- Experiment: `prodops/artifacts/experiments/012-production-cicd-pipeline/experiment.md`
- IaC: `api/infra/iam-deploy-role.yaml`, `.github/workflows/deploy-production.yml`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- OBCs relacionados: `prodops/artifacts/obcs/observability-datadog.md`, `prodops/artifacts/obcs/dynamodb-optimization.md`
