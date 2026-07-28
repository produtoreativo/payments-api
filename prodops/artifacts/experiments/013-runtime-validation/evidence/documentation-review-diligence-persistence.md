# Relatório de Persistência de Entidades Operacionais
# ProdOps Framework — Diligence Persistence Architecture

> Executado em: 2026-07-23
> Escopo: Arquitetura de armazenamento para Finding, Evidence, Remediation e Waiver
> Input: `prodops/documentation-review-diligence-model.md` (modelo canônico já formalizado)
> Status: **concluído — arquitetura de persistência definida**

---

## 1. Executive Summary

Esta execução definiu onde e como as entidades operacionais da Diligence (Finding, Evidence, Remediation e Waiver) são armazenadas, criadas, atualizadas e referenciadas no repositório deste produto.

**Objetivo:** Transformar o modelo canônico abstrato (já formalizado na execução anterior) em infraestrutura concreta de persistência — com diretórios, registry, templates, política de IDs, protocolos de operação e referências declaradas por máquina no manifest.

**Resultado:** A estrutura está pronta para receber instâncias reais produzidas pelos ciclos da Diligence (diligence-sync, diligence-async) e por operações manuais.

### Critérios de aceitação

| Critério | Status |
|---|---|
| Estrutura de diretórios criada em `artifacts/diligence/` | ✓ |
| Registry inicial em YAML com sequências e convenção documentada | ✓ |
| Quatro templates criados (Finding, Evidence, Remediation, Waiver) | ✓ |
| manifest.yaml atualizado com localização canônica de entidades | ✓ |
| README.en.md atualizado: "Planned future concepts" → "Operational entity model" | ✓ |
| `checks/README.md` criado com localização e protocolo do catálogo | ✓ |
| Relatório de persistência criado | ✓ |
| Nenhuma instância real criada (FND-*.md, EVD-*.md, etc.) | ✓ |
| Nenhum script, workflow ou GitHub Action criado | ✓ |
| Nenhum código de produto modificado | ✓ |
| Nenhum commit realizado | ✓ |
| Finding ≠ Issue documentado explicitamente | ✓ |
| Waiver sem expiração declarado inválido | ✓ |
| Remediation Implemented ≠ Finding Verified documentado | ✓ |
| Segurança de Evidence documentada | ✓ |
| 25 anti-padrões documentados (mínimo era 20) | ✓ |
| Quatro exemplos conceituais FICTÍCIOS documentados | ✓ |
| Matriz de autoridade completa | ✓ |

### Arquivos criados (7)

| Arquivo | Tipo | Função |
|---|---|---|
| `prodops/artifacts/diligence/README.md` | Criado | Referência completa de operação — 18 seções, 25 anti-padrões, 4 exemplos |
| `prodops/artifacts/diligence/registry.yaml` | Criado | Índice estruturado inicial (vazio, com sequências e convenção) |
| `prodops/templates/diligence/finding.md` | Criado | Template para instâncias de Finding |
| `prodops/templates/diligence/evidence.md` | Criado | Template para instâncias de Evidence independente |
| `prodops/templates/diligence/remediation.md` | Criado | Template para instâncias de Remediation |
| `prodops/templates/diligence/waiver.md` | Criado | Template para instâncias de Waiver |
| `prodops/framework/journeys/diligence/checks/README.md` | Criado | Localização e protocolo do catálogo de Checks |

### Arquivos modificados (2)

| Arquivo | Tipo | O que mudou |
|---|---|---|
| `prodops/exec/manifest.yaml` | Modificado | Seção `diligence:` adicionada com paths, política de IDs e referências legíveis por máquina |
| `prodops/framework/journeys/diligence/README.en.md` | Modificado | Seção "Planned future concepts" substituída por "Operational entity model"; nota de Output classes atualizada |

### Diretórios criados (6)

```
prodops/artifacts/diligence/
prodops/artifacts/diligence/findings/
prodops/artifacts/diligence/evidence/
prodops/artifacts/diligence/remediations/
prodops/artifacts/diligence/waivers/
prodops/artifacts/diligence/reports/
prodops/templates/diligence/
prodops/framework/journeys/diligence/checks/
```

