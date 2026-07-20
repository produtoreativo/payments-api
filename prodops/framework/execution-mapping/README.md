# Execution Mapping

O **Execution Mapping** é a capability do Framework ProdOps que define, de forma declarativa, como cada tipo de Artefato do Knowledge Space se relaciona com os recursos de execução do GitHub.

Ele não executa sincronizações. Ele não cria Issues. Ele define o **contrato**.

→ [Knowledge vs Execution](../knowledge-vs-execution.md) — princípio fundacional
→ [Matriz de Mapeamento](matrix.md) — todos os artefatos × operações × recursos
→ [Schema de Work Item](work-item-schema.md) — campos canônicos do GitHub Project

---

## Por que este modelo existe

Antes do Execution Mapping, o Framework tinha uma convenção implícita: cada artefato possuía "uma Issue correspondente." Isso criava problemas estruturais:

**Problema 1 — Confusão de identidade**
Perguntar "qual é a Issue do OBC?" é uma pergunta errada. Um OBC pode ter zero Issues (em períodos sem trabalho ativo), uma Issue (refinamento em curso), ou dezenas de Issues (ao longo de sua vida operacional). Não existe "a Issue do OBC".

**Problema 2 — Estado duplicado**
Quando o estado de um artefato é sincronizado com o estado de uma Issue, surgem dois registros do mesmo dado. Qual prevalece? Quem atualiza quem? Isso gera drift e inconsistência.

**Problema 3 — Impossibilidade de múltiplos repositórios**
Se um Business Intent afeta três produtos, e cada produto abre "a Issue do Intent", existem três Issues para o mesmo artefato — sem vínculo declarado entre elas.

**Problema 4 — Operações implícitas**
Sem um modelo explícito, cada membro do time inventa qual tipo de Issue criar, qual label usar, qual campo preencher. O Framework não diz o que é esperado.

**Problema 5 — GitHub como fonte de verdade**
Quando a estrutura de Issues espelha a estrutura de artefatos, o time começa a ler Issues para entender o estado do produto — em vez de ler os artefatos. O GitHub vira a fonte de verdade por acidente.

---

## O que o Execution Mapping resolve

| Problema | Solução |
|---|---|
| "Qual é a Issue do OBC?" | Não existe. Existem Work Items sobre o OBC. Um por operação, quando há trabalho. |
| Estado duplicado | O artefato tem seu próprio estado (no Markdown). O Work Item tem seu próprio estado (no GitHub). São independentes. |
| Múltiplos repositórios | Cada Work Item declara `artifact_id` explicitamente. Vários Work Items podem referenciar o mesmo artefato em repos diferentes. |
| Operações implícitas | O Execution Mapping declara quais operações são permitidas para cada artefato e quais recursos GitHub cada operação pode gerar. |
| GitHub como fonte de verdade | O Work Item referencia o artefato — não é o artefato. O Markdown sempre prevalece. |

---

## Modelo conceitual

### Artifact (Knowledge Space)

Cada Artefato possui:
- **identidade permanente** — `slug` ou ID que não muda
- **estado próprio** — ciclo de vida definido no documento do artefato
- **localização canônica** — path no repositório git
- **operações permitidas** — declaradas no Execution Mapping

### Operation (ponte)

Uma operação é uma ação realizada **sobre** um artefato. Ela:
- tem início, meio e fim
- pode gerar um ou mais Work Items no GitHub
- pode modificar o artefato (via PR)
- pode gerar evidências que complementam o artefato
- **não é o artefato** — quando termina, deixa de existir como Work Item ativo

### Work Item (Execution Space)

Um Work Item é um recurso do GitHub (Issue, PR, Discussion, Release) que:
- referencia explicitamente um ou mais artefatos
- representa uma operação em andamento
- tem seu próprio ciclo de vida no GitHub (Open → Done)
- fecha quando a operação termina
- não substitui o artefato

### Cardinalidade

```
                 Artefato
                    │
         ┌──────────┼──────────┐
         │          │          │
      Work Item  Work Item  Work Item
      (Sprint 1) (Sprint 4) (Sprint 9)
```

Um artefato pode ter **zero** Work Items ativos (nenhum trabalho em curso) ou **muitos** Work Items ao longo de sua vida. Cada Work Item é independente.

```
         Work Item
              │
    ┌─────────┼──────────┐
    │         │          │
 Artefato  Artefato   Artefato
    A         B          C
```

