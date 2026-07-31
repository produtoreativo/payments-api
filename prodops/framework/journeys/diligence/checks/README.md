# Checks — Catálogo de Definições Canônicas

> **Este diretório contém definições normativas e reutilizáveis de Checks da Diligence.**
> Checks são regras do framework — não instâncias de produto.
> Instâncias de Finding geradas por Checks vivem em `prodops/artifacts/diligence/findings/`.

→ [Modelo canônico do Check](../model/check.md)
→ [Catálogo de Checks](catalog.yaml)
→ [Instâncias de entidades](../../../../artifacts/diligence/)
→ [Jornada Diligence](../README.md)

---

## 1. Finalidade

Este diretório serve como repositório central das definições canônicas de Checks da Diligence. Um Check é uma regra declarativa, reproduzível e verificável que define **o que deve ser avaliado** e qual resultado é esperado.

As definições aqui são normativas: todo agente ou ciclo que executa Checks deve usar as definições deste catálogo como fonte de verdade — não inventar regras ad hoc durante a execução.

| `checks/` (este diretório) | `artifacts/diligence/` |
|---|---|
| Definições de framework (normativos) | Instâncias de produto (operacionais) |
| Regras: o que verificar e como | Resultados: o que foi encontrado |
| Estável — muda quando a regra muda | Cresce com cada nova detecção |
| Consumido por todos os produtos | Específico para este produto |
| Versionado com o framework | Versionado com a operação do produto |

---

## 2. Relação entre Check e Finding

Um Check pode gerar múltiplos Findings ao longo do tempo — um por sujeito diferente onde a condição é detectada:

```
Check DIL-TRC-001
    ├── FND-2026-0001  (Work Item #89 — sem artifact_id)
    ├── FND-2026-0002  (Work Item #94 — sem artifact_id)
    └── FND-2026-0015  (Work Item #112 — sem artifact_id, recorrência após correção)
```

**Regras fundamentais:**

- **Check não cria Finding diretamente.** O ciclo que executa o Check decide se o resultado Fail deve gerar Finding, com base na deduplicação e no contexto.
- **Finding referencia o Check pelo campo `check_id`** (formato `DIL-CATEGORY-NNN`). O `check_version` registra qual versão da regra estava vigente na criação do Finding.
- **Check Pass/Not Applicable não gera Finding.** O resultado deve ser registrado no trail de execução do ciclo, não como Finding.
- **Check Error não gera Finding da regra original.** Pode gerar Finding operacional separado sobre falha do mecanismo da Diligence — nunca confundir os dois.

```
Check executado (por ciclo Sync, Async ou manual)
       ↓
resultado avaliado
       ↓
Pass / Not Applicable → nenhuma ação sobre Findings
Warning → avaliar se relevante para registro
Fail → protocolo de Finding (deduplicação → criar ou atualizar)
Error → avaliar: criar Finding operacional sobre a falha do mecanismo?
Indeterminate → escalar ou registrar Finding com Evidence insuficiente
       ↓
Deduplicação usando chave: check_id + sujeito primário + condição + escopo
       ↓
Finding existente?
  ├── sim → atualizar last_detected_at, occurrence_count, adicionar Evidence
  └── não → gerar ID (FND-YYYY-NNNN), criar arquivo, atualizar registry
```

---

## 3. Estrutura do catalog.yaml

O catálogo vive em `catalog.yaml` neste diretório. Campos de nível global:

```yaml
schema_version: 1
catalog_version: "1.0.0"
last_updated: "YYYY-MM-DD"
description: >
  ...

defaults:
  finding_template: prodops/templates/diligence/finding.md
  findings_dir: prodops/artifacts/diligence/findings/
  evidence_template: prodops/templates/diligence/evidence.md
  evidence_dir: prodops/artifacts/diligence/evidence/
  registry: prodops/artifacts/diligence/registry.yaml
  deduplication_key: [check_id, primary_subject, condition, scope]

checks:
  - id: DIL-XXX-NNN
    ...
```

Cada entrada em `checks:` segue o schema completo documentado em `model/check.md`.

---

## 4. Política de IDs

**Formato:** `DIL-[PREFIX]-NNN`

- `DIL` — prefixo imutável da Diligence
- `[PREFIX]` — três letras identificando o grupo primário do Check (ver tabela abaixo)
- `NNN` — sequencial de três dígitos por prefixo (001–999)

