export class CreatePaymentDto {
  tenantId: string;
  amount: number;
  description: string;
  customer: {
    externalId: string;
    name: string;
    email: string;
    cpfCnpj: string;
  };
}
