'use client';

import { useState } from 'react';
import Modal from '@/components/ui/Modal';
import Button from '@/components/ui/Button';
import type { Loan } from '@/lib/types';

interface LoanValidationModalProps {
  open: boolean;
  loan: Loan | null;
  onClose: () => void;
  onConfirm: (decision: 'APPROVED' | 'REJECTED', interestRate?: number, reason?: string) => Promise<void>;
}

export default function LoanValidationModal({ open, loan, onClose, onConfirm }: LoanValidationModalProps) {
  const [decision, setDecision] = useState<'APPROVED' | 'REJECTED'>('APPROVED');
  const [interestRate, setInterestRate] = useState('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleConfirm = async () => {
    if (decision === 'REJECTED' && !reason.trim()) {
      setError('Le motif de rejet est obligatoire.');
      return;
    }
    if (decision === 'APPROVED' && interestRate) {
      const rate = parseFloat(interestRate);
      if (isNaN(rate) || rate <= 0 || rate > 18) {
        setError('Le taux doit être compris entre 0 et 18% (BCEAO).');
        return;
      }
    }
    setLoading(true);
    setError(null);
    try {
      await onConfirm(
        decision,
        decision === 'APPROVED' && interestRate ? parseFloat(interestRate) : undefined,
        decision === 'REJECTED' ? reason : undefined
      );
      setReason('');
      setInterestRate('');
    } catch {
      setError('Erreur lors de la validation. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Valider le prêt">
      {loan && (
        <div className="space-y-4">
          <div className="bg-gray-50 rounded-[6px] p-3 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">Montant</span>
              <span className="font-medium">{Number(loan.amount).toLocaleString('fr-FR')} FCFA</span>
            </div>
            <div className="flex justify-between mt-1">
              <span className="text-gray-500">Score hybride</span>
              <span className="font-medium">{loan.hybridScore?.toFixed(0) ?? '—'}</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Décision</label>
            <div className="flex gap-3">
              {(['APPROVED', 'REJECTED'] as const).map((d) => (
                <button
                  key={d}
                  onClick={() => setDecision(d)}
                  className={`flex-1 py-2 rounded-[6px] text-sm font-medium border transition-colors ${
                    decision === d
                      ? d === 'APPROVED'
                        ? 'bg-[#166534] text-white border-[#166534]'
                        : 'bg-[#991B1B] text-white border-[#991B1B]'
                      : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
                  }`}
                >
                  {d === 'APPROVED' ? '✓ Approuver' : '✕ Rejeter'}
                </button>
              ))}
            </div>
          </div>

          {decision === 'APPROVED' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Taux d&apos;intérêt (%) <span className="text-gray-400 font-normal">— optionnel, max 18%</span>
              </label>
              <input
                type="number"
                step="0.1"
                min="0"
                max="18"
                value={interestRate}
                onChange={(e) => setInterestRate(e.target.value)}
                placeholder="Ex: 12.5"
                className="w-full px-3 py-2 border border-gray-300 rounded-[6px] text-sm focus:outline-none focus:ring-2 focus:ring-[#1A3A5C]"
              />
            </div>
          )}

          {decision === 'REJECTED' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Motif de rejet</label>
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                rows={3}
                placeholder="Expliquer la raison du rejet…"
                className="w-full px-3 py-2 border border-gray-300 rounded-[6px] text-sm focus:outline-none focus:ring-2 focus:ring-[#991B1B] resize-none"
              />
            </div>
          )}

          {error && <p className="text-xs text-[#991B1B]">{error}</p>}

          <div className="flex justify-end gap-3 pt-2">
            <Button variant="ghost" size="sm" onClick={onClose} disabled={loading}>
              Annuler
            </Button>
            <Button
              variant={decision === 'APPROVED' ? 'primary' : 'danger'}
              size="sm"
              onClick={handleConfirm}
              loading={loading}
            >
              Confirmer
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}
