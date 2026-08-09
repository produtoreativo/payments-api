# Framework Gaps — Lacunas Identificadas em Execução

> **Propósito:** Registro contínuo de lacunas, ambiguidades e comportamentos implícitos descobertos durante execução real do ProdOps. Cada entrada indica o que falta no Framework para tornar o processo mais preditivo, automatizável e menos dependente de conhecimento tácito.
>
> **Fonte:** Interações reais entre PM/PO e agente ProdOps. Não é backlog de features — é insumo para evolução do Framework.
>
> **Formato por entrada:** contexto → o que o Framework não diz → o que deveria dizer → impacto se omitido.

---

## GAP-001 — `runtime.yaml` usa `pilot-issue` fixo em vez de `active-issue` por iteração

**Contexto:** Durante a transição da iteração v0.1.0 para v0.2.0 (Boleto), o runtime continuava apontando para a issue #76 (PIX) porque `pilot-issue` era um campo fixo no `runtime.yaml`.

**O que o Framework não diz:** Como trocar o trabalho ativo entre iterações.

**O que deveria dizer:** O campo deve chamar-se `active-issue` e ser atualizado pelo `/readiness` ao declarar readiness para nova feature.

**Impacto se omitido:** Eventos emitidos durante o `/downstream` atualizam o GitHub Project e o Datadog para a issue errada.

**Status:** Corrigido em `runtime.yaml` (v0.3.0 → `active-issue`) e nos scripts `bootstrap-happy-path.sh`, `bootstrap-runtime.sh`, `runtime-doctor.sh`.

---

## GAP-002 — Downstream não atualiza `runtime.yaml` automaticamente ao declarar readiness

**Contexto:** O `runtime.yaml` precisou ser atualizado manualmente para `active-issue: 40`. O Downstream Readiness gera o `context.md` mas não toca o runtime config.

**O que deveria dizer:** O step de Readiness deve incluir: "atualize `github.active-issue` em `runtime.yaml` antes de emitir o primeiro evento."

**Status:** Lacuna aberta. O skill `/readiness` inclui essa instrução mas não há automação.

---

## GAP-003 — Milestone não era parte do fluxo canônico de Readiness

**Contexto:** A issue #40 foi adicionada ao Project sem milestone. Não havia gate que verificasse se a issue tem milestone antes de iniciar Bootstrap.

**O que deveria dizer:** A Readiness Gate do Downstream deve incluir: "issue associada a milestone da iteração ativa".

**Status:** Resolvido. Milestone incluída como Gate 6 no skill `/readiness`.

---

## GAP-004 — Adição da issue ao GitHub Project não era etapa explícita do Downstream

**Contexto:** A issue #40 foi criada mas não estava no Project #25. Foi adicionada manualmente.

**O que deveria dizer:** O Downstream Readiness deve verificar e executar `addProjectV2ItemById` automaticamente.

**Status:** Resolvido. Gate 7 no skill `/readiness` cobre verificação e adição automática.

---

## GAP-005 — Fechamento de milestone anterior não tem gate ou instrução no Framework

**Contexto:** Ao criar a milestone `v0.2.0`, a milestone anterior `v0.1.0-runtime-pilot` ainda estava aberta.

**O que deveria dizer:** Ao iniciar nova iteração, verificar se existe milestone aberta sem issues ativas e sugerir fechamento.

**Status:** Lacuna aberta. Candidato a verificação no Diligence Sync ou no step de abertura de iteração.

---

## GAP-006 — Iteration Plan não tem gate de consistência com GitHub Issues

**Contexto:** O Iteration Plan foi atualizado (Boleto como "Entrou", demais como "Saiu") mas as issues no GitHub não foram alteradas.

**O que deveria dizer:** Ao alterar status de item para "Saiu", propagar para milestone, Project e labels da issue.

**Status:** Lacuna aberta.

---

## GAP-007 — Business Signal não tem fluxo explícito para "funcionalidade já existe"

