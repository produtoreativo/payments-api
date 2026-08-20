# Learnings

Registrar aqui aprendizados reutilizáveis de experimentos, spikes, protótipos e validação exploratória.

Não transformar aprendizados em compromissos de entrega até que sejam aceitos no Downstream.

## Credit Card Asaas Lifecycle

O suporte a cartão de crédito é viável com o shape atual do gateway Payments, mas não deve avançar para Downstream como uma simples extensão de `billingType: CREDIT_CARD`.

Aprendizados principais:

- O checkout hospedado na Asaas e o checkout transparente são contratos de produto e segurança distintos.
- A captura direta de cartão exige campos e decisões não presentes no DTO atual: `creditCard`, `creditCardHolderInfo`, `creditCardToken`, `authorizeOnly`, parcelas e `remoteIp`.
- O processamento imediato do cartão pode recusar a autorização antes de persistir uma cobrança, portanto o modelo de estado da invoice e o comportamento de idempotência devem ser explícitos.
- Eventos de cartão da Asaas — como análise de risco, autorização, recusa de captura, confirmação, recebimento, exclusão e reembolso — precisam de mapeamento explícito de BDD e observabilidade.
- Excluir uma cobrança não paga não equivale a reembolsar uma cobrança de cartão já paga.

Candidato a Downstream apenas após o próximo experimento definir o modelo de captura e produzir atualizações de OBC, BDD, DTO, observabilidade e Reliability Plan.

## Hosted vs Tokenized Credit Card

A comparação focada favorece o checkout hospedado da Asaas como primeiro slice Downstream.

Aprendizado validado:

- O checkout hospedado pode reutilizar o shape atual de `POST /invoices`, pois a Asaas consegue criar um pagamento `CREDIT_CARD` sem campos de cartão e retornar uma `invoiceUrl` para conclusão pelo pagador.
- O pagamento com cartão tokenizado é viável, mas não é apenas uma opção de UI. Exige `creditCardToken`, `remoteIp`, timeout explícito, mapeamento de recusa, mapeamento de análise de risco e regras de armazenamento/segurança para propriedade do token.
- A captura direta de dados brutos de cartão deve ficar fora do primeiro slice Downstream, salvo se a Magazine Siará aceitar explicitamente as obrigações de PCI/segurança e antifraude.
- O Validation Workbench agora expõe o shape proposto do payload tokenizado e os eventos de webhook específicos de cartão para exploração funcional.
- A capability está quase pronta para Downstream como checkout hospedado, mas o pagamento tokenizado ainda precisa de aprovação de produto e segurança antes da entrega.

## Saved Cards and Tokenization Boundary

O suporte a cartões salvos é um contrato de propriedade do Payments, não apenas uma escolha de UI do Checkout.

Aprendizado reutilizável:

- O Cart/Checkout deve listar e selecionar cartões por meio de valores `cardId` de propriedade do Payments. Não deve receber nem armazenar o `creditCardToken` do provedor.
- O Payments pode persistir metadados de exibição seguros do cartão — bandeira, últimos 4 dígitos, vencimento, titular, provedor e status —, mas não deve persistir número completo do cartão, CVV ou payload bruto de `creditCard`.
- O token de cartão do provedor deve ser tratado como material sensível e suprimido de logs, traces, analytics, payloads de erro e mensagens dead-letter.
- O cadastro de novo cartão amplia o escopo PCI/segurança mesmo quando os dados brutos do cartão são apenas transitórios, pois `creditCard` e `creditCardHolderInfo` cruzam o limite da Payments API.
- `remoteIp` pertence ao contexto do pagador e deve ser fornecido pelo Cart/Checkout; usar o IP do servidor Payments enfraquece a evidência de antifraude.
- O checkout hospedado ainda pode avançar primeiro, mas a reutilização de cartões salvos e o cadastro de novo cartão precisam de decisões de Segurança, Arquitetura e Produto antes do Downstream.

## Checkout Gateway Feature Flag Readiness

A incerteza de maior prioridade no contexto atual do produto não é um endpoint da Payments API. É saber se o Checkout consegue habilitar o novo gateway com segurança por meio de Feature Flag com rollout, auditabilidade e evidência de rollback.

Aprendizado reutilizável:

- Uma release pode ter uma Payments API funcional e ainda assim não entregar valor se o flag de roteamento do Checkout não puder ser ativado com segurança.
- A prontidão da Feature Flag é um contrato cross-system entre Checkout, Payments e operações.
- O Rollback deve definir o que acontece com os pedidos já iniciados no Payments; simplesmente desligar o novo tráfego não é suficiente.
- O repositório pode comprovar idempotência do lado Payments, correlação e comportamento de webhook, mas não pode comprovar targeting ou rollback do Checkout sem evidência externa.

## Datadog Native AWS Instrumentation

A Payments API pode manter a instrumentação Datadog sem depender do Serverless Framework.

Aprendizado reutilizável:

