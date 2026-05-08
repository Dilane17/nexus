import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@shared/prisma/prisma.service';
import type {
  AgentProfileResponse,
  AgentClientItem,
  AgentCommissionItem,
  PaginatedAgentCommissionsResponse,
  AgentDashboardResponse,
} from './dto/agent-response.dto';

@Injectable()
export class AgentsService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Profil ───────────────────────────────────────────────────────────────────

  async getProfile(userId: string): Promise<AgentProfileResponse> {
    const agent = await this.prisma.agent.findUnique({
      where: { id: userId },
      select: {
        id: true,
        zone: true,
        agency_code: true,
        commission_rate: true,
        clients_assisted: true,
        user: {
          select: {
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
            status: true,
            created_at: true,
          },
        },
      },
    });

    if (!agent) {
      throw new NotFoundException('Profil agent introuvable');
    }

    return {
      id: agent.id,
      firstName: agent.user.firstName,
      lastName: agent.user.lastName,
      email: agent.user.email,
      phone: agent.user.phone,
      zone: agent.zone,
      agencyCode: agent.agency_code,
      commissionRate: agent.commission_rate,
      clientsAssisted: agent.clients_assisted,
      status: agent.user.status,
      createdAt: agent.user.created_at,
    };
  }

  // ── Clients de la zone ───────────────────────────────────────────────────────

  async getClientsByZone(userId: string): Promise<AgentClientItem[]> {
    const agent = await this.prisma.agent.findUnique({
      where: { id: userId },
      select: { zone: true },
    });

    if (!agent) {
      throw new NotFoundException('Agent introuvable');
    }

    const users = await this.prisma.user.findMany({
      where: {
        city: agent.zone,
        admin: null,
        imfStaff: null,
        agent: null,
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        phone: true,
        city: true,
        district: true,
        kyc_status: true,
        status: true,
        created_at: true,
      },
      orderBy: { created_at: 'desc' },
    });

    return users.map((u) => ({
      id: u.id,
      firstName: u.firstName,
      lastName: u.lastName,
      email: u.email,
      phone: u.phone,
      city: u.city,
      district: u.district,
      kycStatus: u.kyc_status,
      status: u.status,
      createdAt: u.created_at,
    }));
  }

  // ── Historique des commissions ───────────────────────────────────────────────

  async getCommissionHistory(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedAgentCommissionsResponse> {
    const agent = await this.prisma.agent.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!agent) {
      throw new NotFoundException('Agent introuvable');
    }

    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where: {
          type: 'AGENT_COMMISSION',
          created_by: userId,
        },
        select: {
          id: true,
          amount: true,
          status: true,
          initiated_at: true,
          confirmed_at: true,
          momo_reference: true,
        },
        orderBy: { initiated_at: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({
        where: {
          type: 'AGENT_COMMISSION',
          created_by: userId,
        },
      }),
    ]);

    return {
      items: transactions.map((t) => ({
        id: t.id,
        amount: t.amount.valueOf() as unknown as AgentCommissionItem['amount'],
        status: t.status,
        initiatedAt: t.initiated_at,
        confirmedAt: t.confirmed_at,
        reference: t.momo_reference,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Dashboard ────────────────────────────────────────────────────────────────

  async getDashboardStats(userId: string): Promise<AgentDashboardResponse> {
    const agent = await this.prisma.agent.findUnique({
      where: { id: userId },
      select: { clients_assisted: true },
    });

    if (!agent) {
      throw new NotFoundException('Agent introuvable');
    }

    const [pendingAgg, confirmedAgg, recentCommissions] = await Promise.all([
      this.prisma.transaction.aggregate({
        where: {
          type: 'AGENT_COMMISSION',
          created_by: userId,
          status: 'PENDING',
        },
        _sum: { amount: true },
      }),
      this.prisma.transaction.aggregate({
        where: {
          type: 'AGENT_COMMISSION',
          created_by: userId,
          status: 'CONFIRMED',
        },
        _sum: { amount: true },
      }),
      this.prisma.transaction.findMany({
        where: {
          type: 'AGENT_COMMISSION',
          created_by: userId,
        },
        select: {
          id: true,
          amount: true,
          status: true,
          initiated_at: true,
          confirmed_at: true,
          momo_reference: true,
        },
        orderBy: { initiated_at: 'desc' },
        take: 10,
      }),
    ]);

    const pendingAmount = pendingAgg._sum?.amount?.valueOf() ?? '0';
    const confirmedAmount = confirmedAgg._sum?.amount?.valueOf() ?? '0';
    const totalAmount = (Number(pendingAmount) + Number(confirmedAmount)) as unknown as AgentDashboardResponse['totalCommissions'];

    return {
      clientsAssisted: agent.clients_assisted,
      totalCommissions: totalAmount,
      pendingCommissions: (pendingAgg._sum?.amount?.valueOf() ?? 0) as unknown as AgentDashboardResponse['pendingCommissions'],
      confirmedCommissions: (confirmedAgg._sum?.amount?.valueOf() ?? 0) as unknown as AgentDashboardResponse['confirmedCommissions'],
      recentCommissions: recentCommissions.map((t) => ({
        id: t.id,
        amount: t.amount.valueOf() as unknown as AgentCommissionItem['amount'],
        status: t.status,
        initiatedAt: t.initiated_at,
        confirmedAt: t.confirmed_at,
        reference: t.momo_reference,
      })),
    };
  }
}
