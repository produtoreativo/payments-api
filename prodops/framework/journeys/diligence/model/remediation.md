# Remediation — Definição Canônica

## Definição

> **Remediation é a operação planejada e rastreável destinada a remover, reduzir ou controlar a condição registrada em um Finding.**

Uma Remediation não é apenas texto recomendando uma correção. É o registro da resposta operacional da Diligence ou do owner ao Finding: o que será feito, quem fará, como será verificado e qual é o resultado esperado. A Remediation pode gerar um ou mais Work Items — mas é uma entidade distinta do Work Item.

---

## Formato de ID

```
RMD-YYYY-NNNN
```

- `RMD`: prefixo imutável da entidade Remediation
- `YYYY`: ano de criação (quatro dígitos)
- `NNNN`: sequencial de quatro dígitos por ano (0001–9999)

Exemplos: `RMD-2026-0001`, `RMD-2026-0042`

---

## Princípios fundamentais

- **Remediation ≠ Work Item.** A Remediation é o plano e o registro da operação corretora (Knowledge Space). O Work Item é a unidade de execução rastreável no Execution Space. A relação é N:M: uma Remediation pode gerar múltiplos Work Items; um Work Item pode implementar múltiplas Remediações.

- **Remediation Implemented ≠ Finding Verified.** A implementação da Remediation (estado Implemented) não significa automaticamente que a condição do Finding foi resolvida. A verificação é uma etapa independente, realizada por quem não executou a Remediation, com Evidence coletada após a implementação.

- **A Remediation pode se aplicar a múltiplos Findings.** Uma única operação corretora (ex: atualização de documento de glossário) pode resolver múltiplos Findings de categoria Documentation.

- **Um Finding pode ter múltiplas Remediações.** Quando a correção requer múltiplas estratégias paralelas ou sequenciais.

---

## Schema

| Campo | Tipo conceitual | Cardinalidade | Regras e notas |
|---|---|---|---|
| `id` | string | 1 | Formato RMD-YYYY-NNNN; imutável; único no sistema |
| `title` | string | 1 | Obrigatório; resume a operação de correção de forma clara |
| `description` | text | 1 | Obrigatório; descreve o que será feito, como e por quê resolve a condição |
| `finding_ids` | list de Finding IDs | 1..N | Obrigatório; mínimo 1 Finding; lista todos os Findings que esta Remediation endereça |
| `strategy` | enum | 1 primária | Ver taxonomia de estratégias abaixo; pode indicar estratégias secundárias |
| `owner` | string | 1 | Papel responsável pela execução e acompanhamento |
| `status` | enum | 1 | Ver fluxo de estados abaixo |
| `priority` | enum | 0..1 | Separado da severidade do Finding; depende de contexto: Critical, High, Medium, Low |
| `target_date` | date | 0..1 | Data alvo de conclusão; independente do `target_date` do Finding |
| `work_items` | list de Work Item refs | 0..N | Referências aos Work Items de execução; atualizado conforme Work Items são criados |
| `expected_result` | text | 1 | Descreve o que constitui sucesso — estado do sistema após Remediation bem-sucedida |
| `verification_check` | string | 0..1 | Check ID a ser re-executado para verificar resolução |
| `evidence_required` | text | 1 | O que deve ser coletado para comprovar conclusão e verificar resolução |
| `residual_risk` | text | 0..1 | Se a Remediation é parcial, documenta o que permanece sem solução |
| `started_at` | datetime | 0..1 | Set quando status transiciona para In Progress |
| `completed_at` | datetime | 0..1 | Set quando status transiciona para Implemented |
| `verified_at` | datetime | 0..1 | Set quando status transiciona para Verified |

---

## Taxonomia de estratégias

| Estratégia | Definição | Exemplo de uso |
|---|---|---|
| **Correct** | Remove a causa ou condição atual — elimina o problema na origem | Atualizar campo `artifact_id` em Work Item com referência inválida; corrigir vocabulário incorreto em documento normativo |
| **Prevent** | Evita recorrência da condição — muda o processo ou mecanismo para que não ocorra novamente | Adicionar Check automatizado de validação de campo ao ciclo diligence-async |
| **Contain** | Limita o impacto enquanto a correção definitiva não existe — não resolve mas evita que piore | Adicionar aviso em documento afetado indicando que conteúdo está em revisão |
| **Compensate** | Adiciona controle alternativo — não remove a condição mas cria salvaguarda equivalente | Testes manuais adicionais enquanto Reliability Plan não está completo |
| **Migrate** | Move estrutura ou dado para o modelo correto — quando a condição existe por design obsoleto | Migrar OBCs de formato antigo para template canônico atualizado |
| **Document** | Resolve exclusivamente gap documental — quando a condição existe apenas na documentação | Criar entrada de glossário ausente; documentar protocolo não escrito |
| **Reconcile** | Alinha fontes, configurações ou representações — quando múltiplas fontes divergem | Workspace Reconciliation para restaurar campo ausente no GitHub Project; sincronizar estado entre OBC e GitHub Project |
| **Retire** | Remove elemento obsoleto ou inválido — quando a condição existe por algo que não deveria existir | Fechar Work Item órfão que referencia OBC inexistente; remover label obsoleta |

