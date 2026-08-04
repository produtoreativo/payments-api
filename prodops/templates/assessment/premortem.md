# Premortem — [Nome da Funcionalidade ou Release]

<!--
  QUANDO USAR
  -----------
  Antes de iniciar uma sprint ou release com risco real de falha:
  movimentação financeira, integração externa, mudança de SLO, dados
  sensíveis, alta criticidade operacional ou dependência entre times.

  O premortem não é checklist de deploy. É um exercício de imaginação
  controlada: projete o futuro onde a entrega falhou e trabalhe de trás
  para frente para entender por quê — antes que aconteça.

  LOCALIZAÇÃO
  -----------
  prodops/artifacts/plans/reliability/premortem.md

  RELAÇÃO COM OUTROS ARTEFATOS
  ----------------------------
  - OBC: o premortem não substitui o OBC, complementa com análise de falha
  - Reliability Plan: usa os cenários do premortem como entrada de risco
  - Postmortem: após incidentes reais, compare com o premortem — o que acertamos?
  - Iteration Plan: o escopo analisado aqui deve corresponder às funcionalidades "Entrou"
-->

> [Uma frase descrevendo o objetivo deste premortem — o que está sendo entregue e por que o exercício foi feito agora]

---

## 1. Contexto executivo

<!--
  Explique o estado atual do produto/sistema que vai ser modificado.
  Responda: de onde partimos? Qual é a situação técnica e de negócio
  que torna essa entrega arriscada?

  Inclua:
  - O que já existe e funciona
  - O que está quebrado ou bloqueado (bugs, flags, dívida técnica)
  - Dependências externas ou entre times
  - Histórico relevante de incidentes ou aprendizados anteriores
  - Por que esta sprint/release importa agora
-->

[Descreva o contexto do produto, time e entrega. Inclua o estado atual dos sistemas envolvidos, dependências críticas, bugs conhecidos e motivação do trabalho.]

---

## 2. Premissa do premortem

<!--
  Declare explicitamente o cenário imaginado de falha.
  Use sempre a mesma forma: "Estamos no fim de [período] e a entrega falhou."
  Isso cria o ponto de partida mental do exercício.

  Especifique o que "falhou" significa para esta entrega:
  - A funcionalidade não foi habilitada em produção?
  - Houve rollback?
  - Clientes foram impactados?
  - SLO foi violado?
-->

Estamos no fim de [período — ex: sprint de 15 dias, semana de go-live] e a entrega falhou ou precisou ser revertida. [Descreva o que a falha significa para esta entrega específica: o que não funcionou, quem foi impactado, qual era o estado esperado que não foi alcançado.]

Este documento responde: o que provavelmente aconteceu, quais sinais teriam aparecido antes e quais ações reduzem a chance de falha.

---

## 3. Resultado esperado da entrega

<!--
  Liste os resultados observáveis que definem sucesso — não tarefas,
  mas outcomes. "Checkout integrado" é melhor que "endpoint criado".

  Cada resultado deve ser verificável: alguém consegue confirmar
  se foi alcançado sem abrir o código?
-->

| Resultado | Descrição |
|---|---|
| [Nome do resultado 1] | [O que significa ter alcançado esse resultado — comportamento observável] |
| [Nome do resultado 2] | [idem] |
| [Nome do resultado 3] | [idem] |

---

## 4. Hipóteses críticas

<!--
  Liste as premissas que precisam ser verdadeiras para a entrega funcionar.
  Para cada uma: o que acontece se for falsa? Como validar antes de ir a produção?

  Hipóteses críticas são diferentes de riscos: são afirmações que você está
  assumindo como verdadeiras sem ter provado ainda. Se uma delas for falsa,
  a entrega falha de forma não óbvia.

  Exemplos de padrões comuns:
  - "O contrato entre serviço A e B cobre todos os casos"
  - "A Feature Flag isola o novo comportamento completamente"
  - "O volume esperado está dentro da capacidade do sistema"
  - "O serviço dependente X está disponível e estável"
-->

| Hipótese | Risco se for falsa | Como validar antes do go-live |
|---|---|---|
| [Afirmação que você está assumindo como verdadeira] | [O que quebra se ela for falsa] | [Como provar que é verdadeira antes de ir a produção] |

---

## 5. Cenários de falha prováveis

<!--
  Para cada cenário: imagine que a falha JÁ aconteceu. Descreva:
  - O que o time/cliente observa (o sintoma, não a causa)
  - O que provavelmente causou (a causa raiz, não o sintoma)
  - O impacto real para o negócio/cliente
  - Quais sinais apareceriam ANTES ou DURANTE — no monitoring, logs, chamados
  - O que reduz a probabilidade ou o impacto

  IDs no formato [PREFIXO]-PRE-NNN para rastreabilidade.
  Use prefixo que identifique o domínio (ex: PMT para Payments, CHK para Checkout).

  Ordene do mais crítico para o menos crítico (P0 antes de P2).
-->

