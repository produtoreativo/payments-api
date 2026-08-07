# Diligence Capabilities

Capabilities são competências reutilizáveis consumidas pelos ciclos da Diligence e pelo Bootstrap. Definem **o que é feito**, não quando nem por quem.

**Capabilities não são ciclos.** Nenhuma das Capabilities listadas aqui possui acionamento próprio independente. Elas são invocadas como sub-rotinas pelos ciclos diligence-sync, diligence-async, e pelo Bootstrap.

→ Ver [ontology.md](../../../ontology.md) para a definição canônica de Capability.
→ Ver [README.md](../README.md) para a visão geral da jornada Diligence.

---

## Catálogo de Capabilities

| Capability | Propósito resumido | Consumida por |
|---|---|---|
| Backlog Synchronization | Manter o estado do OBC consistente entre todos os níveis da hierarquia de backlogs | Capture, Promote, Repair |
| Work Item Management | Criar, atualizar e fechar Work Items com schema canônico | Attach, Close, Repair |
| Readiness Verification | Verificar pré-requisitos antes que um item avance ou entre em Delivery | Promote, Scan |
| Divergence Detection | Identificar gaps entre artefatos canônicos e ferramentas externas | Scan, Flag |
| Artifact Evolution | Atualizar artefatos de gestão quando decisões mudam o estado do trabalho | Capture, Repair, Close |
| Workspace Reconciliation | Alinhar GitHub Workspace à Canonical Specification | Bootstrap, Diligence Async, Diligence Sync |

---

## Backlog Synchronization

**Definição:** Competência responsável por manter o estado de cada OBC sincronizado entre todos os níveis da hierarquia de backlogs do ProdOps e as ferramentas externas correspondentes.

**Responsabilidade:** Garantir que o estado registrado no artefato canônico (arquivo Markdown do OBC) se reflita corretamente no Product Tracking List, Product Backlog, Icebox, Iteration Backlog, Iteration Plan e no GitHub Project.

**Entradas:**
- Estado atual do OBC (arquivo Markdown)
- Estado atual do item nos backlogs externos
- Critérios de transição por nível de backlog

**Saídas:**
- Estado sincronizado entre artefato e backlogs
- Registro de bloqueio quando critério de transição não está satisfeito
- Relatório de divergências quando há inconsistência irreconciliável automaticamente

**Ciclos consumidores:** diligence-sync (Capture, Promote), diligence-async (Repair)

**Jornadas relacionadas:** Delivery (consome backlogs sincronizados), Assessment (produz decisões que disparam sincronização), Operation (produz sinais que atualizam backlogs)

**Fontes de verdade:**
- Estado do OBC: `prodops/artifacts/obcs/`
- Hierarquia de backlogs: `prodops/framework/backlogs.md`
- Critérios de transição: `prodops/framework/artifact-governance.md`

**Limites:**
- Não prioriza o backlog — priorização é responsabilidade do Product Owner
- Não altera o estado canônico do OBC — apenas sincroniza representações derivadas
- Não cria novos níveis de backlog fora da hierarquia canônica

**Exemplos de uso:**
- OBC transitiona de Draft para Refining → Backlog Synchronization move o item para o Icebox
- OBC transiciona para Committed → Backlog Synchronization move o item para o Iteration Backlog
- Diligence Async detecta item no Iteration Plan com OBC em estado Draft → Backlog Synchronization sinaliza divergência

**Anti-padrões:**
- Mover item de backlog sem verificar critérios canônicos de transição
- Usar o GitHub Project como fonte de verdade para o estado do OBC
- Sincronizar em sentido inverso (do GitHub Project para o artefato Markdown)

---

## Work Item Management

**Definição:** Competência responsável por criar, atualizar, vincular e fechar Work Items no Execution Space, garantindo que cada Work Item respeite o schema canônico e referencie corretamente o artefato, a operação e a jornada.

