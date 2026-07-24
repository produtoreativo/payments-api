# Diligence — Instâncias de Entidades Operacionais

> **Este diretório armazena instâncias operacionais das entidades da Diligence.**
> O modelo canônico (schemas, estados, regras) vive em `prodops/framework/journeys/diligence/model/`.
> Este diretório contém registros concretos: Findings detectados, Evidence coletada, Remediations planejadas e Waivers aprovados.

→ [Modelo canônico](../../framework/journeys/diligence/model/)
→ [Jornada Diligence](../../framework/journeys/diligence/README.md)
→ [Registry](registry.yaml)

---

## 1. Finalidade

Este diretório existe para armazenar registros persistentes e rastreáveis das entidades operacionais da jornada Diligence que pertencem a este produto.

**Diferença fundamental entre modelo e instâncias:**

| | `framework/journeys/diligence/model/` | `artifacts/diligence/` |
|---|---|---|
| **O que contém** | Schemas, definições canônicas, regras, estados | Registros concretos de Findings, Evidence, Remediations, Waivers |
| **Propósito** | Definir como as entidades devem ser | Armazenar o que foi detectado, coletado, planejado, aprovado |
| **Mutabilidade** | Evolui com o framework | Curado + append-only por entidade |
| **Lido por** | Qualquer agente ou pessoa que precisa entender o modelo | Qualquer agente ou pessoa que precisa operar sobre instâncias concretas |
| **Quem escreve** | Framework Owner | Diligence (ciclos sync e async), owners, aprovadores |

---

## 2. Estrutura de diretórios

```
prodops/artifacts/diligence/
├── README.md         — este arquivo: referência para trabalho com instâncias
├── registry.yaml     — índice estruturado de todas as entidades (índice, não fonte)
├── findings/         — registros canônicos de Finding (um arquivo por Finding)
├── evidence/         — Evidence independente com identidade e ciclo de vida próprios
├── remediations/     — planos e registros de Remediation
├── waivers/          — autorizações de Waiver aprovadas e históricas
└── reports/          — relatórios agregados de execução de Diligence
```

### findings/

Registros persistentes de divergências, ausências, riscos de inconsistência ou condições relevantes detectadas pela Diligence. Um arquivo por Finding. Nomenclatura: `FND-YYYY-NNNN.md`.

### evidence/

Evidence com identidade própria — quando reutilizada por múltiplos Findings, quando prova Remediation ou verificação, quando tem validade temporal, ou quando contém saída técnica relevante para auditoria. Nomenclatura: `EVD-YYYY-NNNN.md`.

Evidence inline (pequena, exclusiva de um Finding, sem reutilização) é incluída diretamente no arquivo do Finding — não tem arquivo próprio.

### remediations/

Planos e registros de operação corretora. Um arquivo por Remediation. Uma Remediation pode endereçar múltiplos Findings. Nomenclatura: `RMD-YYYY-NNNN.md`.

### waivers/

Autorizações explícitas e temporárias para aceitar condições registradas em Findings sem Remediation imediata. Um arquivo por Waiver. Waivers expirados são preservados — nunca removidos. Nomenclatura: `WVR-YYYY-NNNN.md`.

### reports/

Relatórios agregados produzidos por execuções de diligence-async (Scan → Flag → Repair). Não são entidades com ID próprio. Nomenclatura livre — normalmente por data: `YYYY-MM-DD-diligence-report.md`.

---

## 3. Diferença entre modelo e instâncias

O `model/` define **o que uma entidade é** — seu schema, estados válidos, transições, regras de validação, anti-padrões, exemplos conceituais. Nenhum Finding real vive no `model/`.

O `artifacts/diligence/` contém **o que foi detectado** — os registros concretos produzidos pela operação dos ciclos da Diligence sobre este produto. Nenhuma regra normativa vive aqui.

**Exemplo:**
- `model/finding.md` define que um Finding tem campo `severity` com valores `Critical | High | Medium | Low | Info`
- `artifacts/diligence/findings/FND-2026-0001.md` é um Finding real com `severity: High`

---

