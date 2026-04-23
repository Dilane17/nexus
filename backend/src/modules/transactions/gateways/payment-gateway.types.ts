import type { payment_gateway, transaction_status } from '@generated/prisma';

export type SupportedGateway = payment_gateway;
export type SupportedMomoProvider = 'MTN_MOMO' | 'MOOV_FLOOZ';

export interface GatewayCustomer {
  firstName: string;
  lastName: string;
  email?: string | null;
  phone: string;
  country?: string;
}

export interface GatewayTransactionContext {
  reference: string;
  amount: number;
  momoProvider: SupportedMomoProvider;
  callbackUrl: string;
  returnUrl: string;
  failureUrl: string;
  description: string;
  customer: GatewayCustomer;
}

export interface GatewayInitiationResult {
  gateway: SupportedGateway;
  providerTransactionId: string | null;
  providerStatus: string | null;
  paymentUrl: string | null;
  payload: Record<string, unknown>;
}

export interface ParsedWebhookEvent {
  reference: string;
  providerTransactionId: string | null;
  providerStatus: string | null;
  internalStatus: Extract<transaction_status, 'CONFIRMED' | 'FAILED'>;
  failureReason?: string | null;
  payload: Record<string, unknown>;
}

export interface VerifiedWebhookEvent extends ParsedWebhookEvent {
  signatureVerified: true;
}

export interface PaymentGatewayAdapter {
  readonly gateway: SupportedGateway;
  initiateDeposit(context: GatewayTransactionContext): Promise<GatewayInitiationResult>;
  initiateWithdrawal(context: GatewayTransactionContext): Promise<GatewayInitiationResult>;
  verifyAndParseWebhook(
    rawBody: Buffer | string,
    headers: Record<string, string | string[] | undefined>,
    body: unknown,
  ): VerifiedWebhookEvent;
}
