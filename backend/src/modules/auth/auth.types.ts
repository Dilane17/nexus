export type UserRole = 'investor' | 'borrower' | 'admin' | 'agent' | 'imf_staff' | 'user';

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
  iat?: number;
  exp?: number;
}

export interface AuthUser {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  city: string | null;
  district: string | null;
  avatar: string | null;
  status: string;
  kyc_status: string;
  isEmailVerified: boolean;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: AuthUser;
}

export interface GoogleProfile {
  googleId: string;
  email: string | null;
  firstName: string;
  lastName: string;
  avatar: string | null;
}

export interface GoogleLoginResult {
  needsVerification: boolean;
  message?: string;
  tokens?: AuthTokens;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message: string;
}
