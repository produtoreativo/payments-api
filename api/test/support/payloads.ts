import { TENANT_ID } from './app-fixture';

export const PIX_INVOICE_PAYLOAD = {
  tenantId: TENANT_ID,
  orderId: 'MS-100045',
  customer: {
    id: 'customer-123',
    name: 'Maria Silva',
    document: '12345678909',
    email: 'maria@example.com',
    mobilePhone: '11987654321',
  },
  amount: 159.9,
  currency: 'BRL',
  dueDate: '2027-12-31',
  billingType: 'PIX',
  provider: 'ASAAS',
  description: 'Pedido MS-100045',
};
