# Finish

Read `prodops/skills/finish/SKILL.md` and execute the full Finish flow.

O Finish tem **quatro sub-passos**, cada um com responsabilidade única e uma fronteira explícita do que **não** faz. Execute-os em ordem; para rodar só um, use o prompt do sub-passo:

1. **validate** (`#finish-validate`) — análise estática de qualidade (format, lint, build) + aceitação/cobertura como exceção dinâmica. Falha retorna ao `hack tdd`.
2. **review** (`#finish-review`) — inspeciona a pipeline e confirma as regras de PR automático, sem executá-la. Branch protection ausente é bloqueador.
3. **push origin** — publica os commits na branch de origem, sem force push.
4. **request** (`#finish-request`) — abre o PR em modo auto aprovação (`gh pr merge --auto --squash`) e atualiza o Release Trail.

Ordem obrigatória: `validate` verde → `review` sem bloqueadores → push → `request`.
