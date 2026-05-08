import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { PassportModule } from '@nestjs/passport';
import { LoansController } from './loans.controller';
import { LoansService } from './loans.service';
import { ImfSandboxService } from './imf-sandbox.service';
import { RolesGuard } from '@shared/guards/roles.guard';
import { GuaranteeFundModule } from '@modules/guarantee-fund/guarantee-fund.module';

@Module({
  imports: [HttpModule, PassportModule, GuaranteeFundModule],
  controllers: [LoansController],
  providers: [LoansService, ImfSandboxService, RolesGuard],
  exports: [LoansService],
})
export class LoansModule {}
