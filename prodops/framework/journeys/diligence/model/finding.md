# Finding — Definição Canônica

## Definição

> **Finding é o registro persistente de uma divergência, ausência, risco de inconsistência ou condição relevante detectada pela Diligence durante a avaliação do sistema de trabalho.**

Um Finding não é uma GitHub Issue. Um Finding não é um Work Item. Um Finding é um artefato do Knowledge Space com identidade própria, estado próprio e trilha histórica própria. A criação de Work Items para investigar ou tratar um Finding é uma decisão operacional — não automática.

---

## Formato de ID

```
FND-YYYY-NNNN
```

- `FND`: prefixo imutável da entidade Finding
- `YYYY`: ano de criação (quatro dígitos)
- `NNNN`: sequencial de quatro dígitos por ano (0001–9999)

**O ID é imutável.** Não muda quando o estado muda. Não depende de número de GitHub Issue. Sobrevive a migrações de ferramenta.

Exemplos: `FND-2026-0001`, `FND-2026-0042`, `FND-2027-0001`

---

## Schema

| Campo | Tipo conceitual | Cardinalidade | Fonte de verdade | Quem pode alterar | Regras de validação |
|---|---|---|---|---|---|
| `id` | string | 1 | Finding registry | Imutável após criação | Formato FND-YYYY-NNNN; único no sistema |
| `title` | string | 1 | Finding | Diligence (criação); owner (revisão) | Obrigatório; máximo 120 caracteres; deve identificar claramente o sujeito e a condição |
| `description` | text | 1 | Finding | Diligence (criação); owner (revisão com registro em trail) | Obrigatório; deve descrever a condição encontrada, não a correção |
| `dimension` | enum | 1 primária + 0..N secundárias | Finding | Diligence (revisão fundamentada) | Obrigatório; valores: Conceptual, Structural, Traceability, Operational, Temporal |
| `category` | enum | 1 | Finding | Diligence (revisão fundamentada) | Obrigatório; ver lista canônica de categorias abaixo |
| `severity` | enum | 1 | Finding | Diligence (revisão fundamentada) | Obrigatório; valores: Critical, High, Medium, Low, Info |
| `status` | enum | 1 | Finding | Ver fluxo de estados abaixo | Obrigatório; transições documentadas no fluxo de estados |
| `detected_at` | datetime | 1 | Finding | Imutável após criação | Obrigatório; set no momento de criação; nunca alterado |
| `detected_by` | string | 1 | Finding | Imutável após criação | Obrigatório; Check ID se automatizado; identificador humano se manual |
| `check_id` | string | 0..1 | Finding | Imutável após criação | Opcional; formato DIL-CATEGORY-NNN; presente quando gerado por Check automatizado |
| `subjects` | list | 1..N | Finding | Diligence (revisão fundamentada) | Obrigatório; mínimo 1 sujeito; cada sujeito com type + reference + system |
| `artifact_references` | list | 0..N | Finding | Diligence | Opcional; referências a artefatos do Knowledge Space relacionados |
| `execution_references` | list | 0..N | Finding | Diligence | Opcional; referências a Work Items, PRs, Issues relacionados |
| `source_of_truth` | string | 1 | Finding | Diligence (revisão fundamentada) | Obrigatório; path ou referência ao documento canônico que define a regra violada |
| `impact` | text | 1 | Finding | Diligence (criação); owner (revisão com registro) | Obrigatório; descreve o que quebra ou arrisca se a condição não for resolvida |
| `owner` | string | 1 | Finding | Processo de escalação documentado | Obrigatório; papel responsável pela resolução |
| `target_date` | date | 0..1 | Finding | owner ou processo de governança | Opcional; data alvo de resolução |
| `evidence` | list de Evidence IDs | 0..N | Finding | Diligence ao coletar Evidence | Opcional na criação; obrigatório antes de transição para Resolved |
| `remediations` | list de Remediation IDs | 0..N | Finding | Diligence ao criar Remediation | Opcional; atualizado conforme Remediações são criadas |
| `waiver` | Waiver ID ou null | 0..1 | Finding | Processo de Waiver documentado | No máximo um Waiver ativo por escopo/período; null quando sem Waiver ativo |
| `resolution` | text | 0..1 | Finding | owner ou Diligence | Obrigatório quando status = Resolved, Verified ou Closed; descreve como foi resolvido |
| `resolved_at` | datetime | 0..1 | Finding | Diligence | Set quando status transiciona para Resolved |
| `verified_at` | datetime | 0..1 | Finding | Diligence | Set quando status transiciona para Verified |
| `trail` | log append-only | 1..N | Finding | Apenas append — nunca editar entradas anteriores | Obrigatório; cada estado + decisão + evidência + responsável; imutável por entrada |