| Prefixo | Grupo | primary_dimension |
|---|---|---|
| `CON` | Conceptual | Conceptual |
| `STR` | Structural | Structural |
| `TRC` | Traceability | Traceability |
| `OPS` | Operational | Operational |
| `TMP` | Temporal | Temporal |
| `RDY` | Readiness (categoria/escopo) | Operational |
| `WSP` | Workspace (categoria/escopo) | Structural |

**Regras:**
- O ID é imutável após criação — não muda quando a regra muda.
- A versão da regra é rastreada no campo `version` do Check.
- IDs nunca são reutilizados, mesmo após deprecação ou remoção de um Check.
- O prefixo reflete o grupo primário do Check — não necessariamente a `category` do Finding que gera.

---

## 5. Política de versionamento

### Mudança material (incrementa `version`)

Qualquer alteração que muda o critério de Pass/Fail, o sujeito aplicável, a severidade padrão ou a política de bloqueio é mudança material:

- Mudança no `expected_condition` ou `failure_condition`
- Adição ou remoção de sujeitos no `scope`
- Mudança de `severity_default`
- Mudança de `blocking` (true → false ou vice-versa)
- Mudança de `waiver_allowed`
- Mudança de `auto_finding` ou `human_review_required`

**Ao fazer mudança material:** incrementar `version` (inteiro), documentar o que mudou em `notes`, avaliar se Findings criados com a versão anterior ainda são válidos com a nova regra.

### Mudança não-material (sem incremento de versão)

- Correção de texto sem mudar critérios
- Adição de exemplos em campos descritivos
- Melhora de `remediation_hint` sem mudar a regra
- Atualização de `escalation_targets` sem mudar a lógica

### Finding registra a versão do Check

O campo `check_version` no Finding indica qual versão da regra estava vigente no momento da criação. Quando a regra muda materialmente, Findings anteriores devem ser avaliados: se a nova regra tornaria o Finding inválido, o Finding recebe classificação `Invalid Rule` — nunca é deletado.

---

## 6. Dimensões

As cinco dimensões canônicas da Diligence definem o **tipo de consistência** que o Check verifica:

| # | Dimensão | O que verifica |
|---|---|---|
| 1 | **Conceptual** | Documentos usam ontologia, vocabulário, estados, relações e responsabilidades compatíveis com o framework |
| 2 | **Structural** | Estrutura real de arquivos, diretórios, índices, links e schemas corresponde ao modelo documentado |
| 3 | **Traceability** | É possível reconstruir as relações entre entidades; referências resolvem para destinos válidos |
| 4 | **Operational** | Operações respeitam schema, estado, propriedade, dependências, critérios de entrada/saída e evidência |
| 5 | **Temporal** | O sistema preserva história, trilhas, decisões passadas e não confunde estado histórico com instrução normativa atual |

**Readiness e Workspace são categorias/escopos — NÃO são dimensões canônicas adicionais.**

- Checks com prefixo `DIL-RDY-NNN` têm `primary_dimension: Operational`
- Checks com prefixo `DIL-WSP-NNN` têm `primary_dimension: Structural`

Um Check tem uma `primary_dimension` obrigatória e pode ter `secondary_dimensions` opcionais quando a condição verificada toca múltiplas dimensões.

---

## 7. Categorias

A categoria de um Check reflete o tipo de Finding que ele pode gerar quando o resultado é Fail:

| Categoria | O que representa |
|---|---|
| **Documentation** | Documentação normativa: vocabulário, terminologia, classificações, referências |
| **Workspace** | Infraestrutura do GitHub Workspace: Labels, Fields, Views, Projects |
| **Work Item** | Schema, rastreabilidade, estado ou conformidade de Work Items |
| **Artifact** | Conteúdo, estado, completude ou conformidade de artefato do Knowledge Space |
| **Readiness** | Pré-condições de transição: artefatos faltando, critérios não satisfeitos |
| **Governance** | Conformidade de governança: aprovações, Waivers, entidades sem fundamento |
| **Evidence** | Evidence de verificação, resolução ou aprovação: ausência onde obrigatória |
| **Backlog** | Consistência entre backlogs, critérios de entrada/saída, hierarquia |
| **Execution Mapping** | Mapeamento entre artefatos e Work Items, cardinalidade KS↔ES |

