---
name: downstream
description: Orquestra a execução do fluxo de entrega governado do ProdOps. Sem argumentos, lê o Iteration Plan e executa os itens com status Entrou em ordem de prioridade. Com Downstream ID, executa apenas aquele item.
---
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/downstream/SKILL.md
     Player:    copilot
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: 2026-08-06T13:38:31Z
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill downstream
-->

# DOWNSTREAM

Downstream é o modo de compromisso do Framework ProdOps. Toda entrega passa obrigatoriamente pelos gates de readiness e pelos ciclos CI Sync e CI Async. O orchestrator nunca bypassa pré-requisitos nem inventa artefatos.

## Downstream ID

Cada item do Downstream possui um **Downstream ID** — o identificador estável da feature ao longo das iterações:

```
DS-<feature-slug-number>
```

O DS-ID identifica a **feature** (estável), não a GitHub Issue (efêmera — muda a cada iteração). O mapeamento `DS-ID → issue` é declarado no `plan.md` da iteração ativa. O agente resolve `DS-39 → issue #106` lendo a tabela de mapeamento do plano, nunca inferindo do número do DS-ID.

## Resolução de skills e configuração do projeto

Ler `prodops/runtime/runtime.yaml` **uma única vez** no início da execução e extrair:

- **Paths de skill** — seção `skills:`. Nunca usar `find` ou `ls` para localizar arquivos de skill.
- **Configuração do GitHub Project** — seção `github:`, campos `owner` e `project-number`.

```yaml
# prodops/runtime/runtime.yaml
github:
  owner: produtoreativo
  project-number: 25
skills:
  bootstrap: prodops/skills/bootstrap/SKILL.md
  hack:      prodops/skills/hack/SKILL.md
  # ...
```

Armazenar os valores como variáveis para uso em todos os comandos `gh project`:

```bash
PROJECT_OWNER=$(python3 -c "import yaml; d=yaml.safe_load(open('prodops/runtime/runtime.yaml')); print(d['github']['owner'])")
PROJECT_NUMBER=$(python3 -c "import yaml; d=yaml.safe_load(open('prodops/runtime/runtime.yaml')); print(d['github']['project-number'])")
```

Para invocar um skill: extrair o path da seção `skills:` → ler o arquivo diretamente com o path canônico.

## Iteration Directory

Ao iniciar qualquer execução, o agente resolve o **ITERATION_DIR** a partir do `iteration-id` declarado no plano ativo:

```
ITERATION_DIR = prodops/artifacts/iterations/<iteration-id>/
```

Todos os artefatos de runtime desta iteração vivem exclusivamente dentro deste diretório:
- Timelines: `ITERATION_DIR/runtime/timelines/<issue>.json`
- Plan Bootstrap: `ITERATION_DIR/runtime/plan-bootstrap.json`
- Plan Validate: `ITERATION_DIR/runtime/plan-validate.json`
- Context capsules: `ITERATION_DIR/cards/<slug>/context.md`
- Session trails: `ITERATION_DIR/trails/`

O `--iteration-id` é propagado para todas as chamadas de `emit-event`, `append.sh`, `derive-state.sh` e `derive-diligence-state.sh`. Nenhum artefato de runtime é escrito fora do ITERATION_DIR da iteração corrente.

## Comandos

| Comando | Escopo |
|---|---|
| `/downstream` | Lê o Iteration Plan, lista os itens `Entrou` em ordem de prioridade e executa CI Sync um a um |
| `/downstream <DS-ID>` | Executa CI Sync apenas para o item com aquele Downstream ID (ex: `/downstream DS-40`) |
| `/downstream ci-sync <DS-ID ou capability>` | Readiness → Bootstrap → Hack → Sync → Finish para o item indicado |
| `/downstream ci-async <DS-ID ou capability>` | Verifica evidências do CI Sync → Ship → Validate → Promote |
| `/downstream full <DS-ID ou capability>` | CI Sync completo → CI Async completo |
| `/downstream recheck` | Apaga `readiness-gate.json` e executa gate check completo — ignora cache |
| `/readiness <capability>` | Verifica pré-requisitos e gera context capsule — sem iniciar implementação |

Use `/readiness` quando quiser verificar gates e preparar o context capsule sem iniciar implementação. Use `/downstream <DS-ID>` quando estiver pronto para iniciar Bootstrap e Hack de um item específico.

