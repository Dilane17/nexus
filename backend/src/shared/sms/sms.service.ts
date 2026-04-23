import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

type PaymentMessageType = 'deposit' | 'withdrawal';
type LoanNotificationType = 'overdue' | 'repayment';

export interface PaymentSmsPayload {
  phone: string;
  firstName: string;
  type: PaymentMessageType;
  amount: number;
  gateway: string;
  currency: string;
  failureReason?: string;
}

export interface LoanRepaymentPayload {
  phone: string;
  firstName: string;
  loanId: string;
  amount: number;
  currency: string;
}

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private readonly username: string | null;
  private readonly apiKey: string | null;
  private readonly from: string | null;
  private readonly baseUrl: string;

  constructor(private readonly config: ConfigService) {
    this.username = config.get<string>('AFRICASTALKING_USERNAME') ?? null;
    this.apiKey = config.get<string>('AFRICASTALKING_API_KEY') ?? null;
    this.from = config.get<string>('AFRICASTALKING_SENDER_ID') ?? null;
    this.baseUrl =
      config.get<string>('AFRICASTALKING_SMS_BASE_URL') ??
      'https://api.sandbox.africastalking.com/version1/messaging';
  }

  async sendOtpSms(
    phone: string,
    firstName: string,
    code: string,
  ): Promise<void> {
    const message = `Bonjour ${firstName}, votre code Nexus : ${code} | Expire dans 5 min`;
    await this.sendSms(phone, message, 'OTP');
  }

  async sendPaymentInitiatedSms(payload: PaymentSmsPayload): Promise<void> {
    const { phone, firstName, type, amount, gateway, currency } = payload;
    const label = type === 'deposit' ? 'depot' : 'retrait';
    const message = `Bonjour ${firstName}, votre ${label} de ${amount.toLocaleString()} ${currency} est initie via ${gateway}. Suivez la confirmation sur votre telephone.`;
    await this.sendSms(phone, message, 'PAYMENT_INITIATED');
  }

  async sendPaymentConfirmedSms(payload: PaymentSmsPayload): Promise<void> {
    const { phone, firstName, type, amount, gateway, currency } = payload;
    const label = type === 'deposit' ? 'depot' : 'retrait';
    const message = `Bonjour ${firstName}, votre ${label} de ${amount.toLocaleString()} ${currency} a ete confirme via ${gateway}.`;
    await this.sendSms(phone, message, 'PAYMENT_CONFIRMED');
  }

  async sendPaymentFailedSms(payload: PaymentSmsPayload): Promise<void> {
    const { phone, firstName, type, amount, gateway, currency, failureReason } =
      payload;
    const label = type === 'deposit' ? 'depot' : 'retrait';
    const suffix = failureReason ? ` Motif: ${failureReason}.` : '';
    const message = `Bonjour ${firstName}, votre ${label} de ${amount.toLocaleString()} ${currency} via ${gateway} a echoue.${suffix}`;
    await this.sendSms(phone, message, 'PAYMENT_FAILED');
  }

  async sendLoanOverdueSms(
    phone: string,
    firstName: string,
    loanId: string,
    daysOverdue: number,
  ): Promise<void> {
    const message = `Bonjour ${firstName}, votre pret ${loanId} est en retard de ${daysOverdue} jour(s). Merci de regulariser rapidement.`;
    await this.sendLoanNotification(phone, message, 'overdue');
  }

  async sendLoanRepaymentReceivedSms(
    payload: LoanRepaymentPayload,
  ): Promise<void> {
    const { phone, firstName, loanId, amount, currency } = payload;
    const message = `Bonjour ${firstName}, votre remboursement de ${amount.toLocaleString()} ${currency} pour le pret ${loanId} a bien ete recu.`;
    await this.sendLoanNotification(phone, message, 'repayment');
  }

  private async sendLoanNotification(
    phone: string,
    message: string,
    type: LoanNotificationType,
  ): Promise<void> {
    await this.sendSms(phone, message, `LOAN_${type.toUpperCase()}`);
  }

  private async sendSms(
    phone: string,
    message: string,
    kind: string,
  ): Promise<void> {
    if (!this.username || !this.apiKey) {
      this.logger.log(`[SMS LOG-ONLY:${kind}] → ${phone} | ${message}`);
      return;
    }

    const body = new URLSearchParams({
      username: this.username,
      to: phone,
      message,
    });

    if (this.from) {
      body.set('from', this.from);
    }

    const maxAttempts = parseInt(
      this.config.get<string>('AFRICASTALKING_SMS_RETRY_ATTEMPTS') ?? '3',
      10,
    );
    const baseDelayMs = parseInt(
      this.config.get<string>('AFRICASTALKING_SMS_RETRY_DELAY_MS') ?? '500',
      10,
    );

    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const response = await fetch(this.baseUrl, {
          method: 'POST',
          headers: {
            Accept: 'application/json',
            apiKey: this.apiKey,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body,
        });

        const payload = (await response.json().catch(() => ({}))) as Record<
          string,
          unknown
        >;

        if (!response.ok) {
          throw new Error(JSON.stringify(payload));
        }

        this.logger.log(`[SMS ${kind}] Envoye a ${phone}`);
        return;
      } catch (error: unknown) {
        lastError = error;
        this.logger.warn(
          `[SMS ${kind}] tentative ${attempt}/${maxAttempts} echouee vers ${phone}`,
        );

        if (attempt < maxAttempts) {
          await new Promise((resolve) =>
            setTimeout(resolve, baseDelayMs * attempt),
          );
        }
      }
    }

    this.logger.error(
      `[SMS ${kind}] Echec Africa's Talking vers ${phone}`,
      lastError,
    );
    throw new Error("Echec d'envoi SMS Africa's Talking");
  }
}
