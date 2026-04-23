import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '@shared/prisma/prisma.service';
import { AppCacheService } from '@shared/cache/app-cache.service';
import type { user_status } from '@generated/prisma';
import type { UpdateUserStatusDto } from './dto/update-user-status.dto';
import type {
  DashboardResponse,
  BceaoReportResponse,
  GuaranteeFundResponse,
  AdminUserItem,
  PaginatedAdminUsersResponse,
} from './dto/admin-response.dto';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: AppCacheService,
  ) {}

  // ── Dashboard global ─────────────────────────────────────────────────────────

  async getDashboard(): Promise<DashboardResponse> {
    return this.cache.getOrSet('admin:dashboard', 60_000, async () => {
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);

      const [
        totalUsers,
        kycValidated,
        kycPending,
        loanCounts,
        portfolioValue,
        txToday,
        txPending,
        txPhantom,
        guaranteeFund,
      ] = await Promise.all([
        this.prisma.user.count(),
        this.prisma.user.count({ where: { kyc_status: 'VALIDATED' } }),
        this.prisma.user.count({ where: { kyc_status: 'SESSION2_DONE', kycSubmittedAt: { not: null } } }),
        this.prisma.loan.groupBy({
          by: ['status'],
          _count: { id: true },
        }),
        this.prisma.loan.aggregate({
          where: { status: { in: ['ACTIVE', 'OVERDUE', 'FUNDING'] } },
          _sum: { outstanding_balance: true },
        }),
        this.prisma.transaction.aggregate({
          where: { initiated_at: { gte: todayStart } },
          _count: { id: true },
          _sum: { amount: true },
        }),
        this.prisma.transaction.count({ where: { status: 'PENDING' } }),
        this.prisma.transaction.count({ where: { status: 'PHANTOM_DETECTED' } }),
        this.prisma.guaranteeFund.findFirst({
          select: {
            total_capital: true,
            active_portfolio_value: true,
            coverage_ratio: true,
            suspension_active: true,
          },
        }),
      ]);

      const byStatus = Object.fromEntries(
        loanCounts.map((r) => [r.status, r._count.id]),
      ) as Record<string, number>;

      const totalLoans = loanCounts.reduce((s, r) => s + r._count.id, 0);
      const overdueCount = byStatus['OVERDUE'] ?? 0;
      const activeCount = byStatus['ACTIVE'] ?? 0;
      const nplRatio = totalLoans > 0 ? overdueCount / totalLoans : 0;

      return {
        users: {
          total: totalUsers,
          kycValidated,
          kycPending,
          activeToday: txToday._count.id,
        },
        loans: {
          totalCount: totalLoans,
          activeCount,
          overdueCount,
          repaidCount: byStatus['REPAID'] ?? 0,
          pendingImfCount: byStatus['PENDING_IMF'] ?? 0,
          totalPortfolioValue: (portfolioValue._sum.outstanding_balance ?? 0) as DashboardResponse['loans']['totalPortfolioValue'],
          nplRatio,
        },
        transactions: {
          todayCount: txToday._count.id,
          todayVolume: (txToday._sum.amount ?? 0) as DashboardResponse['transactions']['todayVolume'],
          pendingCount: txPending,
          phantomCount: txPhantom,
        },
        guaranteeFund: guaranteeFund
          ? {
              totalCapital: guaranteeFund.total_capital as NonNullable<DashboardResponse['guaranteeFund']>['totalCapital'],
              activePortfolioValue: guaranteeFund.active_portfolio_value as NonNullable<DashboardResponse['guaranteeFund']>['activePortfolioValue'],
              coverageRatio: guaranteeFund.coverage_ratio as NonNullable<DashboardResponse['guaranteeFund']>['coverageRatio'],
              suspensionActive: guaranteeFund.suspension_active,
            }
          : null,
      };
    });
  }

  // ── Rapport BCEAO ────────────────────────────────────────────────────────────

  async getBceaoReport(from: string, to: string): Promise<BceaoReportResponse> {
    const fromDate = new Date(from);
    const toDate = new Date(to);
    toDate.setHours(23, 59, 59, 999);

    const [
      loansInPeriod,
      loansByDuration,
      txReconciled,
      txUnreconciled,
      txVolume,
      txPhantom,
      guaranteeFund,
    ] = await Promise.all([
      this.prisma.loan.aggregate({
        where: {
          status: { in: ['ACTIVE', 'OVERDUE', 'REPAID'] },
          created_at: { gte: fromDate, lte: toDate },
        },
        _sum: { amount: true, outstanding_balance: true },
      }),
      this.prisma.loan.groupBy({
        by: ['duration_months'],
        where: { created_at: { gte: fromDate, lte: toDate } },
        _count: { id: true },
        _sum: { amount: true },
      }),
      this.prisma.transaction.count({
        where: { is_reconciled: true, initiated_at: { gte: fromDate, lte: toDate } },
      }),
      this.prisma.transaction.count({
        where: { is_reconciled: false, initiated_at: { gte: fromDate, lte: toDate } },
      }),
      this.prisma.transaction.aggregate({
        where: { initiated_at: { gte: fromDate, lte: toDate } },
        _sum: { amount: true },
      }),
      this.prisma.transaction.count({
        where: { status: 'PHANTOM_DETECTED', initiated_at: { gte: fromDate, lte: toDate } },
      }),
      this.prisma.guaranteeFund.findFirst({
        select: {
          coverage_ratio: true,
          min_threshold: true,
          target_threshold: true,
          suspension_active: true,
        },
      }),
    ]);

    // Répartition par tranche de montant (règle BCEAO)
    const ranges = [
      { label: '25 000 – 100 000 FCFA', min: 25000, max: 100000 },
      { label: '100 001 – 250 000 FCFA', min: 100001, max: 250000 },
      { label: '250 001 – 500 000 FCFA', min: 250001, max: 500000 },
    ];

    const byAmountRange = await Promise.all(
      ranges.map(async (r) => {
        const agg = await this.prisma.loan.aggregate({
          where: {
            created_at: { gte: fromDate, lte: toDate },
            amount: { gte: r.min, lte: r.max },
          },
          _count: { id: true },
          _sum: { amount: true },
        });
        return {
          label: r.label,
          count: agg._count.id,
          amount: (agg._sum.amount ?? 0) as BceaoReportResponse['loans']['byAmountRange'][number]['amount'],
        };
      }),
    );

    const totalLoans = loansByDuration.reduce((s, r) => s + r._count.id, 0);
    const overdueCount = await this.prisma.loan.count({
      where: { status: 'OVERDUE', created_at: { gte: fromDate, lte: toDate } },
    });
    const nplRate = totalLoans > 0 ? overdueCount / totalLoans : 0;

    return {
      generatedAt: new Date(),
      period: { from, to },
      loans: {
        totalEncours: (loansInPeriod._sum.outstanding_balance ?? 0) as BceaoReportResponse['loans']['totalEncours'],
        totalDisbursed: (loansInPeriod._sum.amount ?? 0) as BceaoReportResponse['loans']['totalDisbursed'],
        nplRate,
        byDuration: loansByDuration.map((r) => ({
          months: r.duration_months,
          count: r._count.id,
          amount: (r._sum.amount ?? 0) as BceaoReportResponse['loans']['byDuration'][number]['amount'],
        })),
        byAmountRange,
      },
      transactions: {
        totalReconciled: txReconciled,
        totalUnreconciled: txUnreconciled,
        totalVolume: (txVolume._sum.amount ?? 0) as BceaoReportResponse['transactions']['totalVolume'],
        phantomCount: txPhantom,
      },
      guaranteeFund: guaranteeFund
        ? {
            coverageRatio: guaranteeFund.coverage_ratio as NonNullable<BceaoReportResponse['guaranteeFund']>['coverageRatio'],
            minThreshold: guaranteeFund.min_threshold as NonNullable<BceaoReportResponse['guaranteeFund']>['minThreshold'],
            targetThreshold: guaranteeFund.target_threshold as NonNullable<BceaoReportResponse['guaranteeFund']>['targetThreshold'],
            suspensionActive: guaranteeFund.suspension_active,
          }
        : null,
    };
  }

  // ── Fonds de garantie ────────────────────────────────────────────────────────

  async getGuaranteeFund(): Promise<GuaranteeFundResponse | null> {
    const fund = await this.cache.getOrSet('admin:guarantee-fund', 60_000, () =>
      this.prisma.guaranteeFund.findFirst({
        select: {
          id: true,
          total_capital: true,
          active_portfolio_value: true,
          coverage_ratio: true,
          min_threshold: true,
          target_threshold: true,
          suspension_active: true,
          last_reconstitution_date: true,
        },
      }),
    );

    if (!fund) return null;

    return {
      id: fund.id,
      totalCapital: fund.total_capital as GuaranteeFundResponse['totalCapital'],
      activePortfolioValue: fund.active_portfolio_value as GuaranteeFundResponse['activePortfolioValue'],
      coverageRatio: fund.coverage_ratio as GuaranteeFundResponse['coverageRatio'],
      minThreshold: fund.min_threshold as GuaranteeFundResponse['minThreshold'],
      targetThreshold: fund.target_threshold as GuaranteeFundResponse['targetThreshold'],
      suspensionActive: fund.suspension_active,
      lastReconstituionDate: fund.last_reconstitution_date,
    };
  }

  // ── Gestion utilisateurs ──────────────────────────────────────────────────────

  async listUsers(
    page: number,
    limit: number,
    status?: string,
    kyc_status?: string,
  ): Promise<PaginatedAdminUsersResponse> {
    const where = {
      ...(status ? { status: status as user_status } : {}),
      ...(kyc_status ? { kyc_status: kyc_status as never } : {}),
    };

    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          id: true,
          firstName: true,
          lastName: true,
          phone: true,
          email: true,
          status: true,
          kyc_status: true,
          isPhoneVerified: true,
          created_at: true,
          admin: { select: { id: true } },
          imfStaff: { select: { id: true } },
          agent: { select: { id: true } },
          investor: { select: { id: true } },
          borrower: { select: { id: true } },
        },
        orderBy: { created_at: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      items: users.map((u) => ({
        id: u.id,
        firstName: u.firstName,
        lastName: u.lastName,
        phone: u.phone,
        email: u.email,
        status: u.status,
        kyc_status: u.kyc_status,
        isPhoneVerified: u.isPhoneVerified,
        createdAt: u.created_at,
        role: u.admin
          ? 'admin'
          : u.imfStaff
            ? 'imf_staff'
            : u.agent
              ? 'agent'
              : u.investor
                ? 'investor'
                : u.borrower
                  ? 'borrower'
                  : 'user',
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getUserById(userId: string): Promise<AdminUserItem> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phone: true,
        email: true,
        status: true,
        kyc_status: true,
        isPhoneVerified: true,
        created_at: true,
        admin: { select: { id: true } },
        imfStaff: { select: { id: true } },
        agent: { select: { id: true } },
        investor: { select: { id: true } },
        borrower: { select: { id: true } },
      },
    });

    if (!user) throw new NotFoundException('Utilisateur introuvable');

    return {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      email: user.email,
      status: user.status,
      kyc_status: user.kyc_status,
      isPhoneVerified: user.isPhoneVerified,
      createdAt: user.created_at,
      role: user.admin
        ? 'admin'
        : user.imfStaff
          ? 'imf_staff'
          : user.agent
            ? 'agent'
            : user.investor
              ? 'investor'
              : user.borrower
                ? 'borrower'
                : 'user',
    };
  }

  async updateUserStatus(
    adminId: string,
    targetUserId: string,
    dto: UpdateUserStatusDto,
  ): Promise<AdminUserItem> {
    const admin = await this.prisma.admin.findUnique({
      where: { id: adminId },
      select: { id: true },
    });

    if (!admin) throw new ForbiddenException('Accès réservé aux administrateurs');

    await this.prisma.user.findUniqueOrThrow({ where: { id: targetUserId }, select: { id: true } });

    await this.prisma.user.update({
      where: { id: targetUserId },
      data: { status: dto.status },
    });

    return this.getUserById(targetUserId);
  }
}
