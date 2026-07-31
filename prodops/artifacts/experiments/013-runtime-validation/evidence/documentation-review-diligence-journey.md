# Relatório de Formalização da Jornada Diligence
# ProdOps Framework — Diligence Journey Report

> Executado em: 2026-07-23
> Escopo: `prodops/framework/journeys/diligence/`, `prodops/framework/journeys/README.md`, `prodops/documentation-review-diligence-convergence.md`
> Status: **concluído — todos os arquivos normativos atualizados**

---

## 1. Executive Summary

Esta execução formalizou a Diligence como a quinta jornada canônica do ProdOps Framework, elevando-a de um conjunto de ciclos operacionais para um modelo completo com definição, propósito, questão central, natureza transversal, escopo, limites explícitos, cinco dimensões de consistência, entradas, classes de saída, ciclos, fases, capabilities, participantes, protocolo de escalação, anti-padrões e exemplos canônicos.

**Resultado:**

| Critério | Status |
|---|---|
| Definição canônica presente | ✓ |
| Natureza transversal documentada com diagrama ASCII | ✓ |
| Dois ciclos formalizados (sync e async) | ✓ |
| Workspace Reconciliation classificada como Capability | ✓ |
| Seis Capabilities com template completo | ✓ |
| Limites explícitos (CAN / CANNOT) | ✓ |
| Protocolo de escalação | ✓ |
| Anti-padrões (13 documentados) | ✓ |
| Quatro exemplos canônicos | ✓ |
| Companion EN atualizado | ✓ |
| Validações Step 7 passando | ✓ |
| Nenhum conceito futuro implementado prematuramente | ✓ |

**Arquivos modificados nesta execução:** 9

**Nenhum commit foi feito.** Nenhum arquivo de código foi modificado.

---

## 2. Modelo Formalizado

### Definição canônica

> **Diligence é a jornada transversal responsável por garantir continuamente a consistência do sistema de trabalho do ProdOps, verificando coerência, completude, rastreabilidade e conformidade entre conhecimento, decisões, execução e evidências.**

### Questão central

> O conhecimento, as decisões, a execução e as evidências continuam coerentes e rastreáveis?

### Natureza transversal

A Diligence não é uma etapa linear final — é transversal. O diagrama ASCII formalizado ilustra que ela verifica consistência em todas as demais jornadas simultaneamente e os resultados voltam como novos sinais, decisões e trabalho.

### Ciclos (exatamente dois)

| Ciclo | Natureza | Fases |
|---|---|---|
| diligence-sync | Síncrono, reativo, contextual, bloqueante | Capture → Attach → Promote → Close |
| diligence-async | Assíncrono, proativo, orientado a drift | Scan → Flag → Repair |

Workspace Reconciliation: **Capability** (não Cycle), invocada como sub-rotina.

### Capabilities (seis)

| Capability | Ciclos consumidores |
|---|---|
| Backlog Synchronization | Capture, Promote, Repair |
| Work Item Management | Attach, Close, Repair |
| Readiness Verification | Promote, Scan |
| Divergence Detection | Scan, Flag |
| Artifact Evolution | Capture, Repair, Close |
| Workspace Reconciliation | Bootstrap, Diligence Async, Diligence Sync |

### Cinco dimensões de consistência

Conceitual, Estrutural, Rastreabilidade, Operacional, Temporal.

### Entradas

16 tipos de entrada documentados. Nenhum evento resulta automaticamente em criação de Issue — o evento inicia uma avaliação.

### Classes de saída

14 classes documentadas, sem implementação de schemas formais (Check, Finding, Evidence, Remediation, Waiver estão planejados para versão futura).

### Limites explícitos

13 coisas que a Diligence PODE fazer; 12 coisas que NÃO pode fazer.

### Protocolo de escalação

10 condições de escalação documentadas; 7 alvos de escalação identificados.

### Anti-padrões

13 anti-padrões documentados com justificativa.

