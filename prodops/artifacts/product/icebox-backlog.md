# Icebox - Payments

> **Propósito:** Itens comprometidos pelo Product Owner que ainda estão sendo preparados para Delivery. O Discovery necessário ocorre aqui — funcional, técnico ou operacional. O objetivo é produzir um Local OBC no estado Committed. Enquanto isso não acontece, o item permanece no Icebox.
>
> Itens que concluem o estado Committed avançam para o Iteration Backlog (pronto para desenvolver).
>
> → [Hierarquia de backlogs](../../framework/backlogs.md)

## 1. Governança do Icebox

| Campo | Conteúdo |
| --- | --- |
| Produto | Payments |
| Contexto | Gateway de pagamentos para ecommerce Magazine Siara, com foco inicial em compra por Pix e integração Asaas. |
| Dono de produto | `[Product Manager Payments]` |
| Dono técnico | `[Tech Lead Payments]` |
| Canal | `[Slack/Teams: #payments-prodops]` |
| Fonte principal | Features em `prodops/artifacts/bdd` |
| Última atualização | `2026-06-30` |

## 2. Como usar este backlog

1. Registrar oportunidades como problemas observáveis, não apenas soluções.
2. Classificar cada item por resultado esperado, risco, dependência e evidência.
3. Manter itens no icebox enquanto faltarem contexto, prioridade ou capacidade.
4. Promover para discovery quando houver pergunta crítica a responder.
5. Promover para delivery somente quando houver critérios de aceite, telemetria mínima, dependências conhecidas e owner definido.

## 3. Estados do item

| Estado | Significado | Critério de movimentação |
| --- | --- | --- |
| Icebox | Item comprometido pelo Product Owner (vindo do PIB), sendo refinado pelo Discovery para atingir o estado Committed. | OBC Draft em refinamento; falta completar Discovery funcional, técnico ou operacional. |
| Discovery | Item em investigação de produto, negócio, técnica, operação ou dados. | Existe pergunta clara, dono e prazo de aprendizado. |
| Ready for Delivery | Item pronto para planejamento de sprint/kanban. | Critérios de aceite, dependências, métricas e riscos estão claros. |
| Delivery | Item em implementação. | Time assumiu compromisso e iniciou execução. |
| Done | Entregue e observado em produção. | Critérios de aceite, logs, métricas, eventos e documentação operacional validados. |
| Dropped | Não será executado agora. | Decisão registrada com motivo e condição de revisita. |

## 4. Campos padrão por item

| Campo | Descrição |
| --- | --- |
| ID | Identificador estável do item no backlog. |
| Título | Nome curto, orientado ao resultado. |
| Tipo | Feature, melhoria, risco, experimento, dívida técnica, observabilidade ou operação. |
| Problema/oportunidade | Dor, risco ou oportunidade de negócio que justifica o item. |
| Usuário/cliente | Pessoa, sistema ou time impactado. |
| Outcome esperado | Mudança mensurável no comportamento, operação ou resultado. |
| Evidência atual | Dado, incidente, requisito, feature file, feedback ou hipótese. |
| Escopo MVP | Menor entrega útil e verificável. |
| Fora de escopo | Limites explícitos para evitar expansão silenciosa. |
| Dependências | Sistemas, times, contratos, dados ou decisões necessárias. |
| Riscos | Principais riscos de negócio, dados, tecnologia, segurança ou operação. |
| Telemetria mínima | Eventos, logs, métricas, traces e auditoria necessários. |
| Critérios de aceite | Condições objetivas para considerar o item pronto. |
| Score | Priorização por RICE/ICE/WSJF adaptada ao produto. |
| Status | Estado atual do item. |

## 5. Modelo de priorização

Use RICE como critério padrão e complemente com risco operacional quando a confiabilidade da jornada for parte central da decisão.

