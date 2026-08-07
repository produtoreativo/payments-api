# DORA Metrics — Modelo Estendido

O ProdOps adota um modelo DORA estendido de **7 métricas** que expande as 4 métricas originais do DORA Research Program com 3 extensões orientadas a produto e operação. Os pesos de cada métrica variam conforme o **estágio de produto**, refletindo o que importa mais em cada momento do ciclo de vida.

→ Ver [`product-stages.md`](product-stages.md) para a definição dos estágios.
→ Ver [`glossary.md`](glossary.md) para os termos canônicos.
→ Assessment na plataforma Certificare usa estas métricas como base de avaliação de maturidade.

---

## As 7 métricas

### DORA Core — as 4 originais

#### Lead Time for Change
**O que mede:** tempo entre um commit de código e ele estar em execução em produção.

**Por que importa:** quanto menor, mais rápido o time aprende e entrega valor. Nos estágios iniciais (PoC/MVP), velocidade de aprendizado é tudo.

**Como medir:** timestamp do commit → timestamp do primeiro evento de OBC após o deploy em produção.

**Gap atual:** requer integração CI/CD → plataforma de observabilidade.

---

#### Release Frequency
**O que mede:** frequência de deploys bem-sucedidos para produção.

**Por que importa:** times de alta performance deployam múltiplas vezes por dia. Nos estágios de aceleração (MVR/MVT), frequência alta é sinal de processo maduro.

**Como medir:** contagem de deploys por período no pipeline de CI/CD.

**Gap atual:** requer integração CI/CD → plataforma de observabilidade.

---

#### Change Fail Rate
**O que mede:** percentual de mudanças que causam falha ou degradação observável em produção.

**Por que importa:** nos estágios avançados (MVT/MLP), confiabilidade é inegociável. Alta taxa de falha pós-deploy indica falta de qualidade ou testes insuficientes.

**Como medir:** eventos de falha de OBC (`*_failed`, `*_rejected`, `*_refused`) correlacionados com deploys nos 30 minutos anteriores.

**Padrão de eventos de OBC que alimentam esta métrica:**
Eventos com sufixo `*_failed`, `*_rejected`, `*_refused`, `*_error` correlacionados com deploys recentes. Exemplo de produto (payments-api): `invoice.creation_failed`, `webhook.delivery.failed`.

→ Crie seu mapeamento OBC → DORA em `prodops/artifacts/experiments/<slug>/evidence/obc-dora-mapping.md`

---

#### Mean Time to Recovery (MTTR)
**O que mede:** tempo médio desde a detecção da falha até a recovery completa.

**Por que importa:** falhas acontecem. O que diferencia times maduros é a velocidade de recuperação. Nos estágios avançados (MVT/MLP), MTTR alto é inaceitável.

**Como medir:** gap de tempo entre evento de falha e evento de recovery correspondente, por `correlationId` ou identificador de entidade de domínio.

**Pares de eventos que alimentam esta métrica (padrão):**
`<entidade>.creation_failed` → `<entidade>.created`, `<entidade>.delivery.failed` → `<entidade>.delivery.sent`

---

### Extensões ProdOps — as 3 adicionais

#### Reaction Time
**O que mede:** tempo entre a chegada de um sinal externo e a primeira ação processada pelo sistema.

**Por que importa:** métrica de responsividade. Nos estágios iniciais (PoC/MVP), Reaction Time alto indica arquitetura lenta ou processo manual. É análogo ao MTTD (Mean Time to Detect).

**Como medir:** gap entre o evento de sinal externo recebido e o primeiro evento de processamento interno correspondente, por `correlationId`.

**Padrão de eventos que alimentam esta métrica:**
`<signal>.received` → `<entity>.processed`, `<entity>.authorization.requested` → `<entity>.authorized`, `<signal>.delivery.sent` (latência de entrega)

**SLIs típicos alinhados:**
- Entregas de notificação em X segundos — Y% (definido por OBC do produto)
- Outcomes de confirmação em até N minutos — Y% (definido por OBC do produto)

---

#### Rate of Return
**O que mede:** taxa de defeitos escapados para produção e rework gerado — retentativas do cliente, estornos, cancelamentos pós-confirmação.

**Por que importa:** rework é custo invisível. Nos estágios MVR/MVT, Rate of Return alto indica problemas de qualidade que consomem capacidade operacional.

**Como medir:** contagem de eventos de idempotência e estorno por janela de tempo.

**Padrão de eventos de OBC que alimentam esta métrica:**
Eventos com sufixo `*_idempotency_hit`, `*_refund.requested`, `*_refund.required`, `*_retry`. Exemplo de produto (payments-api): `invoice.idempotency_hit`, `payment.card.refund.requested`.

---

#### Availability
**O que mede:** percentual de tempo em que o serviço está disponível e respondendo corretamente.

