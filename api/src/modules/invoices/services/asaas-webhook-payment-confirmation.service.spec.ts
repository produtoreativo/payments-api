/**
 * DS-39 — Confirmação de Pagamento por Webhook (work-item #106)
 *
 * TDD spec covering the BDD scenarios from
 * prodops/artifacts/bdd/payment-confirmation.feature
 *
 * Red → Green cycle target:
 *   - Canonical `payment.received` event emitted on PAYMENT_RECEIVED webhook
 *   - `payment.confirmed` NOT re-emitted on duplicate PAYMENT_CONFIRMED
 *   - Token rejection never exposes the token value in logs/events
 *   - PAYMENT_OVERDUE does not emit `payment.confirmed`
 */

import { UnauthorizedException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Test, TestingModule } from '@nestjs/testing';
import { AsaasWebhookDto } from '../../../dto/asaas-webhook.dto';
import { AsaasService } from '../../../infra/asaas.service';
import { InvoiceRecord } from '../types/invoice.types';
import { InvoiceRepository } from './invoice-repository.service';
import { InvoiceService } from './invoice.service';
import { ProviderRouterService } from './provider-router.service';

const TENANT_ID = 'tenant-ms-siara';

const makeOpenInvoice = (): InvoiceRecord => ({
  invoiceId: 'inv-100045',
  tenantId: TENANT_ID,
  orderId: 'MS-100045',
  customer: { id: 'cust-1', name: 'Maria Silva', document: '12345678909' },
  amount: 159.9,
  currency: 'BRL',
  dueDate: '2026-12-31',
  billingType: 'PIX',
  provider: 'ASAAS',
  status: 'OPEN',
  providerPaymentId: 'pay_asaas_123',
  externalReference: 'MS-100045',
  createdAt: '2026-08-01T00:00:00.000Z',
  updatedAt: '2026-08-01T00:00:00.000Z',
});

const makeConfirmedInvoice = (): InvoiceRecord => ({
  ...makeOpenInvoice(),
  status: 'CONFIRMED',
});

const makeReceivedInvoice = (): InvoiceRecord => ({
  ...makeOpenInvoice(),
  status: 'RECEIVED',
});

const makePaymentConfirmedWebhook = (): AsaasWebhookDto => ({
  event: 'PAYMENT_CONFIRMED',
  payment: {
    id: 'pay_asaas_123',
    status: 'CONFIRMED',
    confirmedDate: '2026-08-01',
    externalReference: 'MS-100045',
  },
});

const makePaymentReceivedWebhook = (): AsaasWebhookDto => ({
  event: 'PAYMENT_RECEIVED',
  payment: {
    id: 'pay_asaas_123',
    status: 'RECEIVED',
    paymentDate: '2026-08-01',
    externalReference: 'MS-100045',
  },
});

