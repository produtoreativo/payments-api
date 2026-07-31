# Check — Definição Canônica

## Definição

> **Check é uma regra declarativa, reproduzível e verificável usada pela Diligence para avaliar uma condição do sistema de trabalho.**

Um Check define O QUE deve ser avaliado e qual resultado é esperado. Não define quando ou quem avalia — isso é determinado pelos ciclos da Diligence e pelo modo de execução. Um Check bem definido produz resultados consistentes independentemente de quem o executa ou quando.

---

## Formato de ID

```
DIL-[CATEGORY]-NNN
```

- `DIL`: prefixo imutável da Diligence
- `[CATEGORY]`: abreviação de 3 letras da categoria do Finding que o Check pode gerar:
  - `ART` — Artifact
  - `BKL` — Backlog
  - `WIT` — Work Item
  - `EXM` — Execution Mapping
  - `DOC` — Documentation
  - `WSP` — Workspace
  - `RDY` — Readiness
  - `REL` — Reliability
  - `OBS` — Observability
  - `SEC` — Security
  - `RLS` — Release
  - `EVD` — Evidence
  - `GOV` — Governance
  - `TRC` — Traceability
  - `OPS` — Operational
  - `STR` — Structural
- `NNN`: sequencial de três dígitos por categoria (001–999)

O ID é estável mesmo quando a implementação do Check muda. A versão do Check é rastreada separadamente no campo `version`.

Exemplos: `DIL-TRC-001`, `DIL-STR-007`, `DIL-OPS-003`, `DIL-RDY-002`

---

## Schema

| Campo | Tipo conceitual | Cardinalidade | Regras e exemplos |
|---|---|---|---|
| `id` | string | 1 | Formato DIL-CATEGORY-NNN; imutável; único no catálogo |
| `name` | string | 1 | Nome legível por humano; deve indicar claramente o que é verificado. Ex: "Work Item possui Artifact ID válido" |
| `description` | text | 1 | Descrição completa do que o Check avalia, por que é importante e quando é aplicável |
| `dimension` | enum | 1 primária | Conceptual, Structural, Traceability, Operational ou Temporal — ver `finding.md` para definições |
| `category` | enum | 1 | Mesma lista de categorias do Finding: Artifact, Backlog, Work Item, Execution Mapping, Documentation, Workspace, Readiness, Reliability, Observability, Security, Release, Evidence, Governance |
| `scope` | text | 1 | O que o Check avalia: artefatos específicos, todos os OBCs ativos, Work Items abertos, GitHub Workspace, etc. |
| `rule` | text | 1 | A regra declarativa: "Para todo X no estado Y, Z deve existir/conter/referenciar W" |
| `severity_default` | enum | 1 | Severidade padrão do Finding gerado quando o Check falha: Critical, High, Medium, Low ou Info. Pode ser ajustada por contexto |
| `blocking` | boolean | 1 | `true` se o Check pode bloquear transições de estado; `false` se é apenas informativo. Info checks nunca são blocking |
| `execution_mode` | enum | 1 | Sync, Async, Manual, Event-driven ou Scheduled — ver seção abaixo |
| `trigger` | text | 1 | O que aciona a execução: evento específico, fase do ciclo, período, solicitação |
| `inputs` | list | 1..N | O que o Check lê: arquivos, APIs, Work Items, estados de artefatos |
| `source_of_truth` | string | 1 | Referência canônica que fundamenta a regra. Ex: `prodops/framework/execution-mapping/work-item-schema.md` |
| `expected_condition` | text | 1 | Descreve o que constitui resultado Pass — estado do sistema quando tudo está correto |
| `failure_condition` | text | 1 | Descreve o que constitui resultado Fail — estado do sistema que viola a regra |
| `evidence_required` | text | 1 | Que evidência deve ser coletada: o que capturar, de onde, com que formato |
| `automation_level` | enum | 1 | Nível atual de automação: Manual, Automated, Partial |
| `owner` | string | 1 | Papel responsável pela definição e manutenção do Check |
| `version` | string | 1 | Versão semântica da regra do Check. Ex: `1.0.0`, `1.2.1`. Muda quando a regra muda — não quando a implementação muda |
| `waiver_allowed` | boolean | 0..1 | Se ausente, assume `true`. Quando `false`, nenhum Waiver pode suspender o bloqueio gerado por este Check |

---

## Taxonomia de tipos de Check

Um Check tem um tipo primário e pode ter tipos secundários opcionais.

