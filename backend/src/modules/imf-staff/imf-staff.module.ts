import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { ImfStaffController } from './imf-staff.controller';
import { ImfStaffService } from './imf-staff.service';
import { RolesGuard } from '@shared/guards/roles.guard';

@Module({
  imports: [PassportModule],
  controllers: [ImfStaffController],
  providers: [ImfStaffService, RolesGuard],
  exports: [ImfStaffService],
})
export class ImfStaffModule {}
