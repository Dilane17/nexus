import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '@shared/prisma/prisma.service';
import type {
  EscrowWalletResponse,
  PlatformWalletResponse,
  WalletSummaryResponse,
} from './dto/wallet-response.dto';

@Injectable()
export class WalletService implements OnModuleInit {
  private readonly logger = new Logger(WalletService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ── Initialisation au démarrage ──────────────────────────────────────────────

  async onModuleInit(): Promise<void> {
    await Promise.all([
      this.ensureEscrowWalletExists(),
      this.ensurePlatformWalletExists(),
    ]);
    this.logger.log('✅ Wallets initialisés');
  }

  private async ensureEscrowWalletExists(): Promise<void> {
    const existing = await this.prisma.escrowWallet.findFirst();
    if (!existing) {
      await this.prisma.escrowWallet.create({
        data: {
          total_balance: 0,
          investor_funds: 0,
          pending_disbursements: 0,
          locked_for_guarantee: 0,
          platform_fees: 0,
          third_party_manager: 'Nexus',
        },
      });
      this.logger.log('EscrowWallet créé (défaut)');
    }
  }

  private async ensurePlatformWalletExists(): Promise<void> {
    const existing = await this.prisma.platformWallet.findFirst();
    if (!existing) {
      await this.prisma.platformWallet.create({
        data: {
          commission_balance: 0,
          operating_funds: 0,
        },
      });
      this.logger.log('PlatformWallet créé (défaut)');
    }
  }

  // ── Lectures ─────────────────────────────────────────────────────────────────

  async getEscrowWallet(): Promise<EscrowWalletResponse> {
    const wallet = await this.prisma.escrowWallet.findFirstOrThrow();
    return this.toEscrowResponse(wallet);
  }

  async getPlatformWallet(): Promise<PlatformWalletResponse> {
    const wallet = await this.prisma.platformWallet.findFirstOrThrow();
    return this.toPlatformResponse(wallet);
  }

  async getWalletSummary(): Promise<WalletSummaryResponse> {
    const [escrow, platform] = await Promise.all([
      this.prisma.escrowWallet.findFirstOrThrow(),
      this.prisma.platformWallet.findFirstOrThrow(),
    ]);

    const escrowResp = this.toEscrowResponse(escrow);
    const platformResp = this.toPlatformResponse(platform);

    return {
      escrow: escrowResp,
      platform: platformResp,
      totalPlatformValue: (Number(escrow.total_balance) +
        Number(platform.commission_balance) +
        Number(
          platform.operating_funds,
        )) as unknown as WalletSummaryResponse['totalPlatformValue'],
    };
  }

  // ── Mutations atomiques (appelées par d'autres services) ──────────────────────

  async updateEscrowOnDeposit(amount: number): Promise<EscrowWalletResponse> {
    const wallet = await this.prisma.escrowWallet.findFirstOrThrow();
    const updated = await this.prisma.escrowWallet.update({
      where: { id: wallet.id },
      data: {
        investor_funds: { increment: amount },
        total_balance: { increment: amount },
      },
    });
    this.logger.log(`[ESCROW] Dépôt investisseur +${amount}`);
    return this.toEscrowResponse(updated);
  }

  async updateEscrowOnDisbursement(
    amount: number,
  ): Promise<EscrowWalletResponse> {
    const wallet = await this.prisma.escrowWallet.findFirstOrThrow();
    const updated = await this.prisma.escrowWallet.update({
      where: { id: wallet.id },
      data: {
        pending_disbursements: { decrement: amount },
        total_balance: { decrement: amount },
      },
    });
    this.logger.log(`[ESCROW] Décaissement -${amount}`);
    return this.toEscrowResponse(updated);
  }

  async updateEscrowOnGuarantee(amount: number): Promise<EscrowWalletResponse> {
    const wallet = await this.prisma.escrowWallet.findFirstOrThrow();
    const updated = await this.prisma.escrowWallet.update({
      where: { id: wallet.id },
      data: {
        locked_for_guarantee: { increment: amount },
      },
    });
    this.logger.log(`[ESCROW] Garantie +${amount}`);
    return this.toEscrowResponse(updated);
  }

  async addPlatformCommission(amount: number): Promise<PlatformWalletResponse> {
    const wallet = await this.prisma.platformWallet.findFirstOrThrow();
    const updated = await this.prisma.platformWallet.update({
      where: { id: wallet.id },
      data: {
        commission_balance: { increment: amount },
      },
    });
    this.logger.log(`[PLATFORM] Commission +${amount}`);
    return this.toPlatformResponse(updated);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  private toEscrowResponse(wallet: {
    id: string;
    total_balance: { valueOf(): string };
    investor_funds: { valueOf(): string };
    pending_disbursements: { valueOf(): string };
    locked_for_guarantee: { valueOf(): string };
    platform_fees: { valueOf(): string };
    third_party_manager: string;
    last_audit_date: Date | null;
  }): EscrowWalletResponse {
    return {
      id: wallet.id,
      totalBalance:
        wallet.total_balance.valueOf() as unknown as EscrowWalletResponse['totalBalance'],
      investorFunds:
        wallet.investor_funds.valueOf() as unknown as EscrowWalletResponse['investorFunds'],
      pendingDisbursements:
        wallet.pending_disbursements.valueOf() as unknown as EscrowWalletResponse['pendingDisbursements'],
      lockedForGuarantee:
        wallet.locked_for_guarantee.valueOf() as unknown as EscrowWalletResponse['lockedForGuarantee'],
      platformFees:
        wallet.platform_fees.valueOf() as unknown as EscrowWalletResponse['platformFees'],
      thirdPartyManager: wallet.third_party_manager,
      lastAuditDate: wallet.last_audit_date,
    };
  }

  private toPlatformResponse(wallet: {
    id: string;
    commission_balance: { valueOf(): string };
    operating_funds: { valueOf(): string };
    last_withdrawal_date: Date | null;
  }): PlatformWalletResponse {
    return {
      id: wallet.id,
      commissionBalance:
        wallet.commission_balance.valueOf() as unknown as PlatformWalletResponse['commissionBalance'],
      operatingFunds:
        wallet.operating_funds.valueOf() as unknown as PlatformWalletResponse['operatingFunds'],
      lastWithdrawalDate: wallet.last_withdrawal_date,
    };
  }
}
