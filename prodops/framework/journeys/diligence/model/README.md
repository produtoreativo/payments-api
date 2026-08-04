# Modelo de Entidades Operacionais — Diligence

Este diretório contém a definição canônica das entidades operacionais da jornada Diligence: **Check**, **Finding**, **Evidence**, **Remediation** e **Waiver**.

---

## Visão geral

As entidades operacionais da Diligence formalizam o ciclo de vida de uma divergência detectada no sistema de trabalho do ProdOps: desde a regra que a detecta (Check), passando pelo registro persistente da condição (Finding), as provas que a sustentam (Evidence), a operação que a corrige (Remediation) e a autorização explícita para aceitá-la temporariamente sem correção imediata (Waiver).

Estas entidades vivem primariamente no **Knowledge Space** — são documentos e registros rastreáveis. A conexão com o **Execution Space** (Work Items, GitHub Issues) é explícita, rastreada e intencional, mas não automática.

---

## Diagrama de relações

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

## Cardinalidades

```
Check 1 ────── N Finding
  (um Check pode detectar múltiplos Findings ao longo do tempo)

Finding N ──── N Evidence
  (um Finding pode ter múltiplas Evidências; uma Evidência pode suportar múltiplos Findings)

Finding N ──── N Remediation
  (um Finding pode ter múltiplas Remediações; uma Remediation pode corrigir múltiplos Findings)

Finding 1 ──── 0..N Waiver
  (somente um Waiver ativo por Finding por escopo por período)

Remediation N ─ N Work Item
  (uma Remediation pode gerar múltiplos Work Items; um Work Item pode implementar múltiplas Remediações)

Finding N ──── N Work Item
  (um Finding pode ser rastreado por múltiplos Work Items; um Work Item pode tratar múltiplos Findings)

Evidence N ─── N Finding
  (relação bidirecional — uma Evidence pode suportar múltiplos Findings)
```

---

## Knowledge Space vs. Execution Space

### Knowledge Space

As definições canônicas, os registros persistentes e as justificativas formais vivem no Knowledge Space:

- **Definições de Checks**: regras declarativas versionadas que especificam o que avaliar
- **Relatórios de Findings**: registros persistentes de divergências com estado, trilha e resolução
- **Documentos de Waiver**: justificativas formais, aprovações e condições de validade
- **Documentos de Evidence**: provas referenciáveis de detecção, impacto ou resolução
- **Planos de Remediation**: operações planejadas e rastreáveis para correção

### Execution Space

O trabalho de execução sobre as entidades operacionais vive no Execution Space:

- **Work Items para executar Checks**: quando um Check requer operação humana ou coordenada
- **Work Items para investigar Findings**: quando a investigação do Finding requer trabalho rastreável
- **Work Items para aplicar Remediações**: quando a Remediation gera tarefas de execução
- **Work Items para revisar Waivers**: quando a revisão de um Waiver requer coordenação

**Princípio fundamental:** nem todo Finding exige automaticamente a criação de um GitHub Issue. A criação de Work Item ocorre quando há operação ativa rastreável sendo executada. Um Finding pode ser resolvido diretamente pela Diligence sem gerar Work Item separado.

---

## Deduplicação de Findings

### Atualizar Finding existente quando:

- O mesmo Check detecta a mesma condição no mesmo sujeito no mesmo escopo
- A condição não foi resolvida desde a última detecção
- O Finding existente está nos estados: Open, Acknowledged ou In Remediation

Ao atualizar: registrar `last_detected_at`, incrementar contagem de ocorrências, atualizar impacto se mudou, adicionar nova Evidence.

### Criar novo Finding quando:

- O sujeito é diferente
- A regra violada é diferente
- A causa raiz é diferente
- O escopo é independente
- O Finding anterior está Closed e a recorrência representa condição nova relevante

**Nunca reabrir automaticamente um Finding Closed sem preservar o registro da nova ocorrência como evento distinto.**

---

## Política de bloqueio

Um Finding pode bloquear operações do sistema de trabalho (promoção, entrada em Iteration Plan, Release, mudança de estado, reconciliação automática).

