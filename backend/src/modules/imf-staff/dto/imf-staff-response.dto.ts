import type { Prisma } from '@generated/prisma';

type Decimal = Prisma.Decimal;

// ── Profil IMF ─────────────────────────────────────────────────────────────────

export interface ImfStaffProfileResponse {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  imfName: string;
  licenseNumber: string;
  bceaoAgreementRef: string;
  status: string;
  createdAt: Date;
}

// ── Prêt vu par l'IMF ──────────────────────────────────────────────────────────

export interface ImfStaffLoanItem {
  id: string;
  borrowerId: string;
  borrowerName: string;
  borrowerEmail: string;
  amount: Decimal;
  durationMonths: number;
  interestRate: Decimal;
  purpose: string;
  status: string;
  createdAt: Date;
  validatedAt: Date | null;
  rejectedAt: Date | null;
  rejectionReason: string | null;
}

export interface PaginatedImfStaffLoansResponse {
  items: ImfStaffLoanItem[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// ── Dashboard IMF ──────────────────────────────────────────────────────────────

export interface ImfStaffDashboardResponse {
  pendingCount: number;
  validatedCount: number;
  rejectedCount: number;
  totalProcessed: number;
  totalPortfolioValue: Decimal;
  recentActivity: ImfStaffLoanItem[];
}
