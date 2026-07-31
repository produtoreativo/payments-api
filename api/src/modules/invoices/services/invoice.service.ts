import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { ulid } from 'ulid';
import { AsaasWebhookDto } from '../../../dto/asaas-webhook.dto';
import { AsaasService } from '../../../infra/asaas.service';
import { CreateInvoiceDto } from '../dto/create-invoice.dto';
import { InvoiceResponseDto } from '../dto/invoice-response.dto';
import {
  CustomerProviderLink,
  InvoiceRecord,
  PaymentProvider,
  ProviderChargeResponse,
} from '../types/invoice.types';
import { InvoiceRepository } from './invoice-repository.service';
import { ProviderRouterService } from './provider-router.service';

@Injectable()
export class InvoiceService {
  private readonly logger = new Logger(InvoiceService.name);

  constructor(
    private readonly repository: InvoiceRepository,
    private readonly providerRouter: ProviderRouterService,
    private readonly asaas: AsaasService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async createInvoice(
    createInvoiceDto: CreateInvoiceDto,
    idempotencyKey: string,
    correlationId?: string,
  ): Promise<InvoiceResponseDto> {
    this.validateCreateInvoice(createInvoiceDto, idempotencyKey);
    const resolvedCorrelationId = correlationId?.trim() || `corr_${ulid()}`;

    const existing = await this.repository.findByIdempotencyKey(
      createInvoiceDto.tenantId,
      idempotencyKey,
    );

    if (existing) {
      this.logger.log(
        `Returning idempotent invoice ${existing.invoiceId} for order ${existing.orderId}`,
      );
      if (existing.billingType === 'BOLETO') {
        this.eventEmitter.emit('payment.boleto.idempotency_hit', {
          invoiceId: existing.invoiceId,
          orderId: existing.orderId,
          tenantId: existing.tenantId,
          correlationId: resolvedCorrelationId,
        });
      }
      return this.toResponse(existing);
    }

    let provider: PaymentProvider;

    try {
      provider = this.providerRouter.resolve(createInvoiceDto.provider);
    } catch (error) {
      this.emitObservable(
        'pagamento.cobranca.checkout.intencao.de.pagamento.salva_exception',
        {
          tenantId: createInvoiceDto.tenantId,
          orderId: createInvoiceDto.orderId,
          provider: createInvoiceDto.provider ?? 'UNKNOWN',
          correlationId: resolvedCorrelationId,
          stage: 'pagamento_salva',
          flow: 'caminho-feliz',
          step: 1,
          errorType: 'provider_not_enabled',
          errorCode: error instanceof Error ? error.message : 'unknown_error',
          retryable: false,
        },
      );
      throw error;
    }

    const now = new Date().toISOString();
    const invoiceId = `inv_${ulid()}`;
    const invoice: InvoiceRecord = {
      invoiceId,
      tenantId: createInvoiceDto.tenantId,
      orderId: createInvoiceDto.orderId,
      customer: createInvoiceDto.customer,
      amount: createInvoiceDto.amount,
      currency: createInvoiceDto.currency,
      dueDate: createInvoiceDto.dueDate,
      billingType: createInvoiceDto.billingType,
      provider,
      status: 'CREATED',
      description:
        createInvoiceDto.description ??
        `Pedido ${createInvoiceDto.orderId} - Magazine Siará`,
      externalReference: invoiceId,
      createdAt: now,
      updatedAt: now,
    };

    await this.repository.saveInvoice(invoice, idempotencyKey);
    this.eventEmitter.emit('payments.invoice.created', {
      invoiceId: invoice.invoiceId,
      orderId: invoice.orderId,
      provider: invoice.provider,
      status: invoice.status,
      timestamp: now,
    });
    this.emitObservable(
      'pagamento.cobranca.checkout.intencao.de.pagamento.salva',
      {
        invoice,
        correlationId: resolvedCorrelationId,
        stage: 'pagamento_salva',
        flow: 'caminho-feliz',
        step: 1,
      },
    );

    const pendingInvoice = await this.repository.updateInvoice(
      invoice,
      'PROVIDER_PENDING',
    );

    try {
      const customerLink = await this.ensureProviderCustomer(
        pendingInvoice,
        provider,
        resolvedCorrelationId,
      );

      const charge = await this.asaas.createCharge({
        customer: customerLink.providerCustomerId,
        billingType: pendingInvoice.billingType,
        value: pendingInvoice.amount,
        dueDate: pendingInvoice.dueDate,
        description: pendingInvoice.description ?? pendingInvoice.orderId,
        externalReference: pendingInvoice.externalReference,
      });

      this.assertProviderChargeContract(pendingInvoice, charge);
      this.emitObservable(
        'pagamento.processamento.pagamentos.pagamento.pendente',
        {
          invoice: pendingInvoice,
          correlationId: resolvedCorrelationId,
          stage: 'pagamento_pendente',
          flow: 'caminho-feliz',
          step: 3,
          providerOperation: 'POST /v3/payments',
          providerPaymentId: charge.id,
          providerStatus: charge.status,
          paymentUrl:
            charge.invoiceUrl ??
            charge.bankSlipUrl ??
            charge.transactionReceiptUrl,
          amount: charge.value,
          dueDate: charge.dueDate,
          billingType: charge.billingType,
        },
      );

      const hostedPaymentUrl =
        pendingInvoice.billingType === 'CREDIT_CARD'
          ? (charge.invoiceUrl ?? undefined)
          : undefined;

      const openInvoice = await this.repository.updateInvoice(
        pendingInvoice,
        'OPEN',
        {
          providerPaymentId: charge.id,
          providerPayload: charge.payload,
          paymentUrl:
            charge.invoiceUrl ??
            charge.bankSlipUrl ??
            charge.transactionReceiptUrl,
          hostedPaymentUrl,
          bankSlipUrl: charge.bankSlipUrl,
          identificationField: charge.identificationField,
        },
      );

      this.eventEmitter.emit('payments.invoice.opened', {
        invoiceId: openInvoice.invoiceId,
        orderId: openInvoice.orderId,
        provider: openInvoice.provider,
        providerPaymentId: openInvoice.providerPaymentId,
        status: openInvoice.status,
        timestamp: openInvoice.updatedAt,
      });

      if (openInvoice.billingType === 'BOLETO') {
        this.eventEmitter.emit('payment.boleto.created', {
          invoiceId: openInvoice.invoiceId,
          orderId: openInvoice.orderId,
          tenantId: openInvoice.tenantId,
          providerPaymentId: openInvoice.providerPaymentId,
          billingType: openInvoice.billingType,
          dueDate: openInvoice.dueDate,
          correlationId: resolvedCorrelationId,
        });
      }

      if (openInvoice.billingType === 'CREDIT_CARD') {
        this.eventEmitter.emit('payment.card.hosted_invoice.created', {
          tenantId: openInvoice.tenantId,
          orderId: openInvoice.orderId,
          invoiceId: openInvoice.invoiceId,
          providerPaymentId: openInvoice.providerPaymentId,
          provider: openInvoice.provider,
          correlationId: resolvedCorrelationId,
        });
      }
      this.emitObservable('pagamento.processamento.pagamentos.fatura.criada', {
        invoice: openInvoice,
        correlationId: resolvedCorrelationId,
        stage: 'fatura_criada',
        flow: 'caminho-feliz',
        step: 4,
        providerOperation: 'POST /v3/payments',
        providerPaymentId: charge.id,
        providerStatus: charge.status,
        paymentUrl: openInvoice.paymentUrl,
        amount: charge.value,
        dueDate: charge.dueDate,
        billingType: charge.billingType,
      });

      return this.toResponse(openInvoice);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      const errorType = message.includes('provider_contract_violation')
        ? 'provider_contract_violation'
        : 'provider_error';
      const terminalStatus = this.isRetryableProviderError(message)
        ? 'PROVIDER_PENDING'
        : 'FAILED';

      await this.repository.updateInvoice(pendingInvoice, terminalStatus, {
        failureReason: message,
      });

      this.eventEmitter.emit('payments.invoice.provider_failed', {
        invoiceId: pendingInvoice.invoiceId,
        orderId: pendingInvoice.orderId,
        provider: pendingInvoice.provider,
        message,
        timestamp: new Date().toISOString(),
      });

      if (pendingInvoice.billingType === 'BOLETO') {
        this.eventEmitter.emit('payment.boleto.creation_failed', {
          invoiceId: pendingInvoice.invoiceId,
          orderId: pendingInvoice.orderId,
          tenantId: pendingInvoice.tenantId,
          reason: message,
          correlationId: resolvedCorrelationId,
        });
      }
      this.emitObservable(
        'pagamento.processamento.pagamentos.pagamento.pendente_exception',
        {
          invoice: pendingInvoice,
          correlationId: resolvedCorrelationId,
          stage: 'pagamento_pendente',
          flow: 'caminho-feliz',
          step: 3,
          providerOperation: 'POST /v3/payments',
          errorType,
          errorCode: message,
          retryable: this.isRetryableProviderError(message),
        },
      );
      this.emitObservable(
        'pagamento.processamento.pagamentos.fatura.criada_exception',
        {
          invoice: pendingInvoice,
          correlationId: resolvedCorrelationId,
          stage: 'fatura_criada',
          flow: 'caminho-feliz',
          step: 4,
          providerOperation: 'POST /v3/payments',
          errorType,
          errorCode: message,
          retryable: this.isRetryableProviderError(message),
        },
      );

      throw new ServiceUnavailableException({
        message: 'Failed to create invoice on payment provider',
        provider,
        orderId: pendingInvoice.orderId,
        detail: message,
      });
    }
  }

  async getInvoice(
    tenantId: string,
    invoiceId: string,
  ): Promise<{
    invoiceId: string;
    orderId: string;
    status: string;
    amount: number;
    currency: string;
    billingType: string;
    updatedAt: string;
  }> {
    const invoice = await this.repository.findInvoice(tenantId, invoiceId);
    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }
    return {
      invoiceId: invoice.invoiceId,
      orderId: invoice.orderId,
      status: invoice.status,
      amount: invoice.amount,
      currency: invoice.currency,
      billingType: invoice.billingType,
      updatedAt: invoice.updatedAt,
    };
  }

