# Payments API — Guia do Agente

Este arquivo é um roteador mínimo. O contexto de execução vive nos skills, no
manifest e nos artefatos do card — **não pré-leia a documentação do framework**.

## Permissões pré-autorizadas para subagentes

Todas as operações abaixo estão pré-autorizadas pelo operador para esta sessão.
Subagentes **não devem pausar para solicitar confirmação** dessas operações:

- **Read** — qualquer arquivo do repositório, incluindo:
  - `prodops/artifacts/bdd/*.feature`
  - `prodops/artifacts/obcs/*.md`
  - `prodops/artifacts/iterations/*/cards/*/context.md`
  - `prodops/runtime/**`
  - `prodops/skills/**`
  - `prodops/framework/**`
- **Bash** — comandos de leitura, git local, gh CLI e scripts do runtime, conforme
  prescrito pelas Skills. A seção "Autorização por Skill" deste arquivo cobre todas as
  ações instrumentadas pelo fluxo Downstream, Diligence e Workspace Reconciliation.

---

## Protocolo de recebimento de trabalho

**Antes de qualquer ação**, classificar o pedido e propor a jornada adequada.
Nunca iniciar implementação, refatoração, correção ou criação de artefatos sem
passar por este protocolo — independentemente de quem solicita ou como.

### Passo 0 — Classificar o trabalho

| Tipo de pedido | Jornada | Skill de entrada |
|---|---|---|
| Nova feature, endpoint, comportamento de negócio | **Delivery** | `/downstream` |
| Correção de bug com impacto em contrato ou comportamento | **Delivery** | `/downstream` |
| Atualização de dependência com impacto em runtime | **Delivery** | `/downstream` |
| Correção de vulnerabilidade de segurança | **Delivery** | `/downstream` |
| Investigação, descoberta, análise técnica | **Upstream** | `/upstream` |
| Auditoria, risco, conformidade, sinal de negócio | **Diligence** | `/diligence` |
| Pergunta, explicação, leitura de código | nenhuma jornada | responder diretamente |

### Passo 1 — Verificar artefatos de produto

Para pedidos do tipo **Delivery**, antes de propor execução, verificar:

1. Existe OBC em `prodops/artifacts/obcs/<capability>.md`?
2. Existe BDD Feature em `prodops/artifacts/bdd/<capability>.feature`?
3. Risco documentado em `prodops/artifacts/risks/risks.md`?
4. Item no Iteration Plan com status `Entrou`?

### Passo 2 — Propor, não executar

Apresentar ao operador:

```
Jornada identificada: <Delivery | Upstream | Diligence>
Skill de entrada: <skill>
Artefatos presentes: <lista>
Artefatos ausentes: <lista — bloqueia readiness>
Próxima ação proposta: <descrição>
```

Aguardar confirmação **exceto** quando o pedido já invocou explicitamente um
skill (`/downstream`, `/upstream`, `/hack`, etc.) — nesse caso executar
diretamente sem parar para propor.

### Passo 3 — Executar via skill

Após confirmação, executar exclusivamente via skill correspondente.
Nunca implementar código de produção fora do ciclo Bootstrap → Hack → Sync → Finish.

---

## Como trabalhar

1. **Trabalho de Delivery:** invoque o skill da fase — `/bootstrap`, `/hack`,
   `/sync`, `/finish`, `/ship`, `/validate`, `/promote`. Cada skill é
   autossuficiente e diz o que ler.
2. **Exploração:** `/upstream`. **Implementação governada:** `/downstream`.
3. **Paths canônicos, quality gates e vocabulário:** `prodops/exec/manifest.yaml`
   — fonte única, legível por máquina. Consistência: `./prodops/scripts/validate-manifest.sh`.
4. **Contexto da tarefa:** a context capsule do card —
   `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`, gerada pelo gate
   de readiness do `/downstream`. O `iteration-id` e o `slug` vêm do Iteration Plan ativo
   (`prodops/artifacts/plans/iteration-plan.md` → `prodops/artifacts/iterations/<version>/plan.md`).
   Leia-a antes de alterar código de produção — e somente ela.
   Se não existir, execute o readiness do `/downstream` antes do `/bootstrap`.

## Autorização por Skill

As Skills do ProdOps são a fonte de autorização para ações neste repositório.
Quando uma Skill instrui o agente a executar uma ação — merge de PR, push de
branch, criação de issue, atualização de campo no GitHub Project, emissão de
evento — essa instrução constitui autorização explícita do operador. O agente
não deve interromper o fluxo para pedir confirmação adicional: a aprovação está
embutida na Skill.

