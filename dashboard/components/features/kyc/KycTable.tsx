'use client';

import Link from 'next/link';
import Table, { type Column } from '@/components/ui/Table';
import type { User } from '@/lib/types';

interface KycTableProps {
  data: User[];
  loading: boolean;
}

export default function KycTable({ data, loading }: KycTableProps) {
  const columns: Column[] = [
    {
      key: 'name',
      header: 'Nom',
      render: (row) => {
        const u = row as unknown as User;
        return `${u.firstName} ${u.lastName}`;
      },
    },
    { key: 'email', header: 'Email' },
    {
      key: 'phone',
      header: 'Téléphone',
      render: (row) => ((row as unknown as User).phone ?? '—'),
    },
    {
      key: 'kycSubmittedAt',
      header: 'Date soumission',
      render: (row) => {
        const date = (row as unknown as User).kycSubmittedAt;
        return date ? new Date(date).toLocaleDateString('fr-FR') : '—';
      },
    },
    {
      key: 'actions',
      header: '',
      render: (row) => (
        <Link
          href={`/dashboard/kyc/${(row as unknown as User).id}`}
          className="inline-flex items-center px-3 py-1.5 bg-[#1A3A5C] text-white text-xs font-medium rounded-[6px] hover:bg-[#142d47] transition-colors"
        >
          Voir le dossier
        </Link>
      ),
    },
  ];

  return (
    <Table
      columns={columns}
      data={data as unknown as Record<string, unknown>[]}
      loading={loading}
      emptyMessage="Aucun dossier KYC en attente"
    />
  );
}
