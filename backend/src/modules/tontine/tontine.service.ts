import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '@shared/prisma/prisma.service';
import type { tontine_status } from '@generated/prisma';
import type { CreateTontineGroupDto } from './dto/create-tontine-group.dto';
import type { CreateCycleDto } from './dto/create-cycle.dto';
import type { CompleteCycleDto } from './dto/complete-cycle.dto';
import type {
  TontineGroupResponse,
  TontineGroupDetailResponse,
  PaginatedTontineGroupsResponse,
  TontineScoreResponse,
  TontineCycleInfo,
} from './dto/tontine-response.dto';

// ── Helpers ───────────────────────────────────────────────────────────────────

function toGroupResponse(g: {
  id: string;
  name: string;
  leader_user_id: string;
  leader_phone: string;
  member_count: number;
  monthly_contribution: { toString(): string };
  completed_cycles: number;
  status: string;
}): TontineGroupResponse {
  return {
    id: g.id,
    name: g.name,
    leaderUserId: g.leader_user_id,
    leaderPhone: g.leader_phone,
    memberCount: g.member_count,
    monthlyContribution: g.monthly_contribution as TontineGroupResponse['monthlyContribution'],
    completedCycles: g.completed_cycles,
    status: g.status,
  };
}

function toCycleInfo(c: {
  id: string;
  cycle_number: number;
  start_date: Date;
  end_date: Date;
  total_collected: { toString(): string };
  is_complete: boolean;
  beneficiary_id: string;
  members_paid: number;
  members_defaulted: number;
}): TontineCycleInfo {
  return {
    id: c.id,
    cycleNumber: c.cycle_number,
    startDate: c.start_date,
    endDate: c.end_date,
    totalCollected: c.total_collected as TontineCycleInfo['totalCollected'],
    isComplete: c.is_complete,
    beneficiaryId: c.beneficiary_id,
    membersPaid: c.members_paid,
    membersDefaulted: c.members_defaulted,
  };
}