**Contexto:** O BS-MAGS-001 descobriu que boleto já estava implementado. O Framework não define o caminho "Signal → Investigação → Já existe → Downstream" sem Discovery completo.

**Status:** Lacuna aberta. Candidato a adição no skill `/upstream`.

---

## GAP-008 — `runtime.yaml` não documenta seu próprio ciclo de vida

**Contexto:** O arquivo não tem comentários explicando o propósito de cada campo, quem atualiza, quando e com qual comando.

**Status:** Lacuna aberta. Requer criação de `prodops/runtime/README.md`.

---

## GAP-009 — ADRs não têm localização canônica nem formato padronizado no Framework

**Contexto:** Decisões arquiteturais ficam em `prodops/artifacts/architecture/decision-trail.md` — narrativo, sem numeração, sem template.

**Status:** Lacuna aberta. Candidato a template em `prodops/templates/architecture/decision-record.md`.

---

## GAP-010 — O Framework não define Business Case como artefato explícito

**Contexto:** Não há template ou instrução para compor OBC + Experimentos + Reliability Plan + custo em um Business Case estruturado para aprovação de projeto.

**Status:** Lacuna aberta. Candidato a novo template no Discovery Upstream.

---

## GAP-011 — Downstream Readiness não verifica se a arquitetura foi impactada e documentada

**Contexto:** Não há gate que verifique se a feature introduz mudança estrutural que exige atualização do `architecture/overview.md`.

**O que deveria dizer:** O Finish (ou PR checklist) deve incluir: "se a feature introduz novo módulo, rota, tabela, evento ou integração, atualizar `overview.md` antes do PR ser aprovado."

**Status:** Lacuna aberta. Candidato a gate no Finish checklist.

---

## GAP-012 — CI Async não disparava deploy de staging para branches de feature

**Contexto:** O workflow `staging-deploy.yml` disparava apenas em push para `main` e uma branch hardcoded. O skill `/ship` não tinha instrução de como acionar o deploy.

**Status:** Corrigido. `staging-deploy.yml` atualizado com `workflow_dispatch`. Skill `/ship` atualizado com step de acionamento e wait.

---

## GAP-013 — Não existia comando de readiness isolado no Downstream

**Contexto:** Não havia como verificar gates sem iniciar Bootstrap.

**Status:** Resolvido. Skill `/readiness` criado em `prodops/skills/readiness/SKILL.md`.

---

## GAP-014 — Gate `no_mocks` escaneia `api/src` além de `api/test`, bloqueando unit tests legítimos

**Contexto:** Durante o CI Sync do DS-40, o Finish agent criou `invoice.service.spec.ts` em `api/src/` com `jest.fn()` e `.mockReturnValue()` para mockar dependências injetadas (InvoiceRepository, AsaasService) — prática correta para unit tests de camada de serviço. O gate `no_mocks` em `manifest.yaml` escaneia `[api/src, api/test]`, fazendo o CI falhar em dois pushes consecutivos.

**O que o Framework não diz:** A distinção entre "mock em teste de aceitação" (proibido — viola o No Mocks Rule) e "mock de dependência injetada em unit test" (permitido — isola a camada sob teste). O `manifest.yaml` não documenta que a regra se aplica apenas a `api/test/`.

**O que deveria dizer:** O gate `no_mocks` deve escanear apenas `api/test/`. Unit tests em `api/src/**/*.spec.ts` podem usar `jest.fn()` para criar doubles de dependências injetadas — isso não viola o No Mocks Rule, que proíbe substituir implementações reais em testes de aceitação.

**Impacto se omitido:** Qualquer unit test criado em `api/src/` com mocks de dependência vai falhar o CI gate, forçando workarounds incorretos (como mover os testes para `api/test/` ou eliminar o isolamento do unit test).

**Status:** Corrigido. `manifest.yaml` atualizado: `in: [api/test]` (removido `api/src`). Padrões expandidos para cobrir também `.mockRejectedValue(`, `.mockResolvedValue(`, `.mockImplementation(`.

