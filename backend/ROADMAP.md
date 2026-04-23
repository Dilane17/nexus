# Nexus Backend — Roadmap d'implémentation

> Ordre de priorité : chaque module dépend du précédent.
> Cocher une tâche dès qu'elle est terminée et testée via Swagger.

---

## ✅ Module 0 — Infrastructure & Auth

- [x] PrismaModule global
- [x] SharedModule (mail, SMS, guards, pipes)
- [x] `POST /auth/register` — inscription + OTP SMS
- [x] `POST /auth/verify-phone` — vérification OTP téléphone
- [x] `POST /auth/verify-email` — vérification OTP email
- [x] `POST /auth/login` — connexion JWT + refresh token
- [x] `POST /auth/refresh` — renouvellement tokens
- [x] `POST /auth/logout` — révocation refresh token
- [x] `GET  /auth/profile` — profil connecté
- [x] `PATCH /auth/profile` — mise à jour profil (nom, ville)
- [x] `POST /auth/google` — OAuth Google
- [x] `POST /auth/forgot-password` — demande réinitialisation
- [x] `POST /auth/reset-password` — réinitialisation avec OTP
- [x] RolesGuard (imf_staff, admin, investor, borrower, agent)

---

## ✅ Module 1 — Users & KYC

- [x] `POST /users/kyc/session-1` — document d'identité (type + URL photo + selfie)
- [x] `POST /users/kyc/session-2` — informations financières (revenus, source, MoMo)
- [x] `POST /users/kyc/session-3` — soumission finale pour validation IMF
- [x] `GET  /users/kyc/status` — consulter son statut KYC
- [x] `GET  /users/kyc/pending` — [IMF Staff] lister les dossiers en attente
- [x] `PATCH /users/kyc/validate/:userId` — [IMF Staff] approuver ou rejeter
- [x] `GET  /users/profile` — profil complet avec rôle et données métier

---

## ✅ Module 2 — Files (Upload)

- [x] `POST /files/upload` — uploader une image (doc KYC, selfie) → retourne une URL

---

## ✅ Module 3 — Loans (Prêts)

### DTOs
- [x] `create-loan.dto.ts` — montant (25k–500k FCFA), durée (3/6/9/12 mois), objet du prêt
- [x] `validate-loan.dto.ts` — décision IMF (APPROVED / REJECTED) + motif + taux
- [x] `repay-loan.dto.ts` — montant remboursement + référence MoMo + provider
- [x] `loan-response.dto.ts` — format de réponse standardisé

### Endpoints emprunteur
- [x] `POST /loans` — créer une demande de prêt (KYC VALIDATED requis)
- [x] `GET  /loans/my` — mes demandes de prêt (pagination)
- [x] `GET  /loans/:id` — détail d'un prêt
- [x] `POST /loans/:id/repay` — soumettre un remboursement MoMo

### Endpoints IMF Staff
- [x] `GET  /loans/pending-imf` — [IMF] dossiers en attente de validation
- [x] `PATCH /loans/:id/validate` — [IMF] approuver ou rejeter (PENDING_IMF → FUNDING/CANCELLED)

### Logique métier
- [x] Calcul mensualité (formule prêt amortissable, taux max 18% BCEAO)
- [x] Vérification montant (25 000 ≤ montant ≤ 500 000 FCFA)
- [x] Vérification durée (3, 6, 9 ou 12 mois uniquement)
- [x] Scoring hybride — calcul `hybrid_score` à la demande
  - [x] Score MoMo (40%) — basé sur `credit_score` du Borrower
  - [x] Score Tontine (35%) — basé sur `tontine_score` du Borrower
  - [x] Score IMF (25%) — basé sur `default_count` (pénalité -25pts/défaut)
  - [x] Persistance dans `BorrowerScore`
- [x] Vérification que l'emprunteur n'a pas de prêt ACTIVE/OVERDUE/FUNDING en cours
- [x] Idempotence remboursement (unicité `momo_reference`)
- [x] Avancement `next_due_date` + passage en REPAID si balance = 0
- [x] Bonus `credit_score` (+2 pts) si remboursement à temps

