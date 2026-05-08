import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { WalletController } from './wallet.controller';
import { WalletService } from './wallet.service';
import { RolesGuard } from '@shared/guards/roles.guard';

@Module({
  imports: [PassportModule],
  controllers: [WalletController],
  providers: [WalletService, RolesGuard],
  exports: [WalletService],
})
export class WalletModule {}
