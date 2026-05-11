'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Users, Banknote, FileCheck, TrendingUp } from 'lucide-react';
import StatCard from '@/components/ui/StatCard';
import Card from '@/components/ui/Card';
import Badge from '@/components/ui/Badge';
import Table, { type Column } from '@/components/ui/Table';
import api from '@/lib/api';
import type { ApiResponse, DashboardStats, Loan } from '@/lib/types';

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recentLoans, setRecentLoans] = useState<Loan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      try {
        const [statsRes, loansRes] = await Promise.all([
          api.get<ApiResponse<DashboardStats>>('/admin/dashboard'),
          api.get<ApiResponse<{ items: Loan[] }>>('/loans?limit=5&page=1'),
        ]);
        setStats(statsRes.data.data);
        setRecentLoans(loansRes.data.data?.items ?? []);
      } catch {
        setError('Impossible de charger les données du tableau de bord.');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-[8px] p-4 text-sm text-[#991B1B]">
        {error}
      </div>
    );
  }

  const loanColumns: Column[] = [
    {
      key: 'id',
      header: 'ID',
      render: (row) => <span className="font-mono text-xs">{String(row.id).slice(0, 8)}…</span>,
    },
    {
      key: 'amount',
      header: 'Montant',
      render: (row) => `${Number(row.amount).toLocaleString('fr-FR')} FCFA`,
    },
    {
      key: 'durationMonths',
      header: 'Durée',
      render: (row) => `${row.durationMonths} mois`,
    },
    {
      key: 'hybridScore',
      header: 'Score',
      render: (row) => (row.hybridScore != null ? Number(row.hybridScore).toFixed(0) : '—'),
    },
    {
      key: 'status',
      header: 'Statut',
      render: (row) => <Badge status={String(row.status)} />,
    },
    {
      key: 'actions',
      header: '',
      render: (row) => (
        <Link href={`/dashboard/loans/${row.id}`} className="text-[#1A3A5C] text-xs hover:underline font-medium">
          Voir →
        </Link>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-[#1A3A5C]">Tableau de bord</h1>
        <p className="text-sm text-gray-500 mt-0.5">Vue d&apos;ensemble de la plateforme</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <StatCard
          label="Utilisateurs actifs"
          value={loading ? '…' : (stats?.users.total ?? 0)}
          icon={Users}
          accentColor="#1A3A5C"
        />
        <StatCard
          label="Prêts en cours (ACTIVE)"
          value={loading ? '…' : (stats?.loans.activeCount ?? 0)}
          icon={Banknote}
          accentColor="#C8922A"
        />
        <StatCard
          label="KYC en attente"
          value={loading ? '…' : (stats?.users.kycPending ?? 0)}
          icon={FileCheck}
          accentColor="#C8922A"
        />
        <StatCard
          label="NPL Rate"
          value={loading ? '…' : `${((stats?.loans.nplRatio ?? 0) * 100).toFixed(1)}%`}
          icon={TrendingUp}
          accentColor="#991B1B"
        />
      </div>

      <Card title="5 derniers prêts">
        <Table
          columns={loanColumns}
          data={recentLoans as unknown as Record<string, unknown>[]}
          loading={loading}
          emptyMessage="Aucun prêt trouvé"
        />
      </Card>
    </div>
  );
}