## 4. Política de IDs

### Formatos

| Entidade | Formato | Exemplo |
|---|---|---|
| Finding | `FND-YYYY-NNNN` | `FND-2026-0001` |
| Evidence | `EVD-YYYY-NNNN` | `EVD-2026-0001` |
| Remediation | `RMD-YYYY-NNNN` | `RMD-2026-0001` |
| Waiver | `WVR-YYYY-NNNN` | `WVR-2026-0001` |

`YYYY` = ano de criação da entidade. `NNNN` = sequencial de quatro dígitos por tipo por ano (0001–9999).

### Imutabilidade

IDs são **imutáveis após criação**. Não mudam quando o estado da entidade muda. Não dependem de números de GitHub Issue. Sobrevivem a migrações de ferramenta.

### Geração de IDs (procedimento manual até automação existir)

1. Ler `registry.yaml`
2. Localizar o maior sequencial para o tipo + ano corrente
3. Verificar os arquivos no diretório correspondente para confirmar
4. Reservar o próximo número (último + 1)
5. Criar o arquivo com o ID reservado
6. Atualizar `registry.yaml` na mesma mudança (mesmo commit)
7. Validar ausência de colisão antes de concluir

### Risco de concorrência

Se dois agentes executam simultaneamente, colisão de ID é possível. Protocolo:
- **Nunca sobrescrever** arquivo existente
- Recalcular o ID se colisão detectada
- Registrar conflito no trail
- Preservar ambos os trabalhos
- **Nunca renumerar entidades já publicadas**

### Reutilização proibida

Um ID cancelado ou removido **nunca é reutilizado**. A sequência sempre avança.

---

## 5. Registry

### Papel

`registry.yaml` é um **índice** — não uma fonte narrativa. O arquivo individual de cada entidade é a fonte de verdade. O registry existe para navegação eficiente e rastreabilidade estruturada.

**O registry DEVE poder ser reconstruído a partir dos arquivos de entidade.**

### Regras

- **Arquivo de entidade sempre prevalece** sobre qualquer resumo no registry
- O registry é atualizado **na mesma mudança** que cria ou modifica uma entidade (mesmo commit)
- **Drift entre registry e arquivos** é detectado pelo Scan da Diligence Async e tratado como Finding estrutural
- Campos no registry: `type`, `path`, `status`, `severity` (apenas Findings), `related`

### Quem atualiza

Qualquer agente ou pessoa que cria ou modifica uma entidade é responsável por atualizar o registry na mesma operação. Não existe "atualizar o registry depois".

### Tratamento de drift

Se o Scan detecta arquivo sem entrada no registry (ou registry com referência para arquivo inexistente), isso gera um Finding estrutural. A reconciliação reconstrói o registry a partir dos arquivos.

---

## 6. Um arquivo por entidade — rationale

Cada Finding, Evidence, Remediation e Waiver tem seu próprio arquivo Markdown porque:

1. **Identidade independente** — cada entidade tem ID, estado e trilha próprios
2. **Evolução de estado** — o arquivo captura todo o ciclo de vida da entidade em um único lugar
3. **Histórico legível** — o trail append-only torna o git log da entidade auditável
4. **PR review** — mudanças em uma entidade específica são revisadas no PR que as afeta
5. **Conflito de merge mínimo** — dois agentes modificando entidades diferentes não conflitam
6. **Relações N:M** — um Finding referencia múltiplas Evidences; uma Evidence pode ser referenciada por múltiplos Findings
7. **Links estáveis** — `artifacts/diligence/findings/FND-2026-0001.md` é um link permanente
8. **Arquivabilidade** — entidades antigas podem ser movidas para arquivo sem quebrar a estrutura
9. **Rastreabilidade Git** — `git log --follow` mostra toda a história de uma entidade

---

## 7. Evidence: inline vs. independente

### Evidence inline (incluída diretamente no arquivo do Finding)

Permitida quando **todos** os critérios abaixo forem verdadeiros:
- É pequena e não prolonga excessivamente o arquivo do Finding
- Pertence exclusivamente a um Finding (sem reutilização)
- Não tem identidade independente necessária
- Não é reutilizada por outras entidades
- Não contém saída técnica extensa
- Não tem ciclo de validade independente

