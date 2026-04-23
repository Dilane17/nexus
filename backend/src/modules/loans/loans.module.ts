import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { PassportModule } from '@nestjs/passport';
import { LoansController } from './loans.controller';
import { LoansService } from './loans.service';
import { ImfSandboxService } from './imf-sandbox.service';
import { RolesGuard } from '@shared/guards/roles.guard';

@Module({
  imports: [HttpModule, PassportModule],
  controllers: [LoansController],
  providers: [LoansService, ImfSandboxService, RolesGuard],
  exports: [LoansService],
})
export class LoansModule {}
