import { Global, Module } from '@nestjs/common';
import { AppCacheService } from './cache/app-cache.service';
import { CurrencyService } from './currency/currency.service';
import { MailService } from './mail/mail.service';
import { NotificationService } from './notifications/notification.service';
import { FirebasePushService } from './push/firebase-push.service';
import { SmsService } from './sms/sms.service';
import { CloudinaryService } from './cloudinary/cloudinary.service';

@Global()
@Module({
  providers: [
    AppCacheService,
    CurrencyService,
    MailService,
    NotificationService,
    FirebasePushService,
    SmsService,
    CloudinaryService,
  ],
  exports: [
    AppCacheService,
    CurrencyService,
    MailService,
    NotificationService,
    FirebasePushService,
    SmsService,
    CloudinaryService,
  ],
})
export class SharedModule {}
