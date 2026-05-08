import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { WalletService } from './wallet.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { Roles } from '@shared/decorators/roles.decorator';

@ApiTags('Wallet')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Controller('wallet')
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  // ── Escrow ───────────────────────────────────────────────────────────────────

  @Get('escrow')
  @ApiOperation({ summary: '[Admin] État du wallet séquestre (EscrowWallet)' })
  async getEscrow() {
    const data = await this.walletService.getEscrowWallet();
    return { success: true, data, message: 'EscrowWallet récupéré' };
  }

  // ── Platform ─────────────────────────────────────────────────────────────────

  @Get('platform')
  @ApiOperation({
    summary: '[Admin] État du wallet plateforme (PlatformWallet)',
  })
  async getPlatform() {
    const data = await this.walletService.getPlatformWallet();
    return { success: true, data, message: 'PlatformWallet récupéré' };
  }

  // ── Summary ──────────────────────────────────────────────────────────────────

  @Get('summary')
  @ApiOperation({ summary: '[Admin] Vue consolidée Escrow + Platform' })
  async getSummary() {
    const data = await this.walletService.getWalletSummary();
    return { success: true, data, message: 'Résumé wallets récupéré' };
  }
}
