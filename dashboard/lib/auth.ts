import type { JwtPayload, UserRole } from '@/lib/types';

export function decodeJwt(token: string): JwtPayload | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = parts[1];
    const decoded = atob(payload.replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(decoded) as JwtPayload;
  } catch {
    return null;
  }
}

export function getRoleFromToken(token: string): UserRole | null {
  const payload = decodeJwt(token);
  return payload?.role ?? null;
}

export function isTokenExpired(token: string): boolean {
  const payload = decodeJwt(token);
  if (!payload?.exp) return true;
  return Date.now() / 1000 > payload.exp;
}
