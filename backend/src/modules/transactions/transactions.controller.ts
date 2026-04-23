import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  Req,
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
import type { Request } from 'express';
import { TransactionsService } from './transactions.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import { Public } from '@shared/decorators/public.decorator';
import { Roles } from '@shared/decorators/roles.decorator';
import { ZodValidationPipe } from '@shared/pipes/zod-validation.pipe';
import type { JwtPayload } from '@modules/auth/auth.types';

import { depositSchema, DepositDtoDoc } from './dto/deposit.dto';
import { withdrawalSchema, WithdrawalDtoDoc } from './dto/withdrawal.dto';
import type { DepositDto } from './dto/deposit.dto';
import type { WithdrawalDto } from './dto/withdrawal.dto';

@ApiTags('Transactions')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  // ── Routes statiques ──────────────────────────────────────────────────────

  @Get('my')
  @ApiOperation({ summary: 'Historique de mes transactions (paginé)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: [
      'INVESTOR_DEPOSIT',
      'INVESTOR_WITHDRAWAL',
      'LOAN_REPAYMENT',
      'LOAN_DISBURSEMENT',
      'PLATFORM_COMMISSION',
    ],
  })
  async getMyTransactions(
    @CurrentUser() user: JwtPayload,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('type') type?: string,
  ) {
    const data = await this.transactionsService.getMyTransactions(
      user.sub,
      page,
      limit,
      type,
    );
    return { success: true, data, message: 'Transactions récupérées' };
  }

  @Get('unreconciled')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({
    summary:
      '[Admin] Transactions CONFIRMED / PHANTOM non réconciliées (détection PHANTOM auto H+24)',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 50 })
  async getUnreconciled(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ) {
    const data = await this.transactionsService.getUnreconciled(page, limit);
    return {
      success: true,
      data,
      message: 'Transactions non réconciliées récupérées',
    };
  }

  @Post('deposit')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Initier un dépôt MoMo (Investor)' })
  @ApiBody({ type: DepositDtoDoc })
  async initiateDeposit(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(depositSchema)) dto: DepositDto,
  ) {
    const data = await this.transactionsService.initiateDeposit(user.sub, dto);
    return { success: true, data, message: data.message };
  }

  @Post('withdraw')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Initier un retrait MoMo (Investor)' })
  @ApiBody({ type: WithdrawalDtoDoc })
  async initiateWithdrawal(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(withdrawalSchema)) dto: WithdrawalDto,
  ) {
    const data = await this.transactionsService.initiateWithdrawal(
      user.sub,
      dto,
    );
    return {
      success: true,
      data,
      message: 'Retrait initié — en attente de confirmation MoMo',
    };
  }

  // ── Webhooks (sans auth JWT — appelés par les providers) ─────────────────

  @Post('webhook/fedapay')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Webhook FedaPay] Callback de confirmation de paiement',
  })
  @ApiBody({ schema: { type: 'object', additionalProperties: true } })
  async webhookFedapay(
    @Req() req: Request & { rawBody?: Buffer },
    @Body() payload: unknown,
  ) {
    const data = await this.transactionsService.handleWebhook(
      'FEDAPAY',
      payload,
      req.rawBody ?? Buffer.from(JSON.stringify(payload ?? {})),
      req.headers,
    );
    return { success: true, data };
  }

  @Post('webhook/kkiapay')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Webhook KKiaPay] Callback de confirmation de paiement',
  })
  @ApiBody({ schema: { type: 'object', additionalProperties: true } })
  async webhookKkiapay(
    @Req() req: Request & { rawBody?: Buffer },
    @Body() payload: unknown,
  ) {
    const data = await this.transactionsService.handleWebhook(
      'KKIAPAY',
      payload,
      req.rawBody ?? Buffer.from(JSON.stringify(payload ?? {})),
      req.headers,
    );
    return { success: true, data };
  }

  // ── Routes paramétriques ──────────────────────────────────────────────────

  @Patch(':id/reconcile')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] Marquer une transaction comme réconciliée',
  })
  @ApiParam({ name: 'id', description: 'UUID de la transaction' })
  async reconcileTransaction(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) transactionId: string,
  ) {
    const data = await this.transactionsService.reconcileTransaction(
      user.sub,
      transactionId,
    );
    return {
      success: true,
      data,
      message: "Transaction réconciliée — piste d'audit mise à jour",
    };
  }
}