---

## 2. Arquitetura de Persistência

### 2.1 Princípio geral

As entidades operacionais da Diligence vivem no **Knowledge Space** como arquivos Markdown com identidade própria, estado próprio e trilha histórica própria. Esta é a continuação do princípio fundamental `knowledge-vs-execution.md`: artefatos são arquivos, não Issues.

```
prodops/framework/journeys/diligence/model/   ← definições canônicas (schemas, regras)
prodops/framework/journeys/diligence/checks/  ← definições de Checks (framework)
prodops/artifacts/diligence/                  ← instâncias do produto
prodops/templates/diligence/                  ← templates para criação
prodops/exec/manifest.yaml                    ← localização legível por máquina
```

### 2.2 Estrutura de instâncias

```
prodops/artifacts/diligence/
├── README.md         — referência operacional completa
├── registry.yaml     — índice estruturado (não é fonte de verdade)
├── findings/         — FND-YYYY-NNNN.md (um por Finding)
├── evidence/         — EVD-YYYY-NNNN.md (Evidence com identidade própria)
├── remediations/     — RMD-YYYY-NNNN.md (um por Remediation)
├── waivers/          — WVR-YYYY-NNNN.md (um por Waiver)
└── reports/          — relatórios agregados de execução da Diligence
```

### 2.3 Registry

`registry.yaml` é um índice — não uma fonte narrativa. Regras:
- Arquivo de entidade sempre prevalece
- Registry deve ser reconstruível a partir dos arquivos de entidade
- Registry é atualizado na mesma mudança que cria/modifica entidade
- Drift entre registry e arquivos = Finding estrutural

### 2.4 Templates

Quatro templates em `prodops/templates/diligence/`:
- `finding.md` — front matter completo com todos os campos canônicos; seções para Condition, Evidence, Remediation, Waiver, Resolution, Verification, Trail
- `evidence.md` — front matter com tipo, fonte, validade; seções para Description, Source, Content, Integrity, Validity; aviso de imutabilidade
- `remediation.md` — front matter com strategy enum, finding_ids, expected_result; seções para Objective, Plan, Work Items, Verification, Evidence, Trail; aviso Implemented ≠ Verified
- `waiver.md` — front matter com expires_at obrigatório, conditions, compensating_controls; seções para Reason, Scope, Risk Accepted, Conditions, Approval, Validity, Review, Revocation, Trail; avisos de invalidade sem expiração e renovação com novo ID

### 2.5 Manifest

Seção `diligence:` adicionada ao manifest com:
- `schema_version`: versão do schema de entidades
- `model`, `checks_catalog`, `instances`, `registry`, `templates`: paths canônicos
- `id_policy`: formatos de ID, imutabilidade, independência de ferramentas
- `paths`: localização por tipo de entidade

---

## 3. Protocolos

### 3.1 Geração de IDs

**Formatos:** FND-YYYY-NNNN, EVD-YYYY-NNNN, RMD-YYYY-NNNN, WVR-YYYY-NNNN

**Procedimento manual (até automação existir):**
1. Ler registry.yaml
2. Localizar last_sequence para tipo + ano corrente
3. Verificar arquivos no diretório para confirmar
4. Reservar last_sequence + 1
5. Criar arquivo com ID reservado
6. Atualizar registry.yaml (mesma mudança)
7. Validar ausência de colisão

**Risco de concorrência:** dois agentes simultâneos podem gerar o mesmo ID. Protocolo: nunca sobrescrever, recalcular ID, preservar ambos os trabalhos, nunca renumerar entidades publicadas.

**ID cancelado nunca é reutilizado.**

### 3.2 Protocolo de Finding

Fluxo: Check executa → resultado Fail/Warning → deduplicação → Finding existe? → atualizar ou criar → classificar → definir owner → avaliar Remediation/Waiver → atualizar registry.

**Criar quando:** condição concreta, sujeito identificável, Check/regra existe, Evidence mínima, deduplicação executada.
**Não criar quando:** Pass, Not Applicable, sem sujeito, sem regra, sem Evidence, duplicata ativa, hipótese não verificada, ausência de Issue é legítima, Error de Check (sem confirmar condição).

