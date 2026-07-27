# Product Intent — PI-PILOT-001

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-001.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-001` |
| **Título** | Invoice PIX — Happy Path Completo |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-07-26 |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Registrar e validar o ciclo completo de entrega de uma Feature de Invoice PIX no ProdOps Runtime — do Bootstrap ao Promote — produzindo uma Timeline com eventos reais que confirme que o caminho feliz do OEM é coberto sem gaps de Event Type.

> "Queremos que a Feature de Invoice PIX seja executada com Runtime completo — Timeline registrada, Derived State calculado, GitHub COR sincronizado — confirmando que o happy path Bootstrap→Promote é operável sem ajustes estruturais."

---

## Hipótese

> **O ciclo de entrega de Invoice PIX pode ser executado integralmente com o OEM e os Event Types existentes no catálogo Delivery v2, sem necessidade de novos conceitos arquiteturais.**

---

## Escopo da Feature

### O que esta Feature entrega (domínio de Payments)

Geração de uma cobrança PIX para um pedido: criação da intent de pagamento, solicitação de QR Code ao Pix Provider, retorno do QR Code + expiração, exposição ao consumidor. A Feature não inclui confirmação de pagamento (que é PI-PILOT-003).

### Padrão ProdOps exercitado

| Padrão | Exercitado? |
|---|---|
| Happy Path — Bootstrap.Started → Promote.Completed | ✅ Foco primário |
| Gate.Passed / Gate.Failed | ✅ — gate de quality na fase Validate |
| Rework | ❌ — não exercitado nesta Feature |
| Blocking (Impediment) | ❌ — não exercitado nesta Feature |
| Event.Corrected | ❌ — não exercitado nesta Feature |

### Sequência de eventos esperada na Timeline

```
Delivery.Bootstrap.Started
Delivery.Bootstrap.Completed  (ou Delivery.Hack.Started direto)
Delivery.Hack.Started
Delivery.Hack.Completed
Delivery.Sync.Started
Delivery.Sync.Completed
Delivery.Finish.Started
Delivery.Finish.Completed
Delivery.Ship.Started
Delivery.Ship.Completed
Delivery.Validate.Started
Delivery.Gate.Passed
Delivery.Validate.Completed
Delivery.Promote.Started
Delivery.Promote.Completed
```

---

## Valor esperado

### Para o piloto operacional

- Primeira Timeline completa com Work Item real do payments-api
- Baseline do Lead Time e Cycle Time de uma Feature de Payments simples
- Evidência de que o happy path do OEM funciona em condição real

### Para o produto (payments-api)

- Feature de Invoice PIX implementada, testada e promovida com rastreabilidade completa
- Histórico auditável da entrega — quem entregou, quando, por quê, quais gates foram passados

---

## Critérios de sucesso

1. Timeline de `Bootstrap.Started` a `Promote.Completed` registrada sem interrupção
2. Nenhum evento real ficou sem Event Type correspondente no catálogo Delivery v2
3. Derived State calculado pelo RT-02 reflete corretamente o estado em cada ponto do tempo
4. GitHub COR sincronizado com o Derived State final (State = DONE)
5. Gate.Passed registrado em pelo menos uma fase

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] Qual Event Type canônico registra a geração do QR Code — existe um evento de sistema (`Delivery.System.Completed`) ou precisa de um tipo específico?
- [ ] O Bootstrap inclui um Gate para validação de pré-condições de ambiente ou vai direto ao Hack?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