- `dd-trace` e o módulo de observabilidade existente são concerns da aplicação; não exigem `serverless-plugin-datadog`.
- O deploy AWS deve anexar o Datadog Lambda Extension por meio de parâmetros SAM, com a API key injetada pelo pipeline de deploy.
- A validação funcional local deve usar o sandbox NestJS com mocks e armazenamento em memória; a validação Lambda/Localstack é um caminho de infraestrutura separado, não o loop de desenvolvimento padrão.
- A decisão de deploy remanescente é externa ao repositório: os responsáveis pelo pipeline devem fornecer o ARN/versão correto do Datadog Extension Layer por região AWS.
- Lambda Function URL é suficiente para esta API de laboratório e evita o custo do API Gateway.
- O modo de capacidade provisionada do DynamoDB pode manter o modelo atual de tabelas/índices dentro do envelope Free Tier clássico de 25 RCU / 25 WCU, atribuindo 1 RCU e 1 WCU a cada tabela e GSI.
- Remover permissões do CloudWatch Logs evita cobranças de ingestão/armazenamento de logs, ao custo de perder logs de aplicação no lado AWS para troubleshooting.

## ProdOps Add-on Model — Open/Closed Principle (EXP-017)

O Framework ProdOps pode ser estendido com métodos externos sem modificar sua ontologia core.

Aprendizados principais:

- **Extension Points como interfaces estáveis:** declarar EP-001 a EP-005 (discovery.methods, inception.pre-icebox, backlog.prioritization, artifacts.obc.sections, bdd.story-generation) permite que qualquer método externo se plugue ao Framework com contrato explícito — sem tocar em Journey, Cycle, Phase, Capability, Skill ou Step existentes.
- **addon.yaml como contrato declarativo:** cada Add-on declara o que consome (artefatos ProdOps), o que produz (artefatos novos), em quais Extension Points atua e quais gates de entrada/saída satisfaz. Esse contrato é suficiente para um agente invocar o Add-on no momento certo do lifecycle.
- **PBB mapeia limpo para ProdOps:** Personas → OBC stakeholders, Funcionalidades → OBC capabilities, Steps Map (ARO) → BDD Feature steps, COORG → Iteration Backlog prioritization. Nenhum conceito PBB conflita com a ontologia existente.
- **O ponto de hook natural do PBB é EP-002 (inception.pre-icebox):** a sessão PBB ocorre após OBC Draft entrar no Product Backlog e antes do refinamento no Icebox. Ela enriquece o OBC com Personas e Funcionalidades e produz os BDD Features iniciais.
- **Habilitadores PBB → Upstream ProdOps:** Habilitador exploratório do PBB é exatamente um Upstream Spike; Habilitador técnico é um non-functional PBI ou Reliability Plan item. Nenhum conceito novo é necessário.
- **Add-on é camada de implementação, não estrutural:** como Skill e Step, Add-on é uma convenção de implementação — não altera o eixo Journey → Cycle → Phase. O ontology.md recebe apenas uma seção descritiva mínima.
- **Implementação pertence ao prodops-portfolio:** o repositório payments-api é consumidor futuro do Add-on PBB, não o local de implementação. A distribuição acontece via mecanismo prodops-framework (POPS-ICE-001).

Candidato a Downstream em prodops-portfolio imediatamente — sem bloqueadores.

### 6 Invariantes da Indústria — Sistemas de Extensão Maduros (EXP-017 pesquisa)

Pesquisa comparativa de 10 sistemas (VS Code, Eclipse, Backstage, Babel, ESLint, Terraform, GitHub Actions, Gradle, Jenkins, Webpack) identificou 6 invariantes presentes em todos os sistemas bem-sucedidos:

1. **Separação entre Contrato e Implementação:** o Framework declara apenas a interface (Extension Point); o Add-on fornece a implementação. Nunca misturar — Extension Point sem implementação acoplada é o padrão correto.

2. **Registro Declarativo + Ativação Lazy:** Add-ons registram metadados em tempo de descoberta (parse do addon.yaml); código só executa quando o hook point é atingido no lifecycle. Dois problemas resolvidos: startup lento e acoplamento de inicialização.

3. **Inversão de Controle:** o Framework sempre chama o Add-on; o Add-on nunca chama o Framework diretamente nem modifica artefatos core. Add-on recebe o que declarou em `artifacts.consumes` e escreve apenas em `artifacts.produces`.

4. **Identidade Única com Namespace Hierárquico:** Extension Point IDs usam notação de ponto hierárquica (`prodops.inception.pre-icebox`), não IDs simples (`EP-002`). Evita colisões entre Add-ons e torna a origem legível sem consultar documentação adicional.

5. **Isolamento por API Surface:** Add-on não acessa o sistema de arquivos do Framework além do que declarou. Para o contexto ProdOps (agentes LLM + arquivos Markdown), isolamento por API surface é suficiente — isolamento por processo (Terraform/Backstage) só é necessário com Add-ons que executam side effects externos.

6. **Versionamento como Contrato de Primeira Classe:** compatibilidade usa range constraints (`">=1.14.0"`), não versão exata. Versão exata é anti-padrão: quebra automaticamente em cada patch do Framework. Range constraint permite que Add-on continue funcionando em minor/patch versions sem alteração.
