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
