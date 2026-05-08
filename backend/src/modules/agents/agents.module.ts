import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AgentsController } from './agents.controller';
import { AgentsService } from './agents.service';
import { RolesGuard } from '@shared/guards/roles.guard';

@Module({
  imports: [PassportModule],
  controllers: [AgentsController],
  providers: [AgentsService, RolesGuard],
  exports: [AgentsService],
})
export class AgentsModule {}
