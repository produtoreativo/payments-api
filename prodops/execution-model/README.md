# Execution Model

Upstream e Downstream são **modos de execução** do Framework ProdOps — não são jornadas.

Cada modo utiliza todas as jornadas, inclusive Discovery. A diferença está no compromisso e no rigor aplicado, não na presença ou ausência de uma jornada.

## Upstream

Modo permissivo e experimental, sem compromisso de entrega.

**Características:**
- Sem compromisso de entrega
- Liberdade para selecionar capabilities e práticas conforme necessidade
- Código é descartável até ser promovido para Downstream
- Evolução rápida de artefatos
- Foco em aprendizado, não em entrega

Upstream transforma hipóteses em conhecimento validado.

→ [Detalhes do modo Upstream](upstream.md)

## Downstream

Modo com compromisso de entrega e aplicação completa dos quality gates vigentes.

**Características:**
- Compromisso formal com critérios de aceite (OBC + BDD Feature)
- Governança e rastreabilidade completas
- Artefatos obrigatórios antes do início
- Evidências registradas em cada etapa
- Sequência completa obrigatória

Downstream entrega software com o conhecimento validado pelo Upstream.

→ [Detalhes do modo Downstream](downstream.md)

## Como escolher o modo

| Situação | Modo |
|---|---|
| Hipótese a validar, incerteza alta | Upstream |
| Item com compromisso, sendo guiado até completar readiness | Downstream |
| Explorar uma capability nova | Upstream |
| Executar item com todos os gates de readiness satisfeitos | Downstream |
| Prototipar integração com provedor | Upstream |
| Entregar feature com compromisso | Downstream |
