export class InvoiceResponseDto {
  invoiceId: string;
  orderId: string;
  provider: string;
  providerPaymentId: string;
  status: string;
  amount: number;
  currency: string;
  billingType: string;
  dueDate: string;
  paymentUrl?: string;
  hostedPaymentUrl?: string;
  bankSlipUrl?: string;
  identificationField?: string;
  externalReference: string;
}
