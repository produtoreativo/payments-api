import {
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Post,
} from '@nestjs/common';
import { SplitPaymentService } from './split-payment.service';

@Controller('webhooks/split-payment')
export class SplitPaymentWebhookController {
  constructor(private readonly splitPaymentService: SplitPaymentService) {}

  @Post('pix/:splitPaymentId')
  @HttpCode(HttpStatus.OK)
  async confirmPix(
    @Param('splitPaymentId') splitPaymentId: string,
    @Headers('x-tenant-id') tenantId: string,
    @Headers('x-correlation-id') correlationId?: string,
  ) {
    return this.splitPaymentService.confirmPix(
      tenantId,
      splitPaymentId,
      correlationId,
    );
  }

  @Post('boleto/:splitPaymentId')
  @HttpCode(HttpStatus.OK)
  async confirmBoleto(
    @Param('splitPaymentId') splitPaymentId: string,
    @Headers('x-tenant-id') tenantId: string,
    @Headers('x-correlation-id') correlationId?: string,
  ) {
    return this.splitPaymentService.confirmBoleto(
      tenantId,
      splitPaymentId,
      correlationId,
    );
  }

  @Post('boleto/:splitPaymentId/expire')
  @HttpCode(HttpStatus.OK)
  async expireBoleto(
    @Param('splitPaymentId') splitPaymentId: string,
    @Headers('x-tenant-id') tenantId: string,
    @Headers('x-correlation-id') correlationId?: string,
  ) {
    return this.splitPaymentService.expireBoleto(
      tenantId,
      splitPaymentId,
      correlationId,
    );
  }
}
