# prodops/scripts/

Scripts de automação determinística do ProdOps Framework.

---

## Skill vs. Script

| | Skill | Script |
|---|---|---|
| **Natureza** | Instrução interpretativa e decisória | Automação determinística de uma etapa |
| **Executado por** | Agente (Claude Code, Copilot, Codex) | Shell (bash) |
| **Substitui o outro?** | Não | Não |
| **Contexto** | Lê artefatos, toma decisões, orienta o agente | Executa sequência fixada, valida estado, reporta |

Um Script **não substitui** a Skill correspondente. A Skill descreve a intenção e a decisão; o Script automatiza a parte determinística da execução.

---

## Scripts canônicos

Scripts genéricos e reutilizáveis. Não contêm conhecimento de produto. Funcionam em qualquer repositório que siga o ProdOps Framework.

| Script | Responsabilidade | Skill relacionada |
|---|---|---|
| `doctor.sh` | Valida a estrutura canônica do ProdOps no repositório: paths obrigatórios, links markdown, ausência de paths legados, integridade do `framework-lock.yaml` e proteções de `.prodopsignore`. | Utilizado como gate em todas as fases |
| `validate-manifest.sh` | Valida a consistência declarativa do `prodops/exec/manifest.yaml`: paths declarados existem, `commit_types` bate com o hook `commit-msg.sh`, `commit_summary_max` está alinhado. | Qualquer fase — manutenção do manifest |

Estes scripts são protegidos para sync pelo Framework. São listados em `prodops/framework/canonical-paths.md`.

---

## Scripts locais do produto

Scripts específicos do payments-api. Podem depender de estrutura de diretórios, comandos de runtime e convenções desta API. Não são portáveis sem modificação.

Localização: `prodops/scripts/local/`

Protegidos de sync por `.prodopsignore` — consulte `prodops/scripts/local/README.md`.

---

## Scripts de runtime da aplicação

Scripts de build, start, test e deploy da aplicação **não** residem em `prodops/scripts/`. Permanecem junto à aplicação (`api/`, `Makefile`, `package.json`).

---

## Direção de dependência

```
Framework Skill      → pode invocar script canônico (doctor.sh, validate-manifest.sh)
Framework Skill      → NÃO conhece nomes específicos de scripts locais
Product Skill        → pode invocar scripts canônicos, locais ou da aplicação
Scripts canônicos    → NÃO dependem de scripts locais
Scripts locais       → podem ler manifest, artefatos e invocar scripts canônicos
```

---

## Descoberta

```bash
# Listar todos os scripts disponíveis
find prodops/scripts -name "*.sh" | sort

# Executar a validação canônica
./prodops/scripts/doctor.sh

# Validar consistência do manifest
./prodops/scripts/validate-manifest.sh

# Automação local: Sync (rebase + align)
./prodops/scripts/local/sync.sh --help
```

---

## Relação com manifest, artefatos e .prodopsignore

- **manifest.yaml** — scripts canônicos e locais podem ler o manifest como fonte de verdade declarativa.
- **prodops/artifacts/** — scripts canônicos validam a existência de paths de artefatos; scripts locais podem inspecionar o conteúdo.
- **.prodopsignore** — protege `prodops/scripts/local/` de sobrescritas por sync do Framework.
