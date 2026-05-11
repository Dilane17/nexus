import {
  BadGatewayException,
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type {
  Prisma,
  payment_gateway,
  transaction_status,
  transaction_type,
} from '@generated/prisma';
import { PrismaService } from '@shared/prisma/prisma.service';
import { NotificationService } from '@shared/notifications/notification.service';
import { WalletService } from '@modules/wallet/wallet.service';
import type { DepositDto } from './dto/deposit.dto';
import type { WithdrawalDto } from './dto/withdrawal.dto';
import type {
  DepositInitiatedResponse,
  PaginatedTransactionsResponse,
  TransactionResponse,
} from './dto/transaction-response.dto';
import { PaymentGatewayRouterService } from './gateways/payment-gateway-router.service';
import type {
  GatewayTransactionContext,
  SupportedGateway,
} from './gateways/payment-gateway.types';

type TransactionRecord = {
  id: string;
  type: string;
  amount: { toString(): string };
  status: string;
  payment_gateway: string | null;
  momo_reference: string | null;
  momo_provider: string | null;
  provider_transaction_id: string | null;
  provider_status: string | null;
  initiated_at: Date;
  confirmed_at: Date | null;
  reconciled_at: Date | null;
  is_reconciled: boolean;
  failure_reason: string | null;
  created_by: string;
};

function toTransactionResponse(t: TransactionRecord): TransactionResponse {
  return {
    id: t.id,
    type: t.type,
    amount: t.amount as TransactionResponse['amount'],
    status: t.status,
    paymentGateway: t.payment_gateway,
    momoReference: t.momo_reference,
    momoProvider: t.momo_provider,
    providerTransactionId: t.provider_transaction_id,
    providerStatus: t.provider_status,
    initiatedAt: t.initiated_at,
    confirmedAt: t.confirmed_at,
    reconciledAt: t.reconciled_at,
    isReconciled: t.is_reconciled,
    failureReason: t.failure_reason,
    createdBy: t.created_by,
  };
}

const TX_SELECT = {
  id: true,
  type: true,
  amount: true,
  status: true,
  payment_gateway: true,
  momo_reference: true,
  momo_provider: true,
  provider_transaction_id: true,
  provider_status: true,
  initiated_at: true,
  confirmed_at: true,
  reconciled_at: true,
  is_reconciled: true,
  failure_reason: true,
  created_by: true,
} as const;

function generateReference(): string {
  const rand = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `NEXUS-${Date.now()}-${rand}`;
}

@Injectable()
export class TransactionsService {
  private readonly logger = new Logger(TransactionsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly notifications: NotificationService,
    private readonly gatewayRouter: PaymentGatewayRouterService,
    private readonly walletService: WalletService,
  ) {}

  async initiateDeposit(
    userId: string,
    dto: DepositDto,
  ): Promise<DepositInitiatedResponse> {
    const user = await this.assertInvestorUser(userId);
    const gateway = this.gatewayRouter.resolveByMomoProvider(dto.momoProvider);
    const reference = generateReference();

    const created = await this.prisma.transaction.create({
      data: {
        type: 'INVESTOR_DEPOSIT',
        amount: dto.amount,
        status: 'PENDING',
        payment_gateway: gateway.gateway,
        momo_reference: reference,
        momo_provider: dto.momoProvider,
        provider_status: 'INITIATED_LOCAL',
        created_by: userId,
      },
      select: TX_SELECT,
    });

    try {
      const providerResult = await gateway.initiateDeposit(
        this.buildGatewayContext(
          reference,
          dto.amount,
          dto.momoProvider,
          dto.momoPhone,
          user,
          'Dépôt wallet Nexus',
          gateway.gateway,
        ),
      );

      const updated = await this.prisma.transaction.update({
        where: { id: created.id },
        data: {
          provider_transaction_id: providerResult.providerTransactionId,
          provider_status: providerResult.providerStatus,
          provider_payload: this.asJson(providerResult.payload),
        },
        select: TX_SELECT,
      });

      await this.notifications.notifyPaymentInitiated(
        user,
        'deposit',
        dto.amount,
        providerResult.gateway,
      );

      this.logger.log(
        `[DEPOSIT] ${providerResult.gateway} initié — ref: ${reference} — montant: ${dto.amount} FCFA — user: ${userId}`,
      );

      return {
        transaction: toTransactionResponse(updated),
        gateway: providerResult.gateway,
        providerTransactionId: providerResult.providerTransactionId,
        providerStatus: providerResult.providerStatus,
        paymentUrl: providerResult.paymentUrl,
        message: `Dépôt de ${dto.amount.toLocaleString()} FCFA initié. Complétez le paiement sur votre téléphone.`,
      };
    } catch (error: unknown) {
      const failureReason = this.toFailureReason(error);
      await this.prisma.transaction.update({
        where: { id: created.id },
        data: {
          status: 'FAILED',
          provider_status: 'FAILED_TO_INITIATE',
          failure_reason: failureReason,
        },
      });
      throw new BadGatewayException(failureReason);
    }
  }

  async initiateWithdrawal(
    userId: string,
    dto: WithdrawalDto,
  ): Promise<TransactionResponse> {
    const user = await this.assertInvestorUser(userId, true);
    const walletBalance = Number(user.wallet_balance?.toString() ?? 0);

    if (walletBalance < dto.amount) {
      throw new BadRequestException(
        `Solde insuffisant — wallet : ${walletBalance.toLocaleString()} FCFA`,
      );
    }

    const gateway = this.gatewayRouter.resolveByMomoProvider(dto.momoProvider);
    const reference = generateReference();

    const created = await this.prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.create({
        data: {
          type: 'INVESTOR_WITHDRAWAL',
          amount: dto.amount,
          status: 'PENDING',
          payment_gateway: gateway.gateway,
          momo_reference: reference,
          momo_provider: dto.momoProvider,
          provider_status: 'INITIATED_LOCAL',
          created_by: userId,
        },
        select: TX_SELECT,
      });

      await tx.investor.update({
        where: { id: userId },
        data: { wallet_balance: { decrement: dto.amount } },
      });

      return transaction;
    });

    try {
      const providerResult = await gateway.initiateWithdrawal(
        this.buildGatewayContext(
          reference,
          dto.amount,
          dto.momoProvider,
          dto.momoNumber,
          user,
          'Retrait wallet Nexus',
          gateway.gateway,
        ),
      );

      const updated = await this.prisma.transaction.update({
        where: { id: created.id },
        data: {
          provider_transaction_id: providerResult.providerTransactionId,
          provider_status: providerResult.providerStatus,
          provider_payload: this.asJson(providerResult.payload),
        },
        select: TX_SELECT,
      });

      await this.notifications.notifyPaymentInitiated(
        user,
        'withdrawal',
        dto.amount,
        providerResult.gateway,
      );

      this.logger.log(
        `[WITHDRAWAL] ${providerResult.gateway} initié — ref: ${reference} — montant: ${dto.amount} FCFA — user: ${userId}`,
      );

      return toTransactionResponse(updated);
    } catch (error: unknown) {
      const failureReason = this.toFailureReason(error);

      await this.prisma.$transaction(async (tx) => {
        await tx.transaction.update({
          where: { id: created.id },
          data: {
            status: 'FAILED',
            provider_status: 'FAILED_TO_INITIATE',
            failure_reason: failureReason,
          },
        });

        await tx.investor.update({
          where: { id: userId },
          data: { wallet_balance: { increment: dto.amount } },
        });
      });

      throw new BadGatewayException(failureReason);
    }
  }

  async getMyTransactions(
    userId: string,
    page: number,
    limit: number,
    type?: string,
  ): Promise<PaginatedTransactionsResponse> {
    const where = {
      created_by: userId,
      ...(type ? { type: type as transaction_type } : {}),
    };

    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where,
        select: TX_SELECT,
        orderBy: { initiated_at: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({ where }),
    ]);

    return {
      items: transactions.map((tx) => toTransactionResponse(tx)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async handleWebhook(
    gateway: SupportedGateway,
    payload: unknown,
    rawBody: Buffer | string,
    headers: Record<string, string | string[] | undefined>,
  ): Promise<{ processed: boolean }> {
    const adapter = this.gatewayRouter.resolveByGateway(gateway);
    const event = adapter.verifyAndParseWebhook(rawBody, headers, payload);

    const transaction = await this.prisma.transaction.findUnique({
      where: { momo_reference: event.reference },
      select: {
        id: true,
        type: true,
        amount: true,
        status: true,
        created_by: true,
      },
    });

    if (!transaction) {
      if (event.internalStatus === 'CONFIRMED') {
        this.logger.warn(
          `[PHANTOM] Référence ${event.reference} confirmée par ${gateway} sans transaction locale`,
        );
      }
      return { processed: false };
    }

    if (transaction.status !== 'PENDING') {
      await this.prisma.transaction.update({
        where: { id: transaction.id },
        data: {
          provider_transaction_id: event.providerTransactionId ?? undefined,
          provider_status: event.providerStatus,
          provider_payload: this.asJson(event.payload),
          webhook_received_at: new Date(),
          signature_verified: true,
        },
      });
      return { processed: true };
    }

    if (event.internalStatus === 'CONFIRMED') {
      await this.prisma.$transaction(async (tx) => {
        await tx.transaction.update({
          where: { id: transaction.id },
          data: {
            status: 'CONFIRMED',
            provider_transaction_id: event.providerTransactionId ?? undefined,
            provider_status: event.providerStatus,
            provider_payload: this.asJson(event.payload),
            confirmed_at: new Date(),
            webhook_received_at: new Date(),
            signature_verified: true,
          },
        });

        if (transaction.type === 'INVESTOR_DEPOSIT') {
          await tx.investor.update({
            where: { id: transaction.created_by },
            data: {
              wallet_balance: { increment: Number(transaction.amount) },
            },
          });
        }

        if (transaction.type === 'INVESTOR_DEPOSIT') {
          await this.walletService.updateEscrowOnDeposit(
            Number(transaction.amount),
          );
        }
      });

      await this.sendTransactionStatusNotifications(
        transaction.created_by,
        transaction.type,
        'CONFIRMED',
        Number(transaction.amount),
        gateway,
      );

      this.logger.log(
        `[WEBHOOK:${gateway}] CONFIRMED — ref: ${event.reference} — provider: ${event.providerTransactionId ?? 'n/a'}`,
      );

      return { processed: true };
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.transaction.update({
        where: { id: transaction.id },
        data: {
          status: 'FAILED',
          provider_transaction_id: event.providerTransactionId ?? undefined,
          provider_status: event.providerStatus,
          provider_payload: this.asJson(event.payload),
          failure_reason:
            event.failureReason ?? 'Échec signalé par le provider',
          webhook_received_at: new Date(),
          signature_verified: true,
        },
      });

      if (transaction.type === 'INVESTOR_WITHDRAWAL') {
        await tx.investor.update({
          where: { id: transaction.created_by },
          data: {
            wallet_balance: { increment: Number(transaction.amount) },
          },
        });
      }
    });

    await this.sendTransactionStatusNotifications(
      transaction.created_by,
      transaction.type,
      'FAILED',
      Number(transaction.amount),
      gateway,
      event.failureReason,
    );

    this.logger.warn(
      `[WEBHOOK:${gateway}] FAILED — ref: ${event.reference} — raison: ${event.failureReason ?? 'inconnue'}`,
    );

    return { processed: true };
  }

  async getUnreconciled(
    page: number,
    limit: number,
  ): Promise<PaginatedTransactionsResponse> {
    await this.detectAndFlagPhantoms();

    const where = {
      is_reconciled: false,
      status: { in: ['CONFIRMED', 'PHANTOM_DETECTED'] as transaction_status[] },
    };

    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where,
        select: TX_SELECT,
        orderBy: { initiated_at: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({ where }),
    ]);

    return {
      items: transactions.map((tx) => toTransactionResponse(tx)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async reconcileTransaction(
    adminId: string,
    transactionId: string,
  ): Promise<TransactionResponse> {
    const admin = await this.prisma.admin.findUnique({
      where: { id: adminId },
      select: { id: true },
    });

    if (!admin) {
      throw new ForbiddenException('Accès réservé aux administrateurs');
    }

    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
      select: { id: true, is_reconciled: true, status: true },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction introuvable');
    }

    if (transaction.is_reconciled) {
      throw new BadRequestException('Cette transaction est déjà réconciliée');
    }

    if (!['CONFIRMED', 'PHANTOM_DETECTED'].includes(transaction.status)) {
      throw new BadRequestException(
        `Seules les transactions CONFIRMED ou PHANTOM_DETECTED peuvent être réconciliées (statut : ${transaction.status})`,
      );
    }

    const updated = await this.prisma.transaction.update({
      where: { id: transactionId },
      data: {
        is_reconciled: true,
        reconciled_at: new Date(),
        status: 'RECONCILED',
      },
      select: TX_SELECT,
    });

    return toTransactionResponse(updated);
  }

  private async assertInvestorUser(
    userId: string,
    includeWallet = false,
  ): Promise<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phone: string | null;
    wallet_balance?: { toString(): string };
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        phone: true,
      },
    });

    const investor = includeWallet
      ? await this.prisma.investor.findUnique({
          where: { id: userId },
          select: { id: true, wallet_balance: true },
        })
      : await this.prisma.investor.findUnique({
          where: { id: userId },
          select: { id: true },
        });

    if (!investor || !user) {
      throw new ForbiddenException(
        'Seuls les investisseurs peuvent effectuer cette action',
      );
    }

    return {
      ...user,
      ...(includeWallet && 'wallet_balance' in investor
        ? { wallet_balance: investor.wallet_balance as { toString(): string } }
        : {}),
    };
  }

  private buildGatewayContext(
    reference: string,
    amount: number,
    momoProvider: GatewayTransactionContext['momoProvider'],
    phone: string,
    user: {
      firstName: string;
      lastName: string;
      email: string;
      phone: string | null;
    },
    description: string,
    gateway: payment_gateway,
  ): GatewayTransactionContext {
    const baseUrl =
      this.config.get<string>('BASE_URL') ?? 'http://localhost:3000';
    const frontendUrl =
      this.config.get<string>('FRONTEND_URL') ?? 'http://localhost:8081';
    const returnUrl =
      this.config.get<string>('PAYMENT_RETURN_URL') ??
      `${frontendUrl}/wallet?status=success`;
    const failureUrl =
      this.config.get<string>('PAYMENT_FAILURE_URL') ??
      `${frontendUrl}/wallet?status=failed`;

    return {
      reference,
      amount,
      momoProvider,
      callbackUrl: `${baseUrl}/api/v1/transactions/webhook/${gateway.toLowerCase()}`,
      returnUrl,
      failureUrl,
      description,
      customer: {
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: phone || user.phone || '',
        country: 'BJ',
      },
    };
  }

  private async sendTransactionStatusNotifications(
    userId: string,
    type: string,
    status: 'CONFIRMED' | 'FAILED',
    amount: number,
    gateway: payment_gateway,
    failureReason?: string | null,
  ): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { phone: true, firstName: true, email: true },
    });

    if (!user) return;

    if (status === 'CONFIRMED') {
      await this.notifications.notifyPaymentConfirmed(
        user,
        type === 'INVESTOR_DEPOSIT' ? 'deposit' : 'withdrawal',
        amount,
        gateway,
      );
      return;
    }

    await this.notifications.notifyPaymentFailed(
      user,
      type === 'INVESTOR_DEPOSIT' ? 'deposit' : 'withdrawal',
      amount,
      gateway,
      failureReason ?? undefined,
    );
  }

  private async detectAndFlagPhantoms(): Promise<void> {
    const threshold = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const stale = await this.prisma.transaction.findMany({
      where: {
        status: 'PENDING',
        initiated_at: { lt: threshold },
      },
      select: { id: true },
    });

    if (stale.length === 0) return;

    await this.prisma.transaction.updateMany({
      where: { id: { in: stale.map((tx) => tx.id) } },
      data: { status: 'PHANTOM_DETECTED' },
    });

    this.logger.warn(
      `[PHANTOM] ${stale.length} transaction(s) PENDING > 24h marquées PHANTOM_DETECTED`,
    );
  }

  private toFailureReason(error: unknown): string {
    if (error instanceof Error && error.message) {
      return error.message;
    }

    return 'Erreur provider inconnue';
  }

  private asJson(value: Record<string, unknown>): Prisma.InputJsonValue {
    return value as Prisma.InputJsonValue;
  }
}
