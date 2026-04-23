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
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiBody,
} from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { Roles } from '@shared/decorators/roles.decorator';
import { ZodValidationPipe } from '@shared/pipes/zod-validation.pipe';
import type { JwtPayload } from '@modules/auth/auth.types';

import { kycSession1Schema, KycSession1DtoDoc } from './dto/kyc-session1.dto';
import { kycSession2Schema, KycSession2DtoDoc } from './dto/kyc-session2.dto';
import { kycValidateSchema, KycValidateDtoDoc } from './dto/kyc-validate.dto';
import type { KycSession1Dto } from './dto/kyc-session1.dto';
import type { KycSession2Dto } from './dto/kyc-session2.dto';
import type { KycValidateDto } from './dto/kyc-validate.dto';

@ApiTags('Users')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // ── KYC Session 1 — Document d'identité ─────────────────────────────────────

  @Post('kyc/session-1')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Soumettre le document d'identité (session 1/3)" })
  @ApiBody({ type: KycSession1DtoDoc })
  async submitKycSession1(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(kycSession1Schema)) dto: KycSession1Dto,
  ) {
    const data = await this.usersService.submitKycSession1(user.sub, dto);
    return {
      success: true,
      data,
      message: 'Session 1 KYC enregistrée avec succès',
    };
  }

  // ── KYC Session 2 — Informations financières ─────────────────────────────────

  @Post('kyc/session-2')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Soumettre les informations financières (session 2/3)',
  })
  @ApiBody({ type: KycSession2DtoDoc })
  async submitKycSession2(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(kycSession2Schema)) dto: KycSession2Dto,
  ) {
    const data = await this.usersService.submitKycSession2(user.sub, dto);
    return {
      success: true,
      data,
      message: 'Session 2 KYC enregistrée avec succès',
    };
  }

  // ── KYC Session 3 — Soumission finale ───────────────────────────────────────

  @Post('kyc/session-3')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Soumettre le dossier KYC pour validation IMF (session 3/3)',
  })
  async submitKycSession3(@CurrentUser() user: JwtPayload) {
    const data = await this.usersService.submitKycSession3(user.sub);
    return {
      success: true,
      data,
      message: 'Dossier KYC soumis — en attente de validation IMF',
    };
  }

  // ── Statut KYC ──────────────────────────────────────────────────────────────

  @Get('kyc/status')
  @ApiOperation({ summary: 'Consulter son statut KYC' })
  async getKycStatus(@CurrentUser() user: JwtPayload) {
    const data = await this.usersService.getKycStatus(user.sub);
    return { success: true, data, message: 'Statut KYC récupéré' };
  }

  // ── Profil complet ──────────────────────────────────────────────────────────

  @Get('profile')
  @ApiOperation({
    summary: 'Consulter son profil complet (rôle + données métier)',
  })
  async getUserProfile(@CurrentUser() user: JwtPayload) {
    const data = await this.usersService.getUserProfile(user.sub);
    return { success: true, data, message: 'Profil récupéré' };
  }

  // ── Dossiers KYC en attente — IMF Staff ────────────────────────────────────

  @Get('kyc/pending')
  @UseGuards(RolesGuard)
  @Roles('imf_staff', 'admin')
  @ApiOperation({
    summary: '[IMF Staff] Lister les dossiers KYC en attente de validation',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getPendingKycDossiers(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const data = await this.usersService.getPendingKycDossiers(page, limit);
    return {
      success: true,
      data,
      message: 'Dossiers KYC en attente récupérés',
    };
  }

  // ── Valider / Rejeter un dossier KYC — IMF Staff ────────────────────────────

  @Patch('kyc/validate/:userId')
  @UseGuards(RolesGuard)
  @Roles('imf_staff', 'admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[IMF Staff] Approuver ou rejeter un dossier KYC' })
  @ApiParam({
    name: 'userId',
    description: "ID de l'utilisateur dont le dossier est à valider",
  })
  @ApiBody({ type: KycValidateDtoDoc })
  async validateKyc(
    @CurrentUser() imfStaff: JwtPayload,
    @Param('userId') targetUserId: string,
    @Body(new ZodValidationPipe(kycValidateSchema)) dto: KycValidateDto,
  ) {
    const data = await this.usersService.validateKyc(
      imfStaff.sub,
      targetUserId,
      dto,
    );
    const message =
      dto.decision === 'APPROVED'
        ? 'Dossier KYC approuvé — compte utilisateur activé'
        : 'Dossier KYC rejeté — utilisateur notifié';
    return { success: true, data, message };
  }
}
