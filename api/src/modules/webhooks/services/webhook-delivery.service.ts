import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { createHmac, randomUUID } from 'crypto';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { WebhookRepository, WebhookRecord } from './webhook-repository.service';
import type { WebhookEventType } from '../dto/create-webhook.dto';
import { PaymentsEvent } from '../../../events/payments-events';

interface PaymentConfirmedEvent {
  invoiceId: string;
  orderId: string;
  tenantId: string;
  amount: number;
  currency?: string;
  providerPaymentId?: string;
  confirmedAt?: string;
}

interface PaymentCancelledEvent {
  invoiceId: string;
  orderId: string;
  tenantId: string;
  amount?: number;
  currency?: string;
}

interface InvoiceExpiredEvent {
  invoiceId: string;
  orderId: string;
  tenantId: string;
  amount?: number;
  currency?: string;
  billingType?: string;
  dueDate?: string;
  expiredAt?: string;
}

const DELIVERY_TIMEOUT_MS = 10_000;

@Injectable()
export class WebhookDeliveryService {
  private readonly logger = new Logger(WebhookDeliveryService.name);

  constructor(
    private readonly repository: WebhookRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  @OnEvent(PaymentsEvent.InvoiceConfirmed, { async: true })
  async onPaymentConfirmed(event: PaymentConfirmedEvent): Promise<void> {
    if (!event.tenantId) return;

    await this.deliver('invoice.confirmed', event.tenantId, {
      invoiceId: event.invoiceId,
      orderId: event.orderId,
      providerPaymentId: event.providerPaymentId,
      amount: event.amount,
      currency: event.currency ?? 'BRL',
      status: 'CONFIRMED',
      confirmedAt: event.confirmedAt ?? new Date().toISOString(),
    });
  }

  @OnEvent(PaymentsEvent.InvoiceCancelled, { async: true })
  async onPaymentCancelled(event: PaymentCancelledEvent): Promise<void> {
    if (!event.tenantId) return;

    await this.deliver('invoice.cancelled', event.tenantId, {
      invoiceId: event.invoiceId,
      orderId: event.orderId,
      amount: event.amount,
      currency: event.currency ?? 'BRL',
      status: 'CANCELLED',
      cancelledAt: new Date().toISOString(),
    });
  }

  /**
   * Boleto vencido (BS-006): reaproveita o tipo externo `invoice.cancelled`,
   * distinguido por `status: EXPIRED` e `reason: BOLETO_OVERDUE`.
   */
  // Sem `{ async: true }` de propósito: o emissor usa emitAsync e precisa aguardar a entrega
  // (o worker SQS não pode terminar antes dela).
  @OnEvent(PaymentsEvent.InvoiceExpired)
  async onInvoiceExpired(event: InvoiceExpiredEvent): Promise<void> {
    if (!event.tenantId) return;

    await this.deliver('invoice.cancelled', event.tenantId, {
      invoiceId: event.invoiceId,
      orderId: event.orderId,
      amount: event.amount,
      currency: event.currency ?? 'BRL',
      billingType: event.billingType ?? 'BOLETO',
      dueDate: event.dueDate,
      status: 'EXPIRED',
      reason: 'BOLETO_OVERDUE',
      cancelledAt: event.expiredAt ?? new Date().toISOString(),
    });
  }

  private async deliver(
    eventType: WebhookEventType,
    tenantId: string,
    payload: Record<string, unknown>,
  ): Promise<void> {
    let webhooks: WebhookRecord[];

    try {
      webhooks = await this.repository.findActiveByTenantId(tenantId);
    } catch (err: unknown) {
      this.logger.error({
        msg: 'webhook.delivery: failed to load webhooks',
        tenantId,
        err: err instanceof Error ? err.message : String(err),
      });
      return;
    }

    const eligible: WebhookRecord[] = webhooks.filter((wh) =>
      wh.events.includes(eventType),
    );

    for (const webhook of eligible) {
      const deliveryId = randomUUID();
      const body = JSON.stringify({
        deliveryId,
        webhookId: webhook.webhookId,
        event: eventType,
        tenantId,
        timestamp: new Date().toISOString(),
        payload,
      });

      const signature = `sha256=${createHmac('sha256', webhook.secret).update(body).digest('hex')}`;
      const start = Date.now();

      try {
        const response = await this.postWithTimeout(
          webhook.url,
          body,
          signature,
          deliveryId,
        );
        const durationMs = Date.now() - start;

        if (response.ok) {
          this.eventEmitter.emit('payments.observability', {
            event_key: 'webhook.delivery.sent',
            tenantId,
            webhookId: webhook.webhookId,
            event: eventType,
            deliveryId,
            durationMs,
          });
        } else {
          this.eventEmitter.emit('payments.observability', {
            event_key: 'webhook.delivery.failed',
            tenantId,
            webhookId: webhook.webhookId,
            event: eventType,
            deliveryId,
            statusCode: response.status,
            reason: 'non_2xx_response',
          });
        }
      } catch (err) {
        this.eventEmitter.emit('payments.observability', {
          event_key: 'webhook.delivery.failed',
          tenantId,
          webhookId: webhook.webhookId,
          event: eventType,
          deliveryId,
          statusCode: 0,
          reason: err instanceof Error ? err.message : 'unknown_error',
        });
      }
    }
  }

  private async postWithTimeout(
    url: string,
    body: string,
    signature: string,
    deliveryId: string,
  ): Promise<Response> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), DELIVERY_TIMEOUT_MS);

    try {
      return await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Payments-Signature': signature,
          'X-Payments-Delivery-Id': deliveryId,
        },
        body,
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }
  }
}
