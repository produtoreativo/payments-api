---
id: WVR-YYYY-NNNN
title: "[TÍTULO DESCRITIVO — substituir]"
status: "[Proposed|Approved|Active|Expired|Revoked|Rejected|Closed]"
finding_id: "[FND-YYYY-NNNN — exatamente um Finding por Waiver]"
scope: "[o que exatamente está sendo dispensado — ser específico; escopo amplo é rejeitado]"
reason: "[justificativa de negócio ou técnica para o Waiver — por que Remediation imediata não é possível]"
risk_accepted: "[risco que está sendo aceito explicitamente durante a vigência do Waiver]"
approved_by: "[papel/identidade do aprovador — deve ter autoridade para o tipo de condição]"
approved_at: ""
valid_from: ""
expires_at: "[OBRIGATÓRIO — Waiver sem expiração é INVÁLIDO. Sem exceções.]"
review_date: ""
conditions:
  - "[condição que deve ser mantida enquanto o Waiver estiver ativo]"
compensating_controls:
  - "[controle compensatório em vigor durante a vigência do Waiver]"
evidence_ids:
  - "[EVD-YYYY-NNNN — Evidence de aprovação formal; obrigatória]"
revoked_at: ""
revoked_by: ""
---

<!-- → Modelo canônico: prodops/framework/journeys/diligence/model/waiver.md -->
<!-- → Instrução de uso: prodops/artifacts/diligence/README.md -->
<!-- ATENÇÃO: Waiver sem data de expiração é INVÁLIDO. Esta regra não tem exceções. -->
<!-- ATENÇÃO: Renovação gera NOVO Waiver com novo ID. Nunca editar expires_at retroativamente. -->
<!-- ATENÇÃO: Finding permanece visível e rastreável enquanto Waived — Waiver não deleta o Finding. -->
<!-- ATENÇÃO: Waiver não pode ser ativado sem PR com aprovador identificável. -->

# Reason

<!-- Justificativa completa para aceitar temporariamente esta condição.
     Por que a Remediation não pode ser concluída antes da expiração do Waiver?
     Deve ser específica, não genérica ("sem tempo" não é justificativa adequada).
     Ex: "A correção requer Assessment completo com revisão de Risk Owner (estimativa: 2 semanas).
          A Release planejada para 2026-07-28 possui prazo regulatório impostergável.
          A funcionalidade passou por revisão técnica informal sem incidentes nos últimos 30 dias." -->

# Scope

<!-- O que exatamente está sendo dispensado.
     Ser específico sobre: qual condição, qual artefato, qual período, quais operações.
     Escopo amplo ou vago é motivo de rejeição.
     Ex: "Dispensa o requisito de Reliability Plan formal para o OBC credit-card-v2
          exclusivamente para a Release 2026-07-28 (tag v1.4.0).
          Não se aplica a Releases futuras nem a outros OBCs." -->

# Risk Accepted

<!-- Descrição do risco sendo aceito durante a vigência do Waiver.
     O que pode acontecer de errado enquanto este Waiver estiver ativo.
     Não minimizar — o risco aceito deve ser declarado honestamente.
     Ex: "Ausência de critérios formais de confiabilidade pode deixar falhas latentes
          em cenários de carga alta não detectadas antes da Release.
          Risco mitigado parcialmente pelos controles compensatórios abaixo." -->

# Conditions

<!-- Condições que devem ser mantidas para que o Waiver permaneça válido.
     Se uma condição for violada, o Waiver pode ser revogado.
     Ex:
     - Nenhum incidente de produção relacionado à funcionalidade durante a vigência
     - Monitoramento reforçado com alertas em <100ms de latência mantido ativo
     - Tech Lead revisando métricas diariamente até a expiração -->

# Compensating Controls

<!-- Controles alternativos em vigor enquanto o Waiver está ativo.
     Como o risco está sendo mitigado na ausência da Remediation completa.
     Ex:
     - Revisão manual de confiabilidade realizada pelo Tech Lead em 2026-07-22 (sem achados críticos)
     - Dashboard de observabilidade configurado com alertas específicos para esta funcionalidade
     - Rollback automatizado configurado para reverter em caso de degradação acima de 5% -->

# Approval

<!-- Registro da aprovação formal.
     Deve referenciar o PR ou documento onde a aprovação ocorreu.
     Ex:
     Aprovador: Tech Lead + Product Owner
     Data: 2026-07-23
     Pull Request de aprovação: https://github.com/org/repo/pull/145
     Evidence de aprovação: [EVD-2026-0005](../evidence/EVD-2026-0005.md) -->

# Validity

<!-- Período de validade deste Waiver.
     Todos os campos são obrigatórios.
     
     De (valid_from): YYYY-MM-DD
     Até (expires_at): YYYY-MM-DD [OBRIGATÓRIO]
     Data de revisão intermediária (review_date): YYYY-MM-DD [recomendado]
     
     O que acontece ao expirar:
     - Waiver → Expired
     - Finding → Acknowledged (volta ao fluxo normal de tratamento)
     - Bloqueio é reativado se o Check que gerou o Finding ainda retorna Fail
     - Nova decisão necessária: nova Remediation ou novo Waiver com nova justificativa -->

# Review

<!-- Como e quando este Waiver será revisado antes da expiração.
     O que determinará se deve ser renovado, encerrado ou revogado.
     Ex: "Revisão em 2026-07-25 (review_date) com o Tech Lead.
          Critérios para não renovação: ausência de incidentes + Reliability Plan iniciado.
          Critérios para revogação antecipada: qualquer incidente relacionado à funcionalidade." -->

# Revocation

<!-- Preencher apenas se o Waiver for revogado antes da expiração.
     Motivo da revogação, data, quem revogou.
     
     Ex:
     Revogado em: 2026-07-26
     Revogado por: Tech Lead
     Motivo: Incidente de latência detectado em 2026-07-25 — condição de manutenção violada.
     Consequência: Finding retorna a Acknowledged, bloqueio reativado imediatamente. -->

# Evidence

<!-- Evidence relacionada a este Waiver.
     Categorias:
     - Evidence de aprovação (obrigatória): prova de aprovação formal com aprovador identificável
     - Evidence de controles compensatórios: prova de que os controles estão ativos
     - Evidence coletada durante vigência: monitoramento, revisões, etc.
     
     Referenciar por EVD-YYYY-NNNN com link relativo.
     Ex:
     - [EVD-2026-0005](../evidence/EVD-2026-0005.md) — Approval: PR #145 aprovado por Tech Lead e PO
     - [EVD-2026-0006](../evidence/EVD-2026-0006.md) — Dashboard de observabilidade configurado -->

# Trail

<!-- Registro append-only de todas as mudanças relevantes.
     NUNCA sobrescrever entradas anteriores.
     Formato:
     - YYYY-MM-DD HH:MM [papel/agente]: <evento> — <justificativa>
     
     Ex:
     - 2026-07-23 10:00 [Product Context Engineer]: Proposed — Remediation impossível antes da Release
     - 2026-07-23 11:00 [Tech Lead]: Approved — revisado; controles compensatórios confirmados
     - 2026-07-23 11:00 [Product Owner]: Approved — risco aceito explicitamente; PR #145 aprovado
     - 2026-07-23 11:30 [diligence-async]: Active — Waiver ativado; Finding → Waived
     - 2026-07-28 00:00 [sistema]: Expired — expires_at atingido; Finding → Acknowledged -->