describe('DS-39 — Confirmação de Pagamento por Webhook', () => {
  let service: InvoiceService;
  let repository: jest.Mocked<InvoiceRepository>;
  let eventEmitter: jest.Mocked<EventEmitter2>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InvoiceService,
        {
          provide: InvoiceRepository,
          useValue: {
            findByIdempotencyKey: jest.fn(),
            saveInvoice: jest.fn(),
            updateInvoice: jest.fn(),
            findCustomerLink: jest.fn(),
            saveIdempotencyKey: jest.fn(),
            findByProviderPaymentId: jest.fn(),
            findByExternalReference: jest.fn(),
            saveRawProviderEvent: jest.fn(),
            hasRawProviderEvent: jest.fn(),
          },
        },
        {
          provide: ProviderRouterService,
          useValue: { resolve: jest.fn().mockReturnValue('ASAAS') },
        },
        {
          provide: AsaasService,
          useValue: { createCharge: jest.fn(), createCustomer: jest.fn() },
        },
        {
          provide: EventEmitter2,
          useValue: { emit: jest.fn().mockReturnValue(true) },
        },
      ],
    }).compile();

    service = module.get(InvoiceService);
    repository = module.get(InvoiceRepository);
    eventEmitter = module.get(EventEmitter2);
  });

  // -------------------------------------------------------------------------
  // Cenário 1: PAYMENT_CONFIRMED — confirma pagamento e publica evento canônico
  // -------------------------------------------------------------------------
  describe('Cenário 1: PAYMENT_CONFIRMED — confirma pagamento (BDD scenario 1)', () => {
    beforeEach(() => {
      repository.saveRawProviderEvent.mockResolvedValue(true);
      repository.findByProviderPaymentId.mockResolvedValue(makeOpenInvoice());
      repository.updateInvoice.mockResolvedValue(makeConfirmedInvoice());
    });

    it('publica o evento canônico payment.confirmed com campos obrigatórios', async () => {
      await service.processProviderWebhook(
        makePaymentConfirmedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      const calls = (eventEmitter.emit as jest.Mock).mock.calls as [
        string,
        Record<string, unknown>,
      ][];
      const confirmedCall = calls.find(
        ([name]) => name === 'payment.confirmed',
      );
      expect(confirmedCall).toBeDefined();
      const payload = confirmedCall![1];
      expect(payload.invoiceId).toBe('inv-100045');
      expect(payload.orderId).toBe('MS-100045');
      expect(payload.provider).toBe('ASAAS');
      expect(payload.providerPaymentId).toBe('pay_asaas_123');
      expect(typeof payload.confirmedAt).toBe('string');
    });

    it('persiste o evento bruto antes de processar', async () => {
      const callOrder: string[] = [];
      repository.saveRawProviderEvent.mockImplementation(() => {
        callOrder.push('saveRawProviderEvent');
        return Promise.resolve(true);
      });
      repository.updateInvoice.mockImplementation(() => {
        callOrder.push('updateInvoice');
        return Promise.resolve(makeConfirmedInvoice());
      });

      await service.processProviderWebhook(
        makePaymentConfirmedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      const saveIndex = callOrder.indexOf('saveRawProviderEvent');
      const updateIndex = callOrder.indexOf('updateInvoice');
      expect(saveIndex).toBeGreaterThanOrEqual(0);
      expect(updateIndex).toBeGreaterThan(saveIndex);
    });

    it('atualiza a invoice para status CONFIRMED', async () => {
      await service.processProviderWebhook(
        makePaymentConfirmedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.updateInvoice).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'OPEN' }),
        'CONFIRMED',
        expect.anything(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Cenário 2: PAYMENT_RECEIVED — concilia financeiramente sem liberar pedido
  // -------------------------------------------------------------------------
  describe('Cenário 2: PAYMENT_RECEIVED — conciliação financeira (BDD scenario 2)', () => {
    beforeEach(() => {
      repository.saveRawProviderEvent.mockResolvedValue(true);
      repository.findByProviderPaymentId.mockResolvedValue(
        makeConfirmedInvoice(),
      );
      repository.updateInvoice.mockResolvedValue(makeReceivedInvoice());
    });

    it('publica o evento canônico payment.received para conciliação financeira', async () => {
      await service.processProviderWebhook(
        makePaymentReceivedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      const calls = (eventEmitter.emit as jest.Mock).mock.calls as [
        string,
        Record<string, unknown>,
      ][];
      const receivedCall = calls.find(([name]) => name === 'payment.received');
      expect(receivedCall).toBeDefined();
      const payload = receivedCall![1];
      expect(payload.invoiceId).toBe('inv-100045');
      expect(payload.orderId).toBe('MS-100045');
      expect(payload.tenantId).toBe(TENANT_ID);
      expect(payload.provider).toBe('ASAAS');
      expect(payload.providerPaymentId).toBe('pay_asaas_123');
      expect(typeof payload.receivedAt).toBe('string');
    });

    it('nao publica payment.confirmed novamente no PAYMENT_RECEIVED', async () => {
      await service.processProviderWebhook(
        makePaymentReceivedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      const confirmedCalls = (eventEmitter.emit as jest.Mock).mock.calls.filter(
        ([eventName]: [string]) => eventName === 'payment.confirmed',
      );
      expect(confirmedCalls).toHaveLength(0);
    });

    it('atualiza a invoice para status RECEIVED', async () => {
      await service.processProviderWebhook(
        makePaymentReceivedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.updateInvoice).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'CONFIRMED' }),
        'RECEIVED',
        expect.anything(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Cenário 3: Token inválido — rejeita sem alterar estado
  // -------------------------------------------------------------------------
  describe('Cenário 3: Token inválido — rejeição segura (BDD scenario 3)', () => {
    beforeEach(() => {
      process.env.ASAAS_WEBHOOK_TOKEN = 'valid-secret-token';
    });

    afterEach(() => {
      delete process.env.ASAAS_WEBHOOK_TOKEN;
    });

    it('lança UnauthorizedException para token inválido', () => {
      expect(() => service.validateProviderWebhookToken('wrong-token')).toThrow(
        UnauthorizedException,
      );
    });

    it('não expõe o token recebido no evento de rejeição', () => {
      try {
        service.validateProviderWebhookToken('secret-value-must-not-leak');
      } catch {
        // expected
      }

      const allEmitCalls = (eventEmitter.emit as jest.Mock).mock.calls as [
        string,
        Record<string, unknown>,
      ][];
      const rejectionCall = allEmitCalls.find(
        ([eventName]) => eventName === 'payments.security.webhook_rejected',
      );
      expect(rejectionCall).toBeDefined();
      const payload = rejectionCall![1];
      expect(JSON.stringify(payload)).not.toContain(
        'secret-value-must-not-leak',
      );
    });

    it('não altera estado da invoice ao rejeitar token', async () => {
      try {
        await service.processProviderWebhook(
          makePaymentConfirmedWebhook(),
          'wrong-token',
        );
      } catch {
        // expected UnauthorizedException
      }

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.updateInvoice).not.toHaveBeenCalled();
    });
  });

  // -------------------------------------------------------------------------
  // Cenário 4: Webhook duplicado — deduplicação sem republica payment.confirmed
  // -------------------------------------------------------------------------
  describe('Cenário 4: Webhook duplicado — deduplicação (BDD scenario 4)', () => {
    beforeEach(() => {
      // saveRawProviderEvent returns false = event already processed (duplicate)
      repository.saveRawProviderEvent.mockResolvedValue(false);
      repository.findByProviderPaymentId.mockResolvedValue(
        makeConfirmedInvoice(),
      );
    });

    it('não publica payment.confirmed ao receber webhook duplicado', async () => {
      await service.processProviderWebhook(
        makePaymentConfirmedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      const confirmedCalls = (eventEmitter.emit as jest.Mock).mock.calls.filter(
        ([eventName]: [string]) => eventName === 'payment.confirmed',
      );
      expect(confirmedCalls).toHaveLength(0);
    });

    it('retorna sucesso técnico ao reconhecer webhook duplicado', async () => {
      const result = await service.processProviderWebhook(
        makePaymentConfirmedWebhook(),
        undefined,
        { skipTokenValidation: true },
      );

      // Returns the existing confirmed invoice without error
      expect(result).toBeDefined();
      expect(result?.status).toBe('CONFIRMED');
    });
  });

  // -------------------------------------------------------------------------
  // Cenário 5: Webhook antes da consolidação — correlação por externalReference
  // -------------------------------------------------------------------------
  describe('Cenário 5: Correlação por externalReference (BDD scenario 5)', () => {
    it('localiza invoice por externalReference quando providerPaymentId nao encontrado', async () => {
      const earlyWebhook: AsaasWebhookDto = {
        event: 'PAYMENT_CONFIRMED',
        payment: {
          id: 'pay_asaas_999',
          externalReference: 'MS-100045',
          status: 'CONFIRMED',
          confirmedDate: '2026-08-01',
        },
      };

      // Invoice not found by providerPaymentId (not yet consolidated)
      repository.saveRawProviderEvent.mockResolvedValue(true);
      repository.findByProviderPaymentId.mockResolvedValue(undefined);
      // But found by externalReference
      repository.findByExternalReference.mockResolvedValue(makeOpenInvoice());
      repository.updateInvoice.mockResolvedValue(makeConfirmedInvoice());

      await service.processProviderWebhook(earlyWebhook, undefined, {
        skipTokenValidation: true,
      });

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.findByExternalReference).toHaveBeenCalledWith(
        'MS-100045',
      );
      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        'payment.confirmed',
        expect.objectContaining({ invoiceId: 'inv-100045' }),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Cenário 6: PAYMENT_OVERDUE — ignorado, sem liberar pedido
  // -------------------------------------------------------------------------
  describe('Cenário 6: PAYMENT_OVERDUE — evento ignorado (BDD scenario 6)', () => {
    it('nao publica payment.confirmed para PAYMENT_OVERDUE', async () => {
      const overdueWebhook: AsaasWebhookDto = {
        event: 'PAYMENT_OVERDUE',
        payment: { id: 'pay_asaas_123', status: 'OVERDUE' },
      };

      repository.saveRawProviderEvent.mockResolvedValue(true);
      repository.findByProviderPaymentId.mockResolvedValue(makeOpenInvoice());

      await service.processProviderWebhook(overdueWebhook, undefined, {
        skipTokenValidation: true,
      });

      const confirmedCalls = (eventEmitter.emit as jest.Mock).mock.calls.filter(
        ([eventName]: [string]) => eventName === 'payment.confirmed',
      );
      expect(confirmedCalls).toHaveLength(0);
    });
  });
});
