# CI Sync

CI Sync é o agrupamento síncrono do ProdOps Delivery. Representa o trabalho **local, colaborativo e conduzido pelo engenheiro**.

```
CI Sync: Bootstrap → Hack → Sync → Finish
```

## Propósito

CI Sync produz:
- Task fechada
- PR com narrativa da implementação
- Evidências de testes e lint
- Commits organizados seguindo Conventional Commits
- Validações locais executadas

## Estágios

### Bootstrap

Prepara o ambiente, cria a branch e estabelece o contexto de produto. Não produz código — produz contexto.

Saída: branch limpa + ambiente pronto + artefatos ProdOps lidos + contrato verificado.

→ [phases/bootstrap/README.md](phases/bootstrap/README.md)

### Hack

Implementa com ProdOps TDD: Red Bar → Green Bar → Refactor → Commit.

Consome:
- **Prática:** [ProdOps TDD](practices/prodops-tdd.md)
- **Capability:** [Commit Workflow](capabilities/commit-workflow/README.md)

→ [phases/hack/README.md](phases/hack/README.md)

### Sync

Dois steps independentes:

- **rebase** — sincroniza a feature branch com a base (fetch, integração, conflitos, validação)
- **align** — alinha artefatos ProdOps com a implementação (BDD Feature, Event Storming, arquitetura, Release Trail)

→ [phases/sync/README.md](phases/sync/README.md)

### Finish

Executa Quality Gates finais e cria o PR com evidências.

→ [phases/finish/README.md](phases/finish/README.md)

## Capabilities utilizadas

| Capability | Estágio |
|---|---|
| [Commit Workflow](capabilities/commit-workflow/README.md) | Hack, Sync, Finish |
| [Contract Management](capabilities/contract-management.md) | Bootstrap, Hack, Sync |
| [Evidence Management](capabilities/evidence-management.md) | Hack, Finish |
| [Observability](capabilities/observability.md) | Hack |
| [Reliability](capabilities/reliability.md) | Bootstrap, Hack, Finish |
