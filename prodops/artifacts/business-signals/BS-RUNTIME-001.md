# Business Signal — BS-RUNTIME-001

> **Localização canônica:** `prodops/artifacts/business-signals/BS-RUNTIME-001.md`
>
> Um **Business Signal** representa qualquer oportunidade, problema ou hipótese que merece atenção antes de qualquer decisão estratégica. Não é um compromisso. Não é um contrato. Não tem OBC.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `BS-RUNTIME-001` |
| **Título** | Validate the ProdOps Operational Runtime |
| **Data de registro** | 2026-07-25 |
| **Origem** | Team · Technology |
| **Status** | Ativo — gerou PI-RUNTIME-001 |
| **Intent gerada** | [PI-RUNTIME-001](../business-intents/PI-RUNTIME-001.md) |

---

## Qual problema ainda não validamos?

O ProdOps Framework possui um modelo conceitual completo e estabilizado:

- Ontologia Framework → Journey → Cycle → Phase → Capability → Skill → Step
- Operational Event Model (OEM): Event Types, Timelines, Derived State, Shared Types
- Canonical Operational Representation (COR): mapeamento de estados OEM para GitHub Projects
- Três Journeys com catálogos v2: Delivery, Diligence, Assessment
- Shared Types formalizados (Gate.Passed, Gate.Failed, Impediment.Declared)

**O que nunca aconteceu:** o modelo foi documentado mas nunca foi executado com todos os componentes do Runtime operacionalmente integrados. Nenhuma Iteration real foi executada com:

- Operational Timeline registrando Event Instances de um Work Item real
- GitHub COR refletindo os Derived States sincronizados com os eventos da Timeline
- Datadog recebendo métricas derivadas dos dados operacionais (Lead Time, Cycle Time, Gate Failure Rate, Block Time)

O problema não é conceitual — o modelo é sólido. O problema é de **realizabilidade operacional**: não sabemos se o Runtime funciona end-to-end em condições reais.

---

## Por que merece investigação?

Um framework conceitual não validado em execução real carrega riscos ocultos:

1. **Gap modelo-prática:** O OEM define como os eventos devem ser registrados, mas não foi testado com os Skills reais emitindo eventos reais em uma Timeline real.

2. **Sincronização COR-GitHub não comprovada:** O mapeamento de Derived State para Custom Fields do GitHub Projects foi especificado, mas nunca foi sincronizado em uma execução completa de Delivery Journey.

3. **Métricas derivadas não observadas:** O Datadog está definido como destino de métricas operacionais, mas nenhum dashboard com Cycle Time real ou Gate Failure Rate derivado da Timeline foi produzido.

4. **Custo operacional desconhecido:** Não há evidência do overhead real de operar o Framework — quanto tempo leva registrar eventos, qual a fricção dos Skills, se o feedback loop é viável.

5. **Bloqueio para escalar:** Enquanto o Runtime não for validado em um produto, o Framework não pode ser recomendado para outros produtos ou times com confiança baseada em evidência.

A investigação é necessária **antes** de qualquer escalonamento — seja para outros produtos, outros times, ou para construir automações sobre o Runtime.

---

## Quais riscos existem caso a hipótese esteja errada?

| Risco | Consequência se confirmado |
|---|---|
| O Runtime não é viável sem ajustes estruturais | O OEM precisa ser revisado — custo alto em retrospecto |
| O COR não sincroniza corretamente com GitHub Projects | O Estado Derivado fica invisível — perda do benefício de observabilidade |
| Os Skills têm fricção proibitiva | O time para de registrar eventos — Timeline fica incompleta ou abandonada |
| O Derived State é inconsistente com os eventos | Consumers produzem dados incorretos — métricas não confiáveis |
| O Datadog não recebe métricas derivadas | O pilar de observabilidade do Framework falha silenciosamente |
| O overhead do OEM supera o benefício | O Framework aumenta o custo operacional sem retorno mensurável |

O risco mais crítico é o **abandono silencioso** — o time segue executando mas para de registrar eventos, e o Framework vira documentação órfã sem saber.

---

## Quais evidências já possuímos?

| Evidência | Status |
|---|---|
| OEM completo (README, Ontology, Taxonomy, Lifecycle, Schemas, Timeline, Shared Types) | Documentado e estabilizado |
| Delivery Event Catalog v2 (17 tipos, Shared Types integrados) | Documentado |
| Diligence Event Catalog v2 (20 tipos) | Documentado |
| Assessment Event Catalog v2 (19 tipos) | Documentado |
| Diligence Journey executada parcialmente (Scan, Flag, Repair cycles reais) | Evidência parcial — Journey Async rodou |
| GitHub COR especificado (Custom Fields mapeados para Derived State) | Especificado, não validado end-to-end |
| Skills de Delivery, Diligence, Assessment documentados | Documentados |
| Datadog configurado no repositório (EXP-005, EXP-010) | Configurado — integração com OEM não validada |

A evidência existente confirma que o modelo é **consistente internamente**. Não confirma que é **operável em produção**.

---

## Quais evidências ainda faltam?

| Evidência necessária | Descrição |
|---|---|
| Timeline populada com eventos reais | Pelo menos uma Delivery Iteration completa registrada no OEM |
| GitHub COR sincronizado | Custom Fields refletindo Derived State de Work Items reais |
| Derived State calculado e visível | Consumers calculando estado a partir da Timeline sem intervenção manual |
| Métricas no Datadog derivadas da Timeline | Lead Time, Cycle Time, Block Time, Gate Failure Rate calculados de dados reais |
| Feedback do time sobre fricção operacional | Registro qualitativo de onde o Runtime é fluido vs. onde tem atrito |
| Pelo menos uma Diligence Iteration completa no OEM | Diligence Sync + Async com Timeline completa |
| Impediment.Resolved com Lookback em ambiente real | Confirmação do padrão canônico em condição real |

---

## Estado atual do modelo conceitual

O modelo conceitual está **consolidado e estabilizado**. Os seguintes documentos estão em estado `Active` e não devem ser alterados por esta iniciativa:

- `prodops/framework/events/` — OEM completo
- `prodops/framework/events/shared-types.md` — Shared Types v1.0.0
- `prodops/framework/journeys/delivery/events/catalog.md` — v2.0.0
- `prodops/framework/journeys/diligence/events/catalog.md` — v2.0.0
- `prodops/framework/journeys/assessment/events/catalog.md` — v2.0.0

A validação do Runtime **não altera** nenhum destes documentos. Ela gera evidências sobre a aplicabilidade do modelo — e, se necessário, gera Evolution Plans para revisões futuras.
