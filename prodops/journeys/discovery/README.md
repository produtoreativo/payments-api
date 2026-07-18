# Discovery

## Propósito

Discovery é a jornada de exploração e preparação do ProdOps. Ela existe nos modos Upstream e Downstream com responsabilidades diferentes; não é sinônimo de Upstream.

---

## Discovery no Upstream

**Objetivo:** Explorar.

Não existe obrigação de concluir artefatos. Não existem gates obrigatórios. O engenheiro decide quais Skills utilizar. O resultado esperado é aprendizado.

Pode incluir:

- entrevistas e benchmarks
- Event Storming
- protótipos e spikes
- experimentos e vibecoding
- pesquisas

Um experimento Upstream pode produzir código de qualidade de produção, mas esse código é considerado exploratório até que a capability seja promovida para Downstream.

---

## Discovery no Downstream

**Objetivo:** Preparar um item comprometido para Delivery.

Um item entra no Icebox após ser aceito no Product Backlog. A Discovery no Downstream ocorre dentro do Icebox. O objetivo é produzir um Local OBC no estado Committed por meio de refinamento:

- funcional — o que o sistema deve fazer
- técnico — como o sistema deve fazer
- operacional — como o sistema deve se comportar em produção

Ao final da Discovery no Downstream, o item possui Local OBC no estado Committed e avança para o Iteration Backlog.

---

## Objetivos gerais

O Discovery existe para:

- compreender problemas de negócio;
- validar abordagens técnicas;
- explorar capabilities de provedores;
- prototipar integrações;
- validar fluxos de negócio;
- reduzir riscos de implementação;
- evoluir o conhecimento de Produto.

---

# Repository Scope Gate

Antes de criar um experimento, BDD Feature, OBC, protótipo, mudança no Validation Workbench
ou qualquer artefato de execução, confirmar que a capability pode ser desenvolvida
ou validada dentro deste repositório.

Criar artefatos de execução apenas quando este repositório for dono ou puder exercitar diretamente
ao menos um dos seguintes:

- comportamento de API;
- lógica de domínio;
- integração com provedor;
- tratamento de webhook;
- persistência;
- contratos de propriedade da Payments API;
- fluxo do Validation Workbench;
- testes ou evidências executáveis.

Se a solicitação depende de implementação de propriedade de outro repositório ou sistema,
não criar Feature, experimento, protótipo ou artefato de execução aqui.
Registrar apenas como:

- dependência externa;
- risco de release;
- item da Product Tracking List;
- nota do Reliability Plan;
- evidência requerida do sistema responsável.

Exemplos de trabalho fora do repositório:

- implementação da Feature Flag do Checkout;
- targeting de rollout do Checkout;
- comportamento de entrega do Notification Service;
- comportamento de fulfillment do Order Management;
- integração corporativa de ITSM fora da Payments API.

O Upstream pode documentar a dependência, mas não deve fazê-la parecer executável neste repositório.

---

# Saídas Típicas

Uma atividade Upstream pode produzir:

- código executável;
- melhorias no Validation Workbench;
- protótipos;
- cenários BDD;
- OBC drafts;
- atualizações de OpenAPI;
- atualizações de AsyncAPI;
- atualizações de Event Storming;
- atualizações do Reliability Plan;
- atualizações da Product Tracking List;
- decisões de arquitetura.

---

# Workflow

Um fluxo Upstream típico é:

Pergunta de Negócio

↓

Hipótese

↓

Experimento

↓

Implementação

↓

Validação Funcional

↓

Aprendizado

↓

Decisão

↓

Assessment

↓

Downstream (se aprovado)

---

# Experiments

Experimentos ficam em:

```
prodops/journeys/discovery/experiments/
```

Cada experimento deve responder a uma pergunta específica.

Exemplos:

- A API do provedor é suficiente?
- Qual arquitetura deve ser adotada?
- Este fluxo de negócio pode ser validado?
- Quais são os riscos operacionais?