| Tipo | Definição | Exemplo de regra |
|---|---|---|
| **Presence** | Verifica existência obrigatória de algo | "BDD Feature deve existir para OBC em Iteration Plan" |
| **Absence** | Verifica ausência de algo que não deveria estar presente | "Work Item fechado não deve ter operações ativas abertas referenciando-o" |
| **Validity** | Verifica que um valor ou referência é válido e existe | "artifact_id no Work Item deve referenciar artefato existente no repositório" |
| **Consistency** | Compara duas ou mais fontes ou estados | "Estado do OBC no arquivo Markdown deve ser consistente com o estado no GitHub Project Field" |
| **Completeness** | Verifica que campos obrigatórios estão preenchidos com valores aceitáveis | "Work Item deve ter artifact_type, artifact_id, operation e journey preenchidos" |
| **Traceability** | Verifica cadeia de relações entre entidades | "Todo OBC em In Delivery deve ter ao menos um Work Item de implementação aberto" |
| **Readiness** | Verifica pré-condições para avanço | "OBC no Iteration Plan deve ter BDD Feature Committed" |
| **Freshness** | Verifica validade temporal de informação | "Waiver não deve estar expirado para Finding com status Waived" |
| **Conformance** | Verifica aderência a schema ou configuração | "GitHub Project deve ter todos os campos canônicos definidos em github-workspace.md" |
| **Outcome** | Verifica que Evidence suporta o resultado declarado | "Finding Resolved deve ter Evidence de resolução coletada" |

---

## Modos de execução

| Modo | Definição | Acionado por | Exemplo |
|---|---|---|---|
| **Sync** | Executado dentro de uma transição ou operação em andamento | Fase de ciclo diligence-sync | Check de Readiness no step Promote |
| **Async** | Executado fora da transação principal | Varredura periódica diligence-async | Check de completude de Work Items no Scan |
| **Manual** | Executado sob solicitação explícita | Pedido humano ou bootstrap | Auditoria de vocabulário em documentos normativos |
| **Event-driven** | Disparado por evento técnico ou operacional | PR aberto, OBC state mudado, documento editado | Check de rastreabilidade disparado por PR |
| **Scheduled** | Executado periodicamente em intervalo definido | Agendador | Check semanal de Waivers expirados |

---

## Resultados do Check

| Resultado | Significado | Gera Finding? |
|---|---|---|
| **Pass** | Condição satisfeita; sistema conforme a regra | Não |
| **Fail** | Violação confirmada; condição não satisfeita | Sim — Finding com `severity_default` do Check |
| **Warning** | Condição relevante detectada sem violação bloqueante | Pode gerar Finding com severidade Info ou Low; depende da definição do Check |
| **Not Applicable** | A regra não se aplica ao contexto avaliado | Não |
| **Indeterminate** | Evidence insuficiente ou informação inadequada para concluir | Pode gerar Finding de Governance se recorrente; requer escalação |
| **Error** | O Check não pôde executar corretamente | Pode gerar Finding operacional sobre falha do mecanismo Diligence; NÃO gera Finding da regra original |

### Regras sobre resultados

- **Indeterminate ≠ Pass.** Indeterminate significa que não há evidências suficientes para confirmar conformidade — não é confirmação de que tudo está bem.
- **Error NÃO gera automaticamente Finding da regra original.** Se o Check falhou ao executar, não se pode concluir que a regra foi violada. O Error pode gerar um Finding operacional separado sobre a falha do mecanismo da Diligence.
- **Warning NÃO implica Fail.** Um Check que retorna Warning identificou algo digno de atenção, mas sem violação bloqueante da regra.
- **Not Applicable é resultado válido e explícito.** Não registrar como Pass nem como ausência de avaliação — registrar como Not Applicable com justificativa.

---

## Regra de bloqueio

Um Check marcado com `blocking: true` pode impedir transições de estado quando retorna Fail.

Para que o bloqueio seja válido, TODOS os critérios abaixo devem ser satisfeitos:

1. `blocking: true` declarado na definição do Check
2. Existe `source_of_truth` canônico identificado — a regra tem fundamento normativo documentado
3. Resultado é Fail (não Warning, Indeterminate ou Error)
4. Evidence suficiente foi coletada para suportar o resultado Fail
5. `failure_condition` está documentada — existe instrução sobre como resolver
6. Owner ou alvo de escalação identificado

**Checks com resultado Info nunca bloqueam**, independentemente de `blocking: true`.

**Waiver pode suspender o bloqueio** quando `waiver_allowed: true` (ou não declarado) e o Waiver satisfaz todos os critérios de validade.

**`waiver_allowed: false`** torna o bloqueio insuspensível por Waiver. Esta declaração deve ser usada com critério — apenas para casos em que a condição representa risco irremediável por aceitação temporária (ex: perda deliberada de rastreabilidade, violação legal confirmada, promoção sem aprovação obrigatória documentada).

---

## Referências

→ [`README.md`](README.md) — modelo de entidades e relações
→ [`finding.md`](finding.md) — entidade gerada pelo Check quando resultado é Fail
→ [`evidence.md`](evidence.md) — evidências coletadas durante execução do Check
→ [`../README.md`](../README.md) — jornada Diligence
→ [`../diligence-async.md`](../diligence-async.md) — ciclo que executa Checks proativos
→ [`../diligence-sync.md`](../diligence-sync.md) — ciclo que executa Checks reativos e bloqueantes