---

## 8. Tipos

O tipo de um Check descreve o **mecanismo lógico** da verificação:

| Tipo | O que faz | Exemplo |
|---|---|---|
| **Presence** | Verifica existência obrigatória | "Arquivo de entidade deve existir no path canônico" |
| **Absence** | Verifica ausência esperada | "Signal passivo não deve ter Work Item" |
| **Validity** | Verifica que referência/valor é válido | "artifact_id deve referenciar artefato existente" |
| **Consistency** | Compara duas ou mais fontes | "Registry deve ser consistente com arquivos de entidade" |
| **Completeness** | Verifica campos obrigatórios preenchidos | "Waiver Active deve ter todos os campos obrigatórios" |
| **Traceability** | Verifica cadeia de relações | "Work Item ativo deve ter referência a artefato válida" |
| **Readiness** | Verifica pré-condições de avanço | "Critérios de promoção devem estar satisfeitos" |
| **Freshness** | Verifica validade temporal | "Waiver expirado não deve estar Active" |
| **Conformance** | Verifica aderência a schema | "Workspace deve ter campos canônicos declarados" |
| **Outcome** | Verifica que Evidence suporta resultado | "Remediation Implemented deve ter verificação independente" |

---

## 9. Modos de execução

| Modo | Quando é usado | Acionado por |
|---|---|---|
| **Sync** | Dentro de uma transição ou operação em andamento | Fase de ciclo diligence-sync (Promote, Close, Attach) |
| **Async** | Fora da transação principal, proativamente | Varredura periódica diligence-async |
| **Manual** | Sob solicitação explícita | Pedido humano, Bootstrap, auditoria |
| **Event-driven** | Disparado por evento técnico ou operacional | PR aberto, documento editado, Work Item criado |
| **Scheduled** | Periodicamente em intervalo definido | Agendador automático |

Um Check pode suportar múltiplos modos — o campo `execution_modes` é uma lista.

---

## 10. Resultados

| Resultado | Significado | Gera Finding? | Bloqueia? |
|---|---|---|---|
| **Pass** | Condição satisfeita; sistema conforme a regra | Não | Não |
| **Fail** | Violação confirmada; condição não satisfeita | Sim — com `severity_default` do Check | Quando `blocking: true` e Evidence suficiente |
| **Warning** | Condição relevante sem violação bloqueante | Pode gerar Finding de severidade Info/Low | Nunca |
| **Not Applicable** | A regra não se aplica ao contexto avaliado | Não | Não |
| **Indeterminate** | Evidence insuficiente para concluir | Pode gerar Finding de Governance se recorrente | Não diretamente |
| **Error** | O Check não pôde executar corretamente | Pode gerar Finding operacional separado | Não |

### Regras sobre resultados

- **Indeterminate ≠ Pass.** Indeterminate significa ausência de evidência suficiente — não é confirmação de conformidade. Tratar Indeterminate como Pass mascara risco.
- **Error NÃO gera automaticamente Finding da regra original.** Se o Check falhou ao executar, não se pode concluir que a regra foi violada. O Error pode gerar Finding operacional sobre falha do mecanismo da Diligence — são dois Findings conceitualmente distintos.
- **Not Applicable é resultado explícito e válido.** Deve ser registrado como Not Applicable com justificativa — nunca como ausência de avaliação nem confundido com Pass.
- **Warning NÃO implica Fail.** Identifica algo digno de atenção sem violação bloqueante.

---

## 11. Política de bloqueio

Um Check com `blocking: true` pode impedir transições de estado quando retorna Fail. Para que o bloqueio seja válido, **todos** os critérios abaixo devem ser satisfeitos simultaneamente:

1. `blocking: true` declarado no catálogo
2. `source_of_truth` canônico identificado — a regra tem fundamento normativo documentado
3. Resultado é **Fail** (não Warning, Indeterminate ou Error)
4. Evidence suficiente foi coletada para suportar o Fail
5. `failure_condition` documentada — existe instrução sobre como resolver
6. Owner ou alvo de escalação identificado
7. Check não tem `severity_default: Info` — Checks Info nunca bloqueam

O campo `blocking_scope` declara quais transições específicas o Check pode bloquear (ex: Promote, Close, Registry Update, Waiver Activation, Repair).

