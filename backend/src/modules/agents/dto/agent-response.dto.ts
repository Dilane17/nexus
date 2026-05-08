import type { Prisma } from '@generated/prisma';

type Decimal = Prisma.Decimal;

// ── Profil Agent ───────────────────────────────────────────────────────────────

export interface AgentProfileResponse {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  zone: string;
  agencyCode: string;
  commissionRate: Decimal;
  clientsAssisted: number;
  status: string;
  createdAt: Date;
}

// ── Client dans la zone ────────────────────────────────────────────────────────

export interface AgentClientItem {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  city: string | null;
  district: string | null;
  kycStatus: string;
  status: string;
  createdAt: Date;
}

// ── Commission ─────────────────────────────────────────────────────────────────

export interface AgentCommissionItem {
  id: string;
  amount: Decimal;
  status: string;
  initiatedAt: Date;
  confirmedAt: Date | null;
  reference: string | null;
}

export interface PaginatedAgentCommissionsResponse {
  items: AgentCommissionItem[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// ── Dashboard Agent ────────────────────────────────────────────────────────────

export interface AgentDashboardResponse {
  clientsAssisted: number;
  totalCommissions: Decimal;
  pendingCommissions: Decimal;
  confirmedCommissions: Decimal;
  recentCommissions: AgentCommissionItem[];
}