### Exemplos canônicos

4 exemplos com lição explícita: (1) Business Signal passivo, (2) Business Signal com operação ativa, (3) OBC promovido para Delivery, (4) Workspace drift.

### Relações explícitas com as outras quatro jornadas

- Discovery: Diligence verifica; não executa Discovery
- Assessment: Diligence verifica decisões; não refaz Assessment
- Delivery: Diligence verifica pré-condições; não implementa
- Operation: Diligence verifica sinais; não monitora produção

### Knowledge Space ↔ Execution Space

Diagrama de fluxo bidirecional documentado com princípios de sincronização, cardinalidade N:M e restrições do GitHub Project.

---

## 3. Arquivos Modificados

| Arquivo | Mudança | Razão | Companion EN | Validação |
|---|---|---|---|---|
| `prodops/framework/journeys/diligence/README.md` | Reescrita completa com expansão para ~460 linhas | Formalizar todas as seções canônicas exigidas | `README.en.md` atualizado | ✓ |
| `prodops/framework/journeys/diligence/README.en.md` | Reescrita completa — companion EN | Companion EN do README.md reformulado | — (é o companion) | ✓ |
| `prodops/framework/journeys/diligence/diligence-sync.md` | Reescrita com seções de Natureza, Modelo de acionamento, fases detalhadas, relação com Workspace Reconciliation | Formalizar ciclo síncrono | Não existe companion EN | ✓ |
| `prodops/framework/journeys/diligence/diligence-async.md` | Reescrita com seções de Natureza, Modelo de acionamento, fases detalhadas, distinção ausência legítima vs. incompleta, restrições de Repair | Formalizar ciclo assíncrono | Não existe companion EN | ✓ |
| `prodops/framework/journeys/diligence/workspace-reconciliation.md` | Expansão do parágrafo de abertura reforçando classificação como Capability; adição de seção de steps internos com hierarquia de fontes de verdade; tabela de steps com coluna Restrições | Reforçar: Capability (não Cycle), steps internos (não Phases), Inspect não modifica nada | Não existe companion EN | ✓ |
| `prodops/framework/journeys/diligence/capabilities/README.md` | Reescrita completa: de tabela simples para catálogo com template completo (6 seções por Capability) | Formalizar todas as 6 Capabilities com definição, responsabilidade, entradas, saídas, ciclos consumidores, jornadas relacionadas, fontes de verdade, limites, exemplos, anti-padrões | Não existe companion EN | ✓ |
| `prodops/framework/journeys/README.md` | Expansão da seção "Jornadas transversais" com diagrama ASCII e descrição da natureza transversal da Diligence | Garantir que o índice de jornadas reflita a formalização | `README.en.md` | ✓ |
| `prodops/framework/journeys/README.en.md` | Companion EN — mesma expansão da seção transversal | Companion EN | — (é o companion) | ✓ |
| `prodops/documentation-review-diligence-convergence.md` | (1) Correção editorial: 18 → 21 arquivos na seção de resumo; (2) Reestruturação da seção 6 em subseções: divergências parciais / ambiguidades abertas / lacunas abertas / conteúdo deliberadamente não alterado | Correção editorial — o relatório de execução não refletia o count correto da própria tabela | Não aplicável | ✓ |

---

## 4. Decisões Editoriais

### Conteúdo incorporado em arquivos existentes

- **README.md**: conteúdo dos arquivos-base foi preservado e expandido; nenhuma decisão canônica previamente aplicada foi revertida.
- **workspace-reconciliation.md**: o diagrama Mermaid e os guardrails existentes foram preservados; apenas o parágrafo de abertura foi expandido e a seção de steps ganhou restrições explícitas.
- **capabilities/README.md**: o conteúdo da tabela existente (6 capabilities) foi preservado e expandido para o formato completo.
- **journeys/README.md e README.en.md**: a seção "Jornadas transversais" foi expandida; todo o conteúdo anterior foi mantido.

