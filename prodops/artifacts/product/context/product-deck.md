# Product Deck - Payments

> Template aplicado ao produto Payments citado no material do curso ProdOps, no contexto Magazine Siara. Use como ponto de partida e ajuste nomes de times, sistemas, links e indicadores reais.

## 1. Identificação

| Campo | Conteúdo |
| --- | --- |
| Nome do produto | Payments |
| Descrição curta | Produto responsável por habilitar, autorizar, confirmar e observar pagamentos nas jornadas de compra do ecommerce. |
| Contexto de negócio | Magazine Siara, ecommerce com alto volume, dependência de checkout, Pix, gateway de pagamento, antifraude, pedido e notificação. |
| Dono de produto | `[Product Manager Payments]` |
| Dono técnico | `[Tech Lead Payments]` |
| Times principais | Payments, Checkout, Order Management, Antifraude, Plataforma/SRE, Atendimento, Operação. |
| Canal principal | `[Slack/Teams: #payments-prodops]` |
| Última atualização | `2026-07-12` |

## 2. Product Vision

Para clientes que compram no ecommerce da Magazine Siara, o produto Payments deve permitir pagamentos confiáveis, rápidos, rastreáveis e intercambiáveis, garantindo que cada tentativa de pagamento tenha resposta clara, confirmação observável e continuidade operacional mesmo diante de falhas em gateways, Pix, antifraude ou integrações externas.

Payments existe para proteger conversão, GMV, confiança do cliente e capacidade operacional do checkout. O produto deve reduzir entropia na jornada de pagamento, permitir diagnóstico rápido e sustentar mudanças como migração de meios de pagamento, novo gateway, fallback e novas modalidades comerciais.

### Payments como System of Record

Payments é a fonte interna, auditável e reconciliável para invoices, cobranças e transições de pagamento associadas aos pedidos. Provedores como Asaas são PSPs externos: executam cobranças e enviam eventos, mas não governam a verdade operacional da Magazine Siara.

Payments mantém os identificadores internos, a associação com pedido, tenant e cliente, o provedor selecionado, os identificadores externos, a idempotência e o histórico de transições. Estados e eventos externos devem ser traduzidos para o modelo canônico sem perder os dados necessários para auditoria e conciliação.

A fronteira técnica e o estado atualmente implementado estão documentados no [Architecture Overview](../architecture/overview.md). A adoção desta visão não aprova automaticamente estados, eventos ou comportamentos ainda ausentes dos OBCs e BDD Features committed.

## 3. Problemas e oportunidades

| Item | Descrição | Dimensão |
| --- | --- | --- |
| Novo gateway de pagamento | Migrar ou integrar novo gateway sem quebrar checkout, pedidos e conciliação. | Empresa, Tecnologia |
| Compra de 1 item por Pix | Criar confiabilidade para uma jornada crítica e simples o suficiente para mapear ponta a ponta. | Cliente, Tecnologia |
| Problema no checkout | GMV pode cair mesmo com aumento de campanhas se pagamento/checkout degradar. | Cliente, Empresa |
| Baixa rastreabilidade | Falhas em pagamento precisam ser explicadas por evento de domínio, não apenas por status técnico. | Dados, Fluxos |
| Intercambiabilidade | Gateway deve ser substituível via fallback, contratos claros e observabilidade preservada. | Tecnologia, Time |
| Alertas ruins | Alertas genéricos ou sem contexto aumentam MTTR e fadiga operacional. | Dados, Time |

## 4. Services

