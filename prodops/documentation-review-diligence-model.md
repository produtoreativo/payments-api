# Relatório de Formalização do Modelo de Entidades Operacionais
# ProdOps Framework — Diligence Model Report

> Executado em: 2026-07-23
> Escopo: `prodops/framework/journeys/diligence/model/`, `prodops/framework/journeys/diligence/README.md`, `prodops/documentation-review-diligence-journey.md`
> Status: **concluído — modelo canônico definido**

---

## 1. Executive Summary

Esta execução formalizou o modelo canônico de entidades operacionais da jornada Diligence: **Finding**, **Check**, **Evidence**, **Remediation** e **Waiver**. O modelo define schemas, estados, relações, cardinalidades, políticas de bloqueio, deduplicação, imutabilidade e integração com os ciclos existentes (diligence-sync, diligence-async, workspace-reconciliation).

**Arquivos criados:** 6 (todos em `prodops/framework/journeys/diligence/model/`)

**Arquivos modificados:** 2 (`README.md` da jornada Diligence, `documentation-review-diligence-journey.md`)

**Modelo definido:** 5 entidades canônicas com schemas completos, fluxos de estado, regras de validação e 16 anti-padrões

**Commits:** nenhum

**Código de produto:** nenhum modificado ou criado

| Critério de aceitação | Status |
|---|---|
| Cinco entidades com definição canônica | ✓ |
| IDs imutáveis independentes de ferramentas | ✓ |
| Finding explicitamente separado de GitHub Issue | ✓ |
| Waiver sem expiração declarado inválido | ✓ |
| Remediation Implemented ≠ Finding Verified automaticamente | ✓ |
| Indeterminate ≠ Pass documentado | ✓ |
| Error ≠ Fail da regra original documentado | ✓ |
| 16 anti-padrões documentados | ✓ |
| Nenhum script, workflow ou automação criado | ✓ |
| Nenhum Waiver permanente permitido | ✓ |
| Integração com ciclos documentada | ✓ |
| Política de bloqueio com critérios completos | ✓ |
| Correção editorial do relatório de jornada | ✓ |

---

## 2. Modelo Canônico

### 2.1 Entidades e definições

| Entidade | ID Format | Definição canônica |
|---|---|---|
| **Finding** | `FND-YYYY-NNNN` | Registro persistente de uma divergência, ausência, risco de inconsistência ou condição relevante detectada pela Diligence durante a avaliação do sistema de trabalho |
| **Check** | `DIL-CATEGORY-NNN` | Regra declarativa, reproduzível e verificável usada pela Diligence para avaliar uma condição do sistema de trabalho |
| **Evidence** | `EVD-YYYY-NNNN` | Prova persistente e referenciável usada para demonstrar a detecção, o impacto, a correção ou a verificação de uma condição avaliada pela Diligence |
| **Remediation** | `RMD-YYYY-NNNN` | Operação planejada e rastreável destinada a remover, reduzir ou controlar a condição registrada em um Finding |
| **Waiver** | `WVR-YYYY-NNNN` | Autorização explícita, justificada, limitada e temporária para aceitar uma condição registrada em um Finding sem executar imediatamente sua Remediation completa |

### 2.2 Relações e cardinalidades

```
Check 1 ────── N Finding
Finding N ──── N Evidence
Finding N ──── N Remediation
Finding 1 ──── 0..N Waiver (somente um ativo por escopo/período)
Remediation N ─ N Work Item
Finding N ──── N Work Item
Evidence N ─── N Finding
```

### 2.3 Diagrama de relações

```
Check
   │ avalia uma regra
   ▼
Finding
   │ registra uma divergência concreta
   ├──────────────► Evidence
   │                 comprova detecção, impacto ou resolução
   │
   ├──────────────► Remediation
   │                 executa ou orienta a correção
   │
   └──────────────► Waiver
                     autoriza aceitação temporária ou excepcional
```

---

## 3. Decisões Arquiteturais

### 3.1 IDs imutáveis e independentes de ferramentas

Todos os IDs (FND, DIL, EVD, RMD, WVR) são:
- Imutáveis após criação
- Independentes de números de GitHub Issue
- Sobrevivem a migrações de ferramenta
- Sequenciais por ano para auditoria cronológica

**Rationale:** O sistema não pode depender de IDs de ferramentas externas que mudam em migrações ou fechamentos de repositório. A rastreabilidade histórica exige identidade permanente.

### 3.2 Finding é entidade do Knowledge Space — não é GitHub Issue

Finding vive no Knowledge Space como registro persistente. A criação de Work Item para tratar um Finding é uma decisão operacional — não automática. Nem todo Finding exige Issue.

