# Evidence: Workspace Doctor — Before Provisioning

**EXP-013 — Phase 1: Environment Preparation**
**Captured:** 2026-07-25
**Command:** `npx tsx src/cli.ts doctor`

---

```
Running doctor: "ProdOps — payments-api"
Owner: produtoreativo/payments-api

══ Workspace Doctor Report ══════════════════════════════

Project   : found (#24)
Milestone : found (#1)
Fields    : 18 configured, 34 drift(s)
Labels    : 25 configured, 25 drift(s)
Views     : 7 configured, 7 drift(s)
Issues    : 10 configured, 10 drift(s)

── Drifts ───────────────────────────────────────────────

❌ [field] witem type
   fix      : gh project field-create 24 --owner "produtoreativo" --name "witem type" --data-type SINGLE_SELECT --single-select-options "Feature,Runtime Task,Finding"

❌ [field] witem repository
❌ [field] witem feature
❌ [field] witem obc
❌ [field] witem release
❌ [field] witem iteration
❌ [field] oem journey
❌ [field] oem cycle
❌ [field] oem phase
❌ [field] oem state
❌ [field] oem rework-count
❌ [field] oem blocked-since
❌ [field] diligence status
❌ [field] diligence evidence
❌ [field] runtime sync
❌ [field] runtime timeline-state
❌ [field] oem last-event
❌ [field] runtime last-sync

[16 extra fields from existing project configuration — informational]
[25 labels missing]
[7 views missing]
[10 issues missing]

── Summary ──────────────────────────────────────────────

  ❌ Workspace has 76 drift(s) — run 'workspace provision' to repair
```

---

## Interpretação

Estado inicial: projeto e milestone já existiam (criados em sessão anterior);
todos os 18 campos COR, 25 labels, 7 views e 10 issues ausentes.

**Conclusão:** Workspace requer provisionamento completo.