Para que um bloqueio seja válido, TODOS os critérios abaixo devem ser satisfeitos:

1. O Check está marcado com `blocking: true`
2. Existe fonte normativa canônica que define a regra violada
3. A condição de violação foi confirmada (não apenas suspeita)
4. Evidence suficiente foi coletada
5. A severidade é compatível com bloqueio (Info nunca bloqueia)
6. Existe instrução de resolução documentada
7. Existe owner ou alvo de escalação identificado

Um **Waiver válido** pode suspender o bloqueio quando a política do Check permite.

Severidade Critical **não** implica automaticamente impossibilidade de Waiver. Algumas regras podem declarar `waiver_allowed: false` — nesses casos, nenhum Waiver é aceito.

---

## Integração com os ciclos da Diligence

### diligence-sync

- **Capture**: produz Evidence inicial (estado do artefato ao ser registrado); pode criar Finding se a captura revela divergência imediata
- **Attach**: relaciona Work Items a Findings existentes quando o trabalho rastreável existe
- **Promote**: executa Readiness Checks (podem bloquear); Findings de Readiness impedem avanço
- **Close**: produz Evidence de conclusão; pode criar ou atualizar Finding quando o fechamento revela condição não resolvida

### diligence-async

- **Scan**: executa Checks declarados; coleta Evidence do estado detectado
- **Flag**: cria ou atualiza Findings com base nos resultados do Scan; classifica severidade e ação
- **Repair**: executa ou relaciona Remediações autorizadas; cria Work Items quando necessário

### Workspace Reconciliation

- **Inspect**: produz Evidence estrutural do estado do workspace; pode revelar Findings estruturais
- **Reconcile**: executa Remediation autorizada no workspace
- **Verify**: produz Evidence de verificação; atualiza Finding para Verified quando condição foi resolvida

---

## Cinco exemplos de uso do modelo

### Exemplo 1 — Work Item sem Artifact ID

1. Check de rastreabilidade (DIL-TRC-001) executa durante Scan
2. Finding High criado: "Work Item #57 não possui Artifact ID válido" (FND-2026-0001)
3. Evidence: output de `gh issue view 57 --json body,labels` mostrando campo ausente
4. Remediation proposta: atualizar campos do Work Item com referência ao artefato (RMD-2026-0001)
5. Work Item de Remediation criado e executado
6. Check executado novamente → Pass
7. Finding atualizado com Evidence de verificação → Verified → Closed

### Exemplo 2 — Business Signal passivo sem Issue

1. Check avalia: "Business Signal #BS-042 possui operação ativa sem Work Item?"
2. Resultado: Not Applicable (sinal passivo — sem operação ativa autorizada)
3. Nenhum Finding criado
4. Prova que ausência de Issue não é divergência automática

### Exemplo 3 — Campo obrigatório removido do GitHub Project

1. Check estrutural (DIL-STR-007): "Campo 'operation' existe no GitHub Project?"
2. Finding Medium criado (FND-2026-0002): "Campo obrigatório 'Operation' ausente no GitHub Project"
3. Evidence: antes (gh project field-list output com campo) e depois (sem campo)
4. Workspace Reconciliation invocada como Remediation
5. Reconcile: restaurar campo seguindo Canonical Specification
6. Verify: Evidence de conformance após reconciliação
7. Finding → Verified → Closed

### Exemplo 4 — Reliability Plan ausente quando obrigatório

1. Check de Readiness bloqueante (DIL-OPS-003): "Reliability Plan existe para item com movimentação financeira?"
2. Finding High criado (FND-2026-0003), bloqueio de promoção ao Iteration Plan
3. Evidence: OBC file + Assessment decision referenciando necessidade do Reliability Plan
4. Remediation: criar/completar Reliability Plan após decisão autorizada (RMD-2026-0002)
5. Evidence comprova critérios satisfeitos (documento criado e revisado)
6. Promoção reavaliada → Check retorna Pass → Finding → Verified → Closed