| Serviço / Jornada | Cliente/Usuário | Resultado esperado | Criticidade | Service Deck | Status — v0.0.1 |
| --- | --- | --- | --- | --- | --- |
| Compra com Pix | Cliente comprador | Pix gerado, pago, confirmado e pedido liberado. | Crítica | [compra-com-pix.md](service-decks/compra-com-pix.md) | Em desenvolvimento |
| Compra com Boleto | Cliente comprador | Boleto gerado com linha digitável e link PDF, confirmado pelo webhook do provedor. | Alta | — | Em desenvolvimento |
| Compra com Cartão de Crédito | Cliente comprador | Cartão autorizado via fluxo hospedado, confirmado e pedido liberado. | Alta | — | Planejado |
| Confirmação de pagamento | Checkout, Order Management | Pagamento confirmado via webhook; pedido avança no fluxo sem intervenção manual. | Crítica | — | Em desenvolvimento |
| Notificação de resultado ao cliente | Cliente, sistemas integradores | Cliente e sistemas recebem atualização de status via webhook com assinatura verificável. | Alta | — | Em desenvolvimento (MVP) |
| Cancelamento de invoice pendente | Operação, cliente | Cobrança inativa eliminada; nenhum valor processado após cancelamento. | Alta | — | Implementado — adiado para pós v0.0.1 |
| Autenticação via API Token | Sistemas integradores | Somente sistemas autorizados acessam a API; acesso rastreável por tenant e token. | Crítica | — | Em desenvolvimento |
| Configuração de webhook | Sistemas integradores | Consumidor registra endpoint e recebe eventos de pagamento sem polling. | Alta | — | Em desenvolvimento |
| Consulta de status de pagamento | Atendimento, cliente, operação | Status atual consistente entre Payments, provedor e Order Management. | Alta | — | Planejado |
| Fallback de gateway | Checkout, operação | Gateway alternativo assume falhas do primário sem perda de rastreabilidade. | Alta | — | Não previsto — v0.0.1 |
| Conciliação de pagamento | Financeiro, operação | Pagamentos conciliados com pedidos e transações do provedor. | Alta | — | Não previsto — v0.0.1 |

## 5. Time do produto

| Papel | Nome/time | Responsabilidade | Canal |
| --- | --- | --- | --- |
| Product Manager | `[PM Payments]` | Priorizar jornadas, risco, resultado e roadmap de Payments. | `[link]` |
| Tech Lead | `[Tech Lead Payments]` | Arquitetura, contratos, confiabilidade e decisão técnica. | `[link]` |
| Engenharia Payments | `[Squad Payments]` | APIs, eventos, integrações, logs, métricas e testes. | `[link]` |
| Checkout | `[Squad Checkout]` | Experiência de pagamento no fluxo de compra. | `[link]` |
| Order Management | `[Squad Orders]` | Criação/liberação de pedidos após confirmação. | `[link]` |
| Antifraude | `[Squad Antifraude]` | Análise de risco e bloqueios. | `[link]` |
| Plataforma/SRE | `[SRE/Platform]` | Observabilidade, incidentes, SLO, dashboards e runbooks. | `[link]` |
| Atendimento | `[CX/Atendimento]` | Tratativa de clientes impactados e feedback operacional. | `[link]` |
| Financeiro/Conciliação | `[Finance Ops]` | Conciliação, chargeback e divergências financeiras. | `[link]` |

## 6. Arquitetura do produto

> Diagrama de componentes: [`prodops/artifacts/product/architecture/overview.md`](../architecture/overview.md)
>
> O diagrama é a fonte canônica da estrutura do sistema. Atualizar sempre que
> houver mudança estrutural (novo módulo, rota, dependência externa, tabela ou
> tópico de evento). Ver regra completa em `AGENTS.md`.

| Peça | Tipo | Dono | Criticidade | Observação |
| --- | --- | --- | --- | --- |
| Checkout Web/App | Frontend/BFF | Checkout | Crítica | Inicia tentativa de pagamento e apresenta resposta ao cliente. |
| Payments API | API | Payments | Crítica | Orquestra meios de pagamento, contratos e status. |
| Pix Provider | Integração externa | Payments/Financeiro | Crítica | Gera QR Code, recebe confirmação e consulta status. |
| Gateway Primário | Integração externa | Payments | Crítica | Autorização/cartão/outros meios. |
| Gateway Fallback | Integração externa | Payments | Alta | Deve assumir falhas do gateway primário com contrato claro. |
| Antifraude API | API/integração | Antifraude | Alta | Pode aprovar, negar ou colocar transação em análise. |
| Order Management | API/event consumer | Orders | Crítica | Libera pedido após pagamento confirmado. |
| Message Broker | Fila/eventos | Plataforma | Crítica | Distribui eventos de pagamento e pedido. |
| Payments DB | Banco | Payments | Crítica | Estado transacional de pagamentos. |
| Observability Stack | Logs/metrics/traces | Plataforma/SRE | Crítica | Dashboards, alertas, traces e correlation id. |
| Notification Service | API/event consumer | Comunicação | Média | Notifica cliente sobre resultado. |

