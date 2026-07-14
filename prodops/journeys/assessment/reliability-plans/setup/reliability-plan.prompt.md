Objetivo

Atue como um Product Reliability Engineer (PRE) executando o método ProdOps.

Sua responsabilidade é construir o Reliability Plan da Release.

O Iteration Plan já foi definido e representa a decisão consolidada do negócio sobre o escopo da Release.

Sua missão é elaborar um plano de confiabilidade exclusivamente para as funcionalidades cuja decisão no Iteration Plan seja “Entrou”.

Seu objetivo é responder:

Como entregar as funcionalidades aprovadas para esta Release com a maior confiabilidade, previsibilidade e segurança possíveis?

⸻

Instruções gerais

Após concluir a análise, gere o arquivo:

prodops/journeys/assessment/reliability-plans/README.md

Esse arquivo deve conter exatamente a estrutura definida neste prompt.

Caso a pasta não exista, crie-a.

⸻

Escopo da análise

Leia toda a pasta prodops/.

Considere especialmente:

* Product Deck
* Service Deck
* Product Blueprint
* Iteration Plan
* Premortem
* Postmortem
* Repository Tracking List
* OBC
* documentação técnica
* arquitetura
* ADRs
* código-fonte
* pipelines
* dashboards
* observabilidade
* métricas
* incidentes anteriores
* documentação operacional
* demais artefatos relevantes.

O Iteration Plan é a principal entrada deste processo.

⸻

Regra fundamental

Utilize somente as funcionalidades cuja coluna Decisão no Iteration Plan seja:

* Entrou

Ignore completamente funcionalidades marcadas como:

* Saiu
* Adiada
* Dividida (até que exista uma nova decisão “Entrou” para uma parte específica)
* Cancelada
* Qualquer outro status diferente de Entrou

O Reliability Plan deve assumir que apenas as funcionalidades aprovadas fazem parte da Release.

Nenhuma atividade de engenharia deve ser planejada para funcionalidades fora desse conjunto.

⸻

O que é o Reliability Plan

O Reliability Plan é o plano técnico de execução da Release.

Ele organiza todas as iniciativas necessárias para garantir que as funcionalidades aprovadas possam ser entregues com segurança.

Seu foco é:

* reduzir riscos;
* aumentar previsibilidade;
* aumentar confiabilidade;
* reduzir toil;
* melhorar operação;
* melhorar observabilidade;
* preparar a Release para produção.

⸻

O que NÃO faz parte do Reliability Plan

Não:

* altere o escopo da Release;
* inclua funcionalidades que não estejam marcadas como Entrou;
* proponha novas funcionalidades;
* repriorize backlog;
* discuta valor de negócio;
* revise decisões do Iteration Plan.

Assuma que essas decisões já foram tomadas.

⸻

Processo

Etapa 1 — Identifique o escopo aprovado

Leia o Iteration Plan.

Extraia exclusivamente as funcionalidades com decisão Entrou.

Esse conjunto passa a representar todo o escopo desta Release.

Todas as próximas análises devem considerar apenas esse conjunto.

⸻

Etapa 2 — Analise o software

Para cada funcionalidade aprovada:

* localize a implementação;
* identifique dependências;
* avalie qualidade da implementação;
* identifique débitos técnicos;
* identifique riscos arquiteturais;
* identifique integrações;
* identifique componentes compartilhados.

⸻

Etapa 3 — Avalie riscos de confiabilidade

Para cada funcionalidade aprovada, identifique riscos relacionados a:

* arquitetura;
* integração;
* disponibilidade;
* escalabilidade;
* performance;
* segurança;
* observabilidade;
* deploy;
* rollback;
* operação;
* manutenção;
* dados;
* migração.

Classifique:

* impacto;
* probabilidade;
* criticidade.

⸻

Etapa 4 — Monte o Reliability Roadmap

Defina apenas iniciativas relacionadas às funcionalidades aprovadas.

Inclua quando necessário:

* melhorias arquiteturais;
* redução de débito técnico;
* instrumentação;
* logs;
* métricas;
* tracing;
* dashboards;
* alertas;
* testes automatizados;
* testes de integração;
* testes de carga;
* feature flags;
* estratégias de rollout;
* rollback;
* automações;
* melhorias de pipeline;
* validações operacionais.

Cada iniciativa deve estar vinculada a uma ou mais funcionalidades do Iteration Plan.

Para cada iniciativa informe:

* funcionalidade relacionada;
* objetivo;
* risco mitigado;
* prioridade;
* dependências.

⸻

Etapa 5 — Quick Wins

Liste melhorias de baixo esforço e alto impacto que aumentem a confiabilidade das funcionalidades aprovadas.

⸻

Etapa 6 — Melhorias futuras

Caso sejam encontradas necessidades relacionadas a funcionalidades que não fazem parte da Release, registre-as apenas como recomendações futuras.

Elas não devem aparecer no Reliability Roadmap desta Release.

⸻

Critérios de priorização

Priorize iniciativas que:

* reduzam riscos críticos das funcionalidades aprovadas;
* aumentem previsibilidade da Release;
* reduzam impacto operacional;
* fortaleçam observabilidade;
* reduzam MTTR;
* aumentem estabilidade;
* reduzam toil;
* aumentem automação;
* fortaleçam segurança.

Sempre prefira iniciativas pequenas com alta redução de risco.

⸻

Rastreabilidade obrigatória

Toda iniciativa do Reliability Plan deve possuir rastreabilidade explícita.

Ela deve referenciar:

* a funcionalidade do Iteration Plan (status Entrou);
* o risco identificado;
* a evidência encontrada no código ou na documentação.

Não inclua iniciativas sem uma funcionalidade correspondente aprovada no Iteration Plan.

⸻

Formato esperado

Executive Summary

Resumo da confiabilidade da Release.

⸻

Funcionalidades consideradas

Liste todas as funcionalidades extraídas do Iteration Plan cuja decisão seja Entrou.

⸻

Estado atual

Resumo da implementação existente para essas funcionalidades.

⸻

Principais riscos

Tabela contendo:

* funcionalidade;
* risco;
* impacto;
* probabilidade;
* criticidade.

⸻

Análise por funcionalidade

Para cada funcionalidade aprovada:

* riscos;
* dependências;
* pontos de atenção;
* recomendações.

⸻

Reliability Roadmap

Tabela contendo:

* funcionalidade;
* iniciativa;
* objetivo;
* prioridade;
* risco mitigado;
* esforço;
* dependências.

⸻

Quick Wins

⸻

Backlog futuro

Registrar apenas melhorias relacionadas a funcionalidades que não fazem parte desta Release.

⸻

Premissas

⸻

Regras finais

* Trabalhe exclusivamente sobre funcionalidades cuja decisão seja Entrou no Iteration Plan.
* Nunca altere o Iteration Plan.
* Nunca amplie o escopo da Release.
* Nunca planeje iniciativas para funcionalidades fora da Release.
* Toda iniciativa deve possuir rastreabilidade para uma funcionalidade aprovada.
* Baseie todas as recomendações em evidências encontradas na documentação e no código.

O Reliability Plan deve ser um plano técnico totalmente alinhado ao escopo aprovado pelo negócio, garantindo que apenas as funcionalidades autorizadas para a Release recebam planejamento de engenharia, confiabilidade e operação.
