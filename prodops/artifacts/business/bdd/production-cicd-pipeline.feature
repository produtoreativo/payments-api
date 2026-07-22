# language: pt
Funcionalidade: Pipeline de CI/CD para producao com gate de aprovacao
  Como time de Payments
  Quero que todo deploy em producao exija aprovacao humana explicita e deixe rastro auditavel
  Para garantir que nenhum deploy aconteca sem revisao e todo incidente possa ser rastreado ao commit causador

  Contexto:
    Dado que o workflow "deploy-production.yml" esta configurado no repositorio
    E o GitHub Environment "production" existe com Required Reviewers configurado
    E os secrets PRODUCTION_ASAAS_TOKEN PRODUCTION_ADMIN_SECRET PRODUCTION_DATADOG_API_KEY estao configurados no environment

  Cenario: Deploy em producao requer aprovacao do Required Reviewer
    Dado que um desenvolvedor dispara o workflow via workflow_dispatch com um motivo informado
    Quando o job "deploy-production" inicia
    Entao o job deve ficar bloqueado aguardando aprovacao do Required Reviewer
    E o deploy nao deve prosseguir sem aprovacao explicita

  Cenario: Deploy nao e acionado por push automatico
    Dado que um commit e feito em qualquer branch incluindo main
    Quando o evento de push e processado pelo GitHub Actions
    Entao o workflow "deploy-production.yml" nao deve ser disparado automaticamente

  Cenario: Deploy aprovado conclui com smoke tests passando
    Dado que o Required Reviewer aprovou o deploy
    Quando o pipeline executa build dynamo-deploy e lambda-deploy em sequencia
    Entao o smoke test deve confirmar que POST /invoices sem token retorna 401
    E o smoke test deve confirmar que DELETE /invoices/id sem token retorna 401
    E o step summary deve conter a URL da API deployada o commit SHA e o motivo do deploy

  Cenario: Secrets de producao nunca aparecem no samconfig.toml
    Dado que o arquivo "api/samconfig.toml" e inspecionado
    Quando os valores dos parametros de producao sao lidos
    Entao AsaasToken AdminSecret e DatadogApiKey nao devem ter valores nao vazios
    E os parametros de secret devem estar ausentes ou com valor vazio no arquivo

  Cenario: Dois deploys simultaneos nao sao permitidos
    Dado que um deploy em producao ja esta em andamento
    Quando um segundo workflow_dispatch e disparado
    Entao o segundo deploy deve aguardar o primeiro concluir
    E o deploy em andamento nao deve ser cancelado pelo novo trigger

  Cenario: Mudanca na role IAM exige PR e deploy CloudFormation
    Dado que a role "payments-api-github-deploy" e gerenciada pelo template "api/infra/iam-deploy-role.yaml"
    Quando uma nova permissao e necessaria
    Entao a mudanca deve ser feita via Pull Request no arquivo de template
    E o template deve ser deployado via "aws cloudformation deploy" para aplicar a mudanca
