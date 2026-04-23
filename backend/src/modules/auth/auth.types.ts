export type UserRole = 'investor' | 'borrower' | 'admin' | 'agent' | 'imf_staff' | 'user';

export interface JwtPayload {
  sub: string;
  phone: string;
  role: UserRole;
  iat?: number;
  exp?: number;
}

export interface AuthUser {
  id: string;
  firstName: string;
  lastName: string;
  phone: string;
  email: string | null;
  city: string | null;
  district: string | null;
  avatar: string | null;
  status: string;
  kyc_status: string;
  isPhoneVerified: boolean;
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
