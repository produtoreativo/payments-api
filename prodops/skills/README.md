# Skills

Skills representam comportamento executável utilizado por agentes. Cada skill é autossuficiente — descreve o que fazer, quando entrar, o que ler e o que produzir.

Skills **não** são documentação conceitual, templates ou capabilities.

## Skills de Delivery (fases do CI Sync / CI Async)

| Skill | Fase | Link |
|---|---|---|
| Bootstrap | Preparar contexto, branch e ambiente antes do Hack | [bootstrap/SKILL.md](bootstrap/SKILL.md) |
| Hack | Implementação TDD: start → tdd → commit | [hack/SKILL.md](hack/SKILL.md) |
| Sync | Sincronizar branch com base ou artefatos com implementação | [sync/SKILL.md](sync/SKILL.md) |
| Finish | Avaliar done criteria e quality gates ao finalizar | [finish/SKILL.md](finish/SKILL.md) |
| Ship | Preparar PR, release, deploy e readiness final | [ship/SKILL.md](ship/SKILL.md) |
| Validate | Validar comportamento com evidências, SLOs e métricas | [validate/SKILL.md](validate/SKILL.md) |
| Promote | Aprovar e fechar estágio de release | [promote/SKILL.md](promote/SKILL.md) |

### Steps de Hack

| Step | Responsabilidade | Link |
|---|---|---|
| `hack/start` | Limpar working tree, sincronizar base, criar branch | [hack/steps/start/SKILL.md](hack/steps/start/SKILL.md) |
| `hack/tdd` | Ciclo Red → Green → Refactor contra BDD Feature | [hack/steps/tdd/SKILL.md](hack/steps/tdd/SKILL.md) |
| `hack/commit` | Revisar diff, criar commit Conventional Commits | [hack/steps/commit/SKILL.md](hack/steps/commit/SKILL.md) |

## Skills de Jornada

| Skill | Jornada | Link |
|---|---|---|
| Upstream | Discovery — exploração, experimentos, protótipos | [upstream/SKILL.md](upstream/SKILL.md) |
| Downstream | Modo Downstream — readiness e delivery governado | [downstream/SKILL.md](downstream/SKILL.md) |
| Diligence | Diligence — sincronização, drift e reconciliação de workspace | [diligence/SKILL.md](diligence/SKILL.md) |

### Steps de Upstream

| Step | Responsabilidade | Link |
|---|---|---|
| `upstream/move-to-downstream` | Promover experimento concluído para Downstream | [upstream/steps/move-to-downstream/SKILL.md](upstream/steps/move-to-downstream/SKILL.md) |
| `upstream/deploy-to-sandbox` | Deploy de branch experimental no sandbox AWS | [upstream/steps/deploy-to-sandbox/SKILL.md](upstream/steps/deploy-to-sandbox/SKILL.md) |

### Commands de Diligence

| Command | Responsabilidade | Link |
|---|---|---|
| `diligence-sync` | Capture → Attach → Promote → Close para um OBC | [diligence/diligence-sync/SKILL.md](diligence/diligence-sync/SKILL.md) |
| `diligence-async` | Scan → Flag → Repair em todos os OBCs e Issues | [diligence/diligence-async/SKILL.md](diligence/diligence-async/SKILL.md) |
| `workspace-reconciliation` | Inspect → Reconcile → Verify do GitHub Workspace | [diligence/workspace-reconciliation/SKILL.md](diligence/workspace-reconciliation/SKILL.md) |

## Skills do Produto (`skills/local/`)

Skills mantidas neste repositório. Não fazem parte do Framework canônico e não
devem ser distribuídas a outros produtos. Podem consumir o Framework; o
Framework não depende delas. Ver [`local/README.md`](local/README.md).

| Skill | Propósito | Link |
|---|---|---|
| `payments-api-local-testing` | Execução e validação de testes locais com contratos de pagamento | [local/payments-api-local-testing/SKILL.md](local/payments-api-local-testing/SKILL.md) |

## Referências de engenharia

Bases de conhecimento utilizadas pelos agentes — não são skills executáveis. Ver [`references/README.md`](references/README.md) para o índice completo.

### Referências canônicas (Framework)

| Referência | Conteúdo | Link |
|---|---|---|
| TDD ProdOps | Prática TDD no contexto do ProdOps | [references/engineering/tdd-prodops/](references/engineering/tdd-prodops/) |

### Referências locais do produto

Literatura e convenções adotadas por este produto. Framework Skills **não dependem** delas como requisito; são orientações opcionais disponíveis em [`references/local/`](references/local/).

| Referência | Conteúdo | Link |
|---|---|---|
| Clean Code | Princípios e práticas de código limpo | [references/local/engineering/clean-code/](references/local/engineering/clean-code/) |
| DDD | Domain-Driven Design aplicado ao produto | [references/local/engineering/ddd/](references/local/engineering/ddd/) |

## Estrutura de cada Skill

Cada Skill deve conter:
- **Objetivo** — o que a skill faz
- **Quando utilizar** — condição de entrada
- **Entradas** — artefatos consumidos
- **Saídas** — artefatos produzidos
- **Steps** — sequência de execução com links para arquivos de step
