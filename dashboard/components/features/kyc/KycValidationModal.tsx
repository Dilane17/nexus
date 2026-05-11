'use client';

import { useState } from 'react';
import Modal from '@/components/ui/Modal';
import Button from '@/components/ui/Button';

interface KycValidationModalProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => Promise<void>;
}

export default function KycValidationModal({ open, onClose, onConfirm }: KycValidationModalProps) {
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleConfirm = async () => {
    if (!reason.trim()) {
      setError('Le motif de rejet est obligatoire.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await onConfirm(reason);
      setReason('');
    } catch {
      setError('Erreur lors du rejet. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Rejeter le dossier KYC">
      <div className="space-y-4">
        <p className="text-sm text-gray-600">
          Indiquez le motif de rejet. Ce message sera transmis à l&apos;utilisateur.
        </p>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Motif de rejet</label>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={4}
            placeholder="Exemple : Document illisible, photo de mauvaise qualité…"
            className="w-full px-3 py-2 border border-gray-300 rounded-[6px] text-sm focus:outline-none focus:ring-2 focus:ring-[#991B1B] resize-none"
          />
        </div>
        {error && <p className="text-xs text-[#991B1B]">{error}</p>}
        <div className="flex justify-end gap-3 pt-2">
          <Button variant="ghost" size="sm" onClick={onClose} disabled={loading}>
            Annuler
          </Button>
          <Button variant="danger" size="sm" onClick={handleConfirm} loading={loading}>
            Confirmer le rejet
          </Button>
        </div>
      </div>
    </Modal>
  );
}
