# EXP-013 — Iteration 7
## Operational Dashboard Closure

### Contexto

O EXP-013 ainda não está encerrado.

As Iterações 1 a 6 provaram que o Runtime consegue emitir CloudEvents, manter Timelines isoladas, calcular Derived State, sincronizar o GitHub Project e publicar métricas no Datadog.

Porém, permanece um gap obrigatório:

> O experimento só será considerado concluído quando o fluxo operacional puder ser visualizado diretamente no GitHub Project e em uma Dashboard Datadog criada e validada no ambiente real.

Esta iteração deve eliminar esse gap.

---

## Objetivo

Usar as credenciais existentes no `.env` do repositório para:

1. validar o estado operacional no GitHub Project;
2. criar ou atualizar programaticamente a Dashboard Datadog;
3. executar um fluxo operacional real;
4. confirmar visualmente que GitHub e Datadog refletem o mesmo fluxo;
5. coletar evidências suficientes para encerrar formalmente o EXP-013.

Não considerar o experimento concluído enquanto a Dashboard não estiver criada, acessível e exibindo o fluxo operacional executado.

---

## Princípios

- Ler o estado atual completo do EXP-013 antes de alterar qualquer arquivo.
- Ler o `.env` local somente durante a execução.
- Nunca imprimir, registrar, versionar ou incluir credenciais em relatórios.
- Nunca copiar valores sensíveis para arquivos do repositório.
- Utilizar as credenciais apenas para GitHub, Datadog e AWS staging conforme necessário.
- Manter CloudEvents 1.0 como contrato oficial.
- Não criar nova arquitetura.
- Implementar apenas o necessário para fechar o gap de observabilidade.

---

## Phase 1 — Environment and Credential Validation

Localizar e carregar o `.env` utilizado atualmente pelo Runtime.

Validar, sem exibir valores:

### GitHub

- `gh auth status`
- acesso ao owner configurado;
- acesso ao repositório;
- acesso ao GitHub Project #25;
- permissão para ler Issues e campos;
- permissão para atualizar Project Items.

### Datadog

Validar a presença e funcionamento de:

- `DD_API_KEY`
- `DD_APP_KEY`
- Datadog site/região configurada;
- permissão para publicar métricas;
- permissão para criar, ler e atualizar dashboards.

Fazer uma chamada autenticada de leitura à API do Datadog para confirmar que a Application Key funciona.

### AWS Staging

Validar, sem modificar infraestrutura:

- credenciais AWS disponíveis;
- identidade atual via `aws sts get-caller-identity`;
- região configurada;
- acesso ao ambiente de staging necessário para a execução do fluxo operacional.

Se AWS não for necessária para executar o fluxo escolhido, registrar isso explicitamente e não criar recursos apenas para utilizá-la.

### Runtime Doctor

Atualizar o `runtime-doctor.sh` somente se necessário para validar:

- GitHub read/write;
- Datadog metric write;
- Datadog dashboard read/write;
- AWS identity e região;
- `.env` carregado sem exposição de segredos.

Qualquer falha obrigatória deve interromper a execução.

---

## Phase 2 — Dashboard Datadog Real

Utilizar a definição já existente em:

`prodops/artifacts/runtime/datadog-dashboard-definition.json`

Revisar a definição antes da criação.

Criar ou atualizar programaticamente uma Dashboard no Datadog.

### Nome sugerido

`ProdOps Runtime — EXP-013 Operational Flow`

### Requisitos mínimos

A Dashboard deve permitir acompanhar o fluxo por:

- Issue;
- runtime-correlation-id;
- estado;
- CloudEvent type;
- ambiente;
- serviço.

### Widgets obrigatórios

1. **Operational Snapshot**
   - estado mais recente por Issue;
   - Issues #76, #77 e #78.

2. **Event Timeline**
   - eventos ao longo do tempo;
   - agrupamento por CloudEvent type.

3. **State Transitions**
   - transições de estado por Feature.

4. **Event Count**
   - total de eventos por Issue.

5. **Correlation Trace**
   - filtro por `runtime-correlation-id`.

6. **Environment and Service**
   - filtros por `env` e `service`.

A Dashboard deve ser criada via API usando `DD_API_KEY` e `DD_APP_KEY`.

Salvar no repositório apenas:

- dashboard ID;
- dashboard URL;
- definição JSON sem segredos;
- log sanitizado da operação.

Não salvar credenciais.

---

## Phase 3 — GitHub Project Operational Views

Ler o estado atual do GitHub Project #25 e das Views existentes.

Não presumir que as Views estão corretas apenas porque os campos foram atualizados.

Validar que as Issues aparecem nas Views adequadas conforme o estado operacional:

- #76 em DONE;
- #77 em VALIDATING;
- #78 em HACKING.

Validar pelo menos:

- presença da Issue no Project;
- `oem-state`;
- `oem-last-event`;
- coerência do agrupamento ou filtro da View;
- ausência de duplicação de Project Item.

