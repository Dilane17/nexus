import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { TontineController } from './tontine.controller';
import { TontineService } from './tontine.service';

@Module({
  imports: [PassportModule],
  controllers: [TontineController],
  providers: [TontineService],
  exports: [TontineService],
})
export class TontineModule {}
