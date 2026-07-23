# Papel de Upstream Empírico

O repositório `payments-api` atua temporariamente como upstream empírico do ProdOps Framework.

---

## O que significa `status: self`

`status: self` em `prodops/exec/framework-lock.yaml` indica que este repositório é simultaneamente:
- o produto consumidor do Framework;
- a fonte de verdade temporária do próprio Framework.

Isso **não** significa que o domínio de Payments faz parte do ProdOps.
Significa que as definições canônicas ainda evoluem empiricamente neste repositório.

---

## Por que este estado existe

O repositório `prodops-framework` separado existe e está sendo preparado para receber o
conteúdo canônico reconciliado. Durante essa fase, toda evolução do Framework ocorre aqui,
com separação semântica clara das áreas locais.

---

## Boundaries ativos

**O que é canônico (será exportado para `prodops-framework`):**
- `prodops/framework/` — princípios, glossário, ontologia, fluxo, canonical-paths, jornadas
- `prodops/skills/<framework-skills>/` — bootstrap, hack, sync, finish, ship, validate, promote, upstream, downstream, diligence
- `prodops/skills/references/engineering/` — prática de engenharia canônica do Framework
- `prodops/templates/` — templates canônicos
- `prodops/scripts/doctor.sh`, `prodops/scripts/validate-manifest.sh`, `prodops/scripts/validate-export-manifest.sh`

**O que é local do produto (nunca exportado):**
- `prodops/artifacts/` — OBCs, BDD, planos, trilhas, intents, evidências do produto
- `prodops/skills/local/` — Skills específicas desta API
- `prodops/skills/references/local/` — literatura e convenções locais do produto
- `prodops/scripts/local/` — automações locais do produto
- `prodops/exec/` — todo o espaço de execução operacional

O contrato declarativo de exportação está em: `prodops/exec/export-manifest.yaml`

---

## O que NÃO fazer durante esta fase

- **Não executar** `scripts/sync-framework-docs.sh` — desativado por guard explícito (ver inline no arquivo).
  O script está desabilitado porque referencia paths obsoletos e não respeita a fronteira declarativa de exportação.
- **Não alterar** `status: self` manualmente sem completar a transição descrita em `export-boundary.md`.
- **Não exportar** artefatos locais como se fossem canônicos.
- **Não tratar** exemplos de Payments como estrutura obrigatória do Framework.
- **Não reescrever** entradas históricas nos trails (append-only).

---

## Estado atual do conteúdo canônico

O conteúdo canônico em `prodops/framework/` foi generalizado e não contém mais
referências estruturais ao domínio de Payments. Exemplos pedagógicos de produto foram
substituídos por placeholders genéricos (`feature-name-v2`, `product-a`, `<entity>.*`).

Os runbooks de produto foram movidos para `prodops/artifacts/runbooks/`.

O trail de discovery em `prodops/framework/journeys/discovery/upstream-trail.md` contém
uma seção `# History` marcada como registro empírico — preserve como append-only.

---

## Transição futura

Quando o `prodops-framework` estiver pronto para receber o conteúdo reconciliado:

1. Exportar o conteúdo canônico conforme `prodops/exec/export-manifest.yaml`.
2. Publicar versão inicial com tag e LICENSE no `prodops-framework`.
3. Atualizar `prodops/exec/framework-lock.yaml`:
   - `status: self` → `status: consumer`
   - Preencher `external_source`, `synchronization_mechanism`, `version`
4. Alinhar `scripts/sync-framework-docs.sh` com `export-manifest.yaml` antes de qualquer uso.
5. Executar `prodops/scripts/doctor.sh` — deve continuar passando.
6. As áreas locais (`artifacts/`, `skills/local/`, etc.) continuam intactas.

---

## Referências

- Contrato de exportação: `prodops/exec/export-manifest.yaml`
- Documentação da fronteira: `prodops/exec/export-boundary.md`
- Lock de distribuição: `prodops/exec/framework-lock.yaml`
- Paths canônicos: `prodops/framework/canonical-paths.md`