### Novos arquivos criados

- **README.en.md** (diligence): o arquivo anterior existia mas foi completamente reescrito para acompanhar o novo README.md. Como o arquivo já existia, não é "novo" — é atualização do companion.

### Novos arquivos deliberadamente não criados

Conforme a instrução:
- `checks.md`, `findings.md`, `evidence.md`, `remediation.md`, `waivers.md` — não criados
- `operating-model.md` (diligence) — não criado; conteúdo de modelo operacional foi integrado no README.md
- `lifecycle.md` (diligence) — não criado; ciclo de vida está documentado no README.md e nos arquivos de ciclo
- Nenhum arquivo de workflow, automação ou GitHub Actions foi criado

### Termos preservados

- `diligence-sync`, `diligence-async` — termos canônicos preservados exatamente
- `Inspect → Reconcile → Verify` — steps internos do Workspace Reconciliation, preservados como steps (não phases)
- `Capture → Attach → Promote → Close` — fases do diligence-sync, preservadas
- `Scan → Flag → Repair` — fases do diligence-async, preservadas
- `[Artifact ID]: descrição concisa` — formato de título de Work Item, preservado

### Termos removidos ou não usados

- `[Operation] — [Artifact Type] [Artifact ID]: descrição` — padrão de título antigo, não usado em nenhuma seção normativa
- `workspace-reconciliation` como Cycle — não aparece em nenhuma tabela de ciclos
- `Business Signal Issue`, `Business Intent Issue` — não usados como termos canônicos

---

## 5. Validações Executadas

### Check 1 — Workspace Reconciliation não classificada como Cycle

```bash
grep -Rni "workspace-reconciliation.*cycle|cycle.*workspace-reconciliation" prodops/framework prodops/skills
```

**Resultado:** Sem ocorrências. ✓

### Check 2 — Business Signal Issue / Business Intent Issue não são normativos

```bash
grep -Rni "Business Signal Issue|Business Intent Issue" prodops/framework prodops/skills AGENTS.md
```

**Resultado:** Duas ocorrências em `knowledge-vs-execution.md` (linhas 220 e 272) — ambas nas seções "Incorreto" / anti-padrões, identificando os termos como erros a evitar. Não são definições normativas. ✓

### Check 3 — Diligence não decide, prioriza ou implementa (em seções normativas)

```bash
grep -Rni "Diligence.*decide|Diligence.*prioriza|Diligence.*implementa" prodops/framework/journeys/diligence prodops/skills/diligence
```

**Resultado:** Todas as ocorrências estão em seções "não faz" ou de limite (ex: "Ela não avalia, não decide, não implementa"). Nenhuma em instrução normativa positiva. ✓

### Check 4 — Sem terceiro ciclo da Diligence

```bash
grep -Rni "workspace-reconciliation" prodops/framework/journeys/diligence/README.md | grep -i "ciclo|cycle"
```

**Resultado:** Sem ocorrências. ✓

### Check 5 — Formato de título antigo `[Operation] —`

```bash
grep -Rni "\[Operation\] —" prodops/framework prodops/skills AGENTS.md
```

**Resultado:** Uma ocorrência em `scan/SKILL.md:52` — é o critério de detecção do padrão antigo (para que o Repair o corrija). Uso correto em seção de detecção de divergência, não em instrução normativa de criação. ✓

---

## 6. Riscos Residuais

