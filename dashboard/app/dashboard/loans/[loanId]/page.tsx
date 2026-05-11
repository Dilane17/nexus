'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import ProtectedRoute from '@/components/layout/ProtectedRoute';
import Card from '@/components/ui/Card';
import Badge from '@/components/ui/Badge';
import Button from '@/components/ui/Button';
import LoanValidationModal from '@/components/features/loans/LoanValidationModal';
import api from '@/lib/api';
import type { ApiResponse, Loan } from '@/lib/types';

export default function LoanDetailPage() {
  const { loanId } = useParams<{ loanId: string }>();
  const router = useRouter();
  const [loan, setLoan] = useState<Loan | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  useEffect(() => {
    api
      .get<ApiResponse<Loan>>(`/loans/${loanId}`)
      .then((res) => setLoan(res.data.data))
      .catch(() => setError('Impossible de charger les détails du prêt.'))
      .finally(() => setLoading(false));
  }, [loanId]);

  const handleConfirmValidation = async (
    decision: 'APPROVED' | 'REJECTED',
    interestRate?: number,
    reason?: string
  ) => {
    await api.patch(`/loans/${loanId}/validate`, {
      decision,
      ...(interestRate !== undefined ? { interest_rate: interestRate } : {}),
      ...(reason ? { reason } : {}),
    });
    setModalOpen(false);
    router.push('/dashboard/loans');
  };

  if (loading) {
    return (
      <div className="space-y-4 max-w-4xl">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-32 bg-white rounded-[8px] animate-pulse" />
        ))}
      </div>
    );
  }

  if (error || !loan) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-[8px] p-4 text-sm text-[#991B1B]">
        {error ?? 'Prêt introuvable.'}
      </div>
    );
  }

  const momoWeight = 40;
  const tontineWeight = 35;
  const imfWeight = 25;

  return (
    <ProtectedRoute allowedRoles={['admin', 'imf_staff']}>
      <div className="space-y-6 max-w-4xl">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-[#1A3A5C]">Détail du prêt</h1>
            <div className="flex items-center gap-2 mt-1">
              <Badge status={loan.status} />
              <span className="text-sm font-mono text-gray-400">{loan.id}</span>
            </div>
          </div>
          <button onClick={() => router.back()} className="text-sm text-gray-500 hover:text-[#1A3A5C]">
            ← Retour
          </button>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-[8px] p-3 text-sm text-[#991B1B]">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card title="Informations du prêt">
            <dl className="space-y-3 text-sm">
              {[
                ['Montant', `${Number(loan.amount).toLocaleString('fr-FR')} FCFA`],
                ['Taux d\'intérêt', loan.interestRate ? `${Number(loan.interestRate).toFixed(2)}%` : '—'],
                ['Durée', `${loan.durationMonths} mois`],
                ['Mensualité', loan.monthlyInstallment ? `${Number(loan.monthlyInstallment).toLocaleString('fr-FR')} FCFA` : '—'],
                ['Objet', loan.purpose],
                ['Créé le', new Date(loan.createdAt).toLocaleDateString('fr-FR')],
                ['Validé IMF', loan.validatedByImf ? 'Oui' : 'Non'],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between gap-4">
                  <dt className="text-gray-500 shrink-0">{label}</dt>
                  <dd className="font-medium text-gray-800 text-right">{value}</dd>
                </div>
              ))}
            </dl>
          </Card>

          <Card title="Score hybride de l'emprunteur">
            {loan.hybridScore != null ? (
              <div className="space-y-4">
                <div className="text-center">
                  <span className="text-4xl font-bold text-[#1A3A5C]">{loan.hybridScore.toFixed(0)}</span>
                  <span className="text-gray-400 text-sm ml-1">/ 100</span>
                </div>
                <div className="space-y-3">
                  {[
                    { label: 'Mobile Money (MoMo)', weight: momoWeight, color: '#1A3A5C' },
                    { label: 'Tontine Bridge', weight: tontineWeight, color: '#C8922A' },
                    { label: 'Historique IMF', weight: imfWeight, color: '#166534' },
                  ].map(({ label, weight, color }) => (
                    <div key={label}>
                      <div className="flex justify-between text-xs mb-1">
                        <span className="text-gray-600">{label}</span>
                        <span className="font-medium" style={{ color }}>{weight}%</span>
                      </div>
                      <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                        <div
                          className="h-full rounded-full"
                          style={{ width: `${weight}%`, backgroundColor: color }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-400 text-center py-4">Score non calculé</p>
            )}
          </Card>
        </div>

        {loan.status === 'PENDING_IMF' && (
          <div className="flex gap-4">
            <Button variant="primary" size="lg" onClick={() => setModalOpen(true)}>
              Valider / Rejeter ce prêt
            </Button>
          </div>
        )}

        <LoanValidationModal
          open={modalOpen}
          loan={loan}
          onClose={() => setModalOpen(false)}
          onConfirm={handleConfirmValidation}
        />
      </div>
    </ProtectedRoute>
  );
}
