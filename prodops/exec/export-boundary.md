# Fronteira de Exportação do ProdOps Framework

Este documento explica o modelo de propriedade e distribuição do ProdOps Framework
enquanto este repositório (`payments-api`) atua como upstream empírico. O contrato
declarativo vive em `prodops/exec/export-manifest.yaml`; este documento explica o
modelo — não o replica.

---

## Propósito desta fronteira

O ProdOps Framework evoluiu empiricamente neste repositório. Para reconciliar com
o repositório canônico existente `prodops-framework`, é necessário definir com precisão:

1. O que pertence ao Framework e deve ser exportado.
2. O que pertence ao produto e nunca deve ser sobrescrito.
3. O que o Framework define como espaço do consumidor (convention-only).
4. O que descreve como o consumidor instalou o Framework (installation-state).

Esta fronteira permite que a extração seja feita com segurança e que o mecanismo
de sync respeite os invariantes de propriedade.

---

## Distinção fundamental: exportação, instalação e sincronização

| Conceito | Definição | Quem executa |
|---|---|---|
| **Exportação** | Copiar conteúdo exportável deste repositório para `prodops-framework`. | Humano ou ferramenta de extração. Ocorre uma vez. |
| **Instalação** | Inicializar um produto consumidor com o Framework (criar `exec/manifest.yaml`, `exec/framework-lock.yaml`, estrutura de diretórios). | CI ou operador do produto. Ocorre na adoção. |
| **Sincronização** | Propagar atualizações do Framework canônico para consumidores instalados. | Mecanismo futuro (CI+PR). Ocorre em atualizações. |

Estes três processos são distintos e não devem ser confundidos. Este arquivo e
`export-manifest.yaml` descrevem apenas a **exportação**.

---

## As quatro classificações de conteúdo

### 1. Exportável

Conteúdo que pertence ao Framework e deve ser copiado para o repositório
`prodops-framework`.

**Exemplos:**
- `prodops/framework/` — princípios, glossário, ontologia, fluxo, canonical-paths
- `prodops/skills/<framework-skills>/` — bootstrap, hack, sync, finish, ship, validate, promote, upstream, downstream, diligence
- `prodops/skills/references/engineering/` — referências canônicas de engenharia (TDD ProdOps)
- `prodops/templates/` — templates canônicos
- `prodops/scripts/doctor.sh`, `prodops/scripts/validate-manifest.sh`, `prodops/scripts/validate-export-manifest.sh`

### 2. Propriedade do consumidor (consumer-owned)

Conteúdo que pertence ao produto consumidor e nunca deve ser sobrescrito por sync.
Declarado em `.prodopsignore`.

**Exemplos:**
- `prodops/artifacts/` — OBCs, BDD, planos, trilhas, intents, evidências do produto
- `prodops/exec/manifest.yaml` — configuração operacional do produto
- `prodops/exec/framework-lock.yaml` — lock de distribuição do produto
- `prodops/exec/cards/` — work cards de execução (efêmeros)
- `prodops/skills/local/` — Skills locais do produto
- `prodops/skills/references/local/` — referências locais do produto
- `prodops/scripts/local/` — scripts locais do produto

### 3. Convention-only

Caminhos cujo **esquema** é definido pelo Framework, mas cujo **conteúdo**
pertence ao consumidor. O Framework declara que estes espaços existem e os
documenta — mas não exporta nem controla seu conteúdo.

| Caminho | O que o Framework define | O que o consumidor controla |
|---|---|---|
| `prodops/artifacts/` | Estrutura de diretórios, schemas de artefatos | Todos os artefatos do produto |
| `prodops/skills/local/` | Existência do diretório e seu README | Skills específicas do produto |
| `prodops/skills/references/local/` | Existência e propósito | Literatura e convenções locais |
| `prodops/templates/local/` | Existência e propósito | Adaptações locais de templates |
| `prodops/scripts/local/` | Existência e propósito | Automações e adaptadores locais |

### 4. Estado de instalação (installation-state)

Arquivos que descrevem como um consumidor instalou ou rastreia o Framework.
Não são simplesmente canônicos nem simplesmente locais — requerem tratamento
especial. São gerados localmente na instalação inicial e nunca sobrescritos
por sync.

| Arquivo | Papel |
|---|---|
| `prodops/exec/manifest.yaml` | Configuração operacional do produto (gerado na adoção) |
| `prodops/exec/framework-lock.yaml` | Versão instalada e status de drift (gerado na adoção) |
| `.prodopsignore` | Declaração de proteção de áreas do produto |

---

## O que é incluído e por quê

O `export-manifest.yaml` inclui:

- **`framework/**`** — A estrutura conceitual do Framework: princípios, glossário,
  ontologia, fluxo, jornadas, capabilities, práticas, execution model e canonical-paths.
  É o núcleo da distribuição.

