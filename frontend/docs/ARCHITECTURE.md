# Architecture Front-end : PeerFund Bénin (Mobile)

## Stack Technique
- **Framework :** React Native (Expo) + Expo Router
- **Style :** NativeWind (Tailwind CSS)
- **State Management :** Zustand
- **Data Fetching :** Axios
- **Formulaires & Validation :** React Hook Form + Zod

## Arborescence
/app               # Routes de l'application (Expo Router)
  /(auth)          # Écrans d'authentification (Register, Login, OTP)
  /(tabs)          # Navigation principale post-connexion
  /kyc             # Flux de vérification (Sessions 1, 2, 3)
/src
  /api             # Configuration Axios et intercepteurs JWT
  /components      # Composants UI (Boutons, Inputs, etc.)
  /store           # Stores Zustand (authStore, etc.)
  /validators      # Schémas de validation Zod partagés avec le backend
/docs              # Documentation du projet