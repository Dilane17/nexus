import {
  Controller,
  Get,
  Query,
  UseGuards,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
} from '@nestjs/swagger';
import { AgentsService } from './agents.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { Roles } from '@shared/decorators/roles.decorator';
import type { JwtPayload } from '@modules/auth/auth.types';

@ApiTags('Agents')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('agent')
@Controller('agents')
export class AgentsController {
  constructor(private readonly agentsService: AgentsService) {}

  // ── Profil ───────────────────────────────────────────────────────────────────

  @Get('profile')
  @ApiOperation({ summary: "[Agent] Profil complet de l'agent connecté" })
  async getProfile(@CurrentUser() user: JwtPayload) {
    const data = await this.agentsService.getProfile(user.sub);
    return { success: true, data, message: 'Profil agent récupéré' };
  }

  // ── Clients de la zone ───────────────────────────────────────────────────────

  @Get('clients')
  @ApiOperation({ summary: '[Agent] Clients situés dans sa zone' })
  async getClients(@CurrentUser() user: JwtPayload) {
    const data = await this.agentsService.getClientsByZone(user.sub);
    return { success: true, data, message: 'Clients de la zone récupérés' };
  }

  // ── Historique commissions ───────────────────────────────────────────────────

  @Get('commissions')
  @ApiOperation({ summary: '[Agent] Historique des commissions perçues' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getCommissions(
    @CurrentUser() user: JwtPayload,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const data = await this.agentsService.getCommissionHistory(user.sub, page, limit);
    return { success: true, data, message: 'Commissions récupérées' };
  }

  // ── Dashboard ────────────────────────────────────────────────────────────────

  @Get('dashboard')
  @ApiOperation({ summary: '[Agent] Statistiques — clients, commissions' })
  async getDashboard(@CurrentUser() user: JwtPayload) {
    const data = await this.agentsService.getDashboardStats(user.sub);
    return { success: true, data, message: 'Dashboard agent récupéré' };
  }
}