### 3.3 Protocolo de Evidence

**Inline** (no arquivo do Finding): pequena, exclusiva de um Finding, sem reutilização, sem ciclo de validade independente.

**Independente** (arquivo próprio EVD-YYYY-NNNN.md): usada por múltiplos Findings, prova Remediation ou verificação, tem validade temporal, origem externa, saída técnica relevante, precisa de ID próprio.

**Evidence é imutável após criação.** Nova coleta = novo EVD-YYYY-NNNN.

### 3.4 Protocolo de Remediation

12 etapas: Finding reconhecido → estratégia → proposta → owner → aprovação → Work Items → implementação → Evidence de implementação → verificação independente → Evidence de verificação → Finding Verified → fechamento.

**Princípio crítico:** Fechar Issue ≠ fechar Finding. Implemented ≠ Verified. Quem implementou não verifica.

### 3.5 Protocolo de Waiver

13 etapas: Finding ativo → justificativa → escopo → risco → controles compensatórios → aprovador → valid_from → expires_at (obrigatório) → review_date → Evidence de aprovação → ativação → monitoramento → expiração/revogação/fechamento.

**Waiver expirado:** não renovado automaticamente, para de suspender bloqueio, Finding volta a Acknowledged, requer nova decisão. Renovação = novo WVR-YYYY-NNNN. Arquivo expirado preservado com status Expired.

### 3.6 Deduplicação

**Chave:** check_id + sujeito primário + condição + escopo.

**Atualizar Finding existente:** mesma chave, Finding Open/Acknowledged/In Remediation, mesmo contexto operacional.

**Criar novo Finding:** recorrência após fechamento, causa diferente, contexto diferente, escopo diferente, regra mudou materialmente, Finding anterior invalidado. Documentar: `recurrence_of: FND-YYYY-NNNN`.

### 3.7 Matriz de autoridade

| Entidade / Ação | Agente pode preparar | Agente pode registrar | Requer humano | Quem aprova |
|---|---|---|---|---|
| Finding informacional | Sim | Sim | Dependente de política | Diligence Owner |
| Finding bloqueante | Sim | Sim | Sim | Responsável normativo |
| Remediation documental simples | Sim | Sim | Conforme escopo | Owner do artefato |
| Remediation que muda intenção | Não decide | Não conclui sozinho | Sim | Product Owner |
| Waiver | Pode preparar | Não pode ativar sozinho | Sempre | Responsável autorizado |
| Evidence técnica | Sim | Sim | Conforme criticidade | Responsável pela verificação |

### 3.8 Commits e Pull Requests

- Finding de operação local: mesmo branch da operação
- Finding independente: branch específico
- Waiver: Pull Request com aprovador identificável (o PR é Evidence de aprovação)
- Evidence: mesmo commit da detecção ou verificação
- Não obrigatório um commit por entidade
- Não misturar ativação de Waiver com implementação de Remediation

---

## 4. Tabela de arquivos

