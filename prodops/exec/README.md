# prodops/exec/

Espaço de execução operacional do produto. Contém configurações, controles de
runtime e contratos de distribuição do Framework para este repositório.

---

## Arquivos

| Arquivo | Responsabilidade |
|---|---|
| `manifest.yaml` | Configuração operacional do produto: skills ativos, paths locais, gates, vocabulário canônico, GitHub Projects |
| `framework-lock.yaml` | Lock de distribuição do Framework: versão instalada, status de sync, estado de drift |
| `export-manifest.yaml` | **Contrato declarativo de extração** — define o contorno exportável do Framework *(apenas upstream empírico, `status: self`)* |
| `export-boundary.md` | Documentação do modelo de fronteira: propriedade, classificações, layout, transformações e invariantes do sync *(apenas upstream empírico)* |
| `empirical-upstream.md` | Orientação sobre o papel de upstream empírico deste repositório e o significado de `status: self` |
| `cards/` | Work cards de execução (contexto de fase ativo — efêmero) |

> **Contratos distintos:** `manifest.yaml`, `framework-lock.yaml` e
> `export-manifest.yaml` respondem a perguntas diferentes e não se substituem.
> Ver seção abaixo.

> **Mecanismo de sync desabilitado:** `scripts/sync-framework-docs.sh` está
> desabilitado com guard explícito. Não deve ser executado até ser alinhado com
> `export-manifest.yaml`. Ver `export-boundary.md` para o estado atual.

---

## Categorias de conteúdo no prodops/

Três categorias de conteúdo coexistem neste repositório:

### 1. Upstream canônico temporário (Framework)

Conteúdo que pertence ao ProdOps Framework e que será sincronizado a partir do
repositório canônico existente `prodops-framework` após a reconciliação.

- `prodops/framework/` — princípios, glossário, ontologia, fluxo, canonical-paths
- `prodops/framework/execution-model/` — upstream e downstream
- `prodops/framework/journeys/*/` — estrutura e capabilities de cada jornada
- `prodops/skills/<framework-skills>/` — bootstrap, hack, sync, finish, ship, validate, promote, upstream, downstream, diligence
- `prodops/skills/references/engineering/tdd-prodops/` — prática de engenharia canônica do Framework
- `prodops/templates/` — templates canônicos

**Protegido por sync:** Estas áreas receberão atualizações do mecanismo de sync após a reconciliação com prodops-framework.

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

## Três contratos, três perguntas distintas

| | `manifest.yaml` | `framework-lock.yaml` | `export-manifest.yaml` |
|---|---|---|---|
| **Propósito** | Configuração de execução | Controle de distribuição | Contorno de exportação |
| **Pergunta respondida** | *Como este produto executa o Framework?* | *Qual versão do Framework está instalada?* | *O que pertence ao Framework e deve ser exportado?* |
| **Quem escreve** | Equipe do produto | Mecanismo de sync (ou produto, na fase empírica) | Upstream empírico (este repositório) |
| **Quando muda** | Quando muda a configuração de execução do produto | Quando o Framework é atualizado | Quando a fronteira de exportação é revisada |
| **Conteúdo** | Skills, paths, gates, vocabulário, GitHub | Versão, status, drift, mecanismo de sync | Includes, excludes, transformações, convention-only paths |
| **Escopo** | Todo produto consumidor | Todo produto consumidor | Apenas upstream empírico |

Os três arquivos são complementares e não se substituem.

`export-manifest.yaml` e `export-boundary.md` existem **apenas enquanto este
repositório for o upstream empírico** (`status: self`). Após a transição para
`status: consumer`, eles podem ser removidos ou mantidos como histórico.
