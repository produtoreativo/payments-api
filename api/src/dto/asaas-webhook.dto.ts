export class AsaasWebhookDto {
  event: string;
  payment: {
    id: string;
    status: string;
    value: number;
    customer: string;
  };
}