## 7. Matriz de confiabilidade

| Jornada | Peça/dependência | Falha possível | Impacto | Sinal | Acionamento |
| --- | --- | --- | --- | --- | --- |
| Compra com Pix | Pix Provider | QR Code não gerado | Cliente não conclui compra; queda de conversão. | Taxa de erro em `PixQRCodeGerado`; erro 5xx/timeout. | Payments + Plataforma |
| Compra com Pix | Pix Provider | Pagamento realizado, mas não confirmado | Pedido fica parado; abertura de chamados. | Evento `PixPago` sem `PagamentoConfirmado` em até N minutos. | Payments + Orders |
| Autorização | Gateway Primário | Timeout ou indisponibilidade | Checkout degrada; GMV impactado. | Aumento de latência/timeout por gateway. | Payments + SRE |
| Autorização | Gateway Fallback | Fallback não acionado | Falha deixa de ser intercambiável. | Falha primária sem evento `GatewayFallbackAcionado`. | Payments |
| Antifraude | Antifraude API | Análise indisponível | Pagamentos bloqueados ou risco aumentado. | Erro/timeout em decisão antifraude. | Antifraude + Payments |
| Confirmação | Message Broker | Evento não publicado | Orders não libera pedido. | Ausência de `PagamentoConfirmado` no tópico esperado. | Plataforma + Payments |
| Confirmação | Order Management | Pedido não atualizado | Cliente paga e pedido não avança. | `PagamentoConfirmado` sem `PedidoLiberado`. | Orders + Payments |
| Atendimento | Consulta Status | Status inconsistente | Suporte sem resposta confiável. | Divergência Payments DB x Gateway x Orders. | Payments + Atendimento |

## 8. Product Analytics

| Indicador | Tipo | Pergunta que responde | Fonte | Cadência |
| --- | --- | --- | --- | --- |
| Taxa de autorização por meio de pagamento | Cliente/Empresa | Clientes conseguem pagar? | Payments/Gateway | Tempo real + diária |
| Conversão do checkout após seleção de pagamento | Cliente/Empresa | Pagamento está impactando GMV? | Analytics/Checkout | Tempo real + diária |
| Latência p95/p99 de autorização | Tecnologia | O fluxo está rápido o suficiente? | Traces/APM | Tempo real |
| Taxa de erro por gateway | Tecnologia | Qual dependência está degradando? | Metrics/APM | Tempo real |
| Percentual de fallback acionado | Tecnologia/Empresa | Intercambiabilidade está funcionando? | Payments events | Tempo real + semanal |
| Pagamentos confirmados sem pedido liberado | Fluxo/Dados | Existe quebra entre Payments e Orders? | Eventos/consistência | Tempo real |
| Pix pago sem confirmação no prazo | Cliente/Tecnologia | Cliente pagou e ficou sem retorno? | Eventos Pix/Payments | Tempo real |
| MTTR de incidentes Payments | Time/Tecnologia | O time recupera a jornada rápido? | Incident tool | Mensal |
| Alertas acionáveis vs alertas ruidosos | Time/Dados | Observabilidade está gerando ação ou ruído? | Alert manager | Quinzenal |

## 9. Eventos de domínio

| Evento | Descrição | Produtor | Consumidores | Observabilidade mínima |
| --- | --- | --- | --- | --- |
| `PagamentoIniciado` | Cliente escolheu meio de pagamento e iniciou tentativa. | Checkout/Payments | Payments, Analytics | correlationId, paymentId, orderId, method |
| `PixQRCodeGerado` | QR Code Pix foi criado com sucesso. | Payments | Checkout, Analytics | provider, expiration, latency |
| `PagamentoAutorizado` | Gateway autorizou pagamento. | Payments | Orders, Analytics, Notifications | gateway, amount, method, latency |
| `PagamentoRecusado` | Pagamento foi recusado com motivo conhecido. | Payments | Checkout, Analytics, Atendimento | reasonCode, gateway, method |
| `PagamentoConfirmado` | Pagamento foi confirmado e pode liberar pedido. | Payments | Orders, Notifications, Analytics | paymentId, orderId, amount, confirmedAt |
| `PagamentoExpirado` | Janela de pagamento expirou. | Payments | Checkout, Orders, Atendimento | method, expiration, orderId |
| `GatewayFallbackAcionado` | Fluxo usou gateway alternativo. | Payments | SRE, Analytics | gatewayOrigem, gatewayDestino, reason |
| `PagamentoFalhou` | Falha técnica ou inesperada no processamento. | Payments | SRE, Atendimento | errorCode, dependency, traceId |