  async cancelInvoice(
    tenantId: string,
    invoiceId: string,
    idempotencyKey: string,
    correlationId?: string,
  ): Promise<InvoiceResponseDto> {
    this.validateCancelInvoice(tenantId, invoiceId, idempotencyKey);
    const resolvedCorrelationId = correlationId?.trim() || `corr_${ulid()}`;

    const existing = await this.repository.findByIdempotencyKey(
      tenantId,
      idempotencyKey,
    );

    if (existing?.status === 'CANCELLED') {
      return this.toResponse(existing);
    }

    const invoice =
      existing ?? (await this.repository.findInvoice(tenantId, invoiceId));

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.status === 'CONFIRMED' || invoice.status === 'RECEIVED') {
      throw new BadRequestException(
        'Invoice cancellation after confirmation requires refund flow',
      );
    }

    if (!invoice.providerPaymentId) {
      throw new BadRequestException(
        'Invoice cancellation requires providerPaymentId',
      );
    }

    if (invoice.status === 'CANCELLED') {
      await this.repository.saveIdempotencyKey(
        tenantId,
        idempotencyKey,
        invoice,
      );
      return this.toResponse(invoice);
    }

    const cancelRequested = await this.repository.updateInvoice(
      invoice,
      'CANCEL_REQUESTED',
    );
    this.emitObservable(
      'pagamento.cancelamento.cobranca.cancelamento.solicitado',
      {
        invoice: cancelRequested,
        correlationId: resolvedCorrelationId,
        stage: 'cancelamento_solicitado',
        flow: 'cancelamento',
        step: 1,
        providerOperation: `DELETE /v3/payments/${invoice.providerPaymentId}`,
      },
    );