**Checks com `severity_default: Info` nunca bloqueam**, independente de `blocking: true`.

**Waiver pode suspender o bloqueio** quando `waiver_allowed: true` e o Waiver satisfaz todos os critérios de validade.

### Checks bloqueantes no catálogo v1.0.0

| Check ID | blocking_scope |
|---|---|
| DIL-STR-001 | Registry Update |
| DIL-STR-003 | Registry Update |
| DIL-TRC-001 | Promote, Close |
| DIL-TRC-002 | Promote, Repair |
| DIL-TRC-004 | Repair |
| DIL-TRC-005 | Waiver Activation |
| DIL-OPS-003 | Close |
| DIL-OPS-004 | Close |
| DIL-OPS-005 | Waiver Activation |
| DIL-TMP-001 | Waiver Activation, Promote |
| DIL-RDY-001 | Promote, Iteration Plan Entry |
| DIL-RDY-002 | Promote |

---

## 12. Política de Waiver

`waiver_allowed: true` (padrão quando não declarado) significa que um Waiver válido pode suspender o bloqueio gerado por este Check.

`waiver_allowed: false` significa que **nenhum Waiver pode suspender o bloqueio**. Esta declaração é usada com critério extremo — apenas quando a condição representa risco estrutural que não pode ser gerenciado por aceitação temporária.

### Checks com `waiver_allowed: false` no catálogo v1.0.0

| Check ID | Justificativa |
|---|---|
| DIL-STR-001 | Usar path incorreto torna o ID não-rastreável por qualquer mecanismo; não há modo seguro de conviver com arquivo em path errado |
| DIL-STR-003 | ID duplicado torna rastreabilidade estruturalmente impossível; não há modo seguro de operar com IDs duplicados ativos |
| DIL-TRC-004 | Remediation sem Finding válido não tem critério de conclusão verificável — é operacionalmente vazia |
| DIL-TRC-005 | Waiver sem Finding válido não tem significado semântico — não há entidade para dispensar |
| DIL-OPS-004 | Dispensar verificação independente destrói a integridade do ciclo de auditoria |
| DIL-OPS-005 | Waiver impropriamente documentado é violação de governança por definição — não pode ser autorizado por outro Waiver |
| DIL-TMP-001 | Tolerar Waiver expirado como Active é renovação automática disfarçada — viola a política de expiração obrigatória |

**Critério para declarar `waiver_allowed: false`:** a condição representa perda irreversível de rastreabilidade, ou a condição invalida o próprio mecanismo de governança que permitiria o Waiver.

---

## 13. Política de auto_finding

`auto_finding: true` indica que o ciclo pode criar o Finding automaticamente quando o resultado é Fail, sem intervenção humana.

`auto_finding: false` indica que a criação do Finding requer revisão humana mesmo quando o resultado é Fail — o agente prepara o Finding mas não o registra sozinho.

### Quando `auto_finding: true` é seguro

- A condição é objetivamente verificável por inspeção de arquivos ou APIs
- O sujeito é sempre identificável sem ambiguidade
- O source_of_truth é um arquivo canônico acessível
- Falsos positivos têm baixo custo de resolução
- A regra tem critérios de Fail/Pass não ambíguos

### Quando `auto_finding: false` é necessário

- A avaliação requer julgamento sobre intenção ou contexto de negócio
- O resultado pode ser afetado por condições que o agente não pode acessar
- A condição detectada tem alto custo de falso positivo
- O vocabulário ou classificação requer interpretação normativa
- A regra avalia documentos normativos com nuance histórica

---

## 14. Política de revisão humana

`human_review_required` é independente de `auto_finding`:

| `auto_finding` | `human_review_required` | Significado |
|---|---|---|
| `true` | `false` | Finding criado automaticamente; segue para Acknowledged sem revisão |
| `true` | `true` | Finding criado automaticamente; requer confirmação humana antes de Acknowledged |
| `false` | `true` | Finding preparado pelo agente; revisão humana decide se registra |
| `false` | `false` | Raro — implica que o agente decide não criar mesmo sem automação |

`human_review_required: true` é obrigatório quando:
- A condição envolve vocabulário ou classificação normativa (Conceptual)
- O bloqueio pode impactar decisões de produto (promoção de OBC)
- Verificação independente é requisito do modelo (DIL-OPS-004)
- A condição requer análise de intenção ou contexto não estruturado