**Rationale:** Criar Issue para todo Finding viola o modelo N:M artefato-Work Item já consolidado no Framework. Polui o Execution Space com trabalho fantasma. A separação preserva rastreabilidade independente de ferramenta.

### 3.3 Cinco dimensões de Finding

| Dimensão | Foco |
|---|---|
| Conceptual | Vocabulário, ontologia, responsabilidade, classificação |
| Structural | Arquivos, links, schemas, campos, configurações |
| Traceability | Referências, relações, cadeia KS↔ES |
| Operational | Estados, transições, critérios, evidências |
| Temporal | Informações vencidas, snapshots desatualizados, Waivers expirados |

Um Finding tem uma dimensão primária e pode ter dimensões secundárias. Findings não são duplicados por dimensão secundária.

### 3.4 Severidade ≠ Prioridade

Severidade (Critical, High, Medium, Low, Info) descreve o impacto intrínseco da condição. Prioridade depende de contexto: deadline, custo de correção, risco atual, jornada em curso.

**Consequência prática:** Um Finding Low pode receber prioridade alta por deadline. Um Finding High pode receber prioridade baixa por custo de correção elevado e risco controlado.

### 3.5 Deduplicação de Findings

- Atualizar Finding existente quando: mesmo Check + mesmo sujeito + mesma condição + mesmo escopo + Finding ainda Open/Acknowledged/In Remediation
- Criar novo Finding quando: diferente sujeito, regra, causa, escopo, ou Finding anterior Closed com recorrência em novo contexto

### 3.6 Política de bloqueio com sete critérios

Para que um Finding bloqueie, TODOS devem ser verdadeiros:
1. Check com `blocking: true`
2. Fonte normativa canônica identificada
3. Condição confirmada (Fail, não Warning ou Indeterminate)
4. Evidence suficiente coletada
5. Severidade compatível (Info nunca bloqueia)
6. Instrução de resolução documentada
7. Owner ou alvo de escalação identificado

### 3.7 Waiver obrigatoriamente temporário

`expires_at` é campo obrigatório sem exceção neste estágio. Waivers permanentes não são permitidos. Waiver expirado retorna Finding ao fluxo normal sem renovação automática.

### 3.8 Remediation Implemented ≠ Finding Verified

A verificação da Remediation é etapa independente da implementação:
- Quem implementou não verifica a própria implementação
- Evidence de verificação é distinta de Evidence de implementação
- Finding só transiciona para Verified após verificação independente com Evidence

### 3.9 Resultados de Check

- **Indeterminate ≠ Pass**: não há Evidence suficiente para concluir conformidade
- **Error ≠ Fail da regra original**: o Check não pôde executar; pode gerar Finding operacional sobre a falha do mecanismo, não sobre a regra
- **Warning ≠ Fail**: condição relevante sem violação bloqueante
- **Not Applicable é resultado válido e explícito**: não é ausência de avaliação

### 3.10 Evidence é imutável

Evidence histórica não é sobrescrita. Nova coleta cria nova Evidence. O registro histórico é preservado. Evidence pode ter `valid_until` para condições temporais.

### 3.11 Falsas positivas não deletam Findings

Findings inválidos (False Positive, Duplicate, Invalid Rule, Insufficient Evidence, Superseded) são classificados com justificativa — nunca deletados. Um False Positive pode revelar problema no Check — uma Remediation pode ser relacionada ao próprio Check.

### 3.12 `waiver_allowed: false` em Checks

Alguns Checks podem declarar que nenhum Waiver pode suspender o bloqueio. Esta declaração é de uso restrito — para condições de risco irremediável por aceitação temporária. O catálogo de regras não-dispensáveis não foi criado neste estágio.

---

## 4. Tabela de arquivos

