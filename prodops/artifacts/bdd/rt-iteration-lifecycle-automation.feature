Feature: RT Iteration Lifecycle Automation — DS-58
  Como ProdOps Context Engineer
  Quero que a tracking issue seja fechada automaticamente e os assignees preenchidos desde o Plan Bootstrap
  Para que o encerramento de uma Iteration não exija nenhuma ação manual após o último Promote.Completed

  Background:
    Given o CLI "gh" está autenticado com permissão de escrita nas issues
    And "gh api user --jq '.login'" retorna o login do Context Engineer

  Scenario: Assignee preenchido em cada issue criada no Plan Bootstrap
    Given o Plan Bootstrap está sendo executado para a iteração v0.12.0
    When cada GitHub Issue de feature (DS-57, DS-58, DS-59, DS-60) é criada
    Then o campo "assignees" de cada issue contém o login do Context Engineer
    And a tracking issue da iteração também tem o assignee preenchido no momento da criação

  Scenario: Tracking issue fechada automaticamente após todos os Promotes
    Given todas as issues da iteração chegaram ao estado "Promote.Completed"
    When o step de Iteration Closure é executado no downstream-agent
    Then a tracking issue da iteração recebe um comment de encerramento contendo:
      | campo        | conteúdo esperado             |
      | DS-IDs       | DS-57, DS-58, DS-59, DS-60    |
      | PRs mergeados| lista de PRs da iteração      |
      | Data         | data de encerramento          |
    And a tracking issue é fechada com estado "closed"

  Scenario: Auto-close não ocorre com issues pendentes
    Given pelo menos uma issue da iteração ainda não chegou a "Promote.Completed"
    When o Iteration Closure é invocado prematuramente
    Then a tracking issue NÃO é fechada
    And um aviso é registrado indicando quais issues ainda estão pendentes

  Scenario: Falha ao adicionar assignee não bloqueia criação da issue
    Given o GitHub retorna erro ao adicionar o assignee
    When uma issue de feature é criada no Plan Bootstrap
    Then a issue é criada com sucesso (sem assignee)
    And um aviso é registrado no trail da execução
    And o Plan Bootstrap continua sem interrupção

  Scenario: Auto-close é idempotente se tracking issue já fechada
    Given a tracking issue já foi fechada manualmente
    When o step de Iteration Closure tenta fechar a issue novamente
    Then nenhuma ação é executada (sem reabertura, sem comment duplicado)
    And o step retorna sucesso
