# Registro de Riscos — Premortem Payments

> Baseado no documento de Premortem enviado pelo usuário.

## Resumo

O cenário descreve uma release crítica para habilitação de um novo gateway de pagamentos e estabilização do serviço de notificações. O principal risco de negócio é uma multa contratual de **R$ 500 milhões** caso a ativação não ocorra dentro do prazo.

---

# Doom 2 — Atraso na ativação do novo Gateway

## Descrição

A Feature Flag que habilita o novo Gateway permanece desativada devido a um bug conhecido. Caso a correção não seja concluída dentro da janela da release, existe risco de multa contratual e impacto significativo na margem do negócio.

## Impacto

- Financeiro extremamente alto
- Bloqueio da entrada em produção
- Comprometimento da margem
- Atraso na entrega da release

## Mitigações sugeridas

- Premortem específica para a Feature Flag
- Canary Release
- Plano de Rollback
- Observabilidade ponta a ponta
- Testes automatizados sobre a Feature Flag
- War Room durante a ativação

## Evidência Upstream requerida

O experimento `prodops/framework/journeys/discovery/experiments/004-feature-flag-readiness/experiment.md`
classifica esta incerteza como P0 e requer evidências de Checkout antes da
promoção final:

- bug exato que mantém a flag desligada;
- dono e status da correção;
- regra de targeting e rollout gradual;
- auditoria de ativação/desativação;
- telemetria que distingue gateway antigo e novo por pedido;
- critério de pausa e rollback;
- política para pedidos já iniciados no Payments quando a flag for desligada.

---

# Doom 3 — Complexidade da migração para microserviços

## Descrição

O desacoplamento do monólito aumenta significativamente a complexidade operacional e de integração entre serviços.

## Impacto

- Aumento de falhas distribuídas
- Maior dificuldade de diagnóstico
- Dependências entre serviços

## Mitigações sugeridas

- Distributed Tracing
- Service Map
- Health Checks
- Catálogo de dependências
- Testes de integração
- Chaos Engineering gradual

---

# Doom 4 — Falta de visibilidade operacional

## Descrição

Incidentes já ocorreram anteriormente e podem voltar a acontecer sem detecção rápida, prejudicando planejamento e operação.

## Impacto

- Aumento do MTTR
- Perda de confiança
- Incidentes recorrentes

## Mitigações sugeridas

- Instrumentação completa com OpenTelemetry
- Dashboards executivos
- Alertas baseados em SLO
- Integração com ITSM
- Runbooks
- RCAs obrigatórias

---

# Riscos estruturais identificados

- Dependência do novo Gateway para cumprimento contratual.
- Dependência do serviço de Notifier.
- Necessidade de instrumentação no DataDog.
- Integração ao processo corporativo de gestão de incidentes.
- Dependências entre Ecommerce, Payments, Marketing, Vendas, Infraestrutura e Arquitetura.

## Riscos Upstream - Cartão de crédito Asaas

- Checkout hospedado no Asaas reduz risco de PCI porque Payments API não
  trafega dados sensíveis de cartão, mas depende da experiência de pagamento
  hospedada e da URL de invoice retornada pelo provedor.
- Pagamento tokenizado exige contrato explícito para `creditCardToken`,
  `remoteIp`, timeout mínimo de 60 segundos, estados de autorização, análise de
  risco e recusa de captura.
- Captura direta de dados de cartão aumenta a superfície de segurança e não deve
  entrar em Downstream sem decisão formal de compliance, UX e antifraude.
- Eventos `PAYMENT_AUTHORIZED`, `PAYMENT_AWAITING_RISK_ANALYSIS`,
  `PAYMENT_REPROVED_BY_RISK_ANALYSIS` e
  `PAYMENT_CREDIT_CARD_CAPTURE_REFUSED` ainda não possuem estados internos
  completos nem SLOs aceitos.
- Cancelar cobrança aberta por `DELETE /v3/payments` não cobre estorno de
  pagamento confirmado; cartão confirmado exige fronteira de refund/reversal.
- Listagem de cartões salvos exige validação forte de tenant, usuário e
  ownership; erro nesse ponto pode expor cartão/token de outro cliente.
- Token de cartão deve ser tratado como material sensível: não pode aparecer em
  logs, traces, analytics, payloads de erro ou dead-letter queues.
- `remoteIp` precisa representar o IP do pagador; usar IP do servidor Payments
  reduz qualidade antifraude e pode divergir do modelo da Asaas.
- Cadastro de novo cartão amplia a fronteira PCI porque `creditCard` e
  `creditCardHolderInfo` passam pela Payments API mesmo que não sejam
  persistidos.
- Estorno de cartão confirmado precisa de contrato próprio, idempotência e
  evidência do provedor; não deve ser tratado como cancelamento simples.

