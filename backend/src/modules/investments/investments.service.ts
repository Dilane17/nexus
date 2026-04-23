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
import type { investment_status } from '@generated/prisma';
import type { CreateInvestmentDto } from './dto/create-investment.dto';
import type {
  InvestmentResponse,
  InvestmentLoanDetail,
  PaginatedInvestmentsResponse,
  PortfolioSummary,
} from './dto/investment-response.dto';
import type {
  AutoInvestRuleDto,
  AutoInvestRuleResponse,
  AutoInvestRunResult,
} from './dto/auto-invest-rule.dto';

// ── Sélecteurs ────────────────────────────────────────────────────────────────

const INVESTMENT_BASE = {
  id: true,
  investor_id: true,
  loan_id: true,
  amount: true,
  expected_return: true,
  actual_return: true,
  status: true,
  is_guaranteed: true,
  guarantee_tier: true,
  maturity_date: true,
} as const;

const LOAN_DETAIL = {
  amount: true,
  duration_months: true,
  interest_rate: true,
  status: true,
  purpose: true,
  borrowers: {
    select: {
      user: { select: { firstName: true, lastName: true } },
    },
  },
} as const;

// ── Helpers ───────────────────────────────────────────────────────────────────

type BaseInvestment = {
  id: string;
  investor_id: string;
  loan_id: string;
  amount: { toString(): string };
  expected_return: { toString(): string };
  actual_return: { toString(): string };
  status: string;
  is_guaranteed: boolean;
  guarantee_tier: number;
  maturity_date: Date;
};

type LoanDetail = {
  amount: { toString(): string };
  duration_months: number;
  interest_rate: { toString(): string };
  status: string;
  purpose: string | null;
  borrowers: { user: { firstName: string; lastName: string } };
};

function toLoanInfo(loan: LoanDetail): InvestmentLoanDetail {
  return {
    amount: loan.amount as InvestmentLoanDetail['amount'],
    durationMonths: loan.duration_months,
    interestRate: loan.interest_rate as InvestmentLoanDetail['interestRate'],
    status: loan.status,
    purpose: loan.purpose,
    borrowerName: `${loan.borrowers.user.firstName} ${loan.borrowers.user.lastName}`,
  };
}

function toInvestmentResponse(
  inv: BaseInvestment,
  loan?: InvestmentResponse['loan'],
): InvestmentResponse {
  return {
    id: inv.id,
    investorId: inv.investor_id,
    loanId: inv.loan_id,
    amount: inv.amount as InvestmentResponse['amount'],
    expectedReturn: inv.expected_return as InvestmentResponse['expectedReturn'],
    actualReturn: inv.actual_return as InvestmentResponse['actualReturn'],
    status: inv.status,
    isGuaranteed: inv.is_guaranteed,
    guaranteeTier: inv.guarantee_tier,
    maturityDate: inv.maturity_date,
    loan,
  };
}

@Injectable()
export class InvestmentsService {
  private readonly logger = new Logger(InvestmentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationService,
  ) {}

  // ── Investir sur un prêt ─────────────────────────────────────────────────────

