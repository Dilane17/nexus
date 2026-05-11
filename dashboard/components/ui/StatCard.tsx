import { type LucideIcon } from 'lucide-react';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  trend?: { value: number; label: string };
  accentColor?: string;
}

export default function StatCard({ label, value, icon: Icon, trend, accentColor = '#1A3A5C' }: StatCardProps) {
  return (
    <div className="bg-white rounded-[8px] shadow-sm border border-gray-100 p-6">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm text-gray-500 font-medium">{label}</p>
          <p className="mt-1 text-2xl font-bold text-gray-900">{value}</p>
          {trend && (
            <p className={`mt-1 text-xs ${trend.value >= 0 ? 'text-[#166534]' : 'text-[#991B1B]'}`}>
              {trend.value >= 0 ? '▲' : '▼'} {Math.abs(trend.value)}% {trend.label}
            </p>
          )}
        </div>
        <div
          className="p-3 rounded-[8px] opacity-90"
          style={{ backgroundColor: `${accentColor}18` }}
        >
          <Icon size={22} style={{ color: accentColor }} />
        </div>
      </div>
    </div>
  );
}