| Arquivo | Created/Modified | Função | Companion | Validação |
|---|---|---|---|---|
| `artifacts/diligence/README.md` | Created | Referência operacional completa (18 seções, 25 anti-padrões, 4 exemplos FICTÍCIOS) | Não criado | ✓ |
| `artifacts/diligence/registry.yaml` | Created | Índice estruturado inicial com sequências e convenção | Não aplicável | ✓ |
| `artifacts/diligence/findings/` | Created (dir) | Localização canônica para FND-YYYY-NNNN.md | Não aplicável | ✓ |
| `artifacts/diligence/evidence/` | Created (dir) | Localização canônica para EVD-YYYY-NNNN.md | Não aplicável | ✓ |
| `artifacts/diligence/remediations/` | Created (dir) | Localização canônica para RMD-YYYY-NNNN.md | Não aplicável | ✓ |
| `artifacts/diligence/waivers/` | Created (dir) | Localização canônica para WVR-YYYY-NNNN.md | Não aplicável | ✓ |
| `artifacts/diligence/reports/` | Created (dir) | Relatórios agregados de Diligence | Não aplicável | ✓ |
| `templates/diligence/finding.md` | Created | Template com front matter completo e 10 seções | Não criado | ✓ |
| `templates/diligence/evidence.md` | Created | Template com front matter, avisos de imutabilidade e segurança | Não criado | ✓ |
| `templates/diligence/remediation.md` | Created | Template com aviso Implemented ≠ Verified | Não criado | ✓ |
| `templates/diligence/waiver.md` | Created | Template com aviso expires_at obrigatório e renovação = novo ID | Não criado | ✓ |
| `framework/journeys/diligence/checks/README.md` | Created | Localização, protocolo e estado atual do catálogo de Checks | Não criado | ✓ |
| `exec/manifest.yaml` | Modified | Seção diligence: com paths, ID policy e referências | Não aplicável | ✓ |
| `framework/journeys/diligence/README.en.md` | Modified | "Planned future concepts" → "Operational entity model"; nota de Output atualizada | Companion do README.md PT | ✓ |

---

## 5. Decisões arquiteturais

### 5.1 Um arquivo por entidade

Cada Finding, Evidence, Remediation e Waiver tem seu próprio arquivo Markdown. Alternativa rejeitada: lista em arquivo único.

**Rationale:** identidade independente, evolução de estado, histórico legível no git log, PR review específico, conflito de merge mínimo, relações N:M sem aninhamento forçado, links estáveis, arquivabilidade, rastreabilidade Git.

### 5.2 Evidence inline vs. independente

Critério de decisão formal documentado: Evidence inline quando pequena + exclusiva + sem reutilização + sem ciclo de validade; Evidence independente quando qualquer das 12 condições de obrigatoriedade é satisfeita.

**Rationale:** evitar arquivos EVD para cada observação trivial; garantir identidade e referenciabilidade quando a Evidence tem valor independente.

### 5.3 Registry como índice (não fonte)

O registry.yaml é explicitamente um índice — não uma fonte narrativa. O arquivo de entidade sempre prevalece. O registry é reconstruível a partir dos arquivos.

**Rationale:** um único arquivo de estado global cria gargalo em concorrência e perde rastreabilidade individual. O registry serve para navegação eficiente; a fonte de verdade é sempre o arquivo individual.

### 5.4 Fonte de verdade: arquivo no repositório git

Finding, Evidence, Remediation e Waiver vivem como arquivos Markdown no repositório git — não como Issues, Fields, ou estados no GitHub Project. O GitHub Project pode espelhar estado mas não é a fonte.

**Rationale:** consistência com o princípio knowledge-vs-execution.md; independência de ferramentas; sobrevivência a migrações; IDs imutáveis não dependentes de Issue number.

### 5.5 GitHub e Work Items: relação N:M preservada

Finding não requer Issue. Remediation com operação ativa normalmente tem Work Item. Um Work Item pode tratar múltiplos Findings. Fechar Issue não fecha Finding.

**Rationale:** o modelo N:M já consolidado no Framework entre Artefatos e Work Items se aplica igualmente às entidades da Diligence.

### 5.6 Política de IDs: imutável e independente de ferramentas

IDs (FND-YYYY-NNNN, etc.) são imutáveis após criação, independentes de números de GitHub Issue, sequenciais por ano.

**Rationale:** rastreabilidade histórica permanente; independência de migrações de ferramenta; auditabilidade cronológica.

### 5.7 Waiver obrigatoriamente temporário

`expires_at` é obrigatório sem exceções. Renovação gera novo Waiver com novo ID. Arquivo expirado preservado.

**Rationale:** Waiver permanente mascara débito técnico indefinidamente; renovação automática elimina o controle consciente; preservar arquivo expirado mantém auditabilidade.

### 5.8 Checks: catálogo separado das instâncias

Definições de Checks vivem em `framework/journeys/diligence/checks/` (framework). Instâncias de Findings gerados por Checks vivem em `artifacts/diligence/findings/` (produto).

