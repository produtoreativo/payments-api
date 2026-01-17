/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-return */
import axios from 'axios';

export class AsaasService {
  private api = axios.create({
    baseURL: process.env.ASAAS_URL,
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
      access_token: process.env.ASAAS_TOKEN,
    },
  });

  async createPayment(payload: any) {
    const { data } = await this.api.post('/v3/paymentLinks', payload);
    return data;
  }
}
