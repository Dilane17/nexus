import type { Prisma } from '@generated/prisma';
type Decimal = Prisma.Decimal;

export interface LoanResponse {
  id: string;
  borrowerId: string;
  amount: Decimal;
  interestRate: Decimal;
  durationMonths: number;
  status: string;
  monthlyInstallment: Decimal;
  outstandingBalance: Decimal;
  daysOverdue: number;
  validatedByImf: boolean;
  disbursedAt: Date | null;
  nextDueDate: Date | null;
  purpose: string | null;
  rejectionReason: string | null;
  createdAt: Date;
  investmentsCount?: number;
  hybridScore?: number | null;
}

export interface PendingImfLoan {
  id: string;
  amount: Decimal;
  durationMonths: number;
  purpose: string | null;
  createdAt: Date;
  borrower: {
    userId: string;
    firstName: string;
    lastName: string;
    phone: string | null;
    hybridScore: number | null;
  };
}

export interface PaginatedLoansResponse {
  items: LoanResponse[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface PaginatedPendingImfResponse {
  items: PendingImfLoan[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface HybridScoreResponse {
  borrowerId: string;
  momoScore: number;
  tontineScore: number;
  imfScore: number;
  hybridScore: number;
  computedAt: Date;
}