**Rationale:** Checks são normativos e reutilizáveis por todos os produtos do framework; Findings são específicos de cada produto; misturar os dois quebraria a separação framework × produto.

---

## 6. Validações

### Comandos executados e resultados

**V1 — Estrutura de diretórios:**
```
prodops/artifacts/diligence/README.md
prodops/artifacts/diligence/registry.yaml
```
Resultado: ✓ (diretórios criados; apenas README e registry como arquivos)

**V2 — Sem instâncias reais:**
```
(saída vazia)
```
Resultado: ✓ (nenhum FND-*.md, EVD-*.md, RMD-*.md, WVR-*.md criado)

**V3 — Templates existem:**
```
prodops/templates/diligence/evidence.md
prodops/templates/diligence/finding.md
prodops/templates/diligence/remediation.md
prodops/templates/diligence/waiver.md
```
Resultado: ✓

**V4 — Finding não confundido com Issue:**
Saída vazia — nenhuma ocorrência confunde Finding com Issue. Ocorrências nos arquivos estão em seções de anti-padrão (descrevendo o que NÃO fazer).
Resultado: ✓

**V5 — Sem Waiver permanente:**
Ocorrências encontradas são da seção de anti-padrões (descrevendo que criar Waiver sem expiração é anti-padrão). Nenhuma permissão ou instrução de criar Waiver permanente.
Resultado: ✓

**V6 — Sem IDs baseados em GitHub Issue:**
Ocorrência encontrada é do anti-padrão #2 (instruindo que usar número de GitHub Issue como ID é errado).
Resultado: ✓

**V7 — Sem arquivos executáveis:**
Saída vazia.
Resultado: ✓

**V8 — README EN atualizado:**
Linha 169: nota de Output classes atualizada para "implemented".
Linha 417: seção "Operational entity model" presente.
Linha 419: "formally specified and implemented" confirmado.
Resultado: ✓

### Limitações das validações

- Validações são point-in-time e não verificam consistência futura
- O registry.yaml está vazio (sem entidades) — a consistência entre registry e arquivos só pode ser validada quando houver instâncias reais
- Companion EN não foi criado para o `checks/README.md` — consistente com a política atual (diligence-sync.md, diligence-async.md etc. não têm companion EN)
- Companion EN dos templates não foram criados — templates são instrumentos operacionais; companions EN podem ser criados quando o catálogo de Checks for populado

---

## 7. Riscos Residuais

| ID | Risco | Impacto se não resolvido | Ação recomendada |
|---|---|---|---|
| R-1 | Catálogo de Checks não populado | Agentes criam Findings sem `check_id` canônico; rastreabilidade Check → Finding fica informal | Criar `checks/catalog.yaml` como próxima fase |
| R-2 | Geração de IDs manual propensa a colisão em concorrência | Dois agentes simultâneos podem gerar mesmo ID | Implementar mecanismo de lock ou sequence atômica quando automação for criada |
| R-3 | Companion EN do README.md de instâncias ausente | Leitores de inglês não têm versão do guia operacional | Criar `artifacts/diligence/README.en.md` quando o conteúdo estiver estabilizado |
| R-4 | GitHub Project schema para espelhamento de Finding não definido | Agentes que usam GitHub Project para navegação não sabem como representar Finding sem torná-lo fonte de verdade | Definir campos de espelhamento (se desejado) sem criar dependência de fonte |
| R-5 | `waiver_allowed: false` sem lista de Checks declarados | Nenhum Check foi declarado como não-dispensável — todos permitem Waiver por padrão | Ao popular catálogo, declarar explicitamente quais Checks são não-dispensáveis |
| R-6 | Threshold de automação de agente não definido | Agentes podem criar Findings automaticamente para condições que requerem revisão humana | Definir por tipo de Check: quais geram Finding automaticamente vs. requerem confirmação |
| R-7 | Protocolo de branch para Findings ainda depende de julgamento | Finding de operação local pode ir no branch da operação; Finding independente precisa de branch próprio | Formalizar como regra no catálogo de Checks ou no workflow da Diligence |

---

## 8. Readiness para próxima fase (Catálogo de Checks)