    try {
      await this.asaas.cancelCharge(invoice.providerPaymentId);
    } catch (error) {
      if (this.providerStatus(error) === 404) {
        const reconciliationInvoice = await this.repository.updateInvoice(
          cancelRequested,
          'CANCEL_RECONCILIATION_REQUIRED',
          {
            failureReason:
              error instanceof Error ? error.message : 'payment not found',
          },
        );
        this.emitObservable(
          'pagamento.cancelamento.cobranca.conciliacao.requerida',
          {
            invoice: reconciliationInvoice,
            correlationId: resolvedCorrelationId,
            stage: 'conciliacao_cancelamento',
            flow: 'cancelamento',
            step: 2,
            providerOperation: `DELETE /v3/payments/${invoice.providerPaymentId}`,
            errorType: 'provider_not_found',
            retryable: false,
          },
        );

        throw new ConflictException({
          message:
            'Payment provider cancellation requires operational reconciliation',
          invoiceId: reconciliationInvoice.invoiceId,
          status: reconciliationInvoice.status,
        });
      }

      throw error;
    }

    const cancelledInvoice = await this.repository.updateInvoice(
      cancelRequested,
      'CANCELLED',
    );
    await this.repository.saveIdempotencyKey(
      tenantId,
      idempotencyKey,
      cancelledInvoice,
    );

