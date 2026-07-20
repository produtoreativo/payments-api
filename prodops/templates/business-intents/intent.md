# Business Intent — [Título]

Localização canônica: `prodops/artifacts/business/intents/<slug>.md`

> Uma **Business Intent** registra uma decisão estratégica de perseguir valor — nascida de um ou mais Business Signals. Não é um compromisso de implementação. É o ponto de entrada formal do Framework antes de decidir se o trabalho segue por Upstream (exploração) ou Downstream (entrega governada). Entidades nunca mudam de identidade: um Business Signal **gera** uma Business Intent; uma Business Intent **possui** um OBC como documento de contrato.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| Título | |
| Origin Stream | Business / Enterprise / Team / Technology |
| Data de registro | YYYY-MM-DD |
| Solicitante | |
| Dono de produto | |

> **Origin Stream:** Classifique a origem do Business Signal que gerou esta Business Intent. Escolha exatamente um:
> - **Business** — mercado, cliente, produto (conversão, adoção, receita, retenção)
> - **Enterprise** — compliance, regulação, auditoria, parceiros, governança
> - **Team** — processo, produtividade, onboarding, automações, fluxo de trabalho
> - **Technology** — plataforma, segurança, infraestrutura, observabilidade, confiabilidade
>
> Ver [`framework/origin-streams.md`](../../framework/origin-streams.md) para definições e exemplos.

---

## Intenção

Descreva em uma ou duas frases o valor que se pretende gerar.

> "Queremos que [ator] consiga [ação] para [resultado de negócio / melhoria operacional]."

---

## Contexto

Por que esta intenção surgiu agora? Qual pressão, oportunidade ou problema a motivou?

---

## Hipóteses

Liste as hipóteses que motivam esta intenção e que deverão ser confirmadas, refinadas ou descartadas durante a exploração.

Uma hipótese deve representar uma crença sobre o negócio, o usuário, o processo ou o sistema — não uma decisão de implementação.

Exemplos:

- [ ] A limitação atual reduz a conversão / gera custo operacional / cria risco.
- [ ] Resolver este problema gerará valor mensurável.
- [ ] Existe demanda suficiente para justificar o investimento.

---

## Perguntas em aberto

O que precisa ser respondido antes de comprometer implementação?

- [ ]
- [ ]

---

## Modo de execução sugerido

- [ ] **Upstream** — há incerteza suficiente para explorar antes de comprometer
- [ ] **Downstream** — há clareza suficiente; OBC e BDD podem ser escritos agora

Justificativa:

---

## Próximo passo

- Se Upstream: criar experimento em `prodops/journeys/discovery/experiments/`
- Se Downstream: criar OBC em `prodops/artifacts/business/obcs/` e BDD Feature em `prodops/artifacts/business/bdd/`

---

## Artefatos gerados

| Artefato | Localização |
|---|---|
| | |