**Exemplos de Evidence inline adequada:**
- Path observado de arquivo ausente
- Valor de campo no momento da detecção
- Link para PR ou commit específico
- Timestamp de detecção
- Excerpt curto de saída de comando

### Evidence independente (deve ter arquivo próprio em `evidence/`)

Obrigatório quando **qualquer** dos critérios abaixo for verdadeiro:
- É usada por múltiplos Findings
- Prova a execução ou resultado de uma Remediation
- Prova a verificação independente de resolução
- Tem validade temporal (pode expirar)
- Requer preservação imutável para auditoria
- Tem origem externa (sistema externo, terceiro)
- Contém saída técnica relevante (log, output de comando, resposta de API)
- Precisa de auditoria independente
- Precisará de ID próprio para referência cruzada
- Pode expirar e ser sucedida por nova coleta
- Contém anexos ou saída extensa
- É produzida por aprovação formal (ex: Evidence de aprovação de Waiver)

---

## 8. Protocolo de Remediation

A Remediation endereça um ou mais Findings ativos. O protocolo completo:

1. **Finding reconhecido** — Finding existe, está Open ou Acknowledged
2. **Estratégia escolhida** — Correct, Prevent, Contain, Compensate, Migrate, Document, Reconcile, Retire
3. **Remediation proposta** — arquivo RMD-YYYY-NNNN.md criado com plano
4. **Owner definido** — papel responsável pela execução identificado
5. **Aprovação quando necessária** — conforme matriz de autoridade
6. **Work Items relacionados** — criados se a operação requer execução rastreável no Execution Space
7. **Implementação** — ação corretora executada
8. **Evidence de implementação** — coletada e registrada
9. **Verificação independente** — por quem não implementou
10. **Evidence de verificação** — coletada e registrada (distinta da Evidence de implementação)
11. **Finding → Verified** — após verificação independente com Evidence
12. **Fechamento** — Finding fecha após verificação; Remediation fecha na mesma mudança

**Princípios críticos:**
- Fechar um GitHub Issue associado **NÃO fecha o Finding**
- `Remediation Implemented` ≠ `Finding Verified` — verificação é etapa independente
- Quem implementou **não** verifica a própria implementação

---

## 9. Protocolo de Waiver

O Waiver autoriza aceitar temporariamente uma condição sem Remediation imediata:

1. **Finding ativo** — Finding existe e está Open ou Acknowledged; não é possível criar Waiver para Finding Closed
2. **Justificativa de impossibilidade ou adiamento** — razão de negócio ou técnica documentada
3. **Escopo delimitado** — o que exatamente está sendo dispensado; deve ser específico
4. **Risco explicitamente declarado** — o que pode acontecer de errado durante a vigência
5. **Controles compensatórios** — medidas em vigor para mitigar o risco aceito
6. **Aprovador autorizado** — conforme matriz de autoridade; nunca aprovação tácita
7. **Data de início** — `valid_from` explícita
8. **Data de expiração** — `expires_at` obrigatória; Waiver sem expiração é inválido
9. **Data de revisão** — `review_date` intermediária recomendada
10. **Evidence de aprovação** — EVD-YYYY-NNNN referenciando a aprovação formal
11. **Ativação** — Finding transiciona para `Waived`; bloqueio suspenso (se Check permitir)
12. **Monitoramento** — condições e controles compensatórios verificados durante vigência
13. **Expiração, revogação ou fechamento** — uma das três deve ocorrer ao final

**Waiver expirado:**
- **NÃO é renovado automaticamente**
- Para de suspender bloqueio imediatamente
- Finding retorna ao fluxo normal de tratamento (status: Acknowledged)
- Requer nova decisão consciente: nova Remediation ou novo Waiver com nova justificativa
- O arquivo do Waiver expirado é preservado com status `Expired`
- Renovação gera **NOVO Waiver** com novo ID (WVR-YYYY-NNNN) — nunca edita `expires_at` retroativamente