## Modo sem argumentos — `/downstream`

Quando invocado sem argumentos:

1. Ler `prodops/artifacts/plans/iteration-plan.md` → identificar a versão ativa (ex: `v0.6.0`).
2. Ler `prodops/artifacts/iterations/<version>/plan.md` → resolver `ITERATION_ID` e coletar todos os itens com status `Entrou` da tabela de escopo, usando a tabela de mapeamento DS-ID → Issue para obter os números de issue corretos.
3. **Readiness Cache Check** — verificar `ITERATION_DIR/runtime/readiness-gate.json` **antes de qualquer gate check ou Plan Bootstrap**:
   a. Se o arquivo não existe: continuar normalmente para o passo 4.
   b. Se `"result": "ready"`: continuar normalmente para o passo 4.
   c. Se `"result": "blocked"`:
      - Para cada capability em `capabilities`, checar se algum `missing-artifacts` agora existe no disco:
        ```bash
        test -f <artifact-path>
        ```
      - Se **nenhum** artefato novo apareceu: exibir o resultado cacheado abaixo e **parar imediatamente** — não gastar tokens em gate check.
        ```
        ⛔ Readiness bloqueada (resultado cacheado — <checked-at>)
        Gates faltando: <lista de capabilities e gates>
        Artefatos ausentes: <lista de paths>
        Próximo passo: <next-action>
        Re-check forçado: /downstream recheck
        ```
      - Se **qualquer** artefato ausente agora existe: ignorar o cache, deletar o arquivo e continuar para o passo 4 com gate check completo.

4. Apresentar a fila de execução na ordem em que aparecem no Iteration Plan (ordem de prioridade do PM/PO):

```
Fila Downstream — Iteration Plan ativo
────────────────────────────────────────
1. DS-40  create-invoice-boleto
...
```

