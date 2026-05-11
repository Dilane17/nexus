type BadgeVariant = 'success' | 'warning' | 'danger' | 'info' | 'neutral';

const STATUS_MAP: Record<string, BadgeVariant> = {
  ACTIVE: 'success',
  VALIDATED: 'success',
  APPROVED: 'success',
  REPAID: 'success',
  FUNDED: 'success',
  PENDING: 'warning',
  PENDING_IMF: 'warning',
  FUNDING: 'warning',
  SESSION1_DONE: 'info',
  SESSION2_DONE: 'info',
  OVERDUE: 'danger',
  DEFAULTED: 'danger',
  REJECTED: 'danger',
  SUSPENDED: 'danger',
};

const variantClasses: Record<BadgeVariant, string> = {
  success: 'bg-green-100 text-[#166534]',
  warning: 'bg-amber-100 text-amber-800',
  danger: 'bg-red-100 text-[#991B1B]',
  info: 'bg-blue-100 text-blue-800',
  neutral: 'bg-gray-100 text-gray-700',
};

interface BadgeProps {
  status: string;
  label?: string;
  className?: string;
}

export default function Badge({ status, label, className = '' }: BadgeProps) {
  const variant: BadgeVariant = STATUS_MAP[status] ?? 'neutral';
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${variantClasses[variant]} ${className}`}
    >
      {label ?? status.replace(/_/g, ' ')}
    </span>
  );
}
