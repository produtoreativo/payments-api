---
name: delivery
description: Execute the full Delivery + Diligence demo flow for the active Iteration Plan. Use when running a governed demo with CloudEvents, GitHub Project sync, and Datadog metric emission.
argument-hint: "[--demo] [--with-diligence] [--demo-run-id <id>] [--fast]"
---
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/delivery/SKILL.md
     Player:    copilot
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: 2026-08-06T13:38:35Z
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill delivery
-->

# DELIVERY

Executa o fluxo Delivery + Diligence para o Iteration Plan ativo.

## Flags

| Flag | Comportamento |
|---|---|
| `--demo` | Ativa delays visuais entre eventos (padrão: 4s) |
| `--with-diligence` | Executa Diligence Capture → Attach após Delivery |
| `--demo-run-id <id>` | Define o ID de isolamento (padrão: auto-gerado) |
| `--fast` | Desativa delays (modo ensaio técnico) |

## Execução

### 1. Carregar o Iteration Plan

Leia `prodops/artifacts/plans/iteration-plan-pilot.md` e imprima o cabeçalho do plano:

```
═══════════════════════════════════════════════════════════════
  ITERATION PLAN — IP-001 (Piloto Operacional Fase 2)
  Produto: payments-api
═══════════════════════════════════════════════════════════════

  Features selecionadas para esta execução (Bloco 1):
  ┌────┬──────────────────────────────────────────┬──────────────┐
  │ #  │ Feature                                  │ Estado Final │
  ├────┼──────────────────────────────────────────┼──────────────┤
  │ 76 │ FTR-001: Invoice PIX — Happy Path        │ DONE         │
  │ 77 │ FTR-002: Invoice Cartão                  │ VALIDATING   │
  │ 78 │ FTR-003: Confirmação de Pagamento        │ HACKING      │
  └────┴──────────────────────────────────────────┴──────────────┘

  Eventos planejados por Feature:
    #76 → 15 eventos (Bootstrap→Hack→Sync→Finish→Ship→Validate→Promote)
    #77 → 11 eventos (Bootstrap→Hack→Sync→Finish→Ship→Validate)
    #78 →  3 eventos (Bootstrap→Hack.Started)

  Diligence (--with-diligence):
    Cada Feature: Capture.Started → Capture.Completed → Attach.Started → Attach.Completed
    Total: 12 eventos Diligence

  Referência: prodops/artifacts/plans/iteration-plan-pilot.md
═══════════════════════════════════════════════════════════════
```

### 2. Gerar o demo-run-id (se não fornecido via `--demo-run-id`)

Formato: `exp-014-demo-YYYY-MM-DD-HHMM` (UTC)

### 3. Executar o script

```bash
bash prodops/runtime/scripts/demo-delivery-with-diligence.sh \
  [flags passadas pelo usuário] \
  --demo-run-id <demo-run-id>
```

Se o usuário invocou `/delivery --demo --with-diligence`, passe `--demo --with-diligence`.
Se invocou apenas `/delivery`, passe sem flags (modo fast/ensaio).

### 4. Criar o iteration-plan-snapshot

Após execução, salve:
`prodops/artifacts/experiments/014-diligence-tracks-delivery/evidence/recordings/<demo-run-id>/iteration-plan-snapshot.md`

Conteúdo:
- iteration-id, produto, data de execução
- demo-run-id utilizado
- tabela de features com correlation IDs capturados da saída
- eventos por feature
- resultado do validate-demo.sh (se executado)

### 5. Executar validate-demo.sh

```bash
bash prodops/runtime/scripts/validate-demo.sh --demo-run-id <demo-run-id>
```

## Restrições

- Nunca expor credenciais na saída
- Script interno: `prodops/runtime/scripts/demo-delivery-with-diligence.sh`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan-pilot.md`
- GitHub Project: https://github.com/orgs/produtoreativo/projects/25
- Dashboard Datadog: https://app.datadoghq.com/dashboard/jhq-ztv-3pv
