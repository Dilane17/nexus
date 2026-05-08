import type { Prisma } from '@generated/prisma';
type Decimal = Prisma.Decimal;

export interface TontineGroupResponse {
  id: string;
  name: string;
  leaderUserId: string;
  leaderPhone: string;
  memberCount: number;
  monthlyContribution: Decimal;
  completedCycles: number;
  status: string;
}

export interface TontineMemberInfo {
  id: string;
  borrowerId: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  joinedAt: Date;
}

export interface TontineCycleInfo {
  id: string;
  cycleNumber: number;
  startDate: Date;
  endDate: Date;
  totalCollected: Decimal;
  isComplete: boolean;
  beneficiaryId: string;
  membersPaid: number;
  membersDefaulted: number;
}

export interface TontineGroupDetailResponse extends TontineGroupResponse {
  members: TontineMemberInfo[];
  cycles: TontineCycleInfo[];
}

export interface PaginatedTontineGroupsResponse {
  items: TontineGroupResponse[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface TontineScoreResponse {
  borrowerId: string;
  tontineScore: number;
  hasTontineHistory: boolean;
  cyclesParticipated: number;
  averagePaymentRate: number;
}
