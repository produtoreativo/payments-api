# Diligence Capabilities

Capabilities são competências reutilizáveis consumidas pelos ciclos da Diligence. Definem **o que é feito**, não quando nem por quem.

→ Ver [ontology.md](../../../ontology.md) para a definição canônica de Capability e suas famílias (Delivery, Diligence, Product).

| Capability | Propósito | Consumida por |
|---|---|---|
| Backlog Synchronization | Manter o estado do OBC consistente entre todos os níveis da hierarquia de backlogs | Capture, Promote, Repair |
| Work Item Management | Criar, atualizar e fechar Work Items referenciando OBCs, operações e jornadas corretamente | Attach, Close, Repair |
| Readiness Verification | Verificar pré-requisitos de Downstream antes que um item entre em Delivery | Promote, Scan |
| Divergence Detection | Identificar proativamente gaps entre artefatos canônicos e ferramentas externas | Scan, Flag |
| Artifact Evolution | Atualizar artefatos de gestão (Iteration Plan, Roadmap, Premortem) quando decisões mudam o estado do trabalho | Capture, Repair, Close |
| [Workspace Reconciliation](../workspace-reconciliation.md) | Alinhar GitHub Workspace (Labels, Fields, Views, Projetos) à Canonical Specification. Detecta Workspace Drift via Inspect e corrige via Reconcile. Produz Conformance Report via Verify. | Bootstrap, Diligence Async, Diligence Sync, usuário direto |
