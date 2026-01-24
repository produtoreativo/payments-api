/* eslint-disable @typescript-eslint/no-unsafe-member-access */
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

  async createPayment(payload: any, eventEmitter) {
    try {
      const { data } = await this.api.post('/v3/paymentLinks', payload);
      return data;
    } catch (error) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      eventEmitter.emit('payments.invoice.psp_not_integrated', {
        timestamp: new Date(),
        payload: { message: error.message },
      });
      return null;
    }
  }
}