---

## 10. Protocolo de criação de Finding

### Fluxo de decisão

```
Check executado (ou observação manual)
          ↓
  resultado Fail ou Warning relevante?
          ↓
    deduplicação executada
          ↓
    Finding já existe?
       ├── sim → atualizar last_detected_at + incrementar occurrence_count + adicionar Evidence
       └── não → gerar ID + registrar novo Finding
          ↓
    classificar: dimensão primária + categoria + severidade
          ↓
    definir owner ou alvo de escalação
          ↓
    avaliar: Remediation necessária? Waiver necessário?
          ↓
    atualizar registry
```

### CRIAR Finding quando

- Condição concreta observável existe
- Sujeito identificável (arquivo, campo, artefato, Work Item)
- Check ou regra canônica existe que define a expectativa
- Evidence mínima foi coletada
- Resultado é Fail (ou Warning com relevância suficiente para registro)
- Deduplicação foi executada e não há Finding ativo para a mesma condição
- Resultado **não** é apenas falha técnica do mecanismo de Check (Error)

### NÃO criar Finding quando

- Resultado do Check é Pass ou Not Applicable
- Não há sujeito identificável
- Não há regra ou Check canônico aplicável
- Não há Evidence mínima coletada
- Há Finding ativo para a mesma condição (deduplicar, não duplicar)
- A condição é hipótese não verificada
- A ausência de Issue é legítima (sem operação ativa)
- O Check falhou tecnicamente (Error) sem confirmar a condição original

---

## 11. Deduplicação

### Chave conceitual de deduplicação

```
check_id + sujeito primário + condição + escopo
```

### Atualizar Finding existente quando

- Mesma chave de deduplicação
- Finding está Open, Acknowledged ou In Remediation
- Nova ocorrência pertence ao mesmo contexto operacional

**O que atualizar:** `last_detected_at`, `occurrence_count` (incrementar), adicionar nova Evidence, atualizar `impact` se mudou.

### Criar novo Finding quando

- A condição reaparece após fechamento (recorrência em novo contexto)
- A causa raiz é diferente
- O contexto é diferente
- O escopo é diferente
- A regra mudou materialmente desde o Finding anterior
- O Finding anterior foi invalidado

**Documentar recorrência:** `recurrence_of: FND-YYYY-NNNN` no front matter do novo Finding. **Nunca reutilizar o mesmo ID.**

---

## 12. Matriz de autoridade e aprovação

| Entidade / Ação | Agente pode preparar | Agente pode registrar | Requer revisão humana | Quem aprova |
|---|---|---|---|---|
| Finding informacional | Sim | Sim | Dependente de política | Diligence Owner |
| Finding bloqueante | Sim | Sim | Sim | Responsável normativo |
| Remediation documental simples | Sim | Sim | Conforme escopo | Owner do artefato |
| Remediation que muda intenção | Não decide | Não conclui sozinho | Sim | Product Owner |
| Waiver | Pode preparar | Não pode ativar sozinho | Sempre | Responsável autorizado |
| Evidence técnica | Sim | Sim | Conforme criticidade | Responsável pela verificação |

---

## 13. Relação com Work Items (N:M preservada)

### Princípios

- Finding **não requer** Issue
- Remediation com trabalho ativo normalmente tem Work Item
- Um Work Item pode tratar múltiplos Findings
- Um Finding pode ter múltiplos Work Items (ao longo de sua vida)
- Waiver **não pode** ser apenas um label em um Issue
- Evidence **não pode** existir apenas como comentário em Issue

### Regras de fechamento

- Fechar Issue **NÃO fecha Finding**
- Reabrir Finding **não** requer reabrir Issue antigo
- Nova operação pode gerar novo Work Item para Finding existente

---

## 14. Commits e Pull Requests

### Finding

- Finding detectado durante operação local: pode ser commitado no mesmo branch da operação que o detectou
- Finding independente: pode usar branch específico
- Finding bloqueante: recomendável PR separado para revisão

### Waiver

