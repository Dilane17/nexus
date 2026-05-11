# Module 1 — Shell & Navigation + HomeScreen

## Fichiers créés / modifiés

| Fichier | Action |
|---|---|
| `lib/features/shell/presentation/shell_screen.dart` | Nouveau |
| `lib/features/home/presentation/home_screen.dart` | Réécriture |
| `lib/features/loans/presentation/screens/loans_screen.dart` | Nouveau (placeholder) |
| `lib/features/investments/presentation/screens/investments_screen.dart` | Nouveau (placeholder) |
| `lib/features/tontine/presentation/screens/tontine_screen.dart` | Nouveau (placeholder) |
| `lib/features/wallet/presentation/screens/wallet_screen.dart` | Nouveau (placeholder) |
| `lib/core/routes/app_router.dart` | Réécriture avec ShellRoute |

---

## 1.1 — ShellScreen + NavigationBar

### Concept : StatefulShellRoute

Go Router propose deux types de shell :
- `ShellRoute` (simple) : toutes les branches partagent un seul stack de navigation
- `StatefulShellRoute.indexedStack` (utilisé ici) : **chaque onglet a son propre
  stack de navigation, mémorisé indépendamment**

Exemple concret : l'utilisateur est sur Prêts → detail du prêt #42. Il change
d'onglet pour aller sur Wallet. Quand il revient sur Prêts, il retrouve le
détail du prêt #42 — pas la liste racine. C'est le comportement attendu sur mobile.

### `goBranch` avec `initialLocation`

```dart
navigationShell.goBranch(
  index,
  initialLocation: index == navigationShell.currentIndex,
);
```

Le `initialLocation: true` se déclenche uniquement quand l'utilisateur tape
sur l'onglet **déjà actif**. Dans ce cas, go_router remonte au sommet du stack
de cette branche — comportement "double-tap pour revenir au début" standard sur iOS/Android.

### Pourquoi `NavigationBar` plutôt que `BottomNavigationBar` ?

`NavigationBar` est le composant Material 3 (M3). `BottomNavigationBar` est M2.
Comme le projet utilise `ThemeData` M3 (via `useMaterial3: true` dans `app_theme.dart`),
`NavigationBar` est cohérent et bénéficie automatiquement des couleurs du thème
(`indicatorColor`, `surfaceTintColor`…).

---

## 1.2 — app_router.dart : architecture complète

### Structure des routes

```
GoRouter
├── /           → SplashScreen            (hors shell, public)
├── /login      → LoginScreen             (hors shell, public)
├── /register   → RegisterScreen          (hors shell, public)
├── /verify-phone → VerifyPhoneScreen     (hors shell, public)
├── /forgot-password → ForgotPasswordScreen (hors shell, public)
├── /reset-password  → ResetPasswordScreen  (hors shell, public)
├── /kyc        → KYC placeholder         (hors shell, protégé, remplacé en Module 3)
└── StatefulShellRoute.indexedStack
    ├── Branch 0 : /home        → HomeScreen
    ├── Branch 1 : /loans       → LoansScreen       (placeholder M4)
    ├── Branch 2 : /investments → InvestmentsScreen (placeholder M6)
    ├── Branch 3 : /tontine     → TontineScreen     (placeholder M7)
    └── Branch 4 : /wallet      → WalletScreen      (placeholder M5)
```

### Pourquoi `/kyc` est hors du shell ?

Le flow KYC est un "onboarding gate" — il s'affiche avant que l'utilisateur
entre dans l'app principale. Il n'a pas de bottom nav. Une fois le KYC validé,
l'utilisateur entre dans le shell et ne revient plus sur /kyc (sauf si rejeté).

### Logique de redirect

Le redirect est la fonction centrale de go_router. Elle est appelée **à chaque
changement de route** ET **à chaque rebuild du provider** (ici `authProvider`).

Flux de décision :
```
1. Splash ?           → rien (SplashScreen gère son redirect via restoreSession)
2. Non auth + privé ? → /login
3. Auth + route publique ? → _kycRedirect() → /home ou /kyc
4. Sinon             → rien (laisser naviguer)
```

La fonction `_kycRedirect` est extraite du `Provider` pour la testabilité.

---

## 1.3 — HomeScreen

### Architecture interne

L'écran est décomposé en **widgets privés** (préfixés `_`) pour :
1. **Lisibilité** : la méthode `build` principale reste courte
2. **Performance** : chaque widget se rebuild indépendamment
3. **Maintenabilité** : on pourra extraire un widget en fichier séparé plus tard

| Widget | Responsabilité |
|---|---|
| `_HomeHeader` | Salutation + avatar avec initiales |
| `_KycBanner` | Carte conditionnelle pour guider vers le KYC |
| `_BalanceCard` | Affiche le solde (placeholder pour Module 5) |
| `_QuickActionsGrid` | 4 boutons d'action rapide |
| `_RecentActivitySection` | Historique (empty state pour Module 5) |

### Salutation contextuelle

```dart
String get _greeting {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bonjour';
  if (hour < 18) return 'Bon après-midi';
  return 'Bonsoir';
}
```

Petite UX detail : personnaliser le message selon l'heure augmente le sentiment
de proximité avec l'utilisateur.

### KYC Banner

La bannière n'est affichée **que si** `user.needsKyc` est vrai (getter défini
en Module 0). La configuration visuelle (couleur, icône, texte) est déterminée
par un `switch` sur `KycStatus` :

| Statut KYC | Couleur | Message |
|---|---|---|
| `notStarted` | Bleu info | "Vérifiez votre identité" |
| `session1Done` | Orange warning | "KYC en cours – Étape 2/3" |
| `session2Done` | Orange warning | "KYC presque terminé – Étape 3/3" |
| `rejected` | Rouge error | "Dossier rejeté" |

### Quick Actions : gestion des droits

Le bouton "Emprunter" est désactivé si `!user.canAccessLoans` :
- Visuellement : couleur grisée, fond neutre
- Comportement : `onTap` affiche un `SnackBar` explicatif plutôt que d'ignorer silencieusement

Ce pattern "action désactivée avec feedback" est meilleur UX que masquer le bouton
(l'utilisateur sait que la feature existe, comprend pourquoi elle est bloquée).

### `RefreshIndicator`

Le `RefreshIndicator` est en place dès maintenant mais son callback est vide.
En Module 5, on y appelera le refresh du solde et des transactions récentes.

---

## Prochaine étape : Module 2 (FileUploadService)

Le service d'upload de fichiers est requis par le Module 3 (KYC).
Il sera implémenté en premier pour débloquer le flow KYC complet.
