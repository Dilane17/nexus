/* eslint-disable @typescript-eslint/require-await */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-return */
import { Injectable, Logger } from '@nestjs/common';
/** Type temporaire en attendant la génération Prisma */
type currency_code = 'XOF' | 'USD' | 'EUR' | 'NGN';
import { MailService } from '@shared/mail/mail.service';
import { FirebasePushService } from '@shared/push/firebase-push.service';
import { SmsService } from '@shared/sms/sms.service';

type Contact = {
  userId?: string | null;
  firstName: string;
  email?: string | null;
  phone?: string | null;
};

type PaymentType = 'deposit' | 'withdrawal';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private readonly mailService: MailService,
    private readonly pushService: FirebasePushService,
    private readonly smsService: SmsService,
  ) {}

  async notifyPaymentInitiated(
    contact: Contact,
    type: PaymentType,
    amount: number,
    gateway: string,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    await this.sendNonBlocking([
      async () =>
        contact.phone
          ? (this.smsService as any).sendPaymentInitiatedSms(
              contact.phone,
              contact.firstName,
              type,
              amount,
              gateway,
              currency,
            )
          : undefined,
      async () =>
        contact.email
          ? this.mailService.sendPaymentInitiatedEmail(
              contact.email,
              contact.firstName,
              type,
              amount,
              gateway,
              currency,
            )
          : undefined,
      async () =>
        this.pushService.sendToUser(
          contact.userId,
          'Paiement initie',
          `Votre ${type === 'deposit' ? 'depot' : 'retrait'} de ${amount.toLocaleString()} ${currency} via ${gateway} est en attente.`,
          {
            type: 'payment_initiated',
            paymentType: type,
            gateway,
            amount: amount.toString(),
            currency,
          },
        ),
    ]);
  }

  async notifyPaymentConfirmed(
    contact: Contact,
    type: PaymentType,
    amount: number,
    gateway: string,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    await this.sendNonBlocking([
      async () =>
        contact.phone
          ? (this.smsService as any).sendPaymentConfirmedSms(
              contact.phone,
              contact.firstName,
              type,
              amount,
              gateway,
              currency,
            )
          : undefined,
      async () =>
        contact.email
          ? this.mailService.sendPaymentConfirmedEmail(
              contact.email,
              contact.firstName,
              type,
              amount,
              gateway,
              currency,
            )
          : undefined,
      async () =>
        this.pushService.sendToUser(
          contact.userId,
          'Paiement confirme',
          `Votre ${type === 'deposit' ? 'depot' : 'retrait'} de ${amount.toLocaleString()} ${currency} a ete confirme via ${gateway}.`,
          {
            type: 'payment_confirmed',
            paymentType: type,
            gateway,
            amount: amount.toString(),
            currency,
          },
        ),
    ]);
  }

  async notifyPaymentFailed(
    contact: Contact,
    type: PaymentType,
    amount: number,
    gateway: string,
    failureReason?: string,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    await this.sendNonBlocking([
      async () =>
        contact.phone
          ? (this.smsService as any).sendPaymentFailedSms(
              contact.phone,
              contact.firstName,
              type,
              amount,
              gateway,
              failureReason,
              currency,
            )
          : undefined,
      async () =>
        contact.email
          ? this.mailService.sendPaymentFailedEmail(
              contact.email,
              contact.firstName,
              type,
              amount,
              gateway,
              failureReason,
              currency,
            )
          : undefined,
      async () =>
        this.pushService.sendToUser(
          contact.userId,
          'Paiement echoue',
          `Votre ${type === 'deposit' ? 'depot' : 'retrait'} de ${amount.toLocaleString()} ${currency} via ${gateway} a echoue.`,
          {
            type: 'payment_failed',
            paymentType: type,
            gateway,
            amount: amount.toString(),
            currency,
            failureReason: failureReason ?? '',
          },
        ),
    ]);
  }

  async notifyLoanOverdue(
    contact: Contact,
    loanId: string,
    daysOverdue: number,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    await this.sendNonBlocking([
      async () =>
        contact.phone
          ? this.smsService.sendLoanOverdueSms(
              contact.phone,
              contact.firstName,
              loanId,
              daysOverdue,
            )
          : undefined,
      async () =>
        contact.email
          ? this.mailService.sendLoanOverdueEmail(
              contact.email,
              contact.firstName,
              loanId,
              daysOverdue,
            )
          : undefined,
      async () =>
        this.pushService.sendToUser(
          contact.userId,
          'Pret en retard',
          `Votre pret ${loanId} presente ${daysOverdue} jour(s) de retard.`,
          {
            type: 'loan_overdue',
            loanId,
            daysOverdue: daysOverdue.toString(),
            currency,
          },
        ),
    ]);
  }

  async notifyLoanRepaymentReceived(
    contact: Contact,
    loanId: string,
    amount: number,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    await this.sendNonBlocking([
      async () =>
        contact.phone
          ? (this.smsService as any).sendLoanRepaymentReceivedSms(
              contact.phone,
              contact.firstName,
              loanId,
              amount,
              currency,
            )
          : undefined,
      async () =>
        contact.email
          ? this.mailService.sendLoanRepaymentReceivedEmail(
              contact.email,
              contact.firstName,
              loanId,
              amount,
              currency,
            )
          : undefined,
      async () =>
        this.pushService.sendToUser(
          contact.userId,
          'Remboursement recu',
          `Votre remboursement de ${amount.toLocaleString()} ${currency} pour le pret ${loanId} a ete enregistre.`,
          {
            type: 'loan_repayment_received',
            loanId,
            amount: amount.toString(),
            currency,
          },
        ),
    ]);
  }

  private async sendNonBlocking(
    senders: Array<() => Promise<unknown> | undefined>,
  ): Promise<void> {
    const results = await Promise.allSettled(
      senders.map(async (sender) => sender()),
    );

    for (const result of results) {
      if (result.status === 'rejected') {
        this.logger.warn(
          `Notification non bloquante en echec: ${result.reason instanceof Error ? result.reason.message : String(result.reason)}`,
        );
      }
    }
  }
}