| Campo | Escala | Pergunta |
| --- | --- | --- |
| Reach | 1-5 | Quantos clientes, pedidos, times ou fluxos são impactados? |
| Impact | 1-5 | Quanto o item protege conversão, GMV, confiança, eficiência ou continuidade? |
| Confidence | 1-5 | Quanta evidência existe para sustentar a prioridade? |
| Effort | 1-5 | Qual o esforço relativo de engenharia, produto, dados e operação? |
| Operational Risk | 1-5 | Qual o risco de incidente, retrabalho, perda financeira ou divergência operacional se não fizer? |

Fórmula sugerida:

```text
Score = ((Reach * Impact * Confidence) + Operational Risk) / Effort
```

## 6. Backlog resumido

| ID | Título | Tipo | Outcome esperado | Status | Score inicial | Fonte |
| --- | --- | --- | --- | --- | --- | --- |
| PAY-ICE-001 | Criar invoice via gateway com contrato único | Feature | Ecommerce emite cobranças sem acoplamento direto ao provedor Asaas. | Delivery | 16.4 | [create-invoice.feature](../bdd/create-invoice.feature) |
| PAY-ICE-002 | Confirmar pagamento por webhook confiável | Feature | Pedido e ecommerce recebem confirmação uma única vez, com eventos auditáveis. | Delivery | 20.8 | [payment-confirmation.feature](../bdd/payment-confirmation.feature) |
| PAY-ICE-003 | Cancelar invoice pendente com idempotência | Feature | Cobranças abertas podem ser canceladas sem pagamento indevido ou evento duplicado. | Ready for Delivery | 13.7 | [cancel-invoice.feature](../bdd/cancel-invoice.feature) |

## 7. Itens detalhados

### PAY-ICE-001 - Criar invoice via gateway com contrato único

| Campo | Conteúdo |
| --- | --- |
| Tipo | Feature |
| Problema/oportunidade | O ecommerce precisa criar cobranças sem depender diretamente da API de um provedor específico, preservando a capacidade futura de troca ou fallback de gateway. |
| Usuário/cliente | Ecommerce Magazine Siara, Checkout, Payments, Operação. |
| Outcome esperado | Invoice criada com status rastreável, provedor registrado, identificador externo persistido e resposta padronizada ao ecommerce. |
| Evidência atual | Feature `Criar invoice no gateway de pagamentos`; necessidade de contrato único e idempotência por pedido. |
| Escopo MVP | Criar invoice no Asaas, criar/reutilizar cliente Asaas, validar provedor habilitado, garantir idempotência e tratar falhas transientes/validação. |
| Fora de escopo | Múltiplo provedor ativo em fallback automático, split de pagamento, estorno, conciliação financeira completa. |
| Dependências | Credenciais Asaas, cadastro de provedores por tenant, modelo de customer binding, storage de idempotência, contrato de resposta ao ecommerce. |
| Riscos | Duplicidade de cobrança, cliente Asaas duplicado, invoice aberta sem `providerPaymentId`, exposição de payload sensível em erro. |
| Telemetria mínima | Evento de invoice criada, tentativa de chamada ao provedor, provider latency, provider error code, idempotency hit/miss, audit log de rejeição. |
| Critérios de aceite | Cenários do arquivo [create-invoice.feature](../bdd/create-invoice.feature) passam; retry com mesma chave não chama o provedor; falha 5xx não retorna invoice `OPEN` sem `providerPaymentId`; erro de validação é auditável sem segredo. |
| Score | Reach 4, Impact 5, Confidence 4, Effort 5, Operational Risk 2 = 16.4 |
| Status | Delivery — OBC committed em `prodops/artifacts/obcs/create-invoice.md`. Entrou no Iteration Plan. |

**Perguntas de discovery**

- Qual é o contrato canônico de invoice que deve permanecer estável entre provedores?
- Como identificar cliente reutilizável com segurança: documento, `externalReference` ou binding interno?
- Quais erros do Asaas viram erro de negócio, erro técnico ou retry seguro?

### PAY-ICE-002 - Confirmar pagamento por webhook confiável

