---
id: EVD-YYYY-NNNN
type: "[Document|Log|Metric|Test Result|Command Output|API Response|Screenshot|Pull Request|Commit|Release|Dashboard|Approval|Decision Record|Conformance Report|Observation]"
description: "[descrição concisa da evidência — o que ela prova]"
source: "[origem: ferramenta, sistema, comando ou URL]"
collected_at: "YYYY-MM-DDTHH:MM:SS-03:00"
collected_by: "[papel/agente que coletou]"
subject: "[o que está sendo evidenciado — sujeito concreto]"
related_finding: []
related_check: ""
integrity: ""
valid_until: ""
location: "[path relativo, URI, ou comando reproduzível]"
---

<!-- → Modelo canônico: prodops/framework/journeys/diligence/model/evidence.md -->
<!-- → Instrução de uso: prodops/artifacts/diligence/README.md -->
<!-- ATENÇÃO: Este arquivo é imutável após criação. -->
<!-- Nova coleta deve criar novo EVD-YYYY-NNNN com novo ID. -->
<!-- NUNCA incluir segredos, credenciais ou dados sensíveis. Sanitizar quando necessário. -->

# Description

<!-- O que esta Evidence prova.
     Relação com o Finding ou Check que originou a coleta.
     Ex: "Prova que o campo 'owner' estava ausente no arquivo FND-2026-0002.md
          no momento da detecção pelo Check DIL-TRC-001 em 2026-07-23." -->

# Source

<!-- De onde veio este dado.
     Ferramenta, sistema, comando, URL de origem.
     Para Command Output: incluir o comando exato que foi executado.
     Para API Response: incluir o endpoint e método.
     Ex:
     - Ferramenta: GitHub CLI (gh)
     - Comando: gh issue view 89 --json body,labels
     - Executado em: 2026-07-23T14:30:00-03:00
     -->

# Content

<!-- O conteúdo da Evidence.
     
     Para Command Output, Log ou API Response extenso:
       Incluir o excerpt relevante aqui e referenciar arquivo completo em attachments/ se necessário.
     
     Para Document:
       Incluir o trecho relevante com contexto suficiente.
     
     Para Metric:
       Incluir o valor, unidade, período de coleta e sistema de observabilidade.
     
     Para Approval ou Decision Record:
       Incluir referência ao PR, reunião ou documento de aprovação.
     
     NUNCA incluir:
     - Senhas, tokens, chaves API
     - Credenciais de qualquer tipo
     - Dados sensíveis de usuários
     - PII (Personally Identifiable Information)
     
     Substituir valores sensíveis por [REDACTED] e documentar que sanitização foi aplicada. -->

# Integrity

<!-- Hash, assinatura ou mecanismo de verificação quando aplicável.
     Ex:
     - SHA-256 do arquivo capturado: abc123...
     - Verificação: git log --format="%H" -- path/to/file (confirma estado no commit)
     
     Para Evidence sem mecanismo de verificação formal: documentar limitação. -->

# Validity

<!-- Período de validade desta Evidence.
     Se a Evidence é ponto-no-tempo (ex: output de comando): documentar quando foi coletada.
     Se a Evidence pode expirar (ex: métrica, certificado, aprovação): documentar valid_until.
     Se não há data de expiração: justificar por que a Evidence é válida indefinidamente.
     
     Ex:
     - Coletada em: 2026-07-23T14:30:00-03:00
     - Válida até: não expira (snapshot imutável do estado no momento da detecção)
     
     Ou:
     - Coletada em: 2026-07-23T14:30:00-03:00
     - Válida até: 2026-08-23 (métrica de SLO com janela de 30 dias) -->
