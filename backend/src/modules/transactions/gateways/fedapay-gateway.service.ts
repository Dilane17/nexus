import {
  BadGatewayException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'crypto';
import type {
  GatewayInitiationResult,
  GatewayTransactionContext,
  ParsedWebhookEvent,
  PaymentGatewayAdapter,
  VerifiedWebhookEvent,
} from './payment-gateway.types';

type JsonRecord = Record<string, unknown>;

@Injectable()
export class FedapayGatewayService implements PaymentGatewayAdapter {
  readonly gateway = 'FEDAPAY' as const;

  constructor(private readonly config: ConfigService) {}

  async initiateDeposit(
    context: GatewayTransactionContext,
  ): Promise<GatewayInitiationResult> {
    const customer = await this.createCustomer(context);
    const transaction = await this.request<JsonRecord>('/transactions', {
      method: 'POST',
      body: {
        description: context.description,
        amount: Math.round(context.amount),
        callback_url: context.callbackUrl,
        currency: { iso: 'XOF' },
        mode: this.resolveMode(context.momoProvider),
        customer: { id: customer.id },
        custom_metadata: {
          nexusReference: context.reference,
          returnUrl: context.returnUrl,
          failureUrl: context.failureUrl,
        },
      },
    });

    const paymentToken = await this.request<JsonRecord>(
      `/transactions/${transaction.id as string | number}/token`,
      { method: 'POST' },
    );

    return {
      gateway: this.gateway,
      providerTransactionId: this.asString(transaction.id),
      providerStatus: this.asString(transaction.status),
      paymentUrl: this.asString(paymentToken.url),
      payload: {
        customer,
        transaction,
        paymentToken,
      },
    };
  }

  async initiateWithdrawal(
    context: GatewayTransactionContext,
  ): Promise<GatewayInitiationResult> {
    const customer = await this.createCustomer(context);
    const payout = await this.request<JsonRecord>('/payouts', {
      method: 'POST',
      body: {
        amount: Math.round(context.amount),
        currency: { iso: 'XOF' },
        customer: { id: customer.id },
        mode: 'mobile_money',
        custom_metadata: {
          nexusReference: context.reference,
          returnUrl: context.returnUrl,
          failureUrl: context.failureUrl,
        },
      },
    });

    return {
      gateway: this.gateway,
      providerTransactionId: this.asString(payout.id),
      providerStatus: this.asString(payout.status),
      paymentUrl: null,
      payload: {
        customer,
        payout,
      },
    };
  }

  verifyAndParseWebhook(
    rawBody: Buffer | string,
    headers: Record<string, string | string[] | undefined>,
    body: unknown,
  ): VerifiedWebhookEvent {
    const signature = this.getHeader(headers, 'x-fedapay-signature');
    const secret = this.config.get<string>('FEDAPAY_WEBHOOK_SECRET');

    if (!signature || !secret) {
      throw new ForbiddenException('Signature FedaPay manquante ou secret non configuré');
    }

    if (!this.verifySignature(rawBody, signature, secret)) {
      throw new ForbiddenException('Signature FedaPay invalide');
    }

    const event = this.parseWebhook(body);
    return {
      ...event,
      signatureVerified: true,
    };
  }

  private async createCustomer(context: GatewayTransactionContext): Promise<JsonRecord> {
    return this.request<JsonRecord>('/customers', {
      method: 'POST',
      body: {
        firstname: context.customer.firstName,
        lastname: context.customer.lastName,
        email: context.customer.email,
        phone_number: {
          number: this.normalizePhone(context.customer.phone),
          country: context.customer.country ?? 'BJ',
        },
      },
    });
  }

  private parseWebhook(body: unknown): ParsedWebhookEvent {
    const payload = this.ensureRecord(body);
    const eventName = this.asString(payload.name ?? payload.type);
    const entity = this.ensureRecord(payload.entity ?? payload.data ?? payload.transaction ?? payload.payout);
    const reference = this.asString(
      entity.reference ??
        entity.merchant_reference ??
        this.ensureRecord(entity.custom_metadata).nexusReference,
    );

    if (!reference) {
      throw new BadGatewayException('Payload webhook FedaPay incomplet');
    }

    const rawStatus = this.asString(entity.status ?? eventName) ?? 'unknown';
    const normalized = rawStatus.toLowerCase();
    const internalStatus =
      normalized.includes('approve') || normalized.includes('sent') || normalized.includes('transfer')
        ? 'CONFIRMED'
        : 'FAILED';

    return {
      reference,
      providerTransactionId: this.asString(entity.id ?? payload.object_id),
      providerStatus: rawStatus,
      internalStatus,
      failureReason: this.asString(entity.last_error_code ?? payload.message ?? payload.reason) ?? null,
      payload,
    };
  }

  private verifySignature(
    rawBody: Buffer | string,
    signatureHeader: string,
    secret: string,
  ): boolean {
    const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody);
    const parts = signatureHeader.split(',').map((part) => part.trim());
    const timestamp = parts.find((part) => part.startsWith('t='))?.slice(2);
    const signature = parts.find((part) => part.startsWith('v1='))?.slice(3);

    if (!timestamp || !signature) {
      return false;
    }

    const signedPayload = `${timestamp}.${body.toString('utf8')}`;
    const digest = createHmac('sha256', secret).update(signedPayload).digest('hex');

    return this.safeCompare(signature, digest);
  }

  private resolveMode(provider: GatewayTransactionContext['momoProvider']): string {
    return provider === 'MTN_MOMO' ? 'mtn_open' : 'moov_open';
  }

  private async request<T extends JsonRecord>(
    path: string,
    options: { method: 'POST' | 'GET'; body?: JsonRecord },
  ): Promise<T> {
    const secretKey = this.config.get<string>('FEDAPAY_SECRET_KEY');
    const baseUrl =
      this.config.get<string>('FEDAPAY_API_BASE_URL') ??
      'https://sandbox-api.fedapay.com/v1';

    if (!secretKey) {
      throw new BadGatewayException('FEDAPAY_SECRET_KEY non configurée');
    }

    const response = await fetch(`${baseUrl}${path}`, {
      method: options.method,
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
      body: options.body ? JSON.stringify(options.body) : undefined,
    });

    const payload = (await response.json().catch(() => ({}))) as T & {
      message?: string;
      error?: string;
    };

    if (!response.ok) {
      throw new BadGatewayException(
        payload.message ?? payload.error ?? 'Appel FedaPay sandbox échoué',
      );
    }

    return payload;
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

  private safeCompare(left: string, right: string): boolean {
    const leftBuffer = Buffer.from(left);
    const rightBuffer = Buffer.from(right);

    if (leftBuffer.length !== rightBuffer.length) {
      return false;
    }

    return timingSafeEqual(leftBuffer, rightBuffer);
  }
}