---

## Cinco dimensões

Um Finding tem UMA dimensão primária e pode ter dimensões secundárias opcionais. Não criar Findings duplicados apenas porque múltiplas dimensões são afetadas — a dimensão primária é a mais relevante para a correção.

### Conceptual

**Definição:** Divergência de conceito, vocabulário, ontologia, responsabilidade, regra, classificação ou intenção entre documentos normativos ou entre a documentação e o entendimento canônico do framework.

**Exemplos:**
- OBC de um produto descreve "OBC Partitioning" como "capability" quando o documento canônico (`ontology.md`) define como "processo de governança"
- `glossary.md` define "Business Signal Issue" como termo canônico quando `knowledge-vs-execution.md` o classifica como anti-padrão
- Documento normativo atribui responsabilidade de priorização de backlog à Diligence quando esta pertence ao Product Owner

### Structural

**Definição:** Divergência de arquivo, diretório, link, template, schema, campo, configuração, View, label ou qualquer elemento estrutural entre o estado real e o estado definido na Canonical Specification.

**Exemplos:**
- Campo obrigatório `operation` ausente no GitHub Project
- Link quebrado em documento de especificação apontando para arquivo inexistente
- Label canônica `artifact-type:local-obc` ausente no repositório
- Arquivo de OBC não segue o template canônico (campos obrigatórios ausentes)

### Traceability

**Definição:** Divergência de referência, relação, origem, dependência, vínculo entre Knowledge Space e Execution Space, ou ruptura na cadeia Signal → Intent → OBC → Work Item → PR → Release.

**Exemplos:**
- Work Item #57 não possui `artifact_id` válido — referência rompida
- Business Signal #BS-042 possui operação ativa identificada mas nenhum Work Item rastreável
- OBC `credit-card` referencia BDD Feature que não existe no repositório
- PR #312 não referencia nenhum Work Item canônico

### Operational

**Definição:** Divergência de estado, transição, owner, critério de entrada/saída, evidência, bloqueio ou operação ativa que viola as regras operacionais do sistema de trabalho.

**Exemplos:**
- OBC em estado Operational com Work Item ainda aberto (Close não foi executado)
- Item promovido ao Iteration Plan sem BDD Feature Committed
- Work Item marcado como Done sem Evidence de conclusão
- OBC em estado In Delivery sem nenhum Work Item de implementação ativo

### Temporal

**Definição:** Informação vencida, snapshot desatualizado, Waiver expirado, Evidence expirada, histórico alterado, ou confusão entre estado atual e registro histórico.

**Exemplos:**
- Waiver WVR-2025-0003 expirou há 30 dias e o Finding continua com status Waived sem nova decisão
- Evidence coletada há 180 dias referencia estado do sistema que já foi alterado (sem `valid_until` declarado)
- `tracking-list.md` contém entrada com vocabulário obsoleto sendo usada como instrução normativa atual
- OBC mostra data de última atualização de 8 meses atrás mas o item está marcado como In Delivery ativa

---

## Categorias

