import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AppCacheService } from './app-cache.service';

describe('AppCacheService', () => {
  let service: AppCacheService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppCacheService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              const values: Record<string, string | undefined> = {
                REDIS_URL: undefined,
                REDIS_ENABLED: 'false',
                REDIS_KEY_PREFIX: 'nexus:test:',
              };
              return values[key];
            }),
          },
        },
      ],
    }).compile();

    service = module.get<AppCacheService>(AppCacheService);
    await service.onModuleInit();
  });

  it('retourne la valeur en cache avant expiration', async () => {
    let calls = 0;

    const first = await service.getOrSet('admin:dashboard', 10_000, async () => {
      calls += 1;
      return { total: 1 };
    });

    const second = await service.getOrSet('admin:dashboard', 10_000, async () => {
      calls += 1;
      return { total: 2 };
    });

    expect(first).toEqual({ total: 1 });
    expect(second).toEqual({ total: 1 });
    expect(calls).toBe(1);
  });

  it('invalide les cles par prefixe', async () => {
    await service.set('admin:dashboard', { total: 1 }, 10_000);
    await service.set('admin:guarantee', { total: 2 }, 10_000);

    await service.invalidate('admin:dash');

    expect(await service.get('admin:dashboard')).toBeNull();
    expect(await service.get('admin:guarantee')).toEqual({ total: 2 });
  });
});
