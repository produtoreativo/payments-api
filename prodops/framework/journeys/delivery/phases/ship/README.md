→ [Voltar para Delivery](../../README.md)

# Ship

---

## Visão Geral

**Para que serve:** Observa e orquestra o fluxo autônomo do Pull Request criado pelo Finish — checks, aprovação, merge e deploy para o ambiente de Staging da Feature.

**O que Ship NÃO é:** Ship NÃO realiza deploy. Ship NÃO executa CI. Ship NÃO aprova o PR.

**Quem executa:** GitHub (aprovação, merge, workflows) e GitHub Actions (pipelines, deploy).

**Ship:** observa a execução, emite eventos, reage a falhas.

**Como funciona:**

```
Detectar PR criado pelo Finish
→ Observar checks e workflows
→ Observar aprovação automática
→ Observar merge automático
→ Observar deploy para Staging
→ Ship.Completed (somente após merge + deploy bem-sucedido)
```

**Guardrails principais:**

- Não realizar deploy — GitHub Actions executa
- Não aprovar o PR — GitHub executa
- Não mergear o PR — GitHub executa
- Não emitir Ship.Completed sem merge confirmado E deploy em Staging concluído
- Se qualquer etapa CI falhar: interromper progressão, reportar. Finish deve ser reaberto.

**Posição no fluxo:**

```
CI Async  →  [Ship] → Validate → Promote
                 ↑
        precedido pelo Finish do CI Sync
```

---

**Objetivo:** observar a execução autônoma do PR e confirmar que a Feature está disponível em seu ambiente de Staging.

## Ambientes

| Ambiente | Tipo | Ship observa? |
|---|---|---|
| Staging | Efêmero por Feature/OBC | Sim — destino do deploy observado |
| Sandbox | Compartilhado (Release Candidate) | Não — responsabilidade do Promote |
| Production | Operacional | Não — fora da Delivery Journey |

Ship.Completed representa: Feature disponível em seu ambiente de Staging (efêmero por Feature/OBC).

## Responsabilidades por Ator

| Ator | Responsabilidade |
|---|---|
| **Finish** | Cria o PR autônomo (antes do Ship) |
| **GitHub** | Executa aprovação, merge e validações de proteção de branch |
| **GitHub Actions** | Executa pipelines de CI e deploy para Staging |
| **Ship** | Observa execução, emite Ship.Started e Ship.Completed, reage a falhas |
| **Promote** | Promove a Feature de Staging para Sandbox após Ship.Completed |

## Pré-condição

Finish.Completed emitido: PR criado, quality gates satisfeitos, auto-approval e auto-merge configurados.

## Sequência no Ship

1. Detectar o PR criado pelo Finish para o work-item correto.
2. Emitir Ship.Started.
3. Observar execução de checks e workflows do GitHub no PR.
4. Observar aprovação automática no PR.
5. Observar merge automático do PR.
6. Se qualquer check ou workflow falhar: interromper progressão e reportar.
7. Após merge: observar disparo do pipeline de deploy para Staging.
8. Observar resultado do deploy em Staging.
9. Se deploy falhar: interromper progressão e reportar.
10. Após deploy bem-sucedido: registrar evidência no Release Trail.
11. Emitir Ship.Completed.

## Checklist Ship

- [ ] PR criado pelo Finish detectado e confirmado.
- [ ] Checks e workflows do GitHub observados — todos passaram.
- [ ] Aprovação automática observada.
- [ ] Merge automático observado e confirmado.
- [ ] Pipeline de deploy para Staging observado e concluído com sucesso.
- [ ] Release Trail atualizado com entrada de ship.
- [ ] Ship.Completed emitido.

## Resposta a Falhas

| Falha | Ação |
|---|---|
| Check de CI falha | Interromper. Reportar. Finish deve ser reaberto. |
| Auto-approval não ocorre | Reportar como bloqueio. Aguardar investigação. |
| Merge não ocorre | Reportar como bloqueio. Aguardar investigação. |
| Deploy em Staging falha | Interromper. Reportar. Finish deve ser reaberto. |

Para mecânica de execução, veja [`prodops/skills/ship/`](../../../../../skills/ship/).
