export type UserRole = 'admin' | 'imf_staff' | 'investor' | 'borrower' | 'agent' | 'user';

export type KycStatus = 'PENDING' | 'SESSION1_DONE' | 'SESSION2_DONE' | 'VALIDATED' | 'REJECTED';

export type LoanStatus =
  | 'PENDING_IMF'
  | 'REJECTED'
  | 'APPROVED'
  | 'FUNDING'
  | 'FUNDED'
  | 'ACTIVE'
  | 'OVERDUE'
  | 'REPAID'
  | 'DEFAULTED';

export interface AuthUser {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  city: string | null;
  district: string | null;
  avatar: string | null;
  status: string;
  kycStatus: KycStatus;
  isEmailVerified: boolean;
  role?: UserRole;
}

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
  iat?: number;
  exp?: number;
}

export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  city: string | null;
  district: string | null;
  avatar: string | null;
  status: string;
  kycStatus: KycStatus;
  isEmailVerified: boolean;
  role: UserRole;
  kycDocumentType: string | null;
  kycDocumentUrl: string | null;
  kycSelfieUrl: string | null;
  kycMonthlyIncome: number | null;
  kycIncomeSource: string | null;
  kycMomoStatement: string | null;
  kycRejectionReason: string | null;
  kycSubmittedAt: string | null;
  kycValidatedAt: string | null;
  createdAt?: string;
}

export interface Loan {
  id: string;
  borrowerId: string;
  amount: number;
  interestRate: number;
  durationMonths: number;
  status: LoanStatus;
  monthlyInstallment: number;
  outstandingBalance: number;
  daysOverdue: number;
  validatedByImf: boolean;
  hybridScore: number | null;
  disbursedAt: string | null;
  nextDueDate: string | null;
  purpose: string;
  rejectionReason: string | null;
  createdAt: string;
  investmentsCount?: number;
  borrower?: Pick<User, 'id' | 'firstName' | 'lastName' | 'email'>;
}

export interface DashboardStats {
  users: {
    total: number;
    kycValidated: number;
    kycPending: number;
    activeToday: number;
  };
  loans: {
    totalCount: number;
    activeCount: number;
    overdueCount: number;
    repaidCount: number;
    pendingImfCount: number;
    totalPortfolioValue: number;
    nplRatio: number;
  };
  transactions: {
    todayCount: number;
    todayVolume: number;
    pendingCount: number;
    phantomCount: number;
  };
  guaranteeFund: {
    totalCapital: number;
    activePortfolioValue: number;
    coverageRatio: number;
    suspensionActive: boolean;
  } | null;
}

export interface ScoringEngine {
  id: string;
  momoWeight: number;
  tontineWeight: number;
  imfWeight: number;
  warningSignalDays: number;
}

export interface EscrowWallet {
  id: string;
  totalBalance: number;
  investorFunds: number;
  pendingDisbursements: number;
  lockedForGuarantee: number;
  platformFees: number;
  thirdPartyManager: string;
  lastAuditDate: string | null;
}

export interface PlatformWallet {
  id: string;
  commissionBalance: number;
  operatingFunds: number;
  lastWithdrawalDate: string | null;
}

export interface WalletSummary {
  escrow: EscrowWallet;
  platform: PlatformWallet;
  totalPlatformValue: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message: string;
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
    totalPages?: number;
  };
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
