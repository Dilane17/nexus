import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { GuaranteeFundController } from './guarantee-fund.controller';
import { GuaranteeFundService } from './guarantee-fund.service';
import { RolesGuard } from '@shared/guards/roles.guard';

@Module({
  imports: [PassportModule],
  controllers: [GuaranteeFundController],
  providers: [GuaranteeFundService, RolesGuard],
  exports: [GuaranteeFundService],
})
export class GuaranteeFundModule {}
