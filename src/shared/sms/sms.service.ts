import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  async sendOtpSms(
    phone: string,
    firstName: string,
    code: string,
  ): Promise<void> {
    // Mode simulation — brancher Africa's Talking en production
    const message = `Bonjour ${firstName}, votre code Nexus : ${code} | Expire dans 5 min`;
    this.logger.log(`[SMS SIMULATION] → ${phone} | ${message}`);

    // TODO production :
    // const africastalking = require('africastalking')({ apiKey: ..., username: ... });
    // await africastalking.SMS.send({ to: [phone], message, from: 'Nexus' });
  }
}
