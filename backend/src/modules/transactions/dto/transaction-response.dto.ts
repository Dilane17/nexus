import type { Prisma } from '@generated/prisma';
type Decimal = Prisma.Decimal;

export interface TransactionResponse {
  id: string;
  type: string;
  amount: Decimal;
  status: string;
  paymentGateway: string | null;
  momoReference: string | null;
  momoProvider: string | null;
  providerTransactionId: string | null;
  providerStatus: string | null;
  initiatedAt: Date;
  confirmedAt: Date | null;
  reconciledAt: Date | null;
  isReconciled: boolean;
  failureReason: string | null;
  createdBy: string;
}

export interface DepositInitiatedResponse {
  transaction: TransactionResponse;
  gateway: string | null;
  providerTransactionId: string | null;
  providerStatus: string | null;
  paymentUrl: string | null;
  message: string;
}

export interface PaginatedTransactionsResponse {
  items: TransactionResponse[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
