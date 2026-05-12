'use client';

import { startTransition, useEffect, useState } from 'react';
import ProtectedRoute from '@/components/layout/ProtectedRoute';
import Card from '@/components/ui/Card';
import LoansTable from '@/components/features/loans/LoansTable';
import LoanValidationModal from '@/components/features/loans/LoanValidationModal';
import api from '@/lib/api';
import type { ApiResponse, Loan, PaginatedResponse } from '@/lib/types';

type Tab = 'pending' | 'all';

export default function LoansPage() {
  const [activeTab, setActiveTab] = useState<Tab>('pending');
  const [pendingLoans, setPendingLoans] = useState<Loan[]>([]);
  const [allLoans, setAllLoans] = useState<Loan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedLoan, setSelectedLoan] = useState<Loan | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  const loadPending = async () => {
    try {
      const res = await api.get<ApiResponse<PaginatedResponse<Loan>>>('/loans/pending-imf');
      setPendingLoans(res.data.data.items);
    } catch {
      setError('Impossible de charger les prêts en attente.');
    }
  };

  const loadAll = async () => {
    try {
      const res = await api.get<ApiResponse<PaginatedResponse<Loan>>>('/loans/all?limit=50&page=1');
      setAllLoans(res.data.data.items ?? []);
    } catch {
      setError('Impossible de charger les prêts.');
    }
  };

  useEffect(() => {
    startTransition(() => {
      setLoading(true);
      Promise.all([loadPending(), loadAll()]).finally(() => setLoading(false));
    });
  }, []);

  const handleValidate = (loan: Loan) => {
    setSelectedLoan(loan);
    setModalOpen(true);
  };

  const handleConfirmValidation = async (
    decision: 'APPROVED' | 'REJECTED',
    interestRate?: number,
    reason?: string
  ) => {
    if (!selectedLoan) return;
    await api.patch(`/loans/${selectedLoan.id}/validate`, {
      decision,
      ...(interestRate !== undefined ? { interest_rate: interestRate } : {}),
      ...(reason ? { reason } : {}),
    });
    setModalOpen(false);
    setSelectedLoan(null);
    await loadPending();
    await loadAll();
  };

  const tabs: { key: Tab; label: string }[] = [
    { key: 'pending', label: 'En attente IMF' },
    { key: 'all', label: 'Tous les prêts' },
  ];

  return (
    <ProtectedRoute allowedRoles={['admin', 'imf_staff']}>
      <div className="space-y-4">
        <div>
          <h1 className="text-2xl font-bold text-[#1A3A5C]">Prêts</h1>
          <p className="text-sm text-gray-500 mt-0.5">Gestion et validation des demandes de prêt</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-[8px] p-3 text-sm text-[#991B1B]">
            {error}
          </div>
        )}

        <div className="flex border-b border-gray-200">
          {tabs.map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setActiveTab(key)}
              className={`px-5 py-2.5 text-sm font-medium transition-colors border-b-2 -mb-px ${
                activeTab === key
                  ? 'border-[#C8922A] text-[#C8922A]'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {label}
              {key === 'pending' && pendingLoans.length > 0 && (
                <span className="ml-2 bg-[#C8922A] text-white text-xs rounded-full px-1.5 py-0.5">
                  {pendingLoans.length}
                </span>
              )}
            </button>
          ))}
        </div>

        <Card>
          {activeTab === 'pending' ? (
            <LoansTable
              data={pendingLoans}
              loading={loading}
              onValidate={handleValidate}
              showValidateButton
            />
          ) : (
            <LoansTable data={allLoans} loading={loading} />
          )}
        </Card>

        <LoanValidationModal
          open={modalOpen}
          loan={selectedLoan}
          onClose={() => { setModalOpen(false); setSelectedLoan(null); }}
          onConfirm={handleConfirmValidation}
        />
      </div>
    </ProtectedRoute>
  );
}