- **`skills/**`** — As Skills canônicas do Framework (excluindo `skills/local/**` e
  `skills/references/local/**`). São o mecanismo de execução do Framework por agentes.

- **`templates/**`** — Templates canônicos de artefatos (excluindo `templates/local/**`).
  Permitem que consumidores criem artefatos conformes ao Framework.

- **`scripts/doctor.sh`** — Validação estrutural canônica. Exportável porque valida
  a estrutura do Framework, não o conteúdo do produto.

- **`scripts/validate-manifest.sh`** — Validação de consistência do manifest.
  Exportável pelo mesmo motivo.

- **`scripts/validate-export-manifest.sh`** — Validação da fronteira de exportação.
  Exportável como script transitional canônico.

---

## O que é excluído e por quê

- **`skills/local/**`** — Propriedade do consumidor. Cada produto tem suas próprias
  Skills locais.

- **`skills/references/local/**`** — Literatura e convenções escolhidas pelo produto.
  Outros produtos fazem escolhas diferentes.

- **`templates/local/**`** — Adaptações locais de templates. Produto-específicas.

- **`scripts/local/**`** — Automações e adaptadores locais. Não portáveis.

- **`artifacts/**`** — Knowledge Space do produto: OBCs, BDD, planos, trilhas,
  intents, evidências. Integralmente produto-específico.

- **`exec/**`** — Estado de instalação e configuração operacional do produto.
  Gerado localmente; nunca distribuído pelo Framework.

---

## Transformações identificadas antes da extração

O conteúdo exportável contém referências ao papel empírico do payments-api que
devem ser removidas ou generalizadas antes da distribuição:

### 1. `remove-empirical-references`

Escopo: `framework/**`

Arquivos afetados:
- `framework/operating-model.md` e `.en.md` — menciona payments-api como Product Repository
- `framework/glossary.md` e `.en.md` — cita payments-api como exemplo
- `framework/README.md` e `.en.md` — descreve o Framework "aplicado a este produto"
- `framework/artifact-governance.md` — menciona payments-api como exemplo

Ação: Substituir referências diretas a payments-api por placeholders genéricos
(ex: `<your-product-repository>`).

### 2. `generalize-product-examples`

Escopo: `framework/**`

Arquivos afetados:
- `framework/journeys/operation/runbooks.md` e `.en.md` — runbooks são produto-específicos
  (Asaas, DynamoDB, webhook payments-api). Este arquivo deve ser tratado como template
  de runbook, não runbook de produto.
- `framework/execution-mapping/matrix.md` — menciona NestJS, DynamoDB como exemplos
- `framework/execution-mapping/work-item-schema.md` — payments-api como exemplo de valor

### 3. `extract-discovery-history`

Escopo: `framework/journeys/discovery/**`

O trail de discovery, o índice de experimentos e os learnings do payments-api
são históricos e produto-específicos. O Framework exporta apenas a estrutura e
os templates das jornadas de discovery — não o histórico de um produto específico.

Arquivos a **não** exportar como conteúdo canônico:
- `framework/journeys/discovery/upstream-trail.md` — histórico do payments-api
- `framework/journeys/discovery/experiments.md` — índice de experimentos do produto
- `framework/journeys/discovery/learnings.md` — learnings do produto

Substituir por: templates vazios ou exemplos genéricos.

---

## Layout do repositório prodops-framework

### Alternativa A — Preservar nível prodops/ (recomendada)

```
prodops-framework/
├── README.md
├── README.en.md
├── LICENSE
└── prodops/
    ├── framework/
    ├── skills/
    ├── templates/
    └── scripts/
```

### Alternativa B — Promover para root

```
prodops-framework/
├── README.md
├── framework/
├── skills/
├── templates/
└── scripts/
```

**Recomendação: Alternativa A.**

Justificativa:

1. **Links relativos calibrados.** Todos os links relativos nos arquivos do
   Framework são calculados a partir de `prodops/`. Por exemplo,
   `../../artifacts/` assume que o arquivo está dois níveis abaixo de `prodops/`.
   A Alternativa A preserva esta geometria sem modificações.

2. **Consistência com consumidores.** Consumidores instalam o Framework sob
   `prodops/` — o caminho `prodops/framework/` é consistente entre o repositório
   canônico e os repositórios consumidores.

3. **Zero custo de transformação de links.** A Alternativa B exigiria reescrever
   todos os links relativos em todos os arquivos exportados antes da distribuição.

4. **Clareza de propósito.** O diretório `prodops/` sinaliza explicitamente o
   escopo do conteúdo — não é um projeto genérico, é o conteúdo ProdOps.

---

## Arquivos raiz mínimos para o repositório prodops-framework

