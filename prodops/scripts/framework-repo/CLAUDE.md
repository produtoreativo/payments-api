# Claude Code Instructions — ProdOps Framework Repo

Leia `AGENTS.md` inteiro antes de qualquer ação — é o guia operacional deste
repositório e contém as regras de review, versioning e o que pode ser editado aqui.

## Regra crítica: versão do runtime acompanha o framework

Ao trabalhar em um PR de export ou ao incrementar a versão do framework, confirme
que **os três arquivos abaixo têm exatamente o mesmo número de versão**:

1. `prodops/scripts/setup-wsl.sh` — linha `PRODOPS_VERSION="vX.Y.Z"`
2. `prodops/scripts/setup-mac.sh` — linha `PRODOPS_VERSION="vX.Y.Z"`
3. `prodops/runtime/runtime.yaml.example` — campo `framework-version: "vX.Y.Z"`

Se qualquer um divergir, o gate `validate-export-manifest.sh` falhará e o
export deve ser bloqueado até que o upstream corrija e reexporte.

## Não edite scripts canônicos aqui

Scripts em `prodops/scripts/`, skills em `prodops/skills/`, documentação em
`prodops/framework/` e runtime em `prodops/runtime/` são gerenciados pelo
upstream empírico (`payments-api`). Edições diretas aqui serão sobrescritas
na próxima execução de `export-framework.sh`.
