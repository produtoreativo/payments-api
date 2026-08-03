# ProdOps — Guia de Posicionamento e Comunicação

Este documento define como descrever o Framework ProdOps de forma precisa e consistente.
É a referência canônica para agentes ao explicar o framework a stakeholders, novos membros
ou qualquer audiência que precise entender o que é ProdOps e por que ele existe.

---

## O diferencial central — e o erro mais comum

O erro mais frequente ao explicar ProdOps é associar:

- **Upstream → Discovery**
- **Downstream → Delivery**

**Isso está errado.** Upstream e Downstream são **modos de execução**, não fases do produto.
As três jornadas clássicas — **Discovery, Delivery e Operation** — existem nos dois modos.

| | Upstream | Downstream |
|---|---|---|
| **Discovery** | ✓ Exploração livre, sem gate | ✓ Discovery com gates e rastreabilidade |
| **Delivery** | ✓ Código descartável, sem compromisso | ✓ Delivery governado, com evidência |
| **Operation** | ✓ Observações sem SLO formal | ✓ SLOs, OBCs, postmortems |
| **Compromisso** | Nenhum | Completo |
| **Quem controla a transição** | O time, quando quiser | — |

O modo define o **nível de compromisso**, não a fase do produto.
Um item pode estar em Discovery no Downstream (refinando OBC no Icebox com gates formais),
ou em Delivery no Upstream (implementando um protótipo sem compromisso de release).

---

## Explicação resumida — modelo aprovado

Use esta estrutura quando precisar explicar ProdOps de forma concisa:

### Problema que ele resolve

Sem um framework, cada sprint decide de formas diferentes: o que entra, quando entra,
quem aprova, quais evidências existem. Nada é rastreável de ponta a ponta.

### Como funciona

O framework opera em dois **modos de execução**:

**Upstream** — modo de exploração. Sem compromisso de entrega. O time experimenta livremente,
valida hipóteses, descobre o que não sabe. Pode parar, pivotar ou descartar sem custo.
Isso inclui escrever código, prototipar integrações e, quando o ambiente local não é suficiente,
fazer deploy em um ambiente de sandbox real na nuvem — tudo sem gates, sem Release Trail,
sem OBC committed. O objetivo é aprender, não entregar.

**Downstream** — modo de compromisso. Gates obrigatórios, fases sequenciais, evidência em cada
passo. O time só entra aqui quando tem clareza suficiente para assumir a entrega.

Ambos os modos percorrem as mesmas três jornadas de produto — Discovery, Delivery e Operation.
O modo não determina a fase; determina o nível de rigor e compromisso.

### O artefato central

O **OBC** — *Observable Business Contract* — é o documento vivo que conecta intenção de negócio,
critérios de aceite, observabilidade e confiabilidade. Evolui desde o experimento Upstream
até a operação em produção. Nada entra em Downstream sem OBC committed.

### Frase de encerramento

> ProdOps dá ao time a liberdade de explorar sem amarras — até em ambiente real na nuvem —
> e a disciplina de entregar com evidência quando o compromisso é assumido.
> O time decide quando mudar de um modo para o outro.

---

## Upstream chega em ambiente deployado

Este ponto é frequentemente omitido e gera a percepção equivocada de que Upstream é apenas
"código local descartável". Não é.

Um experimento Upstream pode ser implantado em AWS real — stack efêmera, recursos isolados,
ativado manualmente — para validar comportamento contra um provedor externo que não pode
ser exercitado localmente. O deploy de sandbox é parte do repertório de exploração.

**O que o distingue do Downstream:**
- Sem gate de aprovação ou Release Trail
- Stack destruída ao final (`teardown` obrigatório)
- Recursos prefixados `experiment-*`, isolados de staging e production
- Nenhum artefato produzido aqui é considerado entregável

**Quando mencionar:** sempre que a conversa sugerir que Upstream é limitado ao ambiente local
ou que "precisaria ir para Downstream" para validar contra um provedor real.

→ Referência técnica: [`execution-model/upstream.md — Sandbox Deploy`](execution-model/upstream.md#sandbox-deploy-upstream)

---

## O que nunca dizer

| Formulação incorreta | Por que está errada | Formulação correta |
|---|---|---|
| "Upstream é a fase de Discovery" | Upstream é um modo, não uma fase | "Upstream é o modo de exploração" |
| "Downstream é onde acontece a Delivery" | Downstream é um modo; Delivery existe nos dois | "Downstream é o modo de compromisso" |
| "Primeiro vai para Upstream, depois para Downstream" | Itens podem nascer direto em Downstream | "O time decide o modo conforme a clareza da ideia" |
| "ProdOps é um processo de desenvolvimento" | Limita a visão ao ciclo técnico | "ProdOps é um framework que conecta intenção de negócio à evidência de entrega" |
| "No Upstream não tem deploy" | Upstream tem sandbox deploy em AWS real | "Upstream pode chegar em ambiente real — sem gates, com stack efêmera" |
| "Para validar contra o provedor, precisa ir para Downstream" | O step `deploy-to-sandbox` existe exatamente para isso no Upstream | "Upstream tem deploy de sandbox para validar provedores reais sem compromisso" |

---

## Ajuste por audiência

**Para um engenheiro:**
> Upstream é branch de experimento sem PR obrigatório. Downstream é CI/CD com gates:
> OBC committed, BDD passando, Risks documentados, evidência em cada fase.
> Ambos têm Discovery e Delivery — o modo define se você tem compromisso de release ou não.

**Para um PM/PO:**
> Upstream é o espaço seguro para testar uma ideia antes de colocar no roadmap.
> Downstream é o compromisso: o que prometemos, entregamos — com evidência.
> As três jornadas (Discovery, Delivery, Operation) existem nos dois modos.

**Para um executivo:**
> ProdOps garante que cada entrega tem evidência rastreável — da intenção ao código em
> produção. E dá ao time liberdade real de explorar antes de assumir compromissos.

---

## Referências canônicas no framework

→ [Execution Model — Upstream](execution-model/upstream.md)
→ [Execution Model — Downstream](execution-model/downstream.md)
→ [Principles](principles.md) — Princípio 2 (Upstream before commitment)
→ [OBC](obc.md) — seção "OBC no Upstream" e "OBC no Downstream"
→ [Flow](flow.md) — visão geral do ciclo completo