---

# Riscos — Boleto Bancário

## Risco B1 — bankSlipUrl ausente ou expirada

### Descrição

O provedor Asaas pode retornar a cobrança sem `bankSlipUrl` em cenários de instabilidade ou de boleto em processamento. O cliente recebe invoice sem conseguir acessar o boleto para pagamento.

### Impacto

- Alto: cliente não consegue realizar o pagamento; conversão perdida.
- Suporte aumenta com chamados de "boleto não chegou".

### Mitigações

- Validar presença de `bankSlipUrl` na resposta do provedor antes de retornar status `OPEN`. Se ausente, marcar invoice como `FAILED` e logar `payment.boleto.creation_failed`.
- Acceptance test deve verificar que `bankSlipUrl` está presente na resposta.

---

## Risco B2 — dueDate no passado ou ausente

### Descrição

O ecommerce pode enviar `dueDate` no passado ou omiti-la. A Asaas rejeita cobranças com `dueDate` passada com erro 400, mas a falha ocorre após uma chamada desnecessária ao provedor.

### Impacto

- Médio: chamada desnecessária ao provedor; resposta de erro menos clara ao ecommerce.

### Mitigações

- Validar `dueDate` no gateway antes de chamar o provedor: obrigatória e futura (≥ D+1).
- Rejeitar com `400` e mensagem clara antes de qualquer chamada à Asaas.

---

## Risco B3 — Confirmação assíncrona confundida com falha

### Descrição

Diferente do Pix (confirmação imediata), o Boleto permanece em status `OPEN` por dias até o pagamento bancário. Sistemas que esperam confirmação síncrona podem tratar o status `OPEN` como falha.

### Impacto

- Médio: Checkout ou Order Management pode cancelar pedido prematuramente aguardando confirmação.

### Mitigações

- Documentar claramente no OBC e na BDD Feature que status `OPEN` é o estado correto após criação.
- Confirmação de Boleto chega via webhook assíncrono (mesmo fluxo do Pix confirmado).
- Runbook deve incluir diagnóstico de "boleto criado, pagamento não confirmado".

---

## Risco B4 — identificationField ausente na resposta

### Descrição

A linha digitável (`identificationField`) não está mapeada no `ProviderChargeResponse` nem no `InvoiceResponseDto` atual. A implementação exige extensão do contrato de resposta.

### Impacto

- Alto para implementação: campos precisam ser adicionados antes do primeiro test passar. Sem isso a BDD Feature falha no acceptance test.

### Mitigações

- Adicionar `identificationField` a `ProviderChargeResponse`, `InvoiceRecord` e `InvoiceResponseDto` antes de escrever o acceptance test.
- O Bootstrap do Hack deve identificar essa dependência na leitura do OBC.

---

# Recomendações para o Reliability Plan

## Antes da release

- Premortem
- Event Storming
- Revisão dos OBCs
- Revisão dos cenários BDD
- Plano de Rollback
- Plano de Canary
- Testes de carga
- Testes de resiliência

## Durante a release

- Monitoramento em tempo real
- Feature Flag monitorada
- Dashboards executivos
- War Room
- Critérios claros de rollback

## Após a release

- Postmortem
- RCA
- Atualização da Repository Tracking List
- Atualização dos OBCs
- Atualização do Product Deck e Service Deck

---

# DS-Security-01 — Breaking change em atualização de dependência npm

