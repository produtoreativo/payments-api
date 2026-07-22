# Registro de Oportunidades — Premortem Payments

> Baseado no documento de Premortem da release de Payments.

## Objetivo

Consolidar as oportunidades identificadas durante o Premortem para que possam ser incorporadas ao Reliability Plan, ao Roadmap e aos OBCs da release.

---

# Glory 2 — Integração do APM com a ferramenta de ITSM

## Descrição

Integrar a plataforma de observabilidade (DataDog/APM) ao processo corporativo de ITSM, permitindo relacionar incidentes, CIs, CMDB e evidências operacionais.

## Benefícios Esperados

- Redução do MTTR
- Melhor rastreabilidade de incidentes
- Correlação entre alertas e ativos
- Maior eficiência operacional

## Próximas ações

- Integrar DataDog ao ITSM
- Mapear CIs do domínio Payments
- Automatizar abertura de incidentes

---

# Glory 3 — Revisão das Tags de Observabilidade

## Descrição

Reavaliar a estratégia de tags considerando o desacoplamento do monólito em microserviços.

## Benefícios Esperados

- Dashboards por serviço
- Ownership claro
- Consultas mais eficientes
- Métricas padronizadas

## Próximas ações

- Definir padrão de tags
- Atualizar instrumentação
- Revisar dashboards

---

# Glory 9 — Monitoramento do Carrinho

## Descrição

Instrumentar o fluxo do carrinho utilizando DataDog para acompanhar a jornada completa do cliente até a confirmação do pagamento.

## Benefícios Esperados

- Visibilidade ponta a ponta
- Detecção precoce de degradações
- Melhor experiência do cliente
- KPIs de conversão

## Próximas ações

- Instrumentar Checkout
- Instrumentar Payments
- Correlacionar traces distribuídos
- Criar dashboards executivos

---

# Oportunidades Estratégicas Derivadas

Além das oportunidades registradas no documento, o contexto da release evidencia iniciativas que podem aumentar a maturidade operacional:

- Padronizar instrumentação com OpenTelemetry.
- Evoluir contratos observáveis (OBCs) para todas as capabilities críticas.
- Definir OpenSLOs para pagamentos.
- Automatizar Quality Gates de observabilidade.
- Consolidar o Release Trail como evidência da execução.
- Evoluir o Operational Trail para aprendizado contínuo.

---

# Recomendações para o Reliability Plan

## Curto prazo

- Implantar DataDog/APM
- Instrumentar Feature Flags
- Criar dashboards operacionais
- Integrar ITSM

## Médio prazo

- Traces distribuídos completos
- KPIs de negócio
- Alertas baseados em SLO
- Runbooks automatizados

## Longo prazo

- Observabilidade como requisito padrão dos OBCs
- Automação de RCAs
- Roadmap contínuo de confiabilidade
