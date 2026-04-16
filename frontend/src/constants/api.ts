export const API_CONFIG = {
  BASE_URL: "http://localhost:3000/api/v1",
  TIMEOUT: 10000,
};

export const ENDPOINTS = {
  AUTH: {
    REGISTER: "/auth/register",
    LOGIN: "/auth/login",
    VERIFY_PHONE: "/auth/verify-phone",
    VERIFY_EMAIL: "/auth/verify-email",
    RESEND_OTP: "/auth/resend-otp",
    FORGOT_PASSWORD: "/auth/forgot-password",
    RESET_PASSWORD: "/auth/reset-password",
    GOOGLE: "/auth/google",
    REFRESH: "/auth/refresh",
    LOGOUT: "/auth/logout",
    ME: "/auth/me",
  },
  USERS: {
    KYC: (session: 1 | 2 | 3) => `/users/kyc/session-${session}`,
    KYC_STATUS: "/users/kyc/status",
    PROFILE: "/users/profile",
  },
};