| Categoria | Descrição |
|---|---|
| **Artifact** | Finding sobre conteúdo, estado, completude ou conformidade de artefato do Knowledge Space (OBC, BDD Feature, Reliability Plan, etc.) |
| **Backlog** | Finding sobre consistência entre backlogs, critérios de entrada/saída, priorização ou hierarquia de backlogs |
| **Work Item** | Finding sobre schema, rastreabilidade, estado, owner ou conformidade de Work Items no Execution Space |
| **Execution Mapping** | Finding sobre o mapeamento entre artefatos e Work Items, cardinalidade ou relação KS↔ES |
| **Documentation** | Finding sobre documentação normativa: vocabulário, terminologia, links, referências, templates |
| **Workspace** | Finding sobre infraestrutura do GitHub Workspace: Labels, Fields, Views, Projects (gerenciados pelo Workspace Reconciliation) |
| **Readiness** | Finding sobre pré-condições de transição não satisfeitas: artefatos faltando, critérios não atendidos antes de avanço |
| **Reliability** | Finding sobre Reliability Plans: ausência quando obrigatório, completude insuficiente, revisão vencida |
| **Observability** | Finding sobre Evidence de observabilidade: métricas, SLOs, dashboards, alertas referenciados mas ausentes |
| **Security** | Finding sobre conformidade de segurança: controles, aprovações, revisões de segurança ausentes ou expiradas |
| **Release** | Finding sobre Release Trail: falta de evidência de entrega, state incorreto, rastreabilidade rompida entre Work Item e Release |
| **Evidence** | Finding sobre a própria Evidence: ausência onde obrigatória, expiração, conflito entre fontes, insuficiência |
| **Governance** | Finding sobre conformidade de governança: aprovações, autorizações, Waivers expirados, decisões não registradas |

---

## Severidade

A severidade descreve o impacto intrínseco da condição encontrada. **Severidade não é prioridade.** Prioridade depende de contexto, risco atual, deadline, jornada em curso, impacto de negócio, exposição e custo de correção.

| Severidade | Critérios |
|---|---|
| **Critical** | Pode causar perda irreversível de rastreabilidade; habilita entrega insegura; invalida fonte de verdade canônica; permite avanço não autorizado; representa risco operacional grave; requer bloqueio imediato |
| **High** | Compromete significativamente coerência ou execução; pode levar a decisão incorreta ou entrega falha; requer tratamento prioritário; pode bloquear promoção dependendo do contexto |
| **Medium** | Reduz qualidade, clareza ou rastreabilidade; não requer bloqueio imediato; deve ser corrigido no fluxo normal de trabalho |
| **Low** | Impacto limitado; predominantemente editorial ou organizacional; não compromete decisão ou entrega |
| **Info** | Observação, oportunidade, tendência, sinal antecipado; não é violação obrigatória |

**Regra:** Checks com resultado Info **nunca** bloqueiam. Checks Critical não implicam automaticamente impossibilidade de Waiver — a política `waiver_allowed` da regra define isso.

---

## Fluxo de estados

```
Open → Acknowledged → In Remediation → Resolved → Verified → Closed
                    ↘
                     Waived (Finding permanece visível e rastreável)
                      │
                      └──→ (Waiver expira ou é revogado) → Acknowledged
```

| Estado | Significado | Quem pode transicionar |
|---|---|---|
| **Open** | Detectado; ainda não foi reconhecido formalmente | Diligence (criação automática ou manual) |
| **Acknowledged** | Reconhecido; causa e impacto confirmados; aguardando Remediation | owner ou Diligence |
| **In Remediation** | Remediation em andamento; Work Item ou operação de correção ativa | owner ou Diligence |
| **Resolved** | Correção aplicada; Evidence coletada; aguarda verificação independente | owner ou Diligence; requer evidence preenchida |
| **Verified** | Verificação independente concluída; condição confirmada como resolvida; Evidence de verificação presente | Diligence (verificação independente) |
| **Closed** | Encerrado formalmente com trilha completa; não requer mais ação | Diligence (após Verified ou decisão administrativa) |
| **Waived** | Waiver ativo aprovado; bloqueio suspenso conforme política; Finding permanece visível | Processo de Waiver documentado |

### Casos especiais

**Reabertura:** Um Finding Closed pode ser reaberto se a condição recorrer. A recorrência deve ser documentada como novo evento na trail — NÃO sobrescreve a resolução histórica. Criar novo Finding para nova ocorrência se o contexto mudou significativamente.

**Waiver expirado:** Quando Waiver expira, o Finding retorna automaticamente ao estado Acknowledged (ou Open, se o acknowledged nunca ocorreu). Uma nova decisão é necessária — o sistema não renova Waivers automaticamente.

**Remediation falha:** Se a Remediation for executada mas a condição persistir, o Finding retorna de Resolved para In Remediation. A Evidence da verificação negativa deve ser registrada.

**Falso positivo / Finding inválido:** Ver seção abaixo. O Finding não é deletado — é classificado com tipo de invalidade.

**Mudança de severidade:** Sempre registrada na trail com justificativa. A severidade pode aumentar (nova evidência de impacto) ou diminuir (evidência de mitigação parcial).

