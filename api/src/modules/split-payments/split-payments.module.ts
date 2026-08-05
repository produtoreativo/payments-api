import { Module } from '@nestjs/common';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { DynamoService } from '../../infra/dynamo.service';
import { AsaasService } from '../../infra/asaas.service';
import { AuthModule } from '../auth/auth.module';
import { SplitPaymentController } from './split-payment.controller';
import { SplitPaymentWebhookController } from './split-payment-webhook.controller';
import { SplitPaymentService } from './split-payment.service';
import { SplitPaymentRepository } from './split-payment-repository.service';

@Module({
  imports: [EventEmitterModule, AuthModule],
  controllers: [SplitPaymentController, SplitPaymentWebhookController],
  providers: [
    SplitPaymentService,
    SplitPaymentRepository,
    DynamoService,
    AsaasService,
  ],
  exports: [SplitPaymentService, SplitPaymentRepository],
})
export class SplitPaymentsModule {}
