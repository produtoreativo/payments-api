---
id: FND-YYYY-NNNN
title: "[TÍTULO DESCRITIVO — substituir]"
status: Open
severity: "[Critical|High|Medium|Low|Info]"
primary_dimension: "[Conceptual|Structural|Traceability|Operational|Temporal]"
secondary_dimensions: []
category: "[Artifact|Backlog|Work Item|Execution Mapping|Documentation|Workspace|Readiness|Reliability|Observability|Security|Release|Evidence|Governance]"
check_id: "[DIL-CATEGORY-NNN ou null se detectado manualmente]"
detected_at: "YYYY-MM-DDTHH:MM:SS-03:00"
last_detected_at: "YYYY-MM-DDTHH:MM:SS-03:00"
detected_by: "[diligence-sync|diligence-async|manual:<papel>]"
owner: "[papel responsável pela resolução]"
target_date: ""
subjects:
  - type: "[Artifact|Work Item|Pull Request|Release|Project|View|Field|Label|Workflow|Repository|Workspace|Capability|Journey|Document|Link|Configuration]"
    reference: "[URI, path, ou referência estável]"
    system: "[github|local|external]"
artifact_references: []
execution_references: []
source_of_truth: "[documento canônico que define a regra]"
impact: "[o que quebra ou arrisca se não resolvido]"
evidence_ids: []
remediation_ids: []
waiver_ids: []
occurrence_count: 1
recurrence_of: ""
---

<!-- → Modelo canônico: prodops/framework/journeys/diligence/model/finding.md -->
<!-- → Instrução de uso: prodops/artifacts/diligence/README.md -->

# Summary

<!-- Resumo conciso da condição encontrada — 1 a 3 linhas. -->

# Condition Detected

<!-- Descrição detalhada da condição observada.
     O que foi encontrado, onde, em qual contexto.
     Ser específico: qual arquivo, qual campo, qual valor, qual estado. -->

# Expected Condition

<!-- O que deveria ser verdadeiro segundo a fonte de verdade.
     Citar o documento normativo com path completo.
     Ex: "Conforme prodops/framework/ontology.md, o campo status deve conter um dos valores: [...]" -->

# Impact

<!-- Consequências se esta condição não for resolvida.
     Indicar se há bloqueio de transição e qual transição.
     Indicar impacto operacional, de rastreabilidade ou de conformidade. -->

# Subjects

<!-- Detalhe dos subjects afetados.
     O front matter lista os tipos; aqui descreva cada um com contexto completo.
     Ex:
     - Arquivo: prodops/artifacts/obcs/feature-x.md
       Contexto: OBC em estado Draft, campo 'owner' ausente desde a última edição
     -->

# Evidence

<!-- Evidence coletada para sustentar este Finding.
     
     Para Evidence inline (pequena, exclusiva, sem reutilização):
       Incluir o dado diretamente aqui. Ex:
       - Valor observado: status="in-delivery"
       - Valor esperado: status="In Delivery" (conforme ontology.md)
       - Observado em: 2026-07-23T14:30:00-03:00
     
     Para Evidence independente (arquivo próprio em evidence/):
       Referenciar por ID e link relativo. Ex:
       - [EVD-2026-0001](../evidence/EVD-2026-0001.md) — Command Output de gh issue view
     
     Não incluir segredos, credenciais ou dados sensíveis. -->

# Remediation

<!-- Remediações planejadas ou em andamento.
     Referenciar por ID com link relativo. Ex:
     - [RMD-2026-0001](../remediations/RMD-2026-0001.md) — Correct: restaurar campo owner
     
     Se ainda não há Remediation: documentar a ação imediata possível ou a decisão necessária. -->

# Waiver

<!-- Waiver ativo, se houver.
     Referenciar por ID com link relativo. Ex:
     - [WVR-2026-0001](../waivers/WVR-2026-0001.md) — válido até 2026-08-01
     
     Se não há Waiver: deixar vazio ou "Nenhum." -->

# Resolution

<!-- Preencher quando status = Resolved ou Verified.
     O que foi feito, quando, por quem.
     Evidence de comprovação: referência por ID.
     Ex: "Campo owner restaurado com valor 'Product Context Engineer' em 2026-07-24.
          Verificação: [EVD-2026-0002](../evidence/EVD-2026-0002.md)" -->

# Verification

<!-- Preencher quando status = Verified.
     Check re-executado: qual Check, quando, resultado.
     Evidence de verificação: referência por ID.
     Quem verificou (deve ser diferente de quem implementou).
     Ex: "DIL-ART-004 reexecutado em 2026-07-24, resultado: Pass.
          Evidence: [EVD-2026-0002](../evidence/EVD-2026-0002.md)
          Verificado por: Product Context Engineer (independente da implementação)" -->

# Trail

<!-- Registro append-only de todas as mudanças de estado relevantes.
     NUNCA sobrescrever entradas anteriores.
     Formato:
     - YYYY-MM-DD HH:MM [papel/agente]: <mudança> — <justificativa>
     
     Ex:
     - 2026-07-23 14:30 [diligence-async]: Open — detectado durante Scan periódico; Check DIL-ART-004
     - 2026-07-23 15:00 [Product Context Engineer]: Acknowledged — revisado e confirmado
     - 2026-07-24 09:00 [Product Context Engineer]: Resolved — campo corrigido, aguardando verificação
     - 2026-07-24 09:30 [diligence-async]: Verified — Check reexecutado, resultado Pass
     - 2026-07-24 09:30 [diligence-async]: Closed — verificação concluída, Finding encerrado
     -->
