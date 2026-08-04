Feature: RT Event Pipeline Completeness — DS-57
  Como ProdOps Context Engineer
  Quero que todos os eventos do ciclo de Bootstrap cheguem ao Datadog e que cada evento de phase transita o oem-state no GitHub Project
  Para que a observabilidade do Runtime seja completa e confiável sem intervenção manual

  Background:
    Given o tool "prodops/runtime/tools/emit-event/scripts/emit-event" está disponível
    And o script "prodops/runtime/github/sync.sh" está disponível
    And o script "prodops/runtime/datadog/send.sh" está disponível

  Scenario: Todos os eventos de Bootstrap chegam ao Datadog
    Given um Work Item com "work-item-id" válido e "iteration-id" válido
    When os 5 eventos de Bootstrap são emitidos em sequência:
      | evento                                        |
      | Delivery.Bootstrap.Started                    |
      | Delivery.Bootstrap.Dependencies.Installed     |
      | Delivery.Bootstrap.Services.Ready             |
      | Delivery.Bootstrap.Smoke.Passed               |
      | Delivery.Bootstrap.Completed                  |
    Then cada evento aparece no Datadog com tag "issue:<work-item-id>"
    And cada evento aparece com tag "iteration:<iteration-id>"
    And nenhum evento retorna status "dropped" ou "skipped" no pipeline

  Scenario: emit-event retorna github-sync success para eventos de phase
    Given um Work Item com "work-item-id" válido
    When qualquer evento "Delivery.<Phase>.Started" é emitido
    Then o emit-event retorna campo "github-sync" com valor "success"
    And o oem-state do item é transitado no GitHub Project Board dentro de 60 segundos

  Scenario: oem-state FINISHING transitado ao emitir Finish.Started
    Given um Work Item no estado "HACKING" no GitHub Project Board
    When o evento "Delivery.Finish.Started" é emitido para esse Work Item
    Then o oem-state do item é atualizado para "FINISHING" no GitHub Project Board
    And o emit-event não retorna "skip" para o step de github-sync

  Scenario: emit-event com work-item-id nulo e evento de plan não bloqueia pipeline
    Given um evento "Delivery.Plan.Bootstrap.Started" com "work-item-id" ausente ou null
    And "iteration-id" está presente
    When o emit-event é invocado
    Then o pipeline prossegue usando "plan-<iteration-id>" como subject
    And o evento aparece no Datadog sem campo "issue:null"

  Scenario: testes unitários do emit-event passam após correções
    Given o diretório "prodops/runtime/tools/emit-event/tests/" contém os cenários de teste
    When "prodops/runtime/tools/emit-event/tests/run-all.sh" é executado
    Then todos os testes retornam exit 0
    And nenhum teste retorna status "FAIL"
