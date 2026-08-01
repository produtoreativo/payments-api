# Card: production-cicd-pipeline

Date: 2026-08-01

## Runtime Context

```
ds-id:              DS-48
work-item-id:       46
iteration-id:       v0.9.0
iteration-dir:      prodops/artifacts/iterations/v0.9.0/
correlation-id:     adf3a500-e8f5-4fcb-9a2e-2a63e5be6d26
actor-player:       claude
```

## Runtime Paths

```
feature-branch:       feat/46-production-cicd-pipeline
base-branch:          master
session-trail-dir:    prodops/artifacts/iterations/v0.9.0/trails/
obc-path:             prodops/artifacts/obcs/production-cicd-pipeline.md
bdd-path:             prodops/artifacts/bdd/production-cicd-pipeline.feature
```

## Flow State

```
pr-number:      120
infra-scope:    none
oem-state:      PENDING
```

## OBC Summary

Pipeline CI/CD para producao com gate de aprovacao humana. Todos os deploys em
producao requerem aprovacao explicita via GitHub Environment `production` com
Required Reviewers. OIDC keyless auth — sem credenciais de longa vida no repo.

## BDD

- 6/6 cenarios estruturais verificados pelo TDD agent
- Artefatos pre-existentes: EXP-012 (commit b5859c5)

## Implementation Notes

- `.github/workflows/deploy-production.yml` — pipeline com `workflow_dispatch` trigger,
  GitHub Environment gate (`production`), required reviewers, OIDC-based AWS deploy
- `api/infra/iam-deploy-role.yaml` — IAM role CloudFormation template
- `api/samconfig.toml` — SAM config com bloco `[production.deploy.parameters]`