  async createInvestment(
    userId: string,
    dto: CreateInvestmentDto,
  ): Promise<InvestmentResponse> {
    const investor = await this.prisma.investor.findUnique({
      where: { id: userId },
      select: { id: true, wallet_balance: true },
    });

    if (!investor) {
      throw new ForbiddenException(
        'Seuls les investisseurs enregistrés peuvent investir',
      );
    }

    const loan = await this.prisma.loan.findUnique({
      where: { id: dto.loan_id },
      select: {
        id: true,
        borrower_id: true,
        status: true,
        amount: true,
        interest_rate: true,
        duration_months: true,
        monthly_installment: true,
        investments: { select: { amount: true } },
      },
    });

    if (!loan) {
      throw new NotFoundException('Prêt introuvable');
    }

    if (loan.status !== 'FUNDING') {
      throw new BadRequestException(
        `Ce prêt n'est pas ouvert au financement (statut : ${loan.status})`,
      );
    }

    const alreadyFunded = loan.investments.reduce(
      (sum, inv) => sum + Number(inv.amount),
      0,
    );
    const remaining = Number(loan.amount) - alreadyFunded;

    if (dto.amount > remaining) {
      throw new BadRequestException(
        `Le montant dépasse le solde restant à financer (${remaining.toLocaleString()} FCFA disponible)`,
      );
    }

    if (Number(investor.wallet_balance) < dto.amount) {
      throw new BadRequestException(
        `Solde insuffisant — votre wallet : ${Number(investor.wallet_balance).toLocaleString()} FCFA`,
      );
    }

    const guaranteeFund = await this.prisma.guaranteeFund.findFirst({
      select: {
        id: true,
        total_capital: true,
        active_portfolio_value: true,
        coverage_ratio: true,
        suspension_active: true,
        min_threshold: true,
      },
    });

    if (guaranteeFund?.suspension_active) {
      throw new BadRequestException(
        `Nouveaux investissements suspendus — ratio fonds de garantie trop bas (${(Number(guaranteeFund.coverage_ratio) * 100).toFixed(2)}%)`,
      );
    }

    // Retour attendu = part proportionnelle des intérêts du prêt
    const totalRepayment =
      Number(loan.monthly_installment) * loan.duration_months;
    const totalInterest = totalRepayment - Number(loan.amount);
    const proportion = dto.amount / Number(loan.amount);
    const expectedReturn = proportion * totalInterest;

    const maturityDate = new Date();
    maturityDate.setMonth(maturityDate.getMonth() + loan.duration_months);

    const isFullyFunded = alreadyFunded + dto.amount >= Number(loan.amount);

    const investment = await this.prisma.$transaction(async (tx) => {
      const created = await tx.investment.create({
        data: {
          investor_id: userId,
          loan_id: dto.loan_id,
          amount: dto.amount,
          expected_return: expectedReturn,
          maturity_date: maturityDate,
          is_guaranteed: true,
          status: 'ACTIVE',
        },
        select: INVESTMENT_BASE,
      });

      await tx.investor.update({
        where: { id: userId },
        data: {
          wallet_balance: { decrement: dto.amount },
          total_invested: { increment: dto.amount },
        },
      });

      if (guaranteeFund) {
        const newPortfolioValue =
          Number(guaranteeFund.active_portfolio_value) + dto.amount;

        await tx.guaranteeFundInvestment.create({
          data: {
            fund_id: guaranteeFund.id,
            investment_id: created.id,
            covered_amount: dto.amount,
          },
        });

        const newRatio =
          newPortfolioValue > 0
            ? Number(guaranteeFund.total_capital) / newPortfolioValue
            : 0;

        await tx.guaranteeFund.update({
          where: { id: guaranteeFund.id },
          data: {
            active_portfolio_value: newPortfolioValue,
            coverage_ratio: newRatio,
            suspension_active: newRatio < Number(guaranteeFund.min_threshold),
          },
        });
      }

      if (isFullyFunded) {
        const nextDueDate = new Date();
        nextDueDate.setMonth(nextDueDate.getMonth() + 1);

        await tx.loan.update({
          where: { id: dto.loan_id },
          data: {
            status: 'ACTIVE',
            disbursed_at: new Date(),
            next_due_date: nextDueDate,
          },
        });

        // Récupérer le borrower pour le décaissement
        const borrower = await tx.borrower.findUniqueOrThrow({
          where: { id: loan.borrower_id },
          select: { id: true, mobile_money_number: true, momo_provider: true },
        });

        const disbRef = `NEXUS-DISB-${Date.now()}-${Math.random().toString(36).substring(2, 7).toUpperCase()}`;

        await tx.transaction.create({
          data: {
            type: 'LOAN_DISBURSEMENT',
            amount: loan.amount,
            status: 'CONFIRMED',
            momo_reference: disbRef,
            momo_provider: borrower.momo_provider,
            confirmed_at: new Date(),
            is_reconciled: true,
            reconciled_at: new Date(),
            created_by: borrower.id,
          },
        });

        this.logger.log(
          `[DISBURSEMENT SIMULATION] → ${borrower.mobile_money_number} | Montant: ${Number(loan.amount).toLocaleString()} FCFA | Provider: ${borrower.momo_provider} | Prêt: ${loan.id} | Ref: ${disbRef}`,
        );
      }

      return created;
    });

    return toInvestmentResponse(investment);
  }

