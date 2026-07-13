# Quality Gates do Ciclo Hack

Checklist canônico de saída de um ciclo **Red → Green → Yellow**. Um ciclo não fecha — e não se avança para o próximo step ou para o `commit` — enquanto todos os gates abaixo não estiverem satisfeitos.

Este arquivo é a fonte canônica dos gates **por ciclo** do Hack. Os gates de saída de release (o que bloqueia merge) vivem em [`../finish/quality-gates.md`](../finish/quality-gates.md); a referência de engenharia em [`tdd-prodops/quality-gates.md`](../../../../skills/references/engineering/tdd-prodops/quality-gates.md) aponta para cá em vez de duplicar.

---

## Steps sequenciais vs. validações transversais

O Hack tem **três steps sequenciais e independentemente invocáveis** (`prodops/skills/hack/steps/`):

```
start → tdd → commit
```

As validações de **Segurança, Qualidade e Documentação não são steps**. Elas são **transversais**: rodam durante e ao final do **Yellow Bar** de cada ciclo, não como etapas sequenciais extras.

| Validação transversal | O que checar (no Yellow Bar) |
|---|---|
| **Segurança** | Sem secrets no diff; sem dependências vulneráveis; sem configs inseguras; sem PII em logs |
| **Qualidade** | Lint limpo; cobertura mínima; sem mock proibido (`jest.fn()`, `.overrideProvider()`); sem `.only` |
| **Documentação** | Event Storming se novo evento; arquitetura se nova estrutura; Release Trail com evidência do ciclo |

---

## Gates de saída do ciclo (critério mínimo para commitar)

Um ciclo Red → Green → Yellow está completo somente quando:

- [ ] **Green** — teste focado passando
- [ ] **Lint** — `npm run lint` sai com código 0 no pacote afetado
- [ ] **Sem mock proibido** no diff (`jest.fn()`, `.overrideProvider()`)
- [ ] **Sem secrets ou PII** no diff
- [ ] **Release Trail** atualizado com a evidência do ciclo
- [ ] **Artefatos ProdOps impactados** atualizados (Event Storming, arquitetura)

Estes gates são o mínimo para commitar e seguir para o próximo step.

---

## Referências de engenharia por step

| Step | Referências |
|---|---|
| `start` | n/a |
| `tdd` (Red) | [DDD](../../../../skills/references/engineering/ddd/README.md) (linguagem ubíqua, eventos de domínio) · [ProdOps TDD](../../../../skills/references/engineering/tdd-prodops/README.md) (integration-first, mocking policy) |
| `tdd` (Green) | [Clean Code](../../../../skills/references/engineering/clean-code/README.md) (nomes, funções) |
| `tdd` (Yellow) | [Clean Code — refactoring](../../../../skills/references/engineering/clean-code/refactoring.md) · [DDD](../../../../skills/references/engineering/ddd/README.md) (agregados, repositórios) · [observabilidade](../../../../skills/references/engineering/tdd-prodops/observability.md) |
| `commit` | [Conventional Commits](../../capabilities/commit-workflow/README.md#conventional-commits) · escopo de commit |

---

## Relação com Finish e Ship

**Finish** consome os gates de release em [`../finish/quality-gates.md`](../finish/quality-gates.md) como critério de saída do CI Sync. Os gates deste arquivo operam **por ciclo**, dentro do Hack; os gates do Finish operam **por release**, antes do PR. Um ciclo Hack fechado com estes gates é pré-condição para o Finish, não o substitui.
