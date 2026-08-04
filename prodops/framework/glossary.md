# ProdOps Glossary

Termos canônicos do Framework ProdOps. Um conceito = um nome. Um nome = um conceito.

Para a **hierarquia de conceitos estruturais** (Framework, Execution Model, Journey, Cycle, Phase, Capability, Skill, Step), ver [`ontology.md`](ontology.md).
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

**Contém:** Portfolio Tracking List (Business Signals), Business Intent Backlog (Business Intents), Roadmaps (view do BIB), Platform Releases (view do BIB), Milestones.

**Não contém:** Implementação de software, OBCs de produto, BDD Features de produto.

**Relação com outros conceitos:** O Portfolio está entre o Framework (que define as regras) e os Workspaces (que executam). Um Roadmap de Portfolio coordena Product Repositories. Ver **Platform Release**.

---

## Workspace

**Definição:** O nível de integração entre produtos. Responsável por executar e testar múltiplos Product Repositories em conjunto.

**Propósito:** Garantir que produtos que dependem uns dos outros funcionem corretamente de forma integrada. Um Workspace não possui Roadmap nem Business Intents — existe exclusivamente para integração.

**Características operacionais:** O Workspace não possui estado próprio. Observa o GitHub (fonte operacional primária) e nunca decide prioridades — prioridades são decididas pelo Portfolio (Business Intents) ou pelo Product Owner (OBCs no Product Backlog).

**Exemplos:** Checkout Workspace (webshop-api + payments-api + order-mgmt-api).

**Não contém:** Roadmap, Business Intents, código de produto, estado de backlog.

**Relação com outros conceitos:** Um Workspace é coordenado pelo Portfolio e integra Product Repositories. Ver **Product Repository**.

---

## Product Repository

**Definição:** O nível de implementação e operação de um produto específico dentro da arquitetura ProdOps. Cada repositório consumidor do Framework é um Product Repository.

**Propósito:** Implementar Product Capabilities, operar o produto em produção e manter a rastreabilidade completa de Intents até evidências de operação.

**Contém:** OBCs, BDD Features, Iteration Plans, Reliability Plans, Release Trail, código do produto, runbooks, postmortems.

**Relação com outros conceitos:** Um Product Repository adota o Framework, participa de Roadmaps definidos pelo Portfolio e é integrado por Workspaces. Pode também evoluir localmente por meio de seu próprio fluxo de Business Intents.

---

## Platform

**Definição:** O conjunto de Product Repositories coordenados pelo Portfolio e integrados pelos Workspaces. A plataforma é o produto composto — o que o cliente final experimenta.

**Relação com outros conceitos:** A Platform é o resultado da coordenação entre Portfolio, Workspaces e Product Repositories. Ver **Portfolio**, **Workspace**, **Product Repository**.

---

## Platform Release

**Definição:** View sobre o Business Intent Backlog — não é um backlog separado. Agrupa itens do BIB que compõem uma entrega coerente da plataforma como um todo. Coordenada pelo Portfolio.

**Propósito:** Marcar um ponto de entrega coerente da plataforma como um todo — não apenas de um produto isolado.

**Distinção:** Uma Platform Release é diferente de um release local de um único Product Repository. O release local (gerenciado pelo CI Async do repositório) contribui para uma Platform Release, mas não a substitui.

**Relação com outros conceitos:** View sobre o BIB. Gerenciado pelo Portfolio. Composto por releases de múltiplos Product Repositories. Ver **Portfolio**, **Roadmap**.

---

## Roadmap

**Definição:** View sobre o Business Intent Backlog — não é um backlog separado. Organiza os itens do BIB em horizontes de entrega (agora / próximo / futuro). Gerenciado pelo Portfolio.

**Propósito:** Comunicar prioridades e horizonte de entrega da plataforma para stakeholders, times e parceiros. Representa intenção estratégica, não compromisso de entrega.

**Quem gerencia:** O Portfolio. Product Repositories participam de Roadmaps mas não os definem.

**Não confundir com:** Iteration Plan (planejamento de uma iteração dentro de um Product Repository) ou Icebox (candidatos ainda não priorizados).

**Relação com outros conceitos:** View sobre o BIB. Orienta quais Business Intents de quais Product Repositories serão priorizadas. Ver **Portfolio**, **Platform Release**, **Business Intent**.

---

## Origin Stream

**Definição:** Classificação da origem de uma Intent. Identifica de onde a necessidade nasceu e quem a detém.

**Propósito:** Garantir que toda mudança tenha origem rastreável e que o contexto, a linguagem e os critérios de sucesso sejam apropriados para o tipo de necessidade.

**Quando usar:** Ao registrar qualquer Intent. Toda Intent tem exatamente um Origin Stream.

**Quando não usar:** Origin Stream não determina o modo de execução nem a jornada — isso é função do Execution Mode e do Continuous Assessment.

**Os quatro Origin Streams:** Business | Enterprise | Team | Technology

**Relação com outros conceitos:** Um Origin Stream gera um **Business Signal**. O Business Signal, quando investigado e reconhecido como estratégico, pode gerar uma ou mais **Business Intents**. Ver [`origin-streams.md`](origin-streams.md).

---

## Business Signal

**Definição:** Representa qualquer oportunidade, hipótese, problema, benchmark, caso de negócio, value stream, reclamação, nova tecnologia ou ideia que merece atenção. Não é um compromisso. Não é um contrato. Não tem OBC.

**Propósito:** Capturar qualquer sinal que mereça investigação antes de qualquer decisão estratégica ou de investimento. Os Business Signals são o material bruto a partir do qual o trabalho estratégico é identificado.

**Quando usar:** Ao registrar uma necessidade ainda não estruturada o suficiente para ser tratada como uma Business Intent formal. Todo item capturado nas Tracking Lists é um Business Signal.

**Ciclo de vida:** Persiste mesmo após gerar Business Intents — representa o histórico de descoberta. Um Business Signal pode gerar 0, 1 ou N Business Intents.

**Vive em:** Portfolio Tracking List (plataforma) ou Product Tracking List (produto).