| Arquivo | Created/Modified | Conteúdo | Companion EN | Validação |
|---|---|---|---|---|
| `model/README.md` | Created | Overview, diagrama ASCII, cardinalidades, KS vs ES, deduplicação, bloqueio, integração com ciclos, 5 exemplos, 16 anti-padrões | Não criado (política: não existe companion EN para diligence-sync.md, diligence-async.md etc. — consistente com estado atual) | ✓ |
| `model/finding.md` | Created | Definição canônica, ID format, schema completo (22 campos), 5 dimensões, 13 categorias, severidade, fluxo de estados com casos especiais, sujeitos, deduplicação, falso positivo, política de bloqueio, integração com ciclos, matriz dimensão×consistência, 5 exemplos mandatórios | Não criado | ✓ |
| `model/check.md` | Created | Definição canônica, ID format (DIL-CATEGORY-NNN), schema completo (17 campos), taxonomia de 10 tipos, modos de execução, resultados com regras, política de bloqueio | Não criado | ✓ |
| `model/evidence.md` | Created | Definição canônica, ID format, o que pode provar, 15 tipos com hierarquia de preferência, schema completo (10 campos), critérios de suficiência, conflito entre evidências, imutabilidade, expiração | Não criado | ✓ |
| `model/remediation.md` | Created | Definição canônica, ID format, princípios fundamentais, schema completo (14 campos), 8 estratégias, fluxo de estados com casos especiais, relação N:M com Work Items | Não criado | ✓ |
| `model/waiver.md` | Created | Definição canônica, ID format, 5 princípios fundamentais, schema completo (14 campos), 10 regras obrigatórias, política de expiração, unicidade, revogação, `waiver_allowed: false`, fluxo de estados | Não criado | ✓ |
| `diligence/README.md` | Modified | Substituição da seção "Conceitos futuros planejados" por "Modelo de entidades operacionais" com links para model/ | Não atualizado (companion EN existe mas não foi modificado — mudança é referência, não conteúdo novo) | ✓ |
| `documentation-review-diligence-journey.md` | Modified | Correção editorial: Executive Summary "7" → "9" arquivos (alinhamento com tabela da seção 3) | Não aplicável | ✓ |

---

## 5. Validações

### Check 1 — Finding não confundido com Issue

```bash
grep -Rni "Finding.*Issue|Issue.*Finding" prodops/framework/journeys/diligence/model/
```

