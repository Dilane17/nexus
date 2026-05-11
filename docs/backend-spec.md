# Nexus — Frontend Reference Guide

> Base API : **`/api/v1`**
> Authentification : **JWT Bearer** requis sur tous les endpoints sauf ceux marqués 🔓 et les webhooks de paiement.

---

## Table des matières

1. [Modules & Endpoints](#1-modules--endpoints)
2. [Flows utilisateur réels](#2-flows-utilisateur-réels)
3. [Écrans & mapping API](#3-écrans--mapping-api)
4. [Règles UX](#4-règles-ux)
5. [Priorité de développement](#5-priorité-de-développement)
6. [Contraintes backend à respecter](#6-contraintes-backend-à-respecter)

---

## 1. Modules & Endpoints

### 🔐 Auth

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| POST | `/auth/register` | Créer un compte + envoyer OTP SMS | 🔓 |
| POST | `/auth/verify-phone` | Activer le compte avec le code SMS → retourne les tokens | 🔓 |
| POST | `/auth/verify-email` | Vérifier OTP Google/email → retourne les tokens | 🔓 |
| POST | `/auth/resend-otp` | Renvoyer OTP SMS ou email | 🔓 |
| POST | `/auth/forgot-password` | Envoyer OTP de réinitialisation | 🔓 |
| POST | `/auth/reset-password` | Définir un nouveau mot de passe depuis l'OTP | 🔓 |
| POST | `/auth/login` | Connexion phone + password | 🔓 |
| POST | `/auth/refresh` | Renouveler les tokens | 🔓* |
| POST | `/auth/logout` | Révoquer le refresh token | ✅ |
| GET | `/auth/me` | Profil courant de base | ✅ |
| PATCH | `/auth/me` | Modifier nom / ville / quartier | ✅ |
| PATCH | `/auth/change-password` | Changer le mot de passe + force re-login | ✅ |
| GET | `/auth/google` | Démarrer OAuth Google | 🔓 |
| GET | `/auth/google/callback` | Finaliser OAuth Google → tokens ou OTP email requis | 🔓 |

> 🔓* Le refresh nécessite le refresh token dans **`Authorization: Bearer <refreshToken>`** ET dans le body.

---

### 👤 Users

| Méthode | Route | Description | Rôle |
|---------|-------|-------------|------|
| POST | `/users/kyc/session-1` | Soumettre CNI/passeport + selfie (URLs) | ✅ |
| POST | `/users/kyc/session-2` | Soumettre revenus + source + URL relevé (optionnel) | ✅ |
| POST | `/users/kyc/session-3` | Finaliser le KYC pour revue IMF | ✅ |
| GET | `/users/kyc/status` | Voir progression KYC / motif de rejet | ✅ |
| GET | `/users/profile` | Profil complet : rôle, données investisseur, données emprunteur | ✅ |
| GET | `/users/kyc/pending` | Liste KYC en attente | IMF/ADMIN |
| PATCH | `/users/kyc/validate/:userId` | Approuver ou rejeter un KYC | IMF/ADMIN |

---

### 📁 Files

| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/files/upload` | Uploader une image → retourne une URL publique |

> ⚠️ **Images uniquement, max 5 MB.** Pas de PDF.

---

### 💸 Transactions

| Méthode | Route | Description | Rôle |
|---------|-------|-------------|------|
| GET | `/transactions/my` | Mes transactions (paginées) | ✅ |
| POST | `/transactions/deposit` | Démarrer un dépôt via MoMo | ✅ |
| POST | `/transactions/withdraw` | Démarrer un retrait via MoMo | ✅ |
| POST | `/transactions/webhook/fedapay` | Callback provider | 🔓 Webhook |
| POST | `/transactions/webhook/kkiapay` | Callback provider | 🔓 Webhook |
| GET | `/transactions/unreconciled` | Liste transactions non réconciliées | ADMIN |
| PATCH | `/transactions/:id/reconcile` | Marquer une transaction réconciliée | ADMIN |

> ⚠️ **Pas de `GET /transactions/:id`** → utiliser le polling sur la liste pour suivre l'état d'un dépôt/retrait.

---

### 🏦 Loans

| Méthode | Route | Description | Rôle |
|---------|-------|-------------|------|
| GET | `/loans/my` | Mes prêts (emprunteur) | borrower |
| GET | `/loans/:id` | Détail d'un prêt (propriétaire ou IMF) | ✅ |
| POST | `/loans` | Créer une demande de prêt | borrower |
| POST | `/loans/:id/repay` | Enregistrer un remboursement | borrower |
| GET | `/loans/pending-imf` | Liste demandes en attente | IMF/ADMIN |
| PATCH | `/loans/:id/validate` | Approuver / rejeter un prêt | IMF/ADMIN |
| POST | `/loans/:id/sandbox-score` | Simulation scoring risque | IMF/ADMIN |

---

### 📈 Investments

| Méthode | Route | Description | Rôle |
|---------|-------|-------------|------|
| GET | `/investments/my` | Mes investissements | investor |
| GET | `/investments/my/summary` | Totaux portefeuille + résumé wallet | investor |
| GET | `/investments/:id` | Détail d'un investissement | investor |
| POST | `/investments` | Investir dans un prêt en `FUNDING` | investor |
| GET | `/investments/auto-invest` | Voir la règle auto-invest active | investor |
| PUT | `/investments/auto-invest` | Créer / mettre à jour la règle | investor |
| POST | `/investments/auto-invest/run` | Lancer manuellement l'auto-invest | investor |

> ⚠️ Les routes `/investments/auto-invest*` peuvent entrer en conflit avec `/investments/:id` selon l'ordre des contrôleurs backend. **Tester ces routes en priorité.**

---

### 🤝 Tontine

| Méthode | Route | Description | Rôle |
|---------|-------|-------------|------|
| GET | `/tontine/my-score` | Score / historique tontine de l'emprunteur | borrower |
| GET | `/tontine/groups` | Lister les groupes | ✅ |
| POST | `/tontine/groups` | Créer un groupe | ✅ |
| GET | `/tontine/groups/:id` | Détail groupe (membres, cycles) | ✅ |
| POST | `/tontine/groups/:id/join` | Rejoindre un groupe | ✅ |
| POST | `/tontine/groups/:id/cycles` | Leader démarre un cycle | Leader |
| PATCH | `/tontine/cycles/:id/complete` | Leader clôture un cycle + met à jour le score | Leader |

---

### 🛡️ Admin

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/admin/dashboard` | Métriques globales |
| GET | `/admin/reports/bceao` | Rapport conformité sur plage de dates |
| GET | `/admin/guarantee-fund` | Santé du fonds de garantie |
| GET | `/admin/users` | Liste paginée des utilisateurs |
| GET | `/admin/users/:id` | Détail d'un utilisateur |
| PATCH | `/admin/users/:id/status` | Activer / suspendre / bloquer un utilisateur |

> 💡 Ces écrans se prêtent mieux à un **backoffice web** qu'à l'app mobile Expo.

---

## 2. Flows utilisateur réels

### 📱 Inscription par téléphone
```
POST /auth/register
  → SMS OTP reçu
POST /auth/verify-phone  (code OTP)
  → tokens retournés → app authentifiée
```

### 🔑 Connexion + restauration de session
```
POST /auth/login  → stocke accessToken + refreshToken
  (à l'expiry de l'accessToken)
POST /auth/refresh  → nouveaux tokens
  (si refresh échoue)
→ rediriger vers /login
```

### 🔒 Mot de passe oublié
```
POST /auth/forgot-password  (phone ou email Google)
  → OTP reçu
POST /auth/reset-password  (code + nouveau mot de passe)
  → rediriger vers /login
```

### ✅ KYC complet
```
POST /files/upload  (CNI/passeport) → URL doc
POST /files/upload  (selfie) → URL selfie
POST /users/kyc/session-1  (URLs doc + selfie)
  ↓
POST /files/upload  (relevé, optionnel) → URL
POST /users/kyc/session-2  (revenus + source + URL)
  ↓
POST /users/kyc/session-3  (finalisation)
  → en attente revue IMF
GET /users/kyc/status  → polling du statut
  Si REJECTED → lire le motif → recommencer depuis session-1
```

### 💰 Wallet investisseur — Dépôt
```
POST /transactions/deposit  (montant + provider MoMo + numéro)
  → initiation async
  → polling GET /transactions/my  jusqu'à confirmation webhook
  → rafraîchir GET /users/profile ou GET /investments/my/summary
```

### 💰 Wallet investisseur — Retrait
```
POST /transactions/withdraw  (montant + provider + numéro destination)
  → polling GET /transactions/my  jusqu'à confirmation/échec
  → rafraîchir données wallet
```

### 📊 Portefeuille investisseur
```
GET /investments/my/summary  → totaux, taux, solde wallet
GET /investments/my  → liste investissements
GET /investments/auto-invest  → règle active
PUT /investments/auto-invest  → créer/modifier règle
POST /investments/auto-invest/run  → lancer manuellement
  → GET /investments/my  (rafraîchi)
```

### 🏧 Cycle de vie prêt — Emprunteur
```
POST /loans  (montant + durée + objet)
  → en attente décision IMF
GET /loans/my  → statut PENDING → APPROVED → FUNDING → ACTIVE/DISBURSED
  (si REJECTED → lire motif)
  (si ACTIVE)
POST /loans/:id/repay  (montant + provider MoMo + référence externe)
  → ... répéter jusqu'à REPAID
```

### 🤝 Tontine — Emprunteur
```
GET /tontine/my-score  → score + historique
GET /tontine/groups  → parcourir les groupes
POST /tontine/groups  (si création)
POST /tontine/groups/:id/join  (si rejoindre)
  (leader uniquement)
POST /tontine/groups/:id/cycles  → démarrer un cycle
PATCH /tontine/cycles/:id/complete  → clôturer + score mis à jour
```

---

## 3. Écrans & mapping API

| Écran | Endpoints | Notes |
|-------|-----------|-------|
| **Splash / Session Bootstrap** | `POST /auth/refresh`, `GET /users/profile` | Vérifie les tokens stockés ; si refresh échoue → login |
| **Register** | `POST /auth/register` | Champs : firstName, lastName, phone, password, city, district |
| **Phone OTP Verification** | `POST /auth/verify-phone`, `POST /auth/resend-otp` | Code 5 chiffres, timer de renvoi |
| **Login** | `POST /auth/login` | Afficher clairement : bloqué / suspendu / non vérifié |
| **Forgot Password** | `POST /auth/forgot-password` | Choix phone ou email |
| **Reset Password** | `POST /auth/reset-password` | Code + nouveau MDP + confirmation |
| **Home / Role Dashboard** | `GET /users/profile`, `GET /investments/my/summary` (investor), `GET /users/kyc/status` + `GET /loans/my` + `GET /tontine/my-score` (borrower) | Vue role-aware |
| **Profile** | `GET /auth/me`, `PATCH /auth/me`, `PATCH /auth/change-password` | change-password → force re-login |
| **KYC Step 1** | `POST /files/upload` (×2), `POST /users/kyc/session-1` | Doc + selfie |
| **KYC Step 2** | `POST /files/upload` (optionnel), `POST /users/kyc/session-2` | Revenus + source + URL relevé |
| **KYC Review Status** | `GET /users/kyc/status`, `POST /users/kyc/session-3` | Progression, motif rejet, finalisation |
| **Wallet** | `GET /users/profile` ou `GET /investments/my/summary`, `GET /transactions/my` | Solde + historique |
| **Deposit** | `POST /transactions/deposit`, polling `GET /transactions/my` | Async — polling jusqu'à webhook |
| **Withdraw** | `POST /transactions/withdraw`, polling `GET /transactions/my` | Async — polling jusqu'à confirmation |
| **Transactions** | `GET /transactions/my` | Paginé, filtrable |
| **Portfolio Summary** | `GET /investments/my/summary` | Totaux, rendements, ratio NPL |
| **Investments List** | `GET /investments/my` | Liste paginée |
| **Investment Detail** | `GET /investments/:id` | Inclut résumé du prêt associé |
| **Auto-Invest Settings** | `GET /investments/auto-invest`, `PUT /investments/auto-invest`, `POST /investments/auto-invest/run` | ⚠️ Tester conflit avec `/:id` |
| **Loan Request** | `POST /loans` | Montant + durée + objet |
| **My Loans** | `GET /loans/my` | Vue emprunteur |
| **Loan Detail** | `GET /loans/:id` | Statut, échéances, solde, motif rejet |
| **Loan Repayment** | `POST /loans/:id/repay` | Montant + provider MoMo + référence externe MoMo |
| **Tontine Score** | `GET /tontine/my-score` | Score + historique + taux de paiement |
| **Tontine Groups** | `GET /tontine/groups` | Parcourir |
| **Tontine Group Detail** | `GET /tontine/groups/:id`, `POST /tontine/groups/:id/join` | Membres, cycles, CTA rejoindre |
| **Create Tontine Group** | `POST /tontine/groups` | Nom + contribution mensuelle |
| **Leader Cycle Management** | `POST /tontine/groups/:id/cycles`, `PATCH /tontine/cycles/:id/complete` | Choisir bénéficiaire, dates, clôturer |
| **IMF/Admin Ops** (futur web) | `/users/kyc/pending`, `/users/kyc/validate/:userId`, `/loans/pending-imf`, `/loans/:id/validate`, `/loans/:id/sandbox-score`, `/transactions/unreconciled`, `/transactions/:id/reconcile`, `/admin/*` | Backoffice — pas prioritaire mobile |

---

## 4. Règles UX

### ⏳ Chargement
- **Listes et dashboards** → utiliser des **skeleton loaders**, pas des spinners
- **Boutons de soumission** → désactiver pendant OTP, dépôt, retrait, KYC, prêt, auto-invest

### ❌ Erreurs
Afficher directement les messages backend pour :
- OTP invalide
- Compte bloqué
- Téléphone non vérifié
- Solde wallet insuffisant
- KYC non validé
- Prêt actif déjà existant
- Référence MoMo dupliquée

### ✅ Succès
- Après chaque écriture → **confirmation courte** (toast ou écran) + **refetch immédiat** des écrans dépendants

### 🔄 Polling
- Dépôts et retraits sont **asynchrones** (webhook côté backend)
- Après initiation → **poller `GET /transactions/my`** + données wallet régulièrement
- Pas de `GET /transactions/:id` → on surveille la liste

### 🔑 Session & Tokens
- Le refresh nécessite le refresh token : **`Authorization: Bearer <refreshToken>`** + **dans le body**
- `PATCH /auth/change-password` → déconnecte immédiatement l'utilisateur

### 🧩 Cas limites critiques
| Cas | Comportement attendu |
|-----|---------------------|
| KYC rejeté | Afficher le motif de rejet ; permettre de recommencer uniquement depuis `session-1` |
| Loan repayment | Capture de référence manuelle MoMo — **pas** une initiation de paiement |
| change-password | Déconnecter l'utilisateur immédiatement après succès |
| Upload fichier | Images uniquement, **max 5 MB** — pas de PDF |

---

## 5. Priorité de développement

### 🔴 Critique — À livrer en premier

- [ ] Splash / restauration de session
- [ ] Login
- [ ] Register
- [ ] Vérification OTP téléphone
- [ ] Mot de passe oublié / réinitialisation
- [ ] Home role-aware (dashboard)
- [ ] Profile (voir + modifier)
- [ ] KYC Step 1, 2, statut/review
- [ ] Wallet (solde + transactions)
- [ ] Dépôt MoMo
- [ ] Retrait MoMo
- [ ] Transactions (liste paginée)
- [ ] My Loans (liste emprunteur)
- [ ] Loan Detail
- [ ] Loan Request
- [ ] Loan Repayment
- [ ] Portfolio Summary (investisseur)
- [ ] Investments List & Detail
- [ ] Auto-Invest Settings

### 🟡 Important — Second sprint

- [ ] Tontine Score
- [ ] Tontine Groups (liste + détail)
- [ ] Rejoindre / Créer un groupe
- [ ] Gestion des cycles (leader)
- [ ] Google Login

### ⚪ Optionnel / Futur — Backoffice web

- [ ] IMF/Admin : revue KYC, validation prêts, réconciliation transactions, dashboard, rapports, gestion utilisateurs

---

## 6. Contraintes backend à respecter

> [!IMPORTANT]
> **Pas de self-service pour changer de rôle.**
> Il n'existe aucun endpoint permettant à un utilisateur de se proclamer `investor` ou `borrower`. Le rôle est assigné côté backend. L'app doit lire `GET /users/profile.role` et n'afficher que les fonctionnalités que le rôle courant autorise.

> [!WARNING]
> **Pas de liste de prêts en `FUNDING` accessible aux investisseurs mobiles.**
> `POST /investments` existe, mais il n'y a pas d'endpoint mobile-safe pour lister les prêts en `FUNDING`. Le flux "investisseur browse les prêts disponibles" n'est pas encore complètement supporté.

> [!CAUTION]
> **Conflit potentiel de routes auto-invest.**
> Les routes `GET/PUT/POST /investments/auto-invest*` peuvent entrer en conflit avec `GET /investments/:id` selon l'ordre des contrôleurs backend. **Tester ces routes le plus tôt possible** dans le développement.

> [!NOTE]
> **KYC session-2 : upload relevé bancaire.**
> Le champ URL de relevé est optionnel. L'API `/files/upload` n'accepte que des images (pas de PDF). Si l'utilisateur a un PDF, il faut le lui signaler clairement.
