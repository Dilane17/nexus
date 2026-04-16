import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
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
    const html = `
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
                <p style="color:#6b7280;font-size:14px;margin:0 0 32px">Voici votre code de vérification Nexus :</p>
                <div style="text-align:center;margin:0 0 32px">
                  <span style="display:inline-block;background:#eff6ff;border:2px dashed #1a56db;border-radius:12px;padding:20px 48px;font-size:40px;font-weight:800;letter-spacing:12px;color:#1a56db">${code}</span>
                </div>
                <p style="color:#6b7280;font-size:13px;text-align:center;margin:0 0 8px">⏱ Ce code expire dans <strong>5 minutes</strong>.</p>
                <p style="color:#9ca3af;font-size:12px;text-align:center;margin:0">Si vous n'avez pas créé de compte Nexus, ignorez cet email.</p>
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

    try {
      await this.transporter.sendMail({
        from: this.from,
        to,
        subject: 'Votre code de vérification Nexus',
        html,
      });
      this.logger.log(`📧 OTP envoyé à ${to}`);
    } catch (error: unknown) {
      this.logger.error(`❌ Échec envoi email à ${to}`, error);
      throw error;
    }
  }
}
