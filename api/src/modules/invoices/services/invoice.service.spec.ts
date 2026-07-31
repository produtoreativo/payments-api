import { ServiceUnavailableException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Test, TestingModule } from '@nestjs/testing';
import { AsaasService } from '../../../infra/asaas.service';
import { CreateInvoiceDto } from '../dto/create-invoice.dto';
import { CustomerProviderLink, InvoiceRecord } from '../types/invoice.types';
import { InvoiceRepository } from './invoice-repository.service';
import { InvoiceService } from './invoice.service';
import { ProviderRouterService } from './provider-router.service';

const TENANT_ID = 'tenant-test';

const makeDto = (overrides: Partial<CreateInvoiceDto> = {}): CreateInvoiceDto =>
  ({
    tenantId: TENANT_ID,
    orderId: 'ORD-001',
    customer: {
      id: 'cust-1',
      name: 'Maria Silva',
      document: '12345678909',
      email: 'maria@example.com',
      mobilePhone: '11987654321',
    },
    amount: 250.0,
    currency: 'BRL',
    dueDate: (() => {
      const d = new Date();
      d.setUTCDate(d.getUTCDate() + 3);
      return d.toISOString().slice(0, 10);
    })(),
    billingType: 'BOLETO',
    provider: 'ASAAS',
    ...overrides,
  }) as CreateInvoiceDto;

const makePendingInvoice = (): InvoiceRecord => ({
  invoiceId: 'inv_test',
  tenantId: TENANT_ID,
  orderId: 'ORD-001',
  customer: {
    id: 'cust-1',
    name: 'Maria Silva',
    document: '12345678909',
  },
  amount: 250.0,
  currency: 'BRL',
  dueDate: makeDto().dueDate,
  billingType: 'BOLETO',
  provider: 'ASAAS',
  status: 'PROVIDER_PENDING',
  externalReference: 'inv_test',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

const makeCustomerLink = (): CustomerProviderLink => ({
  tenantId: TENANT_ID,
  customerId: 'cust-1',
  provider: 'ASAAS',
  providerCustomerId: 'cus_asaas_abc',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

describe('InvoiceService — Falhas de provedor Boleto', () => {
  let service: InvoiceService;
  let repository: jest.Mocked<InvoiceRepository>;
  let asaas: jest.Mocked<AsaasService>;
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
          },
        },
        {
          provide: ProviderRouterService,
          useValue: { resolve: jest.fn().mockReturnValue('ASAAS') },
        },
        {
          provide: AsaasService,
          useValue: { createCharge: jest.fn() },
        },
        {
          provide: EventEmitter2,
          useValue: { emit: jest.fn() },
        },
      ],
    }).compile();

    service = module.get(InvoiceService);
    repository = module.get(InvoiceRepository);
    asaas = module.get(AsaasService);
    eventEmitter = module.get(EventEmitter2);

    repository.findByIdempotencyKey.mockResolvedValue(undefined);
    repository.saveInvoice.mockResolvedValue(undefined);
    repository.updateInvoice.mockResolvedValue(makePendingInvoice());
    repository.findCustomerLink.mockResolvedValue(makeCustomerLink());
    eventEmitter.emit.mockReturnValue(true);
  });

  describe('Cenário 7: Falha transiente ao criar boleto no provedor', () => {
    it('marca invoice como PROVIDER_PENDING e lança ServiceUnavailableException', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('timeout calling Asaas'),
      );

      await expect(
        service.createInvoice(makeDto(), 'ORD-001:transient', 'corr-test'),
      ).rejects.toThrow(ServiceUnavailableException);

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.updateInvoice).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'PROVIDER_PENDING' }),
        'PROVIDER_PENDING',
        expect.objectContaining({ failureReason: 'timeout calling Asaas' }),
      );
    });

    it('a exceção não expõe bankSlipUrl nem identificationField', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('timeout calling Asaas'),
      );

      let thrown: unknown;
      try {
        await service.createInvoice(
          makeDto(),
          'ORD-001:transient',
          'corr-test',
        );
      } catch (err) {
        thrown = err;
      }

      expect(thrown).toBeInstanceOf(ServiceUnavailableException);
      const response = (
        thrown as ServiceUnavailableException
      ).getResponse() as Record<string, unknown>;
      expect(response.message).toBe(
        'Failed to create invoice on payment provider',
      );
      expect(response).not.toHaveProperty('bankSlipUrl');
      expect(response).not.toHaveProperty('identificationField');
    });

    it('emite evento de falha de boleto', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('timeout calling Asaas'),
      );

      await expect(
        service.createInvoice(makeDto(), 'ORD-001:transient', 'corr-test'),
      ).rejects.toThrow();

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        'payment.boleto.creation_failed',
        expect.objectContaining({ reason: 'timeout calling Asaas' }),
      );
    });
  });

  describe('Cenário 8: Falha de validação retornada pelo provedor', () => {
    it('marca invoice como FAILED quando provedor retorna erro de validação', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('invalid_dueDate: dueDate cannot be today'),
      );

      await expect(
        service.createInvoice(
          makeDto(),
          'ORD-001:provider-validation',
          'corr-test',
        ),
      ).rejects.toThrow(ServiceUnavailableException);

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.updateInvoice).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'PROVIDER_PENDING' }),
        'FAILED',
        expect.objectContaining({
          failureReason: 'invalid_dueDate: dueDate cannot be today',
        }),
      );
    });

    it('a mensagem de erro não expõe bankSlipUrl nem identificationField', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('invalid_dueDate: dueDate cannot be today'),
      );

      let thrown: unknown;
      try {
        await service.createInvoice(
          makeDto(),
          'ORD-001:provider-validation',
          'corr-test',
        );
      } catch (err) {
        thrown = err;
      }

      expect(thrown).toBeInstanceOf(ServiceUnavailableException);
      const response = (
        thrown as ServiceUnavailableException
      ).getResponse() as Record<string, unknown>;
      expect(response.message).toBe(
        'Failed to create invoice on payment provider',
      );
      expect(response).not.toHaveProperty('bankSlipUrl');
      expect(response).not.toHaveProperty('identificationField');
    });
  });
});

