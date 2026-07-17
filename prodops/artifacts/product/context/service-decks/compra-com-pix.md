# Service Deck - Compra com Pix

> Template aplicado a Value Stream Compra com Pix do produto Payments. Use como base para detalhar Service Blueprint, eventos, contratos observáveis, riscos e acionamentos.

## 1. Identificação

| Campo | Conteúdo |
| --- | --- |
| Nome da Value Stream | Compra com Pix |
| Produto principal | Payments |
| Produtos relacionados | Checkout, Order Management, Notification Service, Atendimento, Financeiro/Conciliação |
| Resultado esperado | Cliente seleciona Pix, recebe QR Code/copia e cola, realiza pagamento, tem pagamento confirmado e pedido liberado. |
| Criticidade | Crítica |
| Dono de produto | `[PM Payments]` |
| Dono técnico | `[Tech Lead Payments]` |
| Última atualização | `[YYYY-MM-DD]` |

## 2. Delimitação da jornada

| Item | Descrição |
| --- | --- |
| Início | Cliente seleciona Pix como meio de pagamento no checkout. |
| Fim | Pedido é liberado no Order Management e cliente recebe confirmação. |
| Cliente/usuário | Cliente comprador no ecommerce. |
| Sucesso esperado | QR Code gerado, pagamento identificado, confirmação publicada, pedido liberado e cliente notificado. |
| Falha relevante | Cliente paga, mas pedido não avança; QR Code não é gerado; Pix expira sem clareza; status fica inconsistente. |
| Janela crítica | Black Friday, campanhas de alto tráfego, horário de pico e releases de Payments/Checkout. |

## 3. Service Blueprint

| Camada | Elementos |
| --- | --- |
| Pontos de contato | Checkout Web/App, tela de pagamento Pix, QR Code, copia e cola, tela de confirmação, email/push/WhatsApp. |
| Ações do cliente | Seleciona Pix, confirma compra, copia/escaneia QR Code, paga no banco, aguarda confirmação. |
| Ações de negócio | Criar intenção de pagamento, reservar pedido, gerar QR Code, aguardar liquidação, confirmar pagamento, liberar pedido. |
| Eventos de domínio | `PagamentoIniciado`, `PixQRCodeGerado`, `PixPago`, `PagamentoConfirmado`, `PedidoLiberado`, `PagamentoExpirado`, `PagamentoFalhou`. |
| Sistemas e dependências | Checkout, Payments API, Pix Provider, Payments DB, Message Broker, Order Management, Notification Service, Observability Stack. |
| Times e acionamentos | Payments, Checkout, Orders, Plataforma/SRE, Atendimento, Financeiro. |

## 4. Fluxo principal

1. Cliente escolhe Pix no checkout.
2. Checkout cria solicitação em Payments.
3. Payments cria intenção de pagamento.
4. Payments solicita QR Code ao Pix Provider.
5. Pix Provider retorna QR Code e expiração.
6. Checkout exibe QR Code/copia e cola.
7. Cliente realiza pagamento no banco.
8. Pix Provider envia confirmação ou Payments consulta status.
9. Payments publica `PagamentoConfirmado`.
10. Order Management consome evento e libera pedido.
11. Notification Service informa cliente.

## 5. Event Storming

| Evento | Causa | Resultado | Sistema produtor | Observabilidade |
| --- | --- | --- | --- | --- |
| `PagamentoIniciado` | Cliente seleciona Pix e confirma compra. | Intenção de pagamento criada. | Checkout/Payments | correlationId, orderId, paymentId, amount, method=Pix |
| `PixQRCodeGerado` | Payments recebe QR Code do provider. | Cliente pode pagar. | Payments | provider, expiration, latency, status |
| `PixQRCodeFalhou` | Provider retorna erro/timeout. | Cliente não recebe QR Code. | Payments | errorCode, provider, retryable, traceId |
| `PixPago` | Provider informa pagamento realizado. | Payments pode confirmar pagamento. | Pix Provider/Payments | providerEventId, paymentId, paidAt |
| `PagamentoConfirmado` | Payments valida Pix pago. | Orders pode liberar pedido. | Payments | paymentId, orderId, amount, confirmedAt |
| `PedidoLiberado` | Orders processa confirmação. | Pedido segue para fulfillment. | Order Management | orderId, paymentId, releasedAt |
| `PagamentoExpirado` | QR Code expira sem pagamento. | Cliente precisa nova tentativa. | Payments | expiration, paymentId, orderId |
| `PagamentoFalhou` | Falha inesperada no fluxo. | Jornada entra em erro tratado. | Payments | dependency, errorCode, traceId |

## 6. Observable Business Contract

| Evento | SLI | SLO/limite inicial | Impacto | Resposta | Dono |
| --- | --- | --- | --- | --- | --- |
| `PixQRCodeGerado` | Percentual de QR Codes gerados com sucesso. | 99.5% em até 3s | Cliente não consegue pagar com Pix. | Verificar Pix Provider, Payments API e timeout. | Payments |
| `PixPago` | Percentual de pagamentos Pix recebidos pelo Payments após liquidação. | 99% em até 10s após notificação provider | Cliente paga e fica sem retorno. | Verificar webhook/consulta provider e fila. | Payments + Financeiro |
| `PagamentoConfirmado` | Percentual de Pix pagos que geram confirmação. | 99% em até 30s | Pedido fica parado. | Acionar Payments; verificar consistência Payments DB. | Payments |
| `PedidoLiberado` | Percentual de pagamentos confirmados refletidos em Orders. | 99% em até 30s | Cliente pagou, mas pedido não avançou. | Acionar Orders + Payments; verificar broker/consumer. | Orders + Payments |
| `PagamentoExpirado` | Percentual de expirações comunicadas corretamente. | 99% com resposta clara ao cliente | Cliente tenta pagar Pix vencido. | Verificar expiração e comunicação Checkout. | Payments + Checkout |

