---
id: RMD-YYYY-NNNN
title: "[TÍTULO DESCRITIVO — substituir]"
status: "[Proposed|Approved|In Progress|Implemented|Verified|Rejected|Cancelled]"
strategy: "[Correct|Prevent|Contain|Compensate|Migrate|Document|Reconcile|Retire]"
finding_ids:
  - "[FND-YYYY-NNNN]"
owner: "[papel responsável pela execução]"
priority: "[Alta|Média|Baixa — independente da severidade do Finding]"
target_date: ""
work_item_references: []
expected_result: "[como será o estado do sistema após a remediação bem-sucedida]"
verification_check_id: "[DIL-CATEGORY-NNN — Check a re-executar para verificar resolução]"
evidence_required: "[o que deve ser coletado para provar a conclusão da remediação]"
residual_risk: "[risco remanescente se Remediation for parcial ou não puder ser totalmente concluída]"
started_at: ""
completed_at: ""
verified_at: ""
---

<!-- → Modelo canônico: prodops/framework/journeys/diligence/model/remediation.md -->
<!-- → Instrução de uso: prodops/artifacts/diligence/README.md -->
<!-- NOTA CRÍTICA: Remediation Implemented ≠ Finding Verified. -->
<!-- Verificação é etapa independente, realizada por quem não implementou, com Evidence própria. -->

# Objective

<!-- O que esta Remediation pretende resolver.
     Descrever o estado esperado após a conclusão.
     Referenciar os Findings endereçados com contexto. -->

# Findings Addressed

<!-- Lista dos Findings com breve contexto de cada um.
     Referenciar por ID com link relativo. Ex:
     - [FND-2026-0001](../findings/FND-2026-0001.md) — Campo 'owner' ausente em OBC feature-x
     - [FND-2026-0002](../findings/FND-2026-0002.md) — Campo 'owner' ausente em OBC feature-y
     
     Nota: Uma Remediation pode endereçar múltiplos Findings (relação N:M). -->

# Strategy

<!-- Estratégia principal escolhida e justificativa.
     Estratégias disponíveis:
     - Correct: corrigir diretamente a condição divergente
     - Prevent: introduzir mecanismo que previne recorrência
     - Contain: limitar o impacto sem eliminar a causa
     - Compensate: controle compensatório quando correção direta não é possível
     - Migrate: mover para estrutura que não tem o problema
     - Document: formalizar conhecimento implícito ou ausente
     - Reconcile: alinhar representações divergentes para uma fonte de verdade
     - Retire: eliminar o artefato ou elemento problemático
     
     Estratégias secundárias (se houver):
     Ex: "Primária: Correct (corrigir campos ausentes). Secundária: Prevent (adicionar validação de schema ao CI)." -->

# Plan

<!-- Passos planejados para executar esta Remediation.
     Suficientemente específico para ser executável.
     Incluir ordem de execução quando relevante.
     Ex:
     1. Ler prodops/artifacts/obcs/feature-x.md
     2. Adicionar campo 'owner' com valor 'Product Context Engineer'
     3. Commitar mudança no branch da operação atual
     4. Repetir para feature-y.md
     5. Executar Check DIL-ART-004 para verificar resolução -->

# Work Items

<!-- Work Items relacionados à execução desta Remediation.
     Referenciar por URL ou número do GitHub Issue.
     Lembrar: relação N:M — um Work Item pode implementar múltiplas Remediações.
     Ex:
     - GitHub Issue #92: https://github.com/org/repo/issues/92
     
     Se nenhum Work Item foi criado (operação direta pelo agente):
     - "Nenhum Work Item criado — operação executada diretamente pela Diligence" -->

# Expected Result

<!-- Estado esperado do sistema após a Remediation.
     Deve ser específico e verificável.
     Ex: "Ambos os arquivos OBC conterão campo 'owner' com valor válido conforme schema
          canônico em prodops/framework/journeys/diligence/model/finding.md.
          Check DIL-ART-004 retornará Pass para ambos os sujeitos." -->

# Verification

<!-- Critério de verificação independente.
     - Check a re-executar (ID e nome)
     - Evidence a coletar
     - Quem verifica (deve ser diferente de quem implementou)
     - Quando verificar
     
     Ex: "Check DIL-ART-004 deve retornar Pass para ambos os OBCs.
          Evidence: output do Check após correção (EVD-YYYY-NNNN a criar).
          Verificado por: Product Context Engineer ou diligence-async no próximo Scan.
          Prazo: até 2026-07-25." -->

# Evidence

<!-- Evidence coletada durante e após a Remediation.
     Referenciar por EVD-YYYY-NNNN com link relativo.
     
     Categorias de Evidence para esta Remediation:
     - Evidence de implementação (prova que a ação foi executada)
     - Evidence de verificação (prova que a condição foi resolvida — independente)
     
     Ex:
     - [EVD-2026-0003](../evidence/EVD-2026-0003.md) — snapshot dos arquivos antes da correção
     - [EVD-2026-0004](../evidence/EVD-2026-0004.md) — output do Check após correção (verificação) -->

# Residual Risk

<!-- Se a Remediation for parcial, documentar:
     - O que ficou pendente
     - Qual risco permanece após a implementação
     - Se há Follow-up Remediation necessária
     
     Se a Remediation for completa: "Nenhum risco residual identificado." -->

# Trail

<!-- Registro append-only de decisões, mudanças de estado e aprovações.
     NUNCA sobrescrever entradas anteriores.
     Formato:
     - YYYY-MM-DD HH:MM [papel/agente]: <evento> — <justificativa>
     
     Ex:
     - 2026-07-23 15:00 [diligence-async]: Proposed — detectado durante Scan, Remediation proposta automaticamente
     - 2026-07-23 15:30 [Product Context Engineer]: Approved — revisado e aprovado para execução
     - 2026-07-24 09:00 [Product Context Engineer]: In Progress — iniciando correção dos campos
     - 2026-07-24 09:15 [Product Context Engineer]: Implemented — campos corrigidos em ambos os OBCs
     - 2026-07-24 09:30 [diligence-async]: Verified — Check DIL-ART-004 reexecutado, resultado Pass -->
