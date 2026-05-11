import { Test, TestingModule } from '@nestjs/testing';
import {
  BadGatewayException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationService } from '@shared/notifications/notification.service';
import { PrismaService } from '@shared/prisma/prisma.service';
import { TransactionsService } from './transactions.service';
import { PaymentGatewayRouterService } from './gateways/payment-gateway-router.service';
import { WalletService } from '@modules/wallet/wallet.service';

const txMethods = {
  investor: { findUnique: jest.fn(), update: jest.fn() },
  user: { findUnique: jest.fn() },
  transaction: {
    create: jest.fn(),
    findUnique: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
  },
  admin: { findUnique: jest.fn() },
};

const prismaMock: typeof txMethods & { $transaction: jest.Mock } = {
  ...txMethods,
  $transaction: jest.fn((cb: (tx: typeof txMethods) => Promise<unknown>) =>
    cb(txMethods),
  ),
};

const gatewayMock = {
  gateway: 'FEDAPAY' as const,
  initiateDeposit: jest.fn(),
  initiateWithdrawal: jest.fn(),
  verifyAndParseWebhook: jest.fn(),
};

const routerMock = {
  resolveByMomoProvider: jest.fn(() => gatewayMock),
  resolveByGateway: jest.fn(() => gatewayMock),
};

const notificationsMock = {
  notifyPaymentInitiated: jest.fn(),
  notifyPaymentConfirmed: jest.fn(),
  notifyPaymentFailed: jest.fn(),
};

const configMock = {
  get: jest.fn((key: string) => {
    const map: Record<string, string> = {
      BASE_URL: 'http://localhost:3000',
      FRONTEND_URL: 'http://localhost:8081',
    };
    return map[key];
  }),
};

