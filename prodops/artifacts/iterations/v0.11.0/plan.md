# Iteration Plan — v0.11.0

> Status: 🟡 Planejada — aguardando Bootstrap

## Objetivo

Implementar o mecanismo de distribuição do ProdOps Framework — export, install, sync e CI — para que qualquer repositório produto possa adotar e manter o Framework atualizado a partir do repositório canônico `prodops-framework`.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status |
|---|---|---|---|---|---|---|---|
| DS-53 | #130 | prodops-framework-export: script de extração canônica do Framework | — | ✓ | ✓ | ✓ | Entrou |
| DS-54 | #131 | prodops-framework-install: script de instalação em repo consumidor | DS-53 | ✓ | ✓ | ✓ | Entrou |
| DS-55 | #132 | prodops-framework-sync: script de atualização respeitando .prodopsignore | DS-54 | ✓ | ✓ | ✓ | Entrou |
| DS-56 | #133 | prodops-framework-ci: workflows de propagação automática de releases | DS-55 | ✓ | ✓ | ✓ | Entrou |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.11.0 |
|---|---|---|
| DS-53 | prodops-framework-export | #130 |
| DS-54 | prodops-framework-install | #131 |
| DS-55 | prodops-framework-sync | #132 |
| DS-56 | prodops-framework-ci | #133 |

## Sequência de entrega

DS-53 → DS-54 → DS-55 → DS-56 (sequencial — cada camada depende da anterior)

## Critérios de saída

- [ ] PR merged para DS-53 — `export-framework.sh` funcional + v0.1.0 publicada no `prodops-framework`
- [ ] PR merged para DS-54 — `install-prodops.sh` funcional
- [ ] PR merged para DS-55 — `sync-from-framework.sh` funcional
- [ ] PR merged para DS-56 — workflows `notify-consumers.yml` + `sync-prodops.yml` funcionais
- [ ] `prodops.delivery.promote.completed` emitido para cada issue
- [ ] Issues #130, #131, #132, #133 fechadas no GitHub
- [ ] `framework-lock.yaml` do payments-api atualizado: `status: consumer`, versão e mecanismo preenchidos

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.11.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
