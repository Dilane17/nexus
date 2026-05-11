'use client';

import { useRouter } from 'next/navigation';
import { LogOut } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import Badge from '@/components/ui/Badge';

export default function Header() {
  const router = useRouter();
  const { user, logout } = useAuthStore();

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6 flex-shrink-0">
      <div />
      <div className="flex items-center gap-4">
        {user && (
          <div className="flex items-center gap-3">
            <Badge status={user.role === 'admin' ? 'ACTIVE' : 'SESSION1_DONE'} label={user.role} />
            <span className="text-sm font-medium text-gray-700">
              {user.firstName} {user.lastName}
            </span>
          </div>
        )}
        <button
          onClick={handleLogout}
          className="flex items-center gap-2 text-sm text-gray-500 hover:text-[#991B1B] transition-colors"
        >
          <LogOut size={16} />
          Déconnexion
        </button>
      </div>
    </header>
  );
}