---

## 15. Evidence

Cada Check declara `evidence_required` — lista concreta do que deve ser coletado para suportar o resultado. Evidence genérica ("prova de que a condição existe") não é suficiente.

### Princípios de Evidence para Checks

- Evidence deve ser **mínima e suficiente** — o mínimo necessário para suportar a conclusão
- Evidence deve ser **concreta** — path de arquivo, valor de campo, saída de comando, resultado de API
- Evidence deve ser **reproduzível** — outro agente ou humano deve poder verificar independentemente
- Evidence deve incluir **contexto temporal** — quando foi coletada e o que representava naquele momento

### Hierarquia de preferência

1. Command Output / API Response — reproduzível, verificável
2. File content / Document path — referenciável, estável
3. Log output — gerado por sistema, rastreável
4. Human observation — último recurso com justificativa

---

## 16. Subjects (Sujeitos)

Cada Check tem um `subject_type` — lista dos tipos de entidade que o Check avalia:

| Tipo | Exemplos |
|---|---|
| **Document** | Arquivo Markdown normativo, arquivo de entidade da Diligence |
| **Finding** | Arquivo FND-YYYY-NNNN.md |
| **Evidence** | Arquivo EVD-YYYY-NNNN.md |
| **Remediation** | Arquivo RMD-YYYY-NNNN.md |
| **Waiver** | Arquivo WVR-YYYY-NNNN.md |
| **Work Item** | GitHub Issue, PR |
| **Artifact** | OBC, BDD Feature, Reliability Plan, Business Signal |
| **Workspace** | GitHub Project, configuração de workspace |

**Sujeito primário** é o objeto principal que o Check avalia e que aparece na chave de deduplicação. **Sujeitos relacionados** podem ser referenciados na Evidence mas não definem a chave de deduplicação.

---

## 17. Deduplicação

A chave padrão de deduplicação é:

```
check_id + primary_subject + condition + scope
```

Esta chave determina se um resultado Fail deve criar novo Finding ou atualizar Finding existente:

- **Atualizar** quando: mesma chave + Finding está Open/Acknowledged/In Remediation + mesmo contexto operacional
- **Criar novo** quando: sujeito diferente, causa diferente, escopo diferente, Finding anterior Closed, regra mudou materialmente

Cada Check pode declarar `deduplication_key` específica no catálogo — quando declarada, prevalece sobre o padrão. O padrão global é definido em `defaults.deduplication_key`.

---

## 18. Integração com ciclos

| Ciclo | Fases | Checks aplicáveis |
|---|---|---|
| **diligence-sync** | Capture | Checks conceituais e estruturais de captura de estado |
| | Attach | DIL-TRC-001 (Work Item com referência válida), DIL-TRC-002 (referência resolve) |
| | Promote | DIL-RDY-001 (Reliability Plan quando necessário), DIL-RDY-002 (critérios de promoção) |
| | Close | DIL-OPS-003 (Work Item closure ≠ Finding closure), DIL-OPS-004 (verificação independente) |
| **diligence-async** | Scan | DIL-CON-001, DIL-CON-002, DIL-STR-001, DIL-STR-002, DIL-STR-003, DIL-TRC-002, DIL-TRC-003, DIL-TRC-004, DIL-TRC-005, DIL-OPS-001, DIL-OPS-002, DIL-OPS-005, DIL-TMP-001, DIL-WSP-001 |
| | Flag | Todos os Checks que produziram Fail no Scan |
| | Repair | DIL-TRC-004, DIL-TRC-002, DIL-OPS-003, DIL-OPS-004 |
| **workspace-reconciliation** | Inspect | DIL-WSP-001 |
| (Capability) | Reconcile | Remediations de DIL-WSP-001 |
| | Verify | Verificação pós-reconciliação de DIL-WSP-001 |

---

## 19. Como adicionar Check

1. **Definir necessidade** — identificar a regra normativa que justifica o Check; localizar o `source_of_truth`
2. **Determinar ID** — escolher prefixo baseado na `primary_dimension` e categoria; usar próximo sequencial disponível para o prefixo
3. **Definir campos obrigatórios** — todos os campos marcados como obrigatórios no schema de `model/check.md` devem estar presentes

