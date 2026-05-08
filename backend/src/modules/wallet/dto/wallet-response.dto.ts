import type { Prisma } from '@generated/prisma';

type Decimal = Prisma.Decimal;

// ── Escrow Wallet ──────────────────────────────────────────────────────────────

export interface EscrowWalletResponse {
  id: string;
  totalBalance: Decimal;
  investorFunds: Decimal;
  pendingDisbursements: Decimal;
  lockedForGuarantee: Decimal;
  platformFees: Decimal;
  thirdPartyManager: string;
  lastAuditDate: Date | null;
}

// ── Platform Wallet ────────────────────────────────────────────────────────────

export interface PlatformWalletResponse {
  id: string;
  commissionBalance: Decimal;
  operatingFunds: Decimal;
  lastWithdrawalDate: Date | null;
}

// ── Wallet Summary ─────────────────────────────────────────────────────────────

export interface WalletSummaryResponse {
  escrow: EscrowWalletResponse;
  platform: PlatformWalletResponse;
  totalPlatformValue: Decimal;
}
