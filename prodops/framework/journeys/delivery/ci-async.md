# CI Async

CI Async é o agrupamento assíncrono do ProdOps Delivery. Representa o trabalho **conduzido pela plataforma, pipelines e ambientes**.

```
CI Async: Ship → Validate → Promote
```

## Propósito

CI Async produz:
- Artefato produzido e publicado
- Deploy realizado no ambiente alvo
- Validação em runtime executada
- Promoção controlada com evidência registrada

## Estágios

### Ship

Transforma a implementação em artefato executável e conduz o deploy.

Duas famílias:
- **Preparation:** Build, Package, Version, Sign, SBOM, Publish Artifact
- **Deployment:** Deploy, Progressive Delivery, Feature Flags, Rollout, Rollback, Infrastructure Validation

Build, Package e Publish são capabilities internas do Ship — não são estágios independentes.

→ [phases/ship/README.md](phases/ship/README.md)

### Validate

Verifica a entrega em execução no ambiente alvo.

Capabilities: Smoke Tests, Runtime Contract Validation, Synthetic Monitoring, Health Checks, Observability Validation, SLO Validation, Business Validation, Incident Signals.

→ [phases/validate/README.md](phases/validate/README.md)

### Promote

Oficializa a evolução da versão com aprovação formal e evidência registrada.

Capabilities: Promotion Gates, Environment Promotion, Release Approval, Release Trail, Operational Evidence, Release Documentation, Rollback Readiness.

→ [phases/promote/README.md](phases/promote/README.md)

## Capabilities utilizadas

| Capability | Estágio |
|---|---|
| [Evidence Management](capabilities/evidence-management.md) | Validate, Promote |
| [Observability](capabilities/observability.md) | Validate |
| [Reliability](capabilities/reliability.md) | Promote |
| [Contract Management](capabilities/contract-management.md) | Validate |
