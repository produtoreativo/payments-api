/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import { Injectable, Logger } from '@nestjs/common';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { AsaasWebhookDto } from './dto/asaas-webhook.dto';
import { DynamoService } from './infra/dynamo.service';
import { AsaasService } from './infra/asaas.service';
import { SqsService } from './infra/sqs.service';
import { v4 as uuid } from 'uuid';

@Injectable()
export class AppService {
  constructor(
    private readonly dynamo: DynamoService,
    private readonly asaas: AsaasService,
    private readonly sqs: SqsService,
    private readonly logger: Logger,
  ) {}

  async createPayment(dto: CreatePaymentDto) {
    const customerPk = `TENANT#${dto.tenantId}`;
    const customerSk = `CUSTOMER#${dto.customer.externalId}`;

    console.log({
      table: 'CustomersTable',
      PK: customerPk,
      SK: customerSk,
    });

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
        createdAt: new Date().toISOString(),
      };

      await this.dynamo.putItem('CustomersTable', customer);
    }

    const asaasPayment = await this.asaas.createPayment({
      name: dto.customer.name,
      description: dto.description,
      dueDateLimitDays: 10,
      externalReference: dto.customer.externalId,
      billingType: 'UNDEFINED',
      chargeType: 'DETACHED',
      value: dto.amount,
    });

    const paymentId = uuid();

    const payment = {
      PK: `TENANT#${dto.tenantId}`,
      SK: `PAYMENT#${paymentId}`,
      asaasPaymentId: asaasPayment.id,
      status: asaasPayment.status,
      amount: dto.amount,
      payload: asaasPayment,
      createdAt: new Date().toISOString(),
    };

    await this.dynamo.putItem('PaymentsTable', payment);

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
      receivedAt: new Date().toISOString(),
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
  }
}
