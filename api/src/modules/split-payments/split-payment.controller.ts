import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiTokenGuard } from '../auth/api-token.guard';
import {
  CreateSplitPaymentDto,
  SplitPaymentService,
} from './split-payment.service';

@UseGuards(ApiTokenGuard)
@Controller('split-payments')
export class SplitPaymentController {
  constructor(private readonly splitPaymentService: SplitPaymentService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createSplitPayment(
    @Body() dto: CreateSplitPaymentDto,
    @Headers('idempotency-key') idempotencyKey: string,
    @Headers('x-correlation-id') correlationId?: string,
  ) {
    return this.splitPaymentService.createSplitPayment(
      dto,
      idempotencyKey,
      correlationId,
    );
  }

  @Get(':splitPaymentId')
  @HttpCode(HttpStatus.OK)
  async getSplitPayment(
    @Param('splitPaymentId') splitPaymentId: string,
    @Headers('x-tenant-id') tenantId: string,
  ) {
    return this.splitPaymentService.getSplitPayment(tenantId, splitPaymentId);
  }
}
