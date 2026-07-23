# language: pt
Funcionalidade: Criar invoice via Boleto no gateway de pagamentos
  Como ecommerce Magazine Siará
  Quero criar uma invoice com billingType Boleto usando o gateway de Payments
  Para oferecer pagamento offline com prazo de vencimento sem acoplamento direto ao provedor

  Contexto:
    Dado que o provedor "ASAAS" está habilitado para o ecommerce Magazine Siará
    E o ecommerce envia uma chave de idempotência em toda solicitação de criação
    E o billingType da solicitação é "BOLETO"

  Cenário: Criar boleto com sucesso para cliente já vinculado
    Dado que existe um cliente Magazine Siará "customer-123" vinculado ao cliente Asaas "cus_asaas_123"
    Quando o ecommerce solicitar a criação de uma invoice Boleto para o pedido "MS-200010" no valor de "250.00" BRL com vencimento "D+3"
    E informar o provedor "ASAAS"
    Então o gateway deve registrar a invoice com status "CREATED"
    E deve chamar o endpoint Asaas "POST /v3/payments" com billingType "BOLETO"
    E deve enviar "customer", "value", "dueDate", "description" e "externalReference"
    E o "externalReference" deve conter o identificador do pedido "MS-200010"
    E deve atualizar a invoice para status "OPEN"
    E deve retornar "invoiceId", "provider", "providerPaymentId", "status", "bankSlipUrl" e "identificationField" ao ecommerce
    E "bankSlipUrl" deve ser uma URL válida apontando para o PDF do boleto
    E "identificationField" deve conter a linha digitável do boleto

  Cenário: Criar cliente Asaas antes do boleto quando não houver vínculo
    Dado que não existe vínculo entre o cliente Magazine Siará "customer-456" e um cliente Asaas
    Quando o ecommerce solicitar a criação de uma invoice Boleto no provedor "ASAAS"
    Então o gateway deve buscar se já existe cliente Asaas reutilizável por documento ou "externalReference"
    E, se não encontrar, deve chamar "POST /v3/customers"
    E deve persistir o identificador retornado pelo Asaas
    E deve usar esse identificador no campo "customer" da cobrança Asaas

  Cenário: Rejeitar boleto com data de vencimento no passado
    Quando o ecommerce solicitar a criação de uma invoice Boleto com "dueDate" no passado
    Então o gateway deve rejeitar a solicitação com erro "400" antes de chamar o provedor
    E deve retornar mensagem clara indicando que a data de vencimento deve ser futura
    E não deve chamar a API da Asaas

  Cenário: Rejeitar boleto sem data de vencimento
    Quando o ecommerce solicitar a criação de uma invoice Boleto sem informar "dueDate"
    Então o gateway deve rejeitar a solicitação com erro "400"
    E deve retornar mensagem indicando que "dueDate" é obrigatória para Boleto
    E não deve chamar a API da Asaas

  Cenário: Evitar duplicidade em retentativa do ecommerce
    Dado que uma invoice Boleto para o pedido "MS-200010" já foi criada com a chave de idempotência "MS-200010:create"
    Quando o ecommerce repetir a criação com a mesma chave de idempotência
    Então o gateway não deve chamar novamente o provedor de pagamento
    E deve retornar a mesma invoice criada anteriormente com "bankSlipUrl" e "identificationField"

  Cenário: Rejeitar provedor não habilitado
    Dado que o provedor "ASAAS" está desabilitado para o tenant atual
    Quando o ecommerce solicitar criação de invoice Boleto com provedor "ASAAS"
    Então o gateway deve rejeitar a solicitação com erro de negócio
    E não deve chamar a API da Asaas
    E deve registrar auditoria da tentativa rejeitada

  Cenário: Falha transiente ao criar boleto no provedor
    Dado que o gateway registrou a invoice com status "CREATED"
    Quando a Asaas retornar timeout ou erro 5xx ao criar a cobrança Boleto
    Então o gateway deve marcar a tentativa como falha transiente
    E deve permitir retry seguro com a mesma chave de idempotência
    E não deve informar invoice "OPEN" ao ecommerce sem "providerPaymentId" e "bankSlipUrl"

  Cenário: Falha de validação retornada pelo provedor
    Quando a Asaas rejeitar a criação do boleto por dados inválidos
    Então o gateway deve marcar a invoice como "FAILED"
    E deve retornar erro claro ao ecommerce sem expor segredo ou payload sensível
    E deve manter a resposta do provedor disponível para auditoria interna
