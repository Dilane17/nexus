'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  FileCheck,
  Banknote,
  Settings,
  Wallet,
} from 'lucide-react';
import { useAuthStore } from '@/store/authStore';

const adminNav = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/dashboard/users', label: 'Utilisateurs', icon: Users },
  { href: '/dashboard/kyc', label: 'KYC en attente', icon: FileCheck },
  { href: '/dashboard/loans', label: 'Prêts', icon: Banknote },
  { href: '/dashboard/scoring', label: 'Scoring Engine', icon: Settings },
  { href: '/dashboard/wallet', label: 'Wallets', icon: Wallet },
];

const imfStaffNav = [
  { href: '/dashboard/kyc', label: 'KYC en attente', icon: FileCheck },
  { href: '/dashboard/loans', label: 'Prêts à valider', icon: Banknote },
];

export default function Sidebar() {
  const pathname = usePathname();
  const { user } = useAuthStore();

  const nav = user?.role === 'admin' ? adminNav : imfStaffNav;

  return (
    <aside className="w-64 min-h-screen flex-shrink-0 flex flex-col" style={{ backgroundColor: '#0D1F3C' }}>
      <div className="px-6 py-5 border-b border-white/10">
        <span className="text-white font-bold text-xl tracking-wide">NEXUS</span>
        <span className="ml-2 text-[#C8922A] text-xs font-semibold uppercase">Admin</span>
      </div>

      <nav className="flex-1 px-3 py-4 space-y-1">
        {nav.map(({ href, label, icon: Icon }) => {
          const active = pathname === href || (href !== '/dashboard' && pathname.startsWith(href));
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-[6px] text-sm font-medium transition-colors ${
                active
                  ? 'bg-[#C8922A] text-white'
                  : 'text-white/70 hover:bg-white/10 hover:text-white'
              }`}
            >
              <Icon size={18} />
              {label}
            </Link>
          );
        })}
      </nav>

      <div className="px-6 py-4 border-t border-white/10">
        <p className="text-white/40 text-xs">
          {user?.role === 'admin' ? 'Administrateur' : 'IMF Staff'}
        </p>
      </div>
    </aside>
  );
}
