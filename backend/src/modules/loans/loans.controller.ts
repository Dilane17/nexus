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
import { LoansService } from './loans.service';
import { ImfSandboxService } from './imf-sandbox.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { Roles } from '@shared/decorators/roles.decorator';
import { ZodValidationPipe } from '@shared/pipes/zod-validation.pipe';
import type { JwtPayload } from '@modules/auth/auth.types';

import { createLoanSchema, CreateLoanDtoDoc } from './dto/create-loan.dto';
import { validateLoanSchema, ValidateLoanDtoDoc } from './dto/validate-loan.dto';
import { repayLoanSchema, RepayLoanDtoDoc } from './dto/repay-loan.dto';
import type { CreateLoanDto } from './dto/create-loan.dto';
import type { ValidateLoanDto } from './dto/validate-loan.dto';
import type { RepayLoanDto } from './dto/repay-loan.dto';

@ApiTags('Loans')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('loans')
export class LoansController {
  constructor(
    private readonly loansService: LoansService,
    private readonly imfSandboxService: ImfSandboxService,
  ) {}

  // ── Routes statiques en premier (avant :id) ───────────────────────────────

  @Get('my')
  @ApiOperation({ summary: 'Mes demandes de prêt (emprunteur)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 10 })
  async getMyLoans(
    @CurrentUser() user: JwtPayload,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    const data = await this.loansService.getMyLoans(user.sub, page, limit);
    return { success: true, data, message: 'Prêts récupérés' };
  }

  @Get('funding')
  @ApiOperation({ summary: 'Marketplace investisseur — prêts ouverts au financement' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getFundingLoans(
    @CurrentUser() user: JwtPayload,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const data = await this.loansService.getFundingLoans(user.sub, page, limit);
    return {
      success: true,
      data,
      message: 'Prêts ouverts au financement récupérés',
    };
  }

  @Get('pending-imf')
  @UseGuards(RolesGuard)
  @Roles('imf_staff', 'admin')
  @ApiOperation({ summary: '[IMF] Dossiers de prêt en attente de validation' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getPendingImfLoans(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const data = await this.loansService.getPendingImfLoans(page, limit);
    return {
      success: true,
      data,
      message: 'Dossiers en attente récupérés',
    };
  }

  // ── Routes paramétriques ──────────────────────────────────────────────────

  @Get(':id')
  @ApiOperation({ summary: 'Détail d\'un prêt (emprunteur propriétaire ou IMF/Admin)' })
  @ApiParam({ name: 'id', description: 'UUID du prêt' })
  async getLoanById(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) loanId: string,
  ) {
    const data = await this.loansService.getLoanById(user.sub, loanId);
    return { success: true, data, message: 'Prêt récupéré' };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Créer une demande de prêt (KYC VALIDATED requis)' })
  @ApiBody({ type: CreateLoanDtoDoc })
  async createLoan(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(createLoanSchema)) dto: CreateLoanDto,
  ) {
    const data = await this.loansService.createLoan(user.sub, dto);
    return {
      success: true,
      data,
      message: 'Demande de prêt soumise — en attente de validation IMF',
    };
  }

  @Patch(':id/validate')
  @UseGuards(RolesGuard)
  @Roles('imf_staff', 'admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[IMF] Approuver ou rejeter une demande de prêt' })
  @ApiParam({ name: 'id', description: 'UUID du prêt' })
  @ApiBody({ type: ValidateLoanDtoDoc })
  async validateLoan(
    @CurrentUser() imfStaff: JwtPayload,
    @Param('id', ParseUUIDPipe) loanId: string,
    @Body(new ZodValidationPipe(validateLoanSchema)) dto: ValidateLoanDto,
  ) {
    const data = await this.loansService.validateLoan(imfStaff.sub, loanId, dto);
    const message =
      dto.decision === 'APPROVED'
        ? 'Prêt approuvé — ouvert au financement'
        : 'Prêt rejeté — emprunteur notifié';
    return { success: true, data, message };
  }

  @Post(':id/repay')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Soumettre un remboursement MoMo pour un prêt ACTIVE/OVERDUE' })
  @ApiParam({ name: 'id', description: 'UUID du prêt' })
  @ApiBody({ type: RepayLoanDtoDoc })
  async repayLoan(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) loanId: string,
    @Body(new ZodValidationPipe(repayLoanSchema)) dto: RepayLoanDto,
  ) {
    const data = await this.loansService.repayLoan(user.sub, loanId, dto);
    return {
      success: true,
      data,
      message: data.status === 'REPAID'
        ? 'Prêt entièrement remboursé — félicitations !'
        : 'Remboursement enregistré avec succès',
    };
  }

  @Post(':id/sandbox-score')
  @UseGuards(RolesGuard)
  @Roles('imf_staff', 'admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[IMF] Scoring sandbox — évaluation simulée du risque emprunteur',
    description: 'Retourne une recommandation (APPROVE / APPROVE_WITH_CONDITIONS / HIGH_RISK / REJECT) et un taux suggéré basé sur le score hybride.',
  })
  @ApiParam({ name: 'id', description: 'UUID du prêt à évaluer' })
  async sandboxScore(
    @CurrentUser() imfStaff: JwtPayload,
    @Param('id', ParseUUIDPipe) loanId: string,
  ) {
    const data = await this.imfSandboxService.scoreLoan(imfStaff.sub, loanId);
    return {
      success: true,
      data,
      message: `Scoring sandbox : ${data.recommendation} — taux suggéré : ${(data.suggestedInterestRate * 100).toFixed(0)}%`,
    };
  }
}
