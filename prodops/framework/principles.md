# ProdOps Principles

## 1. Business intent drives technology
Toda ação técnica deve ter uma intenção de negócio rastreável. Tecnologia sem intent não tem direção; intent sem tecnologia não tem resultado. O OBC é o contrato que torna essa relação verificável — ele não é um requisito técnico, é o acordo entre negócio e tecnologia com critérios observáveis em produção. Nenhum trabalho de implementação começa sem que o intent de negócio esteja identificado, compreendido e formalizado. Ver [Origin Streams](origin-streams.md) para as quatro origens possíveis de um Business Intent.

## 2. Flow over friction
Aceleração de entregas é consequência de eliminar fricção, não de aumentar pressão. Fricção surge de contexto ausente, contratos indefinidos, decisões não registradas e automação postergada. Quando o intent é claro, o contrato está definido e as práticas de engenharia estão no lugar, o fluxo é natural. A velocidade de entrega é um indicador de saúde do processo — não um objetivo em si.

## 3. Engineering before implementation
Observabilidade, estratégia de deploy e testes são definidos **antes** de escrever código de produção — nessa ordem de prioridade. Não são práticas adicionadas ao final da entrega; são pré-condições de design. Observabilidade vem primeiro: sem ela, não é possível saber se o comportamento implementado é o correto em produção. Deploy vem segundo: sem estratégia de entrega progressiva, o código não chega ao usuário com controle e segurança. Testes vêm terceiro: TDD é a prática, mas testes sem observabilidade e sem estratégia de deploy são verificação local incompleta. Um sistema que não pode ser observado, não pode ser entregue progressivamente ou não pode ser testado de forma independente não está pronto para ser implementado.

## 4. Product context first
Nenhuma mudança de código começa sem contexto compatível com o modo de execução. Upstream é permissivo, experimental e sem compromisso de entrega. Downstream é completo: antes de executar Delivery, exige todos os artefatos e gates de readiness definidos pelo Framework. Agentes não devem inventar contexto de negócio ausente.

## 5. Upstream before commitment
Upstream não é uma jornada: é o modo sem compromisso de entrega, no qual qualquer jornada pode operar com rigor experimental e maturidade variável. Código é descartável até ser promovido para Downstream. Downstream também pode executar qualquer jornada, mas aplica todos os quality gates vigentes. Ver `AGENTS.md` do repositório (Upstream Path).

## 6. Contracts before implementation
Identificar ou criar um contrato verificável (OpenAPI, AsyncAPI, BDD Feature, schema) antes de escrever código de produção. O contrato é a linguagem compartilhada entre teste e implementação.

## 7. Observability as a deliverable
Logs, erros, métricas e rastreabilidade fazem parte da implementação, não são complementos adicionados depois. Uma feature não está pronta se seu comportamento não puder ser observado em produção.

## 8. Evidence-based decisions
Toda decisão de entrega — promover, reverter, aceitar risco — deve ser respaldada por evidência registrada. Ver [release-trail](../artifacts/trails/release-trail.md) e [operation/](journeys/operation/).

## 9. Reliability is a first-class concern
Objetivos de confiabilidade são definidos antes da implementação, acompanhados via OBCs e SLOs, e validados antes da promoção. Ver [reliability-plans](../artifacts/plans/reliability/).

## 10. No shortcuts in production code
Código de produção não deve conter branches exclusivos de teste, hacks específicos de ambiente ou overrides ocultos que alteram o comportamento em teste. Modos de comportamento projetados (ex: mock de provedor externo) são exceções válidas desde que declarados explicitamente como feature intencional do produto — não como atalho de teste.

## 11. Automation First
Um agente deve sempre tentar executar uma ação ele mesmo antes de instruir um humano a fazê-la. Intervenção manual é último recurso (uma **Manual Exception** documentada), nunca o caminho padrão. Ordem canônica de tentativas: API → MCP → CLI → SDK → Browser Automation → Manual Exception apenas quando tudo mais falhar. Frases como "faça manualmente", "acesse a UI" ou "configure manualmente" são proibidas a menos que todas as opções de automação tenham sido demonstravelmente esgotadas e registradas em um Issue de rastreamento. Ver [automation-first.md](automation-first.md) para o fluxo de decisão completo.
