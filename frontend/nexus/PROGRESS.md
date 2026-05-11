# Nexus Flutter — Plan d'intégration Backend

## Stack identifiée
- State Management : **Riverpod** (StateNotifierProvider)
- Navigation : **go_router** v17
- HTTP : **Dio** v5 — singleton `DioClient`
- Stockage tokens : `flutter_secure_storage`
- Sérialisation : `fromJson/toJson` manuel (freezed installé mais non utilisé)
- Architecture : Feature-first `features/` + `core/` + `shared/`

---

## MODULE 0 — Corrections critiques (prérequis)
- [x] 0.1 — Corriger `app_enums.dart` : aligner tous les enums avec le backend
- [x] 0.2 — Implémenter l'auto-refresh + gestion 401 dans `DioClient`
- [x] 0.3 — Mettre `AuthUser.status` et `AuthUser.kycStatus` en types enum + corriger le redirect KYC dans le router

---

## MODULE 1 — Shell & Navigation
- [x] 1.1 — ShellRoute avec bottom navigation (Home, Loans, Investments, Tontine, Wallet)
- [x] 1.2 — Ajout de toutes les routes manquantes dans `app_router.dart`
- [x] 1.3 — Vrai `HomeScreen` (salutation, carte KYC status, actions rapides)

---

## MODULE 2 — Files (upload — requis par KYC)
- [x] 2.1 — `FileUploadService` (multipart Dio POST `/files/upload`)
- [x] 2.2 — `FileUploadNotifier` (état Loading / Success / Error)

---

## MODULE 3 — KYC
- [x] 3.1 — Modèles : `KycStatusResponse`, `KycSession1Request`, `KycSession2Request`
- [x] 3.2 — `KycRepository` (session-1, session-2, session-3, status, profile)
- [x] 3.3 — `KycNotifier` + `KycState`
- [x] 3.4 — `KycIntroScreen`
- [x] 3.5 — `KycDocumentScreen` (capture + upload via FileUploadService)
- [x] 3.6 — `KycFinancialScreen`
- [x] 3.7 — `KycReviewScreen` + `KycPendingScreen` + `KycRejectedScreen`

---

## MODULE 4 — Loans
- [x] 4.1 — Modèles : `Loan`, `CreateLoanRequest`, `RepayLoanRequest`
- [x] 4.2 — `LoanRepository` (my, detail, create, repay)
- [x] 4.3 — `LoanNotifier` + `LoanState` (liste paginée + détail + submit)
- [x] 4.4 — `LoansScreen` (liste, badges statut, pagination infinie, empty states)
- [x] 4.5 — `LoanDetailScreen` (barre progression, info financières, sheet remboursement)
- [x] 4.6 — `CreateLoanScreen` (formulaire montant/durée/objet, simulation mensualité)

---

## MODULE 5 — Transactions / Wallet
- [x] 5.1 — Modèles : `Transaction`, `DepositRequest`, `WithdrawalRequest`
- [x] 5.2 — `TransactionRepository` (my, deposit, withdraw)
- [x] 5.3 — `TransactionNotifier` + `TransactionState`
- [x] 5.4 — `WalletScreen` (solde + liste historique avec skeleton)
- [x] 5.5 — `DepositScreen` + `WithdrawScreen` (sélecteur MoMo provider)

---

## MODULE 6 — Investments
- [x] 6.1 — Modèles : `Investment`, `AutoInvestRule`, `InvestmentSummary`, `CreateInvestmentRequest`
- [x] 6.2 — `InvestmentRepository` (my, summary, detail, create, auto-invest CRUD+run)
- [x] 6.3 — `InvestmentNotifier` + `InvestmentState`
- [x] 6.4 — `LoanMarketplaceScreen` (onglet Marketplace dans InvestmentsScreen)
- [x] 6.5 — `InvestmentPortfolioScreen` (onglet Portfolio dans InvestmentsScreen)
- [x] 6.6 — `InvestmentDetailScreen`
- [x] 6.7 — `AutoInvestScreen` (configuration règle)

---

## MODULE 7 — Tontine
- [x] 7.1 — Modèles : `TontineGroup`, `TontineCycle`, `TontineScore`
- [x] 7.2 — `TontineRepository` (my-score, groups, group detail, join)
- [x] 7.3 — `TontineNotifier` + `TontineState`
- [x] 7.4 — `TontineScreen` (carte score + liste groupes)
- [x] 7.5 — `TontineGroupDetailScreen` (infos groupe, CTA rejoindre)
- [x] 7.6 — `CreateGroupScreen`
