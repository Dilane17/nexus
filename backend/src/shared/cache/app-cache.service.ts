import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

type CacheEntry<T> = {
  expiresAt: number;
  value: T;
};

@Injectable()
export class AppCacheService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AppCacheService.name);
  private readonly store = new Map<string, CacheEntry<unknown>>();
  private readonly namespace: string;
  private readonly redisEnabled: boolean;
  private redis: Redis | null = null;

  constructor(private readonly config: ConfigService) {
    this.namespace = this.config.get<string>('REDIS_KEY_PREFIX') ?? 'nexus:';
    this.redisEnabled =
      (this.config.get<string>('REDIS_ENABLED') ?? 'true').toLowerCase() !==
      'false';

    const redisUrl = this.config.get<string>('REDIS_URL');
    if (this.redisEnabled && redisUrl) {
      this.redis = new Redis(redisUrl, {
        lazyConnect: true,
        maxRetriesPerRequest: 1,
        enableOfflineQueue: false,
      });
    }
  }

  async onModuleInit(): Promise<void> {
    if (!this.redis) {
      this.logger.log('Cache applicatif en mode memoire');
      return;
    }

    try {
      await this.redis.connect();
      await this.redis.ping();
      this.logger.log('Cache Redis connecte');
    } catch (error: unknown) {
      this.logger.warn(
        `Redis indisponible, fallback memoire: ${error instanceof Error ? error.message : String(error)}`,
      );
      this.redis.disconnect();
      this.redis = null;
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis) {
      await this.redis.quit();
    }
  }

  async getOrSet<T>(
    key: string,
    ttlMs: number,
    factory: () => Promise<T>,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null) {
      return cached;
    }

    const value = await factory();
    await this.set(key, value, ttlMs);
    return value;
  }

  async get<T>(key: string): Promise<T | null> {
    if (this.redis) {
      const raw = await this.redis.get(this.buildKey(key));
      if (!raw) {
        return null;
      }
      return JSON.parse(raw) as T;
    }

    const now = Date.now();
    const cached = this.store.get(key);

    if (!cached || cached.expiresAt <= now) {
      if (cached) {
        this.store.delete(key);
      }
      return null;
    }

    return cached.value as T;
  }

  async set<T>(key: string, value: T, ttlMs: number): Promise<void> {
    if (this.redis) {
      await this.redis.set(
        this.buildKey(key),
        JSON.stringify(value),
        'PX',
        ttlMs,
      );
      return;
    }

    this.store.set(key, {
      value,
      expiresAt: Date.now() + ttlMs,
    });
  }

  async invalidate(prefix?: string): Promise<void> {
    if (this.redis) {
      const match = this.buildKey(prefix ? `${prefix}*` : '*');
      let cursor = '0';

      do {
        const [nextCursor, keys] = await this.redis.scan(
          cursor,
          'MATCH',
          match,
          'COUNT',
          '100',
        );

        if (keys.length > 0) {
          await this.redis.del(...keys);
        }

        cursor = nextCursor;
      } while (cursor !== '0');

      return;
    }

    if (!prefix) {
      this.store.clear();
      return;
    }

    for (const key of this.store.keys()) {
      if (key.startsWith(prefix)) {
        this.store.delete(key);
      }
    }
  }

  private buildKey(key: string): string {
    return `${this.namespace}${key}`;
  }
}
