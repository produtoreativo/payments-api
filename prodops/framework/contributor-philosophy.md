# Filosofia do Contribuidor

Este documento orienta quem propõe mudanças ao Framework ProdOps ou ao Runtime de referência.
Não é um processo de aprovação — é um conjunto de perguntas que ajuda a colocar cada mudança
no lugar certo.

---

## O padrão de camadas

Toda decisão de onde algo pertence parte de três camadas com responsabilidades distintas:

```
Framework  →  define ontologia, princípios e responsabilidades
Runtime    →  executa com escolhas opinativas de engenharia, aberto à extensão
Agents/Skills  →  otimizam livremente para cada serviço (Claude, Codex, Copilot…)
```

**Framework** responde à pergunta *"o que é verdade sobre este domínio?"*
Ele não sabe como você vai rodar — sabe o que existe e por quê.

**Runtime** responde à pergunta *"como uma implementação de referência faz isso?"*
Ele é opinativo por design: faz escolhas concretas de ferramenta, formato e fluxo.
Quem implementa pode trocar qualquer peça; o que não muda é o contrato com o Framework.

**Agents/Skills** respondem à pergunta *"como este serviço específico executa melhor?"*
São livres para usar capacidades exclusivas de cada plataforma — raciocínio, contexto longo,
ferramentas nativas — sem precisar de consistência entre si.

---

## O ideal que guia cada camada

> **Imutável, isolado, reproduzível, detectável.**

- **Imutável**: o resultado de uma execução não deve depender de estado acumulado fora do contrato.
- **Isolado**: cada componente deve poder ser substituído sem quebrar os outros.
- **Reproduzível**: rodar duas vezes com a mesma entrada deve produzir o mesmo efeito observável.
- **Detectável**: falhas e desvios devem ser visíveis sem instrumentação adicional.

Esses quatro qualificadores são a régua. Quando uma mudança viola algum deles, o ônus é de quem
propõe — não de quem revisa.

---

## Antes de propor uma mudança: três perguntas

**1. Isso é uma lei do domínio ou uma conveniência da implementação atual?**

Leis do domínio (o que é um evento, o que é um trail, o que é uma fase de delivery)
pertencem ao Framework.
Conveniências (como o script de emit chama a API do GitHub, qual campo o YAML usa)
pertencem ao Runtime ou ao produto.

Colocar conveniências no Framework o torna frágil. Colocar leis no Runtime as esconde.

**2. Existe evidência empírica ou só raciocínio teórico?**

O Framework e o Runtime evoluem a partir de experimentos reais — não de antecipação.
Uma abstração que nunca foi validada fora de um produto específico não está pronta para
o Framework. Fique no Runtime, ou melhor, no produto, até ter dois casos reais.

**3. A mudança menor que resolve o problema foi escolhida?**

Generalizar antes de precisar cria complexidade sem benefício. O anti-padrão mais comum
é abstrair para o Framework algo que só um produto usa. Se não há um segundo consumidor
real, não generalize ainda.

---

## Como evoluir o Runtime

O Runtime é uma implementação de referência, não uma biblioteca. Quem implementa pode
copiar, bifurcar, estender ou substituir qualquer parte.

O ciclo saudável de evolução:

```
produto descobre algo que funciona
  → extrai o que é product-specific para runtime.yaml / produto local
  → o que sobrou é candidato à RI
    → valida que funciona para outro consumidor hipotético
      → promove para Runtime canônico
```

**Regra prática**: antes de generalizar, elimine o específico. As seis cirurgias de
extração feitas no Runtime em agosto de 2026 (textos em PT → EN, hardcodes de experimento,
credenciais acopladas, branch hardcodada) são o exemplo canônico: primeiro isolamos o que
era do produto, só então o que sobrou virou RI exportável.

---

## Sobre inconsistências temporárias

O Framework e o Runtime evoluíram rapidamente. Por um período será normal encontrar
inconsistências entre documentos, entre nomes de conceitos, entre o que o código faz
e o que o doc diz.

A postura correta não é tolerar — é **mudar à vontade para manter a consistência**.

Inconsistência detectada = PR imediato. Não acumule dívida documental esperando o
"momento certo". O custo de corrigir cedo é baixo; o custo de deixar divergir é alto
porque o Framework é a fonte de verdade que os agentes leem antes de agir.

Quando encontrar conflito entre duas definições:
1. A camada mais alta prevalece (Framework > Runtime > Agents).
2. Se o conflito é dentro da mesma camada, o documento mais recente prevalece.
3. Documente a decisão em `framework-gaps.md` se o conflito revelar uma lacuna real.

---

## O que pertence a cada lugar: referência rápida

| O quê | Framework | Runtime | Produto | Agents/Skills |
|---|---|---|---|---|
| Definição de evento | ✓ | | | |
| Schema de evento | ✓ | | | |
| Script que emite | | ✓ | | |
| Credenciais e endpoints | | | ✓ | |
| Trail templates | | ✓ | | |
| Textos de trail do produto | | | ✓ | |
| Fase de delivery (o que é) | ✓ | | | |
| Skill de fase (como executar) | | ✓ | | |
| Otimização de prompt por modelo | | | | ✓ |
| runtime.yaml | | | ✓ | |
| runtime.yaml.example | | ✓ | | |

---

---

## Padrões da comunidade antes de padrões próprios

Antes de inventar um formato, schema, protocolo ou convenção para o Runtime, escolha um
padrão existente na comunidade — mesmo que tenha baixa adoção.

**Por quê?** Padrões da comunidade já resolveram os casos extremos que você ainda não
encontrou. Eles têm documentação, tooling, exemplos e contribuidores que continuarão
evoluindo o padrão independentemente deste projeto.

Referências canônicas do Runtime ProdOps:

| Domínio | Padrão adotado |
|---|---|
| Contratos de API HTTP | [OpenAPI](https://spec.openapis.org/oas/latest.html) |
| Contratos de eventos assíncronos | [AsyncAPI](https://www.asyncapi.com/docs/reference/specification/latest) |
| Envelope de eventos | [CloudEvents](https://cloudevents.io/) |
| Objetivos de nível de serviço | [OpenSLO](https://openslo.com/) |

Quando não existir um padrão da comunidade para o problema: documente o gap em
`framework-gaps.md`, descreva o padrão mínimo adotado e sinalize que é provisório.
Nunca eleve um padrão provisório a canônico sem revisão explícita.

## Convenções de arquivo

Todo documento do framework deve ter par de idioma:

- `nome.md` — versão em português
- `nome.en.md` — versão em inglês

Ambos criados no mesmo commit. Não existe "criar depois" — um documento sem par está incompleto.
O par `.en.md` é o que permite que o Runtime seja consumido por qualquer equipe e que os agentes
internacionais (Codex, Copilot, GPT) leiam o mesmo contrato sem dependência de tradução futura.

→ [principles.md](principles.md) — os 8 princípios fundacionais
→ [canonical-paths.md](canonical-paths.md) — onde cada artefato vive
→ [framework-gaps.md](framework-gaps.md) — lacunas conhecidas e decisões pendentes
→ [runtime/docs/contract.md](../runtime/docs/contract.md) — contrato do Runtime com o Framework
