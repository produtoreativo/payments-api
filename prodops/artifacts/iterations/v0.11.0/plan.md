# Iteration Plan — v0.11.0

> Status: ✅ Concluído — 2026-08-04

## Objetivo

Implementar o mecanismo de distribuição do ProdOps Framework — export, install, sync e CI — para que qualquer repositório produto possa adotar e manter o Framework atualizado a partir do repositório canônico `prodops-framework`.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-53 | #130 | prodops-framework-export: script de extração canônica do Framework | — | ✓ | ✓ | ✓ | Concluído | #136 |
| DS-54 | #131 | prodops-framework-install: script de instalação em repo consumidor | DS-53 | ✓ | ✓ | ✓ | Concluído | #137 |
| DS-55 | #132 | prodops-framework-sync: script de atualização respeitando .prodopsignore | DS-54 | ✓ | ✓ | ✓ | Concluído | #138 |
| DS-56 | #133 | prodops-framework-ci: workflows de propagação automática de releases | DS-55 | ✓ | ✓ | ✓ | Concluído | #139 |

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

- [x] PR merged para DS-53 — `export-framework.sh` funcional (PR #136) — nota: v0.1.0 publicada no `prodops-framework` requer ação externa (abertura do PR pelo script + aprovação/merge no repo canônico)
- [x] PR merged para DS-54 — `install-prodops.sh` funcional (PR #137)
- [x] PR merged para DS-55 — `sync-from-framework.sh` funcional (PR #138)
- [x] PR merged para DS-56 — workflows `notify-consumers.yml` + `sync-prodops.yml` funcionais (PR #139)
- [x] `prodops.delivery.promote.completed` emitido para cada issue (#130, #131, #132, #133)
- [x] Issues #130, #131, #132, #133 fechadas no GitHub
- [ ] `framework-lock.yaml` do payments-api atualizado: `status: consumer`, versão e mecanismo preenchidos — exceção: payments-api é o repositório fonte (status: self). O framework-lock.yaml de repositórios consumidores é gerado pelo `install-prodops.sh`. Nenhum repositório consumidor externo foi onboarded nesta iteração.

### Nota de fechamento

Critério 7 não cumprido conforme especificado literalmente: o `payments-api` mantém `status: self` no framework-lock.yaml por ser o repositório canônico fonte. O critério aplica-se a repositórios consumidores que executem `install-prodops.sh`. A publicação de v0.1.0 no `prodops-framework` requer ação externa (executar `export-framework.sh` + review/merge do PR gerado). Follow-up registrado em issue de rastreamento.

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.11.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
