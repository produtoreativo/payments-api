# Payments API — Guia do Agente

Este arquivo é um roteador mínimo. O contexto de execução vive nos skills, no
manifest e nos artefatos do card — **não pré-leia a documentação do framework**.

## Como trabalhar

1. **Trabalho de Delivery:** invoque o skill da fase — `/bootstrap`, `/hack`,
   `/sync`, `/finish`, `/ship`, `/validate`, `/promote`. Cada skill é
   autossuficiente e diz o que ler.
2. **Exploração:** `/upstream`. **Implementação governada:** `/downstream`.
3. **Paths canônicos, quality gates e vocabulário:** `prodops/exec/manifest.yaml`
   — fonte única, legível por máquina. Consistência: `./prodops/scripts/validate-manifest.sh`.
4. **Contexto da tarefa:** a context capsule do card —
   `prodops/exec/cards/<card>/context.md`, gerada pelo gate de readiness do
   `/downstream`. Leia-a antes de alterar código de produção — e somente ela.
   Se não existir, execute o readiness do `/downstream` antes do `/bootstrap`.

## Regras invioláveis

- Nunca inventar OBCs, SLOs, riscos ou critérios de aceite ausentes. Contexto
  faltando → parar e reportar, não improvisar.
- Downstream exige: OBC committed + BDD Feature committed + entrada no
  Iteration Plan com status `Entrou` + riscos documentados.
- Reliability Plan é **recomendado** antes de iniciar Delivery; quando existe,
  deve ser revisado antes da decisão de readiness. Não é gate obrigatório.
- Conflito entre diretriz nova e regra existente: preservar a regra existente e
  registrar em Decision Trail (`prodops/templates/assessment/decision-trail.md`).
- Commits seguem Conventional Commits (tipos e limite de summary: no manifest).
- Toda entrega Downstream relevante gera append no release trail
  (`prodops/artifacts/governance/trails/release-trail.md`).

## Doutrina do framework (humanos; agentes somente sob demanda explícita)

Princípios, glossário, fluxo oficial, Origin Streams e modelo operacional:
`prodops/README.md` → `prodops/framework/`.
