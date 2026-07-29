# EXP-016 — Incremento 4: Validação do GitHub Project

**Data:** 2026-07-29

---

## Views Disponíveis

| View # | Nome | Layout | Propósito |
|--------|------|--------|-----------|
| 2 | 01 — Delivery Timeline | BOARD | Tracking por oem-state |
| 4 | 03 — Diligence Tracking | BOARD | Tracking por diligence-status |
| 5 | 04 — Runtime Reconciliation | TABLE | Reconciliação runtime |
| 7 | 02 - Iteration Plan | BOARD | Contexto do plano |
| 8 | 05 — Active Features | BOARD | Features Delivery ativas |
| 9 | 06 — Executive Overview | TABLE | Visão executiva |

---

## Estado das Features após EXP-016

| Issue | Feature | oem-state | oem-last-event | diligence-status | runtime-sync |
|-------|---------|-----------|---------------|-----------------|-------------|
| #76 | FTR-001: Invoice PIX | **DONE** | prodops.diligence.promote.completed | Closed | In Sync |
| #77 | FTR-002: Invoice Cartão | VALIDATING | — | Closed | In Sync |
| #78 | FTR-003: Confirmação Pagamento | HACKING | — | Closed | In Sync |

---

## Movimento Automático do Card

**Feature #76 (FTR-001)**:

```
BOOTSTRAPPING (antes) → HACKING → SYNCING → FINISHING → SHIPPING → VALIDATING → DONE (depois)
```

O `oem-state` foi atualizado automaticamente pelo Runtime em cada evento `*.Completed`, sem intervenção manual:
- `Bootstrap.Completed` → BOOTSTRAPPING
- `Hack.Completed` → HACKING
- `Sync.Completed` → SYNCING
- `Finish.Completed` → FINISHING
- `Ship.Completed` → SHIPPING
- `Validate.Completed` → VALIDATING
- `Promote.Completed` → **DONE**

Todas as 7 transições de estado foram sincronizadas via `github/sync.sh` com resultado `"github-sync": "success"`.

---

## Configuração manual recomendada para demonstração

As views de board (board layout) no GitHub UI devem ter `Column by: oem-state` configurado manualmente (não setável via API REST). Para a demonstração:

| View | Configurar |
|------|-----------|
| 01 — Delivery Timeline | Column by: `oem-state` |
| 05 — Active Features | Column by: `oem-state` |
| 03 — Diligence Tracking | Column by: `diligence-status` |

---

## Links para demonstração

| Sistema | URL |
|---------|-----|
| Delivery Timeline | https://github.com/orgs/produtoreativo/projects/25/views/2 |
| Diligence Tracking | https://github.com/orgs/produtoreativo/projects/25/views/4 |
| Active Features | https://github.com/orgs/produtoreativo/projects/25/views/8 |
| Executive Overview | https://github.com/orgs/produtoreativo/projects/25/views/9 |

**Resultado Incremento 4:** ✓ Cards movimentaram automaticamente — oem-state=DONE confirmado via GitHub API
