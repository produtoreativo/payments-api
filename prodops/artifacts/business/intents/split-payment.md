# Business Intent — Suporte a Múltiplos Pagamentos no Checkout

## Identificação

Campo	Conteúdo
Título	Suporte a Múltiplos Pagamentos no Checkout
Data de registro	2026-07-07
Solicitante	Product Team
Dono de produto	

⸻

## Intenção

Queremos que compradores consigam concluir um pedido utilizando mais de um meio de pagamento quando um único método não atender sua necessidade, aumentando a taxa de conversão e reduzindo o abandono do checkout.

⸻

## Contexto

O modelo atual pressupõe que um pedido é pago utilizando apenas um meio de pagamento. Esse modelo limita cenários comuns de negócio, como combinar diferentes formas de pagamento para concluir uma compra.

Além da limitação funcional, a evolução do ecossistema de pagamentos indica a necessidade de suportar novas estratégias de composição entre métodos de pagamento sem aumentar a complexidade da experiência do usuário.

Esta intenção busca avaliar como tornar o checkout flexível para múltiplos pagamentos preservando simplicidade operacional, escalabilidade e compatibilidade com futuras formas de pagamento.

⸻

## Hipóteses de negócio

- [ ] Alguns clientes abandonam a compra por não conseguirem utilizar mais de um meio de pagamento.
- [ ] Permitir múltiplos pagamentos aumentará a taxa de conversão do checkout.
- [ ] A experiência pode permanecer simples mesmo suportando diferentes composições de pagamento.
- [ ] O modelo pode ser estendido para novos meios de pagamento sem necessidade de grandes mudanças arquiteturais.
- [ ] A flexibilidade de pagamento será mais valiosa para pedidos de maior valor.



## Perguntas em aberto

- [x] * Quais cenários de negócio justificam o uso de múltiplos pagamentos? → Pix + Cartão (limite insuficiente); gift card/cashback + método principal
- [x] * Quais combinações de meios de pagamento devem ser suportadas inicialmente? → Pix + Cartão (P0 MVP); Cartão + Cartão (P1 pós-MVP); Boleto como método parcial fora do MVP
- [x] * Existe um limite máximo de pagamentos por pedido? → 2 métodos no MVP
- [x] * Como representar o saldo restante durante a composição dos pagamentos? → `remainingAmount` derivado; `confirmedAmount` persistido em `PaymentComposition`
- [x] * Como deve funcionar a alteração ou remoção de um pagamento antes da confirmação? → Cancelamento da invoice no Asaas se `OPEN`; nova invoice para o método substituto
- [ ] ⚠ * Como tratar falhas parciais quando apenas um dos pagamentos é autorizado? → **Pendente decisão de produto** — Política B recomendada (manter confirmados, nova tentativa)
- [x] * Como conciliar confirmações assíncronas provenientes de diferentes gateways? → Agregação na `PaymentCompositionService` com `allInvoicesConfirmed()` no processamento de webhook
- [x] * Como preservar uma experiência simples para o usuário durante todo o fluxo? → `compositionId` como referência principal; estado agregado via `GET /v1/payment-compositions/:id`
- [x] * Quais impactos essa mudança traz ao modelo atual de Order e Payment? → Mudança aditiva: `compositionId?` e `allocatedAmount?` em `InvoiceRecord`; nova entidade `PaymentComposition`
- [x] * Quais eventos de negócio deverão existir para suportar observabilidade e auditoria? → 7 novos eventos: `ComposicaoDePagamentoCriada`, `PagamentoParcialConfirmado`, `PagamentoCompostoConfirmado`, `PagamentoParcialFalhou`, `PagamentoCompostoFalhou`, `PagamentoCompostoExpirou`, `ComposicaoCancelada`

⸻

## Modo de execução sugerido

- [x] * Upstream — há incerteza suficiente para explorar antes de comprometer
- [ ] * Downstream — há clareza suficiente; OBC e BDD podem ser escritos agora

### Justificativa:

Embora a necessidade de negócio seja clara, ainda existem decisões importantes relacionadas ao modelo de domínio, experiência do usuário, arquitetura, eventos de negócio, integrações com gateways de pagamento e estratégia de observabilidade. Essas incertezas justificam uma etapa de exploração antes da implementação.

⸻

## Próximo passo

Executar uma atividade no modo Upstream (exploratório) para:

* pesquisar benchmarks de mercado para checkouts com múltiplos pagamentos;
* identificar padrões consolidados de UX;
* modelar alternativas de domínio;
* realizar Event Storming do novo fluxo;
* elaborar um OBC candidato;
* avaliar impactos na arquitetura existente;
* decidir o modelo que seguirá para implementação.

⸻

## Artefatos gerados

| Artefato | Localização |
|---|---|
| Experimento EXP-007 (análise completa) | `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md` |
| Trail do experimento | `prodops/journeys/discovery/experiments/007-split-payment-model/upstream-trail.md` |
| OBC candidato (draft) | `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md` |
| BDD Feature | `prodops/artifacts/business/bdd/payment-composition.feature` — **a criar após decisão de política** |