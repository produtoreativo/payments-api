# Waiver — Definição Canônica

## Definição

> **Waiver é uma autorização explícita, justificada, limitada e temporária para aceitar uma condição registrada em um Finding sem executar imediatamente sua Remediation completa.**

---

## Princípios fundamentais

- **Waiver não deleta a regra.** A regra continua vigente; apenas a aplicação imediata está suspensa.
- **Waiver não declara que a condição é correta.** O Finding continua sendo uma divergência — o Waiver apenas autoriza conviver temporariamente com ela.
- **Waiver não elimina o Finding.** O Finding permanece visível, rastreável e com seu status próprio (Waived).
- **Waiver muda o modo de tratamento temporariamente.** Enquanto o Waiver está ativo, a condição não bloqueia operações que normalmente bloquearia.
- **Waiver expirado retorna o Finding ao fluxo normal.** O Finding volta a exigir tratamento — seja nova Remediation ou novo Waiver com nova justificativa.

---

## Formato de ID

```
WVR-YYYY-NNNN
```

- `WVR`: prefixo imutável da entidade Waiver
- `YYYY`: ano de aprovação (quatro dígitos)
- `NNNN`: sequencial de quatro dígitos por ano (0001–9999)

Exemplos: `WVR-2026-0001`, `WVR-2026-0012`

---

## Schema

| Campo | Tipo conceitual | Cardinalidade | Regras e notas |
|---|---|---|---|
| `id` | string | 1 | Formato WVR-YYYY-NNNN; imutável; único no sistema |
| `finding_id` | string | 1 | Exatamente um Finding; um Waiver endereça um Finding específico |
| `reason` | text | 1 | Obrigatório; justificativa de negócio ou técnica para aceitar a condição temporariamente |
| `scope` | text | 1 | Obrigatório; o que exatamente está sendo dispensado — deve ser explícito e limitado |
| `approved_by` | string | 1 | Papel ou identidade com autoridade para aprovar o Waiver para o tipo de condição em questão |
| `approved_at` | datetime | 1 | Imutável após aprovação; data e hora da aprovação formal |
| `valid_from` | date | 1 | Data de início da validade |
| `expires_at` | date | 1 | **Obrigatório.** Sem exceções neste estágio. Data de expiração explícita e limitada |
| `conditions` | list de strings | 0..N | Condições que devem ser mantidas enquanto o Waiver está ativo |
| `compensating_controls` | list de strings | 0..N | Controles em vigor enquanto o Waiver está ativo para mitigar o risco da condição aceita |
| `review_date` | date | 0..1 | Data de revisão intermediária opcional antes da expiração |
| `status` | enum | 1 | Ver fluxo de estados abaixo |
| `revoked_at` | datetime | 0..1 | Set se o Waiver for revogado antes da expiração |
| `revoked_by` | string | 0..1 | Papel ou identidade que revogou; obrigatório se `revoked_at` está preenchido |
| `evidence` | Evidence ID | 1 | Evidence da aprovação formal; obrigatório |

---

## Regras obrigatórias

Todo Waiver deve conter:

1. **Referência ao Finding** — `finding_id` preenchido; exatamente um Finding
2. **Justificativa** — `reason` descrevendo por que a condição está sendo aceita temporariamente
3. **Owner** — papel responsável pelo acompanhamento do Waiver
4. **Aprovador autorizado** — `approved_by` com papel com autoridade para esta classe de condição
5. **Escopo explícito** — `scope` descrevendo com precisão o que está sendo dispensado
6. **Período de validade** — `valid_from` e `expires_at` preenchidos
7. **Risco aceito** — `reason` deve incluir descrição do risco sendo aceito
8. **Controles compensatórios** — `compensating_controls` quando aplicável ao risco
9. **Data de revisão** — `review_date` recomendada para Waivers com validade superior a 30 dias
10. **Evidence de aprovação** — `evidence` preenchido com EVD da aprovação formal

---

## Regra de expiração

**Waiver sem `expires_at` é inválido.** Esta regra não tem exceções neste estágio do Framework. Waivers permanentes não são permitidos.

Ao criar um Waiver, a data de expiração deve ser:
- Realista: prazo suficiente para concluir a Remediation
- Limitada: não usar prazos indefinidamente longos como substituto para Remediation
- Justificada: a razão para o prazo deve ser documentada no `reason`

