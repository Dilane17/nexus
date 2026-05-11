import ProtectedRoute from '@/components/layout/ProtectedRoute';
import Card from '@/components/ui/Card';
import ScoringEngineForm from '@/components/features/scoring/ScoringEngineForm';

export default function ScoringPage() {
  return (
    <ProtectedRoute allowedRoles={['admin']}>
      <div className="max-w-xl space-y-4">
        <div>
          <h1 className="text-2xl font-bold text-[#1A3A5C]">Scoring Engine</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            Configurez les poids du modèle de scoring hybride (somme = 100%)
          </p>
        </div>
        <Card title="Poids du scoring">
          <ScoringEngineForm />
        </Card>
      </div>
    </ProtectedRoute>
  );
}
