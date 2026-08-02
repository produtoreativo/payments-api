---
name: downstream
description: Orquestra a execução do fluxo de entrega governado do ProdOps. Sem argumentos, lê o Iteration Plan e executa os itens com status Entrou em ordem de prioridade. Com Downstream ID, executa apenas aquele item.
---

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

5. **Project Cleanup** — remover todos os items do GitHub Project antes de adicionar os da nova iteração. **Este passo é independente do Plan Bootstrap e sempre executa**, mesmo que `plan-bootstrap.json` já exista.

   a. Verificar se `ITERATION_DIR/runtime/plan-bootstrap.json` tem o campo `"project-cleanup": "completed"`. Se tiver, pular este passo.
   b. Se não tiver (campo ausente ou arquivo inexistente), remover todos os items atualmente no Project (`$PROJECT_NUMBER`):
      ```bash
      gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
        | jq -r '.items[].id' \
        | while read ITEM_ID; do
            gh project item-delete "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --id "$ITEM_ID"
          done
      ```
   c. Após executar (com ou sem itens removidos), adicionar `"project-cleanup": "completed"` em `ITERATION_DIR/runtime/plan-bootstrap.json` (criar o arquivo com apenas esse campo se ele não existir ainda). Commitar.
   d. Não bloquear se o projeto estiver vazio — registrar `"project-cleanup": "completed"` mesmo assim.

6. **Plan Bootstrap** — executar uma única vez antes do loop de issues:
   a. Verificar se `ITERATION_DIR/runtime/plan-bootstrap.json` já existe com `"status": "completed"`. Se sim, pular para o passo 7 (ambiente já pronto — cleanup já foi tratado no passo 5).
   b. **Issue de acompanhamento do Iteration Plan** — verificar se já existe uma issue com título `[Iteration <iteration-id>]:` no GitHub:
      ```bash
      gh issue list --search "[Iteration <iteration-id>]" --state all --json number,title | jq '.[0].number // empty'
      ```
      - Se **não existir**: criar a issue de acompanhamento:
        ```bash
        gh issue create \
          --title "[Iteration <iteration-id>]: <scope-summary>" \
          --label "prodops,artifact-type:iteration-plan" \
          --body "Iteration Plan: prodops/artifacts/iterations/<iteration-id>/plan.md\n\nCapabilities: <DS-IDs>\nIssues: <issue-numbers>"
        ```
      - Se já existir: anotar o número e continuar.
      - Registrar o número da issue no `plan-bootstrap.json` como `"plan-issue": <number>`.
   c. Emitir `Delivery.Plan.Bootstrap.Started` com `subject: <iteration-id>`, `work-item-id: null` e `--iteration-id <iteration-id>`. Após emitir, verificar o JSON de saída do emit-event: se `"datadog-sync": "error"` ou `"github-sync": "error"`, exibir aviso visível ao usuário — não continuar silenciosamente.
   d. Executar o Bootstrap work: instalar dependências, verificar runtimes e serviços locais, confirmar variáveis de ambiente, executar o smoke gate do manifest.
   e. Se qualquer etapa falhar: reportar o bloqueio e **parar toda a fila** — não iniciar nenhum issue.
   f. Emitir `Delivery.Plan.Bootstrap.Completed` com `subject: <iteration-id>` e `--iteration-id <iteration-id>`. Verificar `"datadog-sync"` e `"github-sync"` na saída — exibir aviso se erro.
   g. Escrever `ITERATION_DIR/runtime/plan-bootstrap.json`:
   ```json
   {
     "iteration-id": "<iteration-id>",
     "status": "completed",
     "project-cleanup": "completed",
     "correlation-id": "<uuid-gerado-no-started>",
     "completed-at": "<timestamp-iso8601>",
     "plan-issue": <número-da-issue-de-acompanhamento>,
     "issues": ["<issue-1>", "<issue-2>", "..."]
   }
   ```
   h. Commitar o arquivo no repositório antes de iniciar o loop.