**Representação no Execution Space:** Um Business Signal não tem representação permanente como GitHub Issue. Work Items são criados quando há uma operação ativa sobre o Signal (ex.: exploração, triagem, promoção). Um mesmo Signal pode ter zero ou mais Work Items ao longo de sua vida. Ver [knowledge-vs-execution.md](knowledge-vs-execution.md).

**Regra crítica:** Entidades nunca mudam de identidade. Um Business Signal nunca "se torna" uma Business Intent — ele **gera** novas entidades Business Intent.

**Relação com outros conceitos:** 1 Business Signal → 0 a N Business Intents. Ver [`backlogs.md`](backlogs.md).

---

## Business Intent

**Definição:** Representa uma decisão estratégica: há clareza sobre qual valor será perseguido. Nasce de um Business Signal (ou múltiplos). Tem identidade e ciclo de vida próprios — não substitui o Business Signal.

**Propósito:** Registrar formalmente uma decisão de investimento antes de qualquer decisão de implementação. A Business Intent captura o "porquê" sem prescrever o "como".

**Quando usar:** Quando um Business Signal for investigado e reconhecido como estrategicamente relevante. Toda mudança que entra no Business Intent Backlog é representada como Business Intent.

**Quando não usar:** Business Intent não é backlog técnico, tarefa de sprint ou ticket de bug isolado. Não representa implementação — representa decisão estratégica.

**Ciclo de vida:** A Business Intent nasce no Business Intent Backlog (fluxo global) — momento em que o Global OBC é criado como Draft. Possui um OBC como documento de contrato — o OBC representa o compromisso com as 4 dimensões: Business, Enterprise, Team e Technology. O OBC Partitioning cria documentos Local OBC (arquivos Markdown) por produto, mas a Intent continua sendo a entidade rastreável.

**Origem:** Pode ser criada diretamente no Business Intent Backlog sem origem em um Business Signal. Quando gerada a partir de um Business Signal, mantém referência opcional ao Signal de origem.

**Representação no Execution Space:** Work Items são criados quando há operações ativas sobre a Intent (ex.: exploração, refinamento, promoção). Um mesmo Intent pode ter zero ou mais Work Items ao longo de sua vida. Ver [knowledge-vs-execution.md](knowledge-vs-execution.md).

**Relação com outros conceitos:** Nasce de um Business Signal (ou criada diretamente no BIB). Possui um OBC como documento de contrato. Ver [`flow.md`](flow.md), [`origin-streams.md`](origin-streams.md) e [`backlogs.md`](backlogs.md).

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

**Onde registrar:** `prodops/framework/journeys/discovery/spikes.md` (se isolado) ou `upstream-trail.md` do experimento (se dentro de um Upstream ativo).

**Relação com outros conceitos:** Ver **PoC**, **Estágio de Produto**, [`product-stages.md`](product-stages.md) e [`journeys/discovery/spikes.md`](journeys/discovery/spikes.md).

---

## Concepção

**Definição:** Fase que compreende o período desde o surgimento do Business Signal até a entrada no Product Backlog. O Business Signal existe como possibilidade — o Product Owner ainda não assumiu compromisso.

**Pergunta central:** Existe valor real aqui?

**Backlogs:** Portfolio Tracking List / Product Tracking List → Business Intent Backlog (fluxo global).

**Estado do OBC:** Não existe nas Tracking Lists. No fluxo global, o **Global OBC** nasce como Draft ao entrar no Business Intent Backlog. No fluxo local, o **Local OBC** nasce como Draft ao entrar no Product Backlog.

**Compromisso:** Nenhum. O Business Signal pode ser descartado sem registro formal de aprendizado.

**Fronteira de saída:** Owner Approval — entrada no Product Backlog (início da Inception).

**Relação com outros conceitos:** Ver [`phases.md`](phases.md), [`backlogs.md`](backlogs.md).

---

## Inception

**Definição:** Fase que compreende o período desde a entrada no Product Backlog até o Local OBC atingir o estado Committed (Iteration Backlog). O Product Owner assumiu compromisso formal de investigação.

**Pergunta central:** O Product Owner está comprometendo atenção e capacidade para investigar isso agora?

**Backlogs:** Product Backlog → Icebox → Iteration Backlog.

**Estado do Local OBC:** Draft → Refining (Icebox) → Committed (Iteration Backlog).

**Compromisso:** Formal. Qualquer encerramento exige registro de aprendizado rastreável no OBC.

**Modo de execução:** Upstream ou Downstream — são **modos**, não fases. Definido pelo Product Owner ao aceitar a Business Intent no Product Backlog. Pode mudar ao longo da Inception.

**Fronteira de saída:** Assessment Review aprovada, Local OBC em estado Committed, BDD Feature committed — entrada no Iteration Backlog.

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

**Definição:** O contrato vivo que representa uma Business Intent durante todo o seu ciclo de vida. Existe em dois níveis: **Global OBC** (contrato de negócio estratégico, pertence ao BIB/Portfolio) e **Local OBC** (contrato de produto, pertence ao Product Backlog/Product Owner). Ver entradas separadas abaixo.

**Estados (maturidade do contrato):** Draft → Refining → Committed → In Delivery → Operational → Archived.

**Criação:** Um OBC nasce APENAS quando uma Business Intent é aceita. O Global OBC nasce ao entrar no Business Intent Backlog. O Local OBC nasce após o Particionamento do OBC (fluxo global) ou ao entrar no Product Backlog (fluxo local). Não existe OBC para Business Signals — o OBC só nasce de Business Intents.

**Relação com outros conceitos:** Âncora a BDD Feature, o Iteration Plan, o Reliability Plan e toda a Delivery. A Diligence mantém o estado do OBC sincronizado entre backlogs e ferramentas.

→ **Definição completa, composição, ciclo de vida e governança:** [`obc.md`](obc.md)

---

## Global OBC

**Definição:** Nível estratégico do Observable Business Contract. Representa uma intenção de negócio completa — independente de produtos, times ou repositórios. É o contrato canônico da capability de negócio. Pertence ao BIB (Portfolio), nunca a um produto.

**Foco:** estratégico. Não contém detalhes de implementação, APIs, repositórios, BDD ou critérios de aceite técnicos.

