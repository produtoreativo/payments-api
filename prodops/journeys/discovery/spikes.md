# Spike Solutions

## O que é uma Spike Solution

Uma Spike Solution é uma **investigação técnica com prazo definido** cuja única saída é uma decisão — não um produto, não um incremento, não código entregável.

O objetivo é responder uma única pergunta técnica específica que bloqueia ou condiciona progresso.

**Característica central:** nunca há cliente envolvido. Se há cliente, é um PoC.

---

## Spike Solution vs PoC

| Dimensão | PoC | Spike Solution |
|---|---|---|
| Cliente envolvido | Sempre | Nunca |
| Objetivo | Validar viabilidade com feedback real | Responder pergunta técnica específica |
| Produz | Aprendizado validado com cliente | Decisão técnica interna |
| Código | Pode ser demonstrável | Sempre descartável |
| Quando usar | Fase de Validação de Hipóteses | Qualquer estágio, qualquer fase |

---

## Quando usar

Uma Spike Solution é adequada quando:

- há uma incerteza técnica específica que bloqueia uma decisão de design ou arquitetura;
- a pergunta não pode ser respondida sem implementação exploratória;
- o escopo é pequeno e bem delimitado (uma pergunta = um spike);
- o risco de implementar sem investigar supera o custo do spike.

Uma Spike Solution **não** é adequada quando:

- o objetivo é validar com usuário ou cliente — use PoC;
- a investigação não tem pergunta definida — use experimento Upstream;
- o resultado será incorporado diretamente ao produto sem revisão — nesse caso, não é um spike.

---

## Quando pode ocorrer

Uma Spike Solution pode ocorrer em qualquer momento do ciclo de vida do produto:

- **Dentro de um experimento Upstream** — para responder uma questão técnica antes de avançar
- **Dentro de um PoC** — para validar um componente técnico antes da demonstração ao cliente
- **No Icebox** — para resolver incerteza técnica que bloqueia o OBC Minimum
- **Durante o Downstream** — para investigar um comportamento inesperado sem alterar o fluxo de entrega

---

## Como registrar

Registre o spike diretamente neste arquivo com a estrutura abaixo.

Se o spike faz parte de um experimento Upstream ativo, registre-o no `upstream-trail.md` do experimento, não aqui.

---

## Estrutura de um registro de Spike

```
## Spike — [Título]

**Data:** YYYY-MM-DD
**Estágio do produto:** PoC | MVP | IPR | MVR | MVT | MLP
**Pergunta:** [Uma pergunta específica e fechada]
**Timebox:** [Ex: 2 horas, 1 dia]

**O que foi investigado:**

**Evidências encontradas:**

**Decisão:**
- [ ] Avançar com a abordagem investigada
- [ ] Descartar a abordagem — motivo:
- [ ] Requer outro spike — pergunta:
- [ ] Escalar para experimento Upstream

**Artefatos produzidos:** (links para código descartável, scripts, notas)
```

---

## Spikes registrados

<!-- Adicionar entradas abaixo conforme ocorrem -->
