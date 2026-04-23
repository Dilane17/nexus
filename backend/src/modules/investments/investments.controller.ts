import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
  DefaultValuePipe,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiBody,
} from '@nestjs/swagger';
import { InvestmentsService } from './investments.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { ZodValidationPipe } from '@shared/pipes/zod-validation.pipe';
import type { JwtPayload } from '@modules/auth/auth.types';

import {
  createInvestmentSchema,
  CreateInvestmentDtoDoc,
} from './dto/create-investment.dto';
import type { CreateInvestmentDto } from './dto/create-investment.dto';
import {
  autoInvestRuleSchema,
  AutoInvestRuleDtoDoc,
} from './dto/auto-invest-rule.dto';
import type { AutoInvestRuleDto } from './dto/auto-invest-rule.dto';

@ApiTags('Investments')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('investments')
export class InvestmentsController {
  constructor(private readonly investmentsService: InvestmentsService) {}

  // ── Routes statiques en premier ───────────────────────────────────────────

  @Get('my')
  @ApiOperation({ summary: 'Mon portefeuille d\'investissements (paginé)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 10 })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['ACTIVE', 'COMPLETED', 'DEFAULTED', 'GUARANTEED'],
  })
  async getMyInvestments(
    @CurrentUser() user: JwtPayload,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('status') status?: string,
  ) {
    const data = await this.investmentsService.getMyInvestments(
      user.sub,
      page,
      limit,
      status,
    );
    return { success: true, data, message: 'Portefeuille récupéré' };
  }

  @Get('my/summary')
  @ApiOperation({
    summary: 'Résumé du portefeuille (totaux, rendements, taux NPL)',
  })
  async getPortfolioSummary(@CurrentUser() user: JwtPayload) {
    const data = await this.investmentsService.getPortfolioSummary(user.sub);
    return { success: true, data, message: 'Résumé du portefeuille récupéré' };
  }

  // ── Routes paramétriques ──────────────────────────────────────────────────

  @Get(':id')
  @ApiOperation({ summary: 'Détail d\'un investissement' })
  @ApiParam({ name: 'id', description: "UUID de l'investissement" })
  async getInvestmentById(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) investmentId: string,
  ) {
    const data = await this.investmentsService.getInvestmentById(
      user.sub,
      investmentId,
    );
    return { success: true, data, message: 'Investissement récupéré' };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Investir sur un prêt en statut FUNDING',
  })
  @ApiBody({ type: CreateInvestmentDtoDoc })
  async createInvestment(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(createInvestmentSchema)) dto: CreateInvestmentDto,
  ) {
    const data = await this.investmentsService.createInvestment(user.sub, dto);
    return {
      success: true,
      data,
      message: 'Investissement enregistré avec succès',
    };
  }

  // ── Auto-Invest ───────────────────────────────────────────────────────────

  @Get('auto-invest')
  @ApiOperation({ summary: 'Consulter sa règle Auto-Invest active' })
  async getAutoInvestRule(@CurrentUser() user: JwtPayload) {
    const data = await this.investmentsService.getAutoInvestRule(user.sub);
    return {
      success: true,
      data,
      message: data ? 'Règle Auto-Invest récupérée' : 'Aucune règle Auto-Invest configurée',
    };
  }

  @Put('auto-invest')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Créer ou mettre à jour la règle Auto-Invest (activer / désactiver)',
  })
  @ApiBody({ type: AutoInvestRuleDtoDoc })
  async setAutoInvestRule(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(autoInvestRuleSchema)) dto: AutoInvestRuleDto,
  ) {
    const data = await this.investmentsService.setAutoInvestRule(user.sub, dto);
    const action = dto.is_active ? 'activée' : 'désactivée';
    return {
      success: true,
      data,
      message: `Règle Auto-Invest ${action} avec succès`,
    };
  }

  @Post('auto-invest/run')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Lancer manuellement l\'Auto-Invest — scanne tous les prêts FUNDING éligibles',
  })
  async runAutoInvest(@CurrentUser() user: JwtPayload) {
    const data = await this.investmentsService.runAutoInvest(user.sub);
    return {
      success: true,
      data,
      message: `Auto-Invest exécuté — ${data.investmentsCreated} investissement(s) créé(s) pour ${data.totalInvested.toLocaleString()} FCFA`,
    };
  }
}
