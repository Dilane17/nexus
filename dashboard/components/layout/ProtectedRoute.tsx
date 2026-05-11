'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import type { UserRole } from '@/lib/types';

interface ProtectedRouteProps {
  children: React.ReactNode;
  allowedRoles?: UserRole[];
}

export default function ProtectedRoute({ children, allowedRoles }: ProtectedRouteProps) {
  const router = useRouter();
  const { accessToken, user } = useAuthStore();

  useEffect(() => {
    if (!accessToken || !user) {
      router.replace('/login');
      return;
    }
    if (allowedRoles && !allowedRoles.includes(user.role)) {
      router.replace('/dashboard');
    }
  }, [accessToken, user, allowedRoles, router]);

  if (!accessToken || !user) return null;
  if (allowedRoles && !allowedRoles.includes(user.role)) return null;

  return <>{children}</>;
}
