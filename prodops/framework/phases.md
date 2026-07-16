# Fases da Intenção: Concepção e Inception

O ciclo de vida de uma Intent antes da Delivery é organizado em duas fases distintas: **Concepção** e **Inception**. Elas diferem em compromisso, governança, estado do OBC e no que pode acontecer ao trabalho.

---

## Concepção

**Período:** desde o surgimento do sinal até a entrada no Product Intent Backlog.

**Backlogs envolvidos:**
- Fluxo global: Global Tracking List → Business Intent Backlog
- Fluxo local: Repository Tracking List (sem OBC ainda)

**Pergunta central:** Existe valor real aqui?

**Governança:** Portfolio PM (fluxo global) ou responsável pelo sinal local. O Product Owner ainda não assumiu compromisso.

**Estado do OBC:** Não existe nas Tracking Lists. Nasce como Draft quando a Intent entra no Business Intent Backlog (fluxo global). No fluxo local, o OBC nasce como Draft somente ao entrar no Product Intent Backlog.

**Compromisso:** Nenhum. A Intent pode ser descartada, reformulada ou adiada indefinidamente sem registro formal de aprendizado.

**O que termina a Concepção:** A entrada no Product Intent Backlog após Owner Approval.

---

## Inception

**Período:** desde a entrada no Product Intent Backlog até o OBC atingir o estado Minimum OBC (Iteration Backlog).

**Backlogs envolvidos:**
- Product Intent Backlog → Icebox → Assessment Review → Iteration Backlog

**Pergunta central:** O Product Owner está comprometendo atenção e capacidade para investigar isso agora?

**Governança:** Product Owner (aceite formal e modo de execução) e Tech Lead (Assessment Review).

**Estado do OBC:** Draft → Draft em refinamento (Icebox) → Minimum OBC (Iteration Backlog).

**Compromisso:** Formal. O Product Owner comprometeu-se a investigar. Qualquer encerramento a partir daqui exige registro explícito de aprendizado e rastreabilidade no OBC.

**Modo de execução:** Upstream (alta incerteza, código descartável) ou Downstream (clareza suficiente, gates obrigatórios). O modo é definido pelo Product Owner ao aceitar a Intent no PIB.

**O que termina a Inception:** Assessment Review aprovada, OBC em estado Minimum OBC, BDD Feature committed — entrada no Iteration Backlog.

---

## A fronteira

A fronteira entre Concepção e Inception é a entrada no **Product Intent Backlog** com **Owner Approval**.

```
CONCEPÇÃO
  Global Tracking List / Repository Tracking List
    ↓  (sinal investigado, valor reconhecido)
  Business Intent Backlog  ← OBC nasce como Draft (fluxo global)
    ↓  (Roadmap / Platform Release — decisão de Portfolio)
─────────────── FRONTEIRA: Owner Approval ───────────────
INCEPTION
  Product Intent Backlog  ← Product Owner aceita, modo definido
    ↓  (Discovery: Upstream ou Downstream)
  Icebox
    ↓  (Assessment Review: PM + Tech Lead)
  Iteration Backlog  ← OBC atinge Minimum OBC
    ↓
DELIVERY
```

**O que muda ao cruzar a fronteira:**

| Dimensão | Concepção | Inception |
|---|---|---|
| Backlogs | Tracking Lists, Business Intent Backlog | Product Intent Backlog, Icebox, Iteration Backlog |
| Governança | Portfolio PM | Product Owner + Tech Lead |
| OBC | Não existe → Draft (BIB) | Draft → Draft em refinamento → Minimum OBC |
| Descarte | Sem registro formal | Exige registro de aprendizado no OBC |
| Modo de execução | Não aplicável | Upstream ou Downstream |

**No fluxo local**, a fronteira de entrada na Inception é o Owner Approval após Premortem e Análise de Risco Preliminar. O Reliability Plan formal ainda não é exigido neste ponto — é produzido durante o Icebox.

---

## Referências

→ [Fluxo do Framework](flow.md)
→ [Hierarquia de Backlogs](backlogs.md)
→ [Glossário](glossary.md)
→ [Execution Model](../execution-model/README.md)