describe('TransactionsService', () => {
  let service: TransactionsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TransactionsService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: ConfigService, useValue: configMock },
        { provide: NotificationService, useValue: notificationsMock },
        { provide: PaymentGatewayRouterService, useValue: routerMock },
        {
          provide: WalletService,
          useValue: { updateEscrowOnDeposit: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<TransactionsService>(TransactionsService);
    jest.clearAllMocks();
    routerMock.resolveByMomoProvider.mockReturnValue(gatewayMock);
    routerMock.resolveByGateway.mockReturnValue(gatewayMock);
  });

  describe('initiateDeposit', () => {
    it("lève ForbiddenException si l'utilisateur n'est pas un investisseur", async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);
      prismaMock.investor.findUnique.mockResolvedValue(null);

      await expect(
        service.initiateDeposit('user-id', {
          amount: 10000,
          momoProvider: 'MTN_MOMO',
          momoPhone: '+22997000000',
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('route MTN_MOMO vers le gateway interne et déclenche le SMS d’initiation', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-id',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@nexus.test',
        phone: '+22997000000',
      });
      prismaMock.investor.findUnique.mockResolvedValue({ id: 'user-id' });
      prismaMock.transaction.create.mockResolvedValue({
        id: 'tx-id',
        type: 'INVESTOR_DEPOSIT',
        amount: 10000,
        status: 'PENDING',
        payment_gateway: 'FEDAPAY',
        momo_reference: 'NEXUS-123-ABC',
        momo_provider: 'MTN_MOMO',
        provider_transaction_id: null,
        provider_status: 'INITIATED_LOCAL',
        initiated_at: new Date(),
        confirmed_at: null,
        reconciled_at: null,
        is_reconciled: false,
        failure_reason: null,
        created_by: 'user-id',
      });
      prismaMock.transaction.update.mockResolvedValue({
        id: 'tx-id',
        type: 'INVESTOR_DEPOSIT',
        amount: 10000,
        status: 'PENDING',
        payment_gateway: 'FEDAPAY',
        momo_reference: 'NEXUS-123-ABC',
        momo_provider: 'MTN_MOMO',
        provider_transaction_id: 'fdp_123',
        provider_status: 'pending',
        initiated_at: new Date(),
        confirmed_at: null,
        reconciled_at: null,
        is_reconciled: false,
        failure_reason: null,
        created_by: 'user-id',
      });
      gatewayMock.initiateDeposit.mockResolvedValue({
        gateway: 'FEDAPAY',
        providerTransactionId: 'fdp_123',
        providerStatus: 'pending',
        paymentUrl: 'https://sandbox.fedapay.test/pay',
        payload: { transaction: { id: 'fdp_123' } },
      });

      const result = await service.initiateDeposit('user-id', {
        amount: 10000,
        momoProvider: 'MTN_MOMO',
        momoPhone: '+22997000000',
      });

      expect(routerMock.resolveByMomoProvider).toHaveBeenCalledWith('MTN_MOMO');
      expect(gatewayMock.initiateDeposit).toHaveBeenCalledTimes(1);
      expect(result.gateway).toBe('FEDAPAY');
      expect(result.providerTransactionId).toBe('fdp_123');
      expect(notificationsMock.notifyPaymentInitiated).toHaveBeenCalledWith(
        expect.objectContaining({
          phone: '+22997000000',
          firstName: 'Ada',
        }),
        'deposit',
        10000,
        'FEDAPAY',
      );
    });
  });

  describe('initiateWithdrawal', () => {
    it('lève BadRequestException si le solde est insuffisant', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-id',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@nexus.test',
        phone: '+22997000000',
      });
      prismaMock.investor.findUnique.mockResolvedValue({
        id: 'user-id',
        wallet_balance: { toString: () => '5000' },
      });

      await expect(
        service.initiateWithdrawal('user-id', {
          amount: 10000,
          momoProvider: 'MTN_MOMO',
          momoNumber: '+22997000000',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("reverse le débit wallet si l'initiation provider échoue", async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-id',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@nexus.test',
        phone: '+22997000000',
      });
      prismaMock.investor.findUnique.mockResolvedValue({
        id: 'user-id',
        wallet_balance: { toString: () => '50000' },
      });
      prismaMock.transaction.create.mockResolvedValue({
        id: 'tx-id',
        type: 'INVESTOR_WITHDRAWAL',
        amount: 10000,
        status: 'PENDING',
        payment_gateway: 'FEDAPAY',
        momo_reference: 'NEXUS-123-ABC',
        momo_provider: 'MTN_MOMO',
        provider_transaction_id: null,
        provider_status: 'INITIATED_LOCAL',
        initiated_at: new Date(),
        confirmed_at: null,
        reconciled_at: null,
        is_reconciled: false,
        failure_reason: null,
        created_by: 'user-id',
      });
      gatewayMock.initiateWithdrawal.mockRejectedValue(
        new Error('Provider down'),
      );

      await expect(
        service.initiateWithdrawal('user-id', {
          amount: 10000,
          momoProvider: 'MTN_MOMO',
          momoNumber: '+22997000000',
        }),
      ).rejects.toThrow(BadGatewayException);

      expect(prismaMock.investor.update).toHaveBeenCalledTimes(2);
      expect(prismaMock.transaction.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: 'FAILED',
            provider_status: 'FAILED_TO_INITIATE',
          }),
        }),
      );
    });
  });

  describe('handleWebhook', () => {
    it('rejette un webhook avec signature invalide', async () => {
      gatewayMock.verifyAndParseWebhook.mockImplementation(() => {
        throw new ForbiddenException('Signature invalide');
      });

      await expect(
        service.handleWebhook(
          'FEDAPAY',
          { type: 'transaction.approved' },
          Buffer.from('{}'),
          {},
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('ne retraite pas une transaction déjà CONFIRMED (idempotence)', async () => {
      gatewayMock.verifyAndParseWebhook.mockReturnValue({
        reference: 'NEXUS-123-ABC',
        providerTransactionId: 'fdp_123',
        providerStatus: 'approved',
        internalStatus: 'CONFIRMED',
        failureReason: null,
        payload: { type: 'transaction.approved' },
        signatureVerified: true,
      });
      prismaMock.transaction.findUnique.mockResolvedValue({
        id: 'tx-id',
        status: 'CONFIRMED',
        type: 'INVESTOR_DEPOSIT',
        amount: 10000,
        created_by: 'inv-id',
      });

      const result = await service.handleWebhook(
        'FEDAPAY',
        {},
        Buffer.from('{}'),
        {},
      );

      expect(result.processed).toBe(true);
      expect(prismaMock.transaction.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            signature_verified: true,
          }),
        }),
      );
    });

    it('retourne processed:false si la référence est inconnue', async () => {
      gatewayMock.verifyAndParseWebhook.mockReturnValue({
        reference: 'UNKNOWN-REF',
        providerTransactionId: 'kkp_123',
        providerStatus: 'transaction.success',
        internalStatus: 'CONFIRMED',
        failureReason: null,
        payload: { event: 'transaction.success' },
        signatureVerified: true,
      });
      prismaMock.transaction.findUnique.mockResolvedValue(null);

      const result = await service.handleWebhook(
        'KKIAPAY',
        {},
        Buffer.from('{}'),
        {},
      );

      expect(result.processed).toBe(false);
    });

    it('crédite le wallet et notifie sur dépôt confirmé', async () => {
      gatewayMock.verifyAndParseWebhook.mockReturnValue({
        reference: 'NEXUS-123-ABC',
        providerTransactionId: 'fdp_123',
        providerStatus: 'approved',
        internalStatus: 'CONFIRMED',
        failureReason: null,
        payload: { type: 'transaction.approved' },
        signatureVerified: true,
      });
      prismaMock.transaction.findUnique.mockResolvedValue({
        id: 'tx-id',
        status: 'PENDING',
        type: 'INVESTOR_DEPOSIT',
        amount: 10000,
        created_by: 'inv-id',
      });
      prismaMock.user.findUnique.mockResolvedValue({
        phone: '+22997000000',
        firstName: 'Ada',
      });

      const result = await service.handleWebhook(
        'FEDAPAY',
        {},
        Buffer.from('{}'),
        {},
      );

      expect(result.processed).toBe(true);
      expect(prismaMock.investor.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { wallet_balance: { increment: 10000 } },
        }),
      );
      expect(notificationsMock.notifyPaymentConfirmed).toHaveBeenCalledWith(
        expect.objectContaining({
          phone: '+22997000000',
          firstName: 'Ada',
        }),
        'deposit',
        10000,
        'FEDAPAY',
      );
    });
  });
});
