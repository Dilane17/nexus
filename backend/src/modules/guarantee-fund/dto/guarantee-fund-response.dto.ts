import type { Prisma } from '@generated/prisma';

type Decimal = Prisma.Decimal;

// ── État du fonds ──────────────────────────────────────────────────────────────

export interface GuaranteeFundStatusResponse {
  id: string;
  totalCapital: Decimal;
  activePortfolioValue: Decimal;
  coverageRatio: Decimal;
  minThreshold: Decimal;
  targetThreshold: Decimal;
  suspensionActive: boolean;
  lastReconstitutionDate: Date | null;
}

// ── Investissement couvert ─────────────────────────────────────────────────────

export interface GuaranteedInvestmentItem {
  id: string;
  fundId: string;
  investmentId: string;
  coveredAmount: Decimal;
  isActivated: boolean;
  activatedAt: Date | null;
  investorName: string;
  investorEmail: string;
  loanId: string;
  loanAmount: Decimal;
  loanStatus: string;
}

// ── Résultat activation ────────────────────────────────────────────────────────

export interface GuaranteeActivationResult {
  fundInvestmentId: string;
  investmentId: string;
  coveredAmount: Decimal;
  newCoverageRatio: Decimal;
  suspensionActive: boolean;
}