**Responsabilidade:** Manter a rastreabilidade do Execution Space: cada operação ativa sobre um artefato deve ter um Work Item com schema completo; cada Work Item fechado deve registrar a entrega ou conclusão; Work Items sem referência válida devem ser identificados e corrigidos.

**Entradas:**
- Artefato de origem (OBC, Business Signal, Business Intent)
- Operação ativa identificada
- Schema canônico de Work Item

**Saídas:**
- Work Item criado com campos preenchidos: `artifact_type`, `artifact_id`, `operation`, `journey`, título canônico
- Work Item atualizado com estado e referências corretas
- Work Item fechado com referência ao Release Trail ou conclusão da operação
- Relatório de Work Items inválidos ou órfãos

**Título canônico:**

```
[Artifact ID]: descrição concisa
```

A operação e o tipo de artefato vão nos campos e labels do Issue — não no título.

**Ciclos consumidores:** diligence-sync (Attach, Close), diligence-async (Repair)

**Jornadas relacionadas:** Delivery (cria Work Items de implementação), Assessment (pode iniciar Work Items de análise), Operation (pode iniciar Work Items de resposta a incidente)

**Fontes de verdade:**
- Schema canônico: `prodops/framework/execution-mapping/work-item-schema.md`
- Cardinalidade N:M: `prodops/framework/knowledge-vs-execution.md`

**Limites:**
- Não cria Work Item para artefato passivo (sem operação ativa)
- Não mantém o mesmo Work Item indefinidamente para toda a vida do artefato — cada operação ativa tem o seu
- Não usa Issue como fonte de verdade do OBC

**Exemplos de uso:**
- Diligence Sync — Attach: OBC Committed com Delivery ativa, sem Work Item → Work Item Management cria Issue com schema completo
- Diligence Sync — Close: OBC transiciona para Operational, Release Trail confirmado → Work Item Management fecha o Issue com referência à entrega
- Diligence Async — Repair: Work Item com artifact_id inválido → Work Item Management registra divergência e escala

**Anti-padrões:**
- Criar Issue para cada artefato (viola N:M)
- Tratar ausência de Issue como divergência automática para artefatos passivos
- Reutilizar o mesmo Work Item para múltiplas operações distintas

---

## Readiness Verification

**Definição:** Competência responsável por verificar se todos os pré-requisitos canônicos estão satisfeitos antes que um item avance na hierarquia de backlogs ou entre em Delivery.

**Responsabilidade:** Garantir que nenhum item avance sem que os critérios de entrada do nível de destino estejam satisfeitos. Quando um critério não está satisfeito, bloquear a transição, registrar o bloqueio com o artefato faltante e escalar se necessário.

**Entradas:**
- Item candidato à transição
- Nível de destino na hierarquia de backlogs
- Critérios canônicos de entrada por nível
- Estado atual do OBC e artefatos associados (BDD Feature, Reliability Plan)

**Saídas:**
- Validação de pré-condição (todos os critérios satisfeitos)
- Bloqueio registrado (critério não satisfeito, artefato faltante identificado)
- Escalação (critério requer decisão humana)

**Ciclos consumidores:** diligence-sync (Promote), diligence-async (Scan — verificação preventiva)

**Jornadas relacionadas:** Delivery (beneficiária da verificação), Assessment (produz Reliability Plan e BDD quando requeridos)

**Fontes de verdade:**
- Critérios por nível: `prodops/framework/backlogs.md`
- Critérios de transição: `prodops/framework/artifact-governance.md`
- Gate condicional do Reliability Plan: `prodops/framework/backlogs.md`

**Limites:**
- Não avalia o mérito de negócio do item — apenas verifica presença e estado dos artefatos
- Não aprova OBC sozinha
- Não decide se um Reliability Plan é necessário — apenas verifica sua presença quando já foi decidido que é necessário