  // ── Mon portefeuille (paginé) ─────────────────────────────────────────────────

  async getMyInvestments(
    userId: string,
    page: number,
    limit: number,
    status?: string,
  ): Promise<PaginatedInvestmentsResponse> {
    const investor = await this.prisma.investor.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!investor) {
      throw new ForbiddenException('Accès réservé aux investisseurs');
    }

    const where = {
      investor_id: userId,
      ...(status
        ? { status: status as investment_status }
        : {}),
    };

    const skip = (page - 1) * limit;

    const [investments, total] = await Promise.all([
      this.prisma.investment.findMany({
        where,
        select: { ...INVESTMENT_BASE, loans: { select: LOAN_DETAIL } },
        orderBy: { maturity_date: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.investment.count({ where }),
    ]);

    return {
      items: investments.map((inv) =>
        toInvestmentResponse(inv, toLoanInfo(inv.loans)),
      ),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Résumé du portefeuille ────────────────────────────────────────────────────

  async getPortfolioSummary(userId: string): Promise<PortfolioSummary> {
    const investor = await this.prisma.investor.findUnique({
      where: { id: userId },
      select: {
        wallet_balance: true,
        total_invested: true,
        total_returns: true,
        risk_profile: true,
        investor_type: true,
      },
    });

    if (!investor) {
      throw new ForbiddenException('Accès réservé aux investisseurs');
    }

    const countsByStatus = await this.prisma.investment.groupBy({
      by: ['status'],
      where: { investor_id: userId },
      _count: { id: true },
    });

    const byStatus = { ACTIVE: 0, COMPLETED: 0, DEFAULTED: 0, GUARANTEED: 0 };
    for (const row of countsByStatus) {
      byStatus[row.status as keyof typeof byStatus] = row._count.id;
    }

    const total = Object.values(byStatus).reduce((a, b) => a + b, 0);
    const nplRatio = total > 0 ? byStatus.DEFAULTED / total : 0;

    const activeSum = await this.prisma.investment.aggregate({
      where: { investor_id: userId, status: 'ACTIVE' },
      _sum: { amount: true },
    });

    return {
      walletBalance: investor.wallet_balance as PortfolioSummary['walletBalance'],
      totalInvested: investor.total_invested as PortfolioSummary['totalInvested'],
      totalReturns: investor.total_returns as PortfolioSummary['totalReturns'],
      riskProfile: investor.risk_profile,
      investorType: investor.investor_type,
      investmentsByStatus: byStatus,
      nplRatio,
      activePortfolioValue: (activeSum._sum.amount ?? 0) as PortfolioSummary['activePortfolioValue'],
    };
  }

  // ── Détail d'un investissement ────────────────────────────────────────────────

  async getInvestmentById(
    userId: string,
    investmentId: string,
  ): Promise<InvestmentResponse> {
    const investment = await this.prisma.investment.findUnique({
      where: { id: investmentId },
      select: { ...INVESTMENT_BASE, loans: { select: LOAN_DETAIL } },
    });

    if (!investment) {
      throw new NotFoundException('Investissement introuvable');
    }

    if (investment.investor_id !== userId) {
      throw new ForbiddenException('Accès refusé à cet investissement');
    }

    return toInvestmentResponse(investment, toLoanInfo(investment.loans));
  }

  // ── Auto-Invest — Créer / Mettre à jour la règle ─────────────────────────────

  async setAutoInvestRule(
    userId: string,
    dto: AutoInvestRuleDto,
  ): Promise<AutoInvestRuleResponse> {
    const investor = await this.prisma.investor.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!investor) throw new ForbiddenException('Accès réservé aux investisseurs');

    const rule = await this.prisma.autoInvestRule.upsert({
      where: { investor_id: userId },
      create: {
        investor_id: userId,
        is_active: dto.is_active,
        max_amount: dto.max_amount,
        max_duration: dto.max_duration,
        min_hybrid_score: dto.min_hybrid_score ?? 0,
      },
      update: {
        is_active: dto.is_active,
        max_amount: dto.max_amount,
        max_duration: dto.max_duration,
        min_hybrid_score: dto.min_hybrid_score ?? 0,
      },
      select: {
        id: true,
        investor_id: true,
        is_active: true,
        max_amount: true,
        max_duration: true,
        min_hybrid_score: true,
        created_at: true,
      },
    });

    return this.toRuleResponse(rule);
  }

  // ── Auto-Invest — Consulter la règle ─────────────────────────────────────────

  async getAutoInvestRule(userId: string): Promise<AutoInvestRuleResponse | null> {
    const investor = await this.prisma.investor.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!investor) throw new ForbiddenException('Accès réservé aux investisseurs');

    const rule = await this.prisma.autoInvestRule.findUnique({
      where: { investor_id: userId },
      select: {
        id: true,
        investor_id: true,
        is_active: true,
        max_amount: true,
        max_duration: true,
        min_hybrid_score: true,
        created_at: true,
      },
    });

    return rule ? this.toRuleResponse(rule) : null;
  }

  // ── Auto-Invest — Exécuter le matching ───────────────────────────────────────

  async runAutoInvest(userId: string): Promise<AutoInvestRunResult> {
    return this.runAutoInvestForInvestor(userId, true);
  }

  @Cron('*/30 * * * *')
  async runScheduledAutoInvest(): Promise<void> {
    const activeRules = await this.prisma.autoInvestRule.findMany({
      where: { is_active: true },
      select: { investor_id: true },
    });

    for (const rule of activeRules) {
      try {
        const result = await this.runAutoInvestForInvestor(rule.investor_id, false);
        if (result.investmentsCreated > 0) {
          this.logger.log(
            `[AUTO-INVEST:CRON] investor=${rule.investor_id} created=${result.investmentsCreated} total=${result.totalInvested}`,
          );
        }
      } catch (error: unknown) {
        this.logger.warn(
          `[AUTO-INVEST:CRON] investor=${rule.investor_id} failed: ${error instanceof Error ? error.message : String(error)}`,
        );
      }
    }
  }

  @Cron('30 1 * * *')
  async maintainGuaranteeFund(): Promise<void> {
    const [fund, platformWallet, activePortfolio] = await Promise.all([
      this.prisma.guaranteeFund.findFirst({
        select: {
          id: true,
          total_capital: true,
          active_portfolio_value: true,
          coverage_ratio: true,
          min_threshold: true,
          target_threshold: true,
          suspension_active: true,
        },
      }),
      this.prisma.platformWallet.findFirst({
        select: {
          id: true,
          commission_balance: true,
        },
      }),
      this.prisma.investment.aggregate({
        where: { status: { in: ['ACTIVE', 'GUARANTEED'] } },
        _sum: { amount: true },
      }),
    ]);

    if (!fund) return;

    const activePortfolioValue = Number(activePortfolio._sum.amount ?? 0);
    const totalCapital = Number(fund.total_capital);
    const targetCapital = activePortfolioValue * Number(fund.target_threshold);
    const requiredTopUp = Math.max(targetCapital - totalCapital, 0);
    const availableCommission = Number(platformWallet?.commission_balance ?? 0);
    const transferAmount = Math.min(requiredTopUp, availableCommission);
    const newCapital = totalCapital + transferAmount;
    const newCoverageRatio =
      activePortfolioValue > 0 ? newCapital / activePortfolioValue : 0;
    const suspensionActive = newCoverageRatio < Number(fund.min_threshold);

    await this.prisma.$transaction(async (tx) => {
      if (platformWallet && transferAmount > 0) {
        await tx.platformWallet.update({
          where: { id: platformWallet.id },
          data: {
            commission_balance: { decrement: transferAmount },
          },
        });
      }

      await tx.guaranteeFund.update({
        where: { id: fund.id },
        data: {
          total_capital: newCapital,
          active_portfolio_value: activePortfolioValue,
          coverage_ratio: newCoverageRatio,
          suspension_active: suspensionActive,
          last_reconstitution_date:
            transferAmount > 0 ? new Date() : undefined,
        },
      });
    });

    this.logger.log(
      `[GUARANTEE:FUND] active=${activePortfolioValue.toFixed(0)} capital=${newCapital.toFixed(0)} transfer=${transferAmount.toFixed(0)} ratio=${(newCoverageRatio * 100).toFixed(2)}%`,
    );
  }

  @Cron('0 2 * * *')
  async activateGuaranteeCoverage(): Promise<void> {
    const triggeredLoans = await this.prisma.loan.findMany({
      where: { status: 'GUARANTEE_ACTIVATED' },
      select: {
        id: true,
        borrower_id: true,
        investments: {
          where: { status: 'ACTIVE', is_guaranteed: true },
          select: {
            id: true,
            amount: true,
            guarantee_fund_investments: {
              where: { is_activated: false },
              select: {
                id: true,
                covered_amount: true,
              },
            },
          },
        },
      },
    });

    for (const loan of triggeredLoans) {
      const guaranteeRows = loan.investments.flatMap((investment) =>
        investment.guarantee_fund_investments.map((row) => ({
          id: row.id,
          investmentId: investment.id,
          coveredAmount: Number(row.covered_amount),
        })),
      );

      if (guaranteeRows.length === 0) {
        continue;
      }

      const totalCovered = guaranteeRows.reduce(
        (sum, row) => sum + row.coveredAmount,
        0,
      );
      const activationReference = `NEXUS-GUARANTEE-${loan.id}`;

      await this.prisma.$transaction(async (tx) => {
        await tx.guaranteeFundInvestment.updateMany({
          where: { id: { in: guaranteeRows.map((row) => row.id) } },
          data: {
            is_activated: true,
            activated_at: new Date(),
          },
        });

        await tx.investment.updateMany({
          where: { id: { in: guaranteeRows.map((row) => row.investmentId) } },
          data: { status: 'GUARANTEED' },
        });

        const existingTx = await tx.transaction.findUnique({
          where: { momo_reference: activationReference },
          select: { id: true },
        });

        if (!existingTx) {
          await tx.transaction.create({
            data: {
              type: 'GUARANTEE_ACTIVATION',
              amount: totalCovered,
              status: 'CONFIRMED',
              momo_reference: activationReference,
              confirmed_at: new Date(),
              is_reconciled: true,
              reconciled_at: new Date(),
              created_by: loan.borrower_id,
            },
          });
        }
      });

      this.logger.warn(
        `[GUARANTEE:ACTIVATION] loan=${loan.id} rows=${guaranteeRows.length} covered=${totalCovered.toFixed(0)}`,
      );
    }
  }

  private async runAutoInvestForInvestor(
    userId: string,
    failIfInactive: boolean,
  ): Promise<AutoInvestRunResult> {
    const investor = await this.prisma.investor.findUnique({
      where: { id: userId },
      select: { id: true, wallet_balance: true },
    });

    if (!investor) throw new ForbiddenException('Accès réservé aux investisseurs');

    const rule = await this.prisma.autoInvestRule.findUnique({
      where: { investor_id: userId },
      select: {
        is_active: true,
        max_amount: true,
        max_duration: true,
        min_hybrid_score: true,
      },
    });

    if (!rule?.is_active) {
      if (!failIfInactive) {
        return {
          loansScanned: 0,
          investmentsCreated: 0,
          totalInvested: 0,
          skipped: [],
        };
      }

      throw new BadRequestException(
        'L\'Auto-Invest est désactivé — activez-le d\'abord via PUT /investments/auto-invest',
      );
    }

    const fundingLoans = await this.prisma.loan.findMany({
      where: {
        status: 'FUNDING',
        duration_months: { lte: rule.max_duration },
      },
      select: {
        id: true,
        amount: true,
        duration_months: true,
        monthly_installment: true,
        investments: { select: { amount: true } },
        borrowers: {
          select: {
            borrower_scores: {
              select: { hybrid_score: true },
              orderBy: { computed_at: 'desc' },
              take: 1,
            },
          },
        },
      },
    });

    const logger = new Logger('AutoInvest');
    const skipped: AutoInvestRunResult['skipped'] = [];
    let investmentsCreated = 0;
    let totalInvested = 0;

    for (const loan of fundingLoans) {
      const latestScore = loan.borrowers.borrower_scores[0];
      const hybridScore = latestScore ? Number(latestScore.hybrid_score) : 0;

      if (hybridScore < Number(rule.min_hybrid_score)) {
        skipped.push({ loanId: loan.id, reason: `Score hybride insuffisant (${hybridScore.toFixed(1)} < ${rule.min_hybrid_score})` });
        continue;
      }

      const alreadyFunded = loan.investments.reduce((s, i) => s + Number(i.amount), 0);
      const remaining = Number(loan.amount) - alreadyFunded;

      if (remaining <= 0) {
        skipped.push({ loanId: loan.id, reason: 'Prêt déjà entièrement financé' });
        continue;
      }

      const currentWallet = Number(
        (await this.prisma.investor.findUnique({ where: { id: userId }, select: { wallet_balance: true } }))
          ?.wallet_balance ?? 0,
      );
      const investAmount = Math.min(Number(rule.max_amount), remaining, currentWallet);

      if (investAmount < 1000) {
        skipped.push({ loanId: loan.id, reason: 'Solde wallet insuffisant pour investir' });
        continue;
      }

      try {
        await this.createInvestment(userId, { loan_id: loan.id, amount: Math.floor(investAmount) });
        investmentsCreated++;
        totalInvested += Math.floor(investAmount);
        logger.log(`[AUTO-INVEST] ${Math.floor(investAmount).toLocaleString()} FCFA → loan ${loan.id}`);

        const investorContact = await this.prisma.user.findUnique({
          where: { id: userId },
          select: { firstName: true, email: true, phone: true },
        });

        if (investorContact) {
          await this.notifications.notifyPaymentInitiated(
            investorContact,
            'deposit',
            Math.floor(investAmount),
            'AUTO_INVEST',
          );
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Erreur inconnue';
        skipped.push({ loanId: loan.id, reason: msg });
      }
    }

    return {
      loansScanned: fundingLoans.length,
      investmentsCreated,
      totalInvested,
      skipped,
    };
  }

  // ── Helper privé ─────────────────────────────────────────────────────────────

  private toRuleResponse(rule: {
    id: string;
    investor_id: string;
    is_active: boolean;
    max_amount: { toString(): string };
    max_duration: number;
    min_hybrid_score: { toString(): string };
    created_at: Date;
  }): AutoInvestRuleResponse {
    return {
      id: rule.id,
      investorId: rule.investor_id,
      isActive: rule.is_active,
      maxAmount: rule.max_amount as AutoInvestRuleResponse['maxAmount'],
      maxDuration: rule.max_duration,
      minHybridScore: rule.min_hybrid_score as AutoInvestRuleResponse['minHybridScore'],
      createdAt: rule.created_at,
    };
  }
}
