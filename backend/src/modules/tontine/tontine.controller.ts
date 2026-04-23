import {
  Controller,
  Get,
  Post,
  Patch,
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
import { TontineService } from './tontine.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { ZodValidationPipe } from '@shared/pipes/zod-validation.pipe';
import type { JwtPayload } from '@modules/auth/auth.types';

import {
  createTontineGroupSchema,
  CreateTontineGroupDtoDoc,
} from './dto/create-tontine-group.dto';
import { createCycleSchema, CreateCycleDtoDoc } from './dto/create-cycle.dto';
import { completeCycleSchema, CompleteCycleDtoDoc } from './dto/complete-cycle.dto';
import type { CreateTontineGroupDto } from './dto/create-tontine-group.dto';
import type { CreateCycleDto } from './dto/create-cycle.dto';
import type { CompleteCycleDto } from './dto/complete-cycle.dto';

@ApiTags('Tontine')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('tontine')
export class TontineController {
  constructor(private readonly tontineService: TontineService) {}

  // ── Routes statiques ──────────────────────────────────────────────────────

  @Get('my-score')
  @ApiOperation({ summary: 'Consulter son score tontine et son historique' })
  async getMyScore(@CurrentUser() user: JwtPayload) {
    const data = await this.tontineService.getMyScore(user.sub);
    return { success: true, data, message: 'Score tontine récupéré' };
  }

  @Get('groups')
  @ApiOperation({ summary: 'Lister les groupes tontine (public)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['PENDING', 'ACTIVE', 'COMPLETED', 'SUSPENDED'],
  })
  async listGroups(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
  ) {
    const data = await this.tontineService.listGroups(page, limit, status);
    return { success: true, data, message: 'Groupes tontine récupérés' };
  }

  @Post('groups')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Créer un groupe tontine (Borrower requis, max 1 groupe actif)' })
  @ApiBody({ type: CreateTontineGroupDtoDoc })
  async createGroup(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(createTontineGroupSchema)) dto: CreateTontineGroupDto,
  ) {
    const data = await this.tontineService.createGroup(user.sub, dto);
    return {
      success: true,
      data,
      message: 'Groupe tontine créé — vous en êtes automatiquement le premier membre',
    };
  }

  // ── Routes paramétriques groupes ─────────────────────────────────────────

  @Get('groups/:id')
  @ApiOperation({ summary: 'Détail d\'un groupe (membres + cycles)' })
  @ApiParam({ name: 'id', description: 'UUID du groupe' })
  async getGroupById(@Param('id', ParseUUIDPipe) groupId: string) {
    const data = await this.tontineService.getGroupById(groupId);
    return { success: true, data, message: 'Groupe récupéré' };
  }

  @Post('groups/:id/join')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Rejoindre un groupe tontine (Borrower requis)' })
  @ApiParam({ name: 'id', description: 'UUID du groupe' })
  async joinGroup(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) groupId: string,
  ) {
    const data = await this.tontineService.joinGroup(user.sub, groupId);
    return {
      success: true,
      data,
      message: 'Vous avez rejoint le groupe avec succès',
    };
  }

  @Post('groups/:id/cycles')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: '[Leader] Démarrer un nouveau cycle' })
  @ApiParam({ name: 'id', description: 'UUID du groupe' })
  @ApiBody({ type: CreateCycleDtoDoc })
  async createCycle(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) groupId: string,
    @Body(new ZodValidationPipe(createCycleSchema)) dto: CreateCycleDto,
  ) {
    const data = await this.tontineService.createCycle(user.sub, groupId, dto);
    return { success: true, data, message: 'Cycle démarré avec succès' };
  }

  // ── Routes paramétriques cycles ───────────────────────────────────────────

  @Patch('cycles/:id/complete')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Leader] Clôturer un cycle + recalcul du score tontine' })
  @ApiParam({ name: 'id', description: 'UUID du cycle' })
  @ApiBody({ type: CompleteCycleDtoDoc })
  async completeCycle(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) cycleId: string,
    @Body(new ZodValidationPipe(completeCycleSchema)) dto: CompleteCycleDto,
  ) {
    const data = await this.tontineService.completeCycle(user.sub, cycleId, dto);
    return {
      success: true,
      data,
      message: 'Cycle clôturé — score tontine mis à jour',
    };
  }
}