**Contém:** Objetivo de Negócio, Valor de Negócio, Stakeholders, Regras de Negócio, Eventos de Negócio, KPIs, Value Stream, Produtos envolvidos (quando conhecidos), Rastreabilidade dos Local OBCs.

**Localização:** Repositório de portfólio da plataforma (externo a repositórios de produto).

**Ciclo de vida:** Draft → Refining → Operational → Archived. Não desaparece após a decomposição — continua evoluindo.

**Relação com outros conceitos:** Decomposto em N Local OBCs pelo OBC Partitioning. Nunca use os termos "pai" ou "filho" — use decomposição/especialização/partição.

→ **Definição completa:** [`obc.md`](obc.md) | [Template](../templates/obcs/global-obc.md)

---

## Local OBC

**Definição:** Nível de produto do Observable Business Contract. Representa a responsabilidade de um único produto. Pode especializar um Global OBC (fluxo global) ou nascer diretamente de uma Business Intent local (fluxo local). Pertence a exatamente um Product Backlog.

**Foco:** implementação e entrega de produto. Contém o contrato técnico e operacional do produto.

**Contém:** Referência de origem obrigatória — Global OBC no fluxo global ou Intent + Repository Tracking Item no fluxo local —, Produto/Repositório/Bounded Context, APIs e Eventos, BDD/Critérios de Aceite, Observabilidade, Regras de Confiabilidade, Contrato de Resposta, Dependências Técnicas, Evidências.

**Localização:** `prodops/artifacts/obcs/<slug>.md`

**Ciclo de vida:** Draft → Refining → Committed → In Delivery → Operational → Archived.

**Não duplica:** quando houver Global OBC, seu conteúdo estratégico. Sempre referencia, nunca copia.

**Relação com outros conceitos:** Especialização/partição do Global OBC no fluxo global; contrato direto da Business Intent no fluxo local. Nunca use os termos "filho" ou "herança".

→ **Definição completa:** [`obc.md`](obc.md) | [Template](../templates/obcs/local-obc.md)

---

## OBC Partitioning

**Definição:** Processo de governança responsável por particionar um Global OBC em Local OBCs — um por produto envolvido. Ocorre entre o Discovery no BIB e a criação de itens nos Product Backlogs dos produtos. Não é uma Framework Capability nem uma Product Capability — é uma atividade pontual de responsabilidade humana.

**Responsabilidades:** identificar produtos envolvidos, identificar repositórios, identificar Bounded Contexts, decompor o Global OBC, criar os Local OBCs, manter rastreabilidade.

**Quem executa:** Portfolio PM + Tech Leads dos produtos envolvidos.

**Relação com outros conceitos:** Etapa entre BIB e Product Backlogs no fluxo global. Resultado: tabela de rastreabilidade no Global OBC + Local OBC Draft em cada Product Backlog.

→ Ver [`backlogs.md`](backlogs.md) e [`obc.md`](obc.md)

---

## Refinamento Contínuo do OBC

**Definição:** Princípio segundo o qual o OBC nunca é considerado finalizado. Continua evoluindo durante Discovery, Delivery e Operation. Toda nova evidência — experimentos, decisões de implementação, incidentes, postmortems, métricas operacionais — atualiza o contrato.

**Propósito:** Garantir que o OBC reflita o estado atual do conhecimento sobre a capability — não apenas a intenção original.

**Relação com outros conceitos:** Aplica-se a ambos os níveis (Global OBC e Local OBC). Alimentado pela jornada Operation e pelo Continuous Assessment.

→ Ver [`obc.md`](obc.md) e [`flow.md`](flow.md)

---

## Exploration

**Definição:** Etapa que refina o OBC draft — nascido no Business Intent Backlog ou Product Backlog — reduzindo incerteza e transformando hipóteses em conhecimento validado. A maior parte do refinamento ocorre durante o Icebox.

**Propósito:** Garantir que o OBC seja construído sobre entendimento real, não sobre suposições. Sem Exploration suficiente, o OBC é frágil.

**Quando usar:** Sempre que a Intent tiver hipóteses não validadas, decisões de domínio em aberto ou incerteza técnica que justifique exploração antes do compromisso.

**Quando não usar:** Quando a Intent é trivial, o comportamento já é bem compreendido e o OBC pode ser escrito diretamente. Neste caso, a Exploration é curta ou inexistente.

**Relação com outros conceitos:** Exploration é realizada pela jornada Discovery em ambos os modos. Discovery descreve a jornada; Upstream ou Downstream define compromisso e rigor.

| Termo | Nível | Significado |
|---|---|---|
| **Exploration** | Etapa do fluxo | O que acontece: redução de incerteza entre Intent e OBC |
| **Discovery** | Jornada | O nome da jornada do Framework que implementa Exploration |
| **Upstream / Downstream** | Execution Mode | O compromisso e o rigor aplicados durante Discovery |

Ver [`flow.md`](flow.md), [`journeys/discovery/README.md`](journeys/discovery/README.md) e [`execution-model/upstream.md`](execution-model/upstream.md).

---

## Discovery

**Definição:** Jornada do Framework ProdOps que implementa a etapa de Exploration. Fluxo de engenharia exploratória orientado a aprendizado.

**Propósito:** Transformar hipóteses em conhecimento validado por meio de experimentos, spikes e protótipos. Produzir o Decision Package que fundamenta o OBC.

**Quando usar:** Ao explorar uma Intent em Upstream ou Downstream, com o rigor correspondente ao modo.

**Quando não usar:** Discovery não é sinônimo de Upstream e não determina, sozinha, se haverá entrega.

**Relação com outros conceitos:** Discovery é a jornada que implementa Exploration e existe nos modos Upstream e Downstream. Ver [`journeys/discovery/README.md`](journeys/discovery/README.md).

---

## Delivery Capability

**Definição:** Competência técnica reutilizável consumida pelas fases da jornada Delivery. Exemplos: Commit Workflow, Contract Management, Evidence Management, Observability, Reliability.

**Propósito:** Encapsular práticas técnicas transversais que podem ser invocadas por múltiplas fases sem duplicação.

