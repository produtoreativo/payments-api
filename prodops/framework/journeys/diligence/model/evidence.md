# Evidence — Definição Canônica

## Definição

> **Evidence é uma prova persistente e referenciável usada para demonstrar a detecção, o impacto, a correção ou a verificação de uma condição avaliada pela Diligence.**

Evidence não é anotação informal. Evidence não é comentário em Issue. Evidence é um registro estruturado com identidade, fonte, temporalidade e referência ao que ela comprova. Uma Evidence pode suportar múltiplos Findings; um Finding pode ser suportado por múltiplas Evidences.

---

## Formato de ID

```
EVD-YYYY-NNNN
```

- `EVD`: prefixo imutável da entidade Evidence
- `YYYY`: ano de coleta (quatro dígitos)
- `NNNN`: sequencial de quatro dígitos por ano (0001–9999)

Exemplos: `EVD-2026-0001`, `EVD-2026-0042`

---

## O que a Evidence pode provar

Uma Evidence pode ser coletada para demonstrar qualquer das condições abaixo:

| O que prova | Quando é coletada |
|---|---|
| **Resultado de Check** | Durante a execução de um Check; documenta o que foi observado |
| **Existência de Finding** | Demonstra que a condição descrita no Finding de fato existe |
| **Impacto** | Demonstra consequências da condição se não for resolvida |
| **Execução de Remediation** | Demonstra que a ação corretora foi aplicada |
| **Resolução** | Demonstra que a condição foi eliminada |
| **Verificação** | Demonstra verificação independente de que a resolução é válida |
| **Validade de Waiver** | Demonstra que o Waiver foi aprovado pelos responsáveis corretos |

---

## Tipos de Evidence

| Tipo | Definição | Exemplos |
|---|---|---|
| **Document** | Arquivo Markdown, texto ou especificação que documenta o estado | OBC file, Reliability Plan, arquivo de glossário |
| **Log** | Saída de processo, sistema ou pipeline | Saída de CI/CD, log de deploy, log de execução de Check |
| **Metric** | Valor mensurável coletado de sistema de observabilidade | Taxa de erro, latência P99, disponibilidade |
| **Test Result** | Resultado de execução de testes automatizados | Relatório de BDD, cobertura, saída de pytest/jest |
| **Command Output** | Saída de comando CLI executado reproduzivelmente | `gh issue view 57 --json body,labels`, `gh project field-list` |
| **API Response** | Resposta de chamada de API capturada | Resposta JSON da GitHub API, resposta de API externa |
| **Screenshot** | Captura de tela de estado visual | Estado de View no GitHub Project, dashboard de observabilidade |
| **Pull Request** | PR que implementa ou documenta uma mudança | PR #42 com as mudanças de Remediation |
| **Commit** | Commit que registra uma mudança específica | Commit hash com a correção aplicada |
| **Release** | Release ou Release Trail que documenta entrega | Release v2.1.0, entrada no Release Trail |
| **Dashboard** | Dashboard ou painel de observabilidade | Dashboard de SLOs, painel de alertas |
| **Approval** | Registro formal de aprovação | Aprovação de PR, sign-off de revisor, aprovação de Waiver |
| **Decision Record** | Registro de decisão tomada por jornada competente | Assessment decision, Architecture Decision Record |
| **Conformance Report** | Relatório de conformidade produzido pelo Workspace Reconciliation | CONFORME / PARCIAL / NÃO CONFORME |
| **Observation** | Observação humana registrada quando Evidence automatizada não é possível | Nota de revisão manual, observação de campo |

### Hierarquia de preferência

Quando múltiplos tipos de Evidence são possíveis para a mesma condição, preferir na seguinte ordem (Automation First):

1. **Command Output / API Response** — reproduzível, verificável, automatizável
2. **Test Result / Log** — gerado por sistema, rastreável
3. **Document / Metric** — referenciável, estável
4. **Dashboard / Conformance Report** — visual mas estruturado
5. **Screenshot** — visual; difícil de verificar automaticamente
6. **Observation** — último recurso; requer justificativa de por que Evidence automatizada não foi possível

---

## Schema

