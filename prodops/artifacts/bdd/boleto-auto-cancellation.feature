Feature: Boleto Auto-Cancellation
  Como sistema de pagamentos
  Quero cancelar automaticamente boletos vencidos após 1 dia do vencimento
  Para manter o estado das invoices consistente e notificar consumidores

  Background:
    Given uma invoice de BOLETO existente com paymentId "pay_boleto_123"
    And a invoice está no status "PENDING"

  Scenario: Boleto vencido é automaticamente expirado
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a invoice deve estar no status "EXPIRED"
    And o evento "payment.boleto.expired" deve ser publicado

  Scenario: Boleto criado com configuração de cancelamento automático
    When uma invoice de BOLETO é criada com daysAfterDueDateToRegistrationCancellation 1
    Then a invoice deve ser criada com sucesso
    And a configuração de cancelamento automático deve ser enviada ao PSP

  Scenario: Webhook PAYMENT_OVERDUE duplicado é tratado de forma idempotente
    Given a invoice já está no status "EXPIRED"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" novamente para paymentId "pay_boleto_123"
    Then a invoice permanece no status "EXPIRED"
    And nenhum evento duplicado é publicado

  Scenario: Boleto confirmado não é expirado
    Given a invoice está no status "CONFIRMED"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_boleto_123"
    Then a invoice permanece no status "CONFIRMED"
    And nenhum evento de expiração é publicado

  Scenario: PAYMENT_OVERDUE para billingType incorreto é ignorado
    Given uma invoice de PIX existente com paymentId "pay_pix_789"
    When o PSP envia webhook com event "PAYMENT_OVERDUE" para paymentId "pay_pix_789"
    Then a invoice não muda de status
    And nenhum evento de expiração é publicado

  Scenario: Valor padrão de daysAfterDueDateToRegistrationCancellation é aplicado
    When uma invoice de BOLETO é criada sem especificar daysAfterDueDateToRegistrationCancellation
    Then o valor padrão de 1 dia deve ser usado
    And a configuração deve ser enviada ao PSP com valor 1
