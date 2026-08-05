export type SplitPaymentStatus =
  | 'PENDING_BOTH'
  | 'PIX_CONFIRMED'
  | 'BOLETO_CONFIRMED'
  | 'COMPLETED'
  | 'PENDING_INVESTIGATION';

export type PixStatus = 'PENDING' | 'CONFIRMED';
export type BoletoStatus = 'PENDING' | 'CONFIRMED' | 'EXPIRED';

export interface SplitPaymentCustomer {
  id: string;
  name: string;
  document: string;
  email?: string;
  mobilePhone?: string;
}

export interface SplitPaymentRecord {
  splitPaymentId: string;
  tenantId: string;
  orderId: string;
  totalAmount: number;
  currency: string;
  pixAmount: number;
  pixInvoiceId: string;
  pixStatus: PixStatus;
  pixConfirmedAt?: string;
  boletoAmount: number;
  boletoInvoiceId: string;
  boletoDueDate: string;
  boletoStatus: BoletoStatus;
  boletoConfirmedAt?: string;
  status: SplitPaymentStatus;
  correlationId: string;
  customer: SplitPaymentCustomer;
  createdAt: string;
  updatedAt: string;
  completedAt?: string;
}
