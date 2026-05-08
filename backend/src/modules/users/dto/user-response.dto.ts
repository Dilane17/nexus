import type { Prisma } from '@generated/prisma';
type Decimal = Prisma.Decimal;

// ── Statut KYC ────────────────────────────────────────────────────────────────

export interface KycStatusResponse {
  userId: string;
  kyc_status: string;
  sessionsCompleted: number;
  kycDocumentType: string | null;
  kycDocumentUrl: string | null;
  kycSelfieUrl: string | null;
  kycMonthlyIncome: Decimal | null;
  kycIncomeSource: string | null;
  kycMomoStatement: string | null;
  kycRejectionReason: string | null;
  kycSubmittedAt: Date | null;
  kycValidatedAt: Date | null;
}

// ── Dossiers KYC en attente ───────────────────────────────────────────────────

export interface PendingKycItem {
  userId: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  email: string;
  kycSubmittedAt: Date | null;
  kyc_status: string;
}

export interface PaginatedKycResponse {
  items: PendingKycItem[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// ── Profil complet ────────────────────────────────────────────────────────────

export interface InvestorData {
  walletBalance: Decimal;
  totalInvested: Decimal;
  totalReturns: Decimal;
  riskProfile: string;
  investorType: string;
}

export interface BorrowerData {
  creditScore: Decimal;
  tontineScore: Decimal;
  hasTontineHistory: boolean;
  defaultCount: number;
  mobileMoneyNumber: string;
}

export type UserRole =
  | 'investor'
  | 'borrower'
  | 'imf_staff'
  | 'admin'
  | 'agent'
  | 'user';

export interface UserProfileResponse {
  id: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  email: string;
  city: string | null;
  district: string | null;
  avatar: string | null;
  status: string;
  kyc_status: string;
  isEmailVerified: boolean;
  role: UserRole;
  investorData: InvestorData | null;
  borrowerData: BorrowerData | null;
}