### Como Checks criarão Findings usando a estrutura criada

Com a estrutura de persistência definida, o catálogo de Checks pode ser populado sem ambiguidade:

1. Check `catalog.yaml` define: `id`, `name`, `check_id` (DIL-CATEGORY-NNN), `dimension`, `category`, `severity_on_fail`, `blocking`, `waiver_allowed`
2. Check é executado pelo ciclo (diligence-sync ou diligence-async)
3. Resultado Fail: agente executa deduplicação usando `check_id + sujeito + condição + escopo`
4. Finding não existe: gerar `FND-2026-NNNN`, criar `artifacts/diligence/findings/FND-2026-NNNN.md` usando template `templates/diligence/finding.md`, atualizar `registry.yaml`
5. Finding existe: atualizar `last_detected_at`, `occurrence_count`, adicionar Evidence ao arquivo existente, atualizar registry

### Campos do catálogo que dependem da estrutura criada

| Campo do Check | Referência à estrutura criada |
|---|---|
| `check_id` | Formato DIL-CATEGORY-NNN — declarado no `manifest.yaml` |
| `finding_template` | `prodops/templates/diligence/finding.md` |
| `registry` | `prodops/artifacts/diligence/registry.yaml` |
| `findings_dir` | `prodops/artifacts/diligence/findings/` |
| `evidence_dir` | `prodops/artifacts/diligence/evidence/` |
| `evidence_template` | `prodops/templates/diligence/evidence.md` |

### Como o catálogo pode referenciar templates e diretórios

O `manifest.yaml` já declara todos os paths necessários na seção `diligence:`. O catálogo pode referenciar:
```yaml
# Em catalog.yaml (futuro):
global:
  finding_template: prodops/templates/diligence/finding.md
  findings_dir: prodops/artifacts/diligence/findings/
  registry: prodops/artifacts/diligence/registry.yaml
  evidence_template: prodops/templates/diligence/evidence.md
  evidence_dir: prodops/artifacts/diligence/evidence/
```

### Decisões que ainda impedem automação completa

| Decisão | Impacto na automação |
|---|---|
| Geração atômica de IDs | Sem mecanismo de lock, dois agentes simultâneos podem criar mesmo ID |
| Threshold de auto-registro | Quais Checks permitem que agente crie Finding sem confirmação humana? |
| Schema de espelhamento no GitHub Project | Agentes que criam Work Items para Remediations precisam saber quais campos usar |
| Protocolo de branch para Findings bloqueantes | Finding que bloqueia promoção: deve ir em branch próprio ou no branch da operação bloqueada? |
| `waiver_allowed: false` — lista de Checks | Sem esta lista, todos os Checks permitem Waiver; regras críticas ficam sem proteção |

### Pré-condições do catálogo que já estão satisfeitas

| Pré-condição | Status | Onde |
|---|---|---|
| Local de armazenamento de Findings | ✓ | `artifacts/diligence/findings/` |
| Local de armazenamento de Evidence | ✓ | `artifacts/diligence/evidence/` (independente) ou inline no Finding |
| Local de armazenamento de Remediations | ✓ | `artifacts/diligence/remediations/` |
| Local de armazenamento de Waivers | ✓ | `artifacts/diligence/waivers/` |
| Formato de IDs declarado por máquina | ✓ | `manifest.yaml` seção `diligence.id_policy` |
| Política de deduplicação documentada | ✓ | `artifacts/diligence/README.md` seção 11 |
| Protocolo de criação de Finding documentado | ✓ | `artifacts/diligence/README.md` seção 10 |
| Template de Finding pronto | ✓ | `templates/diligence/finding.md` |
| Template de Evidence pronto | ✓ | `templates/diligence/evidence.md` |
| Localização do catálogo declarada | ✓ | `framework/journeys/diligence/checks/README.md` |
| Protocolo de versionamento de Checks documentado | ✓ | `checks/README.md` |
| Relação Check → Finding documentada | ✓ | `checks/README.md` + `model/README.md` |
| Matriz de autoridade documentada | ✓ | `artifacts/diligence/README.md` seção 12 |
