import {
  BadGatewayException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type {
  GatewayInitiationResult,
  GatewayTransactionContext,
  ParsedWebhookEvent,
  PaymentGatewayAdapter,
  VerifiedWebhookEvent,
} from './payment-gateway.types';

type JsonRecord = Record<string, unknown>;

@Injectable()
export class KkiapayGatewayService implements PaymentGatewayAdapter {
  readonly gateway = 'KKIAPAY' as const;

  constructor(private readonly config: ConfigService) {}

  async initiateDeposit(
    context: GatewayTransactionContext,
  ): Promise<GatewayInitiationResult> {
    const publicKey = this.config.get<string>('KKIAPAY_PUBLIC_KEY');

    if (!publicKey) {
      throw new BadGatewayException('KKIAPAY_PUBLIC_KEY non configurée');
    }

    const widgetConfig = {
      amount: Math.round(context.amount),
      key: publicKey,
      sandbox: true,
      callback: context.returnUrl,
      phone: this.normalizePhone(context.customer.phone),
      email: context.customer.email ?? undefined,
      name: `${context.customer.firstName} ${context.customer.lastName}`.trim(),
      partnerId: context.reference,
      paymentmethod: 'momo',
      data: {
        nexusReference: context.reference,
        callbackUrl: context.callbackUrl,
      },
    };

    const widgetBaseUrl =
      this.config.get<string>('KKIAPAY_WIDGET_BASE_URL') ??
      'https://cdn.kkiapay.me';

    return {
      gateway: this.gateway,
      providerTransactionId: null,
      providerStatus: 'PENDING_WIDGET',
      paymentUrl: `${widgetBaseUrl}/k.js`,
      payload: { widgetConfig },
    };
  }

  async initiateWithdrawal(
    context: GatewayTransactionContext,
  ): Promise<GatewayInitiationResult> {
    const privateKey = this.config.get<string>('KKIAPAY_SECRET_KEY');

    if (!privateKey) {
      throw new BadGatewayException('KKIAPAY_SECRET_KEY non configurée');
    }

    const payoutBaseUrl =
      this.config.get<string>('KKIAPAY_API_BASE_URL') ??
      'https://api-sandbox.kkiapay.me';

    const payload = {
      amount: Math.round(context.amount),
      phone: this.normalizePhone(context.customer.phone),
      reason: context.description,
      partnerId: context.reference,
      callback: context.callbackUrl,
    };

    const response = await fetch(`${payoutBaseUrl}/api/v1/payouts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': privateKey,
      },
      body: JSON.stringify(payload),
    });

    const body = (await response.json().catch(() => ({}))) as JsonRecord;

    if (!response.ok) {
      throw new BadGatewayException(
        this.asString(body.message ?? body.error) ??
          'Appel KKiaPay payout sandbox échoué',
      );
    }

    return {
      gateway: this.gateway,
      providerTransactionId: this.asString(body.transactionId ?? body.id),
      providerStatus: this.asString(body.status) ?? 'PENDING',
      paymentUrl: null,
      payload: body,
    };
  }

  verifyAndParseWebhook(
    _rawBody: Buffer | string,
    headers: Record<string, string | string[] | undefined>,
    body: unknown,
  ): VerifiedWebhookEvent {
    const configuredSecret = this.config.get<string>('KKIAPAY_WEBHOOK_SECRET');
    const signature = this.getHeader(headers, 'x-kkiapay-secret');

    if (!signature || !configuredSecret) {
      throw new ForbiddenException('Signature KKiaPay manquante ou secret non configuré');
    }

    if (signature !== configuredSecret) {
      throw new ForbiddenException('Signature KKiaPay invalide');
    }

    const event = this.parseWebhook(body);
    return {
      ...event,
      signatureVerified: true,
    };
  }

  private parseWebhook(body: unknown): ParsedWebhookEvent {
    const payload = this.ensureRecord(body);
    const partnerId = this.asString(payload.partnerId);
    const stateData = this.ensureRecord(payload.stateData);
    const reference = partnerId ?? this.asString(stateData.nexusReference);

    if (!reference) {
      throw new BadGatewayException('Payload webhook KKiaPay incomplet');
    }

    return {
      reference,
      providerTransactionId: this.asString(payload.transactionId),
      providerStatus: this.asString(payload.event ?? payload.status),
      internalStatus: payload.isPaymentSucces === true ? 'CONFIRMED' : 'FAILED',
      failureReason:
        this.asString(payload.failureMessage ?? payload.failureCode) ?? null,
      payload,
    };
  }

  private getHeader(
    headers: Record<string, string | string[] | undefined>,
    key: string,
  ): string | null {
    const value = headers[key] ?? headers[key.toLowerCase()];
    return Array.isArray(value) ? value[0] ?? null : value ?? null;
  }

  private normalizePhone(phone: string): string {
    return phone.replace(/[^\d]/g, '');
  }

  private ensureRecord(value: unknown): JsonRecord {
    return value && typeof value === 'object' ? (value as JsonRecord) : {};
  }

  private asString(value: unknown): string | null {
    if (typeof value === 'string' && value.length > 0) return value;
    if (typeof value === 'number') return String(value);
    return null;
  }
}
