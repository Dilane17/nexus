import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  cert,
  getApp,
  getApps,
  initializeApp,
  type App,
} from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { PrismaService } from '@shared/prisma/prisma.service';

@Injectable()
export class FirebasePushService {
  private readonly logger = new Logger(FirebasePushService.name);
  private app: App | null = null;
  private readonly enabled: boolean;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.enabled =
      (this.config.get<string>('FIREBASE_PUSH_ENABLED') ?? 'false').toLowerCase() ===
      'true';
  }

  async sendToUser(
    userId: string | null | undefined,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!userId) {
      return;
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { push_tokens: true },
    });

    const tokens = user?.push_tokens ?? [];
    if (tokens.length === 0) {
      return;
    }

    const app = this.getOrCreateApp();
    if (!app) {
      this.logger.log(`[PUSH LOG-ONLY] ${userId} | ${title} | ${body}`);
      return;
    }

    const response = await getMessaging(app).sendEachForMulticast({
      tokens,
      notification: { title, body },
      data,
    });

    if (response.failureCount === 0) {
      this.logger.log(`[PUSH] Envoye a ${userId} (${tokens.length} token(s))`);
      return;
    }

    const invalidTokens = response.responses
      .map((result, index) => ({ result, token: tokens[index] }))
      .filter(({ result }) => !result.success && this.isInvalidTokenError(result.error?.code))
      .map(({ token }) => token);

    if (invalidTokens.length > 0) {
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          push_tokens: tokens.filter((token) => !invalidTokens.includes(token)),
        },
      });
      this.logger.warn(
        `[PUSH] ${invalidTokens.length} token(s) invalides retires pour ${userId}`,
      );
    }
  }

  private getOrCreateApp(): App | null {
    if (!this.enabled) {
      return null;
    }

    if (this.app) {
      return this.app;
    }

    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = this.config
      .get<string>('FIREBASE_PRIVATE_KEY')
      ?.replace(/\\n/g, '\n');
    const storageBucket = this.config.get<string>('FIREBASE_STORAGE_BUCKET');

    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn(
        'Firebase Push actif mais credentials incomplets. Fallback log-only.',
      );
      return null;
    }

    const appName = 'nexus-backend';
    this.app = getApps().find((app) => app.name === appName) ?? null;

    if (this.app) {
      return this.app;
    }

    this.app = initializeApp(
      {
        credential: cert({
          projectId,
          clientEmail,
          privateKey,
        }),
        ...(storageBucket ? { storageBucket } : {}),
      },
      appName,
    );

    return this.app ?? getApp(appName);
  }

  private isInvalidTokenError(code?: string): boolean {
    return (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token' ||
      code === 'messaging/invalid-argument'
    );
  }
}