| Campo | Conteúdo |
| --- | --- |
| Tipo | Feature |
| Problema/oportunidade | Pagamento confirmado precisa liberar pedido uma única vez, mesmo com webhook duplicado, atrasado ou recebido antes da consolidação interna da invoice. |
| Usuário/cliente | Ecommerce Magazine Siara, Order Management, Payments, Financeiro, Atendimento. |
| Outcome esperado | Evento canônico `payment.confirmed` publicado uma única vez por pagamento confirmado, com invoice atualizada e evento bruto auditável. |
| Evidência atual | Feature `Confirmação de pagamento por webhook`; necessidade de confirmação confiável, conciliação e proteção contra duplicidade. |
| Escopo MVP | Validar token Asaas, persistir evento bruto, processar `PAYMENT_CONFIRMED`, processar `PAYMENT_RECEIVED`, deduplicar eventos, correlacionar por `providerPaymentId` ou `externalReference`. |
| Fora de escopo | Painel financeiro completo, contestação, chargeback, regras avançadas de reconciliação multi-provedor. |
| Dependências | Endpoint público de webhook, segredo/token Asaas, armazenamento de eventos brutos, publicação de eventos canônicos, contrato com ecommerce/Orders. |
| Riscos | Pedido liberado duas vezes, pagamento recebido sem pedido liberado, token vazado em logs, evento não correlacionado, divergência entre `CONFIRMED` e `RECEIVED`. |
| Telemetria mínima | Webhook received, webhook rejected, event deduplication, invoice status transition, canonical event published, lag entre recebimento e publicação. |
| Critérios de aceite | Cenários do arquivo [payment-confirmation.feature](../bdd/payment-confirmation.feature) passam; webhook inválido não altera invoice; evento duplicado retorna sucesso técnico sem republicar; `PAYMENT_RECEIVED` não libera pedido pela segunda vez. |
| Score | Reach 5, Impact 5, Confidence 4, Effort 5, Operational Risk 4 = 20.8 |
| Status | Delivery — OBC committed em `prodops/artifacts/obcs/payment-confirmation.md`. Entrou no Iteration Plan. |

**Perguntas de discovery**

- Qual evento canônico deve liberar pedido: `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED` ou ambos com regras diferentes?
- Qual é o SLA aceitável entre webhook recebido e evento entregue ao ecommerce?
- Como operar eventos não correlacionados ou recebidos fora de ordem?

### PAY-ICE-003 - Cancelar invoice pendente com idempotência

| Campo | Conteúdo |
| --- | --- |
| Tipo | Feature |
| Problema/oportunidade | O ecommerce precisa cancelar cobranças pendentes para impedir pagamento indevido, mantendo idempotência e decisão clara quando o provedor divergir. |
| Usuário/cliente | Ecommerce Magazine Siara, Checkout, Payments, Atendimento, Operação. |
| Outcome esperado | Invoice aberta pode ser cancelada com segurança, sem chamada duplicada ao provedor e sem evento canônico incorreto. |
| Evidência atual | Feature `Cancelar invoice no gateway de pagamentos`; necessidade de cancelamento de cobranças ainda ativas. |
| Escopo MVP | Cancelar invoice `OPEN` no Asaas, registrar `CANCEL_REQUESTED`, confirmar `CANCELLED`, publicar `payment.cancelled`, impedir cancelamento após `CONFIRMED`, tratar 404 de provedor. |
| Fora de escopo | Estorno após pagamento confirmado, disputa financeira, cancelamento parcial, políticas avançadas de conciliação. |
| Dependências | Política de estados da invoice, endpoint Asaas `DELETE /v3/payments/{id}`, idempotência de cancelamento, evento `payment.cancelled`, política para 404. |
| Riscos | Cobrança permanecer pagável após cancelamento local, publicação de cancelamento sem confirmação do provedor, cancelamento indevido após pagamento, duplicidade de evento. |
| Telemetria mínima | Cancel request, provider delete latency/error, status transition, idempotency hit/miss, webhook `PAYMENT_DELETED`, canonical cancellation published. |
| Critérios de aceite | Cenários do arquivo [cancel-invoice.feature](../bdd/cancel-invoice.feature) passam; invoice `CONFIRMED` não é cancelada; retry com mesma chave não chama o provedor; 404 não publica `payment.cancelled` sem decisão explícita. |
| Score | Reach 3, Impact 4, Confidence 4, Effort 4, Operational Risk 2 = 13.7 |
| Status | Ready for Delivery — OBC committed em `prodops/artifacts/obcs/cancel-invoice.md`. Adiado para próxima iteração. |