### Sandbox IMF
- [x] Service `ImfSandboxService` — scoring simulé basé sur le score hybride
- [x] Endpoint `POST /loans/:id/sandbox-score` — [IMF] retourne APPROVE / APPROVE_WITH_CONDITIONS / HIGH_RISK / REJECT + taux suggéré

---

## ✅ Module 4 — Investments (Portefeuille)

### DTOs
- [x] `create-investment.dto.ts` — loan_id, montant (min 5 000 FCFA)
- [x] `investment-response.dto.ts` — InvestmentResponse + InvestmentLoanDetail + PortfolioSummary

### Endpoints
- [x] `POST /investments` — investir sur un prêt en FUNDING
- [x] `GET  /investments/my` — mon portefeuille (pagination + filtre statut)
- [x] `GET  /investments/my/summary` — résumé (totaux, rendements, taux NPL)
- [x] `GET  /investments/:id` — détail d'un investissement

### Logique métier
- [x] Vérifier que le prêt est en statut FUNDING
- [x] Vérifier que le montant ne dépasse pas le solde restant à financer
- [x] Vérifier solde wallet suffisant
- [x] Mettre à jour `wallet_balance` et `total_invested` de l'Investor (atomique)
- [x] Vérifier le fonds de garantie (rejet si `suspension_active = true`)
- [x] Créer `GuaranteeFundInvestment` + recalcul `coverage_ratio`
- [x] Déclencher transition FUNDING → ACTIVE si prêt 100% financé (+ `disbursed_at`, `next_due_date`)
- [x] Calcul `expected_return` proportionnel aux intérêts du prêt

### Auto-Invest
- [x] Modèle `AutoInvestRule` — migration + Prisma generate
- [x] `PUT  /investments/auto-invest` — créer ou mettre à jour la règle (upsert)
- [x] `GET  /investments/auto-invest` — voir la règle active
- [x] `POST /investments/auto-invest/run` — lancer le matching manuellement (scanne prêts FUNDING, filtre par score + durée + montant + solde wallet)

---

## ✅ Module 5 — Tontine

### DTOs
- [x] `create-tontine-group.dto.ts` — nom, contribution mensuelle
- [x] `create-cycle.dto.ts` — numéro cycle, dates, bénéficiaire (avec refine end > start)
- [x] `complete-cycle.dto.ts` — membres payés / défaillants / total collecté
- [x] `tontine-response.dto.ts` — Group, Detail, Cycle, Score, Paginated

### Endpoints
- [x] `POST /tontine/groups` — créer un groupe (leader auto-ajouté comme membre)
- [x] `GET  /tontine/groups` — lister les groupes (filtre statut, pagination)
- [x] `GET  /tontine/groups/:id` — détail groupe + membres + cycles
- [x] `POST /tontine/groups/:id/join` — rejoindre un groupe PENDING ou ACTIVE
- [x] `POST /tontine/groups/:id/cycles` — [Leader] démarrer un cycle (PENDING → ACTIVE auto)
- [x] `PATCH /tontine/cycles/:id/complete` — [Leader] clôturer un cycle
- [x] `GET  /tontine/my-score` — score tontine + métriques

### Logique Tontine Bridge
- [x] Calcul `tontine_score` = moyenne des taux de paiement sur tous les cycles complétés
- [x] Mise à jour `Borrower.tontine_score` et `Borrower.has_tontine_history` à chaque clôture
- [x] Vérification : max 1 groupe PENDING/ACTIVE par leader
- [x] Transition automatique PENDING → ACTIVE à la création du premier cycle
- [x] Vérification bénéficiaire = membre du groupe

---

## ✅ Module 6 — Transactions

### DTOs
- [x] `deposit.dto.ts` — montant, provider, numéro MoMo source
- [x] `withdrawal.dto.ts` — montant, provider, numéro MoMo destinataire
- [x] `webhook-callback.dto.ts` — momo_reference, status, failure_reason
- [x] `transaction-response.dto.ts`

