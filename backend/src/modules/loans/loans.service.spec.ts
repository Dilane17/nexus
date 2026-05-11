import { Test, TestingModule } from '@nestjs/testing';
import { LoansService } from './loans.service';
import { PrismaService } from '@shared/prisma/prisma.service';
import { NotificationService } from '@shared/notifications/notification.service';
import { GuaranteeFundService } from '@modules/guarantee-fund/guarantee-fund.service';
import { ForbiddenException, BadRequestException } from '@nestjs/common';

// ── Mock PrismaService ────────────────────────────────────────────────────────

const prismaMock = {
  borrower: { findUnique: jest.fn(), findUniqueOrThrow: jest.fn() },
  user: { findUnique: jest.fn() },
  loan: {
    count: jest.fn(),
    create: jest.fn(),
    findMany: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  borrowerScore: { create: jest.fn() },
  scoringEngine: { findFirst: jest.fn() },
  imfStaff: { findUnique: jest.fn() },
  admin: { findUnique: jest.fn() },
  transaction: { findUnique: jest.fn(), create: jest.fn() },
  $transaction: jest.fn(),
};

describe('LoansService', () => {
  let service: LoansService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LoansService,
        { provide: PrismaService, useValue: prismaMock },
        {
          provide: NotificationService,
          useValue: {
            notifyLoanOverdue: jest.fn(),
            notifyLoanRepaymentReceived: jest.fn(),
          },
        },
        {
          provide: GuaranteeFundService,
          useValue: { activateGuarantee: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<LoansService>(LoansService);
    jest.clearAllMocks();
  });

  // ── calculateMonthlyInstallment ──────────────────────────────────────────────

  describe('calculateMonthlyInstallment (private)', () => {
    // Accès via cast any pour tester la méthode privée
    const calc = (amount: number, rate: number, months: number) =>
      (
        service as unknown as {
          calculateMonthlyInstallment: (
            a: number,
            r: number,
            m: number,
          ) => number;
        }
      ).calculateMonthlyInstallment(amount, rate, months);

    it('retourne amount/months si taux = 0', () => {
      expect(calc(120000, 0, 12)).toBeCloseTo(10000, 2);
    });

    it('calcule la mensualité correcte pour 150 000 FCFA à 15% sur 6 mois', () => {
      const result = calc(150000, 0.15, 6);
      // Vérification : mensualité × 6 > 150 000 (intérêts inclus)
      expect(result * 6).toBeGreaterThan(150000);
      // Mensualité approximative attendue ~26 500 FCFA
      expect(result).toBeGreaterThan(26000);
      expect(result).toBeLessThan(28000);
    });

    it('respecte le taux max BCEAO (18%)', () => {
      const at18 = calc(100000, 0.18, 12);
      const at19 = calc(100000, 0.19, 12);
      expect(at18).toBeLessThan(at19);
    });

    it('montant plus long = mensualité plus faible', () => {
      const m6 = calc(100000, 0.15, 6);
      const m12 = calc(100000, 0.15, 12);
      expect(m12).toBeLessThan(m6);
    });
  });

  // ── createLoan — garde KYC ───────────────────────────────────────────────────

  describe('createLoan', () => {
    it("lève ForbiddenException si l'utilisateur n'est pas un emprunteur", async () => {
      prismaMock.borrower.findUnique.mockResolvedValue(null);

      await expect(
        service.createLoan('user-id', {
          amount: 50000,
          durationMonths: 6,
          purpose: 'Test achat stock',
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("lève ForbiddenException si le KYC n'est pas VALIDATED", async () => {
      prismaMock.borrower.findUnique.mockResolvedValue({ id: 'borrower-id' });
      prismaMock.user.findUnique.mockResolvedValue({
        kyc_status: 'SESSION1_DONE',
      });

      await expect(
        service.createLoan('user-id', {
          amount: 50000,
          durationMonths: 6,
          purpose: 'Test achat stock',
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('lève BadRequestException si un prêt ACTIVE/OVERDUE/FUNDING existe déjà', async () => {
      prismaMock.borrower.findUnique.mockResolvedValue({ id: 'borrower-id' });
      prismaMock.user.findUnique.mockResolvedValue({ kyc_status: 'VALIDATED' });
      prismaMock.loan.count.mockResolvedValue(1);

      await expect(
        service.createLoan('user-id', {
          amount: 50000,
          durationMonths: 6,
          purpose: 'Test achat stock',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ── validateLoan — garde IMF ─────────────────────────────────────────────────

  describe('validateLoan', () => {
    it("lève ForbiddenException si l'appelant n'est pas IMF Staff", async () => {
      prismaMock.imfStaff.findUnique.mockResolvedValue(null);

      await expect(
        service.validateLoan('user-id', 'loan-id', { decision: 'APPROVED' }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("lève BadRequestException si le prêt n'est pas en PENDING_IMF", async () => {
      prismaMock.imfStaff.findUnique.mockResolvedValue({ id: 'imf-id' });
      prismaMock.loan.findUnique.mockResolvedValue({
        id: 'loan-id',
        status: 'FUNDING',
        amount: 100000,
        duration_months: 6,
      });

      await expect(
        service.validateLoan('imf-id', 'loan-id', { decision: 'APPROVED' }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