**Perguntas de discovery**

- O evento `payment.cancelled` deve ser publicado no comando de cancelamento ou apenas após webhook `PAYMENT_DELETED`?
- Qual política operacional deve ser aplicada quando o Asaas retorna 404?
- Quais status permitem cancelamento e quais exigem fluxo de estorno?

## 8. Definition of Ready

Um item só deve sair do icebox para delivery quando atender aos critérios abaixo.

| Critério | Evidência esperada |
| --- | --- |
| Problema claro | Dor, oportunidade ou risco escrito em linguagem de negócio e operação. |
| Outcome mensurável | Métrica, evento ou comportamento esperado definido. |
| Usuário/cliente conhecido | Sistemas, pessoas ou times impactados identificados. |
| Escopo MVP delimitado | Inclusões e exclusões documentadas. |
| Contrato definido | API, evento, payload ou comportamento externo versionável. |
| Estados e erros mapeados | Transições principais, falhas esperadas e regras de retry/idempotência claras. |
| Observabilidade planejada | Logs, métricas, traces, auditoria e alertas mínimos definidos. |
| Dependências conhecidas | Times, credenciais, tópicos, filas, tabelas e provedores mapeados. |
| Critérios de aceite | Cenários testáveis e rastreáveis a feature file ou especificação. |
| Owner definido | Responsável de produto e técnico nomeados. |

## 9. Definition of Done operacional

| Dimensão | Critério |
| --- | --- |
| Produto | Outcome inicial validado ou plano de medição ativo. |
| Engenharia | Testes automatizados relevantes passando, contrato versionado e deploy rastreável. |
| Confiabilidade | Logs, métricas, traces e alertas mínimos em funcionamento. |
| Operação | Runbook ou procedimento de suporte atualizado para falhas conhecidas. |
| Dados | Eventos canônicos e auditoria persistidos quando aplicável. |
| Segurança | Segredos, tokens e payloads sensíveis protegidos em logs, erros e auditoria. |
| Aprendizado | Decisões, limites e trade-offs registrados no artefato correspondente. |

## 10. Decisões pendentes

| ID | Decisão | Impacto | Dono | Status |
| --- | --- | --- | --- | --- |
| DEC-001 | Definir contrato canônico de invoice entre ecommerce e Payments API. | Bloqueia estabilidade de API e testes de contrato. | Tech Lead Payments | Aberto |
| DEC-002 | Definir política de publicação para `payment.confirmed`, `payment.received` e `payment.cancelled`. | Afeta Orders, ecommerce e conciliação. | PM Payments + Tech Lead Payments | Aberto |
| DEC-003 | Definir política para erros 404, 409, 422, 5xx e timeout do Asaas. | Afeta retry, suporte e estado final da invoice. | Engenharia Payments | Aberto |
| DEC-004 | Definir retenção e mascaramento de eventos brutos de webhook. | Afeta auditoria, segurança e LGPD. | Segurança + Payments | Aberto |
| DEC-005 | Definir SLO inicial de confirmação de pagamento. | Afeta dashboards, alertas e readiness operacional. | SRE + Payments | Aberto |

## 11. Próximas ações recomendadas

| Ação | Dono sugerido | Saída esperada |
| --- | --- | --- |
| Revisar scores com PM, Tech Lead e SRE. | PM Payments | Priorização inicial validada. |
| Transformar PAY-ICE-002 em discovery técnico-operacional. | Tech Lead Payments | Decisão sobre eventos, idempotência e correlação. |
| Especificar contrato canônico de invoice. | Engenharia Payments | OpenAPI ou contrato interno versionado. |
| Definir eventos canônicos e tópicos de publicação. | Payments + Orders | Contrato de integração entre Payments e ecommerce/Orders. |
| Criar matriz de estados da invoice. | Engenharia Payments | Estados permitidos, transições e regras de erro. |
