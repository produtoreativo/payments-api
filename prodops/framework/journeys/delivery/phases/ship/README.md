→ [Voltar para Delivery](../../README.md)

# Ship

---

## Visão Geral

**Para que serve:** Transforma a implementação aprovada pelo Finish em um artefato executável, versionado e publicado, e conduz sua entrega até o ambiente alvo via deployment.

**Como funciona:**

```
Preparation: Build → Package → Version → Sign → SBOM → Publish Artifact
Deployment:  Deploy → Progressive Delivery → Rollout
```

**Guardrails principais:**

- Não shipar mudanças de comportamento não documentadas
- Não incluir secrets, tokens reais ou paths locais no diff
- Evidência TDD obrigatória para mudanças de comportamento — ausência deve ser justificada
- Não alterar escopo de negócio durante o ship

**Posição no fluxo:**

```
CI Async  →  [Ship] → Validate → Promote
                 ↑
        precede pelo Finish do CI Sync
```

---

**Objetivo:** transformar a implementação finalizada em um artefato executável, publicável e implantável, conduzindo sua entrega até o ambiente alvo.

O Ship é organizado em duas famílias de capabilities:

## Preparation

Capabilities responsáveis por produzir o artefato:

| Capability | Descrição |
|---|---|
| **Build** | Compilar, transpilar e empacotar o código |
| **Package** | Criar o artefato distribuível (container, ZIP, layer) |
| **Version** | Aplicar versionamento semântico ao artefato |
| **Sign** | Assinar o artefato para garantir integridade e proveniência |
| **Generate SBOM** | Produzir o Software Bill of Materials |
| **Publish Artifact** | Publicar o artefato no registry (ECR, S3, npm) |

Build, Package e Publish são capabilities internas do Ship. Não são etapas independentes do fluxo principal.

## Deployment

Capabilities responsáveis por conduzir o artefato até o ambiente:

| Capability | Descrição |
|---|---|
| **Deploy** | Executar o deploy do artefato no ambiente alvo |
| **Progressive Delivery** | Estratégias de entrega gradual (canary, blue-green) |
| **Feature Flags** | Controle de ativação de features em runtime |
| **Rollout** | Expansão progressiva do tráfego para a nova versão |
| **Rollback** | Reverter para a versão anterior em caso de falha |
| **Infrastructure Validation** | Verificar que a infraestrutura está correta após deploy |

## Pré-condição

A fase Finish foi concluída: lint, build, testes e Definition of Done satisfeitos. Ver [finish/README.md](../finish/README.md).

## Sequência no Ship

1. Confirmar que a mudança está mapeada ao Reliability Plan ou a um follow-up documentado.
2. Revisar o diff final como se fosse um code review externo.
3. Verificar evidência TDD: toda mudança de comportamento precisa de Red Bar confirmado ou justificativa documentada.
4. Executar security checks: sem secrets, tokens reais, credenciais pessoais ou paths locais.
5. Preencher o template de PR com evidências. Ver [`commit-workflow/templates/pull_request.md`](../../capabilities/commit-workflow/templates/pull_request.md).
6. Publicar o Pull Request.
7. Executar Preparation (Build → Package → Version → Publish Artifact).
8. Executar Deployment (Deploy → Progressive Delivery conforme estratégia).
9. Registrar evidência de ship no Release Trail.

## Checklist Ship

- [ ] Diff revisado — nenhuma mudança não intencional incluída.
- [ ] Evidência TDD presente ou ausência justificada.
- [ ] Sem secrets, credenciais ou paths locais no diff.
- [ ] PR preenchido com: comportamento, validação, risco e rollback.
- [ ] Artefato produzido e publicado.
- [ ] Deploy realizado no ambiente alvo.
- [ ] Release Trail atualizado com entrada de ship.

Para mecânica de execução, veja [`prodops/skills/ship/`](../../../../../skills/ship/).
