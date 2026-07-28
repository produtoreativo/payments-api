# Recording Link — exp-014-demo-2026-07-27-1728

**demo-run-id:** `exp-014-demo-2026-07-27-1728`
**Data:** 2026-07-27T17:28:51Z–17:34:02Z
**Duração estimada:** ~5 min (modo DEMO com delays de 4s)

---

## Status

**Gravação de tela: Manual evidence required**

A gravação de tela do fluxo `/delivery --demo --with-diligence` requer captura manual pelo operador com software de gravação de tela (QuickTime, OBS, Loom, etc.).

---

## Como reproduzir a gravação

### Pré-requisitos

1. `bash prodops/runtime/scripts/prepare-demo.sh` → deve retornar 25/25 PASS
2. GitHub Project aberto: https://github.com/orgs/produtoreativo/projects/25
   - View ativa: `01 — Delivery Timeline` (Board, groupBy: oem-state)
3. Datadog Dashboard aberto: https://app.datadoghq.com/dashboard/jhq-ztv-3pv
   - Time window: Last 15 minutes (auto-refresh on)
   - Filtrar `$demo_run_id` pelo ID da nova execução
4. VS Code com Claude Code instalado

### Layout sugerido (16:9)

```
┌──────────────────────┬──────────────────────┐
│  Terminal VS Code    │  GitHub Project      │
│  (Claude Code)       │  Delivery Board      │
│                      │                      │
│  /delivery --demo    │  cards #76 #77 #78   │
│  --with-diligence    │  por oem-state       │
├──────────────────────┴──────────────────────┤
│  Datadog Dashboard                          │
│  Delivery Event Stream / Diligence Tracking │
└─────────────────────────────────────────────┘
```

### Comando de demonstração

```bash
# No Claude Code (VS Code):
/delivery --demo --with-diligence
```

Ou diretamente no terminal:

```bash
bash prodops/runtime/scripts/demo-delivery-with-diligence.sh \
  --demo \
  --with-diligence \
  --demo-run-id exp-014-demo-YYYY-MM-DD-HHMM
```

### O que deve aparecer na gravação

1. Iteration Plan impresso no terminal (IP-001, 3 features, correlation IDs)
2. Runtime Doctor: 13 checks PASS
3. `[DELIVERY] #76` → 15 eventos → DONE (cards movendo no GitHub)
4. `[DELIVERY] #77` → 11 eventos → VALIDATING
5. `[DELIVERY] #78` → 3 eventos → HACKING
6. `[DILIGENCE] #76/#77/#78` → Capture → Attach (4 eventos por feature)
7. `validate-demo.sh` → 28/28 PASS
8. GitHub: todas as 3 features com `oem-state + diligence-status + runtime-sync = In Sync`
9. Datadog: barras de eventos aparecendo em tempo real

### Onde salvar o vídeo

Após gravação, salvar como:
`evidence/recordings/<novo-demo-run-id>/recording.mp4`

Ou, se o arquivo for muito grande para versionar:
- Upload no Google Drive / Loom / Vimeo
- Atualizar este arquivo com URL, checksum SHA256, duração e data

---

## Evidências alternativas presentes

Embora o vídeo não esteja gravado, as evidências técnicas estão completas:

| Evidência | Status |
|---|---|
| `demo-summary.json` | ✅ `{delivery: 29, diligence: 12}` |
| `delivery-timelines/` | ✅ 76.json (15), 77.json (11), 78.json (3) |
| `diligence-timelines/` | ✅ 4 eventos por feature |
| `derived-states/` | ✅ DONE/VALIDATING/HACKING |
| `github-snapshot.json` | ✅ Attached/Complete/In Sync |
| `datadog-validation.json` | ✅ API status ok |
| `validate-demo.sh` | ✅ 28/28 PASS |
