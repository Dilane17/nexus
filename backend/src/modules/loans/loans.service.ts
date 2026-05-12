import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '@shared/prisma/prisma.service';
import { NotificationService } from '@shared/notifications/notification.service';
import { GuaranteeFundService } from '@modules/guarantee-fund/guarantee-fund.service';
import type { CreateLoanDto } from './dto/create-loan.dto';
import type { ValidateLoanDto } from './dto/validate-loan.dto';
import type { RepayLoanDto } from './dto/repay-loan.dto';
import { DEFAULT_INTEREST_RATE } from './dto/validate-loan.dto';
import type {
  LoanResponse,
  PaginatedLoansResponse,
  PaginatedPendingImfResponse,
  HybridScoreResponse,
} from './dto/loan-response.dto';

// ── Sélecteur partagé ─────────────────────────────────────────────────────────

const LOAN_SELECT = {
  id: true,
  borrower_id: true,
  amount: true,
  interest_rate: true,
  duration_months: true,
  status: true,
  monthly_installment: true,
  outstanding_balance: true,
  days_overdue: true,
  validated_by_imf: true,
  disbursed_at: true,
  next_due_date: true,
  purpose: true,
  rejection_reason: true,
  created_at: true,
} as const;

// ── Helpers ───────────────────────────────────────────────────────────────────

function toLoanResponse(
  loan: {
    id: string;
    borrower_id: string;
    amount: { toString(): string };
    interest_rate: { toString(): string };
    duration_months: number;
    status: string;
    monthly_installment: { toString(): string };
    outstanding_balance: { toString(): string };
    days_overdue: number;
    validated_by_imf: boolean;
    disbursed_at: Date | null;
    next_due_date: Date | null;
    purpose: string | null;
    rejection_reason: string | null;
    created_at: Date;
  },
  extras?: { investmentsCount?: number; hybridScore?: number | null },
): LoanResponse {
  return {
    id: loan.id,
    borrowerId: loan.borrower_id,
    amount: loan.amount as LoanResponse['amount'],
    interestRate: loan.interest_rate as LoanResponse['interestRate'],
    durationMonths: loan.duration_months,
    status: loan.status,
    monthlyInstallment:
      loan.monthly_installment as LoanResponse['monthlyInstallment'],
    outstandingBalance:
      loan.outstanding_balance as LoanResponse['outstandingBalance'],
    daysOverdue: loan.days_overdue,
    validatedByImf: loan.validated_by_imf,
    disbursedAt: loan.disbursed_at,
    nextDueDate: loan.next_due_date,
    purpose: loan.purpose,
    rejectionReason: loan.rejection_reason,
    createdAt: loan.created_at,
    ...extras,
  };
}

@Injectable()
export class LoansService {
  private readonly logger = new Logger(LoansService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationService,
    private readonly guaranteeFundService: GuaranteeFundService,
  ) {}

  // ── Créer une demande de prêt ────────────────────────────────────────────────

  async createLoan(userId: string, dto: CreateLoanDto): Promise<LoanResponse> {
    const borrower = await this.prisma.borrower.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!borrower) {
      throw new ForbiddenException(
        'Seuls les emprunteurs enregistrés peuvent faire une demande de prêt',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { kyc_status: true },
    });

    if (user?.kyc_status !== 'VALIDATED') {
      throw new ForbiddenException(
        'Votre KYC doit être validé avant de faire une demande de prêt',
      );
    }

    const activeLoans = await this.prisma.loan.count({
      where: {
        borrower_id: userId,
        status: { in: ['ACTIVE', 'OVERDUE', 'FUNDING'] },
      },
    });

    if (activeLoans > 0) {
      throw new BadRequestException(
        'Vous avez déjà un prêt en cours. Remboursez-le avant de faire une nouvelle demande.',
      );
    }

    const score = await this.computeHybridScore(userId);
    const monthlyInstallment = this.calculateMonthlyInstallment(
      dto.amount,
      DEFAULT_INTEREST_RATE,
      dto.durationMonths,
    );

