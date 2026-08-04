# language: pt
Funcionalidade: Split Payment — Pix + Boleto em uma mesma compra
  Como cliente da Magazine Siará
  Quero pagar uma compra dividindo o valor entre Pix e Boleto
  Para ter flexibilidade de pagamento sem precisar pagar tudo de uma só vez com o mesmo meio

  Contexto:
    Dado que o gateway possui os provedores Pix e Boleto habilitados para a Magazine Siará
    E o cliente envia uma chave de idempotência em toda solicitação de criação de Split Payment
    E os valores de Pix e Boleto somam exatamente o valor total do pedido

  # ---------------------------------------------------------------------------
  # CAMINHO FELIZ
  # ---------------------------------------------------------------------------

  Cenário: Criar Split Payment com sucesso
    Dado que existe um pedido "MS-200001" no valor total de "500.00" BRL
    Quando o Checkout solicitar a criação de um Split Payment
    E informar Pix no valor de "200.00" BRL
    E informar Boleto no valor de "300.00" BRL
    Então o sistema deve criar o Split Payment com status "PENDING_BOTH"
    E deve gerar uma cobrança Pix com "pixInvoiceId" válido
    E deve gerar uma cobrança Boleto com "boletoInvoiceId" e data de vencimento válidos
    E deve emitir o evento "split_payment.created" com "splitPaymentId", "orderId", "pixAmount", "boletoAmount" e "correlationId"
    E deve retornar "splitPaymentId", "pixInvoiceId", "boletoInvoiceId" e "status" ao Checkout

  Cenário: Pedido liberado após confirmação dos dois meios
    Dado que existe um Split Payment "spl_001" para o pedido "MS-200001" com status "PENDING_BOTH"
    Quando o provedor confirmar o pagamento Pix
    Então o sistema deve emitir "split_payment.pix.confirmed" e atualizar status para "PIX_CONFIRMED"
    Quando o provedor confirmar o pagamento Boleto
    Então o sistema deve emitir "split_payment.boleto.confirmed"
    E deve emitir "split_payment.completed" com "splitPaymentId", "orderId" e "completedAt"
    E deve atualizar status para "COMPLETED"
    E o pedido "MS-200001" deve ser liberado

  Cenário: Confirmação na ordem inversa — Boleto antes do Pix
    Dado que existe um Split Payment "spl_002" com status "PENDING_BOTH"
    Quando o provedor confirmar o pagamento Boleto primeiro
    Então o sistema deve emitir "split_payment.boleto.confirmed" e atualizar status para "BOLETO_CONFIRMED"
    E o pedido não deve ser liberado
    Quando o provedor confirmar o pagamento Pix
    Então o sistema deve emitir "split_payment.pix.confirmed"
    E deve emitir "split_payment.completed"
    E o pedido deve ser liberado

  # ---------------------------------------------------------------------------
  # IDEMPOTÊNCIA
  # ---------------------------------------------------------------------------

  Cenário: Retentativa de criação com mesma chave de idempotência
    Dado que um Split Payment para o pedido "MS-200001" já foi criado com a chave "MS-200001:split"
    Quando o Checkout repetir a criação com a mesma chave de idempotência
    Então o sistema não deve criar novas cobranças no provedor
    E deve retornar o mesmo "splitPaymentId" criado anteriormente

  Cenário: Webhook duplicado de confirmação do Pix
    Dado que o Pix do Split Payment "spl_001" já foi confirmado
    Quando o provedor enviar o webhook de confirmação Pix novamente
    Então o sistema não deve emitir "split_payment.pix.confirmed" pela segunda vez
    E não deve alterar o status atual do Split Payment

  # ---------------------------------------------------------------------------
  # BOLETO VENCIDO
  # ---------------------------------------------------------------------------

  Cenário: Boleto vence com Pix já confirmado
    Dado que existe um Split Payment "spl_003" com status "PIX_CONFIRMED"
    E o Pix foi confirmado
    E o Boleto ainda não foi pago
    Quando a data de vencimento do Boleto for atingida sem pagamento
    Então o sistema deve emitir "split_payment.boleto.expired" com "pixStatus: confirmed"
    E deve atualizar status para "PENDING_INVESTIGATION"
    E não deve cancelar o pedido automaticamente
    E não deve estornar o Pix automaticamente
    E o evento deve conter "splitPaymentId", "orderId", "boletoInvoiceId", "expiredAt" e "correlationId"

  Cenário: Boleto vence sem nenhum pagamento realizado
    Dado que existe um Split Payment "spl_004" com status "PENDING_BOTH"
    E nenhum dos dois meios foi pago
    Quando a data de vencimento do Boleto for atingida sem pagamento
    Então o sistema deve emitir "split_payment.boleto.expired" com "pixStatus: pending"
    E deve atualizar status para "PENDING_INVESTIGATION"
    E não deve cancelar o pedido automaticamente

  # ---------------------------------------------------------------------------
  # VALIDAÇÕES E FALHAS
  # ---------------------------------------------------------------------------

  Cenário: Rejeitar Split Payment com soma de valores incorreta
    Dado que existe um pedido "MS-200002" no valor total de "500.00" BRL
    Quando o Checkout solicitar Split Payment com Pix de "200.00" e Boleto de "200.00" BRL
    Então o sistema deve rejeitar a solicitação com erro de validação
    E não deve chamar o provedor
    E deve retornar mensagem indicando que os valores não somam o total do pedido

  Cenário: Falha transiente ao criar cobrança no provedor
    Dado que o Split Payment foi criado internamente para o pedido "MS-200003"
    Quando o provedor retornar timeout ou erro 5xx ao criar uma das cobranças
    Então o sistema deve registrar a falha transiente
    E deve permitir retry seguro com a mesma chave de idempotência
    E não deve retornar status de sucesso ao Checkout sem os identificadores do provedor

  Cenário: Nenhum dado financeiro exposto em resposta de erro
    Quando qualquer operação de Split Payment falhar
    Então a resposta de erro não deve conter valores de pagamento, dados do provedor ou informações internas
    E deve conter apenas código de erro, mensagem genérica e "correlationId"