| Risco | Descrição | Impacto se não resolvido | Ação recomendada |
|---|---|---|---|
| **R-1** | `tracking-list.md` (content artifact de produto) ainda tem "Business Signal Issue" na nota de cabeçalho | Agentes que lerem apenas o artefato podem criar Issues por Signal passivo | Atualizar manualmente — requer decisão do Product Owner |
| **R-2** | Ambiguidade A-002: linha entre "criar" e "sincronizar" pela Diligence não está formalmente definida para casos edge | Agentes podem interpretar de formas diferentes | Documentar protocolo de criação em `execution-mapping/README.md` ou `knowledge-vs-execution.md` |
| **R-3** | A-005: promoção de Upstream que pula Icebox não tem estados intermediários documentados | Diligence pode bloquear incorretamente itens promovidos de Upstream | Adicionar seção sobre "promoção de Upstream" em `backlogs.md` ou `flow.md` |
| **R-4** | `framework/journeys/assessment/reliability-plans/setup/` usa "Repository Tracking List" | Agentes que usam os prompts de Reliability Plan podem usar o nome antigo | Atualizar quando a documentação de Assessment for revisada |
| **R-5** | L-001: protocolo de transição de modo Upstream → Downstream não documentado | Agentes que mudam de modo não sabem onde registrar a decisão | Documentar protocolo de transição em `execution-model/` |
| **R-6** | L-002: Business Intents sem OBC associado (estado pré-Draft) não têm protocolo de Diligence | Diligence assume que toda Intent tem OBC | Adicionar protocolo para Intent em estado pré-Draft |
| **R-7** | Companions EN ausentes para diligence-sync.md, diligence-async.md, workspace-reconciliation.md e capabilities/README.md | Leitores de inglês não têm versão formalizada desses arquivos | Criar companions EN quando os arquivos PT estiverem estabilizados |

---

## 7. Readiness para Próxima Fase

### Conceitos prontos para especificação formal

Os seguintes conceitos foram explicitamente documentados como "futuros planejados" mas **a infraestrutura conceitual está pronta** para suportá-los:

| Conceito | Dependências satisfeitas | O que falta para implementar |
|---|---|---|
| **Check** | Fontes de verdade definidas; protocolo de escalação; Capabilities de verificação | Decisão sobre schema de critério de entrada/saída; taxonomia de tipos de Check |
| **Finding** | Divergence Detection formalized; Flag phase operational; severidade implícita | Taxonomia formal (severidade, tipo, impacto, artefato afetado) |
| **Evidence** | Release Trail existe; Verify do Workspace Reconciliation gera Conformance Report | Schema formal de Evidence; relação Evidence → Finding |
| **Remediation** | Repair phase operational; Capabilities de correção disponíveis | Schema formal de Remediation; relação Remediation → Finding |
| **Waiver** | Protocolo de escalação com alvos definidos | Schema formal de Waiver; fluxo de autorização |

### Pré-condições satisfeitas para especificação de Check/Finding

1. Modelo N:M artefato-Work Item consolidado ✓
2. Workspace Reconciliation classificada corretamente como Capability ✓
3. Protocolo de escalação com alvos definidos ✓
4. Fontes de verdade por tipo de dado documentadas ✓
5. Anti-padrões que definem o negativo dos Checks ✓
6. Cinco dimensões de consistência estabelecidas (base para taxonomia de Finding) ✓

### Próxima fase recomendada

A especificação formal de **Finding** é o conceito desbloqueador — Define a unidade de resultado que Check, Evidence, Remediation e Waiver orbitam. Recomenda-se especificar Finding primeiro, com taxonomia mínima (severidade: High/Medium/Low; tipo: Conceitual/Estrutural/Rastreabilidade/Operacional/Temporal; artefato afetado; estado: Open/Resolved/Waived).

---

## Apêndice: Arquivos sem companion EN identificado

Os seguintes arquivos foram modificados nesta execução mas não possuem companion EN (`.en.md`). Não foram criados companions novos — registrado para ação futura:

| Arquivo | Companion EN |
|---|---|
| `diligence/diligence-sync.md` | Não existe — criar quando o arquivo PT estiver estabilizado |
| `diligence/diligence-async.md` | Não existe — criar quando o arquivo PT estiver estabilizado |
| `diligence/workspace-reconciliation.md` | Não existe — criar quando o arquivo PT estiver estabilizado |
| `diligence/capabilities/README.md` | Não existe — criar quando o arquivo PT estiver estabilizado |
