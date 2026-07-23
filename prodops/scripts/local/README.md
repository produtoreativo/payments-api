# scripts/local/

Automações e adaptadores específicos do produto payments-api.

- Pertencem a este repositório, não ao ProdOps Framework canônico.
- Continuam versionados — nunca apague sem deprecação registrada.
- Podem consumir manifest, artefatos e scripts canônicos como entradas.
- Scripts canônicos (`doctor.sh`, `validate-manifest.sh`) **não dependem** de nenhum script local específico.
- Product Skills podem invocá-los por nome — o nome do script é convencional, não mandatório no Framework.
- Scripts do runtime da aplicação (build, start, test) permanecem junto à aplicação e **não** são copiados aqui.
- Protegidos de sincronização por `.prodopsignore` — atualizações do Framework não sobrescrevem este diretório.

## Scripts disponíveis

| Script | Propósito |
|---|---|
| `sync.sh` | Automação da fase Sync (rebase + align ProdOps). Substitui execução manual dos steps de git e alinhamento de artefatos. Veja a Skill em `prodops/skills/sync/SKILL.md`. |

## Uso

```bash
# Fluxo completo (rebase → align)
./prodops/scripts/local/sync.sh

# Apenas rebase
./prodops/scripts/local/sync.sh rebase

# Apenas align
./prodops/scripts/local/sync.sh align

# Dry-run (exibe comandos sem executar)
./prodops/scripts/local/sync.sh --dry-run
```

## Dependências

O `sync.sh` requer:
- `git` (operações de rebase/merge)
- `npm` (lint e testes da API — `cd api && npm run lint / test`)
- Estrutura `api/src/modules/` para detecção de módulos NestJS

## Propriedade

Estes scripts pertencem ao produto. Antes de modificá-los consulte a Skill correspondente (`prodops/skills/sync/SKILL.md`) para garantir que o comportamento permanece alinhado com o Framework.
