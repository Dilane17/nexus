'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import axios from 'axios';
import { useAuthStore } from '@/store/authStore';
import { getRoleFromToken } from '@/lib/auth';
import type { ApiResponse, AuthUser, UserRole } from '@/lib/types';

const loginSchema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(6, 'Minimum 6 caractères'),
});

type LoginForm = z.infer<typeof loginSchema>;

interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: AuthUser;
}

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuthStore();
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({ resolver: zodResolver(loginSchema) });

  const onSubmit = async (data: LoginForm) => {
    setError(null);
    try {
      const res = await axios.post<ApiResponse<LoginResponse>>(
        `${process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000/api/v1'}/auth/login`,
        data
      );
      const { accessToken, user } = res.data.data;
      const role = getRoleFromToken(accessToken) as UserRole;

      if (role !== 'admin' && role !== 'imf_staff') {
        setError('Accès refusé. Ce dashboard est réservé aux administrateurs et au staff IMF.');
        return;
      }

      login(accessToken, { ...user, role });

      if (role === 'admin') {
        router.push('/dashboard');
      } else {
        router.push('/dashboard/kyc');
      }
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.status === 401) {
        setError('Email ou mot de passe incorrect.');
      } else {
        setError('Une erreur est survenue. Veuillez réessayer.');
      }
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#0D1F3C' }}>
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white tracking-wide">NEXUS</h1>
          <p className="text-[#C8922A] font-semibold text-sm mt-1 uppercase tracking-widest">
            Admin Dashboard
          </p>
        </div>

        <div className="bg-white rounded-[8px] shadow-xl p-8">
          <h2 className="text-xl font-semibold text-[#1A3A5C] mb-6">Connexion</h2>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input
                type="email"
                {...register('email')}
                placeholder="admin@nexus.bj"
                className="w-full px-3 py-2.5 border border-gray-300 rounded-[6px] text-sm focus:outline-none focus:ring-2 focus:ring-[#1A3A5C] focus:border-transparent"
              />
              {errors.email && (
                <p className="mt-1 text-xs text-[#991B1B]">{errors.email.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Mot de passe</label>
              <input
                type="password"
                {...register('password')}
                placeholder="••••••••"
                className="w-full px-3 py-2.5 border border-gray-300 rounded-[6px] text-sm focus:outline-none focus:ring-2 focus:ring-[#1A3A5C] focus:border-transparent"
              />
              {errors.password && (
                <p className="mt-1 text-xs text-[#991B1B]">{errors.password.message}</p>
              )}
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 rounded-[6px] px-4 py-3">
                <p className="text-sm text-[#991B1B]">{error}</p>
              </div>
            )}

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-2.5 bg-[#1A3A5C] text-white font-semibold rounded-[6px] text-sm hover:bg-[#142d47] transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {isSubmitting && (
                <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4l3-3-3-3v4a8 8 0 00-8 8h4z" />
                </svg>
              )}
              {isSubmitting ? 'Connexion...' : 'Se connecter'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
