Feature: Boleto Auto-Cancellation
  Como sistema de pagamentos
  Quero cancelar automaticamente boletos vencidos após 1 dia do vencimento
  Para manter o estado das invoices consistente e notificar o consumidor por webhook

  Background:
    Given uma invoice de BOLETO existente com paymentId "pay_boleto_123"
    And a invoice está no status "OPEN"

  Scenario: Boleto vencido é automaticamente expirado
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a invoice deve estar no status "EXPIRED"
    And o evento "payments.invoice.expired" deve ser publicado

  Scenario: Boleto vencido entrega o webhook de boleto cancelado ao consumidor inscrito
    Given o tenant tem um webhook ativo inscrito em "invoice.cancelled"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then o consumidor deve receber um webhook do tipo "invoice.cancelled"
    And o payload deve conter o invoiceId e o orderId da invoice
    And o payload deve ter status "EXPIRED" e reason "BOLETO_OVERDUE"
    And o payload deve ter billingType "BOLETO"
    And a entrega deve ser assinada com X-Payments-Signature

  Scenario: Consumidor não inscrito em invoice.cancelled não recebe o webhook
    Given o tenant tem um webhook ativo inscrito apenas em "invoice.confirmed"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a invoice deve estar no status "EXPIRED"
    And nenhum webhook deve ser entregue a esse consumidor

  Scenario: Falha na entrega do webhook não desfaz a expiração
    Given o tenant tem um webhook ativo inscrito em "invoice.cancelled"
    And o endpoint do consumidor responde com erro
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a invoice deve permanecer no status "EXPIRED"

  Scenario: Boleto criado com configuração de cancelamento automático
    When uma invoice de BOLETO é criada com daysAfterDueDateToRegistrationCancellation 1
    Then a invoice deve ser criada com sucesso
    And a configuração de cancelamento automático deve ser enviada ao PSP

  Scenario: Webhook PAYMENT_OVERDUE duplicado é tratado de forma idempotente
    Given a invoice já está no status "EXPIRED"
    And o tenant tem um webhook ativo inscrito em "invoice.cancelled"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" novamente para paymentId "pay_boleto_123"
    Then a invoice permanece no status "EXPIRED"
    And nenhum evento duplicado é publicado
    And nenhum webhook adicional é entregue ao consumidor

  Scenario: Boleto confirmado não é expirado
    Given a invoice está no status "CONFIRMED"
    And o tenant tem um webhook ativo inscrito em "invoice.cancelled"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a invoice permanece no status "CONFIRMED"
    And nenhum evento de expiração é publicado
    And nenhum webhook é entregue ao consumidor

  Scenario: PAYMENT_OVERDUE para billingType incorreto é ignorado
    Given uma invoice de PIX existente com paymentId "pay_pix_789"
    And o tenant tem um webhook ativo inscrito em "invoice.cancelled"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_pix_789"
    Then a invoice não muda de status
    And nenhum evento de expiração é publicado
    And nenhum webhook é entregue ao consumidor

  Scenario: Valor padrão de daysAfterDueDateToRegistrationCancellation é aplicado
    When uma invoice de BOLETO é criada sem especificar daysAfterDueDateToRegistrationCancellation
    Then o valor padrão de 1 dia deve ser usado
    And a configuração deve ser enviada ao PSP com valor 1

  # Observabilidade (BS-006): métricas emitidas de verdade e conferidas no Datadog por
  # api/test/boleto-auto-cancellation.datadog.e2e-spec.ts (npm run test:e2e:datadog)
  Scenario: Boleto expirado é contabilizado no Datadog
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a métrica "invoice.expired" deve chegar ao Datadog
    And a métrica "webhook.received" deve chegar ao Datadog com event_type "payment_overdue"

  Scenario: Entrega do webhook ao consumidor é contabilizada no Datadog
    Given o tenant tem um webhook ativo inscrito em "invoice.cancelled"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a métrica "webhook.delivery.sent" deve chegar ao Datadog com event "invoice.cancelled"

  Scenario: Falha na entrega do webhook é contabilizada no Datadog
    Given o tenant tem um webhook ativo inscrito em "invoice.cancelled"
    And o endpoint do consumidor responde com erro
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a métrica "webhook.delivery.failed" deve chegar ao Datadog com event "invoice.cancelled"

  Scenario Outline: Expiração ignorada é contabilizada no Datadog com o motivo
    Given a invoice não pode ser expirada porque <situacao>
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para a invoice
    Then a métrica "invoice.expiration_ignored" deve chegar ao Datadog com reason "<motivo>"
    And a métrica "invoice.expired" não deve ser incrementada

    Examples:
      | situacao                   | motivo       |
      | está CONFIRMED             | confirmado   |
      | já está EXPIRED            | ja_expirado  |
      | não é uma invoice de BOLETO | billing_type |

  Scenario: Webhook não correlacionado é contabilizado no Datadog
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para um paymentId inexistente
    Then a métrica "webhook.failed" deve chegar ao Datadog com failure_type "uncorrelated"
