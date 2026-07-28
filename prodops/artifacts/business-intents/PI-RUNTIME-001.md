# Product Intent — PI-RUNTIME-001

> **Localização canônica:** `prodops/artifacts/business-intents/PI-RUNTIME-001.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação. É o ponto de entrada formal do Framework antes de decidir se o trabalho segue por Discovery.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-RUNTIME-001` |
| **Título** | Validate the ProdOps Operational Runtime on payments-api |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-07-25 |
| **Business Signal de origem** | [BS-RUNTIME-001](../business-signals/BS-RUNTIME-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Exploration |

---

## Objetivo

Validar que o ProdOps Framework funciona end-to-end em condições reais — utilizando o **payments-api** como produto de referência — comprovando que o Runtime operacional é viável, observável e sustentável por um time de engenharia real.

> "Queremos que o time do payments-api consiga operar o ProdOps Runtime completo — registrando eventos em Timelines, sincronizando o GitHub COR, e observando Derived State no Datadog — confirmando que o modelo conceitual é realizável sem ajustes estruturais."

---

## Hipótese principal

> **O modelo conceitual do ProdOps Framework (Journeys, OEM, Canonical Operational Representation, Operational Timelines, Derived State) é realizável e operável por um time real em um produto real, sem necessidade de revisão estrutural, com overhead aceitável e observabilidade funcional.**

Esta hipótese só pode ser confirmada ou refutada com dados de execução real. Não é possível validá-la por análise de documentos.

---

## Escopo de validação

Esta Product Intent pretende validar os seguintes componentes do Runtime:

| Componente | O que será validado |
|---|---|
| **Runtime** | O ProdOps Runtime é operável por um time real — Skills são executáveis sem guia constante |
| **Delivery Journey** | Uma Iteration completa de Delivery é executada com Timeline registrada e Derived State calculado |
| **Diligence Journey** | Um ciclo completo de Diligence Sync + Async com Timeline completa e COR sincronizado |
| **GitHub COR** | Custom Fields do GitHub Projects refletem Derived State calculado a partir da Timeline |
| **Datadog** | Métricas derivadas da Timeline (Lead Time, Cycle Time, Block Time, Gate Failure Rate) chegam ao Datadog |
| **Operational Timeline** | Event Instances reais são registrados em uma Timeline real, imutável e append-only |
| **Derived State** | O Consumer calcula Derived State corretamente a partir da Timeline sem intervenção manual |

---

## Valor esperado

### Valor primário — evidência de realizabilidade

Confirmação baseada em execução real de que o OEM, a COR e o Datadog integration funcionam conforme especificado. Sem esta evidência, o Framework não pode ser recomendado para escalonamento.

### Valor secundário — identificação de gaps

Durante a validação, gaps entre o modelo e a prática serão identificados: fricção nos Skills, campos de payload desnecessários, eventos ausentes, sincronizações que falham. Esta é informação de alto valor para os Evolution Plans dos catálogos.

### Valor terciário — baseline operacional

A primeira Timeline completa do payments-api estabelece o baseline operacional: qual é o Lead Time real, qual é a taxa de falha de gates, qual é o Block Time médio. Esses dados informam futuros ciclos de Assessment.

---

## Critérios para avançar para Discovery

Esta Product Intent avança para Discovery quando:

1. **Delivery:** pelo menos uma Iteration completa executada com Timeline registrada — evento Bootstrap.Started até Promote.Completed, com Gate.Passed e Impediment.Declared/Resolved reais
2. **Diligence:** pelo menos um ciclo Diligence Sync + um ciclo Diligence Async completados com Timeline registrada e GitHub COR refletindo Derived State
3. **GitHub COR:** Custom Fields atualizados automaticamente (ou com procedimento claro e executável) para refletir o último Derived State de cada Work Item ativo
4. **Datadog:** pelo menos uma métrica derivada da Timeline (ex.: Cycle Time de uma Iteration) visível em Datadog com trace rastreável até os eventos da Timeline
5. **Derived State:** Consumer calculando Derived State corretamente para Timelines históricas e ativas, com Lookback funcionando para Impediment.Resolved

**Critério de parada antecipada (go/no-go):** se qualquer um dos cinco critérios acima revelar um bloqueio estrutural (não apenas fricção operacional), o Discovery produzirá um Evolution Plan em vez de um plano de entrega.

---

## Por que pertence ao payments-api

O payments-api é o produto onde o ProdOps Framework está mais maduro:

- Diligence Journey já executada parcialmente (Scan/Flag/Repair cycles reais)
- Delivery Journey documentada e com Skills operacionais
- OBCs ativos (crédito, pagamentos)
- Experiments executados (EXP-001 a EXP-012)
- Datadog já configurado (EXP-005, EXP-010)
- GitHub Projects com workspace reconciliado

Não existe outro produto no ecossistema com esta base. Executar a validação em outro produto exigiria construir o Foundation do zero — o que inverte a prioridade.

---

## Por que não depende do Portfolio

Esta iniciativa não precisa de aprovação ou coordenação do Portfolio porque:

1. **Escopo claro:** a validação é inteiramente local ao payments-api — não há impacto em outros produtos ou times
2. **Sem dependência de recursos externos:** o time já tem acesso a GitHub Projects, Datadog e ao código do payments-api
3. **Framework-first:** é uma validação técnica do próprio Framework, não uma iniciativa de negócio que requer priorização estratégica
4. **Sem OBC bloqueado no Portfolio:** a Business Intent é local — não há Global OBC pendente de aprovação

O Portfolio seria envolvido apenas se a validação concluir que o Runtime exige mudanças estruturais no Framework — nesse caso, um Evolution Plan seria submetido para aprovação.

---

## Perguntas em aberto

- [ ] Qual será o Work Item de referência para a primeira Iteration de Delivery validada? Um OBC existente, ou um novo criado especificamente para a validação?
- [ ] O Consumer de Derived State será implementado como script, Skills existentes, ou agente? Onde fica o código?
- [ ] Qual a granularidade de sincronização do GitHub COR — por evento, por fase, ou por ciclo?
- [ ] O Datadog receberá métricas via API direta, via evento de sistema OEM, ou via pipeline de coleta separado?
- [ ] Como Impediment.Resolved com Lookback será testado em condição real — será forçado ou aguardado oportunisticamente?

---

## Modo de execução

- [x] **Upstream** — há incerteza suficiente para explorar antes de comprometer
- [ ] Downstream

**Justificativa:** Esta é uma validação de hipóteses técnicas. Nenhuma das perguntas em aberto acima tem resposta documentada no Framework. Discovery é o modo correto — experimentos controlados com Timelines reais, observação de friction points, registro de evidências.

---

## Próximo passo

Criar experimento em `prodops/artifacts/experiments/` com escopo de validação do Runtime (Delivery + Diligence + GitHub COR + Datadog + OEM). O experimento definirá o Work Item de referência, o plano de coleta de evidências e os critérios de sucesso para cada componente.

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal de origem | [BS-RUNTIME-001](../business-signals/BS-RUNTIME-001.md) | Criado |
| Relatório de revisão | [documentation-review-runtime-business-signal-intent.md](../../documentation-review-runtime-business-signal-intent.md) | Criado |
| Experimento de validação | `prodops/artifacts/experiments/013-runtime-validation/` | Pendente — próximo passo |