// ---------------------------------------------------------------------------
// DS-38 — Criar Invoice PIX
// ---------------------------------------------------------------------------

const makePixDto = (
  overrides: Partial<CreateInvoiceDto> = {},
): CreateInvoiceDto =>
  ({
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
    ...overrides,
  }) as CreateInvoiceDto;

const makePixPendingInvoice = (): InvoiceRecord => ({
  invoiceId: 'inv_pix_test',
  tenantId: TENANT_ID,
  orderId: 'MS-100045',
  customer: {
    id: 'customer-123',
    name: 'Maria Silva',
    document: '12345678909',
  },
  amount: 159.9,
  currency: 'BRL',
  dueDate: '2027-12-31',
  billingType: 'PIX',
  provider: 'ASAAS',
  status: 'PROVIDER_PENDING',
  externalReference: 'inv_pix_test',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

describe('InvoiceService — Falhas de provedor PIX (DS-38)', () => {
  let service: InvoiceService;
  let repository: jest.Mocked<InvoiceRepository>;
  let asaas: jest.Mocked<AsaasService>;
  let eventEmitter: jest.Mocked<EventEmitter2>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
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
          useValue: { emit: jest.fn() },
        },
      ],
    }).compile();

    service = module.get(InvoiceService);
    repository = module.get(InvoiceRepository);
    asaas = module.get(AsaasService);
    eventEmitter = module.get(EventEmitter2);

    repository.findByIdempotencyKey.mockResolvedValue(undefined);
    repository.saveInvoice.mockResolvedValue(undefined);
    repository.updateInvoice.mockResolvedValue(makePixPendingInvoice());
    repository.findCustomerLink.mockResolvedValue(makeCustomerLink());
    eventEmitter.emit.mockReturnValue(true);
  });

  describe('Cenário 5 PIX: Falha transiente ao criar cobrança PIX no provedor', () => {
    it('marca invoice como PROVIDER_PENDING em falha transiente (PIX)', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('Request failed with status code 503'),
      );

      await expect(
        service.createInvoice(makePixDto(), 'MS-100045:transient', 'corr-pix'),
      ).rejects.toThrow(ServiceUnavailableException);

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.updateInvoice).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'PROVIDER_PENDING' }),
        'PROVIDER_PENDING',
        expect.objectContaining({
          failureReason: 'Request failed with status code 503',
        }),
      );
    });

    it('nao retorna invoice OPEN sem providerPaymentId em falha transiente (PIX)', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('ETIMEDOUT connecting to Asaas'),
      );

      let thrown: unknown;
      try {
        await service.createInvoice(
          makePixDto(),
          'MS-100045:transient2',
          'corr-pix',
        );
      } catch (err) {
        thrown = err;
      }

      expect(thrown).toBeInstanceOf(ServiceUnavailableException);
      const response = (
        thrown as ServiceUnavailableException
      ).getResponse() as Record<string, unknown>;
      expect(response.message).toBe(
        'Failed to create invoice on payment provider',
      );
    });
  });

  describe('Cenário 6 PIX: Falha de validação retornada pelo provedor (PIX)', () => {
    it('marca invoice como FAILED em rejeição por validação do provedor (PIX)', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('invalid_billingType: billingType inválido para PIX'),
      );

      await expect(
        service.createInvoice(makePixDto(), 'MS-100045:validation', 'corr-pix'),
      ).rejects.toThrow(ServiceUnavailableException);

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(repository.updateInvoice).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'PROVIDER_PENDING' }),
        'FAILED',
        expect.objectContaining({
          failureReason: 'invalid_billingType: billingType inválido para PIX',
        }),
      );
    });

    it('retorna erro claro sem expor segredo ou payload sensivel (PIX)', async () => {
      asaas.createCharge.mockRejectedValueOnce(
        new Error('invalid_cpfCnpj: CPF/CNPJ inválido'),
      );

      let thrown: unknown;
      try {
        await service.createInvoice(
          makePixDto(),
          'MS-100045:validation2',
          'corr-pix',
        );
      } catch (err) {
        thrown = err;
      }

      expect(thrown).toBeInstanceOf(ServiceUnavailableException);
      const response = (
        thrown as ServiceUnavailableException
      ).getResponse() as Record<string, unknown>;
      expect(response.message).toBe(
        'Failed to create invoice on payment provider',
      );
      expect(JSON.stringify(response)).not.toContain('access_token');
      expect(JSON.stringify(response)).not.toContain('ASAAS_TOKEN');
    });
  });
});