5. **Plan Bootstrap** — executar uma única vez antes do loop de issues:
   a. Verificar se `ITERATION_DIR/runtime/plan-bootstrap.json` já existe com `"status": "completed"`. Se sim, pular para o passo 6 (ambiente já pronto).
   b. Emitir `Delivery.Plan.Bootstrap.Started` com `subject: <iteration-id>`, `work-item-id: null` e `--iteration-id <iteration-id>`. Verificar `"datadog-sync"` e `"github-sync"` na saída — exibir aviso se erro.

   **Etapa 1 — Project Cleanup:** remover todos os items existentes do GitHub Project.
   ```bash
   bash prodops/runtime/scripts/project-cleanup.sh
   ```
   Seguro quando o projeto estiver vazio — exit 0. Após executar, emitir `Delivery.Plan.Bootstrap.Project.Cleaned`.

   **Etapa 2 — Issue de acompanhamento:** verificar se já existe uma issue com título `[Iteration <iteration-id>]:` no GitHub:
   ```bash
   gh issue list --search "[Iteration <iteration-id>]" --state all --json number,title | jq '.[0].number // empty'
   ```
   - Se **não existir**: criar. Antes da criação, obter o login do usuário autenticado:
     ```bash
     CE_LOGIN=$(gh api user --jq '.login')
     ```
     Criar a issue incluindo o assignee (falha não-fatal — se o GitHub rejeitar o assignee, criar sem ele e registrar aviso no trail):
     ```bash
     gh issue create \
       --title "[Iteration <iteration-id>]: <scope-summary>" \
       --label "prodops,artifact-type:iteration-plan" \
       --assignee "$CE_LOGIN" \
       --body "Iteration Plan: prodops/artifacts/iterations/<iteration-id>/plan.md\n\nCapabilities: <DS-IDs>\nIssues: <issue-numbers>"
     ```
     Se o comando falhar apenas por causa do `--assignee`, repetir sem `--assignee` e registrar aviso:
     `⚠️ Assignee não pôde ser adicionado à tracking issue — issue criada sem assignee`.
   - Se já existir: anotar o número e continuar.
   Emitir `Delivery.Plan.Bootstrap.Issue.Registered` com o número registrado no payload.

   **Etapa 3 — Registrar issues no plano:** para cada issue do Iteration Plan (todas com status `Entrou`), na ordem de prioridade:
   1. Gerar um novo UUID — este será o `correlation-id` de toda a jornada desta issue.
   2. Emitir `Delivery.Plan.Bootstrap.Issue.Entered` com `work-item-id: <issue-number>`:
      ```json
      {
        "event": "Delivery.Plan.Bootstrap.Issue.Entered",
        "work-item-id": "<issue-number>",
        "iteration-id": "<iteration-id>",
        "correlation-id": "<novo-uuid>",
        "execution-id": "<new-uuid>",
        "actor": { "player": "<player>", "agent": "downstream-agent" },
        "payload": { "ds-id": "<DS-ID>", "slug": "<capability-slug>" }
      }
      ```
   3. Escrever `ITERATION_DIR/cards/<card-slug>/context.md` a partir de `prodops/templates/delivery/context-capsule.md` com o `correlation-id` gerado e todos os campos do template (ds-id, work-item-id, iteration-id, paths, BDD scenarios etc.).

   O dispatcher reage a cada `Plan.Bootstrap.Issue.Entered` e dispara `Diligence.Capture` automaticamente para esta issue.

   **Etapa 4 — Adicionar issues ao Project:** adicionar ao GitHub Project a tracking issue da iteração **e** todas as feature issues do Iteration Plan com status `Entrou`:
   ```bash
   # TRACKING_ISSUE foi obtida na Etapa 2 (número da issue de acompanhamento)
   for ISSUE_NUMBER in "$TRACKING_ISSUE" <lista-de-feature-issues>; do
     gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "https://github.com/$PROJECT_OWNER/payments-api/issues/$ISSUE_NUMBER"
   done
   ```
   A tracking issue deve ser a **primeira** a ser adicionada. Após adicionar todas, emitir `Delivery.Plan.Bootstrap.Issues.Added`.

   **Etapa 5 — Instalar dependências:** instalar dependências com o gerenciador de pacotes declarado. Se falhar: parar toda a fila. Após instalar, emitir `Delivery.Plan.Bootstrap.Dependencies.Installed`.

   **Etapa 6 — Infraestrutura local:** verificar runtimes e CLIs, subir serviços locais (Docker, LocalStack). Se qualquer serviço não estiver reachable: parar toda a fila. Após todos os serviços confirmados, emitir `Delivery.Plan.Bootstrap.Services.Ready`.

   **Etapa 7 — Smoke gate:** executar o gate `smoke` definido em `prodops/exec/manifest.yaml`. Se falhar: parar toda a fila. Após passar, emitir `Delivery.Plan.Bootstrap.Smoke.Passed`.

   c. Escrever `ITERATION_DIR/runtime/plan-bootstrap.json` **antes** de emitir `Plan.Bootstrap.Completed` — o dispatcher reage ao evento e `trail.sh` precisa do arquivo para construir o comentário na issue:
   ```json
   {
     "iteration-id": "<iteration-id>",
     "status": "completed",
     "correlation-id": "<uuid-gerado-no-started>",
     "completed-at": "<timestamp-iso8601>",
     "plan-issue": <número-da-issue-de-acompanhamento>,
     "issues": ["<issue-1>", "<issue-2>", "..."]
   }
   ```
   d. Emitir `Delivery.Plan.Bootstrap.Completed` com `subject: <iteration-id>` e `--iteration-id <iteration-id>`. Verificar `"datadog-sync"`, `"github-sync"` e `"dispatch.status"` na saída — exibir aviso se qualquer campo retornar `"error"` ou `"failed"`.
   e. Commitar o arquivo no repositório antes de iniciar o loop.

