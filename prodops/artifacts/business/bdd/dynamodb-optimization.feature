# language: pt
Funcionalidade: Persistencia DynamoDB otimizada para producao
  Como time de Payments
  Quero que as tabelas DynamoDB operem sem risco de throttling e com PITR habilitado
  Para garantir que nenhum pagamento falhe por limite de capacidade e dados possam ser recuperados

  Contexto:
    Dado que o stack "payments-api-dynamo-production" esta em estado CREATE_COMPLETE ou UPDATE_COMPLETE
    E todas as tabelas criticas estao acessiveis via SDK

  Cenario: Tabelas operam com billing PAY_PER_REQUEST
    Dado que as tabelas PaymentsTable TransactionsTable CustomersTable TenantsTable e WebhooksTable existem
    Quando o billing mode e consultado via describe-table
    Entao todas as tabelas devem retornar BillingMode igual a PAY_PER_REQUEST
    E nenhuma tabela deve ter ProvisionedThroughput definido

  Cenario: PITR esta habilitado em todas as tabelas criticas
    Dado que as tabelas PaymentsTable TransactionsTable CustomersTable TenantsTable e WebhooksTable existem
    Quando o status de backup continuo e consultado via describe-continuous-backups
    Entao todas as tabelas devem retornar PointInTimeRecoveryStatus igual a ENABLED

  Cenario: GSIs sem uso foram removidos
    Dado que a PaymentsTable esta configurada
    Quando os indices globais sao listados
    Entao apenas o indice ProviderPaymentIndex deve existir
    E o indice PaymentStatusIndex nao deve existir

  Cenario: TransactionsTable nao possui GSIs desnecessarios
    Dado que a TransactionsTable esta configurada
    Quando os indices globais sao listados
    Entao nenhum GSI deve existir na TransactionsTable

  Cenario: ProvidersTable nao existe no stack de producao
    Dado que o stack "payments-api-dynamo-production" esta ativo
    Quando os recursos do stack sao listados
    Entao nenhum recurso com nome contendo "ProvidersTable" deve existir

  Cenario: Escrita em alta carga nao gera throttling
    Dado que multiplas escritas simultaneas sao enviadas ao DynamoDB
    Quando as escritas sao processadas com PAY_PER_REQUEST
    Entao nenhuma escrita deve retornar erro de ProvisionedThroughputExceededException
    E todas as escritas devem ser confirmadas com sucesso