**Campos obrigatórios mínimos:**
```yaml
- id               # DIL-XXX-NNN
- version          # inteiro, inicia em 1
- status           # Active
- name             # nome legível
- description      # descrição completa
- primary_dimension # uma das cinco canônicas
- category         # da lista canônica
- type             # da lista canônica
- execution_modes  # lista com pelo menos um modo
- cycles           # lista com pelo menos um ciclo
- phases           # lista com pelo menos uma fase
- source_of_truth  # lista com pelo menos um path/referência
- expected_condition
- failure_condition
- not_applicable_condition
- severity_default
- blocking
- blocking_scope
- waiver_allowed
- auto_finding
- human_review_required
- evidence_required  # lista de pelo menos um item concreto
- subject_type       # lista de pelo menos um tipo
- deduplication_key
- remediation_hint
- escalation_targets
```

4. **Declarar `waiver_allowed: false` apenas com justificativa explícita** — documentar em `notes`
5. **Submeter para revisão** — mudança em `catalog.yaml` deve ser revisada em Pull Request

---

## 20. Como alterar Check

### Mudança não-material (editorial)

Corrigir texto, adicionar exemplos, melhorar `remediation_hint` sem mudar critério de Pass/Fail. Pode ser commitado diretamente sem incrementar `version`. Documentar brevemente em `notes` o que foi corrigido.

### Mudança material

1. Incrementar o campo `version` (inteiro)
2. Documentar o que mudou em `notes` (qual campo mudou e por quê)
3. Avaliar Findings existentes criados com a versão anterior:
   - Se a nova regra tornaria o Finding inválido → classificar como `Invalid Rule` no Finding
   - Se o Finding ainda é válido com a nova regra → registrar na trail do Finding que a regra foi atualizada
4. Submeter em Pull Request com descrição da mudança e impacto nos Findings existentes

---

## 21. Como descontinuar Check

**Nunca deletar um Check do catálogo. Nunca reutilizar um ID.**

Para descontinuar:

1. Alterar `status` de `Active` para `Deprecated` ou `Retired`
   - `Deprecated`: o Check ainda pode ser referenciado mas não deve ser executado em novos ciclos
   - `Retired`: o Check foi definitivamente aposentado; Findings criados por ele são históricos
2. Adicionar `superseded_by: DIL-XXX-NNN` se um novo Check substitui este
3. Documentar a razão em `notes`
4. **Não alterar o `id`** — IDs são imutáveis
5. **Não remover o Check do arquivo** — mesmo Retired permanece no catálogo para referência histórica

Findings criados por Check Deprecated/Retired permanecem válidos com seu `check_id`. Se o Finding ainda é relevante, reclassificar com o ID do Check substituto se houver (`superseded_by`).

---

## 22. Anti-padrões

