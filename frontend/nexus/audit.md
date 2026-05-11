# Audit d'alignement Frontend ↔ Backend Docs

---

## 🔴 CRITIQUE — Bloquant en production

### [C1] Marketplace Investments : mauvais endpoint ✅ CORRIGÉE
`InvestmentNotifier.loadMarketplace()` appelait `GET /loans/my` — endpoint emprunteur propriétaire.

**Fix appliqué** :
- **Backend** : `GET /loans/funding` ajouté dans `loans.controller.ts` (avant `:id`). `LoansService.getFundingLoans()` implémentée : filtre `status = FUNDING` + `borrower_id ≠ userId` + accès réservé aux investisseurs. `getLoanById()` autorise les investisseurs à voir le détail d'un prêt FUNDING qui ne leur appartient pas. `InvestmentsService.createInvestment()` : guard auto-investissement ajouté.
- **Frontend** : `LoanRepository.getFundingLoans()` ajoutée avec parsing paginé (`data.items`). `getMyLoans()` parsing corrigé (idem — `data.items` au lieu de `data` directement). `loadMarketplace()` utilise désormais `getFundingLoans()`, filtre frontend supprimé.

---

## 🟠 IMPORTANT — Fonctionnalité manquante

### [I1] Actions rapides HomeScreen : mauvaises routes ✅ CORRIGÉE
`home_screen.dart:262-265` — Les boutons "Déposer" et "Retirer" naviguaient vers `/wallet` au lieu de `/wallet/deposit` et `/wallet/withdraw`.

### [I2] Resend OTP absent ✅ CORRIGÉE
Déjà implémenté : `VerifyPhoneScreen` a un bouton "Renvoyer le code" avec timer 60s qui appelle `authRepository.resendOtp()` → `POST /auth/resend-otp`.

### [I3] Profil & mot de passe : aucun écran ✅ CORRIGÉE
`auth.md` documente :
- `PATCH /auth/me` — modifier prénom, nom, ville, quartier
- `PATCH /auth/change-password` — changer le mot de passe

**Fix appliqué** : `features/profile/presentation/screens/profile_screen.dart` créé avec formulaire d'édition + changement de mot de passe. Route `/profile` ajoutée dans `app_router.dart`. Avatar dans `HomeScreen` navigue vers `/profile`.

### [I4] Google Auth non implémenté ✅ CORRIGÉE
`auth.md` documente `GET /auth/google`. Bouton Google déjà présent dans `LoginScreen`. `RegisterScreen` ne l'avait pas.

**Fix appliqué** : Méthode `_handleGoogleSignIn()` + bouton "Continuer avec Google" ajoutés dans `RegisterScreen`.

---

## 🟡 MINEUR — UX / complétude

### [M1] Cycles tontine non affichés ✅ CORRIGÉE
`TontineGroupDetailScreen` n'affichait pas les cycles malgré le modèle `TontineCycle` existant.

**Fix appliqué** : `getCycles(groupId)` ajouté dans `TontineRepository` (`GET /tontine/groups/:id/cycles`). `TontineState.cycles` + `loadCycles()` ajoutés dans le provider. `TontineGroupDetailScreen` charge et affiche les cycles via le widget `_CycleTile`.

### [M2] Filtres transactions absents ✅ CORRIGÉE
`GET /transactions/my` accepte un param `type`. `WalletScreen` n'avait aucun sélecteur de filtre.

**Fix appliqué** : `TransactionState.selectedType` + `filterByType()` + `loadTransactions(type)` ajoutés dans le provider. Chips de filtre (Tous / Dépôts / Retraits / Remboursements) ajoutés dans `WalletScreen` via `_FilterChips`.

### [M3] Pagination marketplace hardcodée
`loadMarketplace()` fait `limit: 50` sans pagination réelle.

**Fix** : Implémenter une vraie pagination dans `investment_provider.dart`.

**Statut** : ⏳ À corriger (dépend de [C1])

### [M4] `isPhoneVerified` non exploité ✅ CORRIGÉE
`AuthUser.isPhoneVerified` était mappé mais jamais utilisé.

**Fix appliqué** : Guard ajouté dans `app_router.dart` — si l'utilisateur est authentifié mais `isPhoneVerified == false`, redirection automatique vers `/verify-phone`. `VerifyPhoneScreen` utilise maintenant `_effectivePhone` (fallback sur `authProvider.user.phone` si `widget.phone` est vide).

---

## ✅ Ce qui est conforme

| Module | Verdict |
|---|---|
| Auth (login, register, verify, forgot/reset password) | ✅ Conforme |
| KYC (3 sessions, status, retry sur rejet) | ✅ Conforme |
| Files (upload multipart) | ✅ Conforme |
| Loans (my, detail, create, repay + validations BCEAO) | ✅ Conforme |
| Wallet (deposit, withdraw, history, solde calculé) | ✅ Conforme |
| Investments (portfolio, summary, detail, auto-invest CRUD+run) | ✅ Conforme |
| Tontine (score, groups, create, join) | ✅ Conforme |
| Modèles (enums, Decimal Prisma, fromJson robuste) | ✅ Conforme |
| Router (protection JWT, redirect KYC, toutes routes) | ✅ Conforme |