Caso alguma View existente não reflita os estados corretamente:

- corrigir somente filtros, agrupamentos ou campos necessários;
- não criar uma nova taxonomia;
- não alterar o modelo canônico do Runtime.

Registrar a configuração final das Views.

---

## Phase 4 — Real Operational Flow

Executar novamente um cenário operacional visível.

Preferir o cenário não uniforme já validado:

- #76 → DONE;
- #77 → VALIDATING;
- #78 → HACKING.

Gerar novos `runtime-correlation-id` para esta execução final.

Durante a execução, confirmar:

- CloudEvents validados;
- Timelines atualizadas;
- Derived States calculados;
- GitHub Project sincronizado;
- métricas recebidas no Datadog;
- Dashboard refletindo a execução.

Não considerar HTTP 202 isoladamente como evidência suficiente.

Após o envio, consultar a API do Datadog e confirmar que as métricas estão disponíveis para os correlation IDs da execução.

---

## Phase 5 — Visual Validation

Esta fase é obrigatória.

Abrir e verificar visualmente:

### GitHub Project

- Issues #76, #77 e #78;
- estados distintos;
- Views adequadas;
- campos atualizados.

### Datadog

- Dashboard criada;
- widgets carregando dados;
- filtros funcionando;
- fluxo operacional visível;
- eventos separados por Issue;
- rastreabilidade por correlation ID.

Se houver acesso a browser ou ferramenta de captura:

- gerar screenshots;
- armazenar em `evidence/screenshots/`.

Se a captura automática não for possível:

- fornecer as URLs diretas;
- registrar os valores esperados em cada widget;
- não declarar conclusão até que a visualização seja conferida.

---

## Evidências obrigatórias

Criar ou atualizar:

- `evidence/iteration-7-operational-dashboard-closure.md`
- `evidence/datadog-dashboard.md`
- `evidence/github-project-validation.md`
- `evidence/final-operational-run.md`
- `evidence/screenshots/` quando possível
- dashboard definition JSON
- logs sanitizados de criação e consulta
- snapshot dos estados finais das Issues
- correlation IDs da execução final

O relatório não pode conter API Keys, tokens, secrets ou conteúdo do `.env`.

---

## Critérios de sucesso

A Iteration 7 somente está concluída quando todos forem verdadeiros:

- [ ] `.env` carregado com segurança.
- [ ] GitHub autenticado com leitura e escrita no Project #25.
- [ ] `DD_API_KEY` validada.
- [ ] `DD_APP_KEY` validada.
- [ ] Dashboard Datadog criada ou atualizada via API.
- [ ] Dashboard acessível por URL.
- [ ] Widgets exibindo dados reais do Runtime.
- [ ] Filtros por Issue e correlation ID funcionando.
- [ ] GitHub Project exibindo #76, #77 e #78 nos estados corretos.
- [ ] Views do GitHub coerentes com os estados.
- [ ] Execução operacional final refletida tanto no GitHub quanto no Datadog.
- [ ] Evidências visuais ou validação manual registrada.
- [ ] Nenhuma credencial exposta.
- [ ] Discovery Report atualizado com o resultado final.
- [ ] EXP-013 marcado como Completed somente após a validação visual.

---

## Critérios de não conclusão

Não encerrar o experimento se ocorrer qualquer um destes casos:

- Dashboard apenas definida em JSON, mas não criada.
- Métricas enviadas com HTTP 202, mas não consultadas ou visualizadas.
- `DD_APP_KEY` ausente ou inválida.
- Dashboard criada sem dados.
- GitHub Project atualizado, mas Views não verificadas.
- Screenshots ou validação visual ainda pendentes.
- Credenciais necessárias não funcionarem.
- Fluxo operacional não aparecer simultaneamente no GitHub e no Datadog.

Nesses casos, registrar o bloqueio e manter o EXP-013 como In Progress.

---

## Restrições

Não implementar:

- Rework;
- Blocking;
- Lookback;
- Replay;
- Diligence;
- State Machine;
- Webhooks;
- GitHub Actions;
- EventBridge;
- Kafka;
- SNS;
- SQS;
- nova infraestrutura permanente na AWS;
- refatorações não relacionadas ao gap.

---

## Relatório final

O relatório deve responder objetivamente:

1. A Dashboard Datadog foi criada?
2. Qual é a URL?
3. Os dados reais da execução aparecem?
4. Quais correlation IDs foram validados?
5. O GitHub Project mostra os mesmos estados?
6. As Views refletem corretamente cada Feature?
7. Houve algum ajuste operacional?
8. Algum gap estrutural do Framework foi encontrado?
9. O EXP-013 pode finalmente ser marcado como Completed?

Somente marcar o EXP-013 como concluído se a resposta for positiva e baseada em evidências visuais para GitHub e Datadog.

Pare imediatamente após o fechamento formal do experimento.