| # | Anti-padrão | Por que é errado |
|---|---|---|
| 1 | Criar Check sem `source_of_truth` | Check sem fundamento normativo é regra arbitrária — bloqueios sem fundamento são incontestáveis |
| 2 | Reutilizar ID de Check descontinuado | Findings históricos perdem referência válida; rastreabilidade quebrada |
| 3 | Deletar Check do catálogo | Findings que referenciam o Check perdem `check_id` válido; histórico de auditoria quebrado |
| 4 | Tratar resultado Indeterminate como Pass | Indeterminate significa evidência insuficiente — não é confirmação de conformidade |
| 5 | Tratar resultado Error como Fail da regra original | Error significa que o Check não executou — não que a regra foi violada |
| 6 | Criar Check para regra que não existe em documento normativo | Checks devem refletir regras já documentadas — não inventar novas regras no catálogo |
| 7 | Declarar `waiver_allowed: false` sem justificativa | Restrição extrema deve ter razão explícita — uso indiscriminado bloqueia governança legítima |
| 8 | Criar Checks que executam outros Checks | Check é regra declarativa — não é executor; a execução pertence ao ciclo |
| 9 | Criar Checks que criam Findings diretamente | Check avalia e retorna resultado; o ciclo decide criar ou atualizar Finding |
| 10 | Declarar `primary_dimension: Readiness` ou `primary_dimension: Workspace` | Readiness e Workspace são categorias/escopos; as cinco dimensões canônicas são as únicas válidas |
| 11 | Criar Check para condição hipotética não observada | Check deve verificar condição real e observável; hipóteses pertencem ao Assessment |
| 12 | Usar `evidence_required` genérico como "prova de que existe" | Evidence deve ser concreta (path de arquivo, saída de comando, valor de campo) |
| 13 | Definir `blocking: true` para Check com `severity_default: Info` | Checks Info nunca bloqueam por regra canônica — a combinação é contraditória |
| 14 | Criar Check que avalia execução de outro Check | Checks avaliam o sistema de trabalho, não a execução dos próprios Checks |
| 15 | Atribuir múltiplas `primary_dimension` | Um Check tem exatamente uma `primary_dimension`; outras dimensões vão em `secondary_dimensions` |
| 16 | Criar Finding para resultado Not Applicable | Not Applicable é resultado válido e correto — não é divergência |
| 17 | Fazer Check de Readiness aplicar-se universalmente | Checks de Readiness têm condições de gatilho; quando o gatilho não existe, resultado é Not Applicable |
| 18 | Usar Workspace Reconciliation como Cycle no `cycles` field | workspace-reconciliation é Capability invocada pelos ciclos; o campo `cycles` aceita apenas diligence-sync e diligence-async |
| 19 | Criar Check sem definir `not_applicable_condition` | Sem critério explícito de Not Applicable, Check pode ser aplicado onde não deveria |
| 20 | Fazer `auto_finding: true` para Check conceitual ou de vocabulário | Checks conceituais requerem julgamento humano sobre intenção; `auto_finding: false` é obrigatório |
| 21 | Tratar severidade como prioridade no Check | `severity_default` descreve impacto intrínseco da condição; prioridade de resolução depende de contexto externo |
| 22 | Criar Check com `failure_condition` idêntica à `expected_condition` negada | `failure_condition` deve descrever o estado de falha com especificidade — não apenas a negação do estado de Pass |
| 23 | Omitir `indeterminate_condition` e `error_condition` | Sem definição destes resultados, o avaliador não sabe como proceder em casos limítrofes |
| 24 | Incrementar `version` para mudança editorial | Versionamento deve ser reservado para mudanças materiais — incrementar para todo commit dilui o sinal de mudança de regra |

---

## 23. Exemplos

### Exemplo 1 — Check Structural com auto_finding (DIL-STR-002)

**Cenário:** diligence-async Scan executa DIL-STR-002.

```
1. Ciclo lê registry.yaml → 3 entidades listadas: FND-2026-0001, FND-2026-0002, FND-2026-0003
2. Ciclo lista arquivos em findings/ → 2 arquivos: FND-2026-0001.md, FND-2026-0002.md
3. FND-2026-0003 está no registry mas não tem arquivo → divergência
4. auto_finding: true → ciclo cria Finding sem intervenção humana
5. Finding DIL-STR-002 criado: "FND-2026-0003 no registry sem arquivo correspondente"
6. Evidence: lista de IDs no registry + lista de arquivos em findings/ (diff)
7. Resultado registrado no trail do ciclo Scan
```

**O que NÃO ocorre:** o ciclo não corrige o registry automaticamente durante Scan. Repair é a fase que executa correções.

---

### Exemplo 2 — Check Conceptual com human_review (DIL-CON-001)

**Cenário:** diligence-async Scan detecta possível vocabulário não canônico.

```
1. Ciclo lê documento normativo framework/journeys/diligence/README.md
2. DIL-CON-001 identifica referência a "Workspace Reconciliation Cycle"
3. auto_finding: false → ciclo prepara Finding mas NÃO registra automaticamente
4. human_review_required: true → agente apresenta para revisão humana
5. Revisão humana confirma: "Workspace Reconciliation Cycle" é uso incorreto (deveria ser "Capability")
6. Finding criado após confirmação: "Classificação incorreta de Workspace Reconciliation como Cycle"
7. Evidence: path do documento, seção, trecho exato com o termo incorreto
```

**Decisão do humano:** confirmar ou descartar o Finding preparado.

---

### Exemplo 3 — Check que NUNCA pode retornar Fail (DIL-OPS-001)

**Cenário:** diligence-async Scan avalia Business Signal sem operação ativa.

```
1. Ciclo lê tracking-list.md
2. DIL-OPS-001 avalia Business Signal SIG-042: sem marcação de operação ativa
3. Resultado: Pass (ausência de Work Item é o estado correto)
4. Trail do ciclo: "SIG-042 avaliado em 2026-07-24; Signal passivo; ausência de Work Item confirmada como correta"
5. Nenhum Finding criado
```