---

## GAP-015 — hack-start stasha mudanças não commitadas, descartando alterações de skills e framework feitas durante o readiness

**Contexto:** Durante a preparação do DS-40, foram feitas alterações em `prodops/skills/downstream/SKILL.md` (Downstream ID, modo sem argumentos, tabela de comandos) e `prodops/skills/readiness/SKILL.md` (novo skill). Essas mudanças ficaram no working tree sem commit. Quando o `hack-start` agent executou, fez `git stash` das mudanças não commitadas antes de criar o branch `feat/40-create-invoice-boleto`, preservando-as no stash mas tornando-as invisíveis no branch de feature. O arquivo `framework-gaps.md` também foi perdido (não estava no stash).

**O que o Framework não diz:** Skills e artefatos de framework alterados durante Readiness/Downstream devem ser commitados antes de `hack-start` rodar. Não há instrução explícita sobre o que fazer com mudanças no working tree que não fazem parte do escopo da feature.

**O que deveria dizer:** O skill `/readiness` deve incluir: "commite quaisquer alterações de skills, framework ou ProdOps no branch atual antes de invocar `/downstream ci-sync`. O `hack-start` vai fazer stash de qualquer mudança pendente." Adicionalmente, mudanças em `prodops/skills/` e `prodops/framework/` realizadas durante a sessão devem ser commitadas em um commit separado antes do hack-start.

**Impacto se omitido:** Alterações de framework ficam no stash (recuperáveis mas invisíveis), enquanto arquivos criados mas não versionados pelo git (como `framework-gaps.md`) são perdidos permanentemente.

**Status:** Mitigado nesta sessão via `git show stash@{0}:<path> > <path>` para restaurar arquivos individuais. Requer adição de instrução explícita no skill `/readiness` e no skill `hack-start`.

---

## GAP-016 — Não existe Event Type para falha durante o Ship (Ship.Failed ausente no catálogo)

**Contexto:** O modelo operacional consolidado define que Ship detecta falhas durante a observação do fluxo autônomo do PR (check de CI, merge, deploy em Staging) e interrompe a progressão. No entanto, o catálogo de eventos da Delivery Journey (`prodops/framework/journeys/delivery/events/catalog.md`) e o catálogo de eventos do runtime (`prodops/runtime/catalog/events.yaml`) não definem nenhum `Ship.Failed` ou equivalente.

**O que o Framework não diz:** Como sinalizar via evento que o Ship detectou uma falha durante a observação — CI falhou, merge não ocorreu, ou deploy em Staging falhou.

**O que deveria dizer:** Um Event Type `Ship.Failed` (ou `Shared.Gate.Failed` com contexto Ship) deveria ser emitido quando Ship detecta falha, permitindo que a Diligence Journey detecte o estado BLOCKED e inicie ciclo de reconciliação.

**Impacto se omitido:** Falhas durante Ship são registradas apenas em texto no Release Trail, sem event-driven propagation. A Diligence Journey não pode reagir automaticamente ao estado de falha do Ship. O estado do Work Item permanece SHIPPING indefinidamente sem sinal canônico de falha.

**Status:** Lacuna aberta. Não criar eventos — documentar apenas. Candidato a próxima evolução do catálogo de eventos da Delivery Journey.

---

## GAP-017 — Ship.Started e Finish.Started emitidos pelos skills mas ausentes do catálogo de Event Types

**Contexto:** Os skills `prodops/skills/finish/SKILL.md` e `prodops/skills/ship/SKILL.md` emitem `Delivery.Finish.Started` e `Delivery.Ship.Started` respectivamente. No entanto, o catálogo de eventos da Delivery Journey (`prodops/framework/journeys/delivery/events/catalog.md`) lista apenas `Finish.Completed` e `Ship.Completed` — não há definição formal de `Finish.Started` nem `Ship.Started` como Event Types.

