# CI Async

CI Async é o agrupamento assíncrono do ProdOps Delivery. Representa o trabalho **conduzido pela plataforma, pipelines e ambientes**.

```
CI Async: Ship → Validate → Promote
```

## Propósito

CI Async produz:
- PR autônomo observado: merge confirmado e deploy em Staging bem-sucedido (Ship)
- Validação em runtime executada no ambiente de Staging (Validate)
- Feature promovida para Sandbox (Release Candidate) com evidência registrada (Promote)

## Ambientes

| Ambiente | Tipo | Fase responsável |
|---|---|---|
| Staging | Efêmero por Feature/OBC | Ship (observa deploy) e Validate (valida Feature) |
| Sandbox | Compartilhado (Release Candidate) | Promote (destino da promoção) |
| Production | Operacional | Fora da Delivery Journey |

## Responsabilidades por Ator

| Ator | Responsabilidade |
|---|---|
| **Finish** | Cria o PR autônomo (etapa final do CI Sync) |
| **GitHub** | Executa aprovação, merge e validações de proteção de branch |
| **GitHub Actions** | Executa pipelines de CI e deploy para Staging |
| **Ship** | Observa execução, emite Ship.Started e Ship.Completed, reage a falhas |
| **Validate** | Valida a Feature em execução no ambiente de Staging |
| **Promote** | Promove a Feature de Staging para Sandbox após Ship.Completed |

## Estágios

### Ship

Observa e orquestra o fluxo autônomo do PR criado pelo Finish — checks, aprovação, merge e deploy para Staging.

**Ship NÃO realiza deploy. Ship NÃO executa CI. Ship NÃO aprova o PR.**

Ship.Completed é emitido somente após merge confirmado **E** deploy em Staging concluído com sucesso.

→ [phases/ship/README.md](phases/ship/README.md)

### Validate

Verifica a Feature em execução no ambiente de Staging.

Capabilities: Smoke Tests, Runtime Contract Validation, Synthetic Monitoring, Health Checks, Observability Validation, SLO Validation, Business Validation, Incident Signals.

→ [phases/validate/README.md](phases/validate/README.md)

### Promote

Promove a Feature do ambiente de Staging para o ambiente de Sandbox (Release Candidate). Inicia somente após Ship.Completed.

**Promote NÃO publica em Production. Production está fora da Delivery Journey.**

Capabilities: Promotion Gates, Environment Promotion (Staging → Sandbox), Release Trail, Rollback Readiness.

→ [phases/promote/README.md](phases/promote/README.md)

## Capabilities utilizadas

| Capability | Estágio |
|---|---|
| [Evidence Management](capabilities/evidence-management.md) | Validate, Promote |
| [Observability](capabilities/observability.md) | Validate |
| [Reliability](capabilities/reliability.md) | Promote |
| [Contract Management](capabilities/contract-management.md) | Validate |
