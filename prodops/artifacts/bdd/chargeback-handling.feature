Feature: Chargeback Handling
  Como sistema de pagamentos
  Quero rastrear e publicar eventos de chargeback recebidos do PSP
  Para que os consumidores sejam notificados sem ação financeira autônoma

  Background:
    Given uma invoice de cartão de crédito existente com paymentId "pay_123"
    And a invoice está no status "CONFIRMED"

  Scenario: Chargeback solicitado pelo portador
    When o PSP envia webhook com event "PAYMENT_CHARGEBACK_REQUESTED" para paymentId "pay_123"
    Then a invoice deve estar no status "CHARGEBACK_REQUESTED"
    And o evento "payment.chargeback_requested" deve ser publicado

  Scenario: Chargeback entra em fase de disputa
    Given a invoice está no status "CHARGEBACK_REQUESTED"
    When o PSP envia webhook com event "PAYMENT_CHARGEBACK_DISPUTE" para paymentId "pay_123"
    Then a invoice deve estar no status "CHARGEBACK_DISPUTE"
    And o evento "payment.chargeback_dispute" deve ser publicado

  Scenario: Aguardando reversão de chargeback
    Given a invoice está no status "CHARGEBACK_DISPUTE"
    When o PSP envia webhook com event "PAYMENT_AWAITING_CHARGEBACK_REVERSAL" para paymentId "pay_123"
    Then a invoice deve estar no status "CHARGEBACK_REVERSAL_PENDING"
    And o evento "payment.chargeback_reversal_pending" deve ser publicado

  Scenario: Webhook de chargeback duplicado é tratado de forma idempotente
    Given a invoice já está no status "CHARGEBACK_REQUESTED"
    When o PSP envia webhook com event "PAYMENT_CHARGEBACK_REQUESTED" novamente para paymentId "pay_123"
    Then a invoice permanece no status "CHARGEBACK_REQUESTED"
    And nenhum evento duplicado é publicado

  Scenario: Chargeback para billingType incorreto é ignorado
    Given uma invoice de PIX existente com paymentId "pay_456"
    When o PSP envia webhook com event "PAYMENT_CHARGEBACK_REQUESTED" para paymentId "pay_456"
    Then a invoice não muda de status
    And nenhum evento de chargeback é publicado

  Scenario: CHARGEBACK_DISPUTE sem CHARGEBACK_REQUESTED anterior é aceito (out-of-order)
    Given a invoice está no status "CONFIRMED"
    When o PSP envia webhook com event "PAYMENT_CHARGEBACK_DISPUTE" para paymentId "pay_123"
    Then a invoice deve estar no status "CHARGEBACK_DISPUTE"
    And o evento "payment.chargeback_dispute" deve ser publicado