Experimentos devem ser pequenos e focados.

## Experiment File Layout

Novos experimentos devem usar um diretório por experimento:

```text
prodops/journeys/discovery/experiments/NNN-short-slug/
  experiment.md
  upstream-trail.md
  evidence/
```

Use `experiment.md` para a hipótese estável, escopo, descobertas, recomendação e Decision Package.

Use o `upstream-trail.md` local do experimento para notas cronológicas de execução, evidências de validação, mudanças em artefatos e decisões ocorridas durante o experimento.

Use `evidence/` apenas para material de suporte muito detalhado para o documento do experimento, como saídas de comandos, capturas de tela, exemplos de payload ou respostas do provedor.

Arquivos planos de experimento restaurados de caminhos legados são artefatos históricos. Não criar novos arquivos planos de experimento. Se um arquivo plano for restaurado do histórico ou de outra branch, migrá-lo para o padrão de diretório canônico antes de fazer outras alterações.

O `prodops/journeys/discovery/upstream-trail.md` global não é o lugar primário para o histórico de execução de experimentos. Mantê-lo como índice cronológico de alto nível para marcos entre experimentos, migrações, promoções e mudanças de processo Discovery/Upstream em nível de repositório.

---

# Validation Workbench

O Validation Workbench é o ambiente preferencial para validação funcional.

É usado para:

- validar fluxos de negócio;
- validar integrações;
- validar cenários BDD;
- simular comportamento do provedor;
- validar UX;
- reduzir incerteza de implementação.

O Validation Workbench faz parte do Upstream.

---

# Relationship with Assessment

Todo experimento concluído deve produzir um Decision Package.

O Decision Package alimenta o Continuous Assessment.

O Assessment decide se uma capability deve:

- avançar para Downstream;
- exigir outro experimento;
- aguardar decisões de negócio;
- ser descartada.

## Revisão do Decision Package

O Decision Package não é revisado automaticamente — ele precisa de uma decisão explícita de quem tem autoridade sobre o produto e a arquitetura.

### Quando revisar

Após o experimento atingir seus Exit Criteria (hipótese respondida, recomendação produzida, artefatos atualizados). Não revisar experimentos incompletos.

### Quem participa

| Papel | Responsabilidade na revisão |
|---|---|
| Product Manager | Valida o valor de negócio e decide se a capability entra no Iteration Plan |
| Tech Lead | Valida viabilidade técnica, riscos arquiteturais e OBC |
| Autor do experimento | Apresenta as descobertas e defende a recomendação |

### O que é revisado

O Decision Package completo (seções do `experiment.md`):
- **Executive Summary** — entendimento compartilhado do que foi descoberto
- **Recommended Decision** — a recomendação do autor (ver opções abaixo)
- **Updated Risks** — novos riscos ou riscos mitigados
- **Updated Opportunities** — oportunidades identificadas
- **Updated Tracking Items** — itens que precisam entrar nas Product Tracking Lists ou Portfolio Tracking Lists
- **Updated OBCs** — critérios de sucesso propostos
- **Recommended Downstream Scope** — o que entra na próxima iteração, se aprovado

### Possíveis saídas da revisão

| Recomendação | O que acontece |
|---|---|
| **Promover** | Iniciar processo de promoção (ver seção "Processo de promoção para Downstream"). BDD Feature + OBC movidos. Capability entra no Iteration Plan. |
| **Promover com restrição** | Subconjunto da capability é promovido. Partes restritas permanecem em Upstream para outro experimento. |
| **Requer outro experimento** | Criar novo experimento com hipótese mais específica. Registrar a decisão no `upstream-trail.md` do experimento atual. |
| **Aguardar decisão de negócio** | Bloquear o experimento na Product Tracking List com o decisor e a data esperada. Não abrir novo experimento até a decisão chegar. |
| **Aguardar dependência externa** | Registrar a dependência no Reliability Plan e na Product Tracking List. Monitorar no Continuous Assessment. |
| **Descartar** | Registrar o aprendizado em `prodops/journeys/discovery/learnings.md`. Fechar o experimento com justificativa no `upstream-trail.md`. |

