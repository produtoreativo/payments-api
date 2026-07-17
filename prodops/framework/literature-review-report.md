# Literature Review Report — Framework ProdOps

**Data:** 2026-07-10
**Escopo:** Revisão e reorganização da literatura sobre entradas do Framework ProdOps (origens das mudanças)
**Objetivo:** Consistência conceitual, nomenclatura única, ausência de ambiguidades

---

## 1. Conceitos renomeados

| De | Para | Justificativa |
|---|---|---|
| **Business Intent** | **Intent** | O nome "Business Intent" sugeria que apenas necessidades de mercado (Business) eram capturáveis pelo Framework. A nomenclatura canônica passa a ser "Intent" com um atributo "Origin Stream" declarado. O diretório `prodops/artifacts/business/intents/` é mantido por retrocompatibilidade. |
| **OBC (Outcome-Based Criterion)** | **OBC (Observable Business Contract)** | A definição anterior era incorreta. Um OBC não é um "critério baseado em resultado" mas sim um "contrato observável de negócio" — a distinção é importante porque o contrato é verificável e âncora toda a cadeia de entrega. |
| **Capability** (ambíguo) | **Delivery Capability** ou **Product Capability** | O termo "capability" era usado com dois significados distintos: (1) competências técnicas do processo de entrega (Commit Workflow, Contract Management, etc.) e (2) funcionalidades de produto sendo construídas (split payment, suporte a Pix). A ambiguidade foi resolvida com termos qualificados. |
| **Business** (nó de topo no modelo operacional) | **Origin Stream (Business \| Enterprise \| Team \| Technology)** | O modelo operacional anterior mostrava apenas "Business" como nó de topo, omitindo que há quatro tipos de origem possíveis. |

---

## 2. Ambiguidades eliminadas

### A. OBC definido incorretamente como "Outcome-Based Criterion"

**Problema:** O glossário definia OBC como "Outcome-Based Criterion" — um critério baseado em resultado. Essa definição era incorreta. O OBC é um Observable Business Contract — um contrato, não apenas um critério.

**Impacto:** A definição errada minava a compreensão do papel central do OBC como contrato verificável que âncora toda a cadeia de entrega.

**Solução aplicada:** Definição corrigida no glossário, no operating model, no assessment/README.md e em toda nova documentação. Adicionada nota "Anteriormente definido incorretamente como".

---

### B. Origin Streams inexistentes na documentação

**Problema:** O conceito de que uma Intent pode ter quatro origens diferentes (Business, Enterprise, Team, Technology) não existia em nenhum documento. O modelo operacional mostrava apenas "Business" como nó de topo, criando a falsa impressão de que o Framework só serve para necessidades de mercado.

**Impacto:** Times com necessidades de compliance, evolução de infraestrutura ou melhoria de processo não tinham vocabulário para registrar suas Intents de forma canônica.

**Solução aplicada:** Criado `prodops/framework/origin-streams.md` com definição completa dos quatro Origin Streams, exemplos, contraexemplos e regras de classificação. O modelo operacional foi atualizado para mostrar Origin Stream como camada de topo.

---

### C. "Business Intent" como nomenclatura restritiva

**Problema:** O termo "Business Intent" era ambíguo por dois motivos: (1) "Business" podia ser interpretado como o Origin Stream Business especificamente, excluindo os outros três; (2) "Intent" precedida de "Business" criava a impressão de que apenas intenções de negócio de mercado eram capturáveis.

**Impacto:** A nomenclatura reduzia o escopo percebido do Framework, levando times de compliance, infraestrutura e processo a não registrar Intents ou registrá-las de forma improvisada.

**Solução aplicada:** A nomenclatura canônica passa a ser "Intent" (sem qualificador). O Origin Stream é um atributo da Intent, não parte do nome. O diretório `prodops/artifacts/business/intents/` é mantido por retrocompatibilidade com nota explicativa no README.

---

### D. Exploration vs Discovery vs Upstream — três termos para a mesma fase

**Problema:** Os três termos eram usados de forma intercambiável em diferentes documentos:
- `exploration` aparecia como etapa implícita no fluxo mas nunca nomeada explicitamente
- `discovery` era usado tanto como nome da jornada quanto como sinônimo do modo Upstream
- `upstream` era usado tanto como modo de execução quanto como nome informal da jornada Discovery

**Impacto:** Ao ler documentos diferentes, não ficava claro se "fazer Upstream", "ir para Discovery" e "entrar em Exploration" eram a mesma coisa ou conceitos distintos.

**Solução aplicada:** Tabela de distinção criada no glossário e no flow.md:

