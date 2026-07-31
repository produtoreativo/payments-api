import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiTokenGuard } from '../../auth/api-token.guard';
import { InvoiceService } from '../services/invoice.service';
import { CreateInvoiceDto } from '../dto/create-invoice.dto';

@UseGuards(ApiTokenGuard)
@Controller('invoices')
export class InvoiceController {
  constructor(private invoiceService: InvoiceService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createInvoice(
    @Body() createInvoiceDto: CreateInvoiceDto,
    @Headers('idempotency-key') idempotencyKey: string,
    @Headers('x-correlation-id') correlationId?: string,
  ) {
    return await this.invoiceService.createInvoice(
      createInvoiceDto,
      idempotencyKey,
      correlationId,
    );
  }

  @Get(':invoiceId')
  @HttpCode(HttpStatus.OK)
  async getInvoice(
    @Param('invoiceId') invoiceId: string,
    @Headers('x-tenant-id') tenantId: string,
  ) {
    return await this.invoiceService.getInvoice(tenantId, invoiceId);
  }

  @Delete(':invoiceId')
  @HttpCode(HttpStatus.OK)
  async cancelInvoice(
    @Param('invoiceId') invoiceId: string,
    @Headers('x-tenant-id') tenantId: string,
    @Headers('idempotency-key') idempotencyKey: string,
    @Headers('x-correlation-id') correlationId?: string,
  ) {
    return await this.invoiceService.cancelInvoice(
      tenantId,
      invoiceId,
      idempotencyKey,
      correlationId,
    );
  }

  @Post(':invoiceId/refund')
  @HttpCode(HttpStatus.ACCEPTED)
  async requestRefund(
    @Param('invoiceId') invoiceId: string,
    @Headers('x-tenant-id') tenantId: string,
    @Headers('idempotency-key') idempotencyKey: string,
    @Body() body: { reason?: string },
    @Headers('x-correlation-id') correlationId?: string,
  ) {
    return await this.invoiceService.requestRefund(
      tenantId,
      invoiceId,
      idempotencyKey,
      body?.reason,
      correlationId,
    );
  }
}
