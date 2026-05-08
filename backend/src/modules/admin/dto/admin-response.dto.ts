import type { Prisma } from '@generated/prisma';
type Decimal = Prisma.Decimal;

// ── Dashboard ─────────────────────────────────────────────────────────────────

export interface DashboardResponse {
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
    totalPortfolioValue: Decimal;
    nplRatio: number;
  };
  transactions: {
    todayCount: number;
    todayVolume: Decimal;
    pendingCount: number;
    phantomCount: number;
  };
  guaranteeFund: {
    totalCapital: Decimal;
    activePortfolioValue: Decimal;
    coverageRatio: Decimal;
    suspensionActive: boolean;
  } | null;
}

// ── Rapport BCEAO ─────────────────────────────────────────────────────────────

export interface BceaoReportResponse {
  generatedAt: Date;
  period: { from: string; to: string };
  loans: {
    totalEncours: Decimal;
    totalDisbursed: Decimal;
    nplRate: number;
    byDuration: { months: number; count: number; amount: Decimal }[];
    byAmountRange: { label: string; count: number; amount: Decimal }[];
  };
  transactions: {
    totalReconciled: number;
    totalUnreconciled: number;
    totalVolume: Decimal;
    phantomCount: number;
  };
  guaranteeFund: {
    coverageRatio: Decimal;
    minThreshold: Decimal;
    targetThreshold: Decimal;
    suspensionActive: boolean;
  } | null;
}

// ── Fonds de garantie ─────────────────────────────────────────────────────────

export interface GuaranteeFundResponse {
  id: string;
  totalCapital: Decimal;
  activePortfolioValue: Decimal;
  coverageRatio: Decimal;
  minThreshold: Decimal;
  targetThreshold: Decimal;
  suspensionActive: boolean;
  lastReconstituionDate: Date | null;
}

// ── Utilisateurs ──────────────────────────────────────────────────────────────

export interface AdminUserItem {
  id: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  email: string;
  status: string;
  kyc_status: string;
  createdAt: Date;
  role: string;
}

export interface PaginatedAdminUsersResponse {
  items: AdminUserItem[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