| Arquivo | Necessidade | Versão |
|---|---|---|
| `README.md` | Necessário | 0.1.0 |
| `README.en.md` | Recomendado | 0.1.0 |
| `LICENSE` | Necessário | 0.1.0 |
| `CHANGELOG.md` ou tag strategy | Necessário | 0.1.0 |
| `AGENTS.md` | Necessário (apenas partes do Framework) | 0.1.0 |
| `CONTRIBUTING.md` | Recomendado | posterior |
| `CODE_OF_CONDUCT.md` | Recomendado | posterior |
| `SECURITY.md` | Não necessário | posterior |
| `.github/` | Parcial (apenas templates relevantes ao Framework) | posterior |

**Nota sobre AGENTS.md:** O `AGENTS.md` do payments-api contém tanto routing do
Framework quanto configuração específica do produto (gates com `npm run lint`,
LocalStack, NestJS etc.). O repositório prodops-framework deve ter um `AGENTS.md`
extraído com apenas as partes canônicas do Framework.

---

## Critérios de entrada para versão 0.1.0

- [ ] Fronteira de exportação validada (`export-manifest.yaml` existe e passa `validate-export-manifest.sh`)
- [ ] Doctor passa com exit 0 e zero FAILs
- [ ] Links internos válidos
- [ ] Nenhum conteúdo produto-específico em arquivos exportáveis (transformações aplicadas)
- [ ] Templates canônicos completos
- [ ] Skills canônicas descobríveis via manifest
- [ ] Manifest de exportação válido (YAML)
- [ ] Documentação raiz mínima (`README.md`, `README.en.md`)
- [ ] Licença definida
- [ ] Estratégia de versionamento definida (CHANGELOG ou tag strategy)

---

## Processo futuro de transição self → consumer

**Este processo é documentado apenas. Não executar.**

A sequência para transicionar o payments-api de `status: self` para
`status: consumer`:

1. Extrair o Framework para o repositório `prodops-framework` (aplicando as
   transformações identificadas neste documento).
2. Publicar a versão inicial (`0.1.0`) com tag e LICENSE.
3. Registrar fonte e versão em `prodops/exec/framework-lock.yaml` do payments-api.
4. Alterar `prodops/exec/framework-lock.yaml` do payments-api:
   `status: self` → `status: consumer`.
5. Validar o conteúdo instalado contra a versão publicada.
6. Preservar áreas locais (`artifacts/`, `skills/local/`, etc.) — intocadas.
7. Abrir PR de transição com evidências.
8. Executar `doctor.sh` — deve continuar passando.
9. Remover o papel empírico: este arquivo (`export-manifest.yaml`) e
   `export-boundary.md` podem ser removidos ou mantidos como histórico.

**Evolução esperada do framework-lock.yaml após a transição:**

```yaml
prodops_framework:
  version: "0.1.0"
  status: consumer
  source_repository: prodops-framework
  external_source: https://github.com/<org>/prodops-framework
  synchronization_mechanism: ci-pr-sync

distribution:
  state: installed
  lock_mode: managed
  update_procedure: open-pr-from-framework

drift:
  status: ok
  reason: Content matches installed version 0.1.0.
```

**Nota:** Os campos `external_source`, `synchronization_mechanism`,
`distribution.update_procedure` existem no schema atual do `framework-lock.yaml`
(como `null`). A transição preencherá esses campos sem exigir evolução de schema.
O campo `distribution.state` mudará de `empirical` para `installed`.

---

## Invariantes do sincronizador futuro

Qualquer mecanismo futuro de sincronização (CI+PR sync) **DEVE**:

1. Nunca sobrescrever `artifacts/`
2. Nunca sobrescrever `skills/local/`
3. Nunca sobrescrever `skills/references/local/`
4. Nunca sobrescrever `templates/local/`
5. Nunca sobrescrever `scripts/local/`
6. Preservar o manifest local (`exec/manifest.yaml`)
7. Preservar o lock, modificando apenas metadados controlados (versão, drift)
8. Atualizar apenas conteúdo exportável
9. Detectar divergência local em conteúdo canônico antes de sobrescrever
10. Produzir um diff revisável (PR, não commit direto)
11. Preferir PR sobre modificação silenciosa
12. Nunca reescrever trails históricos
13. Validar links e paths após atualização
14. Executar `doctor.sh` antes e depois da atualização

---

## Inconsistências fora do escopo desta fronteira

As seguintes observações foram identificadas durante a análise mas estão fora
do escopo desta fronteira declarativa:

- **`framework/journeys/operation/runbooks.md`** — conteúdo operacional do
  payments-api (Asaas, DynamoDB, webhook) que está no diretório `framework/`
  mas é produto-específico. Deve ser movido para `artifacts/` na extração.
  (Não mover agora — documentado como transformação `generalize-product-examples`.)

- **`framework/journeys/discovery/`** — histórico empírico do payments-api
  (trails, experimentos, learnings) que não deve ser exportado como canônico.
  (Documentado como transformação `extract-discovery-history`.)

- **`AGENTS.md` no root** — contém mistura de routing canônico do Framework e
  configuração específica do payments-api. Requer separação antes da extração.
