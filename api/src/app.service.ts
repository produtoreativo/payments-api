/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { AsaasWebhookDto } from './dto/asaas-webhook.dto';
import { DynamoService } from './infra/dynamo.service';
import { AsaasService } from './infra/asaas.service';
import { SqsService } from './infra/sqs.service';
import { ulid } from 'ulid';
@Injectable()
export class AppService {
  constructor(
    private readonly dynamo: DynamoService,
    private readonly asaas: AsaasService,
    private readonly sqs: SqsService,
    private readonly logger: Logger,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async createPayment(dto: CreatePaymentDto) {
    const customerPk = `TENANT#${dto.tenantId}`;
    const customerSk = `CUSTOMER#${dto.customer.externalId}`;

    let customer = await this.dynamo.getItem(
      'CustomersTable',
      customerPk,
      customerSk,
    );

    if (!customer) {
      customer = {
        PK: customerPk,
        SK: customerSk,
        ...dto.customer,
        createdAt: new Date(new Date().toUTCString()).toISOString(),
      };
      this.eventEmitter.emit('payments.invoice.customer_not_found', {
        customerId: dto.customer.externalId,
        timestamp: new Date(new Date().toUTCString()).toISOString(),
        payload: { tenantId: dto.tenantId, customer: dto.customer },
      });

      await this.dynamo.putItem('CustomersTable', customer);
      this.eventEmitter.emit('payments.invoice.customer_created', {
        customerId: dto.customer.externalId,
        timestamp: new Date(new Date().toUTCString()).toISOString(),
        payload: { tenantId: dto.tenantId, customer: dto.customer },
      });
    }

    const asaasPayment = await this.asaas.createPayment(
      {
        name: dto.customer.name,
        description: dto.description,
        dueDateLimitDays: 10,
        externalReference: dto.customer.externalId,
        billingType: 'UNDEFINED',
        chargeType: 'DETACHED',
        value: dto.amount,
      },
      this.eventEmitter,
    );
    this.eventEmitter.emit('payments.invoice.psp_integrated', {
      customerId: dto.customer.externalId,
      timestamp: new Date(new Date().toUTCString()).toISOString(),
      payload: { tenantId: dto.tenantId, customer: dto.customer },
    });

    const paymentId = ulid();

    const payment = {
      PK: `TENANT#${dto.tenantId}`,
      SK: `PAYMENT#${paymentId}`,
      asaasPaymentId: asaasPayment.id,
      status: asaasPayment.status,
      amount: dto.amount,
      payload: asaasPayment,
      createdAt: new Date(new Date().toUTCString()).toISOString(),
    };

    await this.dynamo.putItem('PaymentsTable', payment);
    this.eventEmitter.emit('payments.invoice.pendente', {
      customerId: dto.customer.externalId,
      timestamp: new Date(new Date().toUTCString()).toISOString(),
      payload: { tenantId: dto.tenantId, customer: dto.customer },
    });
    return payment;
  }

  async enqueueWebhook(payload: AsaasWebhookDto) {
    await this.sqs.sendMessage(payload);
  }

  async processTransaction(message: any) {
    const payload: AsaasWebhookDto = JSON.parse(message.body);

    this.logger.log('Received Asaas payload', JSON.stringify(payload));

    const transaction = {
      PK: `PAYMENT#${payload.payment.id}`,
      SK: `EVENT#${payload.event}`,
      status: payload.payment.status,
      receivedAt: new Date(new Date().toUTCString()).toISOString(),
    };

    this.logger.log('Storing transaction', JSON.stringify(transaction));

    await this.dynamo.putItem('TransactionsTable', transaction);

    await this.dynamo.updateItem(
      'PaymentsTable',
      `TENANT#${message.tenantId}`,
      `PAYMENT#${payload.payment.id}`,
      {
        status: payload.payment.status,
      },
    );
    this.eventEmitter.emit('payments.invoice.confirmed', {
      customerId: payload.payment.customer,
      timestamp: new Date(new Date().toUTCString()).toISOString(),
      payload,
    });
  }
}