**Quando usar:** Ao referenciar a infraestrutura técnica do processo de entrega.

**Quando não usar:** Não confundir com "Product Capability". Uma Delivery Capability é um mecanismo do Framework, não uma funcionalidade do produto.

**Relação com outros conceitos:** Usada pelas Phases da jornada Delivery. Ver [`journeys/delivery/capabilities/`](journeys/delivery/capabilities/).

---

## Product Capability

**Definição:** Uma funcionalidade, comportamento ou característica do produto que está sendo explorada ou entregue. Exemplos: split payment, suporte a Pix, webhook de confirmação.

**Propósito:** Denominar o escopo de trabalho de produto que uma Intent origina e que um OBC descreve.

**Quando usar:** Ao referenciar o que está sendo construído — a funcionalidade, o comportamento, o valor de produto.

**Quando não usar:** Não confundir com "Delivery Capability". Uma Product Capability é o objeto do trabalho; uma Delivery Capability é um mecanismo do processo.

**Nota:** Em contextos onde a ambiguidade for possível, preferir o termo completo "Product Capability" ou "Delivery Capability" em vez de apenas "capability".

---

## Product Topology

**Definição:** A organização estrutural permanente de um produto. Descreve as quatro dimensões que coexistem em qualquer produto e sobre as quais os OBCs produzem mudanças via Delivery.

**Propósito:** Identificar quais partes da estrutura do produto são afetadas por um OBC — independente de onde a intenção nasceu (Origin Stream) e independente do processo de entrega.

**As quatro Product Dimensions:** Team · Flow · Data · Components

**Separação ontológica obrigatória:**
- **Origin Streams** respondem: "De onde surgiu esta necessidade?" (origem da intenção)
- **Product Topology** responde: "Quais partes do produto serão impactadas?" (estrutura permanente)

**Não representa:** Backlog, jornada, pipeline, fluxo de trabalho ou ciclo de vida do processo. Product Topology descreve a estrutura do produto — não o processo de construção.

**Nunca usar como substituto:** Layers, Domains, Views, Perspectives, Streams.

→ **Definição completa com diagrama e exemplos:** [`product-topology.md`](product-topology.md)

---

## Team (Product Dimension)

**Definição:** A dimensão organizacional da Product Topology. Descreve o ownership, as responsabilidades, as capacidades, os papéis, a colaboração, a governança e o modelo operacional do time que constrói e opera o produto.

**Quando um OBC impacta esta dimensão:** Quando a entrega cria novas responsabilidades operacionais, redefine papéis entre times ou altera o modelo de governança do produto.

**Distinção crítica:** Não confundir com o Origin Stream "Team" — que classifica a *origem* de uma necessidade (o time identificou o problema). A Product Dimension "Team" descreve o *impacto* sobre a organização do produto.

**Relação com outros conceitos:** Uma das quatro Product Dimensions. Ver [`product-topology.md`](product-topology.md).

---

## Flow (Product Dimension)

**Definição:** O eixo temporal da Product Topology. Representa como as demais Product Dimensions (Team, Data, Components) evoluem ao longo das jornadas do Framework — Discovery, Delivery, Operation, Diligence e futuras jornadas. Flow não executa nada: registra a evolução, a transformação e o histórico das mudanças ao longo do tempo.

**Quando um OBC impacta esta dimensão:** Sempre — todo OBC, ao percorrer as jornadas do Framework, sempre deixa um rastro temporal. Flow registra esse trânsito: quando o OBC nasceu (Discovery), foi implementado (Delivery), entrou em produção (Operation) e foi validado (Diligence).

**Distinção crítica:** Flow não é comportamento funcional do produto. Processos de negócio, regras de negócio, máquinas de estado, automações e funcionalidades pertencem à dimensão **Components** — que implementa o comportamento do produto. Flow é exclusivamente o eixo temporal: responde *quando* e *como* as dimensões evoluem, nunca *o que* o produto faz.

**Relação com outros conceitos:** Uma das quatro Product Dimensions; transversal às demais. Ver [`product-topology.md`](product-topology.md).

---

## Data (Product Dimension)

**Definição:** A dimensão informacional da Product Topology. Descreve as entidades de negócio, os contratos de dados, os schemas, a persistência, as integrações, os eventos de domínio e as APIs que compõem o modelo informacional do produto.

**Quando um OBC impacta esta dimensão:** Quando a entrega cria novos schemas, novos eventos de domínio, novos contratos de API ou altera o modelo de persistência existente.

**Relação com outros conceitos:** Uma das quatro Product Dimensions. Ver [`product-topology.md`](product-topology.md).

---

## Components (Product Dimension)

**Definição:** A dimensão física e comportamental da Product Topology. Descreve as aplicações, os serviços, os microsserviços, os bancos de dados, as filas, os pipelines de dados, a infraestrutura e os repositórios que compõem a plataforma técnica do produto. **Os Components implementam o comportamento funcional do produto** — são eles que executam regras de negócio, funcionalidades, integrações, APIs e processos automatizados. O comportamento do produto emerge da colaboração entre seus Components.

**Quando um OBC impacta esta dimensão:** Quando a entrega cria novos serviços, novas APIs, novos workers, novas filas de mensagens, novos bancos de dados ou altera a infraestrutura existente do produto.

**Relação com outros conceitos:** Uma das quatro Product Dimensions. Ver [`product-topology.md`](product-topology.md).

---

## BDD Feature

**Definição:** Especificação Gherkin que descreve o comportamento esperado de uma Product Capability. Fica em `prodops/artifacts/bdd/` (comprometida) ou `prodops/artifacts/experiments/<NNN-slug>/features/` (exploratória — dentro do diretório do experimento). Usada como insumo de TDD no Downstream.

---

## Reliability Plan

**Definição:** Produto da jornada transversal de Assessment que define riscos, SLOs e ações de mitigação para um item comprometido. Fica em `prodops/artifacts/plans/reliability/`.

**Obrigatoriedade:** Condicional e verificável. É gate de Delivery quando houver movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração de persistência ou segurança. Fora desses gatilhos é opcional.

