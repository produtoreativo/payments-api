import { Body, Controller, Get, Logger, Post } from '@nestjs/common';
import { AppService } from './app.service';
import { AsaasWebhookDto } from './dto/asaas-webhook.dto';
import { CreatePaymentDto } from './dto/create-payment.dto';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly logger: Logger,
  ) {}

  @Post('/payments')
  async createPayment(@Body() dto: CreatePaymentDto) {
    return this.appService.createPayment(dto);
  }

  @Post('/webhook/payments')
  async receiveWebhook(@Body() payload: AsaasWebhookDto) {
    console.log('Received Asaas webhook [0]');
    this.logger.log('Received Asaas webhook [1]');
    this.logger.log('Received Asaas webhook', JSON.stringify(payload));
    await this.appService.enqueueWebhook(payload);
    return { received: true };
  }

  @Get('/queue/process')
  async processQueue(@Body() payload: any) {
    await this.appService.processTransaction(payload);
    return { processed: true };
  }
}