**Exemplos de uso:**
- Item candidato ao Iteration Plan: Readiness Verification verifica OBC Committed + BDD Feature Committed + riscos documentados
- Item com risco qualificado para Reliability Plan: Readiness Verification verifica se o Reliability Plan existe e foi revisado
- Diligence Async — Scan: item no Iteration Plan sem BDD Feature committed → Readiness Verification registra divergência

**Anti-padrões:**
- Bloquear item por ausência de Reliability Plan quando nenhum gatilho de risco foi identificado
- Exigir BDD Feature committed para entrada no Iteration Backlog (não é requisito — apenas para o Iteration Plan)
- Avançar item ignorando critérios por pressão de prazo

---

## Divergence Detection

**Definição:** Competência responsável por identificar proativamente gaps, inconsistências e divergências entre o estado canônico dos artefatos no Knowledge Space e o estado observado no Execution Space e nas ferramentas externas.

**Responsabilidade:** Detectar drift antes que ele gere confusão, retrabalho ou decisões baseadas em estado desatualizado. Distinguir ausência legítima de relação incompleta. Não reparar durante a detecção — apenas identificar e caracterizar.

**Entradas:**
- Estado atual de todos os OBCs ativos (`prodops/artifacts/obcs/`)
- Estado atual dos backlogs externos e GitHub Project
- GitHub Workspace (Labels, Fields, Views, Projects)
- Canonical Specification (`prodops/framework/github-workspace.md`)
- Work Items abertos e suas referências

**Saídas:**
- Lista de divergências com: artefato afetado, tipo de gap, severidade, natureza (ausência legítima ou relação incompleta/inválida)
- Distinção explícita entre ausência legítima e divergência real
- Identificação de itens que requerem Workspace Reconciliation

**Ciclos consumidores:** diligence-async (Scan, Flag)

**Jornadas relacionadas:** Todas as jornadas (qualquer jornada pode produzir drift que a Divergence Detection identifica)

**Fontes de verdade:**
- Estado canônico dos artefatos: `prodops/artifacts/`
- Modelo de relação artefato-Work Item: `prodops/framework/knowledge-vs-execution.md`
- Especificação do workspace: `prodops/framework/github-workspace.md`

**Limites:**
- Não repara divergências durante a detecção — reparo pertence à fase Repair
- Não classifica trilhas históricas com vocabulário antigo como divergências normativas
- Não classifica ausência de Work Item como divergência quando não há operação ativa

**Exemplos de uso:**
- OBC com estado Operational e Work Item ainda aberto → Divergence Detection identifica: Close não foi executado
- Work Item aberto com artifact_id que não corresponde a nenhum OBC ativo → Divergence Detection identifica: referência inválida
- Label canônica ausente no GitHub → Divergence Detection identifica: Workspace Drift

**Anti-padrões:**
- Classificar todo Business Signal sem Issue como divergência
- Classificar ausência de Reliability Plan como divergência quando item não tem gatilho de risco
- Marcar como divergência trilhas históricas com vocabulário de versão anterior do Framework

---

## Artifact Evolution

**Definição:** Competência responsável por atualizar artefatos de gestão (Iteration Plan, Roadmap, entradas do Product Backlog) quando decisões do Assessment, resultados do Discovery ou mudanças de estado do OBC alteram o contexto do trabalho.

**Responsabilidade:** Garantir que artefatos de gestão reflitam o estado atual do trabalho. Não reescreve conteúdo de OBCs, BDD Features ou Reliability Plans — esses são modificados apenas pelas jornadas competentes. Atualiza representações derivadas e registros de progresso.

**Entradas:**
- Decisão do Assessment ou resultado do Discovery
- Mudança de estado do OBC
- Sinal da Operation (incidente, risco, evidência)
- Artefatos de gestão atuais

**Saídas:**
- Iteration Plan atualizado (entrada, saída, status)
- Roadmap atualizado (estado do item, datas, decisões)
- Product Backlog atualizado (estado do item)
- Registro de decisão no artefato correspondente

**Ciclos consumidores:** diligence-sync (Capture, Close), diligence-async (Repair)