**No fluxo local (antes do Product Backlog):** O Premortem é o artefato adequado para análise de risco antes do Owner Approval. O Reliability Plan formal é produzido durante o Icebox, após o compromisso do Product Owner.

---

## Portfolio Tracking List

**Definição:** Backlog de plataforma que captura Business Signals ainda não compreendidos o suficiente para gerar uma Business Intent formal. Gerenciado pelo Portfolio.

**Pergunta:** Quais Business Signals merecem atenção na plataforma?

**Contém:** APENAS Business Signals. Nunca Business Intents. Nunca OBCs.

**Não contém:** OBC. Compromisso. Identificador permanente.

**Relação com outros conceitos:** Primeiro nível do fluxo global. Business Signals avançam para o Business Intent Backlog quando reconhecidos como Business Intents. Ver [`backlogs.md`](backlogs.md).

---

## Business Intent Backlog

**Definição:** Backlog estratégico da plataforma que representa Business Intents aceitas para Discovery. O **Global OBC** nasce como Draft ao entrar neste backlog. Contém APENAS Business Intents — nunca Business Signals, nunca Local OBCs. Gerenciado pelo Portfolio.

**Pergunta:** Quais Business Intents merecem Discovery?

**Relação com outros conceitos:** Segundo nível do fluxo global. A Business Intent nasce aqui; o Global OBC Draft é criado junto. Após Discovery, o OBC Partitioning cria Local OBCs nos Product Backlogs dos produtos. Ver [`backlogs.md`](backlogs.md).

---

## Product Tracking List

**Definição:** Backlog de produto que captura Business Signals locais ainda não compreendidos o suficiente para gerar uma Business Intent formal. Artefato: `prodops/artifacts/product/backlogs/tracking-list.md`.

**Pergunta:** Quais Business Signals merecem atenção neste produto?

**Contém:** APENAS Business Signals. Nunca Business Intents. Nunca OBCs.

**Não contém:** OBC. Compromisso. Identificador permanente.

**Relação com outros conceitos:** Primeiro nível do fluxo local. Business Signals avançam via Premortem + Análise de Risco Preliminar + Owner Approval para o Product Backlog. O Reliability Plan formal, quando acionado pelos gatilhos de risco, é produzido depois, durante o Icebox. Ver [`backlogs.md`](backlogs.md).

---

## Product Backlog

**Definição:** Backlog de produto que representa todo trabalho formalmente aceito pelo Product Owner. Contém exclusivamente **Business Intents** — cada Intent possui um Local OBC como documento de contrato. Nunca contém Business Signals isolados nem Global OBCs. Ponto de entrada único do produto para o ciclo de Delivery. Views: **Icebox** (Refining), **Iteration Backlog** (Committed) e **Release** (agrupado por versão).

**Pergunta:** O que foi oficialmente aceito pelo Product Owner?

**Dois caminhos de entrada:** (1) Local OBC via OBC Partitioning, direcionado pelo Portfolio após Discovery no BIB (fluxo global); (2) Business Signal promovido via Premortem + Análise de Risco Preliminar com Owner Approval (Local OBC Draft nasce aqui, fluxo local).

**Após a entrada, a origem deixa de importar.** Todos os itens seguem a mesma jornada: Icebox (Refining) → Iteration Backlog (Committed) → Iteration Plan (In Delivery) → Operation (Operational).

**Relação com outros conceitos:** Ponto de convergência dos fluxos global e local. Nunca recebe Business Signals diretamente — apenas OBCs. Ver [`backlogs.md`](backlogs.md).

---

## Icebox

**Definição:** View sobre o Product Backlog que representa itens em refinamento — Local OBC em estado **Refining**, Discovery em andamento, decisões em aberto. O Discovery funcional, técnico e operacional necessário ocorre neste estado. Artefato: `prodops/artifacts/product/backlogs/icebox-backlog.md`.

**Pergunta:** Quais itens do Product Backlog ainda estão sendo refinados para Delivery?

**Estado do Local OBC:** Refining.

**Natureza:** View — não é uma fila separada. Itens permanecem no Product Backlog e mudam de estado.

**Relação com outros conceitos:** View sobre o Product Backlog. Itens transitam para a view Iteration Backlog quando o Local OBC atinge o estado Committed. Ver [`backlogs.md`](backlogs.md).

---

## Iteration Backlog

**Definição:** View sobre o Product Backlog que representa itens com Local OBC no estado **Committed**, prontos para Delivery imediata. Não é um backlog de refinamento — refinamento acontece no estado Icebox. A única decisão restante é a prioridade do Product Owner. Artefato: `prodops/artifacts/product/backlogs/iteration-backlog.md`.

**Pergunta:** Quais itens do Product Backlog estão prontos para ser desenvolvidos?

**Estado do Local OBC:** Committed.

**Natureza:** View — não é uma fila separada. Itens permanecem no Product Backlog e mudam de estado.

**Relação com outros conceitos:** View sobre o Product Backlog. Itens avançam para o Iteration Plan após Local OBC committed em arquivo + BDD Feature committed. Ver [`backlogs.md`](backlogs.md).

---

## Release (view do Product Backlog)

**Definição:** View sobre o Product Backlog que representa itens agrupados por versão de release do produto. Facilita o planejamento, comunicação e acompanhamento de versões. Não confundir com Platform Release (view do BIB, responsabilidade do Portfolio).

**Pergunta:** Quais itens do Product Backlog fazem parte desta versão de release?

**Gerenciado por:** Product Owner.

**Relação com outros conceitos:** View sobre o Product Backlog. Ver **Platform Release** e [`backlogs.md`](backlogs.md).

---

## Iteration Plan

**Definição:** Registro da execução de Delivery de uma iteração. Não é um backlog de planejamento — representa exclusivamente a execução em andamento. Contém itens do Iteration Backlog, estratégia de execução, jornadas CI Sync e CI Async, evidências e critérios de saída. Artefato: `prodops/artifacts/plans/iteration-plan.md`.

**Pergunta:** O que está sendo executado nesta iteração?

**Relação com outros conceitos:** Recebe itens do Iteration Backlog com OBC committed + BDD committed. É o último backlog antes de Delivery. Ver [`backlogs.md`](backlogs.md).