| Campo | Tipo conceitual | Cardinalidade | Regras e notas |
|---|---|---|---|
| `id` | string | 1 | Formato EVD-YYYY-NNNN; imutável; único no sistema |
| `type` | enum | 1 | Um dos tipos listados acima |
| `description` | text | 1 | Obrigatório; descreve o que a Evidence demonstra e por que é relevante |
| `source` | string | 1 | De onde a Evidence vem: sistema, ferramenta, processo ou responsável |
| `collected_at` | datetime | 1 | Imutável após criação; set no momento da coleta |
| `collected_by` | string | 1 | Identificador do agente ou pessoa que coletou: Check ID, agent ID, ou identificador humano |
| `subject` | string | 1 | O que está sendo evidenciado: Finding ID, Check ID, Remediation ID, Waiver ID, ou artefato |
| `related_finding` | list de Finding IDs | 0..N | Findings que esta Evidence suporta; pode ser vazia (Evidence de Check sem Finding associado) |
| `related_check` | string | 0..1 | Check ID da execução que gerou esta Evidence |
| `integrity` | string | 0..1 | Hash ou mecanismo de verificação quando aplicável (ex: SHA256 do arquivo, assinatura digital) |
| `valid_until` | date | 0..1 | Data de expiração; obrigatório para Evidence temporal (Waiver, métricas, estados dinâmicos) |
| `location` | string | 1 | Referência estável ao conteúdo: path de arquivo, URL, comando reproduzível, referência a commit |

---

## Critérios de suficiência

Quantidade de Evidence não é suficiência. Uma Evidence é suficiente quando satisfaz TODOS os critérios abaixo:

| Critério | Descrição |
|---|---|
| **Relevância** | A Evidence está diretamente relacionada à condição sendo avaliada; não é evidência genérica |
| **Fonte confiável** | Vem de sistema, ferramenta ou processo com autoridade sobre o dado |
| **Temporalidade adequada** | Foi coletada em momento relevante para a condição (não excessivamente antiga) |
| **Reproduzível ou verificável** | Pode ser verificada por outro agente ou revisada por humano sem depender de interpretação |
| **Suporta a conclusão** | O conteúdo da Evidence sustenta a afirmação feita sobre a condição |
| **Não contradita** | Não existe Evidence de fonte de maior autoridade que contradiga a conclusão |

---

## Conflito entre Evidências

Quando Evidence de fontes confiáveis divergem sobre a mesma condição, o resultado do Check deve ser **Indeterminate** — NÃO escolha silenciosa entre as fontes.

O conflito deve ser registrado explicitamente:

- Identificar as duas (ou mais) Evidences conflitantes
- Documentar em que se contradizem
- Registrar o conflito na trail do Finding afetado
- Escalar para decisão humana antes de concluir

**Nunca escolher silenciosamente** entre fontes conflitantes. A escolha silenciosa mascara um problema de modelo ou de dados que precisa ser resolvido.

---

## Imutabilidade

Evidence histórica **não deve ser sobrescrita**. Uma vez registrada, a Evidence representa o estado do sistema no momento da coleta — alterar esse registro retroativamente destrói a trilha histórica.

Quando uma nova coleta é necessária (ex: re-verificação após Remediation):

- Criar nova Evidence com novo ID (`EVD-YYYY-NNNN`)
- Referenciar a Evidence anterior quando relevante
- Registrar na trail do Finding que a nova Evidence substitui ou complementa a anterior para determinada conclusão

A Evidence anterior permanece no registro — o que muda é qual Evidence suporta a conclusão atual.

---

## Expiração de Evidence

Evidence temporal deve ter `valid_until` declarado quando a informação pode mudar e a validade depende de quando foi coletada.

Exemplos de Evidence que **devem** ter `valid_until`:
- Estado de sistema dinâmico (métricas, SLOs, estado de deploy)
- Aprovação de Waiver (válida pelo período do Waiver)
- Conformance Report de Workspace (pode ficar desatualizado rapidamente)
- Decisão de Assessment que pode ser revisada

Evidências sem `valid_until` são tratadas como permanentemente válidas — usar com critério.

Quando Evidence expira:
- Finding associado deve ser reavaliado
- Nova Evidence deve ser coletada se a condição ainda é relevante
- Finding pode retornar a Open ou Acknowledged se a Evidence de resolução expirou

---

## Referências

→ [`README.md`](README.md) — modelo de entidades e relações
→ [`finding.md`](finding.md) — entidade que a Evidence suporta
→ [`check.md`](check.md) — entidade que gera Evidence durante execução
→ [`remediation.md`](remediation.md) — entidade cuja execução deve ser evidenciada
→ [`waiver.md`](waiver.md) — entidade cuja aprovação deve ser evidenciada