| Termo | Nível | Significado |
|---|---|---|
| **Exploration** | Etapa do fluxo | O que acontece: redução de incerteza entre Intent e OBC |
| **Discovery** | Jornada | O nome da jornada do Framework que implementa Exploration |
| **Upstream** | Execution Mode | O modo de execução (baixo compromisso) usado durante Discovery |

---

### E. "Capability" com dois significados distintos

**Problema:** O termo "capability" aparecia em dois contextos com significados completamente diferentes:
- `operating-model.md`: "Capability — competências reutilizáveis consumidas pelas fases" → Delivery Capability (Commit Workflow, Observability, etc.)
- `execution-model/upstream.md`: "explorar uma capability nova", "Reduzir incerteza antes de uma capability entrar no fluxo" → Product Capability (o que está sendo construído)

**Impacto:** Ao ler "capability" isoladamente, não ficava claro se estávamos falando de um mecanismo do processo de entrega ou de uma funcionalidade de produto.

**Solução aplicada:** O glossário agora define explicitamente "Delivery Capability" e "Product Capability" como conceitos distintos. O modelo operacional atualiza o termo no diagrama hierárquico para "Delivery Capability". Uma nota no glossário orienta a usar sempre o termo qualificado quando houver ambiguidade.

---

### F. OBC posicionado incorretamente como entrada do Framework

**Problema:** Vários documentos implicitamente tratavam o OBC como ponto de entrada ou como a primeira coisa a ser criada. O fluxo `Business Intent → Assessment → Upstream/Downstream` omitia a etapa de Exploration que precede o OBC.

**Impacto:** O OBC estava sendo confundido com a entrada do sistema, quando na verdade é o resultado da Exploration sobre uma Intent.

**Solução aplicada:** O `flow.md` explicita a sequência correta com ênfase: "O OBC NÃO é a entrada. O OBC é a transformação de uma Intent suficientemente compreendida em um contrato observável." O modelo operacional foi atualizado para mostrar a camada de Exploration entre Intent e OBC.

---

## 3. Arquivos criados

| Arquivo | Conteúdo |
|---|---|
| `prodops/framework/origin-streams.md` | Definição completa dos quatro Origin Streams (Business, Enterprise, Team, Technology) com exemplos, contraexemplos, artefatos gerados e regras de classificação. Inclui diagrama Mermaid. |
| `prodops/framework/flow.md` | Fluxo oficial do Framework: Origin Stream → Intent → Exploration → OBC → Iteration Plan → Reliability Plan → Delivery → Operation. Para cada etapa: objetivo, o que acontece, o que é produzido, quando avançar. Inclui diagrama Mermaid e tabela de distinção Exploration/Discovery/Upstream. |

---

## 4. Arquivos modificados

| Arquivo | Modificação |
|---|---|
| `prodops/framework/glossary.md` | Corrigido OBC para "Observable Business Contract". Adicionadas entradas: Origin Stream, Intent, Business (Origin Stream), Enterprise (Origin Stream), Team (Origin Stream), Technology (Origin Stream), Exploration, Discovery (revisada), Delivery Capability, Product Capability. Todas as entradas agora têm: definição, propósito, quando usar, quando não usar, relação com outros conceitos. |
| `prodops/framework/operating-model.md` | Adicionada camada Origin Stream no topo do diagrama hierárquico. Adicionada camada Exploration entre Intent e OBC. Renomeado "Business Intent" para "Intent". Renomeado "Capability" para "Delivery Capability". Atualizado ciclo de vida. Adicionados links para `flow.md` e `origin-streams.md`. |
| `prodops/artifacts/business/intents/README.md` | Atualizado para refletir a nomenclatura Intent com Origin Stream. Adicionada nota de retrocompatibilidade. Adicionada tabela dos quatro Origin Streams. Atualizado fluxo pós-registro para incluir Exploration. Tabela de Intents ativas com coluna Origin Stream. |
| `prodops/templates/business-intents/intent.md` | Adicionado campo "Origin Stream" na tabela de Identificação. Adicionada nota explicativa com os quatro Origin Streams e link para `origin-streams.md`. Renomeado título de "Business Intent" para "Intent". Generalizado "Hipóteses de Negócio" para "Hipóteses". |
| `prodops/README.md` | Atualizado modelo operacional para mostrar Origin Stream no topo. Adicionados links para `framework/flow.md` e `framework/origin-streams.md`. Atualizada ordem de leitura. Atualizado portal com nova descrição de `framework/`. |
| `prodops/framework/canonical-paths.md` | Adicionadas entradas para `flow.md` e `origin-streams.md` na seção Framework. Renomeada seção "Business Intents" para "Intents". Adicionada entrada para template de Intent. Renomeada seção "Delivery — Capabilities" para "Delivery — Capabilities (Delivery Capabilities)". |
| `AGENTS.md` | Atualizada ordem de leitura para incluir `flow.md` e `origin-streams.md`. Adicionadas entradas no Source of Truth: fluxo oficial, Origin Streams, Intents registradas. Atualizada nomenclatura OBC para "Observable Business Contracts". Atualizada referência a "capability" para "Product Capability". |
| `prodops/journeys/assessment/README.md` | Corrigida definição de OBCs de "Outcome-Based Criteria" para "Observable Business Contracts". |

