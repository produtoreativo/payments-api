import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { ulid } from 'ulid';
import { AsaasService } from '../../infra/asaas.service';
import {
  SplitPaymentCustomer,
  SplitPaymentRecord,
  SplitPaymentStatus,
} from './split-payment.types';
import { SplitPaymentRepository } from './split-payment-repository.service';

export class CreateSplitPaymentDto {
  tenantId: string;
  orderId: string;
  totalAmount: number;
  currency?: string;
  pixAmount: number;
  boletoAmount: number;
  boletoDueDate: string;
  customer: SplitPaymentCustomer;
}

export interface SplitPaymentResponseDto {
  splitPaymentId: string;
  orderId: string;
  status: SplitPaymentStatus;
  totalAmount: number;
  pix: {
    invoiceId: string;
    amount: number;
    status: string;
    confirmedAt: string | null;
  };
  boleto: {
    invoiceId: string;
    amount: number;
    dueDate: string;
    status: string;
    confirmedAt: string | null;
  };
  createdAt: string;
  completedAt: string | null;
}

@Injectable()
export class SplitPaymentService {
  private readonly logger = new Logger(SplitPaymentService.name);

  constructor(
    private readonly repository: SplitPaymentRepository,
    private readonly asaas: AsaasService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async createSplitPayment(
    dto: CreateSplitPaymentDto,
    idempotencyKey: string,
    correlationId?: string,
  ): Promise<SplitPaymentResponseDto> {
    this.validateCreateDto(dto, idempotencyKey);

    const resolvedCorrelationId = correlationId?.trim() || `corr_${ulid()}`;

    const existing = await this.repository.findByIdempotencyKey(
      dto.tenantId,
      idempotencyKey,
    );

    if (existing) {
      this.logger.log(
        `Returning idempotent split payment ${existing.splitPaymentId} for order ${existing.orderId}`,
      );
      return this.toResponse(existing);
    }

    const splitPaymentId = `spl_${ulid()}`;

    const providerCustomerId = await this.resolveProviderCustomer(
      dto.tenantId,
      dto.customer,
    );

    let pixCharge: { id: string };
    let boletoCharge: { id: string };

    try {
      pixCharge = await this.asaas.createCharge({
        customer: providerCustomerId,
        billingType: 'PIX',
        value: dto.pixAmount,
        dueDate: dto.boletoDueDate,
        description: `Split Payment PIX - Pedido ${dto.orderId}`,
        externalReference: `${splitPaymentId}:pix`,
      });

      boletoCharge = await this.asaas.createCharge({
        customer: providerCustomerId,
        billingType: 'BOLETO',
        value: dto.boletoAmount,
        dueDate: dto.boletoDueDate,
        description: `Split Payment Boleto - Pedido ${dto.orderId}`,
        externalReference: `${splitPaymentId}:boleto`,
      });
    } catch (error) {
      const reason =
        error instanceof Error ? error.message : 'unknown_provider_error';

      this.eventEmitter.emit('split_payment.creation_failed', {
        orderId: dto.orderId,
        reason,
        correlationId: resolvedCorrelationId,
      });

      throw error;
    }

    const now = new Date().toISOString();

    const record: SplitPaymentRecord = {
      splitPaymentId,
      tenantId: dto.tenantId,
      orderId: dto.orderId,
      totalAmount: dto.totalAmount,
      currency: dto.currency ?? 'BRL',
      pixAmount: dto.pixAmount,
      pixInvoiceId: pixCharge.id,
      pixStatus: 'PENDING',
      boletoAmount: dto.boletoAmount,
      boletoInvoiceId: boletoCharge.id,
      boletoDueDate: dto.boletoDueDate,
      boletoStatus: 'PENDING',
      status: 'PENDING_BOTH',
      correlationId: resolvedCorrelationId,
      customer: dto.customer,
      createdAt: now,
      updatedAt: now,
    };

    await this.repository.save(record, idempotencyKey);

    this.eventEmitter.emit('split_payment.created', {
      splitPaymentId: record.splitPaymentId,
      orderId: record.orderId,
      pixAmount: record.pixAmount,
      boletoAmount: record.boletoAmount,
      totalAmount: record.totalAmount,
      correlationId: resolvedCorrelationId,
    });

    return this.toResponse(record);
  }

  async confirmPix(
    tenantId: string,
    splitPaymentId: string,
    correlationId?: string,
  ): Promise<SplitPaymentResponseDto> {
    const record = await this.requireRecord(tenantId, splitPaymentId);

    if (record.pixStatus === 'CONFIRMED') {
      return this.toResponse(record);
    }

    const resolvedCorrelationId = correlationId?.trim() || record.correlationId;
    const confirmedAt = new Date().toISOString();

    const newStatus: SplitPaymentStatus =
      record.status === 'BOLETO_CONFIRMED' ? 'COMPLETED' : 'PIX_CONFIRMED';

    const updated = await this.repository.update(record, newStatus, {
      pixStatus: 'CONFIRMED',
      pixConfirmedAt: confirmedAt,
      ...(newStatus === 'COMPLETED' ? { completedAt: confirmedAt } : {}),
    });

    this.eventEmitter.emit('split_payment.pix.confirmed', {
      splitPaymentId: updated.splitPaymentId,
      orderId: updated.orderId,
      pixInvoiceId: updated.pixInvoiceId,
      confirmedAt,
      correlationId: resolvedCorrelationId,
    });

    if (newStatus === 'COMPLETED') {
      this.eventEmitter.emit('split_payment.completed', {
        splitPaymentId: updated.splitPaymentId,
        orderId: updated.orderId,
        completedAt: updated.completedAt,
        correlationId: resolvedCorrelationId,
      });
    }

    return this.toResponse(updated);
  }

  async confirmBoleto(
    tenantId: string,
    splitPaymentId: string,
    correlationId?: string,
  ): Promise<SplitPaymentResponseDto> {
    const record = await this.requireRecord(tenantId, splitPaymentId);

    if (record.boletoStatus === 'CONFIRMED') {
      return this.toResponse(record);
    }

    const resolvedCorrelationId = correlationId?.trim() || record.correlationId;
    const confirmedAt = new Date().toISOString();

    const newStatus: SplitPaymentStatus =
      record.status === 'PIX_CONFIRMED' ? 'COMPLETED' : 'BOLETO_CONFIRMED';

    const updated = await this.repository.update(record, newStatus, {
      boletoStatus: 'CONFIRMED',
      boletoConfirmedAt: confirmedAt,
      ...(newStatus === 'COMPLETED' ? { completedAt: confirmedAt } : {}),
    });

    this.eventEmitter.emit('split_payment.boleto.confirmed', {
      splitPaymentId: updated.splitPaymentId,
      orderId: updated.orderId,
      boletoInvoiceId: updated.boletoInvoiceId,
      confirmedAt,
      correlationId: resolvedCorrelationId,
    });

    if (newStatus === 'COMPLETED') {
      this.eventEmitter.emit('split_payment.completed', {
        splitPaymentId: updated.splitPaymentId,
        orderId: updated.orderId,
        completedAt: updated.completedAt,
        correlationId: resolvedCorrelationId,
      });
    }

    return this.toResponse(updated);
  }

  async expireBoleto(
    tenantId: string,
    splitPaymentId: string,
    correlationId?: string,
  ): Promise<SplitPaymentResponseDto> {
    const record = await this.requireRecord(tenantId, splitPaymentId);

    if (record.boletoStatus === 'EXPIRED') {
      return this.toResponse(record);
    }

    const resolvedCorrelationId = correlationId?.trim() || record.correlationId;
    const expiredAt = new Date().toISOString();

    const updated = await this.repository.update(
      record,
      'PENDING_INVESTIGATION',
      { boletoStatus: 'EXPIRED' },
    );

    this.eventEmitter.emit('split_payment.boleto.expired', {
      splitPaymentId: updated.splitPaymentId,
      orderId: updated.orderId,
      boletoInvoiceId: updated.boletoInvoiceId,
      expiredAt,
      pixStatus: updated.pixStatus === 'CONFIRMED' ? 'confirmed' : 'pending',
      correlationId: resolvedCorrelationId,
    });

    return this.toResponse(updated);
  }

  async getSplitPayment(
    tenantId: string,
    splitPaymentId: string,
  ): Promise<SplitPaymentResponseDto> {
    const record = await this.requireRecord(tenantId, splitPaymentId);
    return this.toResponse(record);
  }

  private async resolveProviderCustomer(
    tenantId: string,
    customer: SplitPaymentCustomer,
  ): Promise<string> {
    const existing = await this.repository.findCustomerLink(
      tenantId,
      customer.id,
    );

    if (existing) {
      return existing.providerCustomerId;
    }

    const newCustomer = await this.asaas.createCustomer({
      name: customer.name,
      cpfCnpj: customer.document,
      email: customer.email,
      mobilePhone: customer.mobilePhone,
      externalReference: customer.id,
      notificationDisabled: false,
    });

    await this.repository.saveCustomerLink(
      tenantId,
      customer.id,
      newCustomer.id,
    );

    return newCustomer.id;
  }

  private async requireRecord(
    tenantId: string,
    splitPaymentId: string,
  ): Promise<SplitPaymentRecord> {
    const record = await this.repository.findById(tenantId, splitPaymentId);

    if (!record) {
      throw new NotFoundException(`SplitPayment ${splitPaymentId} not found`);
    }

    return record;
  }

  private validateCreateDto(
    dto: CreateSplitPaymentDto,
    idempotencyKey: string,
  ): void {
    if (!idempotencyKey?.trim()) {
      throw new BadRequestException('Idempotency-Key header is required');
    }

    if (!dto.tenantId?.trim()) {
      throw new BadRequestException('tenantId is required');
    }

    if (!dto.orderId?.trim()) {
      throw new BadRequestException('orderId is required');
    }

    if (!dto.customer?.id?.trim()) {
      throw new BadRequestException('customer.id is required');
    }

    const pixAmount = Number(dto.pixAmount);
    const boletoAmount = Number(dto.boletoAmount);
    const totalAmount = Number(dto.totalAmount);

    if (
      !Number.isFinite(pixAmount) ||
      !Number.isFinite(boletoAmount) ||
      !Number.isFinite(totalAmount)
    ) {
      throw new BadRequestException(
        'pixAmount, boletoAmount, and totalAmount must be valid numbers',
      );
    }

    if (Math.abs(pixAmount + boletoAmount - totalAmount) > 0.001) {
      throw new BadRequestException(
        'pixAmount + boletoAmount must equal totalAmount',
      );
    }
  }

  private toResponse(record: SplitPaymentRecord): SplitPaymentResponseDto {
    return {
      splitPaymentId: record.splitPaymentId,
      orderId: record.orderId,
      status: record.status,
      totalAmount: record.totalAmount,
      pix: {
        invoiceId: record.pixInvoiceId,
        amount: record.pixAmount,
        status: record.pixStatus,
        confirmedAt: record.pixConfirmedAt ?? null,
      },
      boleto: {
        invoiceId: record.boletoInvoiceId,
        amount: record.boletoAmount,
        dueDate: record.boletoDueDate,
        status: record.boletoStatus,
        confirmedAt: record.boletoConfirmedAt ?? null,
      },
      createdAt: record.createdAt,
      completedAt: record.completedAt ?? null,
    };
  }
}