### Endpoints investisseur
- [x] `POST /transactions/deposit` — initier un dépôt (référence NEXUS générée + payment_url sandbox)
- [x] `POST /transactions/withdraw` — initier un retrait (débit wallet immédiat, reversé si FAILED)
- [x] `GET  /transactions/my` — historique paginé (filtre par type)

### Endpoints webhook
- [x] `POST /transactions/webhook/fedapay` — callback FedaPay (sans JWT, public)
- [x] `POST /transactions/webhook/kkiapay` — callback KKiaPay (sans JWT, public)

### Réconciliation H+24
- [x] `GET  /transactions/unreconciled` — [Admin] avec détection PHANTOM auto au chargement
- [x] `PATCH /transactions/:id/reconcile` — [Admin] → status RECONCILED + reconciled_at
- [x] Détection PHANTOM : PENDING > 24h → `PHANTOM_DETECTED` (flaggé automatiquement)

### Logique métier
- [x] Idempotence webhook : transaction déjà CONFIRMED → 200 sans retraitement
- [x] Phantom sur référence inconnue : log warn sans crash
- [x] Crédit `wallet_balance` à la confirmation dépôt (webhook CONFIRMED)
- [x] Reversal automatique du débit wallet si retrait échoue (webhook FAILED)
- [x] Piste d'audit via `initiated_at` (conservation 5 ans — règle BCEAO)

---

## ✅ Module 7 — Admin

### Dashboard
- [x] `GET /admin/dashboard` — statistiques globales en une requête parallèle
  - [x] Utilisateurs : total, KYC validés, KYC en attente, actifs aujourd'hui
  - [x] Prêts : NPL ratio, actifs, en retard, remboursés, en attente IMF, encours
  - [x] Transactions : volume du jour, en attente, PHANTOM détectés
  - [x] Fonds de garantie : capital, ratio couverture, suspension

### Gestion fonds de garantie
- [x] `GET /admin/guarantee-fund` — état complet du fonds (ratio, seuils, suspension)

### Rapports BCEAO
- [x] `GET /admin/reports/bceao?from=&to=` — rapport sur période
  - [x] Encours total + montant décaissé
  - [x] Taux NPL sur la période
  - [x] Répartition par durée (3/6/9/12 mois)
  - [x] Répartition par tranche de montant (3 tranches BCEAO)
  - [x] Réconciliation : confirmées vs non-réconciliées vs PHANTOM

### Gestion utilisateurs
- [x] `GET  /admin/users` — liste paginée (filtres statut + kyc_status)
- [x] `GET  /admin/users/:id` — fiche complète avec rôle
- [x] `PATCH /admin/users/:id/status` — bloquer / suspendre / réactiver (raison obligatoire)

---

## ✅ Transversal — Sécurité & Qualité

### Sécurité & robustesse
- [x] Rate limiting global : 100 req/min par IP (`@nestjs/throttler` + `APP_GUARD`)
- [x] Rate limiting strict sur routes sensibles : register/login (10/min), resend-otp/forgot-password (5/min)
- [x] Helmet — sécurisation des headers HTTP (XSS, clickjacking, MIME sniffing…)
- [x] `ParseUUIDPipe` sur tous les paramètres `:id` de route
- [x] Filtre global `PrismaExceptionFilter` — mapping P2002→409, P2025→404, P2003→400, etc.

### Qualité
- [x] Tests unitaires `LoansService` — mensualité (4 cas), garde KYC, garde IMF (9 tests)
- [x] Tests unitaires `TransactionsService` — dépôt, retrait, idempotence webhook, phantom (5 tests)
- [x] `.env.example` complet — toutes les variables documentées avec instructions

---

## Ordre d'implémentation recommandé

```
Loans → Investments → Tontine → Transactions → Admin → Transversal
```

> Chaque module doit avoir ses endpoints Swagger documentés et testables avant de passer au suivant.
