'use client';

import { useEffect, useState } from 'react';
import ProtectedRoute from '@/components/layout/ProtectedRoute';
import Card from '@/components/ui/Card';
import api from '@/lib/api';
import type { ApiResponse, WalletSummary } from '@/lib/types';

function formatFcfa(n: number) {
  return `${Number(n).toLocaleString('fr-FR')} FCFA`;
}

export default function WalletPage() {
  const [summary, setSummary] = useState<WalletSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .get<ApiResponse<WalletSummary>>('/wallet/summary')
      .then((res) => setSummary(res.data.data))
      .catch(() => setError('Impossible de charger les données des wallets.'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-48 bg-white rounded-[8px] animate-pulse" />
        ))}
      </div>
    );
  }

  return (
    <ProtectedRoute allowedRoles={['admin']}>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-[#1A3A5C]">Wallets</h1>
          <p className="text-sm text-gray-500 mt-0.5">Supervision des fonds de la plateforme</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-[8px] p-4 text-sm text-[#991B1B]">
            {error}
          </div>
        )}

        {summary && (
          <>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <Card title="Escrow Wallet">
                <dl className="space-y-3 text-sm">
                  {[
                    ['Solde total', formatFcfa(summary.escrow.totalBalance)],
                    ['Fonds investisseurs', formatFcfa(summary.escrow.investorFunds)],
                    ['Fonds garantie', formatFcfa(summary.escrow.lockedForGuarantee)],
                    ['Frais plateforme', formatFcfa(summary.escrow.platformFees)],
                    ['Gestionnaire', summary.escrow.thirdPartyManager],
                    ['Dernier audit', summary.escrow.lastAuditDate ? new Date(summary.escrow.lastAuditDate).toLocaleDateString('fr-FR') : '—'],
                  ].map(([label, value]) => (
                    <div key={label} className="flex justify-between gap-2">
                      <dt className="text-gray-500 shrink-0">{label}</dt>
                      <dd className="font-medium text-gray-800 text-right">{value}</dd>
                    </div>
                  ))}
                </dl>
              </Card>

              <Card title="Platform Wallet">
                <dl className="space-y-3 text-sm">
                  {[
                    ['Commissions', formatFcfa(summary.platform.commissionBalance)],
                    ['Fonds opérationnels', formatFcfa(summary.platform.operatingFunds)],
                    ['Dernier retrait', summary.platform.lastWithdrawalDate ? new Date(summary.platform.lastWithdrawalDate).toLocaleDateString('fr-FR') : '—'],
                  ].map(([label, value]) => (
                    <div key={label} className="flex justify-between gap-2">
                      <dt className="text-gray-500 shrink-0">{label}</dt>
                      <dd className="font-medium text-gray-800 text-right">{value}</dd>
                    </div>
                  ))}
                  <div className="pt-2 border-t border-gray-100">
                    <div className="flex justify-between">
                      <dt className="text-gray-500">Total plateforme</dt>
                      <dd className="font-bold text-[#1A3A5C]">{formatFcfa(summary.totalPlatformValue)}</dd>
                    </div>
                  </div>
                </dl>
              </Card>

              <Card title="Fonds de Garantie">
                {(() => {
                  const gf = summary.escrow;
                  return (
                    <dl className="space-y-3 text-sm">
                      <div className="flex justify-between gap-2">
                        <dt className="text-gray-500">Capital verrouillé</dt>
                        <dd className="font-medium text-gray-800">{formatFcfa(gf.lockedForGuarantee)}</dd>
                      </div>
                      <div className="flex justify-between gap-2 items-center">
                        <dt className="text-gray-500">Statut</dt>
                        <dd>
                          <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-100 text-[#166534]">
                            Actif
                          </span>
                        </dd>
                      </div>
                    </dl>
                  );
                })()}
              </Card>
            </div>

            <div className="text-xs text-gray-400 text-right">
              Données temps réel — actualisez la page pour mettre à jour
            </div>
          </>
        )}
      </div>
    </ProtectedRoute>
  );
}