---

## Waiver expirado

Quando um Waiver expira:

1. O status do Waiver muda para **Expired**
2. O Finding **retorna ao status Acknowledged** (ou Open, se o Acknowledged nunca ocorreu)
3. Um sinal deve ser gerado para notificar o owner
4. O Finding volta a bloquear operações que bloquearia sem o Waiver
5. **Nenhum Waiver é renovado automaticamente** — uma nova decisão consciente e justificada é necessária
6. A nova decisão pode ser: (a) nova Remediation, (b) novo Waiver com nova justificativa, ou (c) aceitação formal como risco residual documentado

---

## Unicidade de Waiver ativo

**Somente um Waiver pode estar ativo por Finding por escopo por período.** Se as condições mudaram e um novo Waiver é necessário antes da expiração do anterior, o Waiver atual deve ser revogado explicitamente antes de um novo ser aprovado.

---

## Revogação

Um Waiver pode ser revogado antes de expirar quando:
- A condição mudou e a justificativa original não é mais válida
- O risco da condição aumentou
- Os controles compensatórios não foram mantidos
- Uma Remediation foi concluída antes da expiração
- Decisão de governança determina que o Waiver não é mais aceitável

Ao revogar: `revoked_at` e `revoked_by` obrigatórios; motivo da revogação documentado na trail do Finding; Finding retorna ao fluxo normal de tratamento.

---

## Checks com `waiver_allowed: false`

Alguns Checks podem declarar que nenhum Waiver é aceitável para as condições que detectam. Quando `waiver_allowed: false`:

- Nenhum Waiver pode suspender o bloqueio gerado por este Check
- O Finding gerado deve ser resolvido por Remediation completa
- Nenhuma autorização, por mais alto o nível hierárquico, pode substituir a Remediation

Esta declaração é usada com critério extremo — apenas para casos em que a condição representa risco que não pode ser gerenciado por aceitação temporária. Exemplos conceituais (sem pretensão de catálogo completo):
- Perda deliberada e irreversível de rastreabilidade
- Promoção sem aprovação obrigatória documentada em contexto regulatório

Não criar catálogo de regras não-dispensáveis neste estágio.

---

## Fluxo de estados

```
Proposed → Approved → Active → Expired → (Finding retorna a Acknowledged)
                             → Revoked  (revogação explícita com motivo)
         → Rejected  (aprovador recusou)
         → Closed    (Finding Verified eliminando necessidade; ou encerramento adequado)
```

| Estado | Significado | Quem pode transicionar |
|---|---|---|
| **Proposed** | Waiver solicitado; aguarda aprovação formal | Diligence ou owner |
| **Approved** | Aprovado; aguardando início da validade | Aprovador autorizado |
| **Active** | Em vigor; Waiver suspende bloqueio conforme política | Automático quando `valid_from` é atingido |
| **Expired** | `expires_at` foi atingido; Finding volta ao fluxo normal | Automático por temporalidade |
| **Revoked** | Revogado antes da expiração com motivo explícito | Processo de governança |
| **Rejected** | Aprovador recusou a proposta com justificativa | Aprovador autorizado |
| **Closed** | Encerrado adequadamente: Finding resolvido ou encerramento formal documentado | Diligence após Finding Verified |

---

## Relação com Finding e Remediation

```
Finding (FND-2026-XXXX)
   │ Finding identificado e Acknowledged
   │
   ├── Remediation proposta mas não pode ser executada imediatamente
   │
   └── Waiver (WVR-2026-XXXX) criado e aprovado
         │ Finding → Waived
         │ Bloqueio suspenso (se waiver_allowed: true)
         │ Finding permanece visível e rastreável
         │
         ├── Waiver expira → Finding → Acknowledged → nova decisão
         │
         └── Remediation concluída → Finding → Resolved → Verified
               → Waiver → Closed
```

---

## Referências

→ [`README.md`](README.md) — modelo de entidades e relações
→ [`finding.md`](finding.md) — entidade que o Waiver endereça
→ [`evidence.md`](evidence.md) — Evidence da aprovação do Waiver
→ [`remediation.md`](remediation.md) — alternativa ao Waiver quando correção é possível
→ [`check.md`](check.md) — definição de `waiver_allowed` no Check
