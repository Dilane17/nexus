'use client';

import { startTransition, useEffect, useState } from 'react';
import ProtectedRoute from '@/components/layout/ProtectedRoute';
import Card from '@/components/ui/Card';
import KycTable from '@/components/features/kyc/KycTable';
import api from '@/lib/api';
import type { ApiResponse, PaginatedResponse, User } from '@/lib/types';

export default function KycPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [error, setError] = useState<string | null>(null);

  const load = async (p: number) => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<ApiResponse<PaginatedResponse<User>>>(
        `/users/kyc/pending?page=${p}&limit=20`
      );
      setUsers(res.data.data.items);
      setTotalPages(res.data.data.totalPages);
    } catch {
      setError('Impossible de charger les dossiers KYC.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    startTransition(() => { load(page); });
  }, [page]);

  return (
    <ProtectedRoute allowedRoles={['admin', 'imf_staff']}>
      <div className="space-y-4">
        <div>
          <h1 className="text-2xl font-bold text-[#1A3A5C]">KYC en attente</h1>
          <p className="text-sm text-gray-500 mt-0.5">Dossiers soumis en attente de validation</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-[8px] p-4 text-sm text-[#991B1B]">
            {error}
          </div>
        )}

        <Card>
          <KycTable data={users} loading={loading} />

          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-4 pt-4 border-t border-gray-100">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-3 py-1.5 text-sm text-[#1A3A5C] border border-[#1A3A5C] rounded-[6px] hover:bg-[#1A3A5C]/10 disabled:opacity-40"
              >
                ← Précédent
              </button>
              <span className="text-sm text-gray-500">
                Page {page} / {totalPages}
              </span>
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
