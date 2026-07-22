# Runbook — [Nome do Cenário]

Localização canônica: nova seção em `prodops/framework/journeys/operation/runbooks.md`

---

## Quando usar

Descreva o sintoma ou alerta que aciona este runbook.

Exemplos:

- "Pix pago sem confirmação em N minutos"
- "Taxa de erro do gateway primário acima de X%"

---

## Impacto

| Dimensão | Descrição |
|---|---|
| Cliente | |
| Negócio (GMV/conversão) | |
| SLO afetado | |
| Severidade sugerida | SEV1 / SEV2 / SEV3 |

---

## Diagnóstico

Passos para confirmar o problema.

```bash
# Comando de verificação 1
# Comando de verificação 2
```

Logs esperados / queries de observabilidade:

---

## Causa raiz provável

Liste as causas mais comuns e como distingui-las.

| Causa | Como identificar |
|---|---|
| | |

---

## Mitigação imediata

Ações que reduzem o impacto sem resolver a causa raiz.

```bash
# Comando ou ação
```

---

## Resolução

Passos para corrigir a causa raiz.

```bash
# Comando ou ação
```

---

## Verificação pós-resolução

Como confirmar que o serviço voltou ao normal.

- [ ]
- [ ]

---

## Rollback

Se necessário, como reverter a mudança que causou o problema.

---

## Escalação

| Situação | Acionar |
|---|---|
| Problema persiste após mitigação | |
| Impacto em mais de X% das transações | |

---

## Histórico de uso

| Data | Incidente | Quem acionou | Resolução |
|---|---|---|---|
| | | | |
