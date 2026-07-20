# Definition of Done

Uma implementação está pronta quando todos os itens abaixo são verdadeiros:

## Comportamento

- [ ] O comportamento esperado está coberto por um teste que estava vermelho antes da implementação.
- [ ] O teste verifica comportamento na fronteira HTTP ou de evento (não implementação interna).
- [ ] Testes de integração e aceitação relevantes passam.
- [ ] Nenhum mock substitui serviços próprios ou regras de negócio.

## Contratos

- [ ] A BDD Feature para este comportamento reflete o contrato implementado.
- [ ] A spec OpenAPI ou AsyncAPI está atualizada se uma rota ou evento foi adicionado, alterado ou removido.
- [ ] Os critérios de aceite do OBC estão satisfeitos pelas evidências.

## Qualidade de código

- [ ] Nenhum branch exclusivo de teste existe no código de produção.
- [ ] Formatter executado (`npm run lint` com `--fix` aplicado).
- [ ] Lint passa (`npm run lint` exit 0 em `api/`).
- [ ] Build passa.
- [ ] Nenhum erro TypeScript novo introduzido.
- [ ] Commits seguem Conventional Commits (`<type>(<scope>): <summary>`).

## Observabilidade

- [ ] Comportamento observável definido antes de implementar (qual log, qual métrica, qual correlationId).
- [ ] Logs relevantes são emitidos com estrutura correta (correlationId, tenantId).
- [ ] Respostas de erro têm mensagens significativas.
- [ ] Nenhum secret ou PII aparece nos logs.

## Confiabilidade

- [ ] Timeout configurado para chamadas ao provedor externo.
- [ ] Idempotência verificada: mesma operação repetida retorna o mesmo estado.
- [ ] Exceções do provedor produzem resposta HTTP com `message` significativa.
- [ ] Degradação controlada: falha de dependência externa não derruba o sistema.
- [ ] Códigos HTTP correspondem ao comportamento semântico (201, 400, 404, 409).

## Arquitetura

- [ ] Diagrama de arquitetura atualizado se a mudança foi estrutural (novo módulo, rota, tabela, tópico de evento).
- [ ] Event Storming atualizado se eventos foram adicionados, removidos ou renomeados.

## Evidência

- [ ] Evidência acrescentada no trail da sessão ativa em `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md` (Downstream) ou no trail do experimento (Upstream).
- [ ] Evidência inclui: saída dos testes, saída do lint e resumo do que mudou.

## Pronto para Sync + Finish

- [ ] Todos os itens acima estão marcados.
- [ ] A mudança está pronta para entrar no [Finish](../../journeys/delivery/phases/finish/README.md).
