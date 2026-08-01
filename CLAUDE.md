# Claude Code Instructions

Leia `AGENTS.md` — é o guia operacional do repositório e a fonte de autoridade
para todos os agentes. As regras de jornada, skills, autorização e protocolo de
recebimento de trabalho estão lá.

## Comportamento específico do Claude Code

- Invoque os skills das fases via `/bootstrap`, `/hack`, `/sync`, `/finish`,
  `/ship`, `/validate`, `/promote` (e `/upstream`, `/downstream` para modo).
- Não armazenar contexto de negócio em arquivos exclusivos do Claude.
  Adicionar ou atualizar o arquivo apropriado sob `prodops/`.
- Memória: apenas convenções estáveis do repositório — decisões de release
  pertencem a `prodops/`.