**Capability:** dependency-security-update
**Severidade:** Média
**Probabilidade:** Média (multer 1.x → 2.x é upgrade de major; demais são minor/patch)
**Status:** Resolvido — 2026-08-01 (hack DS-44, work-item #115)

## Descrição

A resolução das 27 vulnerabilidades Dependabot envolve atualizar `axios` de `^1.13.2` para `>=1.18.0` (dependência direta) e resolver dependências transitivas via `npm audit fix`. O risco principal era `multer`: a versão patched (`2.2.0`) é um upgrade de major version (1.x → 2.x), o que poderia introduzir breaking changes na API de upload de arquivos.

## Decisão (2026-08-01)

**multer é dependência puramente transitiva** — não há nenhum Version: ImageMagick 7.1.2-25 Q16-HDRI aarch64 037e46295:20260604 https://imagemagick.org
Copyright: (C) 1999 ImageMagick Studio LLC
License: https://imagemagick.org/license/
Features: Cipher DPC HDRI Modules 
Delegates (built-in): bzlib freetype heic jng jpeg lcms ltdl lzma png tiff webp xml zlib zstd
Compiler: clang (17.0.0)
Usage: import [options ...] [ file ]

Image Settings:
  -adjoin              join images into a single multi-image file
  -border              include window border in the output image
  -channel type        apply option to select image channels
  -colorspace type     alternate image colorspace
  -comment string      annotate image with comment
  -compress type       type of pixel compression when writing the image
  -define format:option
                       define one or more image format options
  -density geometry    horizontal and vertical density of the image
  -depth value         image depth
  -descend             obtain image by descending window hierarchy
  -display server      X server to contact
  -dispose method      layer disposal method
  -dither method       apply error diffusion to image
  -delay value         display the next image after pausing
  -encipher filename   convert plain pixels to cipher pixels
  -endian type         endianness (MSB or LSB) of the image
  -encoding type       text encoding type
  -filter type         use this filter when resizing an image
  -format "string"     output formatted image characteristics
  -frame               include window manager frame
  -gravity direction   which direction to gravitate towards
  -identify            identify the format and characteristics of the image
  -interlace type      None, Line, Plane, or Partition
  -interpolate method  pixel color interpolation method
  -label string        assign a label to an image
  -limit type value    Area, Disk, Map, or Memory resource limit
  -monitor             monitor progress
  -page geometry       size and location of an image canvas
  -pause seconds       seconds delay between snapshots
  -pointsize value     font point size
  -quality value       JPEG/MIFF/PNG compression level
  -quiet               suppress all warning messages
  -regard-warnings     pay attention to warning messages
  -repage geometry     size and location of an image canvas
  -respect-parentheses settings remain in effect until parenthesis boundary
  -sampling-factor geometry
                       horizontal and vertical sampling factor
  -scene value         image scene number
  -screen              select image from root window
  -seed value          seed a new sequence of pseudo-random numbers
  -set property value  set an image property
  -silent              operate silently, i.e. don't ring any bells 
  -snaps value         number of screen snapshots
  -support factor      resize support: > 1.0 is blurry, < 1.0 is sharp
  -synchronize         synchronize image to storage device
  -taint               declare the image as modified
  -transparent-color color
                       transparent color
  -treedepth value     color tree depth
  -verbose             print detailed information about the image
  -virtual-pixel method
                       Constant, Edge, Mirror, or Tile
  -window id           select window with this id or name
                       root selects whole screen

Image Operators:
  -annotate geometry text
                       annotate the image with text
  -colors value        preferred number of colors in the image
  -crop geometry       preferred size and location of the cropped image
  -encipher filename   convert plain pixels to cipher pixels
  -extent geometry     set the image size
  -geometry geometry   preferred size or location of the image
  -help                print program options
  -monochrome          transform image to black and white
  -negate              replace every pixel with its complementary color 
  -quantize colorspace reduce colors in this colorspace
  -resize geometry     resize the image
  -rotate degrees      apply Paeth rotation to the image
  -strip               strip image of all profiles and comments
  -thumbnail geometry  create a thumbnail of the image
  -transparent color   make this color transparent within the image
  -trim                trim image edges
  -type type           image type

Miscellaneous Options:
  -debug events        display copious debugging information
  -help                print program options
  -list type           print a list of supported option arguments
  -log format          format of debugging information
  -version             print version information

By default, 'file' is written in the MIFF image format.  To
specify a particular image format, precede the filename with an image
format name and a colon (i.e. ps:image) or specify the image type as
the filename suffix (i.e. image.ps).  Specify 'file' as '-' for
standard input or output. ou uso direto em `api/src/`. É apenas uma dependência transitiva de `@nestjs/platform-express`.

O upgrade para multer >=2.2.0 foi aplicado via `npm audit fix` sem alteração em arquivos de código-fonte. O test suite completo (71 testes e2e + 7 suites de aceitação) passou sem regressões após a atualização.

**Vulnerabilidades residuais (3 — nenhuma high/critical):**
- `aws-sdk` + `uuid` (moderate) — dependências de `aws-lambda@1.0.7` (transitive). A correção requer `--force` que faria downgrade para `aws-lambda@1.0.6` (breaking change de major). **Decisão: aceite de risco.** As vulnerabilidades são de severidade moderada (sem CVE crítico) e a correção introduziria uma breaking change maior. Issue de follow-up registrado para avaliar migração de `aws-sdk` v2 → v3 nativa.

## Impacto final

- Zero vulnerabilidades high/critical restantes
- 3 vulnerabilidades moderadas residuais (1 low + 2 moderate em aws-sdk chain) — aceite de risco registrado
- Build de produção: zero erros
- Test suite: 71/71 passando

## Referências

- OBC: `prodops/artifacts/obcs/dependency-security-update.md`
- Issue: [#55](https://github.com/produtoreativo/payments-api/issues/55)
- Trail: `prodops/artifacts/trails/sessions/2026-08-01-a0e86737.md`