**Mudança de owner:** Registrada na trail com motivo. O owner anterior permanece no histórico.

---

## Sujeitos (Subjects)

Todo Finding deve identificar o que foi afetado. Um Finding sem sujeito é irrastreável e irresolvível.

### Tipos de sujeito

| Tipo | Exemplos |
|---|---|
| **Artifact** | OBC, BDD Feature, Reliability Plan, Business Signal, Business Intent |
| **Work Item** | GitHub Issue #57, GitHub Issue #312 |
| **Pull Request** | PR #42 |
| **Release** | Release v2.1.0, Release Trail entry |
| **Project** | GitHub Project "ProdOps — payments-api" |
| **View** | View "Delivery" no GitHub Project |
| **Field** | Campo "Operation" no GitHub Project |
| **Label** | Label "artifact-type:local-obc" |
| **Workflow** | GitHub Actions workflow |
| **Repository** | Repositório payments-api |
| **Workspace** | GitHub Workspace completo |
| **Capability** | Capability "Readiness Verification" |
| **Journey** | Jornada Delivery, jornada Diligence |
| **Document** | `framework/glossary.md`, `framework/ontology.md` |
| **Link** | Link específico em documento |
| **Configuration** | Configuração do GitHub Project, configuração de automação |

### Estrutura de cada sujeito

```
subject:
  type: <tipo da lista acima>
  reference: <referência estável: URI, path, slug ou ID>
  system: <sistema de origem: knowledge-space, github, external>
  classification: primary | related
```

---

## Deduplicação de Findings

### Atualizar Finding existente quando:

- Mesmo Check + mesmo sujeito + mesma condição + mesmo escopo detectado novamente
- Finding existente está nos estados Open, Acknowledged ou In Remediation

Ao atualizar: acrescentar na trail — `last_detected_at`, contagem de ocorrências, impacto atualizado se mudou, nova Evidence referenciada.

### Criar novo Finding quando:

- Sujeito diferente
- Regra violada diferente
- Causa raiz diferente
- Escopo independente
- Finding anterior está Closed e a condição representa recorrência relevante com novo contexto

### Documentar recorrência

Nunca reabrir automaticamente um Finding histórico sem preservar o novo evento. A recorrência é registrada na trail do Finding existente (se reaberto) ou cria novo Finding com referência ao anterior (se Closed e contexto significativamente diferente).

---

## Falso positivo e Finding inválido

Um Finding pode ser classificado como inválido sem ser deletado. **Findings jamais são deletados.**

### Tipos de invalidade

| Tipo | Quando usar |
|---|---|
| **False Positive** | A condição detectada não representa real divergência; o Check avaliou incorretamente |
| **Duplicate** | Este Finding descreve a mesma condição que um Finding anterior já registrado |
| **Invalid Rule** | A regra que gerou o Finding é incorreta ou inaplicável ao contexto |
| **Insufficient Evidence** | A Evidence coletada é insuficiente para confirmar que a condição existe |
| **Superseded** | Uma mudança no sistema de trabalho tornou esta condição irrelevante |

### O que registrar ao invalidar

- Classificação do tipo de invalidade
- Justificativa detalhada
- Responsável pela classificação
- Evidence que suporta a invalidade
- Data de classificação
- Referência ao Finding substituto (se Duplicate)

**Um falso positivo pode revelar problema no Check.** Quando um False Positive é identificado, verificar se a definição ou implementação do Check precisa ser corrigida. Nesse caso, é possível relacionar uma Remediation ao próprio Check.

---

## Política de bloqueio

Um Finding pode bloquear operações do sistema de trabalho quando as seguintes condições são satisfeitas simultaneamente:

| Critério | Descrição |
|---|---|
| `blocking: true` no Check | O Check está marcado como bloqueante na sua definição |
| Fonte normativa canônica | Existe documento que define a regra violada |
| Condição confirmada | A condição foi verificada (resultado Fail, não apenas Warning ou Indeterminate) |
| Evidence suficiente | Evidence adequada foi coletada para suportar o bloqueio |
| Severidade compatível | Checks com resultado Info nunca bloqueiam |
| Instrução de resolução | Existe caminho documentado para resolver o bloqueio |
| Owner ou escalação | Existe responsável identificado para a resolução |