    const eventPayload = {
      invoiceId: cancelledInvoice.invoiceId,
      orderId: cancelledInvoice.orderId,
      tenantId: cancelledInvoice.tenantId,
      amount: cancelledInvoice.amount,
      currency: cancelledInvoice.currency,
      provider: cancelledInvoice.provider,
      providerPaymentId: cancelledInvoice.providerPaymentId,
      cancelledAt: cancelledInvoice.updatedAt,
    };
    this.eventEmitter.emit('payment.cancelled', eventPayload);
    this.eventEmitter.emit('payments.invoice.cancelled', {
      ...eventPayload,
      timestamp: cancelledInvoice.updatedAt,
    });
    this.emitObservable('pagamento.cancelamento.cobranca.cancelada', {
      invoice: cancelledInvoice,
      correlationId: resolvedCorrelationId,
      stage: 'fatura_cancelada',
      flow: 'cancelamento',
      step: 3,
      providerOperation: `DELETE /v3/payments/${invoice.providerPaymentId}`,
      providerStatus: 'DELETED',
    });

    return this.toResponse(cancelledInvoice);
  }

  async requestRefund(
    tenantId: string,
    invoiceId: string,
    idempotencyKey: string,
    reason?: string,
    correlationId?: string,
  ): Promise<InvoiceResponseDto> {
    if (!tenantId?.trim()) {
      throw new BadRequestException('X-Tenant-Id header is required');
    }
    if (!idempotencyKey?.trim()) {
      throw new BadRequestException('Idempotency-Key header is required');
    }

    const resolvedCorrelationId = correlationId?.trim() || `corr_${ulid()}`;

    const existing = await this.repository.findByIdempotencyKey(
      tenantId,
      idempotencyKey,
    );

    if (existing?.status === 'REFUND_REQUESTED') {
      return this.toResponse(existing);
    }

    const invoice = await this.repository.findInvoice(tenantId, invoiceId);

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.status !== 'CONFIRMED' && invoice.status !== 'RECEIVED') {
      throw new BadRequestException(
        'Refund is only allowed for CONFIRMED or RECEIVED invoices',
      );
    }

    const refundInvoice = await this.repository.updateInvoice(
      invoice,
      'REFUND_REQUESTED',
    );
    await this.repository.saveIdempotencyKey(
      tenantId,
      idempotencyKey,
      refundInvoice,
    );

    this.eventEmitter.emit('payment.card.refund.requested', {
      tenantId: refundInvoice.tenantId,
      orderId: refundInvoice.orderId,
      invoiceId: refundInvoice.invoiceId,
      providerPaymentId: refundInvoice.providerPaymentId,
      amount: refundInvoice.amount,
      reason: reason ?? 'unspecified',
      correlationId: resolvedCorrelationId,
    });

    this.emitObservable('pagamento.estorno.cobranca.estorno.solicitado', {
      invoice: refundInvoice,
      correlationId: resolvedCorrelationId,
      stage: 'estorno_solicitado',
      flow: 'estorno',
      step: 1,
      reason: reason ?? 'unspecified',
    });

    return this.toResponse(refundInvoice);
  }

  async confirmProviderCancellation(
    providerPaymentId: string,
    correlationId?: string,
  ): Promise<InvoiceResponseDto | undefined> {
    const invoice =
      await this.repository.findByProviderPaymentId(providerPaymentId);

    if (!invoice) {
      return undefined;
    }

    if (invoice.status === 'CANCELLED') {
      return this.toResponse(invoice);
    }

    if (invoice.status !== 'CANCEL_REQUESTED') {
      return this.toResponse(invoice);
    }

    const cancelledInvoice = await this.repository.updateInvoice(
      invoice,
      'CANCELLED',
    );
    const resolvedCorrelationId = correlationId?.trim() || `corr_${ulid()}`;
    this.emitObservable(
      'pagamento.cancelamento.webhook.cancelamento.confirmado',
      {
        invoice: cancelledInvoice,
        correlationId: resolvedCorrelationId,
        stage: 'webhook_cancelamento',
        flow: 'cancelamento',
        step: 4,
        providerStatus: 'PAYMENT_DELETED',
      },
    );

    return this.toResponse(cancelledInvoice);
  }

  async processProviderWebhook(
    payload: AsaasWebhookDto,
    accessToken?: string,
    options: { skipTokenValidation?: boolean } = {},
  ): Promise<InvoiceResponseDto | undefined> {
    if (!options.skipTokenValidation) {
      this.validateProviderWebhookToken(accessToken);
    }

    const eventKey = this.providerEventKey(payload);
    const isNewEvent = await this.repository.saveRawProviderEvent(
      eventKey,
      payload,
    );

    if (!isNewEvent) {
      const invoice = await this.findWebhookInvoice(payload);
      return invoice?.providerPaymentId ? this.toResponse(invoice) : undefined;
    }

    switch (payload.event) {
      case 'PAYMENT_DELETED':
        return payload.payment?.id
          ? this.confirmProviderCancellation(
              payload.payment.id,
              `webhook-${payload.payment.id}`,
            )
          : undefined;
      case 'PAYMENT_AUTHORIZED':
        return this.recordCardProviderEvent(
          payload,
          'AUTHORIZED',
          'pagamento.cartao.webhook.pagamento.autorizado',
        );
      case 'PAYMENT_AWAITING_RISK_ANALYSIS':
        return this.recordCardProviderEvent(
          payload,
          'AWAITING_RISK_ANALYSIS',
          'pagamento.cartao.webhook.analise_risco.aguardando',
        );
      case 'PAYMENT_APPROVED_BY_RISK_ANALYSIS':
        return this.recordCardProviderEvent(
          payload,
          'APPROVED_BY_RISK_ANALYSIS',
          'pagamento.cartao.webhook.analise_risco.aprovada',
        );
      case 'PAYMENT_REPROVED_BY_RISK_ANALYSIS':
        return this.recordCardProviderEvent(
          payload,
          'REPROVED_BY_RISK_ANALYSIS',
          'pagamento.cartao.webhook.analise_risco.reprovada',
          true,
        );
      case 'PAYMENT_CREDIT_CARD_CAPTURE_REFUSED':
        return this.recordCardProviderEvent(
          payload,
          'REFUSED',
          'pagamento.cartao.webhook.captura_recusada',
          true,
        );
      case 'PAYMENT_CONFIRMED':
        return this.confirmProviderPayment(payload);
      case 'PAYMENT_RECEIVED':
        return this.receiveProviderPayment(payload);
      case 'PAYMENT_OVERDUE':
        return this.recordIgnoredProviderEvent(payload, 'PAYMENT_OVERDUE');
      default:
        return this.recordIgnoredProviderEvent(payload, payload.event);
    }
  }

  private async confirmProviderPayment(
    payload: AsaasWebhookDto,
  ): Promise<InvoiceResponseDto | undefined> {
    const invoice = await this.findWebhookInvoice(payload);

    if (!invoice) {
      this.emitUncorrelatedWebhook(payload, 'CONFIRMED');
      return undefined;
    }

    if (invoice.status === 'CONFIRMED' || invoice.status === 'RECEIVED') {
      return this.toResponse(invoice);
    }

    const confirmedInvoice = await this.repository.updateInvoice(
      invoice,
      'CONFIRMED',
      this.webhookProviderAttrs(invoice, payload),
    );
    const eventPayload = {
      invoiceId: confirmedInvoice.invoiceId,
      orderId: confirmedInvoice.orderId,
      tenantId: confirmedInvoice.tenantId,
      amount: confirmedInvoice.amount,
      currency: confirmedInvoice.currency,
      provider: confirmedInvoice.provider,
      providerPaymentId: confirmedInvoice.providerPaymentId,
      confirmedAt: payload.payment?.confirmedDate ?? confirmedInvoice.updatedAt,
    };

    this.eventEmitter.emit('payment.confirmed', eventPayload);
    this.eventEmitter.emit('payments.invoice.confirmed', {
      ...eventPayload,
      timestamp: confirmedInvoice.updatedAt,
    });
    this.emitObservable('pagamento.confirmacao.webhook.pagamento.confirmado', {
      invoice: confirmedInvoice,
      correlationId: `webhook-${confirmedInvoice.providerPaymentId}`,
      stage: 'webhook_confirmacao',
      flow: 'confirmacao',
      step: 1,
      providerStatus: payload.payment?.status ?? 'CONFIRMED',
    });

    return this.toResponse(confirmedInvoice);
  }

  private async receiveProviderPayment(
    payload: AsaasWebhookDto,
  ): Promise<InvoiceResponseDto | undefined> {
    const invoice = await this.findWebhookInvoice(payload);

    if (!invoice) {
      this.emitUncorrelatedWebhook(payload, 'RECEIVED');
      return undefined;
    }

    if (invoice.status === 'RECEIVED') {
      return this.toResponse(invoice);
    }

    const receivedInvoice = await this.repository.updateInvoice(
      invoice,
      'RECEIVED',
      this.webhookProviderAttrs(invoice, payload),
    );
    this.emitObservable('pagamento.confirmacao.webhook.pagamento.recebido', {
      invoice: receivedInvoice,
      correlationId: `webhook-${receivedInvoice.providerPaymentId}`,
      stage: 'webhook_recebimento',
      flow: 'confirmacao',
      step: 2,
      providerStatus: payload.payment?.status ?? 'RECEIVED',
      reconciliationEvent: true,
      paymentDate: payload.payment?.paymentDate,
    });

    return this.toResponse(receivedInvoice);
  }

  private async recordIgnoredProviderEvent(
    payload: AsaasWebhookDto,
    providerStatus: string,
  ): Promise<InvoiceResponseDto | undefined> {
    const invoice = await this.findWebhookInvoice(payload);

    if (!invoice) {
      this.emitUncorrelatedWebhook(payload, providerStatus);
      return undefined;
    }

    this.emitObservable('pagamento.confirmacao.webhook.evento.ignorado', {
      invoice,
      correlationId: `webhook-${invoice.providerPaymentId}`,
      stage: 'webhook_evento_ignorado',
      flow: 'confirmacao',
      step: 3,
      providerStatus,
    });

    return this.toResponse(invoice);
  }

  private async recordCardProviderEvent(
    payload: AsaasWebhookDto,
    providerStatus: string,
    eventKey: string,
    terminalFailure = false,
  ): Promise<InvoiceResponseDto | undefined> {
    const invoice = await this.findWebhookInvoice(payload);

    if (!invoice) {
      this.emitUncorrelatedWebhook(payload, providerStatus);
      return undefined;
    }

    const providerAttrs = this.webhookProviderAttrs(invoice, payload);
    const shouldFail =
      terminalFailure &&
      invoice.status !== 'CONFIRMED' &&
      invoice.status !== 'RECEIVED';
    const shouldUpdate = shouldFail || Object.keys(providerAttrs).length > 0;
    const updatedInvoice = shouldUpdate
      ? await this.repository.updateInvoice(
          invoice,
          shouldFail ? 'FAILED' : invoice.status,
          {
            ...providerAttrs,
            ...(shouldFail ? { failureReason: payload.event } : {}),
          },
        )
      : invoice;

    this.emitObservable(eventKey, {
      invoice: updatedInvoice,
      correlationId: `webhook-${updatedInvoice.providerPaymentId}`,
      stage: 'webhook_cartao',
      flow: 'confirmacao',
      step: 4,
      providerStatus,
      cardEvent: true,
      terminalFailure,
      eventType: payload.event,
    });

    return this.toResponse(updatedInvoice);
  }

  private async ensureProviderCustomer(
    invoice: InvoiceRecord,
    provider: PaymentProvider,
    correlationId: string,
  ): Promise<CustomerProviderLink> {
    const existing = await this.repository.findCustomerLink(
      invoice.tenantId,
      invoice.customer.id,
      provider,
    );

    if (existing) {
      this.emitObservable(
        'pagamento.processamento.pagamentos.cliente.encontrado.view',
        {
          invoice,
          correlationId,
          stage: 'cliente_encontrado',
          flow: 'caminho-feliz',
          step: 2,
          providerCustomerId: existing.providerCustomerId,
        },
      );
      return existing;
    }

    if (provider !== 'ASAAS') {
      throw new BadRequestException(`Provider ${provider} is not supported`);
    }

    this.emitObservable(
      'pagamento.cobranca.cadastrada.cliente.nao.encontrado.failure',
      {
        invoice,
        correlationId,
        stage: 'cliente_nao_encontrado',
        flow: 'caminho-alternativo',
        step: 2,
      },
    );

    let customer: { id: string };

    try {
      customer = await this.asaas.createCustomer({
        name: invoice.customer.name,
        cpfCnpj: invoice.customer.document,
        email: invoice.customer.email,
        mobilePhone: invoice.customer.mobilePhone,
        externalReference: invoice.customer.id,
        notificationDisabled: false,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.emitObservable(
        'pagamento.cobranca.cadastrada.cliente.cadastrado_exception',
        {
          invoice,
          correlationId,
          stage: 'cliente_cadastrado',
          flow: 'caminho-alternativo',
          step: 3,
          providerOperation: 'POST /v3/customers',
          errorType: 'provider_error',
          errorCode: this.sanitizeError(message),
          retryable: this.isRetryableProviderError(message),
        },
      );
      throw error;
    }

    const now = new Date().toISOString();
    const link: CustomerProviderLink = {
      tenantId: invoice.tenantId,
      customerId: invoice.customer.id,
      provider,
      providerCustomerId: customer.id,
      createdAt: now,
      updatedAt: now,
    };

    await this.repository.saveCustomerLink(link);
    this.eventEmitter.emit('payments.customer.provider_linked', {
      tenantId: invoice.tenantId,
      customerId: invoice.customer.id,
      provider,
      providerCustomerId: customer.id,
      timestamp: now,
    });
    this.emitObservable('pagamento.cobranca.cadastrada.cliente.cadastrado', {
      invoice,
      correlationId,
      stage: 'cliente_cadastrado',
      flow: 'caminho-alternativo',
      step: 3,
      providerOperation: 'POST /v3/customers',
      providerCustomerId: customer.id,
    });

    return link;
  }

  private assertProviderChargeContract(
    invoice: InvoiceRecord,
    charge: ProviderChargeResponse,
  ): void {
    if (!charge.id) {
      throw new Error('provider_contract_violation: missing payment id');
    }

    if (
      charge.externalReference !== undefined &&
      charge.externalReference !== invoice.externalReference
    ) {
      throw new Error(
        'provider_contract_violation: externalReference mismatch',
      );
    }

    if (charge.value !== undefined && charge.value !== invoice.amount) {
      throw new Error('provider_contract_violation: value mismatch');
    }

    if (charge.dueDate !== undefined && charge.dueDate !== invoice.dueDate) {
      throw new Error('provider_contract_violation: dueDate mismatch');
    }

    if (
      charge.billingType !== undefined &&
      charge.billingType !== invoice.billingType
    ) {
      throw new Error('provider_contract_violation: billingType mismatch');
    }

    if (invoice.billingType === 'BOLETO' && !charge.bankSlipUrl) {
      throw new Error(
        'provider_contract_violation: bankSlipUrl missing for BOLETO',
      );
    }
  }

  private validateCreateInvoice(
    dto: CreateInvoiceDto,
    idempotencyKey: string,
  ): void {
    if (!idempotencyKey?.trim()) {
      throw new BadRequestException('Idempotency-Key header is required');
    }

    const requiredFields: Array<[string, unknown]> = [
      ['tenantId', dto.tenantId],
      ['orderId', dto.orderId],
      ['amount', dto.amount],
      ['currency', dto.currency],
      ['dueDate', dto.dueDate],
      ['billingType', dto.billingType],
      ['customer.id', dto.customer?.id],
      ['customer.name', dto.customer?.name],
      ['customer.document', dto.customer?.document],
    ];

    const missingFields = requiredFields
      .filter(
        ([, value]) => value === undefined || value === null || value === '',
      )
      .map(([field]) => field);

    if (missingFields.length > 0) {
      throw new BadRequestException(
        `Missing required fields: ${missingFields.join(', ')}`,
      );
    }

    if (dto.amount <= 0) {
      throw new BadRequestException('amount must be greater than zero');
    }

    if (dto.currency !== 'BRL') {
      throw new BadRequestException('Only BRL currency is supported');
    }

    if (
      !['BOLETO', 'PIX', 'CREDIT_CARD', 'UNDEFINED'].includes(dto.billingType)
    ) {
      throw new BadRequestException(`Invalid billingType ${dto.billingType}`);
    }

    const unsupportedCardFields = this.unsupportedCardFields(dto);

    if (unsupportedCardFields.length > 0) {
      throw new BadRequestException(
        `Hosted credit card flow does not accept card data fields: ${unsupportedCardFields.join(', ')}`,
      );
    }

    if (Number.isNaN(Date.parse(dto.dueDate))) {
      throw new BadRequestException('dueDate must be a valid date');
    }

    if (dto.billingType === 'BOLETO') {
      const dueDate = new Date(dto.dueDate);
      const tomorrow = new Date();
      tomorrow.setUTCHours(0, 0, 0, 0);
      tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);

      if (dueDate.getTime() < tomorrow.getTime()) {
        throw new BadRequestException(
          'dueDate must be a future date (minimum D+1) for BOLETO',
        );
      }
    }
  }

  private unsupportedCardFields(dto: CreateInvoiceDto): string[] {
    const rawDto = dto as CreateInvoiceDto & Record<string, unknown>;
    const fields = [
      'creditCard',
      'creditCardHolderInfo',
      'creditCardToken',
      'authorizeOnly',
      'installments',
      'remoteIp',
    ];

    return fields.filter((field) => rawDto[field] !== undefined);
  }

  private validateCancelInvoice(
    tenantId: string,
    invoiceId: string,
    idempotencyKey: string,
  ): void {
    const missingFields: string[] = [];

    if (!tenantId?.trim()) {
      missingFields.push('X-Tenant-Id header');
    }

    if (!invoiceId?.trim()) {
      missingFields.push('invoiceId');
    }

    if (!idempotencyKey?.trim()) {
      missingFields.push('Idempotency-Key header');
    }

    if (missingFields.length > 0) {
      throw new BadRequestException(
        `Missing required fields: ${missingFields.join(', ')}`,
      );
    }
  }

  validateProviderWebhookToken(accessToken?: string): void {
    const expectedToken = process.env.ASAAS_WEBHOOK_TOKEN;

    if (expectedToken && accessToken !== expectedToken) {
      this.eventEmitter.emit('payments.security.webhook_rejected', {
        provider: 'ASAAS',
        reason: 'invalid_token',
        timestamp: new Date().toISOString(),
      });
      throw new UnauthorizedException('Invalid Asaas webhook token');
    }
  }

  private providerEventKey(payload: AsaasWebhookDto): string {
    const paymentId =
      payload.payment?.id ??
      payload.payment?.externalReference ??
      `unknown_${ulid()}`;

    return `${payload.event}:${paymentId}`;
  }

  private async findWebhookInvoice(
    payload: AsaasWebhookDto,
  ): Promise<InvoiceRecord | undefined> {
    if (payload.payment?.id) {
      const invoice = await this.repository.findByProviderPaymentId(
        payload.payment.id,
      );

      if (invoice) {
        return invoice;
      }
    }

    if (payload.payment?.externalReference) {
      return this.repository.findByExternalReference(
        payload.payment.externalReference,
      );
    }

    return undefined;
  }

  private emitUncorrelatedWebhook(
    payload: AsaasWebhookDto,
    providerStatus: string,
  ): void {
    const providerPaymentId = payload.payment?.id;
    const externalReference = payload.payment?.externalReference;

    this.emitObservable('pagamento.confirmacao.webhook.nao_correlacionado', {
      correlationId: `webhook-${providerPaymentId ?? externalReference ?? 'unknown'}`,
      stage: 'webhook_nao_correlacionado',
      flow: 'confirmacao',
      step: 0,
      provider: 'ASAAS',
      providerPaymentId,
      externalReference,
      providerStatus,
      eventType: payload.event,
    });
  }

  private webhookProviderAttrs(
    invoice: InvoiceRecord,
    payload: AsaasWebhookDto,
  ): Partial<InvoiceRecord> {
    if (invoice.providerPaymentId || !payload.payment?.id) {
      return {};
    }

    return {
      providerPaymentId: payload.payment.id,
    };
  }

  private toResponse(invoice: InvoiceRecord): InvoiceResponseDto {
    if (!invoice.providerPaymentId) {
      throw new ServiceUnavailableException({
        message: 'Invoice was not opened on payment provider',
        invoiceId: invoice.invoiceId,
        status: invoice.status,
      });
    }

    return {
      invoiceId: invoice.invoiceId,
      orderId: invoice.orderId,
      provider: invoice.provider,
      providerPaymentId: invoice.providerPaymentId,
      status: invoice.status,
      amount: invoice.amount,
      currency: invoice.currency,
      billingType: invoice.billingType,
      dueDate: invoice.dueDate,
      paymentUrl: invoice.paymentUrl,
      hostedPaymentUrl: invoice.hostedPaymentUrl,
      bankSlipUrl: invoice.bankSlipUrl,
      identificationField: invoice.identificationField,
      externalReference: invoice.externalReference,
    };
  }

  private emitObservable(
    eventKey: string,
    payload: {
      invoice?: InvoiceRecord;
      tenantId?: string;
      orderId?: string;
      provider?: string;
      correlationId: string;
      stage: string;
      flow: string;
      step: number;
      [key: string]: unknown;
    },
  ): void {
    const invoice = payload.invoice;
    const event = {
      event_key: eventKey,
      env: process.env.OBSERVABILITY_ENV ?? 'dev',
      stage: payload.stage,
      flow: payload.flow,
      step: payload.step,
      correlationId: payload.correlationId,
      tenantId: invoice?.tenantId ?? payload.tenantId,
      orderId: invoice?.orderId ?? payload.orderId,
      invoiceId: invoice?.invoiceId,
      provider: invoice?.provider ?? payload.provider,
      providerPaymentId:
        invoice?.providerPaymentId ?? payload.providerPaymentId,
      timestamp: new Date().toISOString(),
      ...this.withoutInternalPayload(payload),
    };

    this.eventEmitter.emit('payments.observability', event);
  }

  private withoutInternalPayload(payload: Record<string, unknown>) {
    const rest = { ...payload };
    delete rest.invoice;
    delete rest.correlationId;
    delete rest.stage;
    delete rest.flow;
    delete rest.step;
    return rest;
  }

  private sanitizeError(message: string): string {
    return message
      .replace(/\d{3}\.?\d{3}\.?\d{3}-?\d{2}/g, '[document]')
      .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]')
      .replace(/\b\d{10,11}\b/g, '[phone]');
  }

  private isRetryableProviderError(message: string): boolean {
    return /timeout|5\d\d|ECONNRESET|ETIMEDOUT/i.test(message);
  }

  private providerStatus(error: unknown): number | undefined {
    return typeof error === 'object' && error !== null && 'status' in error
      ? Number((error as { status?: number }).status)
      : undefined;
  }
}