Uma Remediation pode combinar estratégias, mas deve indicar a estratégia primária. Estratégias secundárias são opcionais.

---

## Fluxo de estados

```
Proposed → Approved → In Progress → Implemented → Verified
                                               ↑
                                  (verificação independente da implementação)
         → Rejected (com justificativa)
         → Cancelled (com motivo documentado)
```

| Estado | Significado | Quem pode transicionar | Condições |
|---|---|---|---|
| **Proposed** | Remediation identificada e documentada; aguarda aprovação | Diligence (criação) | Campos obrigatórios preenchidos |
| **Approved** | Aprovada para execução | owner ou processo de governança | Responsável identificado, target_date definida se aplicável |
| **In Progress** | Execução em andamento | owner | Work Items criados ou operação iniciada |
| **Implemented** | Correção aplicada; aguarda verificação independente | owner ou Diligence | Evidence de implementação coletada; `completed_at` preenchido |
| **Verified** | Verificação independente confirma que a condição foi resolvida | Diligence (verificação independente) | Evidence de verificação coletada; Check re-executado se aplicável; `verified_at` preenchido |
| **Rejected** | Decidido que esta Remediation não será executada | owner ou processo de governança | Justificativa documentada; Finding permanece aberto com nova decisão necessária |
| **Cancelled** | Execução abandonada após aprovação | owner | Motivo documentado; `residual_risk` atualizado; Finding permanece aberto |

### Casos especiais

**Implementação parcial:** Se a Remediation for executada parcialmente, NÃO marcar como Implemented. Documentar o que foi feito, o que resta no `residual_risk` e manter o status em In Progress até que a implementação seja completa — ou criar Remediation separada para a parte restante.

**Verificação independente:** A verificação (Verified) é sempre independente da implementação. Quem executou a Remediation não verifica a própria Remediation. A Evidence de verificação é distinta da Evidence de implementação.

**Quem aprova:** Depende do contexto e do scope da Remediation. Para Remediações de workspace, a Diligence pode aprovar autonomamente. Para Remediações que alteram conteúdo canônico de artefatos, a aprovação requer a jornada competente (Assessment, Product Owner, Tech Lead).

**Quem cancela:** O owner pode cancelar com motivo documentado. O processo de governança pode cancelar quando a condição foi superada por outra decisão.

---

## Relação com Work Items

A Remediation é uma entidade do Knowledge Space. Os Work Items que executam a Remediation são entidades do Execution Space.

```
Remediation (Knowledge Space)
   │
   ├── Work Item #101: atualizar artifact_id no Work Item #57
   └── Work Item #102: validar atualização e executar Check novamente
```

| Cardinalidade | Direção |
|---|---|
| Uma Remediation pode ter 0 Work Items | Quando a correção é executada diretamente pela Diligence sem rastreamento separado |
| Uma Remediation pode ter N Work Items | Quando a correção requer múltiplas tarefas paralelas ou sequenciais |
| Um Work Item pode implementar N Remediações | Quando uma única operação resolve múltiplos Findings |

**Princípio:** a Remediation não é substituída pelo Work Item. Quando o Work Item fecha, a Remediation pode estar Implemented — mas só fica Verified após verificação independente com Evidence.

---

## Referências

→ [`README.md`](README.md) — modelo de entidades e relações
→ [`finding.md`](finding.md) — entidade que origina a Remediation
→ [`evidence.md`](evidence.md) — Evidence de implementação e de verificação
→ [`check.md`](check.md) — Check re-executado para verificação
→ [`waiver.md`](waiver.md) — alternativa quando Remediation não pode ser executada imediatamente
→ [`../diligence-async.md`](../diligence-async.md) — fase Repair executa Remediações
→ [`../workspace-reconciliation.md`](../workspace-reconciliation.md) — Capability que executa Remediações de workspace
