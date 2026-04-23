import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { currency_code } from '@generated/prisma';
import * as nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly transporter: Transporter;
  private readonly from: string;

  constructor(private readonly config: ConfigService) {
    this.from = config.get<string>('MAIL_FROM') ?? 'Nexus <no-reply@nexus-benin.com>';

    this.transporter = nodemailer.createTransport({
      host: config.get<string>('MAIL_HOST') ?? 'smtp.gmail.com',
      port: parseInt(config.get<string>('MAIL_PORT') ?? '587', 10),
      secure: false,
      auth: {
        user: config.get<string>('MAIL_USER'),
        pass: config.get<string>('MAIL_PASSWORD'),
      },
    });
  }

  async sendOtpEmail(
    to: string,
    firstName: string,
    code: string,
  ): Promise<void> {
    await this.sendHtmlEmail(
      to,
      'Votre code de vérification Nexus',
      firstName,
      'Voici votre code de vérification Nexus :',
      `<div style="text-align:center;margin:0 0 32px">
        <span style="display:inline-block;background:#eff6ff;border:2px dashed #1a56db;border-radius:12px;padding:20px 48px;font-size:40px;font-weight:800;letter-spacing:12px;color:#1a56db">${code}</span>
      </div>
      <p style="color:#6b7280;font-size:13px;text-align:center;margin:0 0 8px">Ce code expire dans <strong>5 minutes</strong>.</p>
      <p style="color:#9ca3af;font-size:12px;text-align:center;margin:0">Si vous n'avez pas créé de compte Nexus, ignorez cet email.</p>`,
    );
  }

  async sendPaymentInitiatedEmail(
    to: string,
    firstName: string,
    type: 'deposit' | 'withdrawal',
    amount: number,
    gateway: string,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    const label = type === 'deposit' ? 'depot' : 'retrait';
    await this.sendHtmlEmail(
      to,
      `Votre ${label} Nexus a ete initie`,
      firstName,
      `Votre ${label} de ${amount.toLocaleString()} ${this.currencyLabel(currency)} a ete initie via ${gateway}.`,
      '<p style="color:#6b7280;font-size:14px;margin:0">Nous vous informerons automatiquement quand le provider confirmera l’operation.</p>',
    );
  }

  async sendPaymentConfirmedEmail(
    to: string,
    firstName: string,
    type: 'deposit' | 'withdrawal',
    amount: number,
    gateway: string,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    const label = type === 'deposit' ? 'depot' : 'retrait';
    await this.sendHtmlEmail(
      to,
      `Votre ${label} Nexus est confirme`,
      firstName,
      `Votre ${label} de ${amount.toLocaleString()} ${this.currencyLabel(currency)} a ete confirme via ${gateway}.`,
      '<p style="color:#6b7280;font-size:14px;margin:0">Le statut de votre portefeuille a ete mis a jour automatiquement.</p>',
    );
  }

  async sendPaymentFailedEmail(
    to: string,
    firstName: string,
    type: 'deposit' | 'withdrawal',
    amount: number,
    gateway: string,
    failureReason?: string,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    const label = type === 'deposit' ? 'depot' : 'retrait';
    await this.sendHtmlEmail(
      to,
      `Votre ${label} Nexus a echoue`,
      firstName,
      `Votre ${label} de ${amount.toLocaleString()} ${this.currencyLabel(currency)} via ${gateway} a echoue.`,
      `<p style="color:#6b7280;font-size:14px;margin:0">Motif: <strong>${failureReason ?? 'information non fournie par le provider'}</strong></p>`,
    );
  }

  async sendLoanOverdueEmail(
    to: string,
    firstName: string,
    loanId: string,
    daysOverdue: number,
  ): Promise<void> {
    await this.sendHtmlEmail(
      to,
      'Votre pret Nexus est en retard',
      firstName,
      `Votre pret ${loanId} est en retard de ${daysOverdue} jour(s).`,
      '<p style="color:#6b7280;font-size:14px;margin:0">Merci de regulariser votre situation pour eviter des mesures automatiques sur la garantie.</p>',
    );
  }

  async sendLoanRepaymentReceivedEmail(
    to: string,
    firstName: string,
    loanId: string,
    amount: number,
    currency: currency_code = 'XOF',
  ): Promise<void> {
    await this.sendHtmlEmail(
      to,
      'Remboursement de pret recu',
      firstName,
      `Nous avons recu votre remboursement de ${amount.toLocaleString()} ${this.currencyLabel(currency)} pour le pret ${loanId}.`,
      '<p style="color:#6b7280;font-size:14px;margin:0">Merci. Le solde du pret et les retours investisseurs ont ete recalcules.</p>',
    );
  }

  private currencyLabel(currency: currency_code): string {
    return currency === 'XOF' ? 'FCFA' : currency;
  }

  private async sendHtmlEmail(
    to: string,
    subject: string,
    firstName: string,
    intro: string,
    body: string,
  ): Promise<void> {
    const html = this.wrapTemplate(firstName, intro, body);

    try {
      await this.transporter.sendMail({
        from: this.from,
        to,
        subject,
        html,
      });
      this.logger.log(`📧 Email envoyé à ${to} — ${subject}`);
    } catch (error: unknown) {
      this.logger.error(`❌ Échec envoi email à ${to}`, error);
      throw error;
    }
  }

  private wrapTemplate(
    firstName: string,
    intro: string,
    body: string,
  ): string {
    return `
      <!DOCTYPE html>
      <html lang="fr">
      <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
      <body style="margin:0;padding:0;background:#f4f4f4;font-family:Arial,sans-serif">
        <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f4;padding:40px 0">
          <tr><td align="center">
            <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.1)">
              <tr><td style="background:#1a56db;padding:32px 40px;text-align:center">
                <h1 style="color:#ffffff;margin:0;font-size:24px;font-weight:700">Nexus</h1>
                <p style="color:#bfdbfe;margin:4px 0 0;font-size:13px">Plateforme P2P Lending — Bénin</p>
              </td></tr>
              <tr><td style="padding:40px">
                <p style="color:#374151;font-size:15px;margin:0 0 8px">Bonjour <strong>${firstName}</strong>,</p>
                <p style="color:#6b7280;font-size:14px;margin:0 0 24px">${intro}</p>
                ${body}
              </td></tr>
              <tr><td style="background:#f9fafb;padding:16px 40px;text-align:center;border-top:1px solid #e5e7eb">
                <p style="color:#9ca3af;font-size:12px;margin:0">© ${new Date().getFullYear()} Nexus P2P Lending. Tous droits réservés.</p>
              </td></tr>
            </table>
          </td></tr>
        </table>
      </body>
      </html>
    `;
  }
}