| ID | Falha imaginada | Causa provável | Impacto | Sinais antecipados | Ação preventiva |
|---|---|---|---|---|---|
| [PRE-001] | [O que o time ou cliente observa quando a falha acontece] | [Por que isso provavelmente aconteceria — causa técnica ou de processo] | [Quem é afetado e como — cliente, operação, negócio] | [Métricas, logs, alertas ou comportamentos que aparecem antes ou durante] | [O que fazer agora para reduzir chance ou impacto] |

---

## 6. Perguntas que precisam de resposta antes de começar

<!--
  Liste dúvidas concretas que bloqueiam decisões de engenharia ou de produto.
  Não são riscos — são lacunas de conhecimento que precisam ser preenchidas
  antes que o trabalho comece (ou antes do go-live).

  Para cada pergunta: por que ela importa? Quem tem a resposta?
  Se ninguém souber a resposta, é um risco maior do que parece.
-->

| Pergunta | Por que importa | Dono sugerido |
|---|---|---|
| [Dúvida concreta que precisa de resposta] | [O que fica em aberto se não for respondida] | [Time ou papel responsável pela resposta] |

---

## 7. Readiness checklist

<!--
  Critérios mínimos para habilitar a funcionalidade em produção.
  Não é uma lista de tarefas da sprint — é o gate de go-live.

  Cada linha deve ter um critério verificável e um responsável.
  Status: Aberto | Em andamento | Fechado — [justificativa ou referência]

  Áreas comuns: Produto, Contratos, Idempotência, Observabilidade,
  Alertas, Operação/Runbook, Segurança, Persistência, CI/CD, Feature Flag.
-->

| Área | Critério mínimo antes de habilitar em produção | Status |
|---|---|---|
| Produto | [Jornada descrita com estados esperados e mensagens ao cliente] | Aberto |
| Contratos | [Contrato de API/evento documentado e versionado] | Aberto |
| Idempotência | [Operações críticas deduplicadas para retry e webhook duplicado] | Aberto |
| Observabilidade | [Dashboard com métricas de sucesso, erro e latência disponível] | Aberto |
| Alertas | [Alertas definidos para falhas críticas e SLO] | Aberto |
| Operação | [Runbook criado ou atualizado para modos de falha conhecidos] | Aberto |
| Feature Flag | [Rollout gradual, auditoria e rollback testados] | Aberto |
| Segurança | [Secrets e PII mascarados em logs; autorizações revisadas] | Aberto |
| [Área específica] | [Critério específico deste contexto] | Aberto |

---

## 8. Plano de redução de risco

<!--
  Ações concretas para reduzir os riscos identificados nos cenários.
  Não é o backlog da sprint — são as ações de mitigação que devem
  acontecer ANTES ou DURANTE a sprint para que o go-live seja seguro.

  Prioridades: P0 = bloqueia go-live | P1 = altamente recomendado | P2 = melhoria

  Cada ação deve ter um resultado esperado verificável e um dono.
-->

| Prioridade | Ação | Resultado esperado | Dono sugerido |
|---|---|---|---|
| P0 | [Ação que bloqueia o go-live se não for feita] | [Como saber que foi concluída com sucesso] | [Time ou papel] |
| P1 | [Ação altamente recomendada antes do go-live] | [Resultado esperado] | [Dono] |
| P2 | [Melhoria desejável, não bloqueante] | [Resultado esperado] | [Dono] |

---

## 9. Definition of Done ProdOps para esta entrega

<!--
  Critérios que cada história ou capability desta entrega deve atender
  para ser considerada concluída — além dos critérios funcionais.

  Adapte removendo linhas que não se aplicam ao contexto.
  Adicione critérios específicos do domínio (ex: compliance, LGPD, contratos financeiros).
-->

Uma história desta entrega só deve ser considerada concluída quando atender aos pontos abaixo, quando aplicável:

- [ ] Critérios funcionais implementados e testados
- [ ] Contrato de API ou evento documentado e versionado
- [ ] Modos de falha mapeados com resposta clara para os consumidores
- [ ] Idempotência validada para retry, timeout e webhook duplicado
- [ ] Logs estruturados com os identificadores de correlação definidos para este domínio
- [ ] Métricas de sucesso, erro e latência emitidas
- [ ] Evento canônico publicado uma única vez por transição relevante
- [ ] Dashboard ou query operacional disponível
- [ ] Runbook mínimo atualizado para falhas conhecidas
- [ ] [Critério específico do contexto]

---

## 10. Narrativa de alinhamento

<!--
  Texto em prosa para comunicar o essencial a stakeholders, PMs,
  tech leads e times adjacentes que não leram o restante do documento.

  Responda em 3-4 parágrafos:
  1. Qual é o contexto e o que está sendo entregue?
  2. Onde estão as fronteiras de responsabilidade e as dependências críticas?
  3. O que torna esta entrega arriscada e o que foi feito sobre isso?
  4. O que define sucesso — o que vai além de "endpoints entregues"?
-->

[Escreva a narrativa em linguagem acessível. Descreva o contexto, as fronteiras entre times, os riscos principais e o que define sucesso real para esta entrega — não apenas funcional, mas operacional e para o cliente.]