**Por que importa:** nos estágios avançados (MVT/MLP), disponibilidade é critério de sobrevivência do produto.

**Como medir:** razão entre eventos de sucesso e total de tentativas por janela de tempo.

**Padrão de razões de eventos que alimentam esta métrica:**
`<entidade>.created` / (`<entidade>.created` + `<entidade>.creation_failed`),
`<entidade>.confirmed` / sinais externos de confirmação recebidos,
`<signal>.delivery.sent` / (`<signal>.delivery.sent` + `<signal>.delivery.failed`)

**SLIs típicos alinhados:** SLIs de disponibilidade definidos nos OBCs do produto (ex: 99%, 99.9%, 100%) são diretamente métricas de Availability.

---

## Pesos por estágio de produto

Os pesos refletem o que importa mais em cada momento. Escala 1–8: quanto maior, mais relevante para avaliação de maturidade naquele estágio.

| Métrica | PoC | MVP | IPR | MVR | MVT | MLP |
|---|---|---|---|---|---|---|
| Lead Time for Change | 8 | 8 | 5 | 5 | 3 | 3 |
| Reaction Time | 8 | 5 | 3 | 3 | 2 | 1 |
| Release Frequency | 2 | 5 | 8 | 8 | 8 | 5 |
| Change Fail Rate | 1 | 3 | 5 | 5 | 8 | 8 |
| Mean Time to Recovery | 1 | 1 | 3 | 5 | 8 | 8 |
| Availability | 1 | 2 | 3 | 5 | 8 | 8 |
| Rate of Return | 3 | 3 | 5 | 8 | 8 | 5 |

**Leitura:** em PoC/MVP, velocidade de aprendizado domina (Lead Time e Reaction Time com peso 8). Em MVT/MLP, confiabilidade domina (Change Fail Rate, MTTR e Availability com peso 8).

---

## Perfis de avaliação

Cada produto pode adotar um perfil que repondera as métricas conforme seu foco atual.

| Perfil | Foco | Métricas priorizadas |
|---|---|---|
| `balanced` | Equilibrar velocidade, qualidade e confiabilidade | Todas com peso igual |
| `velocity` | Reduzir cycle time, aumentar frequência | Lead Time, Reaction Time, Release Frequency |
| `quality` | Reduzir defeitos, regressões, retrabalho | Change Fail Rate, Test Coverage, Test Pass Rate, Rate of Return |
| `reliability` | Estabilidade, disponibilidade, recuperação | Availability, MTTR, Rollback Health |
| `ai_readiness` | Qualidade e rastreabilidade para adoção de IA | Change Fail Rate (9), Test Coverage (9), Test Pass Rate (9), MTTR (7), Availability (7) |
| `custom` | Ponderação definida pelo time | Personalizado |

---

## Métricas complementares

Usadas em perfis específicos (especialmente `quality` e `ai_readiness`):

| Métrica | O que mede |
|---|---|
| **Test Coverage** | Percentual de código coberto por testes automatizados |
| **Test Pass Rate** | Percentual de testes passando na suite atual |
| **Rollback Health** | Capacidade de reverter um deploy sem perda de dados ou incidente |

---

## Escala de maturidade (0–5)

| Nível | Nome | Descrição |
|---|---|---|
| 0 | Inexistente | Nenhuma prática estabelecida |
| 1 | Inicial | Práticas ad-hoc, sem repetibilidade |
| 2 | Repetível | Práticas básicas existem mas não são sistemáticas |
| 3 | Definido | Processos documentados e seguidos consistentemente |
| 4 | Gerenciado | Métricas coletadas e usadas para decisões |
| 5 | Excelência | Otimização contínua baseada em dados |

**Estratégia de avaliação top-down:** começa no nível 5 e desce no primeiro critério obrigatório que não passa. Um nível só é atingido quando todos os critérios mandatórios daquele nível são satisfeitos.

---

## Como usar no contexto do produto

1. **Identify o estágio atual** do produto → ver [`product-stages.md`](product-stages.md)
2. **Escolha o perfil** de avaliação conforme o foco do momento
3. **Leia os pesos** da tabela acima para o estágio atual
4. **Mapeie os Observable Events** dos OBCs para as métricas → ver `evidence/obc-dora-mapping.md`
5. **Configure dashboards** com as razões de eventos que alimentam cada métrica
6. **Execute o assessment** no Certificare para obter score de maturidade e roadmap

---

## Referências

→ [Estágios de Produto](product-stages.md)
→ [Glossário](glossary.md)
→ Mapeamento OBC → DORA: `prodops/artifacts/experiments/<slug>/evidence/obc-dora-mapping.md` (criado pelo produto)
→ [Jornada Operation](journeys/operation/README.md)
→ [Reliability Plans](../artifacts/plans/reliability/README.md)
