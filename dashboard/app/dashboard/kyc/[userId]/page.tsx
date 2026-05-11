'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import ProtectedRoute from '@/components/layout/ProtectedRoute';
import Card from '@/components/ui/Card';
import Button from '@/components/ui/Button';
import Badge from '@/components/ui/Badge';
import KycValidationModal from '@/components/features/kyc/KycValidationModal';
import api from '@/lib/api';
import type { ApiResponse, User } from '@/lib/types';

export default function KycDetailPage() {
  const { userId } = useParams<{ userId: string }>();
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .get<ApiResponse<User>>(`/admin/users/${userId}`)
      .then((res) => setUser(res.data.data))
      .catch(() => setError('Impossible de charger le dossier.'))
      .finally(() => setLoading(false));
  }, [userId]);

  const validate = async (decision: 'APPROVED' | 'REJECTED', reason?: string) => {
    setActionLoading(true);
    try {
      await api.patch(`/users/kyc/validate/${userId}`, { decision, reason });
      router.push('/dashboard/kyc');
    } catch {
      setError('Erreur lors de la validation. Veuillez réessayer.');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-4">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-32 bg-white rounded-[8px] animate-pulse" />
        ))}
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-[8px] p-4 text-sm text-[#991B1B]">
        {error ?? 'Dossier introuvable.'}
      </div>
    );
  }

  return (
    <ProtectedRoute allowedRoles={['admin', 'imf_staff']}>
      <div className="space-y-6 max-w-4xl">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-[#1A3A5C]">
              {user.firstName} {user.lastName}
            </h1>
            <div className="flex items-center gap-2 mt-1">
              <Badge status={user.kycStatus} />
              <span className="text-sm text-gray-500">{user.email}</span>
            </div>
          </div>
          <button
            onClick={() => router.back()}
            className="text-sm text-gray-500 hover:text-[#1A3A5C]"
          >
            ← Retour
          </button>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-[8px] p-3 text-sm text-[#991B1B]">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card title="Informations personnelles">
            <dl className="space-y-3 text-sm">
              {[
                ['Prénom', user.firstName],
                ['Nom', user.lastName],
                ['Email', user.email],
                ['Téléphone', user.phone ?? '—'],
                ['Ville', user.city ?? '—'],
                ['Quartier', user.district ?? '—'],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between">
                  <dt className="text-gray-500">{label}</dt>
                  <dd className="font-medium text-gray-800">{value}</dd>
                </div>
              ))}
            </dl>
          </Card>

          <Card title="Informations financières">
            <dl className="space-y-3 text-sm">
              {[
                ['Revenu mensuel', user.kycMonthlyIncome ? `${Number(user.kycMonthlyIncome).toLocaleString('fr-FR')} FCFA` : '—'],
                ['Source de revenu', user.kycIncomeSource ?? '—'],
                ['Type de document', user.kycDocumentType ?? '—'],
                ['Soumis le', user.kycSubmittedAt ? new Date(user.kycSubmittedAt).toLocaleDateString('fr-FR') : '—'],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between">
                  <dt className="text-gray-500">{label}</dt>
                  <dd className="font-medium text-gray-800">{value}</dd>
                </div>
              ))}
            </dl>
          </Card>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {user.kycDocumentUrl && (
            <Card title="Document d'identité (CNI/CIP)">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={user.kycDocumentUrl}
                alt="Document identité"
                className="w-full rounded-[6px] object-cover max-h-64"
              />
            </Card>
          )}
          {user.kycSelfieUrl && (
            <Card title="Selfie">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={user.kycSelfieUrl}
                alt="Selfie"
                className="w-full rounded-[6px] object-cover max-h-64"
              />
            </Card>
          )}
        </div>

        {user.kycMomoStatement && (
          <Card title="Relevé Mobile Money">
            <a
              href={user.kycMomoStatement}
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-[#1A3A5C] underline hover:text-[#C8922A]"
            >
              Télécharger / Voir le relevé MoMo
            </a>
          </Card>
        )}

        {(user.kycStatus === 'SESSION2_DONE' || user.kycStatus === 'SESSION1_DONE') && (
          <div className="flex gap-4 pt-2">
            <Button
              variant="primary"
              size="lg"
              loading={actionLoading}
              onClick={() => validate('APPROVED')}
            >
              ✓ Approuver le dossier
            </Button>
            <Button
              variant="danger"
              size="lg"
              disabled={actionLoading}
              onClick={() => setRejectModalOpen(true)}
            >
              ✕ Rejeter le dossier
            </Button>
          </div>
        )}

        <KycValidationModal
          open={rejectModalOpen}
          onClose={() => setRejectModalOpen(false)}
          onConfirm={async (reason) => {
            await validate('REJECTED', reason);
            setRejectModalOpen(false);
          }}
        />
      </div>
    </ProtectedRoute>
  );
}
