import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { payment_gateway } from '@generated/prisma';
import type {
  PaymentGatewayAdapter,
  SupportedGateway,
  SupportedMomoProvider,
} from './payment-gateway.types';
import { FedapayGatewayService } from './fedapay-gateway.service';
import { KkiapayGatewayService } from './kkiapay-gateway.service';

@Injectable()
export class PaymentGatewayRouterService {
  constructor(
    private readonly config: ConfigService,
    private readonly fedapayGateway: FedapayGatewayService,
    private readonly kkiapayGateway: KkiapayGatewayService,
  ) {}

  resolveByMomoProvider(provider: SupportedMomoProvider): PaymentGatewayAdapter {
    const envKey =
      provider === 'MTN_MOMO'
        ? 'PAYMENT_GATEWAY_MTN_MOMO'
        : 'PAYMENT_GATEWAY_MOOV_FLOOZ';

    const configured = this.config.get<string>(envKey);
    const gateway = this.normalizeGateway(
      configured ??
        (provider === 'MTN_MOMO' ? 'FEDAPAY' : 'KKIAPAY'),
    );

    return this.resolveByGateway(gateway);
  }

  resolveByGateway(gateway: SupportedGateway | payment_gateway): PaymentGatewayAdapter {
    return gateway === 'FEDAPAY'
      ? this.fedapayGateway
      : this.kkiapayGateway;
  }

  private normalizeGateway(value: string): SupportedGateway {
    return value?.toUpperCase() === 'KKIAPAY' ? 'KKIAPAY' : 'FEDAPAY';
  }
}
