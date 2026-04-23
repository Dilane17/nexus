import type { Prisma } from '@generated/prisma';
type Decimal = Prisma.Decimal;

export interface InvestmentLoanDetail {
  amount: Decimal;
  durationMonths: number;
  interestRate: Decimal;
  status: string;
  purpose: string | null;
  borrowerName: string;
}

export interface InvestmentResponse {
  id: string;
  investorId: string;
  loanId: string;
  amount: Decimal;
  expectedReturn: Decimal;
  actualReturn: Decimal;
  status: string;
  isGuaranteed: boolean;
  guaranteeTier: number;
  maturityDate: Date;
  loan?: InvestmentLoanDetail;
}

export interface PaginatedInvestmentsResponse {
  items: InvestmentResponse[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface PortfolioSummary {
  walletBalance: Decimal;
  totalInvested: Decimal;
  totalReturns: Decimal;
  riskProfile: string;
  investorType: string;
  investmentsByStatus: {
    ACTIVE: number;
    COMPLETED: number;
    DEFAULTED: number;
    GUARANTEED: number;
  };
  nplRatio: number;
  activePortfolioValue: Decimal;
}