**Resultado:** Todas as ocorrências encontradas estão em seções de anti-padrão ou separação explícita:
- `README.md`: "Transformar todo Finding em Issue" (anti-padrão #1); "Usar Issue number como ID do Finding" (anti-padrão #2)
- `finding.md`: "Um Finding não é uma GitHub Issue" (definição); "Ausência de Issue não é divergência automática" (exemplo 2)
- `evidence.md`: "Evidence não é comentário em Issue" (definição)

Nenhuma ocorrência confunde Finding com Issue. ✓

### Check 2 — Waiver sem expiração não existe

```bash
grep -Rni "Waiver.*sem.*expira|Waiver.*permanent|permanent.*waiver" prodops/framework/journeys/diligence/model/
```

**Resultado:**
- `waiver.md`: "Waiver sem expires_at é inválido. Esta regra não tem exceções neste estágio. Waivers permanentes não são permitidos." — declaração de proibição, não permissão. ✓
- `README.md`: "Criar Waiver sem expiração" — anti-padrão #6. ✓

### Check 3 — Remediation Implemented ≠ Verified automaticamente

```bash
grep -Rni "Implemented.*Verified|automaticamente.*Verified" prodops/framework/journeys/diligence/model/
```

**Resultado:**
- `remediation.md`: "Remediation Implemented ≠ Finding Verified. A implementação da Remediation não significa automaticamente que a condição do Finding foi resolvida." ✓
- `remediation.md`: "Quando o Work Item fecha, a Remediation pode estar Implemented — mas só fica Verified após verificação independente com Evidence." ✓

### Check 4 — Indeterminate não tratado como Pass

```bash
grep -Rni "Indeterminate.*Pass|Error.*Fail" prodops/framework/journeys/diligence/model/
```

**Resultado:**
- `check.md`: "Indeterminate ≠ Pass. Indeterminate significa que não há evidências suficientes para confirmar conformidade — não é confirmação de que tudo está bem." ✓
- `README.md`: "Tratar Indeterminate como Pass" — anti-padrão #15. ✓

### Check 5 — Arquivos model/ existem

```bash
ls -la prodops/framework/journeys/diligence/model/
```

**Resultado:** 6 arquivos presentes:
- `README.md` (12.577 bytes)
- `check.md` (9.664 bytes)
- `evidence.md` (8.679 bytes)
- `finding.md` (25.543 bytes)
- `remediation.md` (9.467 bytes)
- `waiver.md` (8.488 bytes)

✓

### Check 6 — Sem código executável

```bash
find prodops/framework/journeys/diligence/model/ \( -name "*.sh" -o -name "*.py" -o -name "*.js" \) -not -name "*.md"
```

**Resultado:** Nenhum arquivo executável. ✓

---

## 6. Riscos Residuais

| Risco | Descrição | Impacto se não resolvido | Ação recomendada |
|---|---|---|---|
| **R-1** | Catálogo de Checks não criado | Agentes não têm definições canônicas de quais Checks executar — implementação dos ciclos usa classificação informal atual | Criar catálogo de Checks canônicos baseado no modelo check.md; esta é a próxima fase natural |
| **R-2** | `waiver_allowed: false` sem lista de regras | O schema do Check define o campo mas nenhuma regra foi declarada com `waiver_allowed: false` | Ao criar catálogo de Checks, declarar explicitamente quais regras são não-dispensáveis |
| **R-3** | GitHub Project schema para entidades do modelo não definido | Finding, Evidence, Remediation e Waiver vivem no Knowledge Space mas a representação no GitHub Project (se houver) não está especificada | Definir quando/se e como representar estado de Finding no GitHub Project sem torná-lo a fonte de verdade |
| **R-4** | Companion EN dos arquivos model/ ausente | Leitores de inglês não têm versão das especificações do modelo | Criar companions EN quando os arquivos PT estiverem estabilizados (política consistente com diligence-sync.md, diligence-async.md etc.) |
| **R-5** | Protocolo de registro de Finding não operacionalizado | O schema de Finding está definido mas o local de armazenamento canônico (arquivo, diretório) não foi especificado | Definir: os Findings ficam em `prodops/artifacts/diligence/findings/` ou em estrutura centralizada? |
| **R-6** | diligence/README.en.md não atualizado para refletir a seção model/ | O companion EN ainda refere aos conceitos como "futuros planejados" | Atualizar README.en.md para substituir "Conceitos futuros planejados" por referência ao model/ |

---

## 7. Readiness para Próxima Fase

### Decisões necessárias antes do catálogo de Checks

1. **Local de armazenamento de Findings:** `prodops/artifacts/diligence/findings/FND-YYYY-NNNN.md` ou registro centralizado? Cada Finding como arquivo individual ou lista em arquivo único?

2. **Local de armazenamento de Evidence:** Inline no Finding ou arquivo separado em `prodops/artifacts/diligence/evidence/`?

3. **Representação no GitHub Project:** O estado do Finding pode ser espelhado no GitHub Project como campo derivado? Qual campo? Como garantir que o Project não vire fonte de verdade?

4. **Protocolo de Finding gerado por agente:** Quando um agente detecta condição durante diligence-async Scan, onde e como registra o Finding? Qual é o protocolo de commit do Finding?

5. **Threshold de automação:** Quais Checks podem ser totalmente automatizados por agente sem confirmação humana? Quais requerem revisão antes de criar Finding?

### Como o modelo pode ser representado no GitHub Project sem os anti-padrões

| Entidade | Como representar | Como NÃO representar |
|---|---|---|
| **Finding** | Campo "Finding ID" no Work Item de Remediation, com link para arquivo canônico | Finding como tipo de Issue; Finding ID = Issue number |
| **Evidence** | Campo "Evidence" no Work Item com link para arquivo ou comando de coleta | Evidence como comentário de Issue sem ID ou referência estruturada |
| **Remediation** | Work Item separado do Finding, com label `diligence:remediation` e campo linking ao Finding ID | Mesmo Work Item do Finding sendo chamado de "Remediation" |
| **Waiver** | Campo "Waiver ID" no Finding (se espelhado) com link para arquivo de Waiver canônico | Waiver como status do Issue ("Waived" como label sem arquivo de aprovação) |
| **Check** | Campo "Check ID" no Work Item de execução com resultado documentado | Check como checklists de Issue sem ID canônico e sem versionamento |

### Catálogo de Checks: pré-condições satisfeitas

| Pré-condição | Status |
|---|---|
| Taxonomia de tipos de Check definida (10 tipos) | ✓ |
| Modos de execução definidos (Sync/Async/Manual/Event-driven/Scheduled) | ✓ |
| Resultados de Check com regras definidos (Pass/Fail/Warning/Not Applicable/Indeterminate/Error) | ✓ |
| Política de bloqueio com critérios definida | ✓ |
| Dimensões de Finding definidas (base para categoria de Check) | ✓ |
| Formato de ID de Check definido (DIL-CATEGORY-NNN) | ✓ |
| Schema de Check com todos os campos definido | ✓ |
| Relação Check → Finding definida | ✓ |

A infraestrutura conceitual está pronta para o catálogo de Checks.

---

## Apêndice: Correção editorial aplicada

**Arquivo:** `prodops/documentation-review-diligence-journey.md`

**Alteração:** Executive Summary linha "Arquivos modificados nesta execução: 7" corrigida para "9".

**Justificativa:** A tabela da seção 3 daquele relatório contém 9 linhas (README.md, README.en.md, diligence-sync.md, diligence-async.md, workspace-reconciliation.md, capabilities/README.md, journeys/README.md, journeys/README.en.md, documentation-review-diligence-convergence.md). O número 7 no Executive Summary era inconsistente com o próprio documento.