## 7. Matriz de confiabilidade

| Nó/aresta | Falha possível | Impacto | Sinal | Acionamento | Runbook |
| --- | --- | --- | --- | --- | --- |
| Checkout -> Payments | Erro ao criar pagamento Pix | Cliente não inicia pagamento. | 5xx/4xx inesperado em `POST /payments/pix`. | Checkout + Payments | `[link]` |
| Payments -> Pix Provider | Timeout ao gerar QR Code | QR Code não exibido. | Latência p95/p99 e taxa de timeout. | Payments + SRE | `[link]` |
| Pix Provider -> Payments | Webhook não recebido | Pix pago sem confirmação. | `PixPago` ausente após provider confirmar. | Payments + Financeiro | `[link]` |
| Payments DB | Estado inconsistente | Status divergente. | paymentId em estado inválido/estagnado. | Payments | `[link]` |
| Payments -> Broker | Evento não publicado | Orders não libera pedido. | `PagamentoConfirmado` sem publish/ack. | Payments + Plataforma | `[link]` |
| Broker -> Orders | Consumer parado ou com erro | Pedido não avança. | Lag/erro no consumer Orders. | Orders + Plataforma | `[link]` |
| Orders -> Notification | Confirmação não notificada | Cliente sem retorno. | `PedidoLiberado` sem notificação. | Orders + Comunicação | `[link]` |

## 8. Indicadores e dashboards

| Indicador | Pergunta que responde | Fonte | Dashboard |
| --- | --- | --- | --- |
| Taxa de QR Code Pix gerado | Cliente consegue iniciar Pix? | Payments/Pix Provider | `[link]` |
| Latência para gerar QR Code | O Pix está rápido? | Traces/APM | `[link]` |
| Pix pago sem confirmação | Existe quebra entre provider e Payments? | Eventos/consistência | `[link]` |
| Pagamento confirmado sem pedido liberado | Existe quebra entre Payments e Orders? | Eventos/Broker | `[link]` |
| Expirações de Pix | Clientes estão perdendo a janela de pagamento? | Payments | `[link]` |
| Erros por provider | A dependência Pix está degradada? | Metrics/APM | `[link]` |
| Chamados sobre Pix | Cliente está percebendo falha? | Atendimento | `[link]` |

## 9. Riscos

| Risco | Dimensão | Probabilidade | Impacto | Ação |
| --- | --- | --- | --- | --- |
| Provider Pix instável em pico. | Tecnologia/Peças | Média | Alto | Timeout, retry controlado, fallback operacional e alerta acionável. |
| Cliente paga, mas pedido não libera. | Cliente/Fluxos | Média | Alto | Contrato `PagamentoConfirmado -> PedidoLiberado` com SLO e reconciliação. |
| Status divergente entre Payments, Provider e Orders. | Dados | Alta | Alto | Job/consulta de reconciliação e dashboard de divergências. |
| QR Code expira sem mensagem clara. | Cliente | Média | Médio | Contrato de expiração e UX de nova tentativa. |
| Alertas sem contexto de orderId/paymentId. | Time/Dados | Alta | Alto | Logs estruturados com correlationId, paymentId e orderId. |

## 10. Testes e validações

| Cenário | Tipo | Resultado esperado |
| --- | --- | --- |
| Criar Pix com payload válido | Starter/One Step | HTTP 201, paymentId e QR Code retornados. |
| Criar Pix com contrato inválido | Explanation/Contract | HTTP 400 com erro de contrato claro. |
| Pix Provider indisponível | Crash Test Dummy | Erro tratado, alerta, log e sem estado inconsistente. |
| Pix pago e confirmado | End-to-end | `PixPago`, `PagamentoConfirmado`, `PedidoLiberado`. |
| Pix pago sem evento de Orders | Regression | Alerta de confirmação sem pedido. |
| QR Code expirado | Boundary | Evento `PagamentoExpirado` e resposta clara ao cliente. |

## 11. Runbooks

| Runbook | Quando usar | Link |
| --- | --- | --- |
| Pix QR Code não gerado | Aumento de erro/timeout na geração. | `[link]` |
| Pix pago sem confirmação | Cliente pagou, mas Payments não confirmou. | `[link]` |
| Pagamento confirmado sem pedido | Orders não liberou pedido após confirmação. | `[link]` |
| Divergência de status Pix | Provider, Payments e Orders divergem. | `[link]` |

## 12. Links

| Tipo | Link |
| --- | --- |
| Product Deck Payments | `prodops/artifacts/product/context/product-deck.md` |
| OpenAPI Payments Pix | `[link]` |
| Dashboard Pix | `[link]` |
| Tópicos/eventos | `[link]` |
| Alertas | `[link]` |
| Runbooks | `[link]` |
| Backlog | `[link]` |

## 13. Critérios de pronto

- Service Blueprint revisado com Payments, Checkout, Orders e SRE.
- Eventos principais definidos e publicados no catálogo.
- Observable Business Contract inicial aprovado.
- Dashboard Pix com sucesso, erro, latência e divergência.
- Alerta para Pix pago sem confirmação.
- Runbook mínimo para os cenários críticos.
- Backlog com ações de confiabilidade priorizadas.
