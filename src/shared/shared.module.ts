import { Global, Module } from '@nestjs/common';
import { MailService } from './mail/mail.service';
import { SmsService } from './sms/sms.service';

@Global()
@Module({
  providers: [MailService, SmsService],
  exports: [MailService, SmsService],
})
export class SharedModule {}
