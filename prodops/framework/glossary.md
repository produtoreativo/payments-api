# ProdOps Glossary

Termos canônicos do Framework ProdOps. Um conceito = um nome. Um nome = um conceito.

Para o fluxo completo do Framework, ver [`flow.md`](flow.md).
Para os quatro Origin Streams, ver [`origin-streams.md`](origin-streams.md).
Para a hierarquia de backlogs, ver [`backlogs.md`](backlogs.md).

---

## Arquitetura do ProdOps

Os quatro níveis hierárquicos que compõem o ecossistema ProdOps. Ver [operating-model.md](operating-model.md#arquitetura-do-prodops) para o diagrama completo.

---

## Framework (ProdOps Framework)

**Definição:** O sistema canônico de princípios, jornadas, capabilities, skills, templates, padrões, contratos e glossário que define como o ProdOps funciona. Vive em um repositório dedicado de referência.

**Propósito:** Ser a fonte única de verdade sobre como trabalhar com ProdOps — independente de qual produto, portfolio ou workspace o está usando.

**Contém:** Princípios, glossário, fluxo oficial, Origin Streams, modelo operacional, jornadas, skills, templates, Delivery Capabilities.

**Não contém:** Roadmap, Backlogs, Business Intents, Releases, Features de produto.

**Relação com outros conceitos:** O Framework é o nível superior da hierarquia. Portfolio, Workspace e Product Repositories o adotam e o estendem com seus próprios artefatos.

---

## Portfolio

**Definição:** O nível de gestão da plataforma ProdOps. Responsável por coordenar múltiplos produtos, definir prioridades e gerenciar versões da plataforma.

**Propósito:** Decidir o que a plataforma entrega, quando e em que sequência — sem implementar software diretamente.

**Contém:** Global Tracking List, Business Intent Backlog, Roadmaps, Platform Releases, Milestones.

**Não contém:** Implementação de software, OBCs de produto, BDD Features de produto.

**Relação com outros conceitos:** O Portfolio está entre o Framework (que define as regras) e os Workspaces (que executam). Um Roadmap de Portfolio coordena Product Repositories. Ver **Platform Release**.

---

## Workspace

**Definição:** O nível de integração entre produtos. Responsável por executar e testar múltiplos Product Repositories em conjunto.

**Propósito:** Garantir que produtos que dependem uns dos outros funcionem corretamente de forma integrada. Um Workspace não possui Roadmap nem Business Intents — existe exclusivamente para integração.

**Exemplos:** Checkout Workspace (webshop-api + payments-api + order-mgmt-api).

**Não contém:** Roadmap, Business Intents, código de produto.

**Relação com outros conceitos:** Um Workspace é coordenado pelo Portfolio e integra Product Repositories. Ver **Product Repository**.

---

## Product Repository

**Definição:** O nível de implementação e operação de um produto específico dentro da arquitetura ProdOps. Este repositório (`payments-api`) é um Product Repository.

**Propósito:** Implementar Product Capabilities, operar o produto em produção e manter a rastreabilidade completa de Intents até evidências de operação.

**Contém:** OBCs, BDD Features, Iteration Plans, Reliability Plans, Release Trail, código do produto, runbooks, postmortems.

**Relação com outros conceitos:** Um Product Repository adota o Framework, participa de Roadmaps definidos pelo Portfolio e é integrado por Workspaces. Pode também evoluir localmente por meio de seu próprio fluxo de Intents.

---

## Platform

**Definição:** O conjunto de Product Repositories coordenados pelo Portfolio e integrados pelos Workspaces. A plataforma é o produto composto — o que o cliente final experimenta.

**Relação com outros conceitos:** A Platform é o resultado da coordenação entre Portfolio, Workspaces e Product Repositories. Ver **Portfolio**, **Workspace**, **Product Repository**.

---

## Platform Release

**Definição:** Uma versão da plataforma coordenada pelo Portfolio, que inclui contribuições de múltiplos Product Repositories e é validada em nível de Workspace.

**Propósito:** Marcar um ponto de entrega coerente da plataforma como um todo — não apenas de um produto isolado.

**Distinção:** Uma Platform Release é diferente de um release local de um único Product Repository. O release local (gerenciado pelo CI Async do repositório) contribui para uma Platform Release, mas não a substitui.

**Relação com outros conceitos:** Gerenciado pelo Portfolio. Composto por releases de múltiplos Product Repositories. Ver **Portfolio**, **Roadmap**.

---

## Roadmap

**Definição:** Planejamento de Product Capabilities ao longo do tempo, gerenciado pelo Portfolio. Um Roadmap define o que a plataforma entregará, em que ordem e em qual Platform Release.

**Propósito:** Comunicar prioridades e horizonte de entrega da plataforma para stakeholders, times e parceiros.

**Quem gerencia:** O Portfolio. Product Repositories participam de Roadmaps mas não os definem.

**Não confundir com:** Iteration Plan (planejamento de uma iteração dentro de um Product Repository) ou Icebox (candidatos ainda não priorizados).

**Relação com outros conceitos:** O Roadmap é gerenciado pelo Portfolio e orienta quais Intents de quais Product Repositories serão priorizadas. Ver **Portfolio**, **Platform Release**, **Intent**.

---

## Origin Stream

**Definição:** Classificação da origem de uma Intent. Identifica de onde a necessidade nasceu e quem a detém.

**Propósito:** Garantir que toda mudança tenha origem rastreável e que o contexto, a linguagem e os critérios de sucesso sejam apropriados para o tipo de necessidade.

**Quando usar:** Ao registrar qualquer Intent. Toda Intent tem exatamente um Origin Stream.

**Quando não usar:** Origin Stream não determina o modo de execução nem a jornada — isso é função do Execution Mode e do Continuous Assessment.

**Os quatro Origin Streams:** Business | Enterprise | Team | Technology

**Relação com outros conceitos:** Um Origin Stream gera uma Intent. A Intent entra em Exploration. Ver [`origin-streams.md`](origin-streams.md).

---

## Intent

**Definição:** Uma intenção de gerar valor ainda não comprometida com implementação. É o ponto de entrada único do Framework ProdOps para qualquer mudança.

**Propósito:** Registrar formalmente uma necessidade antes de qualquer decisão de execução. A Intent captura o "porquê" sem prescrever o "como".

**Quando usar:** Sempre que uma nova necessidade surgir — independente de origem, tamanho ou urgência. Toda mudança começa com uma Intent.

**Quando não usar:** Intent não é backlog técnico, tarefa de sprint ou ticket de bug isolado. Essas são instâncias de execução derivadas de uma Intent, não Intents em si.

**Ciclo de vida:** A Intent nasce na Global Tracking List ou Repository Tracking List como um sinal ainda não compreendido. Quando investigada e reconhecida como relevante, entra no Business Intent Backlog (fluxo global) ou no Product Intent Backlog (fluxo local) — momento em que seu OBC é criado como Draft. A partir daí, o OBC torna-se o identificador permanente do trabalho.

**Relação com outros conceitos:** A Intent tem um Origin Stream (Business | Enterprise | Team | Technology). A Intent é transformada em OBC pela Exploration. Ver [`flow.md`](flow.md), [`origin-streams.md`](origin-streams.md) e [`backlogs.md`](backlogs.md).

**Anteriormente chamado de:** Business Intent. O nome foi simplificado para Intent para eliminar a ambiguidade de que apenas necessidades de "Business" são capturáveis. O diretório `prodops/business-intents/` é preservado por retrocompatibilidade.

---

## Estágio de Produto

**Definição:** Classificação do momento de maturidade de um produto dentro do ciclo de vida ProdOps. Define quais métricas de delivery têm maior peso e qual é o foco do time naquele período.

**Os seis estágios em ordem:** PoC → MVP → IPR → MVR → MVT → MLP

**Duas macro-fases:**
- **Validação de Hipóteses** (PoC, MVP, IPR): provar que a ideia é viável antes de escalar
- **Aceleração** (MVR, MVT, MLP): crescer com repeatibilidade, tração e encantamento

**Relação com outros conceitos:** O estágio influencia os pesos das métricas DORA e o foco do Reliability Plan. Ver [`product-stages.md`](product-stages.md) e [`dora-metrics.md`](dora-metrics.md).

---

## PoC (Proof of Concept)

**Definição:** Primeiro estágio de produto. Valida se uma ideia ou abordagem é viável junto a um **cliente real**.

**Característica central:** O cliente sempre está envolvido. Sem cliente, não é PoC — é Spike Solution.

**Relação com outros conceitos:** Ver **Estágio de Produto**, **Spike Solution** e [`product-stages.md`](product-stages.md).

---

## DORA Metrics (Extended)

**Definição:** Modelo de 7 métricas de saúde de delivery adotado pelo ProdOps para avaliar maturidade de entrega. Expande as 4 métricas originais do DORA Research Program com 3 extensões orientadas a produto e operação.

**As 7 métricas:**

| Métrica | Tipo | O que mede |
|---|---|---|
| **Lead Time for Change** | DORA Core | Tempo do commit até produção |
| **Release Frequency** | DORA Core | Frequência de deploys |
| **Change Fail Rate** | DORA Core | % de mudanças que causam falha |
| **Mean Time to Recovery** | DORA Core | Tempo médio de recuperação após falha |
| **Reaction Time** | Extensão ProdOps | Tempo entre sinal externo e primeira ação processada |
| **Rate of Return** | Extensão ProdOps | Defeitos escapados e rework — retentativas, estornos |
| **Availability** | Extensão ProdOps | Uptime operacional do serviço |

**Pesos por estágio:** cada estágio de produto define pesos 1–8 para cada métrica. Nos estágios iniciais (PoC/MVP), Lead Time e Reaction Time têm peso máximo. Nos avançados (MVT/MLP), Change Fail Rate, MTTR e Availability dominam.

**Relação com outros conceitos:** Ver [`dora-metrics.md`](dora-metrics.md), [`product-stages.md`](product-stages.md). Assessment de maturidade executado na plataforma Certificare.

---

## Maturity Level (Delivery)

**Definição:** Escala de maturidade de delivery do ProdOps, de 0 a 5. Usada pelo Certificare para posicionar o produto e gerar roadmap de melhoria.

| Nível | Nome | Descrição |
|---|---|---|
| 0 | Inexistente | Nenhuma prática estabelecida |
| 1 | Inicial | Práticas ad-hoc, sem repetibilidade |
| 2 | Repetível | Práticas básicas sem sistematização |
| 3 | Definido | Processos documentados e seguidos |
| 4 | Gerenciado | Métricas coletadas e usadas para decisões |
| 5 | Excelência | Otimização contínua baseada em dados |

**Estratégia top-down:** começa no nível 5 e desce no primeiro critério obrigatório não satisfeito.

**Relação com outros conceitos:** Ver [`dora-metrics.md`](dora-metrics.md).

---

## Spike Solution

**Definição:** Investigação técnica com prazo definido cuja única saída é uma decisão — não um produto, não código entregável. Responde uma única pergunta técnica específica que bloqueia progresso.

**Característica central:** Nunca há cliente envolvido. Se há cliente, é PoC. Código é sempre descartável.

**Quando usar:** Qualquer estágio de produto, qualquer fase de experimento — inclusive dentro de um PoC ou de qualquer jornada Upstream.

**Diferença crítica em relação ao PoC:**

| | PoC | Spike Solution |
|---|---|---|
| Cliente envolvido | Sempre | Nunca |
| Objetivo | Validar com feedback real | Responder pergunta técnica |
| Código | Pode ser demonstrável | Sempre descartável |

**Onde registrar:** `prodops/journeys/discovery/spikes.md` (se isolado) ou `upstream-trail.md` do experimento (se dentro de um Upstream ativo).

**Relação com outros conceitos:** Ver **PoC**, **Estágio de Produto**, [`product-stages.md`](product-stages.md) e [`../journeys/discovery/spikes.md`](../journeys/discovery/spikes.md).

---

## Concepção

**Definição:** Fase que compreende o período desde o surgimento do sinal até a entrada no Product Intent Backlog. A Intent existe como possibilidade — o Product Owner ainda não assumiu compromisso.

**Pergunta central:** Existe valor real aqui?

**Backlogs:** Global Tracking List / Repository Tracking List → Business Intent Backlog (fluxo global).

**Estado do OBC:** Não existe nas Tracking Lists. Nasce como Draft ao entrar no Business Intent Backlog (fluxo global). No fluxo local, nasce como Draft apenas ao entrar no PIB.

**Compromisso:** Nenhum. A Intent pode ser descartada sem registro formal de aprendizado.

**Fronteira de saída:** Owner Approval — entrada no Product Intent Backlog (início da Inception).

**Relação com outros conceitos:** Ver [`phases.md`](phases.md), [`backlogs.md`](backlogs.md).

---

## Inception

**Definição:** Fase que compreende o período desde a entrada no Product Intent Backlog até o OBC atingir o estado Minimum OBC (Iteration Backlog). O Product Owner assumiu compromisso formal de investigação.

**Pergunta central:** O Product Owner está comprometendo atenção e capacidade para investigar isso agora?

**Backlogs:** Product Intent Backlog → Icebox → Iteration Backlog.

**Estado do OBC:** Draft → Draft em refinamento (Icebox) → Minimum OBC (Iteration Backlog).

**Compromisso:** Formal. Qualquer encerramento exige registro de aprendizado rastreável no OBC.

**Modo de execução:** Upstream (alta incerteza) ou Downstream (clareza suficiente), definido pelo Product Owner ao aceitar a Intent no PIB.

**Fronteira de saída:** Assessment Review aprovada, OBC em estado Minimum OBC, BDD Feature committed — entrada no Iteration Backlog.

**Relação com outros conceitos:** Ver [`phases.md`](phases.md), [`backlogs.md`](backlogs.md).

---

## Business (Origin Stream)

**Definição:** Origin Stream que representa necessidades geradas pelo mercado, pelo cliente ou pelas oportunidades de crescimento do produto.

**Propósito:** Capturar Intents orientadas a resultado de mercado — receita, conversão, adoção, retenção, novos canais, novos produtos.

**Quando usar:** A necessidade tem relação direta com valor percebido pelo cliente ou pelo mercado.

**Quando não usar:** Se o benefício é interno à organização (Enterprise), ao processo do time (Team) ou à plataforma técnica (Technology).

**Exemplos:** Split Payment (Pix + Cartão), novo canal Boleto, suporte a recorrência de assinaturas.

**Relação com outros conceitos:** Um dos quatro Origin Streams. Ver [`origin-streams.md`](origin-streams.md).

---

## Enterprise (Origin Stream)

**Definição:** Origin Stream que representa necessidades internas da organização — compliance, legislação, auditoria, parceiros, ERP, financeiro, backoffice, governança, riscos corporativos.

**Propósito:** Capturar Intents obrigatórias por razões externas ao produto — leis, regulações, contratos, políticas corporativas.

**Quando usar:** A necessidade é imposta por fora do produto ou resolve um problema de escala operacional interna.

**Quando não usar:** Se o benefício é para o cliente (Business), para o processo do time (Team) ou para a plataforma (Technology).

**Exemplos:** Adequação à regulação do Banco Central, integração com ERP financeiro, política de retenção de dados LGPD.

**Relação com outros conceitos:** Um dos quatro Origin Streams. Ver [`origin-streams.md`](origin-streams.md).

---

## Team (Origin Stream)

**Definição:** Origin Stream que representa necessidades geradas pelo próprio time de produto e engenharia para evoluir a forma de trabalhar, os processos, as ferramentas e a qualidade operacional.

**Propósito:** Capturar Intents de melhoria interna do modelo operacional — produtividade, onboarding, fluxo de trabalho, automações.

**Quando usar:** A necessidade é sobre como o time trabalha, não o que o time entrega ao mercado.

**Quando não usar:** Se o benefício é para o cliente (Business), para a organização (Enterprise) ou para a plataforma técnica (Technology).

**Exemplos:** Adoção de Conventional Commits, criação de skill de Bootstrap, documentação do Commit Workflow.

**Relação com outros conceitos:** Um dos quatro Origin Streams. Ver [`origin-streams.md`](origin-streams.md).

---

## Technology (Origin Stream)

**Definição:** Origin Stream que representa necessidades geradas pela evolução das capacidades técnicas da plataforma, da segurança, da infraestrutura e da confiabilidade do sistema.

**Propósito:** Capturar Intents de evolução técnica — arquitetura, segurança, infraestrutura, observabilidade, confiabilidade, cloud, banco de dados, Kubernetes, serverless, IAM, criptografia.

**Quando usar:** A necessidade é técnica e o benefício primário é para o sistema — não diretamente para o cliente ou para a organização.

**Quando não usar:** Se a melhoria técnica é consequência de um requisito de produto (Business), corporativo (Enterprise) ou de processo (Team).

**Exemplos:** Migração para DynamoDB, rotação automática de credenciais, adoção de OpenTelemetry, criptografia em repouso.

**Relação com outros conceitos:** Um dos quatro Origin Streams. Ver [`origin-streams.md`](origin-streams.md).

---

## OBC (Observable Business Contract)

**Definição:** O contrato vivo que representa uma intenção de negócio durante todo o seu ciclo de vida. É a fonte de verdade do trabalho — conecta negócio, produto, arquitetura, engenharia, operação, observabilidade e confiabilidade.

**Estados:** Draft → Minimum OBC → Active → Operational → Archived.

**Criação:** Nasce quando uma Intent é aceita. No fluxo global, ao entrar no Business Intent Backlog. No fluxo local, ao entrar no Product Intent Backlog.

**Relação com outros conceitos:** Âncora a BDD Feature, o Iteration Plan, o Reliability Plan e toda a Delivery. A Diligence mantém o estado do OBC sincronizado entre backlogs e ferramentas.

→ **Definição completa, composição, ciclo de vida e governança:** [`obc.md`](obc.md)

---

## Exploration

**Definição:** Etapa que refina o OBC draft — nascido no Business Intent Backlog ou Product Intent Backlog — reduzindo incerteza e transformando hipóteses em conhecimento validado. A maior parte do refinamento ocorre durante o Icebox.

**Propósito:** Garantir que o OBC seja construído sobre entendimento real, não sobre suposições. Sem Exploration suficiente, o OBC é frágil.

**Quando usar:** Sempre que a Intent tiver hipóteses não validadas, decisões de domínio em aberto ou incerteza técnica que justifique exploração antes do compromisso.

**Quando não usar:** Quando a Intent é trivial, o comportamento já é bem compreendido e o OBC pode ser escrito diretamente. Neste caso, a Exploration é curta ou inexistente.

**Relação com outros conceitos:** Exploration é realizada pela jornada Discovery em ambos os modos. Discovery descreve a jornada; Upstream ou Downstream define compromisso e rigor.

| Termo | Nível | Significado |
|---|---|---|
| **Exploration** | Etapa do fluxo | O que acontece: redução de incerteza entre Intent e OBC |
| **Discovery** | Jornada | O nome da jornada do Framework que implementa Exploration |
| **Upstream / Downstream** | Execution Mode | O compromisso e o rigor aplicados durante Discovery |

Ver [`flow.md`](flow.md), [`../journeys/discovery/README.md`](../journeys/discovery/README.md) e [`../execution-model/upstream.md`](../execution-model/upstream.md).

---

## Discovery

**Definição:** Jornada do Framework ProdOps que implementa a etapa de Exploration. Fluxo de engenharia exploratória orientado a aprendizado.

**Propósito:** Transformar hipóteses em conhecimento validado por meio de experimentos, spikes e protótipos. Produzir o Decision Package que fundamenta o OBC.

**Quando usar:** Ao explorar uma Intent em Upstream ou Downstream, com o rigor correspondente ao modo.

**Quando não usar:** Discovery não é sinônimo de Upstream e não determina, sozinha, se haverá entrega.

**Relação com outros conceitos:** Discovery é a jornada que implementa Exploration e existe nos modos Upstream e Downstream. Ver [`../journeys/discovery/README.md`](../journeys/discovery/README.md).

---

## Delivery Capability

**Definição:** Competência técnica reutilizável consumida pelas fases da jornada Delivery. Exemplos: Commit Workflow, Contract Management, Evidence Management, Observability, Reliability.

**Propósito:** Encapsular práticas técnicas transversais que podem ser invocadas por múltiplas fases sem duplicação.

**Quando usar:** Ao referenciar a infraestrutura técnica do processo de entrega.

**Quando não usar:** Não confundir com "Product Capability". Uma Delivery Capability é um mecanismo do Framework, não uma funcionalidade do produto.

**Relação com outros conceitos:** Usada pelas Phases da jornada Delivery. Ver [`../journeys/delivery/capabilities/`](../journeys/delivery/capabilities/).

---

## Product Capability

**Definição:** Uma funcionalidade, comportamento ou característica do produto que está sendo explorada ou entregue. Exemplos: split payment, suporte a Pix, webhook de confirmação.

**Propósito:** Denominar o escopo de trabalho de produto que uma Intent origina e que um OBC descreve.

**Quando usar:** Ao referenciar o que está sendo construído — a funcionalidade, o comportamento, o valor de produto.

**Quando não usar:** Não confundir com "Delivery Capability". Uma Product Capability é o objeto do trabalho; uma Delivery Capability é um mecanismo do processo.

**Nota:** Em contextos onde a ambiguidade for possível, preferir o termo completo "Product Capability" ou "Delivery Capability" em vez de apenas "capability".

---

## BDD Feature

**Definição:** Especificação Gherkin que descreve o comportamento esperado de uma Product Capability. Fica em `prodops/artifacts/bdd/` (comprometida) ou `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (exploratória — dentro do diretório do experimento). Usada como insumo de TDD no Downstream.

---

## Reliability Plan

**Definição:** Produto da jornada transversal de Assessment que define riscos, SLOs e ações de mitigação para um item comprometido. Fica em `prodops/journeys/assessment/reliability-plans/`.

**Obrigatoriedade:** Recomendado, não obrigatório. Fortemente recomendado para itens com risco operacional relevante (complexidade técnica alta, impacto financeiro, novos domínios ou integrações externas). Quando existe, deve ser revisado antes da decisão de readiness do Iteration Plan.

**No fluxo local (pré-PIB):** O Premortem é o artefato adequado para análise de risco antes do Owner Approval. O Reliability Plan formal é produzido durante o Icebox, após o compromisso do Product Owner.

---

## Global Tracking List

**Definição:** Backlog de plataforma que captura qualquer sinal ainda não compreendido o suficiente para ser tratado como uma Intent formal. Gerenciado pelo Portfolio.

**Pergunta:** O que merece atenção na plataforma?

**Não contém:** OBC. Compromisso. Identificador permanente.

**Relação com outros conceitos:** Primeiro nível do fluxo global. Itens avançam para o Business Intent Backlog quando reconhecidos como Intent. Ver [`backlogs.md`](backlogs.md).

---

## Business Intent Backlog

**Definição:** Backlog de plataforma que representa Intents aceitas para Discovery. O OBC nasce como Draft ao entrar neste backlog. Gerenciado pelo Portfolio.

**Pergunta:** O que merece Discovery?

**Relação com outros conceitos:** Segundo nível do fluxo global. O OBC Draft nasce aqui. Itens avançam para o Roadmap. Ver [`backlogs.md`](backlogs.md).

---

## Repository Tracking List

**Definição:** Backlog de produto que captura qualquer sinal local ainda não compreendido o suficiente para ser tratado como um compromisso formal. Artefato: `prodops/artifacts/product/tracking-list.md`.

**Pergunta:** O que merece atenção neste produto?

**Não contém:** OBC. Compromisso. Identificador permanente.

**Relação com outros conceitos:** Primeiro nível do fluxo local. Itens avançam via Premortem + Análise de Risco Preliminar + Owner Approval para o Product Intent Backlog. (O Reliability Plan formal é produzido depois, durante o Icebox — é recomendado, não obrigatório para entrar no PIB.) Ver [`backlogs.md`](backlogs.md).

---

## Product Intent Backlog

**Definição:** Backlog de produto que representa todo trabalho formalmente aceito pelo Product Owner. Ponto de entrada único do produto para o ciclo de Delivery — independente de onde o item veio (Portfolio ou fluxo local). Se o item ainda não tem OBC Draft, ele é criado ao entrar neste backlog.

**Pergunta:** O que foi oficialmente aceito pelo Product Owner?

**Dois caminhos de entrada:** (1) Business Intent do Portfolio via Platform Release; (2) Repository Tracking Item via Premortem + Análise de Risco Preliminar com Owner Approval.

**Após a entrada, a origem deixa de importar.** Todos os itens seguem a mesma jornada: Icebox → Iteration Backlog → Iteration Plan → Delivery.

**Relação com outros conceitos:** Ponto de convergência dos fluxos global e local. Ver [`backlogs.md`](backlogs.md).

---

## Icebox

**Definição:** Backlog de produto que representa itens comprometidos ainda sendo preparados para Delivery. O Discovery funcional, técnico e operacional necessário ocorre aqui. Objetivo: produzir um OBC mínimo aceitável. Artefato: `prodops/artifacts/product/icebox-backlog.md`.

**Pergunta:** O que ainda está sendo preparado para Delivery?

**Relação com outros conceitos:** Recebe itens do Product Intent Backlog. Itens avançam para o Iteration Backlog após OBC mínimo validado. Ver [`backlogs.md`](backlogs.md).

---

## Iteration Backlog

**Definição:** Backlog de produto que representa itens com OBC mínimo validado, prontos para Delivery imediata. Não é um backlog de refinamento — refinamento acontece no Icebox. A única decisão restante é a prioridade do Product Owner. Artefato: `prodops/artifacts/plans/iteration-backlog.md`.

**Pergunta:** O que está pronto para ser desenvolvido?

**Relação com outros conceitos:** Recebe itens do Icebox. Itens avançam para o Iteration Plan após OBC committed + BDD Feature committed. Ver [`backlogs.md`](backlogs.md).

---

## Iteration Plan

**Definição:** Registro da execução de Delivery de uma iteração. Não é um backlog de planejamento — representa exclusivamente a execução em andamento. Contém itens do Iteration Backlog, estratégia de execução, jornadas CI Sync e CI Async, evidências e critérios de saída. Artefato: `prodops/artifacts/plans/iteration-plan.md`.

**Pergunta:** O que está sendo executado nesta iteração?

**Relação com outros conceitos:** Recebe itens do Iteration Backlog com OBC committed + BDD committed. É o último backlog antes de Delivery. Ver [`backlogs.md`](backlogs.md).

---

## CI Sync

**Definição:** O agrupamento síncrono do ProdOps Delivery. Representa o trabalho local, colaborativo e conduzido pelo engenheiro. Inclui Bootstrap, Hack, Sync e Finish. Produz: task fechada, PR com narrativa, evidências, commits organizados, validações locais executadas. Ver [`journeys/delivery/README.md`](../journeys/delivery/README.md).

---

## CI Async

**Definição:** O agrupamento assíncrono do ProdOps Delivery. Representa o trabalho conduzido pela plataforma, pipelines e ambientes. Inclui Ship, Validate e Promote. Produz: artefato publicado, deploy realizado, validação em runtime, promoção controlada. Ver [`journeys/delivery/README.md`](../journeys/delivery/README.md).

---

## Bootstrap

**Definição:** O primeiro estágio do CI Sync. Instala dependências, prepara infraestrutura local, verifica configuração e executa o smoke gate. Não lê código, testes ou artefatos de produto e não cria branch; Git flow pertence ao Hack Start. Ver [`journeys/delivery/phases/bootstrap/README.md`](../journeys/delivery/phases/bootstrap/README.md).

---

## Upstream

**Definição:** Modo permissivo, experimental e sem compromisso de entrega. Pode usar todas as jornadas com maturidade variável; código é descartável até ser promovido. Não é sinônimo de Discovery. Ver [`prodops/journeys/discovery/README.md`](../journeys/discovery/README.md).

---

## Downstream

**Definição:** Modo com compromisso de entrega que aplica todos os quality gates vigentes em todas as jornadas. Guia o item e para em cada lacuna até atingir readiness; então executa o fluxo completo `Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote`. Ver [`prodops/execution-model/downstream.md`](../execution-model/downstream.md).

---

## Hack Flow

**Definição:** A fase de codificação em Upstream e Downstream. Segundo estágio do CI Sync, sucede o Bootstrap. Definido em [`journeys/delivery/phases/hack/README.md`](../journeys/delivery/phases/hack/README.md). Mecânica de execução em [`skills/hack/`](../skills/hack/).

---

## Sync

**Definição:** O terceiro estágio do CI Sync. Tem dois steps independentes: `rebase` (sincroniza a feature branch com a base — fetch, integração, conflitos, validação) e `align` (alinha artefatos ProdOps com a implementação — BDD Features, Event Storming, arquitetura, Release Trail). Invocados via `/sync rebase` e `/sync align`. Ver [`journeys/delivery/phases/sync/README.md`](../journeys/delivery/phases/sync/README.md).

---

## Ship

**Definição:** O primeiro estágio do CI Async. Transforma a implementação finalizada em artefato executável e conduz o deploy. Organizado em duas famílias: Preparation (Build, Package, Version, Sign, SBOM, Publish Artifact) e Deployment (Deploy, Progressive Delivery, Feature Flags, Rollout, Rollback, Infrastructure Validation). Build, Package e Publish são capabilities internas do Ship — não são etapas independentes do fluxo principal. Ver fases: [Ship](../journeys/delivery/phases/ship/README.md), [Validate](../journeys/delivery/phases/validate/README.md), [Promote](../journeys/delivery/phases/promote/README.md).

---

## Validate

**Definição:** O segundo estágio do CI Async. Verifica a entrega em execução no ambiente alvo. Capabilities: Smoke Tests, Runtime Contract Validation, Synthetic Monitoring, Health Checks, Observability Validation, SLO Validation, Business Validation, Incident Signals. Ver fases: [Ship](../journeys/delivery/phases/ship/README.md), [Validate](../journeys/delivery/phases/validate/README.md), [Promote](../journeys/delivery/phases/promote/README.md).

---

## Promote

**Definição:** O terceiro estágio do CI Async. Oficializa a evolução da versão com aprovação formal e evidência registrada. Capabilities: Promotion Gates, Environment Promotion, Release Approval, Release Trail, Operational Evidence, Release Documentation, Rollback Readiness. Ver fases: [Ship](../journeys/delivery/phases/ship/README.md), [Validate](../journeys/delivery/phases/validate/README.md), [Promote](../journeys/delivery/phases/promote/README.md).

---

## ProdOps TDD

**Definição:** A prática utilizada dentro do Hack Flow para produzir código observável e confiável. Definida em [`journeys/delivery/practices/prodops-tdd.md`](../journeys/delivery/practices/prodops-tdd.md).

---

## Red Bar

**Definição:** Teste com falha que expressa corretamente o comportamento desejado. Confirma que o teste detecta a implementação ausente.

---

## Green Bar

**Definição:** Teste passando após a implementação mínima estar em vigor.

---

## Yellow Bar

**Definição:** Padrões usados para gerenciar cenários de teste difíceis: child tests, crash dummies, log strings. Não é uma licença para mockar lógica de negócio.

---

## Progressive Substitution

**Definição:** Estratégia de teste onde um Mock Server (baseado em contrato) é usado primeiro, depois substituído pela integração real sem reescrever os testes. Os testes verificam comportamento pela mesma superfície de contrato independentemente do que está por trás.

---

## Mock Server

**Definição:** Test double em nível de infraestrutura que simula uma dependência externa com base em um contrato (ex.: WireMock, Prism). Distinto do Mock Object, que substitui um serviço próprio.

---

## Mock Object

**Definição:** Test double para uma dependência técnica (logger, clock, gerador de UUID, adaptador de telemetria). Aceitável apenas quando não oculta comportamento de negócio.

---

## Decision Trail

**Definição:** Registro de uma decisão tomada sob incerteza, incluindo contexto, alternativas e impacto. Template: [`prodops/templates/assessment/decision-trail.md`](../templates/assessment/decision-trail.md).

---

## Release Trail

**Definição:** O log append-only de evidências do Downstream. Cada sessão de agente produz seu próprio arquivo em `prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.md`. Ver modelo em [`artifacts/trails/release-trail.md`](../artifacts/trails/release-trail.md).

---

## Diligence

**Definição:** Jornada transversal do Framework ProdOps responsável por manter o sistema de trabalho sincronizado e consistente ao longo do ciclo de vida do produto.

**Propósito:** Fechar o gap entre as decisões produzidas pelo Assessment e o trabalho pronto para a Delivery. Garantir que o estado de cada OBC permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão.

**Princípio:** A Diligence é a guardiã da consistência do sistema de trabalho do ProdOps. Ela garante que o estado de cada Observable Business Contract permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão, sem modificar o código do produto.

**Quando usar:** Continuamente. A Diligence não tem início e fim por ciclo — acompanha o produto enquanto ele existir. É ativada por novos riscos, incidentes, postmortems, mudanças estratégicas ou divergências detectadas entre artefatos.

**O que não faz:** Não implementa software. Não cria Pull Requests de implementação. Não modifica código do produto. Não toma decisões de produto que competem ao Assessment.

**Relação com outros conceitos:** Jornada transversal. Consome artefatos do Assessment e alimenta a Delivery com trabalho organizado e rastreável. Ver [`../journeys/diligence/README.md`](../journeys/diligence/README.md) e [`backlogs.md`](backlogs.md).

---

## GitHub Issue

**Definição:** Representação operacional de um compromisso já assumido no Framework ProdOps. Não é a origem do trabalho.

**Propósito:** Tornar visível e gerenciável, em uma ferramenta de gestão, um OBC que já entrou no Product Intent Backlog ou no Iteration Plan.

**Quando usar:** Normalmente quando um OBC é committed e entra no Iteration Plan — momento em que o compromisso foi assumido e o trabalho está pronto para execução operacional.

**Quando não usar:** Issues não substituem OBCs. Não criar Issues como ponto de entrada do trabalho — o ponto de entrada é a Global Tracking List ou Repository Tracking List. Não usar Issues para capturar Intents que ainda não têm OBC.

**Independência de ferramenta:** O Framework é independente de ferramenta. Uma GitHub Issue, um Jira Card e um Azure DevOps Work Item são representações operacionais do mesmo OBC em ferramentas diferentes. O OBC é a fonte de verdade; a Issue é a instância de execução.

**Relação com outros conceitos:** Gerenciada pela Diligence. Referencia o OBC correspondente. Ver [`backlogs.md`](backlogs.md) e [`../journeys/diligence/README.md`](../journeys/diligence/README.md).
