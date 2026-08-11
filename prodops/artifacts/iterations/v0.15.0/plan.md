# Iteration Plan — v0.15.0

> Status: Em execução — aberta em 2026-08-07

## Objetivo

Refinar a fase Finish do Delivery Journey: decompor o passo monolítico em sub-steps auditáveis (`validate`, `review`, `request`) e instalar os gates de qualidade que faltavam — cobertura, dependências e análise estática de código. Esta iteração não entrega produto — entrega rigor e auditabilidade ao próprio fluxo de encerramento técnico, no mesmo molde de v0.8.0 e v0.11.0.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-62 | #11 | finish-substeps: decompor Finish em `validate`, `review`, `request` com fronteira explícita por step | — | n/a | n/a | n/a | Em execução | #171 |
| DS-63 | #11 | finish-quality-gates: gates `coverage`, `dependencies` e `code-analysis` como `blocks: auto_merge_only` | DS-62 | n/a | n/a | n/a | Em execução | #171 |
| DS-64 | #11 | commit-workflow-rules: subject completo em 72 caracteres, scope-case e ponto final | — | n/a | n/a | n/a | Em execução | #171 |
| DS-65 | #11 | trail-layout-consistency: consolidar session trails em `trails/sessions/`, separar trail por iteração e corrigir a causa raiz no template de capsule | — | n/a | n/a | n/a | Em execução | #171 |
| DS-66 | #11 | skill-materialization-fix: materializar a árvore completa do skill e reparar os defeitos que impediam a regeneração | — | n/a | n/a | n/a | Em execução | #171 |

> **OBC/BDD/Risco marcados `n/a`.** Trabalho de infraestrutura ProdOps não tem
> OBC de produto nem cenário BDD executável. Mesma lacuna que suspendeu a
> v0.8.0 ("gates OBC/BDD/Risks ausentes para infraestrutura ProdOps") —
> registrada em `prodops/framework/framework-gaps.md`, não resolvida aqui.

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.15.0 |
|---|---|---|
| DS-62 | finish-substeps | #11 |
| DS-63 | finish-quality-gates | #11 |
| DS-64 | commit-workflow-rules | #11 |
| DS-65 | trail-layout-consistency | #11 |
| DS-66 | skill-materialization-fix | #11 |

> Os três DS compartilham a issue #11: o refino foi especificado como uma única
> issue guarda-chuva antes de existir a decomposição em DS. Diferente de
> v0.11.0, onde cada DS tinha issue própria.

## Sequência de entrega

DS-62 → DS-63 (os gates dependem da fronteira dos steps) · DS-64 independente.

DS-65 e DS-66 entraram durante a execução, a partir do review da PR: o pedido de
consolidar os trails órfãos expôs a causa raiz no template de capsule (DS-65), e
a decomposição do Finish em multi-arquivo expôs que a materialização só copiava
o `SKILL.md` de topo (DS-66). Ambos são consequência do escopo original, não
trabalho novo.

## Critérios de saída

- [x] Finish decomposto em `validate`, `review`, `request` — cada um com seção "não faz"
- [x] Artefatos da fase criados: `README`, `done-criteria`, `quality-gates`
- [x] Gate `coverage` — `scripts/check-coverage-threshold.sh`, branches ≥ 100%
- [x] Gate `dependencies` — `scripts/check-dependencies.sh`, Snyk severidade ≥ high
- [x] Gate `code-analysis` — `scripts/check-code-analysis.sh`, SonarQube local
- [x] `commit-msg.sh` medindo o subject inteiro, com scope-case e ponto final
- [x] Os três gates executados de ponta a ponta ao menos uma vez
- [x] Session trails consolidados em `trails/sessions/` e índice reconstruído
- [x] Trail por iteração separado do Release Trail (`iteration-trail*.md`)
- [x] `session-trail-dir` corrigido no template de capsule (causa raiz)
- [x] `materialize-skills.sh` materializando a árvore completa do skill
- [x] Push publica a branch de trabalho, nunca a branch de destino do PR
- [x] Gates de auto-merge rodam no `validate`; `request` apenas lê os vereditos
- [x] `validate` inspeciona sem mutar (`prettier --check`, `eslint` sem `--fix`)
- [x] Suíte de regressão do `commit-msg` verificada por mutação
- [x] CI barra skill materializado divergente da fonte
- [x] PR aberto para a issue #11 — #171 (`refine/11-finish-v2` → `master`)
- [ ] Issue #11 fechada no GitHub
- [ ] `prodops.delivery.promote.completed` emitido para a issue #11

### Bloqueadores conhecidos

Ambos exigem `admin` no repositório — herdados do trail `4a9e4c58`:

1. **Sem `required_status_checks` na `master`** (confirmado 404 em 2026-08-10).
   O step `review` trata branch protection ausente como bloqueador, o que impede
   **armar o auto-merge** — não impede abrir o PR (#171 está aberto) nem o merge
   manual por um humano.
2. **`SNYK_TOKEN` não cadastrado.** O gate `dependencies` sai com exit 2 em
   qualquer ambiente enquanto o secret não existir.
3. **Cobertura em 62,78% contra limiar de 100%** — `gates.coverage` sai 1 em todo
   `validate`. Dívida pré-existente do repositório, não regressão desta iteração.
   Enquanto existir, o auto-merge não arma: o caminho é merge manual.

### Dívida registrada, não resolvida aqui

Descoberta durante DS-65 e DS-66; documentada em
`prodops/framework/framework-gaps.md`:

- **20 capsules em 8 iterações** ainda declaram o `session-trail-dir` antigo
  (GAP-019). Capsule é artefato gerado — a correção é regenerar via
  `/downstream`, não editar à mão.
- **153 links apontando para fora do diretório do skill** seguem quebrados no
  destino materializado (GAP-022). Anterior a esta branch; depende de definir a
  fronteira do skill materializado.
- **Gates acoplam ferramenta, credencial e endpoint ao produto** (GAP-020).
  Mantido no produto: um consumidor real só.

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.15.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `prodops/artifacts/trails/sessions/` — trails `4a9e4c58` e
  `c29a5b1a` (sessão ativa)
  (modelo vigente é por sessão, não por iteração; ver `trails/release-trail.md`)
