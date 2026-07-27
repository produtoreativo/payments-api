# GitHub Project #25 — Operational Validation
# EXP-013 Iteration 7

**Validated at:** 2026-07-27T15:31Z
**Project:** ProdOps — payments-api #25
**URL:** https://github.com/orgs/produtoreativo/projects/25
**Project Node ID:** PVT_kwDOAT1J1c4BeiVu

---

## Issues State — API-Validated

State read directly from GitHub Projects v2 GraphQL API (not presumed):

| Issue | Title | oem-state | oem-last-event |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX — Happy Path Completo | **DONE** | prodops.delivery.promote.completed |
| #77 | FTR-002: Invoice Cartão — Happy Path sem PAN | **VALIDATING** | prodops.delivery.validate.started |
| #78 | FTR-003: Confirmação de Pagamento — Webhook | **HACKING** | prodops.delivery.hack.started |

---

## Validation Checks

| Check | Status | Notes |
|---|---|---|
| Issue #76 present in Project | ✅ | Confirmed via GraphQL |
| Issue #77 present in Project | ✅ | Confirmed via GraphQL |
| Issue #78 present in Project | ✅ | Confirmed via GraphQL |
| `oem-state` correct for #76 (DONE) | ✅ | API read |
| `oem-state` correct for #77 (VALIDATING) | ✅ | API read |
| `oem-state` correct for #78 (HACKING) | ✅ | API read |
| `oem-last-event` correct for #76 | ✅ | prodops.delivery.promote.completed |
| `oem-last-event` correct for #77 | ✅ | prodops.delivery.validate.started |
| `oem-last-event` correct for #78 | ✅ | prodops.delivery.hack.started |
| No duplicate Project Items | ✅ | idempotent addProjectV2ItemById |
| Three Issues at distinct states simultaneously | ✅ | DONE / VALIDATING / HACKING |

---

## Views

Existing views in Project #25 (not altered in Iteration 7):
- Board View (grouped by oem-state): Three columns occupied — DONE, VALIDATING, HACKING
- Table View: Three Issues with their respective field values

Visual validation: access https://github.com/orgs/produtoreativo/projects/25 to confirm the three Issues appear in distinct columns.

---

## Auth Scopes Confirmed

`gh auth status` — account: cmilfont — Token scopes include: `project`, `repo`, `admin:org`

All required permissions for read/write to GitHub Project #25 confirmed.
