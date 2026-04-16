import React, { useEffect } from 'react';
import { Slot, useRouter, useSegments } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useAuthStore } from '../src/store/authStore';
import { useFonts, Manrope_700Bold, Manrope_600SemiBold } from '@expo-google-fonts/manrope';
import { PublicSans_400Regular, PublicSans_500Medium } from '@expo-google-fonts/public-sans';
import AnimatedSplash from '../src/components/ui/AnimatedSplash';

// Empêcher le Splash Screen natif de disparaître
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const { isHydrated, hasSession, checkSession } = useAuthStore();
  const segments = useSegments();
  const router = useRouter();

  // Chargement des polices
  const [fontsLoaded, fontError] = useFonts({
    Manrope_700Bold,
    Manrope_600SemiBold,
    PublicSans_400Regular,
    PublicSans_500Medium,
  });

  // Initialisation : Vérification session + délai animation
  useEffect(() => {
    checkSession();
  }, []);

  // Orchestration de la navigation et du Splash
  useEffect(() => {
    // On attend que les polices soient prêtes et que le store soit hydraté
    if (!(fontsLoaded || fontError) || !isHydrated) return;

    // Masquer le splash screen natif
    SplashScreen.hideAsync();

    const inAuthGroup = segments[0] === '(auth)';

    if (hasSession) {
      // Session valide -> Dashboard
      router.replace('/(tabs)');
    } else if (!inAuthGroup) {
      // Pas de session et pas déjà dans auth -> Login
      router.replace('/login');
    }
  }, [fontsLoaded, fontError, isHydrated, hasSession, segments]);

  // Tant que l'initialisation n'est pas terminée, on montre le Splash Animé
  if (!(fontsLoaded || fontError) || !isHydrated) {
    return <AnimatedSplash />;
  }

  return <Slot />;
}