### Registro da decisão

Independente da saída, registrar no `upstream-trail.md` do experimento:
- Data da revisão
- Participantes
- Decisão tomada
- Próximos passos

Se a saída gerar mudança no Reliability Plan, atualizar `prodops/journeys/assessment/risks.md` ou `opportunities.md` antes de fechar o ciclo.

---

# Relationship with Downstream

O Upstream prepara conhecimento.

O Downstream entrega software.

Uma capability deve avançar para Downstream apenas quando:

- o comportamento de negócio está compreendido;
- a arquitetura está estável;
- o Reliability Plan foi atualizado;
- o OBC está suficientemente definido;
- a incerteza remanescente é aceitável.

## Processo de promoção para Downstream

A promoção é uma decisão explícita, não uma consequência automática de um experimento concluído.

### Quem decide

A decisão de promover é do Product Manager + Tech Lead responsáveis pela capability, com base no Decision Package produzido pelo experimento.

### Critérios de promoção

Antes de promover, confirmar que:

1. O Decision Package do experimento tem recomendação clara (`Promover` ou `Promover com restrição`).
2. O comportamento esperado está descrito em um BDD Feature em `prodops/journeys/discovery/experiments/<NNN-slug>/features/` pronto para ser movido para `prodops/artifacts/business/bdd/`.
3. O OBC draft em `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/` tem critérios mensuráveis e pode ser movido para `prodops/artifacts/business/obcs/`.
4. O Reliability Plan foi atualizado com os riscos e mitigation actions identificados no experimento.
5. A incerteza remanescente é aceitável para entrar em Downstream com compromisso de entrega.

### Passos da promoção

```
1. Mover BDD Feature:
   prodops/journeys/discovery/experiments/<NNN-slug>/features/<slug>.feature
   → prodops/artifacts/business/bdd/<slug>.feature

2. Mover OBC:
   prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md
   → prodops/artifacts/business/obcs/<slug>.md
   (remover marcação de draft)

3. Criar ou atualizar entrada no Iteration Plan:
   prodops/artifacts/governance/plans/iteration-plan.md
   (adicionar com decisão `Entrou` na tabela "Iteration Plan recomendado" —
   não apenas em "Iteration Backlog identificado", pois esta seção não satisfaz
   a pré-condição formal do Downstream)

4. Atualizar Product Tracking List se o item estava lá:
   prodops/artifacts/product/backlogs/tracking-list.md
   (mudar status para "Promovido para Downstream")

5. Registrar a promoção no upstream-trail do experimento:
   prodops/journeys/discovery/experiments/<NNN-slug>/upstream-trail.md

6. Registrar no global upstream trail:
   prodops/journeys/discovery/upstream-trail.md
   (entrada de alto nível: o quê foi promovido e quando)
```

### O que NÃO é promoção

- Mover código para produção sem mover os artefatos ProdOps.
- Criar um OBC committed sem BDD Feature correspondente.
- Iniciar implementação Downstream antes de o OBC estar em `prodops/artifacts/business/obcs/`.
- Promover com recomendação `Não promover` ou `Requer outro experimento` no Decision Package.

---

# Golden Rules

- Manter experimentos focados.
- Responder a uma pergunta por vez.
- Produzir evidências executáveis sempre que possível.
- Parar quando a hipótese tiver sido respondida.
- Atualizar os artefatos ProdOps afetados.
- Documentar aprendizados.
- Produzir uma recomendação clara.
- Evitar implementar capabilities não relacionadas.

O aprendizado é o resultado primário.

A implementação é um meio para alcançar o aprendizado.
