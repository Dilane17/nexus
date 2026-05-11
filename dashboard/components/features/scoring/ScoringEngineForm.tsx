'use client';

import { useEffect, useState } from 'react';
import Button from '@/components/ui/Button';
import api from '@/lib/api';
import type { ApiResponse, ScoringEngine } from '@/lib/types';

export default function ScoringEngineForm() {
  const [weights, setWeights] = useState({ momoWeight: 40, tontineWeight: 35, imfWeight: 25 });
  const [warningSignalDays, setWarningSignalDays] = useState(30);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    api
      .get<ApiResponse<ScoringEngine>>('/admin/scoring-engine')
      .then((res) => {
        const d = res.data.data;
        setWeights({
          momoWeight: Math.round(d.momoWeight * 100),
          tontineWeight: Math.round(d.tontineWeight * 100),
          imfWeight: Math.round(d.imfWeight * 100),
        });
        setWarningSignalDays(d.warningSignalDays);
      })
      .catch(() => setError('Impossible de charger la configuration.'))
      .finally(() => setLoading(false));
  }, []);

  const total = weights.momoWeight + weights.tontineWeight + weights.imfWeight;
  const isValid = total === 100;

  const handleSlider = (key: keyof typeof weights, value: number) => {
    setWeights((prev) => ({ ...prev, [key]: value }));
    setSuccess(false);
  };

  const handleSave = async () => {
    if (!isValid) return;
    setSaving(true);
    setError(null);
    setSuccess(false);
    try {
      await api.patch('/admin/scoring-engine', {
        momoWeight: weights.momoWeight / 100,
        tontineWeight: weights.tontineWeight / 100,
        imfWeight: weights.imfWeight / 100,
        warningSignalDays,
      });
      setSuccess(true);
    } catch {
      setError('Erreur lors de la sauvegarde.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="space-y-4">{Array.from({ length: 3 }).map((_, i) => <div key={i} className="h-10 bg-gray-200 rounded animate-pulse" />)}</div>;
  }

  const sliders = [
    { key: 'momoWeight' as const, label: 'Mobile Money (MoMo)', color: '#1A3A5C' },
    { key: 'tontineWeight' as const, label: 'Tontine Bridge', color: '#C8922A' },
    { key: 'imfWeight' as const, label: 'Historique IMF', color: '#166534' },
  ];

  return (
    <div className="space-y-6">
      <div className="space-y-5">
        {sliders.map(({ key, label, color }) => (
          <div key={key}>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-medium text-gray-700">{label}</label>
              <span className="text-lg font-bold" style={{ color }}>{weights[key]}%</span>
            </div>
            <input
              type="range"
              min={0}
              max={100}
              value={weights[key]}
              onChange={(e) => handleSlider(key, parseInt(e.target.value))}
              className="w-full h-2 rounded-full appearance-none cursor-pointer"
              style={{ accentColor: color }}
            />
          </div>
        ))}
      </div>

      <div
        className={`flex items-center justify-between rounded-[8px] px-4 py-3 text-sm font-semibold ${
          isValid ? 'bg-green-50 text-[#166534]' : 'bg-red-50 text-[#991B1B]'
        }`}
      >
        <span>Total des poids</span>
        <span className="text-lg">{total}%{isValid ? ' ✓' : ' ✗ — doit être 100%'}</span>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Jours d&apos;alerte signaux ({warningSignalDays}j)
        </label>
        <input
          type="number"
          min={1}
          value={warningSignalDays}
          onChange={(e) => setWarningSignalDays(parseInt(e.target.value) || 1)}
          className="w-32 px-3 py-2 border border-gray-300 rounded-[6px] text-sm focus:outline-none focus:ring-2 focus:ring-[#1A3A5C]"
        />
      </div>

      {error && <p className="text-sm text-[#991B1B]">{error}</p>}
      {success && <p className="text-sm text-[#166534]">✓ Configuration enregistrée avec succès.</p>}

      <Button onClick={handleSave} loading={saving} disabled={!isValid} size="lg">
        Enregistrer la configuration
      </Button>
    </div>
  );
}
