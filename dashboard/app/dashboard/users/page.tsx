'use client';

import { startTransition, useEffect, useState } from 'react';
import ProtectedRoute from '@/components/layout/ProtectedRoute';
import Card from '@/components/ui/Card';
import Badge from '@/components/ui/Badge';
import Table, { type Column } from '@/components/ui/Table';
import api from '@/lib/api';
import type { ApiResponse, PaginatedResponse, User } from '@/lib/types';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    startTransition(() => {
      setLoading(true);
      api
        .get<ApiResponse<PaginatedResponse<User>>>(`/admin/users?page=${page}&limit=20`)
        .then((res) => {
          setUsers(res.data.data.items);
          setTotalPages(res.data.data.totalPages);
        })
        .catch(() => setError('Impossible de charger les utilisateurs.'))
        .finally(() => setLoading(false));
    });
  }, [page]);

  const columns: Column[] = [
    {
      key: 'name',
      header: 'Nom',
      render: (row) => `${row.firstName} ${row.lastName}`,
    },
    { key: 'email', header: 'Email' },
    {
      key: 'phone',
      header: 'Téléphone',
      render: (row) => (row.phone as string | null) ?? '—',
    },
    {
      key: 'role',
      header: 'Rôle',
      render: (row) => (
        <span className="text-xs font-mono bg-gray-100 px-2 py-0.5 rounded">{String(row.role)}</span>
      ),
    },
    {
      key: 'kycStatus',
      header: 'KYC',
      render: (row) => <Badge status={String(row.kycStatus)} />,
    },
    {
      key: 'status',
      header: 'Statut',
      render: (row) => <Badge status={String(row.status)} />,
    },
  ];

  return (
    <ProtectedRoute allowedRoles={['admin']}>
      <div className="space-y-4">
        <div>
          <h1 className="text-2xl font-bold text-[#1A3A5C]">Utilisateurs</h1>
          <p className="text-sm text-gray-500 mt-0.5">Liste de tous les membres de la plateforme</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-[8px] p-3 text-sm text-[#991B1B]">
            {error}
          </div>
        )}

        <Card>
          <Table
            columns={columns}
            data={users as unknown as Record<string, unknown>[]}
            loading={loading}
            emptyMessage="Aucun utilisateur trouvé"
          />
          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-4 pt-4 border-t border-gray-100">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-3 py-1.5 text-sm text-[#1A3A5C] border border-[#1A3A5C] rounded-[6px] hover:bg-[#1A3A5C]/10 disabled:opacity-40"
              >
                ← Précédent
              </button>
              <span className="text-sm text-gray-500">Page {page} / {totalPages}</span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-3 py-1.5 text-sm text-[#1A3A5C] border border-[#1A3A5C] rounded-[6px] hover:bg-[#1A3A5C]/10 disabled:opacity-40"
              >
                Suivant →
              </button>
            </div>
          )}
        </Card>
      </div>
    </ProtectedRoute>
  );
}
