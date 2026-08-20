# Experiment Upstream Trail — EXP-017

Referência: `prodops/artifacts/experiments/017-prodops-addon-model/experiment.md`

---

# History

## 2026-08-19 — Sessão inicial

### Activity

Experimento iniciado e Design Package completo produzido em sessão única.

### Summary

A sessão partiu da leitura completa do livro *Product Backlog Building* (Aguiar & Caroli, 2021) e da ontologia do ProdOps Framework. O objetivo era projetar um modelo de extensão baseado no Open/Closed Principle que permitisse ao Framework incorporar métodos externos sem modificar sua estrutura core.

O design produziu: (1) cinco Extension Points estáveis (EP-001 a EP-005) que funcionam como interfaces declaradas pelo Framework; (2) um contrato de Add-on (addon.yaml) que qualquer método externo deve satisfazer para se tornar plugável; (3) o mapeamento completo do PBB para conceitos ProdOps — Personas → OBC stakeholders, Funcionalidades → OBC capabilities, PBIs/Steps Map → BDD Features, COORG → Iteration Backlog; (4) a estrutura de arquivos para implementação em prodops-portfolio; (5) a alteração mínima necessária no ontology.md (seção Add-on, não-disruptiva).

Todas as cinco perguntas do experimento foram respondidas. Nenhuma questão aberta persiste. A hipótese foi confirmada: Extension Points estáveis permitem extensão sem modificação do core.

### Artifacts Updated

- `prodops/artifacts/experiments/017-prodops-addon-model/experiment.md` — criado (Design Package completo)
- `prodops/artifacts/experiments/017-prodops-addon-model/upstream-trail.md` — criado (este arquivo)
- `prodops/artifacts/product/backlogs/tracking-list.md` — sem novo item (Downstream direto)
- `prodops/framework/journeys/discovery/learnings.md` — atualizado com aprendizados EXP-017

### Evidence

- Leitura de PDF: *Product Backlog Building* (Aguiar & Caroli, 2021), páginas 1–100
- Leitura de: `prodops/framework/ontology.md`, `operating-model.md`, `phases.md`, `principles.md`, `framework-gaps.md`
- Leitura de: `prodops/artifacts/product/backlogs/tracking-list.md` (contexto de escopo)
- Design validado contra: nenhum conflito com ontologia existente identificado

### Decision

- [x] Pronto para Assessment → Mover para Downstream em prodops-portfolio

### Notes

A implementação Downstream deve abrir Work Item em prodops-portfolio, não em payments-api. O repositório payments-api será consumidor do Add-on PBB após a implementação. O Skill `/pbb` será distribuído via mecanismo `prodops-framework` (EXP — framework distribution, POPS-ICE-001) para todos os consumidores.

---

## 2026-08-20 — Pesquisa de melhores práticas da indústria

### Activity

Pesquisa comparativa de 10 sistemas de extensão maduros. Refinamento do design v1 → v2.

### Summary

Pesquisa cobrindo VS Code (contribution points + package.json), Eclipse (Extension Points XML + OSGi), Backstage (createExtensionPoint TypeScript), Babel (Visitor Pattern), ESLint (Plugin + Rule Model), Terraform (Provider gRPC Protocol), GitHub Actions (action.yml + Reusable Workflows), Gradle (Plugin interface + ExtensionContainer), Jenkins (ExtensionPoint Java + Descriptor), Webpack (Tapable hooks).

A análise identificou **6 invariantes** presentes em todos os sistemas bem-sucedidos. O design v1 do EXP-017 satisfazia parcialmente os invariantes 1, 3 e 4. A pesquisa revelou dois gaps: (a) ausência de **Two-Phase Initialization** — o modelo v1 não separava descoberta declarativa de ativação; (b) ausência de **namespace hierárquico** para Extension Points — os IDs eram simples (`EP-002`) em vez de namespaced (`prodops.inception.pre-icebox`). Ambos foram corrigidos no design v2.

O padrão de **Inversão de Controle** confirmou a diretriz de isolamento: o Add-on Skill nunca modifica artefatos do Framework core, apenas lê o que declara em `artifacts.consumes` e escreve o que declara em `artifacts.produces`.

O padrão de **Versionamento com range constraints** levou ao campo `compatibility.framework-version: ">=1.14.0"` em vez do campo `version` simples do design v1. O anti-padrão de versão exata foi explicitamente excluído do schema.

### Artifacts Updated

- `prodops/artifacts/experiments/017-prodops-addon-model/experiment.md` — design v2 com 6 invariantes, addon.yaml v2, Extension Points namespaced, Two-Phase Initialization
- `prodops/artifacts/experiments/017-prodops-addon-model/upstream-trail.md` — esta entrada

### Evidence

- 10 sistemas analisados: VS Code, Eclipse, Backstage, Babel, ESLint, Terraform, GitHub Actions, Gradle, Jenkins, Webpack
- Fontes: documentações oficiais, Babel Plugin Handbook, Eclipse Architecture (AOSA book), Backstage Backend System docs
- 6 invariantes identificados: Separação Contrato/Implementação, Registro Declarativo + Ativação Lazy, Inversão de Controle, Identidade Namespaced, Isolamento por API Surface, Versionamento como Contrato

### Decision

- [x] Continuar experimento → pronto para Assessment e Downstream

### Notes

O único invariante que o modelo ProdOps não implementa completamente é o **Invariante 5 — Isolamento Físico** (processo separado, como Terraform ou Backstage backend). Para o contexto atual (agentes LLM lendo arquivos Markdown), isolamento por API surface é suficiente. Isolamento por processo seria relevante se Add-ons começassem a executar código de side effects significativos — candidato a evolução futura.
