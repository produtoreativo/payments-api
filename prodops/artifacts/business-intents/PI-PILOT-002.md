# Product Intent — PI-PILOT-002

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-002.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-002` |
| **Título** | Invoice Cartão — Happy Path sem Armazenar PAN |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-07-26 |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Registrar e validar o ciclo completo de entrega de uma Feature de Invoice Cartão via fluxo hospedado — sem armazenar PAN — no ProdOps Runtime, confirmando que o caminho feliz do OEM cobre o ciclo de cartão e que a restrição de não-armazenamento de PAN não exige Event Types adicionais no catálogo.

> "Queremos que a Feature de Invoice Cartão (hosted, sem PAN) seja executada com Runtime completo — Timeline registrada, Derived State calculado — confirmando que o happy path de cartão é coberto pelo OEM sem gaps e sem comprometer constraints de compliance (PCI-DSS)."

---

## Hipótese

> **O ciclo de entrega de Invoice Cartão via fluxo hospedado pode ser executado com o OEM existente, e a restrição de não-armazenamento de PAN é endereçável no nível de implementação, sem necessidade de Event Types ou Shared Types novos.**

---

## Escopo da Feature

### O que esta Feature entrega (domínio de Payments)

Geração de uma cobrança de cartão de crédito via fluxo hospedado (tokenized/hosted): o Payments cria uma intent de pagamento, o gateway hospeda a coleta de dados do cartão (nunca trafegando o PAN pela payments-api), e retorna um identificador de cobrança. O PAN nunca é armazenado ou logado pela payments-api.

### Invariante de segurança

O PAN (Primary Account Number) **nunca aparece** em nenhum campo de nenhum `EventInstance` na Timeline — nem em `payload`, nem em `notes`, nem em `producer_identity`. Esta invariante é estrutural e deve ser verificável pela inspeção dos eventos registrados.

### Padrão ProdOps exercitado

| Padrão | Exercitado? |
|---|---|
| Happy Path — Bootstrap.Started → Promote.Completed | ✅ Foco primário |
| Gate.Passed / Gate.Failed | ✅ — gate de compliance no Validate (PAN-free check) |
| Rework | ❌ — não exercitado nesta Feature |
| Blocking (Impediment) | ❌ — não exercitado nesta Feature |
| Event.Corrected | ❌ — não exercitado nesta Feature |

### Sequência de eventos esperada na Timeline

```
Delivery.Bootstrap.Started
Delivery.Hack.Started
Delivery.Hack.Completed
Delivery.Sync.Started
Delivery.Sync.Completed
Delivery.Finish.Started
Delivery.Finish.Completed
Delivery.Ship.Started
Delivery.Ship.Completed
Delivery.Validate.Started
Delivery.Gate.Passed          (compliance: PAN-free verificado)
Delivery.Validate.Completed
Delivery.Promote.Started
Delivery.Promote.Completed
```

---

## Valor esperado

### Para o piloto operacional

- Segunda Timeline completa — segundo ponto de evidência do happy path
- Confirmação de que o Gate.Passed serve como mecanismo de auditoria de compliance
- Verificação de que a invariante PAN-free é estruturalmente garantida no modelo de eventos

### Para o produto (payments-api)

- Feature de Invoice Cartão promovida com rastreabilidade de compliance incorporada à Timeline
- Evidência auditável de que nenhuma etapa do ciclo de entrega armazenou PAN

---

## Critérios de sucesso

1. Timeline de `Bootstrap.Started` a `Promote.Completed` registrada sem interrupção
2. Nenhum `EventInstance` na Timeline contém PAN em qualquer campo
3. `Gate.Passed` com nota de compliance registrado na fase Validate
4. Derived State calculado corretamente em cada ponto do tempo
5. Nenhum Event Type novo foi necessário além do catálogo Delivery v2

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] O gate de compliance (PAN-free) usa `Delivery.Gate.Passed` com `notes` descritivos, ou precisa de um Shared Type específico para compliance gates?
- [ ] Como evidenciar a ausência de PAN — inspeção manual dos eventos da Timeline ou verificação automatizada?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