**O que o Framework não diz:** O catálogo não define as preconditions, postconditions, payload_shape ou alters_state dos eventos Started para Finish e Ship. Apenas os eventos Completed têm definição formal.

**O que deveria dizer:** Todos os eventos emitidos pelos skills devem ter uma entrada correspondente no catálogo de Event Types com schema completo.

**Impacto se omitido:** Consumers que processam eventos da Delivery Journey não têm schema formal para `Finish.Started` e `Ship.Started`. Validação de evento fica incompleta. A Timeline pode conter eventos não catalogados.

**Status:** Lacuna aberta. Não criar eventos — documentar apenas. Candidato a próxima versão do catálogo (v2.1.0 ou v3.0.0).

---

## GAP-018 — O catálogo de eventos usa "homologação" e "produção" — ambíguos com o modelo de ambientes consolidado

**Contexto:** O catálogo de eventos da Delivery Journey (`catalog.md`) usa os termos "ambiente de homologação" (Ship.Completed) e "produção" (Promote.Completed, Promote.Approved). O modelo operacional consolidado define: Staging (efêmero por Feature), Sandbox (compartilhado, Release Candidate) e Production (fora da Journey).

**O que o Framework não diz:** Se "homologação" no catálogo equivale a Staging ou Sandbox. Se "produção" no Promote.Completed significa que Promote leva a Production (errado no novo modelo) ou Sandbox.

**O que deveria dizer:** Os descritivos dos eventos do catálogo devem usar os termos canônicos: Staging, Sandbox, Production — não "homologação" e "produção" de forma genérica.

**Impacto se omitido:** Ambiguidade entre o catálogo de eventos e o modelo operacional. Agentes que leem o catálogo podem inferir que Promote leva para Production, contradizendo o modelo operacional consolidado que coloca Production fora da Delivery Journey.

**Status:** Lacuna aberta. Não alterar o catálogo de eventos neste ciclo — documentar apenas. Candidato a próxima versão do catálogo.

---

## GAP-019 — O nome `release-trail.md` designa dois artefatos de camadas diferentes

**Contexto:** Durante a refatoração do Finish (branch `refine/11-finish-v2`), foram encontrados 7 arquivos de trail fora de `prodops/artifacts/trails/sessions/`. Ao inspecioná-los, eram dois artefatos distintos com o mesmo nome: 3 eram session trails de verdade (UUID de sessão, convenção `YYYY-MM-DD-<session-id>.md`) que haviam sido escritos dentro de `iterations/<version>/trails/`; os outros 4 eram evidência de TDD escopada por iteração ou card (`# Release Trail — v0.9.0`), sem qualquer identidade de sessão.

**O que o Framework não diz:** Que "Release Trail" designa exclusivamente o log append-only de sessões. Não existe nome canônico para o artefato que consolida evidência de teste de uma entrega dentro de uma iteração, então ele herdou o nome do conceito do Framework.

**O que deveria dizer:** Release Trail é ontologia do Framework — endereçado por session ID, vive em `trails/sessions/`. O trail por iteração/card é artefato de produto — endereçado por versão ou slug, vive em `iterations/<version>/`. São camadas diferentes na tabela de `contributor-philosophy.md` ("trail templates → Runtime" vs "textos de trail do produto → Produto") e não devem compartilhar nome.

**Impacto se omitido:** Um agente que lê `iterations/v0.9.0/release-trail.md` pode inferir que trails são escopados por iteração e passar a escrever session trails lá — foi exatamente o que aconteceu com os 3 arquivos encontrados. A colisão de nome propaga o erro de localização.

**Status:** Mitigado em `refine/11-finish-v2`. Os 4 agregados foram renomeados para `iteration-trail*.md` e `release-trail.md` ganhou a seção "Release Trail ≠ Iteration Trail". Falta o Framework nomear formalmente esse artefato — hoje `iteration-trail` é convenção do produto, não definição do Framework. O nome descreve o escopo (uma entrega dentro de uma iteração) em vez do conteúdo, porque os 4 arquivos não são homogêneos: dois são evidência de TDD, um é registro de entrega (`DS-58 — RT Iteration Lifecycle Automation`) e um é trail de card.

