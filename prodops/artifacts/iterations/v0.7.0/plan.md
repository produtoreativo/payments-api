# Iteration Plan — v0.7.0 (Ativo)

> Status: 🔄 Em andamento

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status |
|---|---|---|---|---|---|---|---|
| DS-44 | #115 | dependency-security-update: eliminar vulnerabilidades Dependabot (14H/11M/2L em 9 pacotes) | — | ✓ | ✓ | ✓ | Entrou |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.7.0 |
|---|---|---|
| DS-44 | dependency-security-update | #115 |

## Critérios de saída

- [ ] PR merged em `master` para DS-44
- [ ] `prodops.delivery.promote.completed` emitido para a issue de DS-44
- [ ] 0 alertas Dependabot com severity `critical` ou `high` em estado `open`
- [ ] Test suite 100% verde após atualização de dependências
- [ ] Issue de DS-44 fechada no GitHub

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.7.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