@Injectable()
export class TontineService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Créer un groupe ──────────────────────────────────────────────────────────

  async createGroup(
    userId: string,
    dto: CreateTontineGroupDto,
  ): Promise<TontineGroupResponse> {
    const borrower = await this.prisma.borrower.findUnique({
      where: { id: userId },
      select: { id: true, mobile_money_number: true },
    });

    if (!borrower) {
      throw new ForbiddenException(
        'Seuls les emprunteurs peuvent créer un groupe tontine',
      );
    }

    const activeGroup = await this.prisma.tontineGroup.findFirst({
      where: {
        leader_user_id: userId,
        status: { in: ['PENDING', 'ACTIVE'] },
      },
      select: { id: true },
    });

    if (activeGroup) {
      throw new BadRequestException(
        'Vous êtes déjà leader d\'un groupe actif. Clôturez-le avant d\'en créer un nouveau.',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { phone: true },
    });

    const group = await this.prisma.$transaction(async (tx) => {
      const created = await tx.tontineGroup.create({
        data: {
          name: dto.name,
          leader_user_id: userId,
          leader_phone: user?.phone ?? borrower.mobile_money_number,
          monthly_contribution: dto.monthly_contribution,
          member_count: 1,
          status: 'PENDING',
        },
        select: {
          id: true,
          name: true,
          leader_user_id: true,
          leader_phone: true,
          member_count: true,
          monthly_contribution: true,
          completed_cycles: true,
          status: true,
        },
      });

      // Le leader est automatiquement le premier membre
      await tx.tontineMember.create({
        data: {
          group_id: created.id,
          borrower_id: userId,
        },
      });

      return created;
    });

    return toGroupResponse(group);
  }

  // ── Lister les groupes ───────────────────────────────────────────────────────

  async listGroups(
    page: number,
    limit: number,
    status?: string,
  ): Promise<PaginatedTontineGroupsResponse> {
    const where = status ? { status: status as tontine_status } : {};
    const skip = (page - 1) * limit;

    const [groups, total] = await Promise.all([
      this.prisma.tontineGroup.findMany({
        where,
        select: {
          id: true,
          name: true,
          leader_user_id: true,
          leader_phone: true,
          member_count: true,
          monthly_contribution: true,
          completed_cycles: true,
          status: true,
        },
        orderBy: { member_count: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.tontineGroup.count({ where }),
    ]);

    return {
      items: groups.map(toGroupResponse),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ── Détail d'un groupe ───────────────────────────────────────────────────────

  async getGroupById(groupId: string): Promise<TontineGroupDetailResponse> {
    const group = await this.prisma.tontineGroup.findUnique({
      where: { id: groupId },
      select: {
        id: true,
        name: true,
        leader_user_id: true,
        leader_phone: true,
        member_count: true,
        monthly_contribution: true,
        completed_cycles: true,
        status: true,
        tontine_members: {
          select: {
            id: true,
            borrower_id: true,
            joined_at: true,
            borrowers: {
              select: {
                user: { select: { firstName: true, lastName: true, phone: true } },
              },
            },
          },
          orderBy: { joined_at: 'asc' },
        },
        tontine_cycles: {
          select: {
            id: true,
            cycle_number: true,
            start_date: true,
            end_date: true,
            total_collected: true,
            is_complete: true,
            beneficiary_id: true,
            members_paid: true,
            members_defaulted: true,
          },
          orderBy: { cycle_number: 'asc' },
        },
      },
    });

    if (!group) {
      throw new NotFoundException('Groupe tontine introuvable');
    }

    return {
      ...toGroupResponse(group),
      members: group.tontine_members.map((m) => ({
        id: m.id,
        borrowerId: m.borrower_id,
        firstName: m.borrowers.user.firstName,
        lastName: m.borrowers.user.lastName,
        phone: m.borrowers.user.phone,
        joinedAt: m.joined_at,
      })),
      cycles: group.tontine_cycles.map(toCycleInfo),
    };
  }

  // ── Rejoindre un groupe ──────────────────────────────────────────────────────

  async joinGroup(
    userId: string,
    groupId: string,
  ): Promise<TontineGroupResponse> {
    const borrower = await this.prisma.borrower.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!borrower) {
      throw new ForbiddenException(
        'Seuls les emprunteurs peuvent rejoindre un groupe tontine',
      );
    }

    const group = await this.prisma.tontineGroup.findUnique({
      where: { id: groupId },
      select: {
        id: true,
        name: true,
        leader_user_id: true,
        leader_phone: true,
        member_count: true,
        monthly_contribution: true,
        completed_cycles: true,
        status: true,
      },
    });

    if (!group) {
      throw new NotFoundException('Groupe tontine introuvable');
    }

    if (!['PENDING', 'ACTIVE'].includes(group.status)) {
      throw new BadRequestException(
        `Impossible de rejoindre un groupe en statut "${group.status}"`,
      );
    }

    const alreadyMember = await this.prisma.tontineMember.findUnique({
      where: { group_id_borrower_id: { group_id: groupId, borrower_id: userId } },
      select: { id: true },
    });

    if (alreadyMember) {
      throw new BadRequestException('Vous êtes déjà membre de ce groupe');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.tontineMember.create({
        data: { group_id: groupId, borrower_id: userId },
      });

      return tx.tontineGroup.update({
        where: { id: groupId },
        data: { member_count: { increment: 1 } },
        select: {
          id: true,
          name: true,
          leader_user_id: true,
          leader_phone: true,
          member_count: true,
          monthly_contribution: true,
          completed_cycles: true,
          status: true,
        },
      });
    });

    return toGroupResponse(updated);
  }

  // ── Démarrer un cycle ────────────────────────────────────────────────────────

  async createCycle(
    userId: string,
    groupId: string,
    dto: CreateCycleDto,
  ): Promise<TontineGroupDetailResponse> {
    const group = await this.prisma.tontineGroup.findUnique({
      where: { id: groupId },
      select: {
        id: true,
        leader_user_id: true,
        status: true,
        tontine_members: { select: { borrower_id: true } },
      },
    });

    if (!group) {
      throw new NotFoundException('Groupe tontine introuvable');
    }

    if (group.leader_user_id !== userId) {
      throw new ForbiddenException(
        'Seul le leader du groupe peut démarrer un cycle',
      );
    }

    if (group.status === 'COMPLETED' || group.status === 'SUSPENDED') {
      throw new BadRequestException(
        `Impossible de créer un cycle — groupe en statut "${group.status}"`,
      );
    }

    const isMember = group.tontine_members.some(
      (m) => m.borrower_id === dto.beneficiary_id,
    );
    if (!isMember) {
      throw new BadRequestException(
        'Le bénéficiaire doit être membre du groupe',
      );
    }

    const existingCycle = await this.prisma.tontineCycle.findUnique({
      where: { group_id_cycle_number: { group_id: groupId, cycle_number: dto.cycle_number } },
      select: { id: true },
    });

    if (existingCycle) {
      throw new BadRequestException(
        `Le cycle numéro ${dto.cycle_number} existe déjà pour ce groupe`,
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.tontineCycle.create({
        data: {
          group_id: groupId,
          cycle_number: dto.cycle_number,
          start_date: new Date(dto.start_date),
          end_date: new Date(dto.end_date),
          beneficiary_id: dto.beneficiary_id,
        },
      });

      // Activer le groupe si encore en PENDING
      if (group.status === 'PENDING') {
        await tx.tontineGroup.update({
          where: { id: groupId },
          data: { status: 'ACTIVE' },
        });
      }
    });

    return this.getGroupById(groupId);
  }

  // ── Clôturer un cycle ────────────────────────────────────────────────────────

  async completeCycle(
    userId: string,
    cycleId: string,
    dto: CompleteCycleDto,
  ): Promise<TontineGroupDetailResponse> {
    const cycle = await this.prisma.tontineCycle.findUnique({
      where: { id: cycleId },
      select: {
        id: true,
        is_complete: true,
        group_id: true,
        tontine_groups: { select: { leader_user_id: true } },
      },
    });

    if (!cycle) {
      throw new NotFoundException('Cycle introuvable');
    }

    if (cycle.tontine_groups.leader_user_id !== userId) {
      throw new ForbiddenException(
        'Seul le leader du groupe peut clôturer un cycle',
      );
    }

    if (cycle.is_complete) {
      throw new BadRequestException('Ce cycle est déjà clôturé');
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.tontineCycle.update({
        where: { id: cycleId },
        data: {
          is_complete: true,
          members_paid: dto.members_paid,
          members_defaulted: dto.members_defaulted,
          total_collected: dto.total_collected,
        },
      });

      await tx.tontineGroup.update({
        where: { id: cycle.group_id },
        data: { completed_cycles: { increment: 1 } },
      });
    });

    // Recalculer le score tontine du leader
    await this.recalculateTontineScore(userId);

    return this.getGroupById(cycle.group_id);
  }

  // ── Score tontine ────────────────────────────────────────────────────────────

  async getMyScore(userId: string): Promise<TontineScoreResponse> {
    const borrower = await this.prisma.borrower.findUnique({
      where: { id: userId },
      select: { id: true, tontine_score: true, has_tontine_history: true },
    });

    if (!borrower) {
      throw new ForbiddenException('Accès réservé aux emprunteurs');
    }

    const { cyclesParticipated, averagePaymentRate } =
      await this.computeScoreMetrics(userId);

    return {
      borrowerId: userId,
      tontineScore: Number(borrower.tontine_score),
      hasTontineHistory: borrower.has_tontine_history,
      cyclesParticipated,
      averagePaymentRate,
    };
  }

  // ── Helpers privés ───────────────────────────────────────────────────────────

  private async recalculateTontineScore(borrowerId: string): Promise<void> {
    const { cyclesParticipated, averagePaymentRate } =
      await this.computeScoreMetrics(borrowerId);

    const newScore = Math.min(100, Math.max(0, averagePaymentRate));

    await this.prisma.borrower.update({
      where: { id: borrowerId },
      data: {
        tontine_score: newScore,
        has_tontine_history: cyclesParticipated > 0,
      },
    });
  }

  private async computeScoreMetrics(borrowerId: string): Promise<{
    cyclesParticipated: number;
    averagePaymentRate: number;
  }> {
    // Cycles des groupes que le borrower a dirigés OU dont il est membre
    const memberGroups = await this.prisma.tontineMember.findMany({
      where: { borrower_id: borrowerId },
      select: { group_id: true },
    });

    const groupIds = memberGroups.map((m) => m.group_id);

    if (groupIds.length === 0) {
      return { cyclesParticipated: 0, averagePaymentRate: 0 };
    }

    const completedCycles = await this.prisma.tontineCycle.findMany({
      where: { group_id: { in: groupIds }, is_complete: true },
      select: { members_paid: true, members_defaulted: true },
    });

    if (completedCycles.length === 0) {
      return { cyclesParticipated: 0, averagePaymentRate: 0 };
    }

    const totalPaymentRate = completedCycles.reduce((sum, c) => {
      const total = c.members_paid + c.members_defaulted;
      return sum + (total > 0 ? (c.members_paid / total) * 100 : 0);
    }, 0);

    return {
      cyclesParticipated: completedCycles.length,
      averagePaymentRate: totalPaymentRate / completedCycles.length,
    };
  }
}