## 10. Observable Business Contracts

| Evento | SLI | SLO/limite inicial | Impacto | Resposta | Dono |
| --- | --- | --- | --- | --- | --- |
| `PagamentoConfirmado` | Percentual de pagamentos confirmados refletidos em Orders. | 99% em até 30s | Pedido parado após pagamento. | Acionar Payments + Orders; verificar broker e consumer. | Payments/Orders |
| `PixQRCodeGerado` | Percentual de QR Codes gerados com sucesso. | 99.5% em até 3s | Cliente não consegue pagar com Pix. | Acionar Payments; avaliar provider e fallback operacional. | Payments |
| `GatewayFallbackAcionado` | Percentual de falhas elegíveis com fallback executado. | 95% das falhas elegíveis | Falha de gateway vira indisponibilidade. | Acionar Payments; verificar regras de roteamento. | Payments |
| `PagamentoRecusado` | Percentual de recusas com motivo de negócio mapeado. | 99% com reasonCode conhecido | Cliente e atendimento sem explicação. | Acionar Payments + Antifraude/Gateway. | Payments |
| `PagamentoFalhou` | Tempo até alerta acionável com contexto. | Alerta em até 2min | MTTR alto e troubleshooting lento. | Acionar SRE + Payments com runbook. | SRE/Payments |

## 11. SLOs iniciais

| SLO | Janela | Justificativa |
| --- | --- | --- |
| 99.5% das tentativas de pagamento respondem com sucesso, recusa conhecida ou erro tratado. | 30 dias | O cliente precisa receber resposta clara, não ficar em estado desconhecido. |
| 99% dos pagamentos confirmados liberam pedido em até 30 segundos. | 30 dias | Evita cliente pago sem pedido avançar. |
| p95 de autorização abaixo de 3 segundos para gateway primário. | 7 dias | Latência impacta conversão do checkout. |
| 95% das falhas elegíveis acionam fallback automaticamente. | 30 dias | Garante intercambiabilidade do gateway. |
| 100% dos incidentes SEV1/SEV2 de Payments geram postmortem e atualização de artefato. | Mensal | Fecha o ciclo ProdOps de aprendizado. |

## 12. Dashboards

| Dashboard | Perguntas que deve responder | Link |
| --- | --- | --- |
| Payments - Jornada Checkout | Cliente consegue pagar? Onde está a queda? | `[link]` |
| Payments - Pix | QR Code, expiração, confirmação e divergências estão saudáveis? | `[link]` |
| Payments - Gateways | Qual gateway está lento, recusando ou falhando? | `[link]` |
| Payments - Orders Consistency | Pagamento confirmado virou pedido liberado? | `[link]` |
| Payments - Incidents | Quais incidentes ocorreram, MTTR e recorrência? | `[link]` |

## 13. Runbooks

| Runbook | Quando usar | Link |
| --- | --- | --- |
| Pix pago sem confirmação | Cliente pagou, mas pedido não avançou. | `[link]` |
| Gateway primário indisponível | Aumento de timeout/5xx no gateway. | `[link]` |
| Fallback não acionado | Falha elegível sem evento de fallback. | `[link]` |
| Pagamento confirmado sem pedido | Evento Payments não refletiu em Orders. | `[link]` |
| Divergência de status | Atendimento consulta status divergente. | `[link]` |

## 14. Stakeholders

| Stakeholder | Interesse | Decisão que toma | Canal |
| --- | --- | --- | --- |
| Diretoria Ecommerce | GMV, conversão, confiança na Black Friday. | Priorização de risco e investimento. | `[link]` |
| Produto Checkout | Experiência e conversão. | Priorização de UX e jornadas. | `[link]` |
| Produto Payments | Roadmap de meios de pagamento e confiabilidade. | Prioridade do produto Payments. | `[link]` |
| Financeiro | Conciliação, custo, chargeback. | Regras financeiras e aceitação de risco. | `[link]` |
| Atendimento | Redução de chamados e respostas confiáveis. | Procedimentos de suporte. | `[link]` |
| Plataforma/SRE | Operabilidade, SLO, incidentes. | Padrões de observabilidade e resposta. | `[link]` |
| Segurança/Antifraude | Risco, fraude e compliance. | Políticas de aprovação e bloqueio. | `[link]` |

