import {
  Injectable,
  Logger,
  OnModuleInit,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '@shared/prisma/prisma.service';
import type {
  GuaranteeFundStatusResponse,
  GuaranteedInvestmentItem,
  GuaranteeActivationResult,
} from './dto/guarantee-fund-response.dto';

@Injectable()
export class GuaranteeFundService implements OnModuleInit {
  private readonly logger = new Logger(GuaranteeFundService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ── Initialisation ───────────────────────────────────────────────────────────

  async onModuleInit(): Promise<void> {
    await this.ensureFundExists();
    this.logger.log('✅ GuaranteeFund initialisé');
  }

  private async ensureFundExists(): Promise<void> {
    const existing = await this.prisma.guaranteeFund.findFirst();
    if (!existing) {
      await this.prisma.guaranteeFund.create({
        data: {
          total_capital: 0,
          active_portfolio_value: 0,
          coverage_ratio: 0,
          min_threshold: 0.03,
          target_threshold: 0.05,
          suspension_active: false,
        },
      });
      this.logger.log('GuaranteeFund créé (défaut)');
    }
  }

  // ── État du fonds ────────────────────────────────────────────────────────────

  async getFundStatus(): Promise<GuaranteeFundStatusResponse> {
    const fund = await this.prisma.guaranteeFund.findFirstOrThrow();
    return this.toStatusResponse(fund);
  }

  // ── Activation garantie pour un investissement ───────────────────────────────

  async activateGuarantee(
    investmentId: string,
  ): Promise<GuaranteeActivationResult> {
    const investment = await this.prisma.investment.findUnique({
      where: { id: investmentId },
      select: {
        id: true,
        amount: true,
        status: true,
        is_guaranteed: true,
        loan_id: true,
        investor_id: true,
      },
    });

    if (!investment) {
      throw new NotFoundException('Investissement introuvable');
    }

    if (!investment.is_guaranteed) {
      throw new BadRequestException(
        "Cet investissement n'est pas éligible à la garantie",
      );
    }

    if (investment.status === 'GUARANTEED') {
      throw new BadRequestException(
        'Cet investissement est déjà couvert par la garantie',
      );
    }

    const fund = await this.prisma.guaranteeFund.findFirstOrThrow();

    const existing = await this.prisma.guaranteeFundInvestment.findUnique({
      where: {
        fund_id_investment_id: {
          fund_id: fund.id,
          investment_id: investmentId,
        },
      },
      select: { id: true },
    });

    if (existing) {
      throw new BadRequestException(
        'Une couverture existe déjà pour cet investissement',
      );
    }

    const coveredAmount = Number(investment.amount);

    const result = await this.prisma.$transaction(async (tx) => {
      const gfi = await tx.guaranteeFundInvestment.create({
        data: {
          fund_id: fund.id,
          investment_id: investmentId,
          covered_amount: coveredAmount,
          is_activated: true,
          activated_at: new Date(),
        },
        select: {
          id: true,
          covered_amount: true,
        },
      });

      await tx.investment.update({
        where: { id: investmentId },
        data: { status: 'GUARANTEED' },
      });

      const newCapital = Number(fund.total_capital) - coveredAmount;
      const activePortfolio = await tx.investment.aggregate({
        where: { status: { in: ['ACTIVE', 'GUARANTEED'] } },
        _sum: { amount: true },
      });
      const activePortfolioValue = Number(activePortfolio._sum.amount ?? 0);
      const newCoverageRatio =
        activePortfolioValue > 0 ? newCapital / activePortfolioValue : 0;
      const suspensionActive = newCoverageRatio < Number(fund.min_threshold);

      await tx.guaranteeFund.update({
        where: { id: fund.id },
        data: {
          total_capital: newCapital,
          active_portfolio_value: activePortfolioValue,
          coverage_ratio: newCoverageRatio,
          suspension_active: suspensionActive,
        },
      });

      return {
        fundInvestmentId: gfi.id,
        investmentId,
        coveredAmount:
          gfi.covered_amount.valueOf() as unknown as GuaranteeActivationResult['coveredAmount'],
        newCoverageRatio:
          newCoverageRatio as unknown as GuaranteeActivationResult['newCoverageRatio'],
        suspensionActive,
      };
    });

    this.logger.warn(
      `[GUARANTEE:ACTIVATE] investment=${investmentId} covered=${coveredAmount} ratio=${(Number(result.newCoverageRatio) * 100).toFixed(2)}%`,
    );

    return result;
  }

  // ── Vérifier / mettre à jour la suspension ───────────────────────────────────

  async checkAndUpdateSuspension(): Promise<GuaranteeFundStatusResponse> {
    const fund = await this.prisma.guaranteeFund.findFirstOrThrow();

    const activePortfolio = await this.prisma.investment.aggregate({
      where: { status: { in: ['ACTIVE', 'GUARANTEED'] } },
      _sum: { amount: true },
    });

    const activePortfolioValue = Number(activePortfolio._sum.amount ?? 0);
    const totalCapital = Number(fund.total_capital);
    const coverageRatio =
      activePortfolioValue > 0 ? totalCapital / activePortfolioValue : 0;

    const minThreshold = Number(fund.min_threshold);
    const targetThreshold = Number(fund.target_threshold);

    let suspensionActive = fund.suspension_active;

    if (coverageRatio < minThreshold && !suspensionActive) {
      suspensionActive = true;
      this.logger.warn('[GUARANTEE:SUSPEND] Ratio sous le seuil minimum');
    } else if (coverageRatio >= targetThreshold && suspensionActive) {
      suspensionActive = false;
      this.logger.log(
        '[GUARANTEE:RESUME] Ratio rétabli au-dessus du seuil cible',
      );
    }

    const updated = await this.prisma.guaranteeFund.update({
      where: { id: fund.id },
      data: {
        active_portfolio_value: activePortfolioValue,
        coverage_ratio: coverageRatio,
        suspension_active: suspensionActive,
      },
    });

    return this.toStatusResponse(updated);
  }

  // ── Recalculer le ratio ──────────────────────────────────────────────────────

  async recalculateCoverageRatio(): Promise<GuaranteeFundStatusResponse> {
    const fund = await this.prisma.guaranteeFund.findFirstOrThrow();

    const activePortfolio = await this.prisma.investment.aggregate({
      where: { status: { in: ['ACTIVE', 'GUARANTEED'] } },
      _sum: { amount: true },
    });

    const activePortfolioValue = Number(activePortfolio._sum.amount ?? 0);
    const totalCapital = Number(fund.total_capital);
    const coverageRatio =
      activePortfolioValue > 0 ? totalCapital / activePortfolioValue : 0;

    const updated = await this.prisma.guaranteeFund.update({
      where: { id: fund.id },
      data: {
        active_portfolio_value: activePortfolioValue,
        coverage_ratio: coverageRatio,
      },
    });

    return this.toStatusResponse(updated);
  }

  // ── Liste des investissements couverts ───────────────────────────────────────

  async getGuaranteedInvestments(): Promise<GuaranteedInvestmentItem[]> {
    const rows = await this.prisma.guaranteeFundInvestment.findMany({
      select: {
        id: true,
        fund_id: true,
        investment_id: true,
        covered_amount: true,
        is_activated: true,
        activated_at: true,
        investments: {
          select: {
            loan_id: true,
            amount: true,
            investors: {
              select: {
                user: {
                  select: {
                    firstName: true,
                    lastName: true,
                    email: true,
                  },
                },
              },
            },
            loans: {
              select: {
                status: true,
              },
            },
          },
        },
      },
      orderBy: { activated_at: 'desc' },
    });

    return rows.map((r) => ({
      id: r.id,
      fundId: r.fund_id,
      investmentId: r.investment_id,
      coveredAmount:
        r.covered_amount.valueOf() as unknown as GuaranteedInvestmentItem['coveredAmount'],
      isActivated: r.is_activated,
      activatedAt: r.activated_at,
      investorName: `${r.investments.investors.user.firstName} ${r.investments.investors.user.lastName}`,
      investorEmail: r.investments.investors.user.email,
      loanId: r.investments.loan_id,
      loanAmount:
        r.investments.amount.valueOf() as unknown as GuaranteedInvestmentItem['loanAmount'],
      loanStatus: r.investments.loans.status,
    }));
  }

  // ── Helper ───────────────────────────────────────────────────────────────────

  private toStatusResponse(fund: {
    id: string;
    total_capital: { valueOf(): string };
    active_portfolio_value: { valueOf(): string };
    coverage_ratio: { valueOf(): string };
    min_threshold: { valueOf(): string };
    target_threshold: { valueOf(): string };
    suspension_active: boolean;
    last_reconstitution_date: Date | null;
  }): GuaranteeFundStatusResponse {
    return {
      id: fund.id,
      totalCapital:
        fund.total_capital.valueOf() as unknown as GuaranteeFundStatusResponse['totalCapital'],
      activePortfolioValue:
        fund.active_portfolio_value.valueOf() as unknown as GuaranteeFundStatusResponse['activePortfolioValue'],
      coverageRatio:
        fund.coverage_ratio.valueOf() as unknown as GuaranteeFundStatusResponse['coverageRatio'],
      minThreshold:
        fund.min_threshold.valueOf() as unknown as GuaranteeFundStatusResponse['minThreshold'],
      targetThreshold:
        fund.target_threshold.valueOf() as unknown as GuaranteeFundStatusResponse['targetThreshold'],
      suspensionActive: fund.suspension_active,
      lastReconstitutionDate: fund.last_reconstitution_date,
    };
  }
}
