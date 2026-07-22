# language: pt
Funcionalidade: Observabilidade com Datadog em producao
  Como time de Payments
  Quero que toda requisicao a API gere traces e logs no Datadog
  Para diagnosticar falhas por correlationId sem consultar CloudWatch manualmente

  Contexto:
    Dado que o ambiente de producao possui a Datadog Extension Layer configurada
    E a variavel DD_TRACE_ENABLED esta definida como true
    E a variavel DD_LOGS_INJECTION esta definida como true
    E a DatadogApiKey esta configurada via secret de deploy

  Cenario: Requisicao gera trace visivel no Datadog APM
    Dado que o gateway recebe uma requisicao autenticada
    Quando a requisicao e processada pelo Lambda
    Entao um trace com service "payments-api" e env "production" deve estar disponivel no Datadog APM em ate 60 segundos
    E o trace deve conter o correlationId da requisicao

  Cenario: Log estruturado contem dd.trace_id injetado
    Dado que o gateway emite um log durante o processamento de uma requisicao
    Quando o log e enviado ao CloudWatch e coletado pelo Datadog
    Entao o log deve conter o campo dd.trace_id correspondente ao trace ativo
    E o log deve conter o campo dd.span_id

  Cenario: Metricas de runtime Lambda aparecem no Datadog
    Dado que uma funcao Lambda foi invocada
    Quando a invocacao e concluida
    Entao metricas de duracao memoria e cold start devem estar disponiveis no Datadog
    E as metricas devem estar associadas ao service "payments-api" e env "production"

  Cenario: DatadogApiKey nao e exposta em logs ou traces
    Dado que o Lambda esta rodando com DatadogApiKey configurada
    Quando qualquer log ou trace e emitido
    Entao a DatadogApiKey nao deve aparecer em nenhum campo de log ou trace
    E nenhum outro secret deve aparecer em texto claro em traces ou logs

  Cenario: Falha na extensao Datadog nao impede resposta da API
    Dado que a Datadog Extension nao esta disponivel
    Quando o gateway recebe uma requisicao autenticada
    Entao a requisicao deve ser processada normalmente e retornar resposta valida
    E a falha da extensao deve ser registrada sem impedir o processamento
