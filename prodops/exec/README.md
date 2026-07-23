# prodops/exec/

Espaço de execução operacional do produto. Contém configurações e controles
de runtime que pertencem a este repositório, não ao Framework canônico.

---

## Arquivos

| Arquivo | Responsabilidade |
|---|---|
| `manifest.yaml` | Configuração operacional do produto: skills ativos, paths locais, gates, vocabulário canônico, GitHub Projects |
| `framework-lock.yaml` | Lock de distribuição do Framework: versão instalada, status de sync, estado de drift |
| `cards/` | Work cards de execução (contexto de fase ativo — efêmero) |

---

## Categorias de conteúdo no prodops/

Três categorias de conteúdo coexistem neste repositório:

### 1. Upstream canônico temporário (Framework)

Conteúdo que pertence ao ProdOps Framework e que, quando `prodops-framework`
existir, será sincronizado a partir do repositório canônico.

- `prodops/framework/` — princípios, glossário, ontologia, fluxo, canonical-paths
- `prodops/framework/execution-model/` — upstream e downstream
- `prodops/framework/journeys/*/` — estrutura e capabilities de cada jornada
- `prodops/skills/<framework-skills>/` — bootstrap, hack, sync, finish, ship, validate, promote, upstream, downstream, diligence
- `prodops/skills/references/engineering/tdd-prodops/` — prática de engenharia canônica do Framework
- `prodops/templates/` — templates canônicos

**Protegido por sync:** Estas áreas podem receber atualizações do mecanismo de sync futuro.

### 2. Local do produto

Conteúdo que pertence a este produto e que nunca deve ser sobrescrito por sync.
Declarado em `.prodopsignore`.

- `prodops/artifacts/` — OBCs, BDD, planos, trilhas, intents (Knowledge Space local)
- `prodops/exec/manifest.yaml` — configuração operacional do produto
- `prodops/exec/framework-lock.yaml` — lock de distribuição do produto
- `prodops/exec/cards/` — work cards de execução
- `prodops/skills/local/` — Skills locais desta API (ex: `payments-api-local-testing`)
- `prodops/skills/references/local/engineering/clean-code/` — referência opcional do produto
- `prodops/skills/references/local/engineering/ddd/` — referência opcional do produto
- `prodops/scripts/local/` — scripts específicos do produto (automações e adaptadores locais)

**Protegido por `.prodopsignore`:** Nunca sobrescrito por sync do Framework.

### 3. Estado de runtime ou gerado

Conteúdo efêmero ou gerado durante a execução — não é artefato permanente.

- `prodops/exec/cards/` — contexto de fase ativo (limpo após Promote)

---

## Distinção entre manifest.yaml e framework-lock.yaml

| | `manifest.yaml` | `framework-lock.yaml` |
|---|---|---|
| **Propósito** | Configuração de execução | Controle de distribuição |
| **Pergunta respondida** | *Como este produto executa o Framework?* | *Qual versão do Framework está instalada?* |
| **Quem escreve** | Equipe do produto | Mecanismo de sync (ou produto, na fase empírica) |
| **Quando muda** | Quando muda a configuração de execução do produto | Quando o Framework é atualizado |
| **Conteúdo** | Skills, paths, gates, vocabulário, GitHub | Versão, status, drift, mecanismo de sync |

Os dois arquivos são complementares e não se substituem.