- **Deve ser revisado em Pull Request** com aprovador identificável
- O PR é a Evidence de revisão do Waiver
- Nunca commitar ativação de Waiver sem PR rastreável

### Evidence

- Pode ser incluída no mesmo commit da detecção ou verificação
- Evidence de verificação deve ser commitable com o Finding atualizado

### Restrições

- Não é obrigatório um commit por entidade
- Não misturar aprovação de Waiver com implementação silenciosa de Remediation no mesmo commit

---

## 15. Segurança

Evidence **nunca** deve conter:
- Segredos, tokens, senhas, chaves API
- Credenciais de qualquer tipo
- Dados sensíveis de usuários ou clientes
- PII (Personally Identifiable Information)

**Práticas obrigatórias:**
- Sanitizar saídas antes de incluir como Evidence
- Substituir valores sensíveis por `[REDACTED]` ou `[SANITIZED]`
- Referenciar armazenamento seguro externo quando o dado sensível for necessário para a Evidence
- Documentar que sanitização foi aplicada na seção Content da Evidence

---

## 16. Anti-padrões

| # | Anti-padrão | Por que é errado |
|---|---|---|
| 1 | Criar Finding para cada execução de Check sem deduplicação | Polui o registro com duplicatas; perde contagem de recorrências; impossibilita análise de tendências |
| 2 | Usar número de GitHub Issue como ID de Finding | IDs de Finding são imutáveis; Issue number muda em migrações; toda rastreabilidade é quebrada |
| 3 | Deletar Finding resolvido | Perde trilha histórica; recorrências ficam sem contexto; impossibilita auditoria |
| 4 | Fechar Finding sem Evidence | Evidence diferencia resolução verificada de declaração; sem Evidence, o Finding não está realmente resolvido |
| 5 | Tratar Remediation Implemented como Finding automaticamente Verified | Verificação é independente da implementação; a Remediation pode ser parcial ou incorreta |
| 6 | Criar Waiver sem data de expiração | Waiver permanente é tratamento definitivo de divergência que deve ser resolvida; mascara débito técnico indefinidamente |
| 7 | Renovar Waiver editando `expires_at` do Waiver original | Renovação exige novo Waiver com novo ID e nova justificativa; editar retroativamente perde rastreabilidade |
| 8 | Ativar Waiver sem PR com aprovador identificável | Aprovação tácita não é aprovação; Waiver sem aprovador rastreável é inválido |
| 9 | Registrar Evidence apenas como comentário em Issue | Evidence em Issue desaparece ou fica inacessível em migrações; não tem ID próprio; não é referenciável |
| 10 | Criar Finding sem sujeito identificado | Finding sem sujeito é irrastreável e irresolvível; não pode ser atribuído nem verificado |
| 11 | Sobrescrever Evidence histórica com nova coleta | Evidence é imutável; nova coleta cria nova Evidence com novo ID; histórico é preservado |
| 12 | Usar severidade como sinônimo de prioridade | Severidade descreve impacto intrínseco; prioridade depende de contexto, deadline e custo de correção |
| 13 | Bloquear operação sem fonte normativa canônica identificada | Bloqueio requer regra canônica; bloqueio sem fundamento é arbitrário e incontestável |
| 14 | Tratar resultado Error do Check como Fail da regra original | Error significa que o Check não pôde executar; pode gerar Finding operacional, não Finding da regra |
| 15 | Tratar resultado Indeterminate do Check como Pass | Indeterminate significa evidência insuficiente; não é confirmação de conformidade |
| 16 | Permitir que GitHub Project seja fonte de verdade do Finding | Finding vive em `artifacts/diligence/findings/`; GitHub Project pode espelhar estado mas não é a fonte |
| 17 | Criar Remediation sem Finding ativo relacionado | Remediation sem Finding endereçado não tem fundamento; não há critério de conclusão |
| 18 | Criar Finding sem evidence mínima | Finding sem evidência é apenas suspeita; a evidência mínima é o que diferencia Finding de hipótese |
| 19 | Reabrir Finding fechado em vez de criar novo para recorrência | Recorrência após fechamento é condição nova; reabrir perde a separação de contextos |
| 20 | Incluir segredos ou credenciais em Evidence | Evidence é artifact Git; segredos em Git são vazamentos de segurança, mesmo em repos privados |
| 21 | Misturar aprovação de Waiver e implementação de Remediation no mesmo commit | Waiver requer PR com aprovador; Remediation pode ser commit separado; misturar torna auditoria impossível |
| 22 | Considerar que verificação pode ser feita por quem implementou a Remediation | Verificação independente é requisito do modelo; auto-verificação anula o valor do ciclo |
| 23 | Gerar relatório de Diligence em prodops/artifacts/diligence/findings/ | Relatórios agregados vão em reports/; findings/ é exclusivo para arquivos FND-YYYY-NNNN.md |
| 24 | Não atualizar registry.yaml na mesma mudança que cria/modifica entidade | Registry desatualizado é drift imediato; a reconciliação posterior é custosa e propensa a erros |
| 25 | Criar Finding com status Verified sem Evidence de verificação independente | Status Verified sem Evidence é declaração não comprovada; equivalente a não resolver o Finding |

