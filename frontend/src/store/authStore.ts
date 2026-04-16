import { create } from "zustand";

interface AuthState {
  isAuthenticated: boolean;
  hasSession: boolean;
  isHydrated: boolean;
  checkSession: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  isAuthenticated: false,
  hasSession: false,
  isHydrated: false,
  checkSession: async () => {
    // Simulation d'une vérification de session (refresh token, etc.)
    await new Promise((resolve) => setTimeout(resolve, 2000));
    // Pour l'instant, session à false pour tester le flow de login
    set({ isHydrated: true, isAuthenticated: false, hasSession: false });
  },
}));
