# Business Signal — BS-PILOT-001

> **Localização canônica:** `prodops/artifacts/business-signals/BS-PILOT-001.md`
>
> Um **Business Signal** representa qualquer oportunidade, problema ou hipótese que merece atenção antes de qualquer decisão estratégica. Não é um compromisso. Não é um contrato. Não tem OBC.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `BS-PILOT-001` |
| **Título** | Executar o Piloto Operacional ProdOps com Features Reais do payments-api |
| **Data de registro** | 2026-07-26 |
| **Origem** | Team · Technology |
| **Status** | Ativo — gerou PI-PILOT-001 a PI-PILOT-003 |
| **Antecedente** | [BS-RUNTIME-001](./BS-RUNTIME-001.md) — valida o Runtime; este sinal foca na execução com Work Items reais |
| **Intents geradas** | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) · [PI-PILOT-002](../business-intents/PI-PILOT-002.md) · [PI-PILOT-003](../business-intents/PI-PILOT-003.md) |

---

## Qual problema ainda não validamos?

O ProdOps Runtime chegou a um estágio crítico com a Fase 1 do EXP-013:

- **SDK v0.1.1** implementado com `EventId`, `OperationalEvent`, `CloudEventSource`, `CloudEventEncodingContext`, `StateHistory` e `OperationalStateEngine` completos
- **RT-01 (Operational Event Producer)** implementado — valida, codifica e entrega para `EventPublisher`; 37 testes, Exit 0
- **RT-02 (Operational State Engine)** implementado — compute deterministico puro; `validate → deduplicate → order → applyCorrections → replay → stateHistory`; 98 testes, Exit 0

**O que ainda não aconteceu:** os componentes do Runtime foram implementados e testados isoladamente, mas nunca exercitados com Work Items reais de negócio que cubram o espectro completo de padrões da máquina de estados:

- Nenhum Work Item real passou por `Bootstrap.Started → Promote.Completed` com Timeline registrada e Derived State calculado
- Nenhum cenário de Rework (PR que exige revisão e retorno ao Hack) foi executado com eventos reais na Timeline
- Nenhum cenário de Blocking (Impediment) com Lookback foi exercitado em condição real
- O padrão de conflito durante Sync nunca foi registrado como Event Instance real

O problema não é de capacidade técnica do Runtime — os componentes funcionam. O problema é que a hipótese central do piloto (`PI-RUNTIME-001`) exige evidência de execução com **Work Items heterogêneos reais**, não apenas testes sintéticos.

---

## Por que merece investigação?

O piloto operacional precisa de um conjunto de Work Items que:

1. **Seja representativo do domínio real** — features reais do payments-api, não cenários fabricados
2. **Cubra o espectro completo** da máquina de estados do OEM: happy path, rework, blocking, conflito de Sync
3. **Tenha rastreabilidade bidirecional** — do Business Signal ao evento na Timeline, do evento ao Derived State, do Derived State ao GitHub COR
4. **Produza evidência auditável** — cada Work Item gera uma Timeline que pode ser inspecionada independentemente

Sem um conjunto estruturado de 6 Work Items cobrindo esses padrões, o piloto não poderá confirmar ou refutar a hipótese de Q8 ("O Runtime exige novos conceitos arquiteturais?") com evidência suficiente.

---

## Quais riscos existem caso a hipótese esteja errada?

| Risco | Consequência se confirmado |
|---|---|
| Os 3 happy paths revelam que o OEM é insuficiente para features reais de Payments | Evolution Plan necessário antes de Downstream — piloto encerrado antecipadamente |
| O Rework (PI-PILOT-005) exige conceitos não previstos no Framework | Shared Types ou event catalog precisam de revisão estrutural |
| O Blocking + Lookback (PI-PILOT-006) falha em condição real | Propriedade de imutabilidade da Timeline não satisfeita — bloqueio crítico |
| O conflito durante Sync (PI-PILOT-004) não tem Event Type correspondente no catálogo | Gap de cobertura no catálogo da Delivery Journey |
| Os 6 Work Items produzem evidence inconsistente | Baseline de métricas do piloto é inválido — resultados não interpretáveis |

O risco mais crítico é a **descoberta tardia de gaps estruturais** — identificá-los com Work Items reais, ainda no Discovery, é o objetivo correto. É muito menos custoso descobrir aqui do que após um OBC.

---

## Quais evidências já possuímos?

| Evidência | Status |
|---|---|
| SDK v0.1.1 implementado e tipado (EventId, OperationalEvent, StateHistory, OSE) | Implementado — 0 erros de tipo |
| RT-01 (Operational Event Producer) — 37 testes passando, Exit 0 | Implementado |
| RT-02 (Operational State Engine) — 98 testes passando, Exit 0 | Implementado |
| Workspace COR do payments-api reconciliado (GitHub Projects) | Evidenciado em EXP-013/evidence/ |
| Catálogos v2 de Delivery, Diligence e Assessment (17, 20, 19 tipos) | Documentados e estabilizados |
| EXP-013 em andamento — componentes individuais validados | Parcial — end-to-end pendente |
| features de payments-api existentes com domínio conhecido (PIX, Cartão, Split) | Documentado no product-deck e service decks |

A evidência existente confirma que os **componentes estão prontos**. Não confirma que os **padrões de negócio reais são cobertos**.

---

## Quais evidências ainda faltam?

| Evidência necessária | Descrição |
|---|---|
| Timeline de Work Item real — happy path completo | Bootstrap.Started → Promote.Completed com eventos reais de Payments |
| Timeline de Work Item com Rework | Rework.Started + Rework.Completed com causa documentada |
| Timeline de Work Item com Blocking + Lookback | Impediment.Declared + Impediment.Resolved com Lookback executado |
| Conflito durante Sync mapeado em Event Type | Identificar se há Event Type no catálogo ou se é gap |
| Derived State calculado para cada um dos 6 Work Items | Confirmação de que o OSE deriva o estado correto para cada padrão |
| Evidência de rastreabilidade end-to-end | BS-PILOT-001 → PI → Feature → Timeline → Derived State → GitHub COR |

---

## Estado atual

O sinal está **ativo**. As 6 Product Intents foram geradas e estão sob Discovery. O piloto aguarda a conclusão do Discovery Report, do Roadmap e do Release Draft para avaliar se segue para Downstream (OBC) ou permanece em Upstream (Evolution Plan).

Os documentos `Runtime`, `SDK`, `OEM`, `Timeline` e catálogos de eventos **não são alterados** por este sinal — ele trabalha apenas na camada de produto.