---

## 17. Exemplos conceituais

> **ATENÇÃO: Os exemplos abaixo são FICTÍCIOS. Não representam condições reais deste produto.**
> São usados exclusivamente para ilustrar o modelo de persistência.

---

### Exemplo 1 — Finding informacional resolvido na mesma análise (sem Work Item)

**Contexto:** Durante uma varredura diligence-async, o agente detecta que o arquivo `prodops/artifacts/obcs/feature-x.md` possui o campo `status` com valor `"in-delivery"` (minúsculas, sem hífen no padrão canônico) quando o valor correto é `"In Delivery"` (conforme `ontology.md`).

**O que acontece:**
1. Check DIL-ART-004 executa: "Campos de OBC seguem vocabulário canônico?"
2. Resultado: Fail — valor `"in-delivery"` não pertence ao enum válido
3. Deduplicação: nenhum Finding ativo para este sujeito e condição
4. Finding criado: `FND-2026-0001.md` — severidade Low, dimensão Conceptual, categoria Artifact
5. Evidence inline: valor observado (`"in-delivery"`) e valor esperado (`"In Delivery"`) incluídos diretamente no Finding
6. Remediação imediata: o agente corrige o campo (operação documental simples dentro da autoridade do agente)
7. Check reexecutado: Pass
8. Finding atualizado: status → Verified, Evidence de verificação inline
9. Finding fechado: status → Closed

**Resultado:** Finding aberto e fechado na mesma sessão de análise. Nenhum Work Item criado. Evidence inline suficiente.

---

### Exemplo 2 — Finding com Remediation (Work Item sem Artifact ID no Execution Space)

**Contexto:** Check DIL-TRC-001 detecta que o Work Item #89 (GitHub Issue) está ativo com operação de implementação mas não possui o campo `artifact_id` preenchido — violação do schema de Work Item.

**O que acontece:**
1. Finding criado: `FND-2026-0002.md` — severidade High, dimensão Traceability, categoria Work Item
2. Evidence independente criada: `EVD-2026-0001.md` — Command Output de `gh issue view 89 --json body,labels` mostrando ausência do campo
3. Evidence independente criada porque contém saída técnica relevante e pode ser referenciada em audit futura
4. Remediation criada: `RMD-2026-0001.md` — estratégia Correct, owner: Product Context Engineer
5. Work Item #90 criado no GitHub referenciando a Remediation (o irônico: um Work Item para corrigir um Work Item sem referência)
6. Correção aplicada: campo `artifact_id` preenchido no Issue #89
7. Verificação: Check DIL-TRC-001 reexecutado, resultado Pass
8. Evidence de verificação criada: `EVD-2026-0002.md`
9. Finding → Verified → Closed; Remediation → Verified

**Nota:** O Work Item #90 criado para a Remediation **não** tem Artifact ID no ProdOps — a referência é ao Finding `FND-2026-0002`. Isso é intencional: nem todo Work Item de Diligence referencia um OBC.

---

