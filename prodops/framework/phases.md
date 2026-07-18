# Fases da Business Intent: Concepção e Inception

O ciclo de vida de uma Business Intent antes da Delivery é organizado em duas fases distintas: **Concepção** e **Inception**. Elas diferem em compromisso, governança, estado do OBC e no que pode acontecer ao trabalho.

---

## Concepção

**Período:** desde o surgimento do Business Signal até a entrada no Product Backlog.

**Dois fluxos independentes — escolha um:**

| Fluxo | Quando usar | Backlogs |
|---|---|---|
| **Global** | Business Signal de escopo incerto; não se sabe qual produto ou time resolve. Envolve negócio, cadeia de valor ou plataforma inteira. | Portfolio Tracking List → Business Intent Backlog |
| **Local** | Business Signal já direcionado; destino certo — este produto, este time. Não precisa de triagem de plataforma. | Product Tracking List → (direto ao Product Backlog) |

Os dois fluxos são independentes. Um sinal não precisa passar pelo fluxo global antes de entrar no local. Não há duplicação entre as duas tracking lists.

**Pergunta central:** Existe valor real aqui?

**Governança:** Portfolio PM (fluxo global) ou Product Owner / responsável local (fluxo local). O Product Owner ainda não assumiu compromisso formal em nenhum dos dois.

**Estado do OBC:** Não existe nas Tracking Lists. No fluxo global, o **Global OBC** nasce como Draft ao entrar no Business Intent Backlog. No fluxo local, o **Local OBC** nasce como Draft diretamente ao entrar no Product Backlog.

**Compromisso:** Nenhum. A Business Intent pode ser descartada, reformulada ou adiada indefinidamente sem registro formal de aprendizado.

**O que termina a Concepção:** A entrada no Product Backlog após Owner Approval — independente de qual fluxo originou o Business Signal.

---

## Inception

**Período:** desde a entrada no Product Backlog até o Local OBC atingir o estado Committed (Iteration Backlog).

**Backlogs envolvidos:**
- Product Backlog (fonte de verdade) — com views: Icebox (Refining) → Iteration Backlog (Committed)

**Pergunta central:** O Product Owner está comprometendo atenção e capacidade para investigar isso agora?

**Governança:** Product Owner (aceite formal e modo de execução) e Tech Lead (Assessment Review).

**Estado do OBC (Local OBC):** Draft → Refining (Icebox) → Committed (Iteration Backlog).

**Compromisso:** Formal. O Product Owner comprometeu-se a investigar. Qualquer encerramento a partir daqui exige registro explícito de aprendizado e rastreabilidade no OBC.

**Modo de execução:** Upstream ou Downstream — são **modos**, não fases. O modo é definido pelo Product Owner ao aceitar a Business Intent no Product Backlog e pode mudar ao longo da Inception. Upstream é usado para alta incerteza; Downstream para clareza suficiente com gates obrigatórios. Um item pode iniciar Upstream e, após reduzir incerteza, transicionar para Downstream sem mudar de fase.

**O que termina a Inception:** Assessment Review aprovada, Local OBC em estado Committed, BDD Feature committed — item atinge o estado "pronto" no Product Backlog (view Iteration Backlog).

---

## A fronteira

A fronteira entre Concepção e Inception é a entrada no **Product Backlog** com **Owner Approval**.

```
CONCEPÇÃO

  [Sinal de escopo incerto]          [Sinal já direcionado]
  negócio / plataforma /             produto / time específico
  múltiplos produtos                 destino já conhecido
         │                                    │
         ▼                                    ▼
  Portfolio Tracking List         Product Tracking List
  (Portfolio governa)            (Product Owner / time governa)
         │                                    │
         ▼                                    │
  Business Intent Backlog                     │
  (Global OBC nasce como Draft)               │
  ├─ Roadmap [view: horizonte]               │
  └─ Platform Release [view: versão]         │
         │                                    │
         ▼ Discovery no BIB                   │
  OBC Partitioning                            │
  (Global OBC → Local OBCs)                  │
         │                                    │
         │  (Portfolio direciona ao produto)  │
         │                                    │
         └──────────────┬─────────────────────┘
                        │ Premortem + Análise de Risco + Owner Approval
                        ▼
══════════════ FRONTEIRA ══════════════════════════════════

INCEPTION

  Product Backlog  ← fonte de verdade do produto
  (Local OBC nasce como Draft se ainda não existe — fluxo local)
    │              │
    │  [view]      ├─ Icebox [Refining]
    │              └─ Iteration Backlog [Committed]
    │  (Assessment Review: PM + Tech Lead valida a transição)
         │
         ▼
  DELIVERY
```

**O que muda ao cruzar a fronteira:**

| Dimensão | Concepção | Inception |
|---|---|---|
| Backlogs | Tracking Lists, Business Intent Backlog | Product Backlog, Icebox (VIEW), Iteration Backlog (VIEW) |
| Governança | Portfolio PM (global) / responsável local | Product Owner + Tech Lead |
| OBC | Não existe → Global OBC Draft (BIB) / Local OBC Draft (Product Backlog) | Draft → Refining → Committed |
| Descarte | Sem registro formal | Exige registro de aprendizado no OBC |
| Modo de execução | Não aplicável | Upstream ou Downstream (modos, não fases) |

**No fluxo local**, o Business Signal vai diretamente da Product Tracking List para o Product Backlog via Premortem + Análise de Risco Preliminar + Owner Approval — sem passar pelo Portfolio, sem passar pelo Business Intent Backlog. O Local OBC nasce diretamente no Product Backlog. O Reliability Plan formal ainda não é exigido neste ponto — é produzido durante o Icebox.

---

## Referências

→ [Fluxo do Framework](flow.md)
→ [Hierarquia de Backlogs](backlogs.md)
→ [Glossário](glossary.md)
→ [Execution Model](../execution-model/README.md)