**Se um avaliador tentasse registrar Fail:** isso seria violação do modelo N:M — a própria tentativa de Fail constitui a divergência a reportar (não o Signal).

---

### Exemplo 4 — Check bloqueante com waiver_allowed: false (DIL-TMP-001)

**Cenário:** Waiver WVR-2026-0001 tem expires_at: 2026-07-20 e ainda está Active em 2026-07-24.

```
1. diligence-async Scan executa DIL-TMP-001 em varredura periódica
2. Resultado: Fail — expires_at (2026-07-20) < data atual (2026-07-24) e status = Active
3. auto_finding: true → Finding criado automaticamente: "Waiver WVR-2026-0001 expirado ainda Active"
4. blocking: true, blocking_scope: [Waiver Activation, Promote] → promoção bloqueada
5. waiver_allowed: false → nenhum novo Waiver pode suspender este bloqueio
6. Evidence: valor do campo expires_at, data atual, status observado do Waiver
7. Remediation necessária: atualizar status do Waiver para Expired; owner do Finding notificado
8. Finding retorna para Acknowledged → nova decisão consciente necessária
```

**Consequência:** o owner deve decidir: criar nova Remediation ou criar novo Waiver (WVR-2026-0002) com nova justificativa.

---

## 24. Escopo da primeira versão

### O que o catálogo v1.0.0 cobre

O catálogo v1.0.0 contém 18 Checks cobrindo:

- **Conceitual** (2 Checks): vocabulário e classificação ontológica em documentos normativos
- **Estrutural** (3 Checks): path de arquivos de entidade, consistência do registry, unicidade de IDs
- **Rastreabilidade** (5 Checks): referências de Work Item, resolução de artefatos, Check em Finding, Finding em Remediation, Finding em Waiver
- **Operacional** (5 Checks): modelo N:M de Signal, operação ativa sem Work Item, fechamento de Work Item vs. Finding, verificação independente, campos obrigatórios de Waiver
- **Temporal** (1 Check): Waiver expirado não pode estar Active
- **Readiness** (2 Checks, primary_dimension: Operational): Reliability Plan condicional, critérios de promoção
- **Workspace** (1 Check, primary_dimension: Structural): conformidade do schema do GitHub workspace

### O que NÃO está coberto nesta versão (intencionalmente)

- Checks sobre estado de OBC (Draft, Refining, Committed, In Delivery, Operational) — requer mapeamento completo de transições
- Checks sobre BDD Features (presença, completude, critérios de aceite)
- Checks sobre Reliability Plan (conteúdo, completude, revisão periódica)
- Checks sobre Release Trail (entradas, evidências de Release)
- Checks sobre Iteration Plan (critérios de entrada, saída, priorização)
- Checks de Observabilidade (métricas, SLOs, alertas)
- Checks de Segurança (aprovações, controles de acesso)
- Automação de execução de Checks — o catálogo é declarativo; execução é responsabilidade dos ciclos
- Schema do GitHub Project para espelhamento de Findings — representação sem tornar Issue fonte de verdade

### Limitações explícitas desta versão

- Nenhum executor automático existe para os Checks declarados
- Geração de IDs de Finding é manual (protocolo documentado em `artifacts/diligence/README.md`)
- GitHub Project schema para espelhamento de entidades Diligence não está definido
- Companion em inglês não criado para este README

---

## Referências

→ [Modelo canônico do Check](../model/check.md) — schema completo, tipos, resultados, política de bloqueio
→ [Catálogo de Checks](catalog.yaml) — definições canônicas de todos os Checks desta versão
→ [Modelo canônico do Finding](../model/finding.md) — o que um Check cria quando Fail
→ [Instrução de persistência](../../../../artifacts/diligence/README.md) — onde armazenar o que Checks produzem
→ [Jornada Diligence](../README.md) — contexto completo dos ciclos que executam Checks
→ [manifest.yaml](../../../../exec/manifest.yaml) — localização canônica declarada por máquina
→ [knowledge-vs-execution.md](../../../../framework/knowledge-vs-execution.md) — modelo N:M (relevante para DIL-OPS-001 e DIL-OPS-002)