**Jornadas relacionadas:** Assessment (produz decisões que disparam evolução), Discovery (produz resultados que disparam evolução), Operation (produz sinais que disparam evolução), Delivery (consome artefatos evoluídos)

**Fontes de verdade:**
- Iteration Plan: `prodops/exec/iteration-plans/`
- Roadmap: arquivo correspondente em `prodops/exec/`
- OBC: `prodops/artifacts/obcs/`

**Limites:**
- Não reescreve conteúdo de OBCs — apenas atualiza representações derivadas e metadados de gestão
- Não inventa conteúdo de artefato — registra apenas o que foi decidido pela jornada competente
- Não toma decisões sobre o estado do OBC — apenas registra as decisões já tomadas

**Exemplos de uso:**
- Assessment decide Reliability Plan necessário → Artifact Evolution registra a decisão no Iteration Plan e atualiza o campo correspondente
- OBC transiciona para Operational → Artifact Evolution atualiza a entrada no Roadmap com data de conclusão
- Discovery conclui experimento com decisão de descontinuar → Artifact Evolution atualiza o status do item no Product Backlog

**Anti-padrões:**
- Reescrever critérios de sucesso do OBC durante sincronização
- Atualizar o Iteration Plan com informações não confirmadas por nenhuma jornada
- Usar Artifact Evolution para corrigir decisões de Assessment que o agente considera incorretas

---

## Workspace Reconciliation

**Definição:** Competência responsável por alinhar o GitHub Workspace (Labels, Custom Fields, Views, projetos gerenciados) à Canonical Specification, detectando e corrigindo Workspace Drift.

**Classificação: Capability — não é um Cycle, não é uma Phase de nenhum Cycle.**

Esta Capability é invocada como sub-rotina. Não possui acionamento próprio. Retorna um Conformance Report ao chamador.

→ **Ver especificação completa em [workspace-reconciliation.md](../workspace-reconciliation.md)**

**Responsabilidade:** Manter a infraestrutura do GitHub Workspace conforme a Canonical Specification, para que os ciclos da Diligence e a Delivery possam operar sobre campos, labels e projetos consistentes.

**Entradas:**
- Canonical Specification (`prodops/framework/github-workspace.md`)
- Estado atual do GitHub Workspace (lido via API)

**Saídas:**
- Drift Report (Inspect)
- Correções aplicadas (Reconcile)
- Conformance Report: CONFORME / PARCIAL / NÃO CONFORME (Verify)

**Steps internos (não são Phases de Cycle):** Inspect → Reconcile → Verify

**Ciclos consumidores:** Bootstrap, diligence-async (Repair), diligence-sync (Attach, Promote quando necessário)

**Jornadas relacionadas:** Delivery (depende de labels e campos para Work Items), Diligence (depende de infraestrutura para operar), Bootstrap (pré-condição de novos repositórios)

**Fontes de verdade:**
- Canonical Specification: `prodops/framework/github-workspace.md`
- Sync manifest: `prodops/artifacts/trails/github-sync-manifest.md` (criado pelo produto)

**Limites:**
- Não opera em projetos manuais (fora do escopo `ProdOps — `)
- Inspect não modifica nada — leitura pura
- Reconcile nunca remove sem confirmação
- Não altera conteúdo de artefatos do Knowledge Space

**Exemplos de uso:**
- Bootstrap de novo repositório: Workspace Reconciliation garante infraestrutura pronta antes de qualquer Delivery
- Diligence Async detecta label canônica ausente: Workspace Reconciliation invocada pelo Repair
- Diligence Sync — Attach falha por campo obrigatório ausente: Workspace Reconciliation invocada antes de retomar Attach

**Anti-padrões:**
- Invocar Workspace Reconciliation como ciclo independente (não tem acionamento próprio)
- Confundir os steps internos Inspect/Reconcile/Verify com Phases de um Cycle da Diligence
- Usar Workspace Reconciliation para corrigir conteúdo de OBCs ou Work Items
