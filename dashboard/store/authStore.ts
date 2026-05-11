'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { AuthUser, UserRole } from '@/lib/types';

interface AuthState {
  user: (AuthUser & { role: UserRole }) | null;
  accessToken: string | null;
  login: (token: string, user: AuthUser & { role: UserRole }) => void;
  logout: () => void;
  isAdmin: () => boolean;
  isImfStaff: () => boolean;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      accessToken: null,

      login: (token, user) => {
        set({ accessToken: token, user });
      },

      logout: () => {
        set({ accessToken: null, user: null });
      },

      isAdmin: () => get().user?.role === 'admin',

      isImfStaff: () => get().user?.role === 'imf_staff',
    }),
    {
      name: 'nexus-auth',
    }
  )
);