### Exemplo 5 — Waiver temporário para divergência conhecida

1. Finding High reconhecido (FND-2026-0004): dependência circular entre dois artefatos
2. Correção requer refatoração que não pode ser concluída antes da Release planejada
3. Waiver aprovado com validade de 14 dias (WVR-2026-0001), controle compensatório definido
4. Finding permanece visível com status Waived; bloqueio de promoção suspenso
5. Waiver expira → Finding volta a exigir tratamento (status muda para Acknowledged)
6. Nova decisão necessária: nova Remediation ou novo Waiver com justificativa atualizada

---

## Anti-padrões (16)

| # | Anti-padrão | Por que é errado |
|---|---|---|
| 1 | Transformar todo Finding em Issue | Viola o modelo N:M; polui o Execution Space com trabalho fantasma; Finding é entidade do Knowledge Space |
| 2 | Usar Issue number como ID do Finding | IDs de Finding são imutáveis e independentes de ferramentas; migração de GitHub quebraria toda rastreabilidade |
| 3 | Apagar Finding resolvido | Perde trilha histórica; impossibilita auditoria; recorrências ficam sem contexto |
| 4 | Fechar Finding sem Evidence | Evidence é o que diferencia resolução verificada de declaração; sem Evidence, o Finding não está realmente resolvido |
| 5 | Considerar Remediation implementada como automaticamente verificada | Implementação e verificação são etapas independentes; a Remediation pode falhar ou ser parcial |
| 6 | Criar Waiver sem expiração | Waiver sem expiração é tratamento permanente de divergência que deve ser resolvida; mascara débito técnico indefinidamente |
| 7 | Renovar Waiver automaticamente | Waiver expirado requer nova decisão consciente e justificada; renovação automática elimina o controle |
| 8 | Usar severidade como sinônimo de prioridade | Severidade descreve impacto intrínseco; prioridade depende de contexto, deadline, custo de correção e risco atual |
| 9 | Criar Finding sem subject | Finding sem sujeito identificado é irrastreável e irresolvível |
| 10 | Gerar novo Finding em toda execução do mesmo Check para o mesmo sujeito | Duplica Findings; perde contagem de recorrências; impossibilita acompanhamento de tendências |
| 11 | Sobrescrever Evidence histórica | Evidence é imutável uma vez registrada; nova coleta gera nova Evidence; o histórico é preservado |
| 12 | Escolher silenciosamente entre fontes conflitantes | Fontes conflitantes devem gerar resultado Indeterminate ou escalação; escolha silenciosa esconde problema de modelo |
| 13 | Bloquear sem fonte normativa | Bloqueio requer regra canônica identificada; bloqueio sem fundamento normativo é arbitrário e incontestável |
| 14 | Tratar Check Error como violação comprovada | Error significa que o Check não pôde executar; pode gerar Finding operacional sobre a falha do mecanismo, não sobre a regra original |
| 15 | Tratar Indeterminate como Pass | Indeterminate significa evidências insuficientes; não é confirmação de conformidade |
| 16 | Permitir que GitHub Project seja fonte de verdade do Finding | Finding vive no Knowledge Space (arquivo Markdown ou registro persistente); o GitHub Project pode espelhar estado mas não é a fonte canônica |

---

## Referências

→ [`finding.md`](finding.md) — definição canônica do Finding
→ [`check.md`](check.md) — definição canônica do Check
→ [`evidence.md`](evidence.md) — definição canônica do Evidence
→ [`remediation.md`](remediation.md) — definição canônica do Remediation
→ [`waiver.md`](waiver.md) — definição canônica do Waiver
→ [`../README.md`](../README.md) — visão geral da jornada Diligence
→ [`../diligence-sync.md`](../diligence-sync.md) — ciclo síncrono
→ [`../diligence-async.md`](../diligence-async.md) — ciclo assíncrono
→ [`../workspace-reconciliation.md`](../workspace-reconciliation.md) — capability de reconciliação
→ [`../../../knowledge-vs-execution.md`](../../../knowledge-vs-execution.md) — princípio KS vs. ES