**Regra operacional:** respeite as Skills, execute o que elas prescrevem, não
adicione gates de confirmação que a Skill não prevê.

Isso se aplica a todos os agentes que operam neste repositório.

---

## Regras invioláveis

- Nunca inventar OBCs, SLOs, riscos ou critérios de aceite ausentes. Contexto
  faltando → parar e reportar, não improvisar.
- Downstream exige: OBC committed + BDD Feature committed + entrada no
  Iteration Plan com status `Entrou` + riscos documentados.
- Reliability Plan é **opcional** — nunca bloqueia readiness. Incluir quando houver
  movimentação financeira, integração externa, mudança de SLO ou risco alto/crítico.
- Conflito entre diretriz nova e regra existente: preservar a regra existente e
  registrar em Decision Trail (`prodops/templates/assessment/decision-trail.md`).
- Commits seguem Conventional Commits (tipos e limite de summary: no manifest).
- Toda entrega Downstream relevante gera append no release trail
  (`prodops/artifacts/trails/release-trail.md`).
- **NUNCA executar** `scripts/sync-framework-docs.sh` — o script está desativado
  e causaria exportação incorreta. Ver `prodops/exec/empirical-upstream.md`.

## Arquitetura

Diagrama canônico: `prodops/artifacts/architecture/overview.md`

**Atualizar antes de fechar o task quando houver:** novo módulo NestJS, nova
rota ou grupo de rotas, nova dependência externa, novo DynamoDB table ou índice,
novo tópico de evento ou fila SQS, mudança de autenticação em rota.

**Não** exige atualização: novos campos em DTOs, bugfixes internos, novos
cenários BDD sem nova infra, refatorações sem mudança de contrato.

Adicionar linha na tabela "Histórico de mudanças estruturais" do `overview.md`.

## Execution Mapping

Ao criar qualquer Work Item (GitHub Issue, PR, Discussion):
1. Consultar `prodops/framework/execution-mapping/matrix.md` — verificar se a operação é permitida para o artefato.
2. Preencher campos obrigatórios: `artifact_type`, `artifact_id`, `operation`, `journey`.
3. Usar o padrão de título: `[Artifact ID]: descrição concisa`. A operação e o tipo de artefato vão em campos e labels do Issue — não no título.
4. Nunca criar Work Item sem referência de artefato.

Referência: `prodops/framework/execution-mapping/work-item-schema.md`

## Mapa de áreas do repositório

| Área | Tipo | Descrição |
|---|---|---|
| `prodops/framework/` | **Canônico do Framework** | Princípios, glossário, ontologia, jornadas, canonical-paths |
| `prodops/skills/bootstrap`, `hack`, `sync`, `finish`, `ship`, `validate`, `promote`, `upstream`, `downstream`, `diligence` | **Canônico do Framework** | Skills executáveis do Framework |
| `prodops/skills/references/engineering/` | **Canônico do Framework** | Prática TDD ProdOps |
| `prodops/templates/` | **Canônico do Framework** | Templates canônicos |
| `prodops/scripts/doctor.sh`, `validate-manifest.sh`, `validate-export-manifest.sh` | **Canônico do Framework** | Scripts de validação canônicos |
| `prodops/artifacts/` | **Local do produto** | OBCs, BDD, planos, trilhas, evidências, runbooks de produto |
| `prodops/skills/local/` | **Local do produto** | Skills específicas desta API (ex: `payments-api-local-testing`) |
| `prodops/skills/references/local/` | **Local do produto** | Literatura e convenções locais |
| `prodops/scripts/local/` | **Local do produto** | Automações locais |
| `prodops/exec/` | **Local do produto** | Manifest, lock, cards, contratos de exportação |

## Upstream empírico — estado atual

Este repositório tem `status: self` em `prodops/exec/framework-lock.yaml`.
Isso significa que é simultaneamente produto consumidor e fonte temporária do Framework.

- Conteúdo canônico generalizável: `prodops/framework/`
- Histórico empírico do produto: `prodops/artifacts/` e seção `# History` do upstream-trail
- Documento de orientação: `prodops/exec/empirical-upstream.md`

## Doutrina do framework (humanos; agentes somente sob demanda explícita)

Princípios, glossário, fluxo oficial, Origin Streams e modelo operacional:
`prodops/README.md` → `prodops/framework/`.
