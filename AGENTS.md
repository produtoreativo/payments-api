# Payments API — Guia do Agente

Este arquivo é um roteador mínimo. O contexto de execução vive nos skills, no
manifest e nos artefatos do card — **não pré-leia a documentação do framework**.

## Como trabalhar

1. **Trabalho de Delivery:** invoque o skill da fase — `/bootstrap`, `/hack`,
   `/sync`, `/finish`, `/ship`, `/validate`, `/promote`. Cada skill é
   autossuficiente e diz o que ler.
2. **Exploração:** `/upstream`. **Implementação governada:** `/downstream`.
3. **Paths canônicos, quality gates e vocabulário:** `prodops/exec/manifest.yaml`
   — fonte única, legível por máquina. Consistência: `./prodops/scripts/validate-manifest.sh`.
4. **Contexto da tarefa:** a context capsule do card —
   `prodops/exec/cards/<card>/context.md`, gerada pelo gate de readiness do
   `/downstream`. Leia-a antes de alterar código de produção — e somente ela.
   Se não existir, execute o readiness do `/downstream` antes do `/bootstrap`.

## Regras invioláveis

- Nunca inventar OBCs, SLOs, riscos ou critérios de aceite ausentes. Contexto
  faltando → parar e reportar, não improvisar.
- Downstream exige: OBC committed + BDD Feature committed + entrada no
  Iteration Plan com status `Entrou` + riscos documentados.
- Reliability Plan é gate quando houver movimentação financeira, integração
  externa, mudança de SLO, risco alto/crítico ou alteração de persistência
  ou segurança.
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
3. Usar o padrão de título: `[Operation] — [Artifact Type] [Artifact ID]: descrição`.
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
