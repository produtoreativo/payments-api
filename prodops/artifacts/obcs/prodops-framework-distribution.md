# OBC - ProdOps Framework Distribution

## Status

Committed. Business Intent: POPS-ICE-001. Business Signal: #129. Iteration Plan: v0.11.0 — DS-53 · DS-54 · DS-55 · DS-56.

## Business Outcome

Qualquer repositório produto pode adotar o ProdOps Framework a partir do repositório canônico `prodops-framework` e receber atualizações de forma automatizada, rastreável e segura — sem risco de sobrescrever artefatos locais do produto e com evidência de cada versão instalada.

O mecanismo opera em 4 camadas sequenciais: Export (extração canônica do framework), Install (adoção por novos repositórios), Sync (atualização de repositórios existentes) e CI (propagação automática de novas releases).

### Em linguagem executiva

Hoje o ProdOps Framework evolui no `payments-api` e qualquer equipe que queira adotá-lo precisa copiar manualmente os arquivos — sem saber o que copiar, sem garantia de integridade e sem como receber melhorias futuras. Este trabalho cria o equivalente a um instalador e um mecanismo de atualização: instala uma vez, atualiza automaticamente quando o framework evolui, nunca sobrescreve o trabalho do produto.

## Premortem

Riscos identificados antes do início da Delivery:

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Export script sobrescreve áreas do consumidor (`artifacts/`, `skills/local/`) | Alta sem controle | Crítico — perda de artefatos do produto | `.prodopsignore` obrigatório; invariantes no sync script |
| Links relativos quebram após cópia para `prodops-framework` | Média | Alto — framework inutilizável | `doctor.sh` antes e depois; validação de links em `validate-export-manifest.sh` |
| Versão instalada fica fora de sync silenciosamente | Média | Médio — framework desatualizado sem aviso | `framework-lock.yaml` com `drift.status`; CI notifica |
| Conteúdo produto-específico de `payments-api` exportado como canônico | Baixa (transforms já aplicadas) | Alto — contamina o framework canônico | `validate-export-manifest.sh` + transforms declaradas no manifest |
| CI propaga versão quebrada para todos os consumidores simultaneamente | Baixa | Alto — impacto em N repos | PR revisável por repo; nunca commit direto em `main` |
| prodops-framework sem LICENSE bloqueia adoção | Baixa | Médio — bloqueio legal | Camada 1 inclui LICENSE como critério de entrada |

## Observable Events

Não aplicável nesta fase — o mecanismo de distribuição não emite eventos OEM. Métricas de operação serão definidas no estado Committed se necessário.

## Initial SLIs

| SLI | Initial target |
|---|---|
| Repositório consumidor instalado sem sobrescrita de `artifacts/` ou `skills/local/` | 100% |
| Export script passa em `validate-export-manifest.sh` antes de abrir PR | 100% |
| `doctor.sh` passa com exit 0 antes e depois de cada sync | 100% |
| Sync cria PR revisável — nunca commit direto em `main` | 100% |

## Reliability Rules

- O sync script nunca sobrescreve paths declarados em `.prodopsignore`.
- Nenhuma Camada (2, 3, 4) é executável sem a Camada 1 estar completa (versão publicada no `prodops-framework`).
- `doctor.sh` deve passar com exit 0 antes de qualquer push para o `prodops-framework`.
- Todo sync resulta em PR — nunca em commit direto. O PR deve conter diff revisável.
- `framework-lock.yaml` é atualizado pelo sync script — nunca manualmente após a Camada 2.

## Scope

### Camada 1 — Export (desbloqueadora)
`export-framework.sh`: lê `export-manifest.yaml`, copia conteúdo exportável de `payments-api` para clone local de `prodops-framework`, aplica transforms declaradas, abre PR. Publica `v0.1.0` com tag + LICENSE + CHANGELOG.

### Camada 2 — Install
`install-prodops.sh`: inicializa repo consumidor — cria estrutura `prodops/`, copia framework, gera `exec/manifest.yaml` e `exec/framework-lock.yaml` com `status: consumer`, cria `.prodopsignore`.

### Camada 3 — Sync
`sync-from-framework.sh`: lê `framework-lock.yaml`, compara com versão disponível, aplica `.prodopsignore`, detecta divergência local, atualiza lock, abre PR revisável.

### Camada 4 — CI
`notify-consumers.yml` (em `prodops-framework`) + `sync-prodops.yml` (em cada consumidor): propaga novas releases automaticamente via `workflow_dispatch`.

### Fora de escopo
- Migração de repos que não usam `prodops/` como raiz
- Resolução automática de conflitos em conteúdo canônico divergente
- Publicação no NPM ou qualquer registry de pacotes
- Suporte a múltiplas versões do framework instaladas simultaneamente

## Critérios de aceite (por camada)

| DS | Camada | Critério verificável |
|---|---|---|
| DS-53 | Export | `export-framework.sh` passa `validate-export-manifest.sh`; PR aberto no `prodops-framework`; `doctor.sh` com exit 0 no destino |
| DS-54 | Install | `install-prodops.sh` cria estrutura `prodops/` completa; `framework-lock.yaml` com `status: consumer`; `doctor.sh` com exit 0 no repo consumidor |
| DS-55 | Sync | `sync-from-framework.sh` abre PR sem tocar em paths do `.prodopsignore`; `framework-lock.yaml` atualizado com nova versão e `drift.status: ok`; `doctor.sh` passa antes e depois |
| DS-56 | CI | `workflow_dispatch` no repo consumidor abre PR de sync ao publicar nova release no `prodops-framework`; nenhum commit direto em `main` |

## Related Artifacts

- Business Signal: [#129](https://github.com/produtoreativo/payments-api/issues/129)
- Export Manifest: `prodops/exec/export-manifest.yaml`
- Export Boundary: `prodops/exec/export-boundary.md`
- Framework Lock: `prodops/exec/framework-lock.yaml`
- Validate Export Script: `prodops/scripts/validate-export-manifest.sh`
- BDD Export: `prodops/artifacts/bdd/prodops-framework-export.feature`
- BDD Install: `prodops/artifacts/bdd/prodops-framework-install.feature`
- BDD Sync: `prodops/artifacts/bdd/prodops-framework-sync.feature`
- BDD CI: `prodops/artifacts/bdd/prodops-framework-ci.feature`
- Iteration Plan: `prodops/artifacts/plans/iterations/v0.11.0/plan.md`
