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
import { ImfStaffService } from './imf-staff.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { Roles } from '@shared/decorators/roles.decorator';
import type { JwtPayload } from '@modules/auth/auth.types';

@ApiTags('IMF Staff')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('imf_staff')
@Controller('imf-staff')
export class ImfStaffController {
  constructor(private readonly imfStaffService: ImfStaffService) {}

  // ── Profil ───────────────────────────────────────────────────────────────────

  @Get('profile')
  @ApiOperation({ summary: "[IMF] Profil complet de l'agent IMF connecté" })
  async getProfile(@CurrentUser() user: JwtPayload) {
    const data = await this.imfStaffService.getProfile(user.sub);
    return { success: true, data, message: 'Profil IMF récupéré' };
  }

  // ── Prêts en attente ─────────────────────────────────────────────────────────

  @Get('loans/pending')
  @ApiOperation({ summary: '[IMF] Prêts en attente de validation (PENDING_IMF)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getPendingLoans(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const data = await this.imfStaffService.getPendingLoans(page, limit);
    return { success: true, data, message: 'Prêts en attente récupérés' };
  }

  // ── Prêts traités ────────────────────────────────────────────────────────────

  @Get('loans/validated')
  @ApiOperation({ summary: '[IMF] Prêts déjà traités (validés ou rejetés)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getValidatedLoans(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const data = await this.imfStaffService.getValidatedLoans(page, limit);
    return { success: true, data, message: 'Prêts traités récupérés' };
  }

  // ── Dashboard ────────────────────────────────────────────────────────────────

  @Get('dashboard')
  @ApiOperation({ summary: '[IMF] Statistiques — prêts en attente, validés, rejetés' })
  async getDashboard() {
    const data = await this.imfStaffService.getDashboardStats();
    return { success: true, data, message: 'Dashboard IMF récupéré' };
  }
}