7. Para cada item na fila, em ordem, sem pedir confirmação entre eles:
   a. Executar `/readiness <capability>` — se falhar: gravar `readiness-gate.json` com `"result": "blocked"` (ver seção **Readiness Cache**) e **parar toda a fila**.
   b. Executar CI Sync: Bootstrap → Hack → Sync → Finish. Após **cada fase concluída**:

      **7b-i — Verificar saída de cada emit-event:** o emit-event retorna JSON com campos `"datadog-sync"` e `"github-sync"`. Após **cada chamada** de emit-event (em qualquer fase), capturar o JSON e verificar:
      ```bash
      RESULT=$(bash prodops/runtime/tools/emit-event/scripts/emit-event --input <event.json>)
      echo "$RESULT" | jq -r '"datadog-sync: \(."datadog-sync") | github-sync: \(."github-sync")"'
      ```
      Se `"datadog-sync": "error"` → exibir: `⚠️ Datadog sync falhou — evento registrado na timeline local mas não enviado ao Datadog`.
      Se `"github-sync": "error"` → exibir: `⚠️ GitHub sync falhou — oem-state NÃO foi atualizado no Project`. Neste caso **não avançar** para a próxima fase sem resolver, pois o estado do Project ficará inconsistente.

      **7b-ii — Postar comentário obrigatório na issue:**
      ```bash
      gh issue comment <work-item-id> --body "## <Fase> — <YYYY-MM-DD HH:MM UTC>

      **Status:** <Concluído | Bloqueado | Falhou>

      <resumo em até 5 linhas: o que foi feito, evidências principais, próximo passo>

      ---
      *correlation-id: <uuid> · iteration: <iteration-id> · actor: <player>*"
      ```
      **Este passo é obrigatório e não pode ser omitido.** Postar mesmo em caso de falha ou bloqueio — o comentário deve descrever o motivo e a ação necessária.
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

1. Criar Issue via `gh issue create`:
   - **Título:** `[DS-<n>]: <capability-description>`
   - **Body:** incluir DS-ID, iteration-id, OBC path, BDD path e link para o plan.md
   - **Labels:** `journey:delivery`, `artifact-type:local-obc`, `operation:implement`
2. Associar ao Project (`$PROJECT_NUMBER`):
   ```bash
   gh issue edit <number> --add-project "ProdOps Runtime"
   ```
3. Atualizar a coluna `Issue` do `plan.md` com o número criado.
4. Commitar `plan.md` antes de continuar.

Nunca iniciar Bootstrap sem Issue mapeada — o `work-item-id` da capsule e dos eventos depende desse número.

Quando todos os pré-requisitos existirem:

1. Emitir `Delivery.Plan.Entered` para a issue, gerando o `correlation-id` do flow inteiro:

```json
{
  "event": "Delivery.Plan.Entered",
  "work-item-id": "<issue-number>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<new-uuid>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

2. Gerar `ITERATION_DIR/cards/<card-slug>/context.md` a partir de `prodops/templates/delivery/context-capsule.md`. Preencher **todos** os campos do template, incluindo:

**Runtime Context** — preenchido com dados da iteração ativa:
- `ds-id` — identificador estável da feature (ex: `DS-39`)
- `work-item-id` — número da issue da iteração corrente (resolvido via tabela DS-ID → Issue do `plan.md`)
- `iteration-id` — versão da iteração (ex: `v0.6.0`)
- `iteration-dir` — `prodops/artifacts/iterations/<version>/`
- `correlation-id` — UUID gerado no `Delivery.Plan.Entered` acima
- `actor-player` — player corrente (`claude`, `codex` ou `copilot`)

**Runtime Paths** — pré-computados para eliminar derivação em cada fase:
- `feature-branch` — `feat/<work-item-id>-<slug>`
- `base-branch` — branch base do merge (normalmente `master`)
- `timeline-path` — `ITERATION_DIR/runtime/timelines/<work-item-id>.json`
- `plan-bootstrap-path` — `ITERATION_DIR/runtime/plan-bootstrap.json`
- `plan-validate-path` — `ITERATION_DIR/runtime/plan-validate.json`
- `session-trail-dir` — `ITERATION_DIR/trails/`
- `obc-path`, `bdd-path` — paths absolutos dos artefatos de produto
- `reliability-path` — path do Reliability Plan se existir, caso contrário `"none"`

**Flow State** — deixar em branco; preenchido por Finish (`pr-number`) e Ship (`infra-scope`):
- `pr-number: (preenchido pelo Finish)`
- `infra-scope: (preenchido pelo Ship)`
- `oem-state: PENDING`

**BDD Scenarios** — incluir os steps completos (Given/When/Then), não apenas one-liners, para que o Hack/tdd possa executar o Red phase sem abrir o arquivo `.feature`.

O capsule é o único artefato que o agente precisa carregar para executar o flow inteiro sem reler arquivos de infraestrutura. O `correlation-id` gerado aqui é propagado para Bootstrap, Hack, Sync, Finish, Ship, Validate e Promote.

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

### Ações de fechamento (em ordem)

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

3. **Commitar:**
   ```
   chore(prodops): close iteration <iteration-id> — all <N> items promoted
   ```

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
```
chore(prodops): register follow-up issues from iteration <iteration-id>
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

## Referências

→ [Readiness SKILL.md](../readiness/SKILL.md)
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)
→ [Iteration Plan](../../artifacts/plans/iteration-plan.md)