## 15. Maturidade de Delivery (DORA)

O ProdOps avalia a maturidade de delivery do produto por meio das 7 métricas DORA estendidas, com pesos ajustados conforme o estágio atual.

**Estágio atual do produto:** MVP → IPR

**Perfil de avaliação adotado:** `balanced`

**Métricas e pesos prioritários neste estágio (MVP pesos / IPR pesos):**

| Métrica | Peso MVP | Peso IPR | Foco atual |
|---|---|---|---|
| Lead Time for Change | 8 | 5 | Alto — velocidade de aprendizado ainda crítica |
| Reaction Time | 5 | 3 | Médio — responsividade do sistema |
| Release Frequency | 5 | 8 | Crescente — aumentar cadência de deploys |
| Change Fail Rate | 3 | 5 | Crescente — qualidade de testes e gates |
| Mean Time to Recovery | 1 | 3 | Baixo ainda — runbooks e alertas em construção |
| Availability | 2 | 3 | Crescente — SLOs estabelecidos por OBC |
| Rate of Return | 3 | 5 | Crescente — reduzir retentativas e estornos |

**Lacunas de instrumentação para cobertura completa:**

| Gap | Métrica afetada | Ação recomendada |
|---|---|---|
| Sem integração CI/CD com observabilidade | Lead Time, Release Frequency | Intent Technology: pipeline → DataDog |
| Sem incident management integrado | MTTR | Intent Technology: PagerDuty ou equivalente |
| Change Fail Rate sem correlação temporal de deploy | Change Fail Rate | Intent Technology: deployment events |

**Assessment de maturidade:** executar no Certificare com perfil `balanced` para obter score 0–5 por métrica e roadmap priorizado.

→ Definições e pesos completos: [`../../../framework/dora-metrics.md`](../../../framework/dora-metrics.md)
→ Mapeamento Observable Events → DORA: [`../../../journeys/discovery/experiments/008-dora-extended-documentation/evidence/obc-dora-mapping.md`](../../../journeys/discovery/experiments/008-dora-extended-documentation/evidence/obc-dora-mapping.md)

---

## 16. Links

| Tipo | Link |
| --- | --- |
| Repositório Payments API | `[link]` |
| Repositório Checkout/BFF | `[link]` |
| Pipelines Payments | `[link]` |
| OpenAPI/Contratos | `[link]` |
| Tópicos/Eventos | `[link]` |
| Dashboards | `[link]` |
| Alertas | `[link]` |
| Runbooks | `[link]` |
| Backlog | `[link]` |
| Postmortems | `[link]` |

## 17. Repository Tracking List inicial

| Item | Origem | Dimensão | Dono | Status | Próxima ação |
| --- | --- | --- | --- | --- | --- |
| Confirmar SLO de Pix com negócio. | Continuous Assessment | Cliente/Empresa | PM Payments | Aberto | Validar meta inicial. |
| Mapear contratos com gateway primário e fallback. | Service Deck | Tecnologia/Peças | Tech Lead Payments | Aberto | Revisar OpenAPI e erros. |
| Criar alerta para Pix pago sem confirmação. | ODD | Dados/Fluxos | SRE + Payments | Aberto | Definir query e runbook. |
| Validar evento `GatewayFallbackAcionado`. | Reliability Plan | Tecnologia/Dados | Payments | Aberto | Implementar ou confirmar evento. |
| Revisar fluxo PagamentoConfirmado -> PedidoLiberado. | Matriz de Confiabilidade | Fluxos/Times | Payments + Orders | Aberto | Desenhar Service Blueprint. |

## 18. Próximos artefatos recomendados

- Service Deck da jornada `Compra com Pix`.
- Matriz de Confiabilidade detalhada para `PagamentoConfirmado -> PedidoLiberado`.
- Reliability Plan para migração ou adoção de novo gateway de pagamento.
- Observable Business Contract para `PagamentoConfirmado`.
- Runbook `Pix pago sem confirmação`.
