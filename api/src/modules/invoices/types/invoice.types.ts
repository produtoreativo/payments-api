export type PaymentProvider = 'ITAU' | 'ASAAS';

export type BillingType = 'BOLETO' | 'PIX' | 'CREDIT_CARD' | 'UNDEFINED';

export type InvoiceStatus =
  | 'CREATED'
  | 'PROVIDER_PENDING'
  | 'OPEN'
  | 'CONFIRMED'
  | 'RECEIVED'
  | 'REFUND_REQUESTED'
  | 'CANCEL_REQUESTED'
  | 'CANCELLED'
  | 'CANCEL_RECONCILIATION_REQUIRED'
  | 'FAILED'
  | 'CHARGEBACK_REQUESTED'
  | 'CHARGEBACK_DISPUTE'
  | 'CHARGEBACK_REVERSAL_PENDING';

export interface InvoiceCustomer {
  id: string;
  name: string;
  document: string;
  email?: string;
  mobilePhone?: string;
}

export interface InvoiceRecord {
  invoiceId: string;
  tenantId: string;
  orderId: string;
  customer: InvoiceCustomer;
  amount: number;
  currency: string;
  dueDate: string;
  billingType: BillingType;
  provider: PaymentProvider;
  providerPaymentId?: string;
  status: InvoiceStatus;
  description?: string;
  externalReference: string;
  paymentUrl?: string;
  hostedPaymentUrl?: string;
  bankSlipUrl?: string;
  identificationField?: string;
  providerPayload?: unknown;
  failureReason?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CustomerProviderLink {
  tenantId: string;
  customerId: string;
  provider: PaymentProvider;
  providerCustomerId: string;
  createdAt: string;
  updatedAt: string;
}

export interface ProviderChargeRequest {
  customer: string;
  billingType: BillingType;
  value: number;
  dueDate: string;
  description: string;
  externalReference: string;
}

export interface ProviderChargeResponse {
  id: string;
  status: string;
  value?: number;
  dueDate?: string;
  billingType?: BillingType;
  externalReference?: string;
  invoiceUrl?: string;
  bankSlipUrl?: string;
  identificationField?: string;
  transactionReceiptUrl?: string;
  payload: unknown;
}