**Um Waiver válido pode suspender o bloqueio** quando a política do Check permite (i.e., quando `waiver_allowed: true` ou não declarado). Alguns Checks podem declarar `waiver_allowed: false` — nesses casos, nenhum Waiver suspende o bloqueio.

Severidade Critical **não** implica automaticamente impossibilidade de Waiver. A declaração `waiver_allowed: false` na regra do Check é o que torna o Waiver impossível.

---

## Integração com os ciclos

### diligence-sync

| Fase | Uso do Finding |
|---|---|
| **Capture** | Pode criar Finding se a captura revela divergência (ex: OBC sem gatilho canônico) |
| **Attach** | Relaciona Work Items a Findings existentes |
| **Promote** | Executa Readiness Checks; Findings bloqueantes impedem a promoção |
| **Close** | Verifica Finding relacionado; atualiza para Verified/Closed se condição resolvida |

### diligence-async

| Fase | Uso do Finding |
|---|---|
| **Scan** | Executa Checks; prepara Evidence de detecção |
| **Flag** | Cria Finding (se novo) ou atualiza Finding existente (se recorrência) |
| **Repair** | Executa Remediation; atualiza Finding para In Remediation ou Resolved |

### Workspace Reconciliation

| Step | Uso do Finding |
|---|---|
| **Inspect** | Produz Evidence estrutural; pode revelar Finding (registrado na volta ao ciclo chamador) |
| **Reconcile** | Executa Remediation autorizada |
| **Verify** | Produz Evidence de verificação; atualiza Finding para Verified quando condição resolvida |

---

## Matriz: Dimensão × Consistência

| Dimensão | Exemplos de Check | Exemplos de Finding | Evidence esperada | Remediation típica |
|---|---|---|---|---|
| **Conceptual** | Verificar vocabulário canônico em documento normativo | OBC Partitioning chamada de "capability" em `glossary.md` quando deveria ser "processo de governança" | Trecho do documento com termo incorreto | Atualizar documento com terminologia canônica |
| **Structural** | Verificar campos obrigatórios em Work Item | Work Item #42 sem campo `artifact_id` | Saída de `gh issue view 42 --json body,labels` | Atualizar campos do Work Item com referência ao artefato |
| **Traceability** | Verificar cadeia Signal → Work Item | Business Signal #BS-007 com operação ativa sem Work Item correspondente | `gh issue list` + `tracking-list.md` | Criar Work Item referenciando o Business Signal |
| **Operational** | Verificar estado OBC vs. estado Work Item | OBC "credit-card" está Operational mas Work Item #15 ainda está Open | Arquivo OBC + saída de `gh issue view 15` | Fechar Work Item com Evidence de entrega |
| **Temporal** | Verificar expiração de Waiver | Waiver WVR-2025-0003 expirou há 30 dias | Datas do registro do Waiver | Solicitar nova decisão; reabrir Finding para tratamento |

---

## Cinco exemplos mandatórios

### Exemplo 1 — Work Item sem Artifact ID

**Contexto:** diligence-async Scan detecta Work Item com campo obrigatório ausente.

1. Check de rastreabilidade (DIL-TRC-001) executa durante a fase Scan
2. Finding High criado: "Work Item #57 não possui Artifact ID válido" (FND-2026-0001)
   - `subjects`: `[{type: Work Item, reference: github://issues/57, system: github}]`
   - `source_of_truth`: `prodops/framework/execution-mapping/work-item-schema.md`
3. Evidence EVD-2026-0001 coletada: output de `gh issue view 57 --json body,labels` mostrando campo ausente
4. Remediation RMD-2026-0001 proposta e aprovada: atualizar campos do Work Item com referência ao artefato
5. Work Item de Remediation criado; campos corrigidos
6. Check (DIL-TRC-001) executado novamente → Pass
7. Evidence EVD-2026-0002 coletada: `gh issue view 57 --json body,labels` mostrando campo preenchido
8. Finding atualizado → Resolved → Verified → Closed

**Lição:** Finding vive no Knowledge Space; o Work Item de correção vive no Execution Space; são entidades distintas.

---

### Exemplo 2 — Business Signal passivo sem Issue

**Contexto:** diligence-async Scan avalia Business Signals na tracking list.

