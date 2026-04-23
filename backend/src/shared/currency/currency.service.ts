import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@generated/prisma';
import type { currency_code } from '@generated/prisma';

const FALLBACK_CURRENCY_CODE: currency_code = 'XOF';
type ExchangeRates = Record<currency_code, number>;

const DEFAULT_RATES: ExchangeRates = {
  XOF: 1,
  USD: 0.0016,
  EUR: 0.0015,
  NGN: 2.45,
};

const SUPPORTED_CODES: currency_code[] = ['XOF', 'USD', 'EUR', 'NGN'];

const CURRENCY_LOCALE_MAP: Record<currency_code, string> = {
  XOF: 'fr-SN', // West African CFA
  USD: 'en-US',
  EUR: 'fr-FR',
  NGN: 'en-NG',
};

@Injectable()
export class CurrencyService {
  private readonly logger = new Logger(CurrencyService.name);
  private readonly supportedCurrencies: currency_code[];
  private readonly defaultCurrency: currency_code;
  private readonly exchangeRates: ExchangeRates;

  constructor(private readonly config: ConfigService) {
    this.supportedCurrencies = this.parseSupportedCurrencies(
      this.config.get<string>('SUPPORTED_CURRENCIES'),
    );

    const configuredDefaultCurrency =
      this.config.get<string>('DEFAULT_CURRENCY');
    this.defaultCurrency = this.validateAndNormalizeCurrency(
      configuredDefaultCurrency,
      FALLBACK_CURRENCY_CODE,
      'DEFAULT_CURRENCY',
    );
    if (
      configuredDefaultCurrency &&
      configuredDefaultCurrency.toUpperCase() !== this.defaultCurrency
    ) {
      this.logger.warn(
        `DEFAULT_CURRENCY "${configuredDefaultCurrency}" est invalide ou non supportée. Utilisation de la devise par défaut: ${this.defaultCurrency}`,
      );
    } else if (!configuredDefaultCurrency) {
      this.logger.warn(
        `DEFAULT_CURRENCY non définie. Utilisation de la devise par défaut: ${this.defaultCurrency}`,
      );
    }

    this.exchangeRates = this.parseExchangeRates(
      this.config.get<string>('EXCHANGE_RATES_JSON'),
    );
  }

  getDefaultCurrency(): currency_code {
    return this.defaultCurrency;
  }

  getSupportedCurrencies(): currency_code[] {
    return [...this.supportedCurrencies];
  }

  // Public method for normalizing currency, uses instance's defaultCurrency as fallback
  normalizeCurrency(value?: string | null): currency_code {
    return this.validateAndNormalizeCurrency(
      value,
      this.defaultCurrency,
      'runtime',
    );
  }

  // Private helper for robust currency validation and normalization
  private validateAndNormalizeCurrency(
    value: string | null | undefined,
    fallback: currency_code,
    context: 'DEFAULT_CURRENCY' | 'runtime',
  ): currency_code {
    const candidate = (value ?? '').trim().toUpperCase(); // Ensure candidate is always a string

    if (
      candidate &&
      this.supportedCurrencies.includes(candidate as currency_code)
    ) {
      return candidate as currency_code;
    }

    if (context === 'runtime') {
      if (!value)
        this.logger.debug(
          `Devise non spécifiée, utilisation du fallback: ${fallback}`,
        );
      else
        this.logger.warn(
          `Devise "${value}" non supportée. Utilisation du fallback: ${fallback}`,
        );
    }

    return fallback;
  }

  convertDecimal(
    amount: Prisma.Decimal | number | string | null | undefined,
    from: currency_code,
    to: currency_code,
  ): Prisma.Decimal {
    const decimalAmount = new Prisma.Decimal(amount ?? 0);

    if (decimalAmount.isNaN() || !decimalAmount.isFinite()) {
      return new Prisma.Decimal(0);
    }

    if (from === to) {
      return decimalAmount.toDecimalPlaces(2);
    }

    const rateFrom = new Prisma.Decimal(this.exchangeRates[from] ?? 1);
    const rateTo = new Prisma.Decimal(this.exchangeRates[to] ?? 1);

    // (Amount / RateFrom) * RateTo using high-precision decimal math
    return decimalAmount.div(rateFrom).mul(rateTo).toDecimalPlaces(2);
  }

  formatAmount(
    amount: Prisma.Decimal | number | string,
    currency: currency_code,
  ): string {
    const numericValue =
      amount instanceof Prisma.Decimal ? amount.toNumber() : Number(amount);

    const locale = CURRENCY_LOCALE_MAP[currency] || 'fr-FR';
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currency === 'XOF' ? 'XOF' : currency,
      currencyDisplay: 'symbol',
      minimumFractionDigits: 0,
    })
      .format(numericValue)
      .replace('XOF', 'FCFA'); // Custom override for CFA display
  }

  currencyLabel(currency: currency_code): string {
    switch (currency) {
      case 'USD':
        return 'USD';
      case 'EUR':
        return 'EUR';
      case 'NGN':
        return 'NGN';
      case 'XOF':
      default:
        return 'FCFA';
    }
  }

  private parseSupportedCurrencies(raw?: string | null): currency_code[] {
    const parsed = (raw ?? 'XOF,USD,EUR,NGN') // Default string if env var is missing
      .split(',')
      .map((value) => value.trim().toUpperCase())
      .filter((value): value is currency_code =>
        SUPPORTED_CODES.includes(value as currency_code),
      );

    return parsed.length > 0 ? parsed : [FALLBACK_CURRENCY_CODE];
  }

  private parseExchangeRates(raw?: string | null): ExchangeRates {
    if (!raw) {
      return DEFAULT_RATES;
    }

    try {
      const parsed = JSON.parse(raw) as Partial<Record<string, number>>;
      const merged: ExchangeRates = { ...DEFAULT_RATES };

      for (const currency of this.supportedCurrencies) {
        const value = parsed[currency];
        if (typeof value === 'number' && Number.isFinite(value) && value > 0) {
          merged[currency] = value;
        }
      }

      return merged;
    } catch (error: unknown) {
      this.logger.warn(
        `EXCHANGE_RATES_JSON invalide, fallback aux taux par défaut: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return DEFAULT_RATES;
    }
  }
}
