/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-return */
import { Injectable } from '@nestjs/common';
import axios from 'axios';
import {
  ProviderChargeRequest,
  ProviderChargeResponse,
} from '../modules/invoices/types/invoice.types';

@Injectable()
export class AsaasService {
  private api = axios.create({
    baseURL: this.baseUrl(),
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
      'user-agent': process.env.ASAAS_USER_AGENT ?? 'payments-api',
      access_token: process.env.ASAAS_TOKEN,
    },
  });

  async createCustomer(payload: {
    name: string;
    cpfCnpj: string;
    email?: string;
    mobilePhone?: string;
    externalReference: string;
    notificationDisabled?: boolean;
  }): Promise<{ id: string } & Record<string, unknown>> {
    if (this.mockEnabled()) {
      return {
        id: `cus_mock_${payload.externalReference}`,
        object: 'customer',
        name: payload.name,
        cpfCnpj: payload.cpfCnpj,
        externalReference: payload.externalReference,
      };
    }

    try {
      const { data } = await this.api.post<{ id: string }>(
        '/customers',
        payload,
      );
      return data;
    } catch (error) {
      throw new Error(this.extractErrorMessage(error));
    }
  }

  async createCharge(
    payload: ProviderChargeRequest,
  ): Promise<ProviderChargeResponse> {
    if (this.mockEnabled()) {
      const id = `pay_mock_${payload.externalReference}`;
      const isBoleto = payload.billingType === 'BOLETO';
      const bankSlipUrl = isBoleto
        ? `https://sandbox.asaas.com/b/pdf/${id}`
        : undefined;
      const identificationField = isBoleto
        ? `34191.75402 01234.567890 12345.678901 9 10000000250000`
        : undefined;
      return {
        id,
        status: 'PENDING',
        value: payload.value,
        dueDate: payload.dueDate,
        billingType: payload.billingType,
        externalReference: payload.externalReference,
        invoiceUrl: `https://sandbox.asaas.com/i/${id}`,
        bankSlipUrl,
        identificationField,
        payload: {
          id,
          object: 'payment',
          status: 'PENDING',
          invoiceUrl: `https://sandbox.asaas.com/i/${id}`,
          bankSlipUrl,
          identificationField,
          ...payload,
        },
      };
    }

    try {
      const { data } = await this.api.post('/payments', payload);
      return {
        id: data.id,
        status: data.status,
        value: data.value,
        dueDate: data.dueDate,
        billingType: data.billingType,
        externalReference: data.externalReference,
        invoiceUrl: data.invoiceUrl,
        bankSlipUrl: data.bankSlipUrl,
        identificationField: data.identificationField,
        transactionReceiptUrl: data.transactionReceiptUrl,
        payload: data,
      };
    } catch (error) {
      throw new Error(this.extractErrorMessage(error));
    }
  }

  async cancelCharge(providerPaymentId: string) {
    if (this.mockEnabled()) {
      if (providerPaymentId.startsWith('pay_mock_force404_')) {
        const err = new Error('invalid_action: Payment not found') as Error & {
          status?: number;
        };
        err.status = 404;
        throw err;
      }
      return {
        id: providerPaymentId,
        status: 'DELETED',
      };
    }

    try {
      const { data } = await this.api.delete(`/payments/${providerPaymentId}`);
      return data ?? { id: providerPaymentId, status: 'DELETED' };
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const message = this.extractErrorMessage(error);
        const providerError = new Error(message) as Error & {
          status?: number;
        };
        providerError.status = error.response?.status;
        throw providerError;
      }

      throw error;
    }
  }

  async confirmSandboxPayment(providerPaymentId: string) {
    if (this.mockEnabled()) {
      return {
        id: providerPaymentId,
        status: 'CONFIRMED',
      };
    }

    try {
      const { data } = await this.api.post(
        `/sandbox/payment/${providerPaymentId}/confirm`,
        {},
      );
      return data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const message = this.extractErrorMessage(error);
        const providerError = new Error(message) as Error & {
          status?: number;
        };
        providerError.status = error.response?.status;
        throw providerError;
      }

      throw error;
    }
  }

  private baseUrl(): string {
    const url = process.env.ASAAS_URL ?? 'https://api-sandbox.asaas.com/v3';
    return url.endsWith('/v3') ? url : `${url.replace(/\/$/, '')}/v3`;
  }

  private mockEnabled(): boolean {
    return process.env.ASAAS_MOCK === 'true';
  }

  private extractErrorMessage(error: unknown): string {
    if (!axios.isAxiosError(error)) {
      return error instanceof Error ? error.message : 'Unknown Asaas error';
    }

    const errors = error.response?.data?.errors;

    if (Array.isArray(errors) && errors.length > 0) {
      return errors
        .map((item) => `${item.code}: ${item.description}`)
        .join('; ');
    }

    return error.message;
  }
}
