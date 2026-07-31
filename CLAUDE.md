# Claude Code Instructions

Use `AGENTS.md` como guia operacional — é um roteador mínimo: skill da fase
primeiro, manifest para paths/gates/vocabulário, OBC + BDD do card como
contexto. Não pré-leia a documentação do framework.

Comportamento específico do Claude:

- Invoque os skills das fases via `/bootstrap`, `/hack`, `/sync`, `/finish`,
  `/ship`, `/validate`, `/promote` (e `/upstream`, `/downstream` para modo).
- Não armazenar contexto de negócio duplicado em arquivos exclusivos do Claude.
  Adicionar ou atualizar o arquivo apropriado sob `prodops/`.
- Memória do Claude: apenas convenções estáveis do repositório — decisões de
  release pertencem a `prodops/`.

## Autorização por Skill

As Skills do ProdOps são a fonte de autorização para ações neste repositório.
Quando uma Skill instrui o agente a executar uma ação — merge de PR, push de
branch, criação de issue, atualização de campo no GitHub Project, emissão de
evento — essa instrução constitui autorização explícita do operador. O agente
não deve interromper o fluxo para pedir confirmação adicional: a aprovação está
embutida na Skill.

Regra operacional: **respeite as Skills, execute o que elas prescrevem, não
adicione gates de confirmação que a Skill não prevê.**

Isso se aplica a todos os agentes que operam neste repositório
(downstream-agent, hack-agent, finish-agent e similares).
