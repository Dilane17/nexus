import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@shared/prisma/prisma.service';
import type {
  ImfStaffProfileResponse,
  ImfStaffLoanItem,
  PaginatedImfStaffLoansResponse,
  ImfStaffDashboardResponse,
} from './dto/imf-staff-response.dto';

@Injectable()
export class ImfStaffService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Profil ───────────────────────────────────────────────────────────────────

  async getProfile(userId: string): Promise<ImfStaffProfileResponse> {
    const imfStaff = await this.prisma.imfStaff.findUnique({
      where: { id: userId },
      select: {
        id: true,
        imf_name: true,
        license_number: true,
        bceao_agreement_ref: true,
        user: {
          select: {
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
            status: true,
            created_at: true,
          },
        },
      },
    });

    if (!imfStaff) {
      throw new NotFoundException('Profil IMF introuvable');
    }

    return {
      id: imfStaff.id,
      firstName: imfStaff.user.firstName,
      lastName: imfStaff.user.lastName,
      email: imfStaff.user.email,
      phone: imfStaff.user.phone,
      imfName: imfStaff.imf_name,
      licenseNumber: imfStaff.license_number,
      bceaoAgreementRef: imfStaff.bceao_agreement_ref,
      status: imfStaff.user.status,
      createdAt: imfStaff.user.created_at,
    };
  }

  // ── Prêts en attente de validation ───────────────────────────────────────────

  async getPendingLoans(
    page: number,
    limit: number,
  ): Promise<PaginatedImfStaffLoansResponse> {
    const skip = (page - 1) * limit;

    const [loans, total] = await Promise.all([
      this.prisma.loan.findMany({
        where: { status: 'PENDING_IMF' },
        select: {
          id: true,
          borrower_id: true,
          amount: true,
          duration_months: true,
          interest_rate: true,
          purpose: true,
          status: true,
          created_at: true,
          validated_by_imf: true,
          rejection_reason: true,
          borrowers: {
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
        },
        orderBy: { created_at: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.loan.count({ where: { status: 'PENDING_IMF' } }),
    ]);

    return {
      items: loans.map((l) => this.toLoanItem(l)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Prêts déjà traités ───────────────────────────────────────────────────────

  async getValidatedLoans(
    page: number,
    limit: number,
  ): Promise<PaginatedImfStaffLoansResponse> {
    const skip = (page - 1) * limit;

    const [loans, total] = await Promise.all([
      this.prisma.loan.findMany({
        where: {
          status: {
            in: ['FUNDING', 'ACTIVE', 'OVERDUE', 'REPAID', 'CANCELLED'],
          },
          validated_by_imf: true,
        },
        select: {
          id: true,
          borrower_id: true,
          amount: true,
          duration_months: true,
          interest_rate: true,
          purpose: true,
          status: true,
          created_at: true,
          validated_by_imf: true,
          rejection_reason: true,
          borrowers: {
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
        },
        orderBy: { created_at: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.loan.count({
        where: {
          status: {
            in: ['FUNDING', 'ACTIVE', 'OVERDUE', 'REPAID', 'CANCELLED'],
          },
          validated_by_imf: true,
        },
      }),
    ]);

    return {
      items: loans.map((l) => this.toLoanItem(l)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Dashboard ────────────────────────────────────────────────────────────────

  async getDashboardStats(): Promise<ImfStaffDashboardResponse> {
    const [pendingCount, validatedCount, rejectedCount, portfolioAgg, recentLoans] =
      await Promise.all([
        this.prisma.loan.count({ where: { status: 'PENDING_IMF' } }),
        this.prisma.loan.count({
          where: {
            status: { in: ['FUNDING', 'ACTIVE', 'OVERDUE', 'REPAID'] },
            validated_by_imf: true,
          },
        }),
        this.prisma.loan.count({
          where: { status: 'CANCELLED', rejection_reason: { not: null } },
        }),
        this.prisma.loan.aggregate({
          where: {
            status: { in: ['ACTIVE', 'OVERDUE', 'FUNDING'] },
          },
          _sum: { amount: true },
        }),
        this.prisma.loan.findMany({
          where: {
            OR: [
              { status: 'PENDING_IMF' },
              { validated_by_imf: true },
              { rejection_reason: { not: null } },
            ],
          },
          select: {
            id: true,
            borrower_id: true,
            amount: true,
            duration_months: true,
            interest_rate: true,
            purpose: true,
            status: true,
            created_at: true,
            validated_by_imf: true,
            rejection_reason: true,
            borrowers: {
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
          },
          orderBy: { created_at: 'desc' },
          take: 10,
        }),
      ]);

    return {
      pendingCount,
      validatedCount,
      rejectedCount,
      totalProcessed: validatedCount + rejectedCount,
      totalPortfolioValue: (portfolioAgg._sum.amount ?? 0) as ImfStaffDashboardResponse['totalPortfolioValue'],
      recentActivity: recentLoans.map((l) => this.toLoanItem(l)),
    };
  }

  // ── Helper ───────────────────────────────────────────────────────────────────

  private toLoanItem(loan: {
    id: string;
    borrower_id: string;
    amount: { valueOf(): string };
    duration_months: number;
    interest_rate: { valueOf(): string };
    purpose: string | null;
    status: string;
    created_at: Date;
    validated_by_imf: boolean;
    rejection_reason: string | null;
    borrowers: {
      user: {
        firstName: string;
        lastName: string;
        email: string;
      };
    };
  }): ImfStaffLoanItem {
    return {
      id: loan.id,
      borrowerId: loan.borrower_id,
      borrowerName: `${loan.borrowers.user.firstName} ${loan.borrowers.user.lastName}`,
      borrowerEmail: loan.borrowers.user.email,
      amount: loan.amount.valueOf() as unknown as ImfStaffLoanItem['amount'],
      durationMonths: loan.duration_months,
      interestRate: loan.interest_rate.valueOf() as unknown as ImfStaffLoanItem['interestRate'],
      purpose: loan.purpose ?? '',
      status: loan.status,
      createdAt: loan.created_at,
      validatedAt: loan.validated_by_imf ? loan.created_at : null,
      rejectedAt: loan.rejection_reason ? loan.created_at : null,
      rejectionReason: loan.rejection_reason,
    };
  }
}