6. Para cada item na fila, em ordem, sem pedir confirmação entre eles:
   a. Executar `/readiness <capability>` — se falhar: gravar `readiness-gate.json` com `"result": "blocked"` (ver seção **Readiness Cache**) e **parar toda a fila**.
   b. Executar CI Sync: Bootstrap → Hack → Sync → Finish — **em sequência estrita e síncrona**. Cada fase é um sub-agente invocado com `run_in_background: false`. Nunca spawnar uma fase em background. Nunca iniciar a fase seguinte antes de receber o resultado da fase anterior. Após **cada fase concluída**:

      **6b-i — Verificar saída de cada emit-event:** o emit-event retorna JSON com campos `"datadog-sync"`, `"github-sync"` e `"dispatch.status"`. Após **cada chamada** de emit-event (em qualquer fase), capturar o JSON e verificar os três campos:
      ```bash
      RESULT=$(bash prodops/runtime/tools/emit-event/scripts/emit-event --input <event.json>)
      echo "$RESULT" | jq -r '"datadog-sync: \(."datadog-sync") | github-sync: \(."github-sync") | dispatch: \(.dispatch.status)"'
      ```
      Se `"datadog-sync": "error"` → exibir: `⚠️ Datadog sync falhou — evento registrado na timeline local mas não enviado ao Datadog`.
      Se `"github-sync": "error"` → exibir: `⚠️ GitHub sync falhou — oem-state NÃO foi atualizado no Project`. Neste caso **não avançar** para a próxima fase sem resolver, pois o estado do Project ficará inconsistente.
      Se `"dispatch.status": "failed"` → exibir: `⚠️ Dispatch falhou — subscribers não notificados (trail e diligence podem estar incompletos)`. Não-fatal: continuar execução mas registrar no trail da issue.

      **6b-ii — Registrar trail entry obrigatória na issue (por phase):**

      Este passo é composto por duas entradas de trail por phase: uma ao **iniciar** a phase e outra ao **concluir** (ou falhar). Ambas devem ser postadas antes de avançar qualquer estado.

      **Campos obrigatórios em toda entry de trail:** `phase-name`, `work-item-id`, `status`, `timestamp`. A ausência de qualquer campo invalida a entry como evidência auditável.

      **Entry de início de phase** — postar imediatamente antes de invocar o sub-agente da phase:
      ```bash
      gh issue comment <work-item-id> --body "## Trail — <Fase> Iniciada — <YYYY-MM-DDTHH:MM:SSZ>

      **phase:** <Fase>
      **work-item-id:** <work-item-id>
      **status:** started
      **timestamp:** <YYYY-MM-DDTHH:MM:SSZ>

      ---
      *correlation-id: <uuid> · iteration: <iteration-id> · actor: <player>*"
      ```

      **Entry de conclusão de phase** — postar após receber o resultado do sub-agente e **antes de avançar para a próxima phase**:
      ```bash
      gh issue comment <work-item-id> --body "## Trail — <Fase> — <YYYY-MM-DDTHH:MM:SSZ>

      **phase:** <Fase>
      **work-item-id:** <work-item-id>
      **status:** <completed | failed | blocked>
      **timestamp:** <YYYY-MM-DDTHH:MM:SSZ>

      <resumo em até 5 linhas: o que foi feito, evidências principais, próximo passo>

      ---
      *correlation-id: <uuid> · iteration: <iteration-id> · actor: <player>*"
      ```

      **Regras de trail:**
      - A entry de conclusão deve ser postada **antes de avançar à próxima phase ou issue** — nunca após.
      - Postar mesmo em caso de falha ou bloqueio — o comentário deve descrever o motivo e a ação necessária.
      - **Falha ao postar trail é não-fatal:** se `gh issue comment` retornar erro, registrar aviso interno (`⚠️ Trail entry falhou — <motivo>`) e continuar a execução normalmente. A incapacidade de registrar trail não deve bloquear nem interromper o loop de execução.
      - O trail parcial (entries de início sem entries de conclusão) é suficiente para diagnosticar a última phase executada em caso de interrupção mid-flight.
   c. Reportar evidências do item concluído e avançar automaticamente para o próximo.

Parar apenas quando: (1) um readiness falhar, (2) um gate de qualidade não passar, (3) a fila se esgotar.

## Modo por Downstream ID — `/downstream DS-<n>`

Quando invocado com um Downstream ID:

1. Resolver a capability a partir do número de issue (`DS-40` → issue #40 → `create-invoice-boleto`).
2. Verificar que o item consta no Iteration Plan com status `Entrou`.
3. Executar `/readiness <capability>`.
4. Se Ready: confirmar com o usuário e executar CI Sync.

## Gate de readiness

Antes de executar qualquer ciclo, avaliar a capability contra todos os pré-requisitos atuais do Downstream:

1. OBC committed em `prodops/artifacts/obcs/`.
2. BDD Feature committed em `prodops/artifacts/bdd/`.
3. Riscos documentados em `prodops/artifacts/risks/risks.md`.
4. Item no Iteration Plan com status `Entrou`.
5. GitHub Issue existente e mapeada na coluna `Issue` do `plan.md` da iteração ativa.

Tratar como **Downstream Declared** enquanto houver pré-requisitos ausentes. Declarar **Downstream Ready** apenas após os cinco gates passarem. **Delivery Started** começa somente quando o Bootstrap inicia.

Reliability Plan (`prodops/artifacts/plans/reliability/<capability>.md`) é opcional. Se existir, incluir `reliability-path` na capsule e referenciar SLOs nas fases de Validate e Promote. Sua ausência não bloqueia o flow.

## Readiness Cache

Para evitar consumo de tokens em invocações repetidas com gates bloqueados, o resultado do gate check é persistido em `ITERATION_DIR/runtime/readiness-gate.json`.

### Formato

```json
{
  "iteration-id": "<iteration-id>",
  "checked-at": "<timestamp-iso8601>",
  "result": "blocked",
  "capabilities": {
    "<DS-ID>": {
      "slug": "<capability-slug>",
      "gates": {
        "obc": false,
        "bdd": false,
        "risks": false,
        "iteration-plan": true,
        "github-issue": true
      },
      "missing-artifacts": [
        "prodops/artifacts/obcs/<slug>.md",
        "prodops/artifacts/bdd/<slug>.feature"
      ]
    }
  },
  "next-action": "Criar artefatos via /upstream antes de re-invocar /downstream"
}
```

### Regras

1. **Gravar ao falhar**: quando qualquer gate de readiness falhar, gravar o arquivo com `"result": "blocked"` antes de parar.
2. **Fast path de bloqueio**: se o arquivo existe com `"result": "blocked"` e **nenhum** `missing-artifact` apareceu no disco, parar imediatamente sem re-executar o gate check.
3. **Auto-invalidação**: se qualquer artefato listado em `missing-artifacts` agora existe (`test -f <path>`), deletar o arquivo e executar o gate check completo.
4. **Limpeza após passe**: quando todos os gates passarem, gravar `"result": "ready"` (sobrescreve o blocked anterior).
5. **Re-check forçado**: `/downstream recheck` apaga o arquivo e executa gate check completo independentemente do estado atual.
6. **Commitar**: após gravar ou atualizar o arquivo, incluir no próximo commit de artefatos de runtime da iteração.

### Gate 5 — criação de Issue quando ausente

Se o item estiver no Iteration Plan com status `Entrou` mas sem Issue mapeada:

1. Obter o login do usuário autenticado (reutilizar `CE_LOGIN` se já capturado no Plan Bootstrap, ou capturar agora):
   ```bash
   CE_LOGIN=$(gh api user --jq '.login')
   ```
2. Criar Issue via `gh issue create` incluindo o assignee (falha não-fatal — se o GitHub rejeitar o `--assignee`, criar sem ele e registrar aviso no trail: `⚠️ Assignee não pôde ser adicionado à issue DS-<n> — issue criada sem assignee`):
   - **Título:** `[DS-<n>]: <capability-description>`
   - **Body:** incluir DS-ID, iteration-id, OBC path, BDD path e link para o plan.md
   - **Labels:** `journey:delivery`, `artifact-type:local-obc`, `operation:implement`
   - **Assignee:** `--assignee "$CE_LOGIN"`
3. Atualizar a coluna `Issue` do `plan.md` com o número criado.
4. Commitar `plan.md` antes de continuar.

Não associar ao Project aqui — a adição de todas as issues ao Project ocorre de forma centralizada na Etapa 3 do Plan Bootstrap (`Plan.Bootstrap.Issues.Added`).

Nunca iniciar Bootstrap sem Issue mapeada — o `work-item-id` da capsule e dos eventos depende desse número.

Quando todos os pré-requisitos existirem:

### Protocolo de Restart (se a timeline já tem eventos)

**Antes de emitir qualquer evento**, verificar se a timeline do item já existe com eventos de uma execução anterior:

```bash
TIMELINE="$ITERATION_DIR/runtime/timelines/<work-item-id>.json"
test -f "$TIMELINE" && jq -e 'length > 0' "$TIMELINE" >/dev/null 2>&1
```

- **Timeline existe com eventos** → esta é uma execução de restart. Extrair o `correlation-id` anterior da timeline:
  ```bash
  PREV_CORR=$(jq -r '.[0].data["runtime-correlation-id"]' "$TIMELINE")
  ```
  Emitir os três eventos de Restart usando o `correlation-id` **anterior** (liga o histórico):
  ```json
  { "event": "Delivery.Restart.Requested", "work-item-id": "<work-item-id>", "iteration-id": "<iteration-id>", "correlation-id": "<PREV_CORR>", "execution-id": "<new-uuid>", "actor": { "player": "<player>", "agent": "downstream-agent" }, "payload": {} }
  { "event": "Delivery.Restart.Started",   "correlation-id": "<PREV_CORR>", ... }
  { "event": "Delivery.Restart.Completed", "correlation-id": "<PREV_CORR>", ... }
  ```
  Depois gerar um **novo UUID** para esta execução. Todos os eventos de fase seguintes usam o novo `correlation-id`.

- **Timeline não existe ou está vazia** → primeira execução. Gerar novo UUID diretamente. Nenhum evento de Restart.

Os eventos de Restart não alteram `oem-state` — são puramente auditáveis. O Restart não re-emite `Plan.Bootstrap.Issue.Entered` — esse evento é responsabilidade exclusiva do Plan Bootstrap. Em restart, sobrescrever a capsule com o novo `correlation-id` antes de invocar Bootstrap. **Eventos de Restart são puramente auditáveis; as fases seguintes usam o novo `correlation-id`.**

### Carregar capsule da issue

A capsule foi escrita pelo Plan Bootstrap na Etapa 3 (`Delivery.Plan.Bootstrap.Issue.Entered`). Ler `ITERATION_DIR/cards/<card-slug>/context.md`:

- Se **restart**: sobrescrever o campo `correlation-id` na capsule com o novo UUID gerado no Protocolo de Restart acima e atualizar `oem-state: PENDING`.
- Se **primeira execução**: usar a capsule sem modificação — o `correlation-id` já está correto.

O capsule é o único artefato que o agente precisa carregar para executar o flow inteiro sem reler arquivos de infraestrutura. O `correlation-id` propagado aqui é usado pelo Bootstrap, Hack, Sync, Finish, Ship, Validate e Promote.

## CI Sync

1. **Bootstrap** — quando invocado dentro do loop do `/downstream` (modo sem argumentos ou por DS-ID a partir de um plano), o Bootstrap opera em fast path se o Plan Bootstrap já completou: emite apenas os eventos Started/Completed sem re-executar dependências ou smoke gate. Em execuções isoladas (sem Plan Bootstrap), executa o fluxo completo.
2. **Hack** — executar `start`, `tdd` e `commit`; `start` é dono do Git flow e da criação de branch.
3. **Sync** — sincronizar a branch e alinhar artefatos ProdOps impactados.
4. **Finish** — executar quality gates finais e preparar o PR.

## CI Async

O CI Async opera em três fases sequenciais sobre todos os itens do plano:

**Fase 1 — Ship (por issue, em sequência)**
Para cada issue na fila do plano, em ordem:
1. Confirmar que evidências do CI Sync existem e foram aprovadas.
2. Acionar `staging-deploy.yml` via `gh workflow run` e aguardar conclusão.
3. Avançar para a próxima issue sem aguardar Validate.

**Fase 2 — Validate (por issue, em sequência)**
Para cada issue na fila do plano, em ordem:
1. Validar BDD, OBC, observabilidade, SLOs e riscos no ambiente alvo.
2. Após `Validate.Completed`: atualizar `plan-validate-<iteration-id>.json` marcando a issue como validada.
3. Após a última issue validar: emitir `Delivery.Plan.Validated` — o gate de plano passa.
4. Se qualquer Validate falhar: **parar toda a fase 3**. Nenhum Promote ocorre enquanto houver issues pendentes.

**Fase 3 — Promote (por issue, em sequência — gate de plano obrigatório)**
Só iniciada após `Delivery.Plan.Validated` emitido:
1. Para cada issue na fila do plano, em ordem: aplicar gates de aprovação e registrar no Release Trail.
2. O Promote de cada issue verifica `plan-validate-<iteration-id>.json` antes de emitir `Promote.Started`.

**Nota sobre execuções standalone** (`/downstream ci-async DS-<n>`): sem contexto de Iteration Plan, o CI Async opera por issue de forma independente (Ship → Validate → Promote) sem gate de plano.

## Fechamento de iteração

O fechamento é executado imediatamente após o último `Promote.Completed` da iteração — nunca antes, nunca postergado para a próxima sessão.

### Gatilho

Todas as condições abaixo devem ser verdadeiras:

1. `ITERATION_DIR/runtime/plan-validate.json` tem `"status": "all-validated"`.
2. Todas as issues do plano estão `CLOSED` no GitHub (`gh issue view <n> --json state`).
3. Todos os PRs correspondentes estão `MERGED`.

Se **qualquer** issue do plano ainda não atingiu `Promote.Completed`, o step de Iteration Closure **não** fecha a tracking issue. Registrar aviso listando as issues pendentes:
```
⚠️ Iteration Closure bloqueado — issues ainda pendentes de Promote.Completed: <lista de issue-numbers>
Tracking issue NÃO fechada. Re-invocar após todos os Promotes.
```

### Ações de fechamento (em ordem)

0. **Fechar tracking issue da iteração (auto-close):**
   Resolver o número da tracking issue a partir de `ITERATION_DIR/runtime/plan-bootstrap.json` (campo `plan-issue`).
   Verificar se a tracking issue já está fechada (idempotência):
   ```bash
   TRACKING_STATE=$(gh issue view <plan-issue> --json state --jq '.state')
   ```
   - Se `TRACKING_STATE == "CLOSED"`: nenhuma ação — não reabrir, não postar comment duplicado. Registrar no trail: `ℹ️ Tracking issue #<plan-issue> já estava fechada — nenhuma ação executada.` e continuar.
   - Se `TRACKING_STATE == "OPEN"`:
     a. Postar comment de encerramento:
        ```bash
        gh issue comment <plan-issue> --body "## Iteração <iteration-id> — Encerramento Automático

        **Data:** <YYYY-MM-DD>

        **DS-IDs entregues:** <lista DS-IDs, ex: DS-57, DS-58, DS-59, DS-60>

        **PRs mergeados:** <lista de PRs, ex: #148, #149, #150, #151>

        Todos os Promotes concluídos. Iteração encerrada pelo downstream-agent.

        ---
        *iteration: <iteration-id> · actor: <player>*"
        ```
     b. Fechar a tracking issue:
        ```bash
        gh issue close <plan-issue>
        ```

1. **Atualizar `ITERATION_DIR/plan.md`:**
   - Header: `# Iteration Plan — <iteration-id>` (remover sufixo `(Ativo)`)
   - Status: `✅ Concluído — <YYYY-MM-DD>`
   - Coluna `Status` de cada item: `Entrou` → `Concluído`
   - Adicionar coluna `PR` com o número do PR mergeado por item
   - Marcar critérios de saída cumpridos com `[x]`; critérios não cumpridos permanecem `[ ]` com nota explicativa

2. **Atualizar `prodops/artifacts/plans/iteration-plan.md`:**
   - Mover a linha da iteração ativa para a tabela de histórico
   - Status: `✅ Concluído — PRs #<n>–#<m>`
   - Substituir a seção "Iteração corrente" por: `Nenhuma iteração ativa. Próxima iteração a definir.`

3. **Commitar — adicionar todos os arquivos modificados antes do commit:**
   ```bash
   git add prodops/artifacts/iterations/<iteration-id>/plan.md
   git add prodops/artifacts/plans/iteration-plan.md
   git add prodops/artifacts/iterations/<iteration-id>/runtime/
   git add prodops/artifacts/iterations/<iteration-id>/cards/
   git add prodops/artifacts/trails/
   git status  # verificar que não há arquivos faltando antes de commitar
   git commit -m "chore(prodops): close iteration <iteration-id> — all <N> items promoted"
   ```
   Executar `git status` após o `git add` e antes do `commit` — se houver arquivos modificados não staged, adicioná-los antes de prosseguir.

### O que NÃO fazer no fechamento

- Não criar nova iteração no mesmo commit de fechamento — são atos distintos.
- Não apagar nem mover `runtime/` — os artefatos de runtime pertencem ao histórico da iteração.
- Não marcar `[x]` em critérios que não foram satisfeitos — registrar a exceção em nota.

### Iteração com critérios parciais

Se ao menos um critério de saída não foi cumprido (ex.: timelines ausentes, Diligence pendente):
- Fechar mesmo assim se todos os gates operacionais (PRs merged, issues closed, plan-validate all-validated) passaram.
- Registrar a exceção em nota de fechamento no `plan.md` da iteração.
- Aplicar o protocolo de issues de follow-up abaixo.

### Issues de follow-up — inconsistências e problemas detectados

Ao concluir cada fase e ao fechar a iteração, o agente deve identificar e registrar toda inconsistência, problema residual ou débito detectado durante a execução. Para cada item identificado:

**1. Criar GitHub Issue com:**
- **Título:** descrição objetiva do problema (`[follow-up]: <descrição concisa>` ou título canônico do Work Item Schema)
- **Body:** origem (fase onde foi detectado), impacto, próxima ação concreta
- **Labels:** `journey:diligence`, `artifact-type:business-signal`, `operation:capture`
- **Referências:** issue da iteração que originou o problema, PR, iteration-id

**2. Adicionar entrada na Tracking List** (`prodops/artifacts/product/backlogs/tracking-list.md`):
- Nova linha na tabela com: descrição, origem, dimensão, dono, número da issue criada, status `Aberto`, próxima ação

**3. Postar comentário na issue da iteração** que originou o problema, referenciando a nova issue de follow-up.

**Quando criar follow-up obrigatoriamente:**

| Situação | Exemplo |
|---|---|
| Critério de saída não satisfeito | Timelines ausentes, Diligence pendente |
| Problema residual após entrega | Alerta Dependabot remanescente pós-atualização |
| Débito técnico identificado durante Hack | Bug contornado sem fix, test coverage insuficiente |
| Gate parcialmente satisfeito | SLI abaixo do target após Validate |
| Anomalia observada em fase operacional | Evento duplicado no Datadog, estado inconsistente no Project |

**Quando NÃO criar follow-up:**
- Decisão explícita de aceite de risco já registrada em `risks.md`
- Item já rastreado em issue existente aberta

**Commit das atualizações:**
```bash
git add prodops/artifacts/product/backlogs/tracking-list.md
git status  # verificar que não há arquivos faltando antes de commitar
git commit -m "chore(prodops): register follow-up issues from iteration <iteration-id>"
```

## Protocolo de exceção — bloqueios

Quando uma fase não pode avançar (permissão negada, gate falhou, timeout, bloqueio externo):

1. Emitir `Delivery.Block.Declared` **antes de parar**, registrando o motivo no payload:

```json
{
  "event": "Delivery.Block.Declared",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

Isso seta `oem-state = BLOCKED` no GitHub Project e aciona automaticamente o Diligence Sync (`diligence.capture`) via dispatcher.

2. Reportar o bloqueio ao caller com: fase em que ocorreu, motivo, e ação necessária para resolução.

Quando o bloqueio é resolvido e o flow retoma:

3. Emitir `Delivery.Block.Resolved` **antes de continuar**, usando o mesmo `correlation-id`:

```json
{
  "event": "Delivery.Block.Resolved",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

Isso seta `oem-state = PENDING` e permite que o Bootstrap inicie novamente.

## Guardrails

- Não iniciar uma fase de Delivery enquanto o readiness estiver incompleto.
- Não tratar uma entrada no Iteration Plan sozinha como readiness.
- Não inventar OBCs, cenários BDD, riscos ou critérios de aceite.
- Não fazer o Bootstrap executar Git flow ou trabalho de contexto de produto.
- Não fazer ship de trabalho suportado apenas por evidência Upstream.
- Não pular quality gates sem decisão explícita registrada e aceite de risco.
- Não promover itens com risco alto não resolvido sem aceite explícito.
- Não criar GitHub Issues ou PRs sem declarar artifact_type, artifact_id, operation e journey.
- No modo sem argumentos, parar apenas em falha de readiness ou falha de gate — nunca aguardar confirmação entre itens.
- Usar o padrão canônico de título de Work Item: `[Artifact ID]: descrição`.
- Nunca parar silenciosamente — todo bloqueio deve emitir `Delivery.Block.Declared` antes de reportar ao caller.
- **Nunca spawnar sub-agentes de fase (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) em background.** Todo sub-agente deve usar `run_in_background: false`. O downstream-agent aguarda o resultado antes de invocar a fase seguinte.
- **Em restart (timeline com eventos pré-existentes), sempre emitir `Delivery.Restart.*` com o `correlation-id` anterior antes de qualquer evento de fase.** Nunca omitir o protocolo de Restart — ele é a evidência auditável de que a execução foi retomada e o marcador que separa execuções na timeline.
- **Eventos duplicados na timeline são esperados e corretos em restart.** Cada execução gera um novo `correlation-id`; os eventos de Restart com o correlation-id anterior ligam os históricos. Não tentar suprimir eventos de fase em restart.

## Referências

→ Readiness SKILL
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)
→ [Iteration Plan](../../artifacts/plans/iteration-plan.md)
