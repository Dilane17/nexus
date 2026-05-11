'use client';

import Link from 'next/link';
import Table, { type Column } from '@/components/ui/Table';
import Badge from '@/components/ui/Badge';
import Button from '@/components/ui/Button';
import type { Loan } from '@/lib/types';

interface LoansTableProps {
  data: Loan[];
  loading: boolean;
  onValidate?: (loan: Loan) => void;
  showValidateButton?: boolean;
}

export default function LoansTable({ data, loading, onValidate, showValidateButton }: LoansTableProps) {
  const columns: Column[] = [
    {
      key: 'borrower',
      header: 'Emprunteur',
      render: (row) => {
        const loan = row as unknown as Loan;
        return loan.borrower
          ? `${loan.borrower.firstName} ${loan.borrower.lastName}`
          : loan.borrowerId.slice(0, 8) + '…';
      },
    },
    {
      key: 'amount',
      header: 'Montant',
      render: (row) => `${Number((row as unknown as Loan).amount).toLocaleString('fr-FR')} FCFA`,
    },
    {
      key: 'interestRate',
      header: 'Taux',
      render: (row) => {
        const rate = (row as unknown as Loan).interestRate;
        return rate ? `${Number(rate).toFixed(1)}%` : '—';
      },
    },
    {
      key: 'durationMonths',
      header: 'Durée',
      render: (row) => `${(row as unknown as Loan).durationMonths} mois`,
    },
    {
      key: 'hybridScore',
      header: 'Score',
      render: (row) => {
        const score = (row as unknown as Loan).hybridScore;
        return score != null ? score.toFixed(0) : '—';
      },
    },
    {
      key: 'status',
      header: 'Statut',
      render: (row) => <Badge status={(row as unknown as Loan).status} />,
    },
    {
      key: 'actions',
      header: '',
      render: (row) => {
        const loan = row as unknown as Loan;
        return (
          <div className="flex items-center gap-2">
            {showValidateButton && onValidate && (
              <Button size="sm" variant="secondary" onClick={() => onValidate(loan)}>
                Valider
              </Button>
            )}
            <Link
              href={`/dashboard/loans/${loan.id}`}
              className="text-[#1A3A5C] text-xs font-medium hover:underline"
            >
              Voir →
            </Link>
          </div>
        );
      },
    },
  ];

  return (
    <Table
      columns={columns}
      data={data as unknown as Record<string, unknown>[]}
      loading={loading}
      emptyMessage="Aucun prêt trouvé"
    />
  );
}
