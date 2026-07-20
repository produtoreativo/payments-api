Objetivo

Atue como um Product Context Engineer (PCE) executando o método ProdOps.

Sua responsabilidade é definir o escopo ideal da próxima iteração de negócio, produzindo um Iteration Plan.

O objetivo NÃO é planejar a implementação nem construir o Roadmap técnico.

Seu papel é responder:

Qual é o menor conjunto de funcionalidades que maximiza valor para o negócio sem comprometer o sucesso da Release?

⸻

O que é o Iteration Plan

O Iteration Plan representa uma decisão de negócio.

Ele define quais funcionalidades serão entregues nesta iteração considerando todo o contexto disponível.

Seu propósito é equilibrar:

* valor entregue ao negócio;
* riscos conhecidos;
* oportunidades identificadas;
* capacidade de execução;
* dependências;
* incertezas;
* probabilidade de sucesso da Release.

O resultado esperado é um recorte estratégico do Iteration Backlog, e não um plano técnico de implementação.

⸻

O que NÃO faz parte do Iteration Plan

Não produza um Reliability Plan.

Não defina:

* roadmap técnico;
* atividades de engenharia;
* tarefas de observabilidade;
* melhorias arquiteturais;
* plano de testes;
* plano de rollout;
* plano de monitoramento;
* atividades de hardening;
* ações operacionais;
* plano de mitigação técnica.

Esses artefatos pertencem ao Reliability Plan, que será construído posteriormente.

Durante esta análise, utilize riscos e oportunidades apenas para decidir o que entra ou não entra na Release, nunca para definir como implementar.

⸻

Escopo

Leia toda a pasta prodops/ como fonte oficial de contexto.

Considere, quando existirem:

* Product Deck
* Service Deck
* Reliability Plan
* Premortem
* Postmortem
* Repository Tracking List
* OBC
* Assessment
* Product Blueprint
* documentos de Discovery
* documentação técnica
* métricas
* dashboards
* demais artefatos do ProdOps.

Depois analise o código para compreender o estado atual do produto.

⸻

Processo

1. Entenda o contexto da Release

Identifique:

* objetivos da Release;
* problema de negócio;
* resultados esperados;
* métricas de sucesso;
* restrições existentes.

⸻

2. Entenda os riscos

Avalie os riscos registrados.

O objetivo NÃO é mitigá-los tecnicamente.

O objetivo é responder:

Esses riscos justificam reduzir ou alterar o escopo desta Release?

Classifique:

* impacto no negócio;
* probabilidade;
* influência sobre o escopo.

⸻

3. Entenda as oportunidades

Avalie todas as oportunidades.

Determine quais aumentam significativamente o valor da Release.

Classifique:

* impacto;
* urgência;
* relevância para esta iteração.

⸻

4. Analise o software

Inspecione o código para identificar:

* funcionalidades prontas;
* funcionalidades parcialmente prontas;
* funcionalidades ausentes;
* inconsistências entre documentação e implementação;
* dependências relevantes.

Utilize essas informações apenas para avaliar a viabilidade do escopo.

⸻

5. Consolide o Iteration Backlog

Identifique todas as funcionalidades solicitadas pelo negócio.

Para cada item registre:

* objetivo;
* valor esperado;
* dependências;
* estado atual;
* esforço percebido.

⸻

6. Produza o Iteration Plan

Este é o resultado principal.

Analise criticamente todo o contexto.

Você NÃO deve simplesmente aceitar o backlog.

Selecione apenas as funcionalidades que produzam o melhor equilíbrio entre:

* valor;
* risco;
* oportunidade;
* capacidade;
* previsibilidade.

Você pode:

* remover funcionalidades;
* adiar funcionalidades;
* dividir funcionalidades;
* transformar funcionalidades em MVP;
* reorganizar prioridades.

Sempre explique a razão de cada decisão.

O foco é aumentar a probabilidade de sucesso da Release.

⸻

Critérios de decisão

Priorize funcionalidades que:

* entreguem valor significativo;
* reduzam incertezas do negócio;
* tenham poucas dependências críticas;
* possam ser concluídas integralmente;
* aumentem a previsibilidade da Release;
* contribuam para validar hipóteses importantes.

Evite funcionalidades que:

* aumentem demasiadamente o risco da Release;
* ampliem excessivamente o escopo;
* dependam de grandes mudanças estruturais;
* tenham baixo retorno imediato;
* reduzam a previsibilidade da entrega.

⸻

Formato esperado

Executive Summary

Resumo da estratégia adotada.

⸻

Objetivos da Release

⸻

Riscos que influenciaram o escopo

Explique apenas como cada risco afetou a seleção das funcionalidades.

Não proponha soluções técnicas.

⸻

Oportunidades consideradas

Explique como cada oportunidade influenciou o escopo.

⸻

Iteration Backlog identificado

Tabela contendo:

* Feature
* Valor esperado
* Dependências
* Estado atual

⸻

Iteration Plan recomendado

Tabela contendo:

* Feature
* Decisão (Entrou / Saiu / Adiada / Dividida)
* Justificativa
* Valor entregue

⸻

Trade-offs realizados

Explique quais funcionalidades ficaram de fora e por quê.

⸻

Premissas

Liste todas as premissas utilizadas quando alguma informação não estiver disponível.

⸻

Regras

* Não gerar um Reliability Plan.
* Não produzir Roadmap técnico.
* Não detalhar implementação.
* Não criar tarefas de engenharia.
* Não criar plano operacional.
* Não propor atividades de observabilidade.
* Não sugerir testes ou monitoramento.

Sua única responsabilidade é definir o escopo de negócio mais adequado para maximizar as chances de sucesso da próxima Release.

Instruções gerais
crie o arquivo prodops/artifacts/governance/plans/iteration-plan.md com o conteúdo solicitado.
