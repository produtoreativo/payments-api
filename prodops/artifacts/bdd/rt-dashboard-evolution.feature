Feature: RT Dashboard Evolution — DS-60
  Como ProdOps Context Engineer
  Quero que o dashboard Datadog do Runtime exiba cycle time por phase, permita filtro por Iteration ID e use labels canônicos
  Para que qualquer stakeholder possa monitorar a performance de entrega por iteração sem conhecer os nomes internos de CloudEvents

  Background:
    Given o script "prodops/runtime/datadog/send.sh" está disponível
    And o pipeline emit-event entrega eventos com tags corretas (pré-requisito: DS-57 concluído)

  Scenario: Tag iteration presente em todos os eventos enviados ao Datadog
    Given um evento qualquer de delivery é emitido com "iteration-id" válido
    When o "send.sh" envia o evento ao Datadog
    Then o evento contém a tag "iteration:<iteration-id>"
    And a tag está presente independentemente do tipo de evento (Bootstrap, Hack, Sync, etc.)

  Scenario: Template variable $iteration_id funcional no dashboard Runtime
    Given o dashboard Runtime está configurado no Datadog
    When a template variable "$iteration_id" é selecionada com valor "v0.12.0"
    Then todos os widgets do dashboard filtram os dados para a iteração selecionada
    And o dashboard exibe apenas eventos com tag "iteration:v0.12.0"

  Scenario: Widget de cycle time por phase exibe duração média
    Given eventos ".Started" e ".Completed" para as 7 phases estão presentes no Datadog
    When o widget de cycle time é consultado para a iteração selecionada
    Then o widget exibe duração média para cada phase:
      | phase    |
      | Bootstrap |
      | Hack      |
      | Sync      |
      | Finish    |
      | Ship      |
      | Validate  |
      | Promote   |
    And o cycle time é calculado entre "<Phase>.Started" e "<Phase>.Completed" para o mesmo work-item-id

  Scenario: Labels dos widgets usam nomes canônicos
    Given os widgets existentes no dashboard Runtime estão configurados
    When os labels são inspecionados
    Then nenhum label contém nomes internos de CloudEvents (ex: "prodops.delivery.bootstrap.started")
    And cada label usa o nome canônico da phase correspondente (ex: "Bootstrap", "Hack", "Sync")

  Scenario: Dashboard exportado como JSON commitado no repositório
    Given as alterações no dashboard foram aplicadas no Datadog
    When o dashboard é exportado via API Datadog
    Then o JSON exportado está presente em "prodops/runtime/datadog/"
    And o arquivo contém a definição das template variables e widgets de cycle time