### Exemplo 3 — Uma Remediation para múltiplos Findings (campo removido de documentação)

**Contexto:** Varredura detecta que o campo `owner` foi removido de três OBCs diferentes durante uma refatoração de template. Isso gera três Findings distintos (sujeitos diferentes), mas uma única Remediation pode corrigir todos.

**O que acontece:**
1. Três Findings criados: `FND-2026-0003.md`, `FND-2026-0004.md`, `FND-2026-0005.md`
2. Todos: dimensão Structural, categoria Artifact, severidade Medium
3. Uma única Remediation criada: `RMD-2026-0002.md` com `finding_ids: [FND-2026-0003, FND-2026-0004, FND-2026-0005]`
4. Estratégia: Correct — restaurar campo `owner` em cada OBC com valor correto
5. Trabalho executado diretamente pelo agente (operação documental simples)
6. Evidence de verificação coletada para cada OBC corrigido (pode ser uma Evidence com três sujeitos ou três Evidences separadas)
7. Todos os três Findings → Verified → Closed
8. Remediation → Verified

**Resultado:** N:M operacional — uma Remediation trata múltiplos Findings. O campo `Project` foi intencionalmente omitido deste exemplo para não criar confusão com GitHub Project.

---

### Exemplo 4 — Waiver (Finding bloqueante, correção impossível antes de deadline)

**Contexto:** Finding `FND-2026-0006.md` detecta que um OBC que entrou no Iteration Plan não possui Reliability Plan (obrigatório para funcionalidades com movimentação financeira). A correção requer Assessment completo (2 semanas) mas a Release está em 5 dias.

**O que acontece:**
1. Finding existe: `FND-2026-0006.md` — severidade High, bloqueante (DIL-RDY-003)
2. Situação: prazo impede Remediation completa antes da Release
3. Justificativa preparada: Release crítica de segurança com prazo regulatório; Reliability Plan será produzido na iteração seguinte; funcionalidade já passou por revisão técnica informal
4. Waiver preparado: `WVR-2026-0001.md` — Finding: FND-2026-0006, escopo delimitado à Release específica
5. `expires_at`: 5 dias (data da Release)
6. `review_date`: 2 dias (revisão intermediária)
7. Controles compensatórios: revisão manual de confiabilidade pelo Tech Lead, monitoramento reforçado nos primeiros 3 dias após Release
8. Risco declarado: ausência de critérios formais de confiabilidade pode deixar falhas latentes não detectadas
9. Waiver vai para PR com aprovador identificável (Tech Lead + Product Owner)
10. Evidence de aprovação criada: `EVD-2026-0003.md` referenciando o PR aprovado
11. Waiver → Active; Finding → Waived; bloqueio suspenso
12. Release acontece
13. 5 dias depois: `expires_at` atingido → Waiver → Expired
14. Finding → Acknowledged (volta ao fluxo normal)
15. Nova Remediation iniciada: `RMD-2026-0003.md` para criar o Reliability Plan

**Resultado:** O Finding permaneceu visível e rastreável durante toda a vigência do Waiver. A Release aconteceu. O trabalho pendente foi retomado imediatamente após expiração.

---

## 18. Links para o modelo canônico

→ [`model/`](../../framework/journeys/diligence/model/) — visão geral do modelo e relações
→ [`model/finding.md`](../../framework/journeys/diligence/model/finding.md) — schema completo do Finding
→ [`model/check.md`](../../framework/journeys/diligence/model/check.md) — schema completo do Check
→ [`model/evidence.md`](../../framework/journeys/diligence/model/evidence.md) — schema completo da Evidence
→ [`model/remediation.md`](../../framework/journeys/diligence/model/remediation.md) — schema completo da Remediation
→ [`model/waiver.md`](../../framework/journeys/diligence/model/waiver.md) — schema completo do Waiver
→ [`checks/`](../../framework/journeys/diligence/checks/) — catálogo de definições de Checks (framework)
→ [`registry.yaml`](registry.yaml) — índice de entidades deste produto
→ [`../../templates/diligence/`](../../templates/diligence/) — templates para criação de instâncias