**Dívida residual:** 20 capsules já geradas, em 8 iterações (v0.6.0, v0.7.0, v0.9.0 a v0.14.0), ainda declaram `session-trail-dir: prodops/artifacts/iterations/<version>/trails/`. O template foi corrigido, mas capsules são artefato gerado e não devem ser editadas à mão — a correção correta é regenerar via `/downstream`, não um sed em massa. Até lá, um agente que ler uma capsule antiga recebe o path errado. Os diretórios `trails/` correspondentes foram removidos: mantê-los vazios preservaria exatamente o layout que a Regra 1 declara desvio.

---

## GAP-020 — Gates de qualidade acoplam ferramenta, credencial e endpoint ao produto

**Contexto:** Os gates `scripts/check-code-analysis.sh` e `scripts/check-dependencies.sh` implementam análise estática e verificação de dependências, mas hardcodam a escolha de ferramenta e a topologia local: container `sonarqube`, `localhost:9000`, imagem do scanner, e leitura de `SNYK_TOKEN` a partir de `api/.env`.

**O que o Framework não diz:** Onde termina a definição do gate (o que precisa ser verificado antes de um PR mergear) e onde começa a escolha de implementação (com qual ferramenta, em qual endpoint, com qual credencial). A tabela de `contributor-philosophy.md` cobre "credenciais e endpoints → Produto", mas não diz qual camada define o gate em si.

**O que deveria dizer:** O Framework define quais classes de gate existem (análise estática, dependências, cobertura, aceitação) e o contrato de exit code. O Runtime oferece uma implementação de referência opinativa. O produto fornece credenciais, endpoints e limiares.

**Impacto se omitido:** Cada produto reimplementa os mesmos gates do zero, e a RI não consegue exportar verificação de qualidade sem arrastar junto a escolha de ferramenta.

**Status:** Lacuna aberta. **Não promover para o Runtime neste ciclo** — os gates têm um único consumidor real, e `contributor-philosophy.md` (pergunta 2) exige dois casos reais antes de generalizar. Documentar apenas; reavaliar quando um segundo consumidor existir.

---

## GAP-021 — `materialize-skills.sh` assumia um skill = um arquivo

**Contexto:** O script materializava apenas `prodops/skills/<skill>/SKILL.md` para os três players. Quando `finish` e `hack` passaram a ser multi-arquivo (`steps/<step>/SKILL.md`), os sub-steps nunca chegavam a `.claude/`, `.agents/` e `.github/` — mas o `SKILL.md` materializado continuava linkando para eles com paths relativos à origem. O resultado eram links pendurados em todos os players, sem nenhum sinal de erro: o `--check` só compara o `SKILL.md` de topo e reportava "up-to-date".

**O que o Framework não diz:** Que um skill pode ser multi-arquivo, e que a materialização é responsável pela subárvore inteira — não só pelo arquivo de entrada.

**O que deveria dizer:** A unidade de materialização é o diretório do skill, não o `SKILL.md`. Qualquer arquivo referenciado por path relativo a partir do skill precisa existir no destino, senão o contrato lido pelo player está incompleto.

**Impacto se omitido:** Codex e Copilot leem um `SKILL.md` que manda abrir `steps/validate/SKILL.md` e não encontram o arquivo. O agente executa a fase sem a definição do sub-passo, ou inventa o comportamento. Silencioso porque o gate de drift não olhava a subárvore.

**Status:** Corrigido em `refine/11-finish-v2`. `materialize-skills.sh` ganhou `materialize_steps()`, chamada inclusive quando o `SKILL.md` de topo está up-to-date (o pai estar em dia não diz nada sobre os filhos). Corrige `finish` (multi-arquivo introduzido nesta branch) e também `hack`, que tinha o mesmo defeito latente desde antes.
