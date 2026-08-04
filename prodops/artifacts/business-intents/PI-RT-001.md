# Product Intent — PI-RT-001

> **Localização canônica:** `prodops/artifacts/business-intents/PI-RT-001.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-RT-001` |
| **Título** | Event Pipeline Completeness — Bootstrap intermediários e sync de oem-state |
| **Origin Stream** | Technology |
| **Data de registro** | 2026-08-04 |
| **Business Signal de origem** | [#135](https://github.com/produtoreativo/payments-api/issues/135) — Qualidade operacional Runtime v0.11.0 |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |

---

## Objetivo

Garantir que todos os eventos do ciclo de Bootstrap chegam ao Datadog (não apenas Started e Completed) e que cada evento emitido transita o oem-state corretamente no GitHub Project — eliminando os gaps de observabilidade detectados na Iteration v0.11.0.

> "Queremos que o pipeline de eventos seja completo e confiável — cada evento emitido deve aparecer no Datadog com tags corretas e refletir o estado no GitHub Project sem intervenção manual."

---

## Hipótese

> **Os gaps de eventos e o oem-state inconsistente têm raízes corrigíveis no pipeline emit-event → github/sync.sh: eventos de fase intermediária ou não são emitidos, ou a derivação de estado falha silenciosamente.**

---

## Escopo

### Problemas mapeados

| # | Problema | Signal |
|---|---|---|
| 1 | Eventos intermediários do Bootstrap (Dependencies.Installed, Services.Ready, Smoke.Passed) ausentes no Datadog | #135 item 2 |
| 2 | DS-53 não transitou para FINISHING no GitHub Project apesar do evento Finish.Started ter chegado ao Datadog | #135 item 3 |

### O que está fora do escopo

- Mudanças no schema CloudEvents (contrato estável)
- Alterações nos dashboards Datadog (coberto por PI-RT-003)

---

## Critérios de sucesso

1. Todos os 5 eventos de Bootstrap (Started, Dependencies.Installed, Services.Ready, Smoke.Passed, Completed) aparecem no Datadog com `issue:<work-item-id>` correto
2. Cada evento `Delivery.<Phase>.Started` transita o oem-state para o estado correspondente no GitHub Project dentro de 60s
3. `emit-event.sh` retorna `"github-sync": "success"` para todos os eventos de fase
4. Nenhum estado FINISHING, SYNCING, FINISHING detectado como "skip" no GitHub sync

---

## Perguntas em aberto

- [ ] Os eventos intermediários de Bootstrap são emitidos pelo skill mas não chegam ao Datadog, ou não são emitidos pelo skill?
- [ ] O oem-state FINISHING de DS-53 — o github/sync.sh recebeu o evento mas não conseguiu atualizar o Project, ou o evento nunca chegou ao github/sync.sh?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [#135](https://github.com/produtoreativo/payments-api/issues/135) | Aberto |
| Business Intent | `prodops/artifacts/business-intents/PI-RT-001.md` | Este arquivo |