---

## CI Sync

**Definição:** O Cycle síncrono do ProdOps Delivery. Representa o trabalho local, colaborativo e conduzido pelo engenheiro. Inclui Bootstrap, Hack, Sync e Finish. Produz: task fechada, PR com narrativa, evidências, commits organizados, validações locais executadas. Ver [`journeys/delivery/README.md`](journeys/delivery/README.md).

---

## CI Async

**Definição:** O Cycle assíncrono do ProdOps Delivery. Representa o trabalho conduzido pela plataforma, pipelines e ambientes. Inclui Ship, Validate e Promote. Produz: artefato publicado, deploy realizado, validação em runtime, promoção controlada. Ver [`journeys/delivery/README.md`](journeys/delivery/README.md).

---

## Execution Model

**Definição:** O par de modos de execução que define o nível de compromisso, quality gates e critérios de qualidade aplicados quando qualquer Journey é executada — Upstream (exploração) e Downstream (compromisso). Não é uma Journey, não é uma Phase.

**Regra fundamental:** O Execution Model define *como* as Journeys executam — não *o que* elas são. Qualquer Journey pode operar em qualquer modo.

→ Definição completa: [`ontology.md — Execution Model`](ontology.md#modificador-transversal-execution-model) · [`execution-model/README.md`](execution-model/README.md)

---

## Journey (Jornada)

**Definição:** Um caminho de trabalho com responsabilidade única, ciclo de vida próprio e critérios de entrada e saída definidos. As 5 jornadas são: Discovery, Delivery, Operation, Assessment e Diligence.

**Regra fundamental:** Journeys não são modos de execução. Upstream e Downstream não são jornadas — são modos do Execution Model que se aplicam sobre as jornadas.

→ Definição completa: [`ontology.md — Journey`](ontology.md#journey-jornada) · [`journeys/README.md`](journeys/README.md)

---

## Cycle (Ciclo)

**Definição:** Agrupamento ordenado de Phases dentro de uma Journey, com propósito, acionamento e natureza distintos. Delivery tem CI Sync e CI Async; Diligence tem diligence-sync e diligence-async. Workspace Reconciliation é uma Capability do Diligence — não é um Cycle. Discovery, Operation e Assessment não têm Cycles formais.

→ Definição completa: [`ontology.md — Cycle`](ontology.md#cycle-ciclo)

---

## Phase (Fase)

**Definição:** Estágio individual e ordenado dentro de um Cycle, com pré-condições, responsabilidade única e saída verificável. Exemplos: Bootstrap, Hack, Ship, Capture, Inspect.

**Distinção:** [`phases.md`](phases.md) descreve **Concepção** e **Inception** — esses são **Lifecycle Stages** (estágios do ciclo de vida de uma Business Intent antes da Delivery), diferentes das Phases desta ontologia. Quando houver ambiguidade, usar: "Lifecycle Stage", "Delivery Phase" ou "Diligence Phase".

→ Definição completa: [`ontology.md — Phase`](ontology.md#phase-fase)

---

## Skill

**Definição:** Especificação de comportamento executável para agentes. Uma Skill implementa uma Journey, Cycle, Phase ou Capability, descrevendo o que o agente deve fazer, quando entrar, o que ler e o que produzir. Skill NÃO é um conceito estrutural do Framework — é uma implementação independente de tecnologia.

→ Definição completa: [`ontology.md — Skill`](ontology.md#skill) · [`skills/README.md`](../skills/README.md)

---

## Step

**Definição:** Sub-unidade ordenada dentro de uma Skill, com entrada e saída próprias. Pode ser invocado individualmente. Step é estrutura interna de Skill — não tem relação direta com o eixo estrutural (Journey, Cycle, Phase, Capability).

→ Definição completa: [`ontology.md — Step`](ontology.md#step)

---

## Bootstrap

**Definição:** O primeiro estágio do CI Sync. Instala dependências, prepara infraestrutura local, verifica configuração e executa o smoke gate. Não lê código, testes ou artefatos de produto e não cria branch; Git flow pertence ao Hack Start. Ver [`journeys/delivery/phases/bootstrap/README.md`](journeys/delivery/phases/bootstrap/README.md).

---

## Upstream

**Definição:** **Modo de execução** permissivo, experimental e sem compromisso de entrega. Pode usar todas as jornadas com maturidade variável; código é descartável até ser promovido. Não é sinônimo de Discovery. Não é uma fase — é um modo que pode iniciar em **qualquer estágio** do ciclo de vida. Quando concluído, o item retorna ao estágio original.

**Importante:** Upstream não muda o estágio do item. Um item em Discovery que inicia Upstream continua em Discovery; quando o Upstream termina, retorna ao estágio em que estava.

Ver [`prodops/framework/journeys/discovery/README.md`](journeys/discovery/README.md).

---

## Downstream

**Definição:** **Modo de execução** padrão, com compromisso de entrega que aplica todos os quality gates vigentes em todas as jornadas. Guia o item e para em cada lacuna até atingir readiness; então executa o fluxo completo `Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote`. Não é uma fase — é um modo de execução. Pode iniciar em qualquer estágio do ciclo de vida.

Ver [`prodops/framework/execution-model/downstream.md`](execution-model/downstream.md).

---

## Hack Flow

**Definição:** A fase de codificação em Upstream e Downstream. Segundo estágio do CI Sync, sucede o Bootstrap. Definido em [`journeys/delivery/phases/hack/README.md`](journeys/delivery/phases/hack/README.md). Mecânica de execução em [`skills/hack/`](../skills/hack/).

---

## Sync

**Definição:** O terceiro estágio do CI Sync. Tem dois steps independentes: `rebase` (sincroniza a feature branch com a base — fetch, integração, conflitos, validação) e `align` (alinha artefatos ProdOps com a implementação — BDD Features, Event Storming, arquitetura, Release Trail). Invocados via `/sync rebase` e `/sync align`. Ver [`journeys/delivery/phases/sync/README.md`](journeys/delivery/phases/sync/README.md).

---

## Ship

**Definição:** O primeiro estágio do CI Async. Transforma a implementação finalizada em artefato executável e conduz o deploy. Organizado em duas famílias: Preparation (Build, Package, Version, Sign, SBOM, Publish Artifact) e Deployment (Deploy, Progressive Delivery, Feature Flags, Rollout, Rollback, Infrastructure Validation). Build, Package e Publish são capabilities internas do Ship — não são etapas independentes do fluxo principal. Ver fases: [Ship](journeys/delivery/phases/ship/README.md), [Validate](journeys/delivery/phases/validate/README.md), [Promote](journeys/delivery/phases/promote/README.md).

---

## Validate

**Definição:** O segundo estágio do CI Async. Verifica a entrega em execução no ambiente alvo. Capabilities: Smoke Tests, Runtime Contract Validation, Synthetic Monitoring, Health Checks, Observability Validation, SLO Validation, Business Validation, Incident Signals. Ver fases: [Ship](journeys/delivery/phases/ship/README.md), [Validate](journeys/delivery/phases/validate/README.md), [Promote](journeys/delivery/phases/promote/README.md).

---

## Promote

**Definição:** O terceiro estágio do CI Async. Oficializa a evolução da versão com aprovação formal e evidência registrada. Capabilities: Promotion Gates, Environment Promotion, Release Approval, Release Trail, Operational Evidence, Release Documentation, Rollback Readiness. Ver fases: [Ship](journeys/delivery/phases/ship/README.md), [Validate](journeys/delivery/phases/validate/README.md), [Promote](journeys/delivery/phases/promote/README.md).

---

## ProdOps TDD

**Definição:** A prática utilizada dentro do Hack Flow para produzir código observável e confiável. Definida em [`journeys/delivery/practices/prodops-tdd.md`](journeys/delivery/practices/prodops-tdd.md).

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

**Relação com outros conceitos:** Jornada transversal. Consome artefatos do Assessment e alimenta a Delivery com trabalho organizado e rastreável. Ver [`journeys/diligence/README.md`](journeys/diligence/README.md) e [`backlogs.md`](backlogs.md).

---

## Canonical Operational Representation

**Definição:** A materialização operacional do modelo conceitual do ProdOps.

No estágio atual do Framework, a Canonical Operational Representation é realizada através de **GitHub Projects** (escopo por Jornada ou domínio operacional) e **GitHub Issues** (Work Items individuais).

**O que NÃO é:** A Canonical Operational Representation não é o modelo conceitual em si. OBCs, Business Intents, Business Signals e demais artefatos continuam vivendo como arquivos Markdown em `prodops/`. O GitHub é a expressão operacional desse conhecimento — não o conhecimento.

**Responsabilidade de manutenção:** A jornada **Diligence** é a guardiã da sincronização entre o modelo conceitual (`prodops/`) e a Canonical Operational Representation (GitHub Projects e Issues).

**Relação com outros conceitos:** Ver [GitHub Project](#github-project), [GitHub Issue](#github-issue), [knowledge-vs-execution.md](knowledge-vs-execution.md).

---

## GitHub Project

**Definição:** A representação operacional canônica de uma Jornada ou domínio operacional do ProdOps. Organiza e projeta Work Items (GitHub Issues) de um escopo específico (por Journey, Phase e Operation). Não representa o Framework como um todo — o Framework pode ter múltiplos Projects canônicos, cada um cobrindo o escopo de sua Jornada. Não substitui artefatos do Knowledge Space.

**Propósito:** Tornar visível o trabalho em andamento sobre artefatos ProdOps, agrupado e filtrado por dimensões operacionais (Journey, Artifact Type, Operation, Phase).

**O que representa:** Um domínio de gestão do trabalho. Cada GitHub Project rastreia Work Items de um escopo (Portfolio ou Product Repository). Não contém artefatos — contém operações sobre artefatos.

**O que NÃO representa:** Backlogs de artefatos. O GitHub Project não é um substituto para OBCs, Business Intents, Business Signals ou qualquer artefato do Knowledge Space. Views dentro de um Project são filtros sobre Work Items — nunca sobre artefatos.

**Canonical status:** GitHub Projects constituem a Canonical Operational Representation do ProdOps — cada Project representa operacionalmente uma Jornada ou domínio operacional específico. Não existe abstração para outras ferramentas (Jira, Azure DevOps, Linear). Ferramentas externas são sincronizações opcionais — nunca equivalentes.

→ Ver [Canonical Operational Representation](#canonical-operational-representation)

**Relação com outros conceitos:** Contém Work Items (GitHub Issues). Organizado por Views. Estado representado por Fields. Classificado por Labels. Ver [knowledge-vs-execution.md](knowledge-vs-execution.md).

---

## GitHub Issue

**Definição:** Work Item que representa uma operação sendo executada sobre um ou mais artefatos do Knowledge Space (Business Signal, Business Intent, OBC, BDD, etc.).

**Propósito:** Tornar visível e rastreável o trabalho de execução realizado sobre os artefatos ProdOps em GitHub Projects.

**Quando usar:** Ao registrar trabalho (exploração, refinamento, entrega, revisão) sobre qualquer artefato do Knowledge Space. Um Work Item deve sempre referenciar o(s) artefato(s) afetado(s) por tipo e ID.

**Quando não usar:** Issues não substituem OBCs. O OBC é um documento Markdown — não tem representação como Issue. Não criar Issues como ponto de entrada do trabalho — o ponto de entrada é a Portfolio Tracking List ou Product Tracking List.

**Ferramentas externas:** Jira, Azure DevOps, Linear e similares são sincronizações OPCIONAIS do GitHub — não são equivalentes. O GitHub é a fonte de verdade operacional.

**Work Items referenciam artefatos — não são os artefatos.**

Todo Work Item deve declarar: Artifact Type, Artifact ID, Operation, Journey.

Exemplos de Work Items corretos:
- Issue: "Discovery — BI-042 Suporte a split de pagamento" → referencia Business Intent BI-042
- Issue: "Refinar OBC payments-invoice-v2 — seção BDD incompleta" → referencia Local OBC
- Issue: "Atualizar arquitetura — novo módulo webhooks" → referencia Architecture overview.md

Um mesmo artefato pode ter dezenas de Work Items ao longo de sua vida.
Um mesmo Work Item pode afetar múltiplos artefatos.

**Relação com outros conceitos:** Gerenciada pela Diligence. Ver [`backlogs.md`](backlogs.md) e [`journeys/diligence/README.md`](journeys/diligence/README.md).

→ [Knowledge vs Execution](knowledge-vs-execution.md)

---

## View (GitHub Project)

**Definição:** Projeção canônica do estado de Work Items (GitHub Issues) dentro de um GitHub Project, filtrada e organizada por uma dimensão operacional específica — Journey, Phase, Operation, Artifact Type ou combinação delas.

**Propósito:** Tornar visíveis as fatias operacionais relevantes do trabalho em andamento — ex.: "todos os Work Items da jornada Delivery em fase Hack" ou "Work Items bloqueados por Findings".

**O que representa:** Um filtro persistente e nomeado sobre Work Items. A View não altera o estado dos Work Items — apenas os projeta. Diferentes Views podem mostrar os mesmos Work Items sob diferentes perspectivas.

**O que NÃO representa:** Uma lista de artefatos. "A View do Icebox" mostra Work Items sobre artefatos em estado Refining — não os artefatos em si. Ausência de um artefato em uma View não significa ausência do artefato no sistema.

**Distinção:** View no sentido desta entrada é a construção de interface do GitHub Projects. Não confundir com as Views conceituais de backlog (Icebox, Iteration Backlog, Release) — essas são construções do modelo ProdOps que podem ser _implementadas_ como Views do GitHub Project.

**Relação com outros conceitos:** Deriva de Fields. Parte de um GitHub Project. Ver [knowledge-vs-execution.md](knowledge-vs-execution.md).

---

## Field (GitHub Project)

**Definição:** Estado operacional de um Work Item (GitHub Issue) dentro de um GitHub Project. Campos representam dimensões do estado operacional necessárias para projetar corretamente cada Work Item nas Views.

**Campos canônicos obrigatórios:** `Artifact Type`, `Artifact ID`, `Operation`, `Journey`. Ver schema completo em [`execution-mapping/work-item-schema.md`](execution-mapping/work-item-schema.md).

**Dois tipos de campos:**
- **Campos cujo dono é o Execution Space** (GitHub): `Status`, `Assignee`, `Priority` — podem ser editados diretamente no Project.
- **Campos cujo dono é o Knowledge Space** (artefatos Markdown): `Artifact ID`, `Artifact Type`, `Finding Severity`, `Waiver Expiration` — não devem ser editados manualmente no Project; edição manual cria drift.

**O que NÃO são:** Fonte de verdade de artefatos. O estado canônico de um artefato vive em seu arquivo Markdown. Campos que derivam do Knowledge Space são reflexos — não fontes de verdade.

**Relação com outros conceitos:** Preenchidos pelo criador do Work Item (campos de identidade) ou pelo GitHub (campos operacionais). Lidos pelas Views. Auditados pela Diligence (Capability: Workspace Reconciliation). Ver [execution-mapping/work-item-schema.md](execution-mapping/work-item-schema.md).

---

## Label (GitHub)

**Definição:** Mecanismo auxiliar de classificação de Work Items (GitHub Issues) — **nunca** fonte de verdade para estado de nenhum artefato ou entidade ProdOps.

**Propósito:** Facilitar busca, filtro e categorização operacional de Work Items por `operation:<valor>` e `artifact-type:<valor>`.

**Uso canônico no ProdOps:**
- `operation:<valor>` — operação sendo executada (ex: `operation:refine`, `operation:promote`)
- `artifact-type:<valor>` — tipo do artefato afetado (ex: `artifact-type:local-obc`, `artifact-type:finding`)
- `journey:<valor>` — jornada ProdOps (recomendada)

**O que Labels NÃO podem representar:**
- ID canônico de nenhuma entidade (Finding, Remediation, Waiver, OBC, etc.)
- Status canônico de Finding ou de qualquer artefato
- Severidade de Finding
- Aprovação de Waiver
- Estado de expiração de Waiver
- Qualquer estado que exija persistência e auditoria

**Regra:** Se a informação precisa ser permanente, auditável ou autoritativa, ela pertence ao arquivo Markdown da entidade — não a uma Label. Labels são efêmeras e mutáveis; estados canônicos não são.

**Relação com outros conceitos:** Usadas em GitHub Issues. Convenção de nomenclatura definida em [execution-mapping/work-item-schema.md](execution-mapping/work-item-schema.md). Ver [knowledge-vs-execution.md](knowledge-vs-execution.md).

---

## Business Signal Work Item

**Definição:** Work Item (GitHub Issue) que rastreia uma operação ativa sobre um Business Signal. Representa trabalho SOBRE o Signal — não é o Signal em si. O Signal é um artefato do Knowledge Space (arquivo na tracking list); o Work Item é uma representação efêmera do trabalho de execução.

**Exemplos de operações:** captura, triagem, exploração, promoção para Business Intent.

**Cardinalidade:** Um Business Signal pode ter zero ou mais Work Items ao longo de sua vida. A ausência de Work Item não é uma divergência — só é divergência quando há operação ativa sem Work Item rastreável.

**Não confundir com:** O Business Signal em si (artefato permanente). Ver [knowledge-vs-execution.md](knowledge-vs-execution.md).

---

## Business Intent Work Item

**Definição:** Work Item (GitHub Issue) que rastreia uma operação ativa sobre uma Business Intent. Representa trabalho SOBRE a Intent — não é a Intent em si. A Intent é um artefato do Knowledge Space; o Work Item é uma representação efêmera do trabalho de execução.

**Exemplos de operações:** exploração, refinamento, revisão, promoção, particionamento.

**Cardinalidade:** Uma Business Intent pode ter zero ou mais Work Items ao longo de sua vida. A ausência de Work Item não é uma divergência — só é divergência quando há operação ativa sem Work Item rastreável.

**Não confundir com:** A Business Intent em si (artefato permanente). O OBC é um documento Markdown — não tem representação como Issue. Ver [knowledge-vs-execution.md](knowledge-vs-execution.md).
