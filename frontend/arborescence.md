# Arborescence du Projet Nexus — Frontend

Cette structure utilise **Expo Router** pour la navigation et une architecture modulaire dans `src/` pour la logique métier.

```text
frontend/
├── app/                       # 📂 Routes de l'application (File-based routing)
│   ├── (auth)/                # 🔐 Groupe Authentification (sans TabBar)
│   │   ├── login.tsx          # Écran de connexion
│   │   ├── register.tsx       # Écran d'inscription
│   │   ├── verify-otp.tsx     # Validation OTP (SMS/Email)
│   │   └── forgot-password.tsx # Récupération de compte
│   ├── (tabs)/                # 🏠 Navigation principale (Bottom Tabs)
│   │   ├── index.tsx          # Dashboard (Home)
│   │   ├── loans.tsx          # Gestion des prêts
│   │   ├── wallet.tsx         # Portefeuille / Transactions
│   │   ├── profile.tsx        # Paramètres du profil
│   │   └── _layout.tsx        # Configuration du TabBar
│   ├── kyc/                   # 🆔 Flux de vérification d'identité
│   │   ├── session-1.tsx      # Identité (CNI/CIP)
│   │   ├── session-2.tsx      # Revenus
│   │   └── session-3.tsx      # Soumission IMF
│   ├── onboarding/            # 🚀 Introduction (Slides)
│   │   └── index.tsx
│   ├── _layout.tsx            # Orchestrateur (Nav, Polices, Splash)
│   └── index.tsx              # Redirection initiale
├── src/                       # 📂 Logique métier et composants
│   ├── components/            # 🏗️ Composants UI réutilisables
│   │   ├── common/            # Atomes : Button, Input, Card, OtpInput
│   │   ├── layout/            # Organismes : Headers, Containers
│   │   └── ui/                # Animations : AnimatedSplash, etc.
│   ├── store/                 # 🧠 État global (Zustand)
│   │   ├── authStore.ts
│   │   ├── userStore.ts
│   │   └── loanStore.ts
│   ├── services/              # 🌐 Appels API (Axios)
│   │   ├── api.ts             # Instance Axios & Intercepteurs
│   │   ├── authService.ts
│   │   └── userService.ts
│   ├── constants/             # 🎨 Design System & Config
│   │   ├── colors.ts          # Palette "Kinetic Noir"
│   │   ├── typography.ts      # Styles de texte
│   │   └── api.ts             # Endpoints et Base URL
│   ├── hooks/                 # ⚓ Hooks personnalisés (useAuth...)
│   ├── types/                 # 📝 Définitions TypeScript
│   └── validators/            # ✅ Schémas de validation (Zod)
├── assets/                    # 🖼️ Images, Logos et Polices
├── docs/                      # 📖 Documentation technique
└── app.json                   # ⚙️ Configuration Expo
```
