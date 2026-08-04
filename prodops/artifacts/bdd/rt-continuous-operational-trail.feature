Feature: RT Continuous Operational Trail — DS-59
  Como ProdOps Context Engineer
  Quero que o trail de cada Feature seja registrado continuamente durante a execução, com uma entry por phase
  Para que seja possível auditar o estado da execução em tempo real e diagnosticar falhas mid-flight

  Background:
    Given o downstream-agent está executando o loop de issues da iteração v0.12.0
    And cada Work Item tem uma GitHub Issue correspondente criada no Plan Bootstrap

  Scenario: Entry de trail registrada após cada phase completada
    Given o downstream-agent está processando um Work Item
    When cada phase é completada em sequência:
      | phase      |
      | Bootstrap  |
      | Hack       |
      | Sync       |
      | Finish     |
      | Ship       |
      | Validate   |
      | Promote    |
    Then uma entry é adicionada ao GitHub Issue comment antes de avançar à próxima phase
    And cada entry contém: nome da phase, work-item-id, status (completed), timestamp

  Scenario: Trail parcial disponível após falha mid-flight
    Given o downstream-agent completou Bootstrap e Hack para um Work Item
    When a execução é interrompida durante a phase Sync
    Then o GitHub Issue contém entries de trail para Bootstrap e Hack
    And a última entry indica que Sync foi iniciado mas não concluído
    And o trail permite diagnosticar a última phase executada com sucesso

  Scenario: downstream-agent documenta qual issue está processando
    Given o downstream-agent inicia o loop sobre as issues da iteração
    When cada issue é processada
    Then o downstream-agent registra no GitHub Issue comment qual phase está iniciando
    And registra qual phase concluiu antes de avançar

  Scenario: Falha ao escrever trail entry não bloqueia execução da phase
    Given o GitHub retorna erro ao adicionar o comment de trail
    When o downstream-agent tenta registrar a entry da phase
    Then a phase prossegue normalmente
    And um aviso é registrado internamente sem interromper o loop

  Scenario: SKILL.md do downstream instrui trail por phase como requisito
    Given o arquivo "prodops/skills/downstream/SKILL.md" está presente
    When o conteúdo é inspecionado
    Then existe instrução explícita para registrar entry de trail após cada phase
    And a instrução especifica: phase name, work-item-id, status, timestamp como campos obrigatórios
