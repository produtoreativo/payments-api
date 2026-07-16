# Cards — Context Capsules

Cada diretório aqui corresponde a **um card** e contém sua **context capsule**
(`<card-slug>/context.md`): o resumo comprimido (~1k tokens) que o `/bootstrap`
gera no gate de readiness a partir do OBC, da BDD Feature, dos riscos e do Reliability Plan. As
fases seguintes (Hack, Sync, Finish) leem a capsule em vez de percorrer a
árvore de artefatos — a "taxa de leitura" é paga uma única vez, no readiness do Downstream.

Regras:

- **Gerada, não escrita à mão.** Capsules são produzidas pelo `/downstream`
  seguindo `prodops/templates/delivery/context-capsule.md`. Não editar
  diretamente; se o contexto mudou, rodar o readiness do `/downstream` de novo.
- **Um diretório por card.** `prodops/exec/cards/<card-slug>/context.md`.
- **Seguro regenerar.** A capsule é derivada dos artefatos canônicos — pode
  ser recriada a qualquer momento sem perda de informação.
- **Commitar ou não fica a critério do time.** Capsules committed dobram como
  evidência de onboarding (mostram o contexto que a implementação enxergou);
  a recomendação é commitar.