---

## 5. Arquivos removidos

Nenhum arquivo foi removido.

---

## 6. Impactos de compatibilidade

### Retrocompatibilidade preservada

- **Diretório `prodops/artifacts/business/intents/`:** Mantido com nota explicativa. Documentos existentes não foram renomeados.
- **Links internos:** Todos os links existentes foram preservados. Novos links foram adicionados.
- **Artefatos existentes (split-payment.md):** Não alterados. O artefato existente continua válido como Intent de origem Business.

### Alterações visíveis

- O modelo operacional agora mostra `Origin Stream (Business | Enterprise | Team | Technology)` no topo, onde antes mostrava apenas `Business`. Leitores do modelo antigo verão uma hierarquia mais rica.
- O term `OBC` mantém a sigla mas muda o significado expandido de "Outcome-Based Criterion" para "Observable Business Contract". O comportamento esperado do OBC não muda — apenas a definição textual.
- O termo "Capability" no diagrama do modelo operacional agora aparece como "Delivery Capability" para evitar ambiguidade.

---

## 7. Recomendações para evolução futura

### 7.1 — Atualizar artefato split-payment.md para incluir Origin Stream

O artefato `prodops/artifacts/business/intents/split-payment.md` é a única Intent existente e não possui o campo Origin Stream. Recomenda-se atualizar para incluir `origin_stream: Business` na tabela de Identificação, servindo como exemplo canônico do novo formato.

### 7.2 — Revisar uso de "capability" em documentos de jornadas

O termo "capability" (sem qualificador) ainda aparece em vários documentos das jornadas Delivery e Discovery. Uma varredura futura deve identificar cada ocorrência e qualificar como "Product Capability" ou "Delivery Capability" conforme o contexto.

### 7.3 — Criar exemplos de Intent por Origin Stream

Atualmente existe apenas um exemplo de Intent (split-payment.md, origem Business). Criar exemplos documentados para os outros três Origin Streams ajudaria times de compliance, infraestrutura e engenharia a reconhecer e registrar suas Intents.

### 7.4 — Considerar separação do diretório business-intents

No médio prazo, avaliar migrar `prodops/artifacts/business/intents/` para `prodops/intents/` para eliminar definitivamente a ambiguidade. Este passo exige atualizar todos os links internos e deve ser feito com coordenação da equipe. Não recomendado neste ciclo para evitar ruptura.

### 7.5 — Adicionar nota de retrocompatibilidade ao split-payment.md

Adicionar comentário inicial ao split-payment.md indicando que este artefato foi registrado antes da introdução dos Origin Streams e que seu Origin Stream é Business.

---

## Decisões arquiteturais tomadas

**Por que "Intent" e não "Business Intent"?**
Clareza supera familiaridade. O nome "Business Intent" criava uma barreira de entrada para todos os Origin Streams que não são Business. A escolha de simplificar para "Intent" (com Origin Stream como atributo) é mais genérica e mais precisa simultaneamente.

**Por que manter `prodops/artifacts/business/intents/` sem renomear?**
Retrocompatibilidade. Renomear o diretório quebraria todos os links existentes nos artefatos, nas skills e nos documentos de treinamento. A decisão de renomear pode ser tomada em um ciclo dedicado com impacto menor de ruptura.

**Por que "Exploration" como nome da etapa do fluxo?**
Para resolver a polissemia de "Discovery" (que é a jornada) e "Upstream" (que é o modo). "Exploration" é o termo do nível do fluxo macro — neutro em relação à jornada e ao modo. Isso permite dizer "durante a Exploration" sem conotar qual jornada ou modo está sendo usado.

**Por que "Delivery Capability" em vez de apenas "Capability"?**
Para distinguir do termo "Product Capability" que já era usado informalmente. "Delivery Capability" é mais preciso e segue o padrão de qualificação que o Framework usa em outros lugares (ex: "CI Sync" vs "CI Async").
