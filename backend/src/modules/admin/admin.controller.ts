import {
  Controller,
  Get,
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
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { Roles } from '@shared/decorators/roles.decorator';
import { ZodValidationPipe } from '@shared/pipes/zod-validation.pipe';
import type { JwtPayload } from '@modules/auth/auth.types';

import {
  updateUserStatusSchema,
  UpdateUserStatusDtoDoc,
} from './dto/update-user-status.dto';
import type { UpdateUserStatusDto } from './dto/update-user-status.dto';

@ApiTags('Admin')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ── Dashboard ─────────────────────────────────────────────────────────────

  @Get('dashboard')
  @ApiOperation({ summary: '[Admin] Tableau de bord global — NPL, utilisateurs, transactions' })
  async getDashboard() {
    const data = await this.adminService.getDashboard();
    return { success: true, data, message: 'Dashboard récupéré' };
  }

  // ── Rapport BCEAO ─────────────────────────────────────────────────────────

  @Get('reports/bceao')
  @ApiOperation({ summary: '[Admin] Rapport BCEAO — encours, NPL, réconciliation, fonds de garantie' })
  @ApiQuery({ name: 'from', required: true, example: '2026-01-01', description: 'Date de début (YYYY-MM-DD)' })
  @ApiQuery({ name: 'to', required: true, example: '2026-04-30', description: 'Date de fin (YYYY-MM-DD)' })
  async getBceaoReport(
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    const data = await this.adminService.getBceaoReport(from, to);
    return { success: true, data, message: 'Rapport BCEAO généré' };
  }

  // ── Fonds de garantie ─────────────────────────────────────────────────────

  @Get('guarantee-fund')
  @ApiOperation({ summary: '[Admin] État du fonds de garantie' })
  async getGuaranteeFund() {
    const data = await this.adminService.getGuaranteeFund();
    return { success: true, data, message: 'Fonds de garantie récupéré' };
  }

  // ── Gestion utilisateurs ──────────────────────────────────────────────────

  @Get('users')
  @ApiOperation({ summary: '[Admin] Lister tous les utilisateurs' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'status', required: false, enum: ['PENDING', 'ACTIVE', 'SUSPENDED', 'BLOCKED'] })
  @ApiQuery({ name: 'kyc_status', required: false, enum: ['NOT_STARTED', 'SESSION1_DONE', 'SESSION2_DONE', 'VALIDATED', 'REJECTED'] })
  async listUsers(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
    @Query('kyc_status') kyc_status?: string,
  ) {
    const data = await this.adminService.listUsers(page, limit, status, kyc_status);
    return { success: true, data, message: 'Utilisateurs récupérés' };
  }

  @Get('users/:id')
  @ApiOperation({ summary: '[Admin] Fiche complète d\'un utilisateur' })
  @ApiParam({ name: 'id', description: 'UUID de l\'utilisateur' })
  async getUserById(@Param('id', ParseUUIDPipe) userId: string) {
    const data = await this.adminService.getUserById(userId);
    return { success: true, data, message: 'Utilisateur récupéré' };
  }

  @Patch('users/:id/status')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Bloquer, suspendre ou réactiver un compte' })
  @ApiParam({ name: 'id', description: 'UUID de l\'utilisateur' })
  @ApiBody({ type: UpdateUserStatusDtoDoc })
  async updateUserStatus(
    @CurrentUser() admin: JwtPayload,
    @Param('id', ParseUUIDPipe) targetUserId: string,
    @Body(new ZodValidationPipe(updateUserStatusSchema)) dto: UpdateUserStatusDto,
  ) {
    const data = await this.adminService.updateUserStatus(admin.sub, targetUserId, dto);
    const action = dto.status === 'ACTIVE' ? 'réactivé' : dto.status === 'SUSPENDED' ? 'suspendu' : 'bloqué';
    return { success: true, data, message: `Compte utilisateur ${action}` };
  }
}
