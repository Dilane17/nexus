import { Test, TestingModule } from '@nestjs/testing';
import { InvestmentsService } from './investments.service';
import { PrismaService } from '@shared/prisma/prisma.service';
import { NotificationService } from '@shared/notifications/notification.service';

const prismaMock = {
  investor: { findUnique: jest.fn(), update: jest.fn() },
  user: { findUnique: jest.fn() },
  loan: { findUnique: jest.fn(), findMany: jest.fn(), update: jest.fn() },
  investment: {
    create: jest.fn(),
    aggregate: jest.fn(),
    updateMany: jest.fn(),
  },
  autoInvestRule: { findUnique: jest.fn(), findMany: jest.fn() },
  guaranteeFund: { findFirst: jest.fn(), update: jest.fn() },
  guaranteeFundInvestment: { create: jest.fn(), updateMany: jest.fn() },
  platformWallet: { findFirst: jest.fn(), update: jest.fn() },
  transaction: { findUnique: jest.fn(), create: jest.fn() },
  $transaction: jest.fn(),
};

const notificationsMock = {
  notifyPaymentInitiated: jest.fn(),
};

describe('InvestmentsService', () => {
  let service: InvestmentsService;

  beforeEach(async () => {
    prismaMock.$transaction.mockImplementation(
      async (callback: (tx: typeof prismaMock) => Promise<unknown>) =>
        callback(prismaMock),
    );

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InvestmentsService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: NotificationService, useValue: notificationsMock },
      ],
    }).compile();

    service = module.get<InvestmentsService>(InvestmentsService);
    jest.clearAllMocks();
  });

  it('exécute le cron Auto-Invest pour les règles actives', async () => {
    prismaMock.autoInvestRule.findMany.mockResolvedValue([
      { investor_id: 'inv-1' },
    ]);
    prismaMock.investor.findUnique.mockResolvedValue({
      id: 'inv-1',
      wallet_balance: { toString: () => '100000' },
    });
    prismaMock.autoInvestRule.findUnique.mockResolvedValue({
      is_active: true,
      max_amount: 20000,
      max_duration: 6,
      min_hybrid_score: 50,
    });
    prismaMock.loan.findMany.mockResolvedValue([]);

    await service.runScheduledAutoInvest();

    expect(prismaMock.autoInvestRule.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { is_active: true },
      }),
    );
  });

  it('rééquilibre le fonds de garantie avec la commission plateforme', async () => {
    prismaMock.guaranteeFund.findFirst.mockResolvedValue({
      id: 'fund-1',
      total_capital: 1000,
      active_portfolio_value: 10000,
      coverage_ratio: 0.1,
      min_threshold: 0.03,
      target_threshold: 0.2,
      suspension_active: false,
    });
    prismaMock.platformWallet.findFirst.mockResolvedValue({
      id: 'wallet-1',
      commission_balance: 2000,
    });
    prismaMock.investment.aggregate.mockResolvedValue({
      _sum: { amount: 10000 },
    });

    await service.maintainGuaranteeFund();

    expect(prismaMock.platformWallet.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'wallet-1' },
      }),
    );
    expect(prismaMock.guaranteeFund.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'fund-1' },
        data: expect.objectContaining({
          active_portfolio_value: 10000,
        }),
      }),
    );
  });

  it('active la couverture pour les prêts en GUARANTEE_ACTIVATED', async () => {
    prismaMock.loan.findMany.mockResolvedValue([
      {
        id: 'loan-1',
        borrower_id: 'borrower-1',
        investments: [
          {
            id: 'invst-1',
            amount: 5000,
            guarantee_fund_investments: [
              {
                id: 'gfi-1',
                covered_amount: 5000,
              },
            ],
          },
        ],
      },
    ]);
    prismaMock.transaction.findUnique.mockResolvedValue(null);

    await service.activateGuaranteeCoverage();

    expect(prismaMock.guaranteeFundInvestment.updateMany).toHaveBeenCalled();
    expect(prismaMock.investment.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { status: 'GUARANTEED' },
      }),
    );
    expect(prismaMock.transaction.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          type: 'GUARANTEE_ACTIVATION',
        }),
      }),
    );
  });
});
