import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '@shared/prisma/prisma.service';
import type { KycSession1Dto } from './dto/kyc-session1.dto';
import type { KycSession2Dto } from './dto/kyc-session2.dto';
import type { KycValidateDto } from './dto/kyc-validate.dto';
import type {
  KycStatusResponse,
  PaginatedKycResponse,
  UserProfileResponse,
  InvestorData,
  BorrowerData,
  UserRole,
} from './dto/user-response.dto';

// ── Prisma select partagé ─────────────────────────────────────────────────────

const KYC_SELECT = {
  id: true,
  kyc_status: true,
  kycDocumentType: true,
  kycDocumentUrl: true,
  kycSelfieUrl: true,
  kycMonthlyIncome: true,
  kycIncomeSource: true,
  kycMomoStatement: true,
  kycRejectionReason: true,
  kycSubmittedAt: true,
  kycValidatedAt: true,
} as const;

// ── Helpers ───────────────────────────────────────────────────────────────────

function sessionsCompleted(status: string): number {
  switch (status) {
    case 'SESSION1_DONE':
      return 1;
    case 'SESSION2_DONE':
      return 2;
    case 'VALIDATED':
      return 3;
    default:
      return 0;
  }
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  // ── KYC Session 1 ───────────────────────────────────────────────────────────

  async submitKycSession1(
    userId: string,
    dto: KycSession1Dto,
  ): Promise<KycStatusResponse> {
    const user = await this.findUserOrThrow(userId);

    const allowedStatuses = ['NOT_STARTED', 'REJECTED'];
    if (!allowedStatuses.includes(user.kyc_status)) {
      throw new BadRequestException(
        `Session 1 déjà complétée (statut actuel : ${user.kyc_status})`,
      );
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        kycDocumentType: dto.documentType,
        kycDocumentUrl: dto.documentUrl,
        kycSelfieUrl: dto.selfieUrl,
        kyc_status: 'SESSION1_DONE',
        // Réinitialiser les sessions suivantes en cas de recommencement
        kycMonthlyIncome: null,
        kycIncomeSource: null,
        kycMomoStatement: null,
        kycRejectionReason: null,
        kycSubmittedAt: null,
        kycValidatedAt: null,
        kycValidatedBy: null,
      },
      select: KYC_SELECT,
    });

    return this.toKycStatus(updated);
  }

  // ── KYC Session 2 ───────────────────────────────────────────────────────────

  async submitKycSession2(
    userId: string,
    dto: KycSession2Dto,
  ): Promise<KycStatusResponse> {
    const user = await this.findUserOrThrow(userId);

    if (user.kyc_status !== 'SESSION1_DONE') {
      throw new BadRequestException(
        `La session 1 doit être complétée avant la session 2 (statut actuel : ${user.kyc_status})`,
      );
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        kycMonthlyIncome: dto.monthlyIncome,
        kycIncomeSource: dto.incomeSource,
        kycMomoStatement: dto.momoStatementUrl ?? null,
        kyc_status: 'SESSION2_DONE',
      },
      select: KYC_SELECT,
    });

    return this.toKycStatus(updated);
  }

  // ── KYC Session 3 (soumission finale) ───────────────────────────────────────

  async submitKycSession3(userId: string): Promise<KycStatusResponse> {
    const user = await this.findUserOrThrow(userId);

    if (user.kyc_status !== 'SESSION2_DONE') {
      throw new BadRequestException(
        `La session 2 doit être complétée avant la soumission finale (statut actuel : ${user.kyc_status})`,
      );
    }

    if (user.kycSubmittedAt) {
      throw new BadRequestException(
        'Le dossier KYC a déjà été soumis et est en attente de validation',
      );
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { kycSubmittedAt: new Date() },
      select: KYC_SELECT,
    });

    return this.toKycStatus(updated);
  }

  // ── Statut KYC ──────────────────────────────────────────────────────────────

  async getKycStatus(userId: string): Promise<KycStatusResponse> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: KYC_SELECT,
    });

    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    return this.toKycStatus(user);
  }

  // ── Dossiers KYC en attente (IMF Staff) ────────────────────────────────────

  async getPendingKycDossiers(
    page: number,
    limit: number,
  ): Promise<PaginatedKycResponse> {
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where: {
          kyc_status: 'SESSION2_DONE',
          kycSubmittedAt: { not: null },
        },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          phone: true,
          email: true,
          kycSubmittedAt: true,
          kyc_status: true,
        },
        orderBy: { kycSubmittedAt: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.user.count({
        where: {
          kyc_status: 'SESSION2_DONE',
          kycSubmittedAt: { not: null },
        },
      }),
    ]);

    return {
      items: items.map((u) => ({
        id: u.id,
        firstName: u.firstName,
        lastName: u.lastName,
        phone: u.phone,
        email: u.email,
        kycSubmittedAt: u.kycSubmittedAt,
          kycStatus: u.kyc_status,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Validation KYC (IMF Staff) ──────────────────────────────────────────────

  async validateKyc(
    imfStaffUserId: string,
    targetUserId: string,
    dto: KycValidateDto,
  ): Promise<KycStatusResponse> {
    // Vérifier que l'IMF Staff existe bien
    const imfStaff = await this.prisma.imfStaff.findUnique({
      where: { id: imfStaffUserId },
      select: { id: true },
    });

    if (!imfStaff) {
      throw new ForbiddenException('Accès réservé au personnel IMF');
    }

    const target = await this.findUserOrThrow(targetUserId);

    if (target.kyc_status !== 'SESSION2_DONE') {
      throw new BadRequestException(
        `Le dossier n'est pas en attente de validation (statut : ${target.kyc_status})`,
      );
    }

    if (!target.kycSubmittedAt) {
      throw new BadRequestException(
        "Le dossier n'a pas encore été soumis par l'utilisateur",
      );
    }

    const newStatus = dto.decision === 'APPROVED' ? 'VALIDATED' : 'REJECTED';

    const updated = await this.prisma.user.update({
      where: { id: targetUserId },
      data: {
        kyc_status: newStatus,
        kycValidatedAt: new Date(),
        kycValidatedBy: imfStaffUserId,
        kycRejectionReason: dto.decision === 'REJECTED' ? dto.reason : null,
        // Si validé, activer le compte
        status: dto.decision === 'APPROVED' ? 'ACTIVE' : undefined,
      },
      select: KYC_SELECT,
    });

    return this.toKycStatus(updated);
  }

  // ── Profil complet ──────────────────────────────────────────────────────────

  async getUserProfile(userId: string): Promise<UserProfileResponse> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phone: true,
        email: true,
        city: true,
        district: true,
        avatar: true,
        status: true,
        kyc_status: true,
        isEmailVerified: true,
        investor: {
          select: {
            wallet_balance: true,
            total_invested: true,
            total_returns: true,
            risk_profile: true,
            investor_type: true,
          },
        },
        borrower: {
          select: {
            credit_score: true,
            tontine_score: true,
            has_tontine_history: true,
            default_count: true,
            mobile_money_number: true,
          },
        },
        admin: { select: { id: true } },
        imfStaff: { select: { id: true } },
        agent: { select: { id: true } },
      },
    });

    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    const role = this.determineRole(user);

    const investorData: InvestorData | null = user.investor
      ? {
          walletBalance: user.investor.wallet_balance,
          totalInvested: user.investor.total_invested,
          totalReturns: user.investor.total_returns,
          riskProfile: user.investor.risk_profile,
          investorType: user.investor.investor_type,
        }
      : null;

    const borrowerData: BorrowerData | null = user.borrower
      ? {
          creditScore: user.borrower.credit_score,
          tontineScore: user.borrower.tontine_score,
          hasTontineHistory: user.borrower.has_tontine_history,
          defaultCount: user.borrower.default_count,
          mobileMoneyNumber: user.borrower.mobile_money_number,
        }
      : null;

    return {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      email: user.email,
      city: user.city,
      district: user.district,
      avatar: user.avatar,
      status: user.status,
      kycStatus: user.kyc_status,
      isEmailVerified: user.isEmailVerified,
      role,
      investorData,
      borrowerData,
    };
  }

  // ── Helpers privés ──────────────────────────────────────────────────────────

  private async findUserOrThrow(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        ...KYC_SELECT,
        kycValidatedBy: true,
      },
    });

    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    return user;
  }

  private toKycStatus(user: {
    id: string;
    kyc_status: string;
    kycDocumentType: string | null;
    kycDocumentUrl: string | null;
    kycSelfieUrl: string | null;
    kycMonthlyIncome: { toString(): string } | null;
    kycIncomeSource: string | null;
    kycMomoStatement: string | null;
    kycRejectionReason: string | null;
    kycSubmittedAt: Date | null;
    kycValidatedAt: Date | null;
  }): KycStatusResponse {
    return {
      userId: user.id,
      kycStatus: user.kyc_status,
      sessionsCompleted: sessionsCompleted(user.kyc_status),
      kycDocumentType: user.kycDocumentType,
      kycDocumentUrl: user.kycDocumentUrl,
      kycSelfieUrl: user.kycSelfieUrl,
      kycMonthlyIncome:
        user.kycMonthlyIncome as KycStatusResponse['kycMonthlyIncome'],
      kycIncomeSource: user.kycIncomeSource,
      kycMomoStatement: user.kycMomoStatement,
      kycRejectionReason: user.kycRejectionReason,
      kycSubmittedAt: user.kycSubmittedAt,
      kycValidatedAt: user.kycValidatedAt,
    };
  }

  private determineRole(user: {
    investor: object | null;
    borrower: object | null;
    admin: object | null;
    imfStaff: object | null;
    agent: object | null;
  }): UserRole {
    if (user.admin) return 'admin';
    if (user.imfStaff) return 'imf_staff';
    if (user.agent) return 'agent';
    if (user.investor) return 'investor';
    if (user.borrower) return 'borrower';
    return 'user';
  }
}
