import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { TransactionsController } from './transactions.controller';
import { TransactionsService } from './transactions.service';
import { RolesGuard } from '@shared/guards/roles.guard';
import { PaymentGatewayRouterService } from './gateways/payment-gateway-router.service';
import { FedapayGatewayService } from './gateways/fedapay-gateway.service';
import { KkiapayGatewayService } from './gateways/kkiapay-gateway.service';
import { WalletModule } from '@modules/wallet/wallet.module';

@Module({
  imports: [PassportModule, WalletModule],
  controllers: [TransactionsController],
  providers: [
    TransactionsService,
    RolesGuard,
    PaymentGatewayRouterService,
    FedapayGatewayService,
    KkiapayGatewayService,
  ],
  exports: [TransactionsService],
})
export class TransactionsModule {}