    const loan = await this.prisma.loan.create({
      data: {
        borrower_id: userId,
        amount: dto.amount,
        interest_rate: DEFAULT_INTEREST_RATE,
        duration_months: dto.durationMonths,
        monthly_installment: monthlyInstallment,
        outstanding_balance: dto.amount,
        purpose: dto.purpose,
        status: 'PENDING_IMF',
      },
      select: LOAN_SELECT,
    });

    return toLoanResponse(loan, { hybridScore: score.hybridScore });
  }

  // ── Mes prêts (emprunteur) ───────────────────────────────────────────────────

  async getMyLoans(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedLoansResponse> {
    const borrower = await this.prisma.borrower.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!borrower) {
      throw new ForbiddenException('Accès réservé aux emprunteurs');
    }

    const skip = (page - 1) * limit;

    const [loans, total] = await Promise.all([
      this.prisma.loan.findMany({
        where: { borrower_id: userId },
        select: LOAN_SELECT,
        orderBy: { created_at: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.loan.count({ where: { borrower_id: userId } }),
    ]);

    return {
      items: loans.map((l) => toLoanResponse(l)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Prêts ouverts au financement (marketplace investisseur) ─────────────────

  async getFundingLoans(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedLoansResponse> {
    const investor = await this.prisma.investor.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!investor) {
      throw new ForbiddenException('Accès réservé aux investisseurs');
    }

    const skip = (page - 1) * limit;

    const [loans, total] = await Promise.all([
      this.prisma.loan.findMany({
        where: {
          status: 'FUNDING',
          borrower_id: { not: userId },
        },
        select: LOAN_SELECT,
        orderBy: { created_at: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.loan.count({
        where: {
          status: 'FUNDING',
          borrower_id: { not: userId },
        },
      }),
    ]);

    return {
      items: loans.map((l) => toLoanResponse(l)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Détail d'un prêt ─────────────────────────────────────────────────────────

  async getLoanById(userId: string, loanId: string): Promise<LoanResponse> {
    const loan = await this.prisma.loan.findUnique({
      where: { id: loanId },
      select: {
        ...LOAN_SELECT,
        _count: { select: { investments: true } },
      },
    });

    if (!loan) {
      throw new NotFoundException('Prêt introuvable');
    }

    const isOwner = loan.borrower_id === userId;
    const isStaff = await this.isImfStaffOrAdmin(userId);

    if (!isOwner && !isStaff) {
      // Un investisseur peut voir le détail d'un prêt FUNDING qui n'est pas le sien
      const isInvestor = await this.prisma.investor.findUnique({
        where: { id: userId },
        select: { id: true },
      });
      const canViewAsFundingLoan =
        !!isInvestor &&
        loan.status === 'FUNDING' &&
        loan.borrower_id !== userId;

      if (!canViewAsFundingLoan) {
        throw new ForbiddenException('Accès refusé à ce prêt');
      }
    }

    return toLoanResponse(loan, { investmentsCount: loan._count.investments });
  }

  // ── Prêts en attente IMF ─────────────────────────────────────────────────────

  async getPendingImfLoans(
    page: number,
    limit: number,
  ): Promise<PaginatedPendingImfResponse> {
    const skip = (page - 1) * limit;

    const [loans, total] = await Promise.all([
      this.prisma.loan.findMany({
        where: { status: 'PENDING_IMF' },
        select: {
          id: true,
          borrower_id: true,
          amount: true,
          interest_rate: true,
          duration_months: true,
          status: true,
          purpose: true,
          created_at: true,
          borrowers: {
            select: {
              id: true,
              user: {
                select: { firstName: true, lastName: true, phone: true },
              },
              borrower_scores: {
                select: { hybrid_score: true },
                orderBy: { computed_at: 'desc' },
                take: 1,
              },
            },
          },
        },
        orderBy: { created_at: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.loan.count({ where: { status: 'PENDING_IMF' } }),
    ]);

    return {
      items: loans.map((l) => {
        const hybridScore = l.borrowers.borrower_scores[0]
          ? Number(l.borrowers.borrower_scores[0].hybrid_score)
          : null;
        return {
          id: l.id,
          borrowerId: l.borrower_id,
          amount: l.amount as PaginatedPendingImfResponse['items'][number]['amount'],
          interestRate: l.interest_rate as PaginatedPendingImfResponse['items'][number]['interestRate'],
          durationMonths: l.duration_months,
          status: l.status,
          purpose: l.purpose,
          createdAt: l.created_at,
          hybridScore,
          borrower: {
            userId: l.borrowers.id,
            firstName: l.borrowers.user.firstName,
            lastName: l.borrowers.user.lastName,
            phone: l.borrowers.user.phone,
            hybridScore,
          },
        };
      }),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Tous les prêts (Admin) ───────────────────────────────────────────────────

  async getAllLoans(page: number, limit: number): Promise<PaginatedLoansResponse> {
    const skip = (page - 1) * limit;
    const [loans, total] = await Promise.all([
      this.prisma.loan.findMany({
        select: {
          ...LOAN_SELECT,
          borrowers: {
            select: {
              user: { select: { firstName: true, lastName: true, email: true } },
            },
          },
        },
        orderBy: { created_at: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.loan.count(),
    ]);

    return {
      items: loans.map((l) =>
        toLoanResponse(l, {
          // @ts-expect-error borrowers comes from joined select
          borrower: l.borrowers?.user,
        }),
      ),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Valider / Rejeter un prêt (IMF Staff) ────────────────────────────────────

  async validateLoan(
    imfStaffUserId: string,
    loanId: string,
    dto: ValidateLoanDto,
  ): Promise<LoanResponse> {
    const imfStaff = await this.prisma.imfStaff.findUnique({
      where: { id: imfStaffUserId },
      select: { id: true },
    });

    if (!imfStaff) {
      throw new ForbiddenException('Accès réservé au personnel IMF');
    }

    const loan = await this.prisma.loan.findUnique({
      where: { id: loanId },
      select: { id: true, status: true, amount: true, duration_months: true },
    });

    if (!loan) {
      throw new NotFoundException('Prêt introuvable');
    }

    if (loan.status !== 'PENDING_IMF') {
      throw new BadRequestException(
        `Ce prêt n'est pas en attente de validation IMF (statut : ${loan.status})`,
      );
    }

    let updatedLoan;

    if (dto.decision === 'APPROVED') {
      const rate = dto.interest_rate ?? DEFAULT_INTEREST_RATE;
      const monthlyInstallment = this.calculateMonthlyInstallment(
        Number(loan.amount),
        rate,
        loan.duration_months,
      );

      updatedLoan = await this.prisma.loan.update({
        where: { id: loanId },
        data: {
          status: 'FUNDING',
          interest_rate: rate,
          monthly_installment: monthlyInstallment,
          validated_by_imf: true,
          imf_validated_by: imfStaffUserId,
        },
        select: LOAN_SELECT,
      });
    } else {
      updatedLoan = await this.prisma.loan.update({
        where: { id: loanId },
        data: {
          status: 'CANCELLED',
          rejection_reason: dto.reason,
          imf_validated_by: imfStaffUserId,
        },
        select: LOAN_SELECT,
      });
    }

    return toLoanResponse(updatedLoan);
  }

  // ── Rembourser un prêt ───────────────────────────────────────────────────────

  async repayLoan(
    userId: string,
    loanId: string,
    dto: RepayLoanDto,
  ): Promise<LoanResponse> {
    const loan = await this.prisma.loan.findUnique({
      where: { id: loanId },
      select: {
        id: true,
        borrower_id: true,
        amount: true,
        status: true,
        outstanding_balance: true,
        monthly_installment: true,
        next_due_date: true,
      },
    });

    if (!loan) throw new NotFoundException('Prêt introuvable');
    if (loan.borrower_id !== userId)
      throw new ForbiddenException('Ce prêt ne vous appartient pas');
    if (!['ACTIVE', 'OVERDUE'].includes(loan.status)) {
      throw new BadRequestException(
        `Impossible de rembourser un prêt en statut "${loan.status}"`,
      );
    }

    const existingTx = await this.prisma.transaction.findUnique({
      where: { momo_reference: dto.momoReference },
      select: { id: true },
    });
    if (existingTx)
      throw new BadRequestException('Cette référence MoMo a déjà été utilisée');

    // Investissements actifs liés — lus avant la transaction (lecture seule)
    const activeInvestments = await this.prisma.investment.findMany({
      where: { loan_id: loanId, status: 'ACTIVE' },
      select: { id: true, investor_id: true, amount: true },
    });

    const loanAmount = Number(loan.amount);
    const currentBalance = Number(loan.outstanding_balance);
    const repaidAmount = Math.min(dto.amount, currentBalance);
    const newBalance = Math.max(0, currentBalance - repaidAmount);
    const isFullyRepaid = newBalance === 0;
    const isOnTime =
      loan.next_due_date === null || new Date() <= loan.next_due_date;
    const nextDueDate = isFullyRepaid
      ? null
      : this.advanceDueDate(
          loan.next_due_date,
          Number(loan.monthly_installment),
          repaidAmount,
        );

    const updatedLoan = await this.prisma.$transaction(async (tx) => {
      // 1. Mettre à jour le prêt
      const updated = await tx.loan.update({
        where: { id: loanId },
        data: {
          outstanding_balance: newBalance,
          status: isFullyRepaid ? 'REPAID' : loan.status,
          days_overdue: isFullyRepaid ? 0 : undefined,
          next_due_date: nextDueDate,
        },
        select: LOAN_SELECT,
      });

      // 2. Enregistrer la transaction MoMo
      await tx.transaction.create({
        data: {
          type: 'LOAN_REPAYMENT',
          amount: repaidAmount,
          status: 'PENDING',
          momo_reference: dto.momoReference,
          momo_provider: dto.momoProvider,
          created_by: userId,
        },
      });

      // 3. Distribuer les retours aux investisseurs proportionnellement
      for (const investment of activeInvestments) {
        const share =
          loanAmount > 0 ? Number(investment.amount) / loanAmount : 0;
        const investorReturn = Math.round(repaidAmount * share * 100) / 100;

        await tx.investment.update({
          where: { id: investment.id },
          data: { actual_return: { increment: investorReturn } },
        });

        await tx.investor.update({
          where: { id: investment.investor_id },
          data: { total_returns: { increment: investorReturn } },
        });

        this.logger.log(
          `[REPAYMENT] Investisseur ${investment.investor_id} — part: ${(share * 100).toFixed(2)}% — retour: ${investorReturn.toFixed(0)} FCFA`,
        );
      }

      // 4. Si remboursement total → clôturer tous les investissements
      if (isFullyRepaid && activeInvestments.length > 0) {
        await tx.investment.updateMany({
          where: { loan_id: loanId, status: 'ACTIVE' },
          data: { status: 'COMPLETED' },
        });
        this.logger.log(
          `[LOAN] Prêt ${loanId} REPAID — ${activeInvestments.length} investissement(s) clôturé(s)`,
        );
      }

      // 5. Bonus credit_score si remboursement à temps
      if (isOnTime) {
        await tx.borrower.update({
          where: { id: userId },
          data: { credit_score: { increment: 2 } },
        });
      }

      return updated;
    });

    const borrowerUser = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { phone: true, firstName: true, email: true },
    });

    if (borrowerUser) {
      await this.notifications.notifyLoanRepaymentReceived(
        borrowerUser,
        loanId,
        repaidAmount,
      );
    }

    return toLoanResponse(updatedLoan);
  }

  // ── Cron — Détection des retards (01h00 chaque jour) ────────────────────────

  @Cron('0 1 * * *')
  async checkOverdueLoans(): Promise<void> {
    const now = new Date();

    const overdueLoans = await this.prisma.loan.findMany({
      where: {
        status: 'ACTIVE',
        next_due_date: { lt: now },
      },
      select: {
        id: true,
        next_due_date: true,
        borrower_id: true,
        borrowers: {
          select: {
            user: {
              select: {
                phone: true,
                firstName: true,
                email: true,
              },
            },
          },
        },
      },
    });

    if (overdueLoans.length === 0) return;

    for (const loan of overdueLoans) {
      const daysOverdue = Math.floor(
        (now.getTime() - new Date(loan.next_due_date!).getTime()) / 86_400_000,
      );

      const newStatus = daysOverdue > 30 ? 'GUARANTEE_ACTIVATED' : 'OVERDUE';

      await this.prisma.loan.update({
        where: { id: loan.id },
        data: { status: newStatus, days_overdue: daysOverdue },
      });

      if (newStatus === 'GUARANTEE_ACTIVATED') {
        this.logger.error(
          `[CRON] Prêt ${loan.id} → GUARANTEE_ACTIVATED (${daysOverdue}j de retard)`,
        );

        const investments = await this.prisma.investment.findMany({
          where: { loan_id: loan.id, status: 'ACTIVE', is_guaranteed: true },
          select: { id: true },
        });

        for (const inv of investments) {
          try {
            await this.guaranteeFundService.activateGuarantee(inv.id);
          } catch (err) {
            this.logger.error(
              `[CRON] Échec activation garantie investment=${inv.id}: ${err instanceof Error ? err.message : 'inconnu'}`,
            );
          }
        }
      } else {
        this.logger.warn(
          `[CRON] Prêt ${loan.id} → OVERDUE (${daysOverdue}j de retard)`,
        );
      }

      if (loan.borrowers.user) {
        await this.notifications.notifyLoanOverdue(
          loan.borrowers.user,
          loan.id,
          daysOverdue,
        );
      }
    }

    this.logger.log(
      `[CRON] ${overdueLoans.length} prêt(s) marqué(s) en retard`,
    );
  }

  // ── Helpers privés ───────────────────────────────────────────────────────────

  private async computeHybridScore(
    borrowerId: string,
  ): Promise<HybridScoreResponse> {
    const [borrower, engine] = await Promise.all([
      this.prisma.borrower.findUniqueOrThrow({
        where: { id: borrowerId },
        select: {
          credit_score: true,
          tontine_score: true,
          default_count: true,
        },
      }),
      this.prisma.scoringEngine.findFirst({
        select: { momo_weight: true, tontine_weight: true, imf_weight: true },
      }),
    ]);

    const momoWeight = engine ? Number(engine.momo_weight) : 0.4;
    const tontineWeight = engine ? Number(engine.tontine_weight) : 0.35;
    const imfWeight = engine ? Number(engine.imf_weight) : 0.25;

    const momoScore = Math.min(100, Number(borrower.credit_score));
    const tontineScore = Math.min(100, Number(borrower.tontine_score));
    const imfScore = Math.max(0, 100 - borrower.default_count * 25);

    const hybridScore =
      momoWeight * momoScore +
      tontineWeight * tontineScore +
      imfWeight * imfScore;

    const saved = await this.prisma.borrowerScore.create({
      data: {
        borrower_id: borrowerId,
        momo_score: momoScore,
        tontine_score: tontineScore,
        imf_score: imfScore,
        hybrid_score: hybridScore,
      },
      select: { computed_at: true },
    });

    return {
      borrowerId,
      momoScore,
      tontineScore,
      imfScore,
      hybridScore,
      computedAt: saved.computed_at,
    };
  }

  private calculateMonthlyInstallment(
    amount: number,
    annualRate: number,
    months: number,
  ): number {
    const r = annualRate / 12;
    if (r === 0) return amount / months;
    const factor = Math.pow(1 + r, months);
    return (amount * r * factor) / (factor - 1);
  }

  private advanceDueDate(
    currentDueDate: Date | null,
    monthlyInstallment: number,
    repaidAmount: number,
  ): Date | null {
    if (!currentDueDate) return null;
    const monthsPaid = Math.floor(repaidAmount / monthlyInstallment);
    if (monthsPaid <= 0) return currentDueDate;
    const next = new Date(currentDueDate);
    next.setMonth(next.getMonth() + monthsPaid);
    return next;
  }

  private async isImfStaffOrAdmin(userId: string): Promise<boolean> {
    const [imfStaff, admin] = await Promise.all([
      this.prisma.imfStaff.findUnique({
        where: { id: userId },
        select: { id: true },
      }),
      this.prisma.admin.findUnique({
        where: { id: userId },
        select: { id: true },
      }),
    ]);
    return !!(imfStaff ?? admin);
  }
}
