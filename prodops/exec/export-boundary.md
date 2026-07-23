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

## Estado das transformações após canonicalização interna

A canonicalização interna foi concluída. As transformações identificadas anteriormente
foram aplicadas a este repositório. O conteúdo exportável em `framework/` é agora genérico.

### 1. `remove-empirical-references` — **RESOLVIDA**

As referências estruturais a `payments-api` foram generalizadas:
- `framework/operating-model.md` e `.en.md` — genérico
- `framework/glossary.md` e `.en.md` — genérico
- `framework/README.md` e `.en.md` — genérico
- `framework/artifact-governance.md` — genérico
- `framework/principles.md` e `.en.md` — `ASAAS_MOCK=true` substituído por placeholder genérico

### 2. `generalize-product-examples` — **RESOLVIDA**

Os exemplos produto-específicos foram generalizados:
- `framework/journeys/operation/runbooks.md` e `.en.md` — agora definição canônica de Runbook
- `framework/execution-mapping/matrix.md` — NestJS/DynamoDB/SQS substituídos por placeholders
- `framework/execution-mapping/work-item-schema.md` — payments-invoice-v2 substituído por feature-name-v2
- `framework/dora-metrics.md` e `.en.md` — eventos específicos substituídos por padrões genéricos
- `framework/backlogs.md` e `.en.md` — nomes de produtos específicos removidos
- `framework/knowledge-vs-execution.md` e `.en.md` — exemplos generalizados
- `framework/journeys/operation/README.md` e `.en.md` — webhook/payment refs generalizadas

O runbook de produto foi preservado em `prodops/artifacts/runbooks/payments-api-runbook.md`.

### 3. `extract-discovery-history` — **SEPARADA (não movida)**

O trail de discovery em `framework/journeys/discovery/upstream-trail.md` contém
uma seção `# History` marcada com nota contextual explícita que a identifica como
registro empírico do produto. A separação é semântica (via marcador de seção) — os
arquivos permanecem no lugar como registros append-only.

Arquivos a **não** exportar como conteúdo canônico:
- `framework/journeys/discovery/upstream-trail.md` (seção `# History`) — histórico do produto
- `framework/journeys/discovery/experiments.md` — índice de experimentos do produto
- `framework/journeys/discovery/learnings.md` — learnings do produto

### 4. `disable-sync-script` — **CONCLUÍDA**

`scripts/sync-framework-docs.sh` foi desabilitado com um guard explícito que retorna
exit code 1 antes de qualquer operação. O conteúdo original foi preservado abaixo do
guard para referência futura.

---

## Estado atual da fronteira

**O conteúdo em `framework/` está genérico e pronto para extração.**

Pendências não-bloqueantes (não impedem a exportação, devem ser tratadas antes
de qualquer mecanismo de sync automático):

1. **Mecanismo de exportação:** `scripts/sync-framework-docs.sh` precisa ser alinhado
   com `export-manifest.yaml` antes de qualquer uso. O script está desabilitado.
2. **`framework/journeys/discovery/upstream-trail.md`:** a seção `# History` é produto-específica
   e não deve ser incluída na exportação canônica. O `export-manifest.yaml` deve incluir
   uma exclusão ou transformação explícita para este arquivo.
3. **Validação final de links:** após a exportação para `prodops-framework`, os links
   relativos devem ser verificados.

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

As seguintes observações foram identificadas durante a análise. As marcadas como
**RESOLVIDAS** foram endereçadas durante a canonicalização interna.

- **`framework/journeys/operation/runbooks.md`** — **RESOLVIDA.** O arquivo foi
  reescrito como definição canônica de Runbook. O conteúdo produto-específico foi
  preservado em `prodops/artifacts/runbooks/payments-api-runbook.md`.

- **`framework/journeys/discovery/`** — **PARCIALMENTE RESOLVIDA.** O `upstream-trail.md`
  recebeu marcador de seção explícito na seção `# History`. O `export-manifest.yaml`
  deve incluir exclusão ou transformação para a seção de história antes da exportação.

- **`AGENTS.md` no root** — **RESOLVIDA.** O AGENTS.md foi atualizado para incluir
  o mapa de áreas, a nota de upstream empírico e a proibição explícita de execução
  do script de sync. O AGENTS.md é um artefato local do produto — não é exportado.