1. Check avalia: "Business Signal #BS-042 possui operação ativa sem Work Item rastreável?"
2. Resultado: **Not Applicable** — sinal passivo, sem investigação ativa autorizada, sem operação em andamento
3. Nenhum Finding criado
4. Trail registra: "BS-042 avaliado em 2026-07-23; ausência de Work Item é legítima; nenhuma operação ativa identificada"

**Lição:** Ausência de Issue não é divergência automática. Check que retorna Not Applicable não gera Finding.

---

### Exemplo 3 — Campo obrigatório removido do GitHub Project

**Contexto:** diligence-async Scan detecta drift no workspace.

1. Check estrutural (DIL-STR-007) executa: "Campo 'Operation' existe no GitHub Project?"
2. Finding Medium criado (FND-2026-0002): "Campo obrigatório 'Operation' ausente no GitHub Project 'ProdOps — payments-api'"
   - `subjects`: `[{type: Field, reference: github://projects/payments-api/fields/Operation, system: github}]`
3. Evidence EVD-2026-0003 coletada: saída de `gh project field-list` antes e depois mostrando ausência
4. Workspace Reconciliation invocada como Remediation (RMD-2026-0002): restaurar campo seguindo Canonical Specification
5. Reconcile executa; campo restaurado
6. Evidence EVD-2026-0004 coletada: saída de `gh project field-list` confirmando campo presente
7. Check (DIL-STR-007) executado novamente → Pass
8. Finding → Verified → Closed

**Lição:** Workspace drift é tratado pela Workspace Reconciliation como Remediation; Evidence antes e depois documenta a condição e a resolução.

---

### Exemplo 4 — Reliability Plan ausente quando obrigatório

**Contexto:** diligence-sync Promote detecta pré-condição não satisfeita.

1. Check de Readiness bloqueante (DIL-OPS-003) executa: "Reliability Plan existe para item com movimentação financeira?"
2. OBC "payment-gateway" — movimentação financeira identificada; Reliability Plan ausente
3. Finding High criado (FND-2026-0003): "Reliability Plan ausente para OBC payment-gateway com movimentação financeira"
   - `blocking`: true (Check é bloqueante)
   - `source_of_truth`: `prodops/framework/backlogs.md` (seção: gate condicional)
4. Promoção ao Iteration Plan bloqueada
5. Evidence EVD-2026-0005 coletada: arquivo OBC + Assessment decision referenciando necessidade
6. Remediation RMD-2026-0003: criar Reliability Plan após decisão autorizada pelo Assessment
7. Reliability Plan criado e revisado
8. Evidence EVD-2026-0006: arquivo Reliability Plan criado + revisão documentada
9. Check (DIL-OPS-003) executado novamente → Pass
10. Bloqueio de promoção suspenso; promoção concluída
11. Finding → Verified → Closed

**Lição:** Finding bloqueante impede avanço; Remediation resolve a condição; Check re-executado confirma resolução antes de liberar.

---

### Exemplo 5 — Waiver temporário

**Contexto:** Finding reconhecido; Remediation não pode ser concluída antes da Release.

1. Finding High reconhecido (FND-2026-0004): "Dependência circular entre OBC 'analytics' e OBC 'reporting'"
   - Status: Acknowledged
2. Equipe avalia: refatoração necessária, mas não pode ser concluída antes da Release v2.1.0 (10 dias)
3. Product Owner solicita Waiver; Tech Lead aprova
4. Waiver criado (WVR-2026-0001):
   - `finding_id`: FND-2026-0004
   - `reason`: "Refatoração de dependência circular não pode ser concluída antes da Release v2.1.0; risco mitigado por testes manuais de integração"
   - `expires_at`: 2026-08-07 (14 dias)
   - `compensating_controls`: ["testes manuais de integração antes de cada deploy", "revisão de impacto pelo Tech Lead"]
   - `approved_by`: Tech Lead
5. Finding → Waived; bloqueio de promoção suspenso
6. Finding permanece visível e rastreável com status Waived
7. Waiver expira em 2026-08-07 → Finding retorna a Acknowledged
8. Nova decisão necessária: Remediation concluída (se possível) ou novo Waiver com nova justificativa

**Lição:** Waiver não elimina o Finding; não altera a regra; não declara a condição correta; o Finding permanece rastreável; Waiver expirado exige nova decisão consciente.