Um Work Item pode afetar **múltiplos artefatos** simultaneamente. Exemplo: uma PR que atualiza OBC, BDD e Architecture ao mesmo tempo.

---

## Catálogo de operações

As operações são ações semânticas realizadas sobre artefatos. Elas se agrupam em famílias:

### Família: Criação
| Operação | Descrição |
|---|---|
| `Create` | Primeira instância do artefato é criada |
| `Capture` | Sinal ou observação é registrada (Business Signal) |
| `Define` | Artefato exploratório é definido (Experiment) |

### Família: Refinamento
| Operação | Descrição |
|---|---|
| `Refine` | Conteúdo do artefato evolui; critérios emergem |
| `Update` | Conteúdo atualizado com nova informação (evidência, decisão) |
| `Prototype` | Modelo parcial criado para validar hipótese |

### Família: Revisão e Aprovação
| Operação | Descrição |
|---|---|
| `Review` | Artefato é avaliado por um ou mais responsáveis |
| `Approve` | Artefato recebe aprovação formal (muda estado) |
| `Validate` | Artefato é verificado contra critérios objetivos (ex: CI) |

### Família: Estrutura
| Operação | Descrição |
|---|---|
| `Split` | Artefato origina N especializações (Global OBC → Local OBCs) |
| `Merge` | Dois artefatos são consolidados em um |
| `Promote` | Artefato avança de nível (Signal gera Intent, Upstream → Downstream) |

### Família: Execução
| Operação | Descrição |
|---|---|
| `Implement` | Código é desenvolvido contra o artefato |
| `Experiment` | Experimento formal é executado com base no artefato |
| `Release` | Artefato contribui para uma Release |

### Família: Encerramento
| Operação | Descrição |
|---|---|
| `Archive` | Artefato encerrado; histórico preservado |
| `Deprecate` | Artefato marcado obsoleto; ainda acessível |
| `Discard` | Artefato descartado com justificativa |
| `Cancel` | Trabalho sobre o artefato é cancelado |

---

## Recursos GitHub por tipo

| Recurso GitHub | Quando usar |
|---|---|
| **Issue** | Rastrear trabalho de exploração, refinamento, revisão — trabalho que não resulta em commit |
| **Pull Request** | Rastrear trabalho que resulta em modificação de arquivo no repositório |
| **Discussion** | Rastrear decisões abertas, arquiteturais ou de negócio — sem artefato definido ainda |
| **Release** | Marcar ponto de entrega de um conjunto de artefatos para produção |
| **Workflow** (Actions) | Operações automatizadas: validação de BDD, lint, build |
| **Milestone** | Agrupar Work Items relacionados a um entregável ou horizonte de tempo |
| **Project Item** | Representar um Work Item dentro de um GitHub Project para gestão visual |

---

## Múltiplos repositórios

O Execution Mapping suporta nativamente cenários multi-repositório:

```
Business Intent BI-042 (Global OBC no repositório de portfólio)
  │
  ├─ Local OBC em payments-api      ← Work Items em payments-api
  ├─ Local OBC em webshop-api       ← Work Items em webshop-api
  └─ Local OBC em order-api         ← Work Items em order-api
```

Cada repositório rastreia seu próprio trabalho via Work Items. O vínculo entre os repositórios é estabelecido pelo `artifact_id` (que referencia o mesmo Global OBC) — não por um espelhamento de Issues.

---

## Única fonte de verdade

```
Markdown > GitHub > Ferramentas externas

prodops/artifacts/business/obcs/payments-invoice-v2.md
  = fonte de verdade do CONTEÚDO e ESTADO do OBC

GitHub Issue #234 "Refinar OBC — seção BDD incompleta"
  = fonte de verdade do TRABALHO em andamento sobre o OBC

Jira / ADO / Linear
  = espelhos de conveniência do GitHub (opcionais)
```

Se há divergência entre o Markdown e o GitHub, o **Markdown prevalece**. O Work Item é criado para executar trabalho que trará o GitHub para o mesmo estado que o Markdown descreve.

---

## Referências

→ [Knowledge vs Execution](../knowledge-vs-execution.md)
→ [Matriz de Mapeamento](matrix.md)
→ [Schema de Work Item](work-item-schema.md)
→ [Modelo Operacional](../operating-model.md)
→ [Glossário](../glossary.md)
